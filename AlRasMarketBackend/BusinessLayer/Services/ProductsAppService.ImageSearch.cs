using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
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
        await ExpireDueListingsAsync(cancellationToken);

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
        var nameTranslations = await dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId != null
                && productIds.Contains(t.ProductId.Value)
                && t.Field == ContentTranslationFields.Name)
            .Select(t => new { ProductId = t.ProductId!.Value, t.TextAr, t.TextEn })
            .ToListAsync(cancellationToken)
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

        var items = await BuildPublicProductListItemsAsync(ranked, cancellationToken);

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
    private async Task<List<PublicProductQueryRow>> SearchCatalogByProductNameAnyAsync(
        IReadOnlyList<string> words,
        int take,
        CancellationToken cancellationToken)
    {
        var productsQuery = ApplyPublicProductFilter(dbContext.Products.AsNoTracking());

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

        HashSet<Guid> candidateIds = [];
        foreach (var word in uniqueWords)
        {
            var containsPattern = ToSqlLikePattern(word);

            var fromProducts = await productsQuery
                .Where(x => EF.Functions.Like(x.NameEn ?? string.Empty, containsPattern))
                .Select(x => x.ProductId)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var fromNameTranslations = await (
                    from t in dbContext.ContentTranslations.AsNoTracking()
                    join p in productsQuery on t.ProductId equals p.ProductId
                    where t.Scope == ContentTranslationScopes.Product
                          && t.ProductId != null
                          && t.Field == ContentTranslationFields.Name
                          && (EF.Functions.Like(t.TextAr ?? string.Empty, containsPattern)
                              || EF.Functions.Like(t.TextEn ?? string.Empty, containsPattern))
                    select t.ProductId!.Value)
                .Distinct()
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            foreach (var id in fromProducts.Concat(fromNameTranslations))
            {
                candidateIds.Add(id);
            }
        }

        if (candidateIds.Count == 0)
        {
            return [];
        }

        var candidateRows = await productsQuery
            .Where(x => candidateIds.Contains(x.ProductId))
            .Select(x => new { x.ProductId, x.NameEn })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var nameTranslationRows = await dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId != null
                && candidateIds.Contains(t.ProductId.Value)
                && t.Field == ContentTranslationFields.Name)
            .Select(t => new { ProductId = t.ProductId!.Value, t.TextAr, t.TextEn })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var translationsByProduct = nameTranslationRows
            .GroupBy(t => t.ProductId)
            .ToDictionary(g => g.Key, g => g.ToList());

        var wholeWordIds = new HashSet<Guid>();
        foreach (var row in candidateRows)
        {
            translationsByProduct.TryGetValue(row.ProductId, out var trs);
            var haystacks = new List<string?> { row.NameEn };
            if (trs is not null)
            {
                foreach (var tr in trs)
                {
                    haystacks.Add(tr.TextAr);
                    haystacks.Add(tr.TextEn);
                }
            }

            if (uniqueWords.Any(word => haystacks.Any(h => ContainsWholeWord(h, word))))
            {
                wholeWordIds.Add(row.ProductId);
            }
        }

        if (wholeWordIds.Count == 0)
        {
            return [];
        }

        return await SelectPublicProductRows(productsQuery.Where(x => wholeWordIds.Contains(x.ProductId)))
            .OrderByDescending(x => x.CreatedAt)
            .Take(take)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);
    }

    public async Task<object> DetectProductsFromImageAsync(Stream imageStream, string fileName, CancellationToken cancellationToken = default)
    {
        await using var buffered = new MemoryStream();
        await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
        if (buffered.Length == 0)
        {
            return EmptyImageSearchResult();
        }

        // Primary path: catalog-local vector search (Qdrant HNSW) against ads you indexed.
        try
        {
            buffered.Position = 0;
            var vector = await imageEmbeddingService
                .EmbedImageAsync(buffered, fileName, cancellationToken: cancellationToken)
                .ConfigureAwait(false);

            if (vector is { Length: > 0 })
            {
                var hits = await productImageVectorIndex
                    .SearchSimilarAsync(vector, cancellationToken)
                    .ConfigureAwait(false);

                // CLIP answered — never fall through to vision name-search (returns wrong ads).
                if (hits.Count == 0)
                {
                    logger.LogInformation(
                        "CLIP image search found no confident matches for {FileName}",
                        fileName);
                    return EmptyImageSearchResult();
                }

                if (hits.Count > 0)
                {
                    var orderedIds = hits
                        .GroupBy(h => h.ProductId)
                        .Select(g => new { ProductId = g.Key, Score = g.Max(x => x.Score) })
                        .OrderByDescending(x => x.Score)
                        .Select(x => x.ProductId)
                        .ToList();

                    var rows = await SelectPublicProductRows(
                            dbContext.Products.AsNoTracking().Where(p => orderedIds.Contains(p.ProductId)))
                        .ToListAsync(cancellationToken)
                        .ConfigureAwait(false);

                    var byId = rows.ToDictionary(x => x.ProductId);
                    var ranked = orderedIds
                        .Where(byId.ContainsKey)
                        .Select(id => byId[id])
                        .ToList();

                    var items = await BuildPublicProductListItemsAsync(ranked, cancellationToken)
                        .ConfigureAwait(false);

                    var topName = hits
                        .Select(h => h.ProductName)
                        .FirstOrDefault(n => !string.IsNullOrWhiteSpace(n))
                        ?? string.Empty;

                    return new
                    {
                        detectedProductName = topName,
                        detectedBrand = string.Empty,
                        suggestedNames = hits
                            .Select(h => h.ProductName)
                            .Where(n => !string.IsNullOrWhiteSpace(n))
                            .Distinct(StringComparer.OrdinalIgnoreCase)
                            .Take(8)
                            .ToList(),
                        count = items.Count,
                        items,
                        scores = hits
                            .GroupBy(h => h.ProductId)
                            .Select(g => new
                            {
                                productId = g.Key,
                                score = g.Max(x => x.Score)
                            })
                            .OrderByDescending(x => x.score)
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
            }
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("Vector image search timed out for {FileName}", fileName);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Vector image search failed for {FileName}; falling back to vision names", fileName);
        }

        // Fallback (empty catalog / Qdrant down): previous vision → name search.
        buffered.Position = 0;
        ImageProductVisionResult vision;
        try
        {
            vision = await openAiVisionService
                .SuggestProductNamesFromImageAsync(buffered, fileName, cancellationToken)
                .ConfigureAwait(false);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning("Image search timed out for {FileName}", fileName);
            return EmptyImageSearchResult();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Image search vision failed for {FileName}", fileName);
            return EmptyImageSearchResult();
        }

        var searchNames = vision.SearchNames?.ToList() ?? [];
        if (searchNames.Count == 0)
        {
            searchNames = vision.FallbackNames?.ToList() ?? [];
        }

        object searchResult;
        if (searchNames.Count == 0)
        {
            searchResult = EmptySuggestedNamesSearch(searchNames);
        }
        else
        {
            searchResult = await SearchBySuggestedNamesAsync(searchNames, cancellationToken)
                .ConfigureAwait(false);

            var countAfterDetect = ReadSearchCount(searchResult);
            if (countAfterDetect == 0
                && vision.HasDetectedProductName
                && vision.FallbackNames is { Count: > 0 })
            {
                searchResult = await SearchBySuggestedNamesAsync(vision.FallbackNames, cancellationToken)
                    .ConfigureAwait(false);
                searchNames = vision.FallbackNames.ToList();
            }
        }

        var resultType = searchResult.GetType();
        var itemsFallback = resultType.GetProperty("items")?.GetValue(searchResult) as IEnumerable<object>
            ?? Array.Empty<object>();
        var count = ReadSearchCount(searchResult);
        if (count < 0)
        {
            count = itemsFallback.Count();
        }

        var suggestedForClient = new List<string>();
        if (!string.IsNullOrWhiteSpace(vision.DetectedProductName))
        {
            suggestedForClient.Add(vision.DetectedProductName.Trim());
        }

        if (!string.IsNullOrWhiteSpace(vision.DetectedBrand))
        {
            suggestedForClient.Add(vision.DetectedBrand.Trim());
        }

        if (suggestedForClient.Count == 0)
        {
            suggestedForClient.AddRange(searchNames);
        }

        return new
        {
            detectedProductName = vision.DetectedProductName ?? string.Empty,
            detectedBrand = vision.DetectedBrand ?? string.Empty,
            suggestedNames = suggestedForClient
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(8)
                .ToList(),
            count,
            items = itemsFallback,
            searchMode = "vision-fallback",
            products = searchResult
        };
    }

    private static object EmptyImageSearchResult() => new
    {
        detectedProductName = string.Empty,
        detectedBrand = string.Empty,
        suggestedNames = Array.Empty<string>(),
        count = 0,
        items = Array.Empty<object>(),
        products = EmptySuggestedNamesSearch([])
    };

    private static object EmptySuggestedNamesSearch(IReadOnlyList<string> names) => new
    {
        searchNames = names,
        searchTokens = Array.Empty<string>(),
        count = 0,
        items = Array.Empty<object>()
    };

    private static int ReadSearchCount(object searchResult)
    {
        var countObj = searchResult.GetType().GetProperty("count")?.GetValue(searchResult);
        return countObj is int c ? c : -1;
    }
}
