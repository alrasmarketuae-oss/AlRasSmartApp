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
    public async Task<object> GetAllAsync(GetProductsInput input, CancellationToken cancellationToken = default)
    {
        var (page, pageSize) = NormalizePaging(input.Page, input.PageSize);

        var cacheKey = $"{AllProductsCacheKey}:v{AllProductsCacheVersion}:p{page}:s{pageSize}";

        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var skip = (page - 1) * pageSize;

        var (products, totalCount) = await productData.GetHomeCatalogPageAsync(skip, pageSize, cancellationToken);

        var result = await BuildPublicProductListPageAsync(
            products,
            totalCount,
            page,
            pageSize,
            cancellationToken,
            includeRetailFields: false);

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);

        return result;
    }

    public async Task<object> SearchAsync(SearchProductsInput input, CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        var queryText = NormalizeSearchQuery(input.Query);
        var (page, pageSize) = NormalizePaging(input.Page, input.PageSize);

        if (ProductCodeGenerator.TryNormalize(queryText, out var productCode))
        {
            var codeCacheKey =
                $"{SearchProductsCachePrefix}code:{productCode}:v{SearchProductsCacheVersion}:p{page}:s{pageSize}";
            var codeCached = await TryGetProductCacheAsync(codeCacheKey, cancellationToken);
            if (codeCached is not null)
            {
                return codeCached;
            }

            var codeProducts = await productData.GetPublicProductsByCodeAsync(
                productCode,
                (page - 1) * pageSize,
                pageSize,
                cancellationToken);

            var matchedRetailCode = codeProducts.Any(p =>
                string.Equals(p.RetailCode, productCode, StringComparison.OrdinalIgnoreCase));

            // RetailCode → retail channel only. ProductCode → both hybrid cards.
            var codeResult = matchedRetailCode
                ? await BuildPublicProductListPageAsync(
                    codeProducts,
                    codeProducts.Count,
                    page,
                    pageSize,
                    cancellationToken,
                    projectRetailAsPrimary: true,
                    includeRetailFields: true,
                    expandHybridSearchChannels: false)
                : await BuildPublicProductListPageAsync(
                    codeProducts,
                    codeProducts.Count,
                    page,
                    pageSize,
                    cancellationToken,
                    expandHybridSearchChannels: true);

            await SetProductCacheAsync(codeCacheKey, codeResult, TimeSpan.FromMinutes(2), cancellationToken);
            return codeResult;
        }

        var cacheKey = $"{SearchProductsCachePrefix}{queryText.ToLowerInvariant()}:v{SearchProductsCacheVersion}:p{page}:s{pageSize}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        // Meilisearch typo-tolerance finds IDs; SQL/Redis hydrate lightweight cards.
        // No synchronous OpenAI on the search hot path.
        var catalog = await SearchCatalogPreferMeiliAsync(queryText, page, pageSize, cancellationToken);

        // Soft name LIKE when Meili+strict SQL miss — only for longer queries.
        if (page == 1 && catalog.TotalCount == 0 && queryText.Trim().Length >= 4)
        {
            var (looseProducts, looseTotal) =
                await SearchCatalogByNameLooseAsync(queryText, page, pageSize, cancellationToken);
            catalog = new CatalogSearchHitPage(looseProducts, looseTotal, null, false);
        }

        if (page == 1 && catalog.TotalCount == 0)
        {
            await LogMissedProductSearchAsync(
                queryText,
                input.SearcherUserId,
                "No catalog hits after Meilisearch typo-tolerance + SQL fallback.",
                cancellationToken);

            var empty = await BuildTypoAssistEmptySearchAsync(
                queryText,
                pageSize,
                correctedQuery: null,
                wasMisspelled: false,
                cancellationToken);

            // Empty pages are not cached so a later index sync can surface new ads quickly.
            return empty;
        }

        var items = await BuildSearchProductCardItemsAsync(
            catalog.Products,
            cancellationToken);

        object result;
        if (catalog.WasMisspelled && !string.IsNullOrWhiteSpace(catalog.CorrectedQuery))
        {
            result = new
            {
                count = items.Count,
                totalCount = catalog.TotalCount,
                page,
                pageSize,
                totalPages = catalog.TotalCount == 0
                    ? 0
                    : (int)Math.Ceiling(catalog.TotalCount / (double)pageSize),
                items,
                aiAssist = new
                {
                    applied = true,
                    wasMisspelled = true,
                    originalQuery = queryText,
                    correctedQuery = catalog.CorrectedQuery,
                    status = "corrected",
                    messageAr = $"ربما قصدت «{catalog.CorrectedQuery}». عرضنا النتائج بناءً على التصحيح.",
                    messageEn =
                        $"Did you mean \"{catalog.CorrectedQuery}\"? Showing results for the corrected name."
                }
            };
        }
        else
        {
            result = new
            {
                count = items.Count,
                totalCount = catalog.TotalCount,
                page,
                pageSize,
                totalPages = catalog.TotalCount == 0
                    ? 0
                    : (int)Math.Ceiling(catalog.TotalCount / (double)pageSize),
                items
            };
        }

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    private sealed record CatalogSearchHitPage(
        List<ProductPublicRow> Products,
        int TotalCount,
        string? CorrectedQuery,
        bool WasMisspelled);

    private async Task<CatalogSearchHitPage> SearchCatalogPreferMeiliAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        if (productTextSearchIndex.IsEnabled)
        {
            try
            {
                var meili = await SearchCatalogViaMeiliAsync(queryText, page, pageSize, cancellationToken);
                if (meili.TotalCount > 0 || meili.Products.Count > 0)
                {
                    return meili;
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Meilisearch product search failed; falling back to SQL for {Query}", queryText);
            }
        }

        var (sqlProducts, sqlTotal) =
            await SearchCatalogByTextAsync(queryText, page, pageSize, cancellationToken);
        return new CatalogSearchHitPage(sqlProducts, sqlTotal, null, false);
    }

    /// <summary>
    /// Meili ranks IDs (typo-tolerant); hydrate from SQL in Meili order (Dictionary reorder in memory).
    /// </summary>
    private async Task<CatalogSearchHitPage> SearchCatalogViaMeiliAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var tokens = queryText
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(t => !IsSearchStopToken(t))
            .ToList();
        if (tokens.Count == 0)
        {
            return new CatalogSearchHitPage([], 0, null, false);
        }

        // Synonyms live on the Meili index — do not expand into the query string.
        var meiliQuery = string.Join(' ', tokens);
        var hitPage = await productTextSearchIndex.SearchAsync(
            meiliQuery,
            limit: Math.Max(page * pageSize, 100),
            cancellationToken);

        if (hitPage.Hits.Count == 0)
        {
            return new CatalogSearchHitPage([], 0, null, false);
        }

        var (wasMisspelled, correctedQuery) = DetectMeiliTypoAssist(queryText, hitPage.Hits);

        var orderedIds = hitPage.Hits
            .Select(h => h.ProductId)
            .Distinct()
            .ToList();

        // Batch IN via TVP (ADO) — no EF change-tracker overhead.
        var rows = await productData.GetProductsByIdsAsync(orderedIds, cancellationToken);
        var byId = rows.ToDictionary(x => x.ProductId);

        // Keep Meilisearch relevance order; do not re-sort by CreatedAt in SQL/memory.
        var publicOrdered = orderedIds
            .Where(byId.ContainsKey)
            .Select(id => byId[id])
            .Where(p =>
                (p.Status == ProductCatalogCodes.StatusActive
                    || (p.Status == ProductCatalogCodes.StatusUnderReview && p.IsApproved == true))
                && (p.ProductTypeId != ProductCatalogCodes.TypeRequests || p.Quantity > 0))
            .ToList();

        var totalCount = publicOrdered.Count;
        if (hitPage.EstimatedTotal > totalCount && orderedIds.Count >= Math.Max(page * pageSize, 100))
        {
            totalCount = hitPage.EstimatedTotal;
        }

        var skip = (page - 1) * pageSize;
        var pageRows = publicOrdered.Skip(skip).Take(pageSize).ToList();
        return new CatalogSearchHitPage(pageRows, totalCount, correctedQuery, wasMisspelled);
    }

    /// <summary>
    /// Infer "did you mean" from Meili typo hits without calling OpenAI.
    /// </summary>
    private static (bool WasMisspelled, string? CorrectedQuery) DetectMeiliTypoAssist(
        string originalQuery,
        IReadOnlyList<ProductTextSearchHit> hits)
    {
        if (hits.Count == 0)
        {
            return (false, null);
        }

        var query = (originalQuery ?? string.Empty).Trim();
        if (query.Length < 2)
        {
            return (false, null);
        }

        string? bestLabel = null;
        var bestDistance = int.MaxValue;

        foreach (var hit in hits.Take(5))
        {
            foreach (var candidate in new[] { hit.NameAr, hit.NameEn, hit.ProductCode })
            {
                var label = candidate?.Trim();
                if (string.IsNullOrWhiteSpace(label))
                {
                    continue;
                }

                if (string.Equals(query, label, StringComparison.OrdinalIgnoreCase))
                {
                    return (false, null);
                }

                if (!IsPlausibleSpellingCorrection(query, label))
                {
                    continue;
                }

                var distance = LevenshteinDistance(
                    query.ToLowerInvariant(),
                    label.ToLowerInvariant());
                if (distance < bestDistance)
                {
                    bestDistance = distance;
                    bestLabel = label;
                }
            }
        }

        return bestLabel is null ? (false, null) : (true, bestLabel);
    }

    private async Task<(List<ProductPublicRow> Products, int TotalCount)> SearchCatalogByTextAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var tokens = queryText
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(t => !IsSearchStopToken(t))
            .ToList();

        if (tokens.Count == 0)
        {
            return ([], 0);
        }

        var tokenWordGroups = new List<IReadOnlyList<string>>();
        foreach (var token in tokens)
        {
            var words = new List<string> { token };
            words.AddRange(ResolveSearchSynonyms(token));
            var uniqueWords = words
                .Select(w => w.Trim())
                .Where(w => !string.IsNullOrWhiteSpace(w))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(6)
                .ToList();
            if (uniqueWords.Count == 0)
            {
                return ([], 0);
            }

            tokenWordGroups.Add(uniqueWords);
        }

        return await productData.SearchPublicCatalogByTokenWordsAsync(
            tokenWordGroups,
            page,
            pageSize,
            cancellationToken);
    }

    public async Task<object> SuggestSearchAsync(
        string query,
        int limit = 8,
        CancellationToken cancellationToken = default)
    {
        var q = (query ?? string.Empty).Trim();
        if (q.Length < 1)
        {
            return new { suggestions = Array.Empty<string>() };
        }

        var take = Math.Clamp(limit <= 0 ? 8 : limit, 1, 20);

        if (productTextSearchIndex.IsEnabled)
        {
            try
            {
                var suggestions = await productTextSearchIndex.SuggestAsync(q, take, cancellationToken);
                return new { suggestions };
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Meilisearch suggest failed for {Query}", q);
                // Fall through to SQL only when Meili throws.
            }
        }

        // SQL fallback — only when Meili is disabled or errored (not for empty hits).
        var index = await productData.GetSearchNameIndexAsync(cancellationToken);
        var fallback = index.Names
            .Concat(index.ProductCodes)
            .Where(name => name.Contains(q, StringComparison.OrdinalIgnoreCase))
            .Take(take)
            .ToList();

        return new { suggestions = fallback };
    }

    /// <summary>
    /// Lenient name search: substring match on NameEn / translations when strict search returns 0.
    /// </summary>
    private Task<(List<ProductPublicRow> Products, int TotalCount)> SearchCatalogByNameLooseAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken) =>
        productData.SearchPublicCatalogByNameLooseAsync(queryText, page, pageSize, cancellationToken);

    private Task<object> BuildTypoAssistEmptySearchAsync(
        string originalQuery,
        int pageSize,
        string? correctedQuery,
        bool wasMisspelled,
        CancellationToken cancellationToken)
    {
        _ = cancellationToken;
        var hasSuggestion = wasMisspelled && !string.IsNullOrWhiteSpace(correctedQuery);
        return Task.FromResult<object>(new
        {
            count = 0,
            totalCount = 0,
            page = 1,
            pageSize,
            totalPages = 0,
            items = Array.Empty<object>(),
            aiAssist = new
            {
                applied = true,
                wasMisspelled,
                originalQuery,
                correctedQuery = hasSuggestion ? correctedQuery : null,
                status = hasSuggestion ? "corrected" : "not_in_catalog",
                messageAr = hasSuggestion
                    ? $"لا يتوفر لدينا حالياً منتج باسم «{originalQuery}». هل قصدت «{correctedQuery}»؟ اضغط للاقتراح إن رغبت بالبحث عنه."
                    : $"لا يتوفر لدينا حالياً منتج باسم «{originalQuery}»، لكن تم أخذ طلبك في الاعتبار. حاول البحث عنه بعد ساعة وسنحاول توفيره.",
                messageEn = hasSuggestion
                    ? $"We currently do not have \"{originalQuery}\". Did you mean \"{correctedQuery}\"? Tap the suggestion if you want to search it."
                    : $"We currently do not have \"{originalQuery}\", but your request was noted. Please try searching again in about an hour and we will try to stock it."
            }
        });
    }

    private async Task LogMissedProductSearchAsync(
        string queryText,
        string? searcherUserId,
        string? notes,
        CancellationToken cancellationToken)
    {
        try
        {
            Guid? userId = null;
            string? displayName = null;
            string? email = null;
            string? phone = null;

            if (Guid.TryParse(searcherUserId, out var parsedUserId))
            {
                userId = parsedUserId;
                var user = await productData.GetUserByIdAsync(parsedUserId, tracked: false, cancellationToken);
                if (user is not null)
                {
                    displayName = string.IsNullOrWhiteSpace(user.FullName) ? null : user.FullName.Trim();
                    email = string.IsNullOrWhiteSpace(user.Email) ? null : user.Email.Trim();
                    phone = string.IsNullOrWhiteSpace(user.PhoneNumber) ? null : user.PhoneNumber.Trim();
                }
            }

            await productData.TryAddMissedProductSearchAsync(
                new MissedProductSearchInsert
                {
                    Query = queryText,
                    UserId = userId,
                    UserDisplayName = displayName,
                    UserEmail = email,
                    UserPhone = phone,
                    Notes = notes
                },
                cancellationToken);
            MissedProductSearchAppService.InvalidateListCache();
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to log missed product search for query {Query}", queryText);
        }
    }

    public async Task<object> GetByCodeAsync(string productCode, CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        if (!ProductCodeGenerator.TryNormalize(productCode, out var normalizedCode))
        {
            throw new ArgumentException("Invalid product code.");
        }

        var cacheKey = $"{ProductByCodeCachePrefix}v{ProductDetailCacheVersion}:{normalizedCode}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var product = await productData.GetPublicProductByCodeExactAsync(normalizedCode, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        var matchedRetailCode = string.Equals(
            product.RetailCode,
            normalizedCode,
            StringComparison.OrdinalIgnoreCase);

        var items = await BuildPublicProductListItemsAsync(
            [product],
            cancellationToken,
            projectRetailAsPrimary: matchedRetailCode
                || (ProductTypeCodes.IsRetail(product.ProductTypeId)
                    && !ProductTypeCodes.IsCategoryProduct(product.CategoryId, product.ProductTypeId)),
            includeRetailFields: true);
        var result = new
        {
            productCode = normalizedCode,
            searchListingChannel = matchedRetailCode ? "retail" : (string?)null,
            item = items.FirstOrDefault()
        };

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    public async Task<object> GetByIdAsync(
        string productId,
        bool asRetail = false,
        CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        if (!Guid.TryParse(productId, out var parsedId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var cacheKey = $"{ProductByIdCachePrefix}v{ProductDetailCacheVersion}:{(asRetail ? "r" : "w")}:{parsedId:D}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var product = await productData.GetPublicProductByIdAsync(parsedId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        // Wholesale/home: category hybrids keep base price. Retail feed: project
        // retail as primary so Add to Cart shows the retail unit/price.
        var projectRetail = asRetail
            ? (ProductTypeCodes.IsRetail(product.ProductTypeId)
                || product.RetailPrice.HasValue
                || product.RetailQuantity.HasValue)
            : (ProductTypeCodes.IsRetail(product.ProductTypeId)
                && !ProductTypeCodes.IsCategoryProduct(product.CategoryId, product.ProductTypeId));

        var items = await BuildPublicProductListItemsAsync(
            [product],
            cancellationToken,
            projectRetailAsPrimary: projectRetail,
            includeRetailFields: true);
        var result = new
        {
            productId = parsedId.ToString("D"),
            item = items.FirstOrDefault()
        };

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    public async Task<object> GetSearchNameIndexAsync(CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        var cacheKey = $"products:search-name-index:v{SearchNameIndexCacheVersion}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var index = await productData.GetSearchNameIndexAsync(cancellationToken);
        var result = new
        {
            totalCount = index.Names.Count + index.ProductCodes.Count,
            names = index.Names,
            productCodes = index.ProductCodes,
        };

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(30), cancellationToken);
        return result;
    }

    public async Task<object> GetByTypeAsync(GetProductsByTypeInput input, CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(input.ProductTypeName))
        {
            throw new ArgumentException("ProductTypeName is required.");
        }

        var normalizedType = input.ProductTypeName.Trim().ToLowerInvariant();
        var (page, pageSize) = NormalizePaging(input.Page, input.PageSize);
        var cacheKey = $"{ProductsByTypeCachePrefix}{normalizedType}:v{ByTypeProductsCacheVersion}:p{page}:s{pageSize}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var productType = await productData.GetProductTypeByNameAsync(normalizedType, cancellationToken)
            ?? throw new KeyNotFoundException($"Product type '{input.ProductTypeName}' was not found.");

        var isRetailType = ProductTypeCodes.IsRetail(productType.Id);
        var (products, totalCount) = await productData.GetProductsByTypePageAsync(
            productType.Id,
            isRetailType,
            (page - 1) * pageSize,
            pageSize,
            cancellationToken);

        var items = await BuildPublicProductListItemsAsync(
            products,
            cancellationToken,
            projectRetailAsPrimary: isRetailType);

        var result = new
        {
            productType = productType.TypeNameEn,
            productTypeId = productType.Id,
            count = items.Count,
            totalCount,
            page,
            pageSize,
            totalPages = totalCount == 0 ? 0 : (int)Math.Ceiling(totalCount / (double)pageSize),
            items
        };

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    public async Task<object> GetByCategoryAsync(GetProductsByCategoryInput input, CancellationToken cancellationToken = default)
    {
        if (input.CategoryId == 0)
        {
            throw new ArgumentException("CategoryId is required.");
        }

        var (page, pageSize) = NormalizePaging(input.Page, input.PageSize);
        var cacheKey =
            $"{ProductsByCategoryCachePrefix}{input.CategoryId}:v{ByCategoryProductsCacheVersion}:p{page}:s{pageSize}:pub{input.PublicCatalog}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var category = await productData.GetCategoryByIdAsync(input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException($"Category '{input.CategoryId}' was not found.");

        var (products, totalCount) = input.PublicCatalog
            ? await productData.GetPublicProductsByCategoryPageAsync(
                category.CategoryId,
                (page - 1) * pageSize,
                pageSize,
                cancellationToken)
            : await productData.GetProductsByCategoryPageAsync(
                category.CategoryId,
                (page - 1) * pageSize,
                pageSize,
                cancellationToken);

        var items = await BuildPublicProductListItemsAsync(
            products,
            cancellationToken,
            includeRetailFields: input.PublicCatalog,
            expandHybridSearchChannels: input.PublicCatalog);

        var result = new
        {
            categoryId = category.CategoryId,
            categoryName = category.NameEn,
            count = items.Count,
            totalCount,
            page,
            pageSize,
            totalPages = totalCount == 0 ? 0 : (int)Math.Ceiling(totalCount / (double)pageSize),
            items
        };

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    public async Task<object> GetFeaturedAsync(GetProductsInput input, CancellationToken cancellationToken = default)
    {
        await ExpireDueListingsAsync(cancellationToken);

        var (page, pageSize) = NormalizePaging(input.Page, input.PageSize);
        var cacheKey = $"{FeaturedProductsCacheKey}:v{FeaturedProductsCacheVersion}:p{page}:s{pageSize}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var (products, totalCount) = await productData.GetFeaturedProductsPageAsync(
            (page - 1) * pageSize,
            pageSize,
            cancellationToken);

        var result = await BuildPublicProductListPageAsync(
            products,
            totalCount,
            page,
            pageSize,
            cancellationToken);

        await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        return result;
    }

    public async Task<object> IncreaseViewsAsync(string productId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await productData.GetProductByIdTrackedAsync(parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        product.ViewsCount += 1;
        await productData.SaveChangesAsync(cancellationToken);

        productCacheVersions.BumpListViews();

        return new
        {
            productId = product.ProductId,
            viewsCount = product.ViewsCount
        };
    }
}
