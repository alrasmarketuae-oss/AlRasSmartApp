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

        var ranked = await RankCatalogProductsByDetectedNamesAsync(
            hits,
            names,
            tokens,
            cancellationToken).ConfigureAwait(false);

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
            .Take(24)
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
    /// When listing photos are missing, search by CLIP/reference labels (not OpenAI guessing).
    /// </summary>
    public async Task<object> DetectProductsFromImageAsync(
        Stream imageStream,
        string fileName,
        CancellationToken cancellationToken = default,
        int page = 1,
        int pageSize = 20,
        string? searcherUserId = null)
    {
        var (normalizedPage, normalizedPageSize) = NormalizePaging(page, pageSize);
        var skip = (normalizedPage - 1) * normalizedPageSize;

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
            var catalogAudience = await ResolveCatalogSearchAudienceAsync(
                searcherUserId,
                cancellationToken);

            var ranked = orderedIds
                .Where(byId.ContainsKey)
                .Select(id => byId[id])
                .ToList();
            ranked = FilterCatalogRowsForAudience(ranked, catalogAudience);

            var items = ranked.Count > 0
                ? await BuildPublicProductListItemsAsync(
                        ranked,
                        cancellationToken,
                        expandHybridSearchChannels: true,
                        catalogAudience: catalogAudience)
                    .ConfigureAwait(false)
                : [];
            var totalCount = ranked.Count;
            byte? detectedCategoryId = null;

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

            var suggestedNames = hits
                .Select(h => h.ProductName)
                .Concat(suggestedFromReferences)
                .Where(n => !string.IsNullOrWhiteSpace(n))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(8)
                .ToList();

            var searchMode = "clip-qdrant";
            IReadOnlyList<string> fallbackSearchNames = Array.Empty<string>();
            IReadOnlyList<string> fallbackSearchTokens = Array.Empty<string>();

            // CLIP reference labels (e.g. Cardamom / الهيل) expand the catalog only when
            // no listing photo was close enough. Otherwise visual matches win — a photo
            // from the same ad must not be replaced by the whole الهيل category.
            if (ranked.Count == 0 && suggestedNames.Count > 0)
            {
                var (fallbackRows, fallbackTotal, fallbackMode, fallbackNames, fallbackTokens, categoryId) =
                    await ResolveCatalogFromClipLabelsAsync(
                            suggestedNames,
                            fileName,
                            skip,
                            normalizedPageSize,
                            cancellationToken)
                        .ConfigureAwait(false);
                if (fallbackTotal > 0)
                {
                    ranked = fallbackRows;
                    ranked = FilterCatalogRowsForAudience(ranked, catalogAudience);
                    items = await BuildPublicProductListItemsAsync(
                            ranked,
                            cancellationToken,
                            expandHybridSearchChannels: true,
                            catalogAudience: catalogAudience)
                        .ConfigureAwait(false);
                    totalCount = fallbackTotal;
                    searchMode = fallbackMode;
                    fallbackSearchNames = fallbackNames;
                    fallbackSearchTokens = fallbackTokens;
                    detectedCategoryId = categoryId;
                }
            }

            if (searchMode == "clip-qdrant")
            {
                totalCount = ranked.Count;
                ranked = ranked.Skip(skip).Take(normalizedPageSize).ToList();
                items = ranked.Count > 0
                    ? await BuildPublicProductListItemsAsync(
                            ranked,
                            cancellationToken,
                            expandHybridSearchChannels: true,
                            catalogAudience: catalogAudience)
                        .ConfigureAwait(false)
                    : [];
            }

            return new
            {
                detectedProductName = topName,
                detectedBrand = string.Empty,
                detectedCategoryId,
                suggestedNames,
                count = items.Count,
                totalCount,
                page = normalizedPage,
                pageSize = normalizedPageSize,
                totalPages = totalCount == 0
                    ? 0
                    : (int)Math.Ceiling(totalCount / (double)normalizedPageSize),
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
                searchMode,
                products = new
                {
                    searchNames = fallbackSearchNames,
                    searchTokens = fallbackSearchTokens,
                    count = items.Count,
                    totalCount,
                    page = normalizedPage,
                    pageSize = normalizedPageSize,
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

    private async Task<List<ProductPublicRow>> RankCatalogProductsByDetectedNamesAsync(
        List<ProductPublicRow> hits,
        IReadOnlyList<string> names,
        IReadOnlyList<string> tokens,
        CancellationToken cancellationToken)
    {
        var productIds = hits.Select(x => x.ProductId).ToList();
        var nameTranslations = await productData
            .GetProductNameTranslationsByProductIdsAsync(productIds, cancellationToken)
            .ConfigureAwait(false);

        var namesByProduct = nameTranslations
            .GroupBy(t => t.ProductId)
            .ToDictionary(g => g.Key, g => g.ToList());

        return hits
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
            .Select(x => x.Product)
            .ToList();
    }

    /// <summary>
    /// When CLIP/reference photos label the image (e.g. cardamom) but no listing
    /// photos are close enough in Qdrant, search the public catalog by that label
    /// and then by matching category.
    /// </summary>
    private async Task<(
        List<ProductPublicRow> Rows,
        int TotalCount,
        string SearchMode,
        IReadOnlyList<string> SearchNames,
        IReadOnlyList<string> SearchTokens,
        byte? CategoryId)> ResolveCatalogFromClipLabelsAsync(
        IReadOnlyList<string> suggestedNames,
        string fileName,
        int skip,
        int take,
        CancellationToken cancellationToken)
    {
        var names = suggestedNames
            .Select(x => x?.Trim() ?? string.Empty)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(12)
            .ToList();

        var tokens = BuildImageSearchTokens(names);
        logger.LogInformation(
            "CLIP labeled {Names} from {FileName}; loading the full matching catalog (skip {Skip}, take {Take}).",
            string.Join(", ", names),
            fileName,
            skip,
            take);

        var page = take <= 0 ? 1 : (skip / take) + 1;
        var category = await ResolveCategoryFromDetectedNamesAsync(
            names.Concat(tokens).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            cancellationToken)
            .ConfigureAwait(false);
        if (category is not null)
        {
            var (categoryRows, categoryTotal) = await productData
                .GetPublicProductsByCategoryPageAsync(category.CategoryId, skip, take, cancellationToken)
                .ConfigureAwait(false);
            if (categoryTotal > 0)
            {
                logger.LogInformation(
                    "Image search catalog: category {CategoryId} {CategoryName} has {Total} public listings.",
                    category.CategoryId,
                    category.NameEn,
                    categoryTotal);
                return (categoryRows, categoryTotal, "clip-category", names, tokens, category.CategoryId);
            }
        }

        var searchQuery = names[0];
        var meili = await SearchCatalogPreferMeiliAsync(searchQuery, page, take, cancellationToken)
            .ConfigureAwait(false);
        if (meili.TotalCount > 0 || meili.Products.Count > 0)
        {
            return (meili.Products, meili.TotalCount, "clip-name", names, tokens, category?.CategoryId);
        }

        if (tokens.Count > 0)
        {
            var (nameRows, nameTotal) = await productData
                .SearchPublicProductsByNameAnyPageAsync(tokens, skip, take, cancellationToken)
                .ConfigureAwait(false);
            if (nameTotal > 0)
            {
                return (nameRows, nameTotal, "clip-name", names, tokens, category?.CategoryId);
            }
        }

        return ([], 0, "clip-qdrant", names, tokens, category?.CategoryId);
    }

    private static object EmptyImageSearchResult() => new
    {
        detectedProductName = string.Empty,
        detectedBrand = string.Empty,
        detectedCategoryId = (byte?)null,
        suggestedNames = Array.Empty<string>(),
        count = 0,
        totalCount = 0,
        page = 1,
        pageSize = 20,
        totalPages = 0,
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
