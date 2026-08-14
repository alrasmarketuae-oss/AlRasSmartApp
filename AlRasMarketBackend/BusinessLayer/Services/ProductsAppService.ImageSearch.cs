using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    public async Task<object> SearchByThreeNamesAsync(string firstName, string secondName, string thirdName, CancellationToken cancellationToken = default)
    {
        return await SearchBySuggestedNamesAsync(
            [firstName, secondName, thirdName],
            cancellationToken).ConfigureAwait(false);
    }

    public async Task<object> SearchBySuggestedNamesAsync(
        IReadOnlyList<string> suggestedNames,
        CancellationToken cancellationToken = default)
    {
        // Do not await listing expiry here — image/name search must stay snappy.
        var names = (suggestedNames ?? Array.Empty<string>())
            .Select(x => x?.Trim() ?? string.Empty)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(12)
            .ToList();

        if (names.Count == 0)
        {
            throw new ArgumentException("At least one product name is required.");
        }

        var namesKey = string.Join('|', names.Select(n => n.ToLowerInvariant()).OrderBy(n => n));
        var cacheKey = $"{SearchProductsCachePrefix}image-names:v{SearchProductsCacheVersion}:{namesKey}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        // Image search: product name only (never category).
        // Singular + plural (and synonyms) are OR'd in one catalog query.
        var tokens = BuildImageSearchTokens(names);
        if (tokens.Count == 0)
        {
            return new
            {
                searchNames = names,
                searchTokens = Array.Empty<string>(),
                count = 0,
                items = Array.Empty<object>()
            };
        }

        var hits = await SearchCatalogByProductNameAnyAsync(tokens, take: 100, cancellationToken)
            .ConfigureAwait(false);

        if (hits.Count == 0)
        {
            return new
            {
                searchNames = names,
                searchTokens = tokens,
                count = 0,
                items = Array.Empty<object>()
            };
        }

        var productIds = hits.Select(x => x.ProductId).ToList();
        var nameTranslations = await productData
            .GetProductNameTranslationsByProductIdsAsync(productIds, cancellationToken)
            .ConfigureAwait(false);

        var namesByProduct = nameTranslations
            .GroupBy(t => t.ProductId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var ranked = hits
            .Select(product =>
            {
                var nameTexts = new List<string?>();
                if (!string.IsNullOrWhiteSpace(product.NameEn))
                {
                    nameTexts.Add(product.NameEn);
                }

                if (namesByProduct.TryGetValue(product.ProductId, out var trs))
                {
                    foreach (var tr in trs)
                    {
                        nameTexts.Add(tr.TextAr);
                        nameTexts.Add(tr.TextEn);
                    }
                }

                return new
                {
                    Product = product,
                    Score = ScoreImageNameMatch(names, tokens, nameTexts)
                };
            })
            .Where(x => x.Score > 0)
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Product.CreatedAt)
            .Take(100)
            .Select(x => x.Product)
            .ToList();

        var items = await BuildPublicProductListItemsAsync(
            ranked,
            cancellationToken,
            expandHybridSearchChannels: true);

        var result = new
        {
            searchNames = names,
            searchTokens = tokens,
            count = items.Count,
            items
        };

        if (items.Count > 0)
        {
            await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        }

        return result;
    }

    /// <summary>
    /// Whole-word OR match: any of <paramref name="words"/> (e.g. singular + plural) against
    /// product name / name translations only — one candidate+filter pass.
    /// </summary>
    private async Task<List<ProductPublicRow>> SearchCatalogByProductNameAnyAsync(
        IReadOnlyList<string> words,
        int take,
        CancellationToken cancellationToken)
    {
        var uniqueWords = words
            .SelectMany(w =>
            {
                var list = new List<string> { w };
                list.AddRange(ResolveSearchSynonyms(w));
                return list;
            })
            .Select(w => w.Trim())
            .Where(w => !string.IsNullOrWhiteSpace(w) && !IsSearchStopToken(w))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(16)
            .ToList();

        if (uniqueWords.Count == 0)
        {
            return [];
        }

        return await productData
            .SearchPublicProductsByNameAnyAsync(uniqueWords, take, cancellationToken)
            .ConfigureAwait(false);
    }

    /// <summary>
    /// Visual product search: Image → CLIP embed → Qdrant HNSW → catalog products.
    /// No OpenAI Vision fallback — text guessing is not visual marketplace search.
    /// </summary>
    public async Task<object> DetectProductsFromImageAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default)
    {
        await using var buffered = new MemoryStream();
        await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
        if (buffered.Length == 0)
        {
            return EmptyImageSearchResult();
        }

        if (!imageEmbeddingOptions.Value.Enabled
            || string.IsNullOrWhiteSpace(imageEmbeddingOptions.Value.ClipServiceUrl))
        {
            logger.LogWarning("Image search unavailable — CLIP is disabled or ClipServiceUrl is empty.");
            return EmptyImageSearchResult();
        }

        using var clipCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        clipCts.CancelAfter(TimeSpan.FromSeconds(12));

        try
        {
            buffered.Position = 0;
            var vector = await imageEmbeddingService
                .EmbedImageAsync(buffered, fileName, cancellationToken: clipCts.Token)
                .ConfigureAwait(false);

            if (vector is not { Length: > 0 })
            {
                logger.LogWarning("CLIP embed returned empty for {FileName}", fileName);
                return EmptyImageSearchResult();
            }

            var hits = await productImageVectorIndex
                .SearchSimilarAsync(vector, clipCts.Token)
                .ConfigureAwait(false);

            if (hits.Count == 0)
            {
                logger.LogInformation(
                    "CLIP image search found no confident matches for {FileName}",
                    fileName);
                return EmptyImageSearchResult();
            }

            var referenceHits = hits.Where(h => h.IsReference).ToList();
            var catalogHits = hits.Where(h => !h.IsReference).ToList();

            var orderedIds = catalogHits
                .GroupBy(h => h.ProductId)
                .Select(g => new { ProductId = g.Key, Score = g.Max(x => x.Score) })
                .OrderByDescending(x => x.Score)
                .Select(x => x.ProductId)
                .Where(id => id != ClipVectorIds.ReferenceProductId)
                .ToList();

            var rows = orderedIds.Count > 0
                ? await productData
                    .GetProductsByIdsAsync(orderedIds, cancellationToken)
                    .ConfigureAwait(false)
                : [];

            var byId = rows.ToDictionary(x => x.ProductId);
            var ranked = orderedIds
                .Where(byId.ContainsKey)
                .Select(id => byId[id])
                .ToList();

            var items = ranked.Count > 0
                ? await BuildPublicProductListItemsAsync(
                        ranked,
                        cancellationToken,
                        expandHybridSearchChannels: true)
                    .ConfigureAwait(false)
                : [];

            var topName = hits
                .Select(h => h.ProductName)
                .FirstOrDefault(n => !string.IsNullOrWhiteSpace(n))
                ?? string.Empty;

            var referenceMatches = referenceHits
                .GroupBy(h => h.ReferenceImageId)
                .Select(g =>
                {
                    var best = g.OrderByDescending(x => x.Score).First();
                    return new
                    {
                        referenceImageId = best.ReferenceImageId,
                        productName = best.ProductName,
                        imagePath = best.ImagePath,
                        score = best.Score,
                        isReference = true,
                    };
                })
                .OrderByDescending(x => x.score)
                .ToList();

            var suggestedFromReferences = referenceMatches
                .Select(x => x.productName)
                .Where(n => !string.IsNullOrWhiteSpace(n));

            return new
            {
                detectedProductName = topName,
                detectedBrand = string.Empty,
                suggestedNames = hits
                    .Select(h => h.ProductName)
                    .Concat(suggestedFromReferences)
                    .Where(n => !string.IsNullOrWhiteSpace(n))
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .Take(8)
                    .ToList(),
                count = items.Count,
                items,
                referenceMatches,
                referenceCount = referenceMatches.Count,
                scores = catalogHits
                    .GroupBy(h => h.ProductId)
                    .Select(g => new
                    {
                        productId = g.Key,
                        score = g.Max(x => x.Score)
                    })
                    .OrderByDescending(x => x.score)
                    .ToList(),
                referenceScores = referenceMatches
                    .Select(x => new
                    {
                        referenceImageId = x.referenceImageId,
                        productName = x.productName,
                        score = x.score,
                    })
                    .ToList(),
                searchMode = "clip-qdrant",
                products = new
                {
                    searchNames = Array.Empty<string>(),
                    searchTokens = Array.Empty<string>(),
                    count = items.Count,
                    items
                }
            };
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("CLIP/Qdrant image search timed out for {FileName}", fileName);
            return EmptyImageSearchResult();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "CLIP/Qdrant image search failed for {FileName}", fileName);
            return EmptyImageSearchResult();
        }
    }

    private static object EmptyImageSearchResult() => new
    {
        detectedProductName = string.Empty,
        detectedBrand = string.Empty,
        suggestedNames = Array.Empty<string>(),
        count = 0,
        items = Array.Empty<object>(),
        referenceMatches = Array.Empty<object>(),
        referenceCount = 0,
        referenceScores = Array.Empty<object>(),
        searchMode = "clip-qdrant",
        products = EmptySuggestedNamesSearch([])
    };

    private static object EmptySuggestedNamesSearch(IReadOnlyList<string> names) => new
    {
        searchNames = names,
        searchTokens = Array.Empty<string>(),
        count = 0,
        items = Array.Empty<object>()
    };
}
