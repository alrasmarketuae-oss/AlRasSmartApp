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

        var baseQuery = ApplyHomeCatalogProductFilter(dbContext.Products.AsNoTracking());
        var totalCount = await baseQuery.CountAsync(cancellationToken);

        var products = await SelectPublicProductRows(baseQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        products = products
            .Where(x => x.CategoryId.HasValue && x.CategoryId.Value > 0)
            .ToList();

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

            var codeQuery = ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                .Where(x => x.ProductCode == productCode);

            var codeProducts = await SelectPublicProductRows(codeQuery)
                .OrderByDescending(x => x.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

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

    private async Task<(List<PublicProductQueryRow> Products, int TotalCount)> SearchCatalogByTextAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var skip = (page - 1) * pageSize;
        var productsQuery = ApplyPublicProductFilter(dbContext.Products.AsNoTracking());
        var tokens = queryText
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(t => !IsSearchStopToken(t))
            .ToList();

        if (tokens.Count == 0)
        {
            return ([], 0);
        }

        foreach (var token in tokens)
        {
            // Synonyms are OR'd; multiple query tokens are AND'd via successive filters.
            var words = new List<string> { token };
            words.AddRange(ResolveSearchSynonyms(token));
            var uniqueWords = words
                .Select(w => w.Trim())
                .Where(w => !string.IsNullOrWhiteSpace(w))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(6)
                .ToList();

            // 1) Broad SQL candidate fetch (substring LIKE only to shrink the set).
            //    Never return these as final hits — step 2 enforces whole-word.
            //    Do NOT use localList.Any(...) inside EF Where (matches every product).
            HashSet<Guid> candidateIds = [];
            foreach (var word in uniqueWords)
            {
                var containsPattern = ToSqlLikePattern(word);

                var fromProducts = await productsQuery
                    .Where(x =>
                        EF.Functions.Like(x.NameEn ?? string.Empty, containsPattern)
                        || EF.Functions.Like(x.ProductCode ?? string.Empty, ToExactLikePattern(word))
                        || (x.Category != null && (
                            EF.Functions.Like(x.Category.NameEn ?? string.Empty, containsPattern)
                            || EF.Functions.Like(x.Category.NameAr ?? string.Empty, containsPattern)))
                        || (x.ProductType != null
                            && EF.Functions.Like(x.ProductType.TypeNameEn ?? string.Empty, containsPattern))
                        || EF.Functions.Like(x.DescriptionEn ?? string.Empty, containsPattern)
                        || EF.Functions.Like(x.RetailDescriptionEn ?? string.Empty, containsPattern)
                        || EF.Functions.Like(x.SupplierNotesEn ?? string.Empty, containsPattern)
                        || EF.Functions.Like(x.ShippingDescriptionEn ?? string.Empty, containsPattern))
                    .Select(x => x.ProductId)
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                var fromTranslations = await (
                        from t in dbContext.ContentTranslations.AsNoTracking()
                        join p in productsQuery on t.ProductId equals p.ProductId
                        where t.Scope == ContentTranslationScopes.Product
                              && t.ProductId != null
                              && (t.Field == ContentTranslationFields.Name
                                  || t.Field == ContentTranslationFields.Description
                                  || t.Field == ContentTranslationFields.RetailDescription
                                  || t.Field == ContentTranslationFields.SupplierNotes
                                  || t.Field == ContentTranslationFields.ShippingDescription)
                              && (EF.Functions.Like(t.TextAr ?? string.Empty, containsPattern)
                                  || EF.Functions.Like(t.TextEn ?? string.Empty, containsPattern))
                        select t.ProductId!.Value)
                    .Distinct()
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                foreach (var id in fromProducts.Concat(fromTranslations))
                {
                    candidateIds.Add(id);
                }
            }

            if (candidateIds.Count == 0)
            {
                return ([], 0);
            }

            // 2) Whole-word only (C#) — "فاخر"∈"شوكو فاخر"; "كو"/"كوك"∉"كوكو".
            var candidateRows = await productsQuery
                .Where(x => candidateIds.Contains(x.ProductId))
                .Select(x => new
                {
                    x.ProductId,
                    x.NameEn,
                    x.ProductCode,
                    x.DescriptionEn,
                    x.RetailDescriptionEn,
                    x.SupplierNotesEn,
                    x.ShippingDescriptionEn,
                    CategoryNameEn = x.Category != null ? x.Category.NameEn : null,
                    CategoryNameAr = x.Category != null ? x.Category.NameAr : null,
                    ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : null
                })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var translationRows = await dbContext.ContentTranslations.AsNoTracking()
                .Where(t =>
                    t.Scope == ContentTranslationScopes.Product
                    && t.ProductId != null
                    && candidateIds.Contains(t.ProductId.Value)
                    && (t.Field == ContentTranslationFields.Name
                        || t.Field == ContentTranslationFields.Description
                        || t.Field == ContentTranslationFields.RetailDescription
                        || t.Field == ContentTranslationFields.SupplierNotes
                        || t.Field == ContentTranslationFields.ShippingDescription))
                .Select(t => new { ProductId = t.ProductId!.Value, t.TextAr, t.TextEn })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var translationsByProduct = translationRows
                .GroupBy(t => t.ProductId)
                .ToDictionary(g => g.Key, g => g.ToList());

            var wholeWordIds = new HashSet<Guid>();
            foreach (var row in candidateRows)
            {
                translationsByProduct.TryGetValue(row.ProductId, out var trs);
                var haystacks = new List<string?>
                {
                    row.NameEn,
                    row.ProductCode,
                    row.DescriptionEn,
                    row.RetailDescriptionEn,
                    row.SupplierNotesEn,
                    row.ShippingDescriptionEn,
                    row.CategoryNameEn,
                    row.CategoryNameAr,
                    row.ProductTypeName
                };
                if (trs is not null)
                {
                    foreach (var tr in trs)
                    {
                        haystacks.Add(tr.TextAr);
                        haystacks.Add(tr.TextEn);
                    }
                }

                // Keep only products where a search word is a full token (never letter substring).
                if (uniqueWords.Any(word => haystacks.Any(h => ContainsWholeWord(h, word))))
                {
                    wholeWordIds.Add(row.ProductId);
                }
            }

            if (wholeWordIds.Count == 0)
            {
                return ([], 0);
            }

            productsQuery = productsQuery.Where(x => wholeWordIds.Contains(x.ProductId));
        }

        var totalCount = await productsQuery.CountAsync(cancellationToken);
        var products = await SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (products, totalCount);
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
    private async Task<(List<PublicProductQueryRow> Products, int TotalCount)> SearchCatalogByNameLooseAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        var q = (queryText ?? string.Empty).Trim();
        if (q.Length < 2)
        {
            return ([], 0);
        }

        var skip = (page - 1) * pageSize;
        var productsQuery = ApplyPublicProductFilter(dbContext.Products.AsNoTracking());
        var containsPattern = ToSqlLikePattern(q);

        var fromProducts = await productsQuery
            .Where(x => EF.Functions.Like(x.NameEn ?? string.Empty, containsPattern))
            .Select(x => x.ProductId)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var fromTranslations = await (
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

        var ids = fromProducts.Concat(fromTranslations).Distinct().ToList();
        if (ids.Count == 0)
        {
            return ([], 0);
        }

        var matchedQuery = productsQuery.Where(x => ids.Contains(x.ProductId));
        var totalCount = await matchedQuery.CountAsync(cancellationToken).ConfigureAwait(false);
        var products = await SelectPublicProductRows(matchedQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return (products, totalCount);
    }

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
                var user = await dbContext.Users.AsNoTracking()
                    .Where(x => x.Id == parsedUserId)
                    .Select(x => new { x.FullName, x.Email, x.PhoneNumber })
                    .FirstOrDefaultAsync(cancellationToken);

                if (user is not null)
                {
                    displayName = string.IsNullOrWhiteSpace(user.FullName) ? null : user.FullName.Trim();
                    email = string.IsNullOrWhiteSpace(user.Email) ? null : user.Email.Trim();
                    phone = string.IsNullOrWhiteSpace(user.PhoneNumber) ? null : user.PhoneNumber.Trim();
                }
            }

            var since = DateTime.UtcNow.AddHours(-1);
            var duplicateExists = await dbContext.MissedProductSearches.AsNoTracking()
                .AnyAsync(
                    x => x.QueryText == queryText
                         && x.UserId == userId
                         && x.CreatedAtUtc >= since,
                    cancellationToken);

            if (duplicateExists)
            {
                return;
            }

            dbContext.MissedProductSearches.Add(new MissedProductSearch
            {
                Id = Guid.NewGuid(),
                QueryText = queryText.Length > 200 ? queryText[..200] : queryText,
                UserId = userId,
                UserDisplayName = displayName,
                UserEmail = email,
                UserPhone = phone,
                CreatedAtUtc = DateTime.UtcNow,
                Notes = notes is { Length: > 500 } ? notes[..500] : notes
            });

            await dbContext.SaveChangesAsync(cancellationToken);
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

        var product = await SelectPublicProductRows(
                ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    .Where(x => x.ProductCode == normalizedCode))
            .FirstOrDefaultAsync(cancellationToken)
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

        var product = await SelectPublicProductRows(
                ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    .Where(x => x.ProductId == parsedId))
            .FirstOrDefaultAsync(cancellationToken)
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

        var names = await ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => !string.IsNullOrWhiteSpace(x.NameEn))
            .Select(x => x.NameEn!.Trim())
            .Distinct()
            .ToListAsync(cancellationToken);

        var translatedNameRows = await (
                from t in dbContext.ContentTranslations.AsNoTracking()
                join p in ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    on t.ProductId equals p.ProductId
                where t.Scope == ContentTranslationScopes.Product
                      && t.Field == ContentTranslationFields.Name
                select new { t.TextAr, t.TextEn })
            .ToListAsync(cancellationToken);

        var translatedNames = translatedNameRows
            .SelectMany(x => new[] { x.TextAr, x.TextEn })
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x!.Trim());

        names = names
            .Concat(translatedNames)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x, StringComparer.OrdinalIgnoreCase)
            .ToList();

        var codes = await ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => !string.IsNullOrWhiteSpace(x.ProductCode))
            .Select(x => x.ProductCode!.Trim())
            .Distinct()
            .OrderBy(x => x)
            .ToListAsync(cancellationToken);

        var result = new
        {
            totalCount = names.Count + codes.Count,
            names,
            productCodes = codes,
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

        var productType = await dbContext.ProductTypes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.TypeNameEn.ToLower() == normalizedType, cancellationToken)
            ?? throw new KeyNotFoundException($"Product type '{input.ProductTypeName}' was not found.");

        var isRetailType = ProductTypeCodes.IsRetail(productType.Id);

        IQueryable<Product> productsQuery;
        if (isRetailType)
        {
            // Retail: include pure retail AND category hybrids (CategoryId + ProductTypeId=1).
            // Do NOT require CategoryId == null — that hid dual-listed products.
            productsQuery = dbContext.Products.AsNoTracking()
                .Where(x =>
                    x.ProductTypeId == ProductTypeCodes.Retail
                    && x.Status != ProductStatusCodes.Rejected
                    && (x.Status == ProductStatusCodes.Active
                        || x.Status == ProductStatusCodes.Paused
                        || (x.Status == ProductStatusCodes.UnderReview && x.IsApproved == true)));
        }
        else
        {
            // Offers / Booking / Requests only — not dual category listings.
            productsQuery = dbContext.Products.AsNoTracking()
                .Where(x =>
                    x.ProductTypeId == productType.Id
                    && x.CategoryId == null
                    && x.Status != ProductStatusCodes.Rejected
                    && (x.Status == ProductStatusCodes.Active
                        || x.Status == ProductStatusCodes.Paused
                        || (x.Status == ProductStatusCodes.UnderReview && x.IsApproved == true))
                    && (x.ProductTypeId != ProductTypeCodes.Requests || x.Quantity > 0));
        }

        var totalCount = await productsQuery.CountAsync(cancellationToken);

        var products = await SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

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

        var category = await dbContext.Categories
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.CategoryId == input.CategoryId, cancellationToken)
            ?? throw new KeyNotFoundException($"Category '{input.CategoryId}' was not found.");

        var productsQuery = ApplyHomeCatalogProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => x.CategoryId == category.CategoryId);

        var totalCount = await productsQuery.CountAsync(cancellationToken);

        var products = await SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

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

        var featuredQuery = ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => x.IsFeatured);

        var totalCount = await featuredQuery.CountAsync(cancellationToken);

        var products = await SelectPublicProductRows(featuredQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

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

        var product = await dbContext.Products.FirstOrDefaultAsync(x => x.ProductId == parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        product.ViewsCount += 1;
        await dbContext.SaveChangesAsync(cancellationToken);

        productCacheVersions.BumpListViews();

        return new
        {
            productId = product.ProductId,
            viewsCount = product.ViewsCount
        };
    }
}
