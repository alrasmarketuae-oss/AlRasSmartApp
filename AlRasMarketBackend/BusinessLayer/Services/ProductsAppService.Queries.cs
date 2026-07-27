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

            var codeResult = await BuildPublicProductListPageAsync(
                codeProducts,
                codeProducts.Count,
                page,
                pageSize,
                cancellationToken);

            await SetProductCacheAsync(codeCacheKey, codeResult, TimeSpan.FromMinutes(2), cancellationToken);
            return codeResult;
        }

        var cacheKey = $"{SearchProductsCachePrefix}{queryText.ToLowerInvariant()}:v{SearchProductsCacheVersion}:p{page}:s{pageSize}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var (products, totalCount) = await SearchCatalogByTextAsync(queryText, page, pageSize, cancellationToken);

        // Strict whole-word can miss real catalog names (esp. Arabic/English mixes).
        // Soft name LIKE before AI — only for queries long enough to avoid كو∈كوكو noise.
        if (page == 1 && totalCount == 0 && queryText.Trim().Length >= 4)
        {
            (products, totalCount) =
                await SearchCatalogByNameLooseAsync(queryText, page, pageSize, cancellationToken);
        }

        // AI spelling assist: only when the first page has no catalog hits.
        if (page == 1 && totalCount == 0)
        {
            var assisted = await TryApplyAiSearchAssistAsync(
                queryText,
                page,
                pageSize,
                input.SearcherUserId,
                cancellationToken);
            if (assisted is not null)
            {
                return assisted;
            }
        }

        var result = await BuildPublicProductListPageAsync(products, totalCount, page, pageSize, cancellationToken);

        // Do not cache empty pages so AI assist can still run on the next request.
        if (totalCount > 0)
        {
            await SetProductCacheAsync(cacheKey, result, TimeSpan.FromMinutes(2), cancellationToken);
        }

        return result;
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

    private async Task<object?> TryApplyAiSearchAssistAsync(
        string originalQuery,
        int page,
        int pageSize,
        string? searcherUserId,
        CancellationToken cancellationToken)
    {
        ProductSearchSpellCheckResult spell;
        try
        {
            spell = await openAiVisionService.CheckProductSearchSpellingAsync(originalQuery, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "AI product search spelling check failed for query {Query}", originalQuery);
            return null;
        }

        if (spell.IsMisspelled && !string.IsNullOrWhiteSpace(spell.CorrectedName))
        {
            string correctedQuery;
            try
            {
                correctedQuery = NormalizeSearchQuery(spell.CorrectedName);
            }
            catch (ArgumentException)
            {
                await LogMissedProductSearchAsync(
                    originalQuery,
                    searcherUserId,
                    "AI suggested an invalid correction.",
                    cancellationToken);
                return await BuildAiAssistedEmptySearchAsync(
                    originalQuery,
                    pageSize,
                    correctedQuery: null,
                    wasMisspelled: false,
                    cancellationToken);
            }

            if (!string.Equals(correctedQuery, originalQuery, StringComparison.OrdinalIgnoreCase))
            {
                var (correctedProducts, correctedTotal) =
                    await SearchCatalogByTextAsync(correctedQuery, page, pageSize, cancellationToken);

                // Whole-word search can miss valid catalog names after AI typo fixes
                // (Arabic/English variants, punctuation). Fall back to name LIKE.
                if (correctedTotal == 0)
                {
                    (correctedProducts, correctedTotal) =
                        await SearchCatalogByNameLooseAsync(
                            correctedQuery,
                            page,
                            pageSize,
                            cancellationToken);
                }

                // If the corrected name exists in catalog, always return it (do not log as missed).
                if (correctedTotal > 0)
                {
                    var items = await BuildPublicProductListItemsAsync(correctedProducts, cancellationToken);
                    return new
                    {
                        count = items.Count,
                        totalCount = correctedTotal,
                        page,
                        pageSize,
                        totalPages = (int)Math.Ceiling(correctedTotal / (double)pageSize),
                        items,
                        aiAssist = new
                        {
                            applied = true,
                            wasMisspelled = true,
                            originalQuery,
                            correctedQuery,
                            status = "corrected",
                            messageAr = $"ربما قصدت «{correctedQuery}». عرضنا النتائج بناءً على التصحيح.",
                            messageEn = $"Did you mean \"{correctedQuery}\"? Showing results for the corrected name."
                        }
                    };
                }

                // Correction not in catalog: only log when the typo was a close spelling change.
                // Unrelated AI guesses must not create missed-search noise or hide results.
                if (IsPlausibleSpellingCorrection(originalQuery, correctedQuery))
                {
                    await LogMissedProductSearchAsync(
                        correctedQuery,
                        searcherUserId,
                        $"Original query misspelled as '{originalQuery}'; corrected name also missing.",
                        cancellationToken);

                    return await BuildAiAssistedEmptySearchAsync(
                        originalQuery,
                        pageSize,
                        correctedQuery,
                        wasMisspelled: true,
                        cancellationToken);
                }

                // Unrelated AI invention that is also missing: do not log as missed-search noise.
                return await BuildAiAssistedEmptySearchAsync(
                    originalQuery,
                    pageSize,
                    correctedQuery: null,
                    wasMisspelled: false,
                    cancellationToken);
            }
        }

        await LogMissedProductSearchAsync(
            originalQuery,
            searcherUserId,
            "AI confirmed spelling is correct; product not in catalog.",
            cancellationToken);

        return await BuildAiAssistedEmptySearchAsync(
            originalQuery,
            pageSize,
            correctedQuery: null,
            wasMisspelled: false,
            cancellationToken);
    }

    /// <summary>
    /// Lenient name search for AI spelling assist: substring match on NameEn and
    /// name translations only (no whole-word gate). Used after strict search returns 0.
    /// </summary>
    private Task<(List<ProductPublicRow> Products, int TotalCount)> SearchCatalogByNameLooseAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken) =>
        productData.SearchPublicCatalogByNameLooseAsync(queryText, page, pageSize, cancellationToken);

    private Task<object> BuildAiAssistedEmptySearchAsync(
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

        var items = await BuildPublicProductListItemsAsync([product], cancellationToken);
        var result = new
        {
            productCode = normalizedCode,
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
            $"{ProductsByCategoryCachePrefix}{input.CategoryId}:v{ByCategoryProductsCacheVersion}:p{page}:s{pageSize}";
        var cached = await TryGetProductCacheAsync(cacheKey, cancellationToken);
        if (cached is not null)
        {
            return cached;
        }

        var category = await productData.GetCategoryByIdAsync(input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException($"Category '{input.CategoryId}' was not found.");

        var (products, totalCount) = await productData.GetProductsByCategoryPageAsync(
            category.CategoryId,
            (page - 1) * pageSize,
            pageSize,
            cancellationToken);

        var items = await BuildPublicProductListItemsAsync(
            products,
            cancellationToken,
            includeRetailFields: false);

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
