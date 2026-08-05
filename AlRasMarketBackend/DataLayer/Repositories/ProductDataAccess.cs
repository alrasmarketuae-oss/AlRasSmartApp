using System.Data;
using System.Text.RegularExpressions;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DataLayer.Repositories;

public sealed class ProductDataAccess(
    IRasAlSouqDbContext dbContext,
    ProductAdoRepository productAdoRepository,
    ILogger<ProductDataAccess> logger) : IProductDataAccess
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        dbContext.SaveChangesAsync(cancellationToken);

    public Task<string> InsertProductAsync(Product product, CancellationToken cancellationToken = default) =>
        productAdoRepository.InsertProductAsync(product, cancellationToken);

    public async Task<List<ProductPublicRow>> GetProductsByIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default)
    {
        var rows = await productAdoRepository.GetProductsByIdsAsync(productIds, cancellationToken);
        return rows.Select(MapAdoRow).ToList();
    }

    public async Task<string> AllocateProductCodeAsync(CancellationToken cancellationToken = default)
    {
        var connection = ((DbContext)dbContext).Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
        {
            await connection.OpenAsync(cancellationToken);
        }

        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT NEXT VALUE FOR dbo.ProductCodeSeq;";
        var raw = await command.ExecuteScalarAsync(cancellationToken);
        var sequenceValue = Convert.ToInt64(raw);
        logger.LogDebug("Allocated product code sequence value {SequenceValue}", sequenceValue);
        return ProductCodeGenerator.FromSequenceValue(sequenceValue);
    }

    public Task<Product?> GetProductByIdTrackedAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products.FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken);

    public Task<Product?> GetProductWithMediaForDeleteAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products
            .Include(x => x.ProductImages)
            .Include(x => x.ProductDocuments)
            .Include(x => x.ProductVideos)
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken);

    public async Task<ProductMediaSnapshot> GetProductMediaPathsForSnapshotAsync(
        Guid productId,
        CancellationToken cancellationToken = default)
    {
        var images = await dbContext.ProductImages.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .OrderBy(x => x.Id)
            .Select(x => x.ImagePath)
            .ToListAsync(cancellationToken);
        var documents = await dbContext.ProductDocuments.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .OrderBy(x => x.Id)
            .Select(x => x.DocumentPath)
            .ToListAsync(cancellationToken);
        var videos = await dbContext.ProductVideos.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .OrderBy(x => x.Id)
            .Select(x => x.VideoPath)
            .ToListAsync(cancellationToken);
        return new ProductMediaSnapshot
        {
            ImagePaths = images,
            DocumentPaths = documents,
            ExtraVideoPaths = videos
        };
    }

    public Task<List<long>> GetProductImageIdsByProductIdAsync(
        Guid productId,
        CancellationToken cancellationToken = default) =>
        dbContext.ProductImages.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .OrderBy(x => x.Id)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

    public async Task<ProductDeleteCascadeResult> DeleteProductCascadeAsync(
        Product product,
        CancellationToken cancellationToken = default)
    {
        var productId = product.ProductId;
        var result = new ProductDeleteCascadeResult
        {
            OwnerId = product.OwnerId,
            ImageIds = product.ProductImages.Select(x => x.Id).ToList(),
            ImagePaths = product.ProductImages.Select(x => x.ImagePath).ToList(),
            DocumentPaths = product.ProductDocuments.Select(x => x.DocumentPath).ToList(),
            VideoPaths = ResolveVideoPaths(product)
        };

        var cartItems = await dbContext.CartItems
            .Where(x => x.ProductId == productId)
            .ToListAsync(cancellationToken);
        if (cartItems.Count > 0)
        {
            dbContext.CartItems.RemoveRange(cartItems);
        }

        var offerIds = await dbContext.Offers
            .Where(x => x.ProductId == productId)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);
        if (offerIds.Count > 0)
        {
            await RemoveRangeAsync(dbContext.OfferOnRequestImages.Where(x => offerIds.Contains(x.OfferId)), cancellationToken);
            await RemoveRangeAsync(dbContext.OfferOnRequestDocuments.Where(x => offerIds.Contains(x.OfferId)), cancellationToken);
            await RemoveRangeAsync(dbContext.Offers.Where(x => offerIds.Contains(x.Id)), cancellationToken);
        }

        var negotiableOffers = await dbContext.OffersOnNegotiable
            .Where(x => x.ProductId == productId)
            .ToListAsync(cancellationToken);
        if (negotiableOffers.Count > 0)
        {
            dbContext.OffersOnNegotiable.RemoveRange(negotiableOffers);
        }

        if (product.ProductImages.Count > 0)
        {
            dbContext.ProductImages.RemoveRange(product.ProductImages);
        }

        if (product.ProductDocuments.Count > 0)
        {
            dbContext.ProductDocuments.RemoveRange(product.ProductDocuments);
        }

        if (product.ProductVideos.Count > 0)
        {
            dbContext.ProductVideos.RemoveRange(product.ProductVideos);
        }

        dbContext.Products.Remove(product);
        await dbContext.SaveChangesAsync(cancellationToken);
        return result;
    }

    public async Task<ProductOrderDeleteMediaResult> DeleteProductOrdersAndDependentsAsync(
        Guid productId,
        CancellationToken cancellationToken = default)
    {
        var result = new ProductOrderDeleteMediaResult();
        var orderIds = await dbContext.Orders.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        if (orderIds.Count > 0)
        {
            result.OrderImagePaths = await dbContext.OrderImages.AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.ImagePath)
                .ToListAsync(cancellationToken);
            result.OrderVideoPaths = await dbContext.OrderVideos.AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.VideoPath)
                .ToListAsync(cancellationToken);

            await RemoveRangeAsync(dbContext.InternationalShipments.Where(x => orderIds.Contains(x.OrderId)), cancellationToken);
            await RemoveRangeAsync(dbContext.PendingPayments.Where(x => orderIds.Contains(x.OrderId)), cancellationToken);
            await RemoveRangeAsync(dbContext.OrderVideos.Where(x => orderIds.Contains(x.OrderId)), cancellationToken);
            await RemoveRangeAsync(dbContext.OrderImages.Where(x => orderIds.Contains(x.OrderId)), cancellationToken);
            await RemoveRangeAsync(
                dbContext.ContentTranslations.Where(x => x.OrderId != null && orderIds.Contains(x.OrderId.Value)),
                cancellationToken);
            await RemoveRangeAsync(dbContext.Orders.Where(x => orderIds.Contains(x.Id)), cancellationToken);
        }

        await RemoveRangeAsync(dbContext.PendingOrderItems.Where(x => x.ProductId == productId), cancellationToken);
        return result;
    }

    public async Task<(List<ProductPublicRow> Rows, int TotalCount)> GetHomeCatalogPageAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var baseQuery = ProductQueryHelpers.ExcludeHomeFeedCategories(
            ProductQueryHelpers.ApplyHomeCatalogProductFilter(dbContext.Products.AsNoTracking()));
        var totalCount = await baseQuery.CountAsync(cancellationToken);
        var rows = await ProductQueryHelpers.SelectPublicProductRows(baseQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);
        rows = rows.Where(x => x.CategoryId.HasValue && x.CategoryId.Value > 0).ToList();
        return (rows, totalCount);
    }

    public Task<List<ProductPublicRow>> GetPublicProductsByCodeAsync(
        string productCode,
        int skip,
        int take,
        CancellationToken cancellationToken = default) =>
        ProductQueryHelpers.SelectPublicProductRows(
                ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    .Where(x => x.ProductCode == productCode || x.RetailCode == productCode))
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

    public Task<ProductPublicRow?> GetPublicProductByIdAsync(
        Guid productId,
        CancellationToken cancellationToken = default) =>
        ProductQueryHelpers.SelectPublicProductRows(
                ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    .Where(x => x.ProductId == productId))
            .FirstOrDefaultAsync(cancellationToken);

    public Task<ProductPublicRow?> GetPublicProductByCodeExactAsync(
        string productCode,
        CancellationToken cancellationToken = default) =>
        ProductQueryHelpers.SelectPublicProductRows(
                ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                    .Where(x => x.ProductCode == productCode || x.RetailCode == productCode))
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<(List<ProductPublicRow> Products, int TotalCount)> SearchPublicCatalogByTokenWordsAsync(
        IReadOnlyList<IReadOnlyList<string>> tokenWordGroups,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var skip = (page - 1) * pageSize;
        var productsQuery = ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking());

        if (tokenWordGroups.Count == 0)
        {
            return ([], 0);
        }

        foreach (var group in tokenWordGroups)
        {
            var uniqueWords = group
                .Select(w => w.Trim())
                .Where(w => !string.IsNullOrWhiteSpace(w))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Take(6)
                .ToList();
            if (uniqueWords.Count == 0)
            {
                return ([], 0);
            }

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
                    .ToListAsync(cancellationToken);

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
                    .ToListAsync(cancellationToken);

                foreach (var id in fromProducts.Concat(fromTranslations))
                {
                    candidateIds.Add(id);
                }
            }

            if (candidateIds.Count == 0)
            {
                return ([], 0);
            }

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
                .ToListAsync(cancellationToken);

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
                .ToListAsync(cancellationToken);

            var translationsByProduct = translationRows
                .GroupBy(t => t.ProductId)
                .ToDictionary(g => g.Key, g => g.ToList());

            var wholeWordIds = new HashSet<Guid>();
            foreach (var row in candidateRows)
            {
                translationsByProduct.TryGetValue(row.ProductId, out var trs);
                var haystacks = new List<string?>
                {
                    row.NameEn, row.ProductCode, row.DescriptionEn, row.RetailDescriptionEn,
                    row.SupplierNotesEn, row.ShippingDescriptionEn,
                    row.CategoryNameEn, row.CategoryNameAr, row.ProductTypeName
                };
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
                return ([], 0);
            }

            productsQuery = productsQuery.Where(x => wholeWordIds.Contains(x.ProductId));
        }

        var totalCount = await productsQuery.CountAsync(cancellationToken);
        var products = await ProductQueryHelpers.SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return (products, totalCount);
    }

    public async Task<(List<ProductPublicRow> Products, int TotalCount)> SearchPublicCatalogByNameLooseAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var q = (queryText ?? string.Empty).Trim();
        if (q.Length < 2)
        {
            return ([], 0);
        }

        var skip = (page - 1) * pageSize;
        var productsQuery = ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking());
        var containsPattern = ToSqlLikePattern(q);

        var fromProducts = await productsQuery
            .Where(x => EF.Functions.Like(x.NameEn ?? string.Empty, containsPattern))
            .Select(x => x.ProductId)
            .ToListAsync(cancellationToken);

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
            .ToListAsync(cancellationToken);

        var ids = fromProducts.Concat(fromTranslations).Distinct().ToList();
        if (ids.Count == 0)
        {
            return ([], 0);
        }

        var matchedQuery = productsQuery.Where(x => ids.Contains(x.ProductId));
        var totalCount = await matchedQuery.CountAsync(cancellationToken);
        var products = await ProductQueryHelpers.SelectPublicProductRows(matchedQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        return (products, totalCount);
    }

    public async Task<ProductSearchNameIndex> GetSearchNameIndexAsync(CancellationToken cancellationToken = default)
    {
        var names = await ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => !string.IsNullOrWhiteSpace(x.NameEn))
            .Select(x => x.NameEn!.Trim())
            .Distinct()
            .ToListAsync(cancellationToken);

        var translatedNameRows = await (
                from t in dbContext.ContentTranslations.AsNoTracking()
                join p in ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
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

        var codes = await ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Select(x => new { x.ProductCode, x.RetailCode })
            .ToListAsync(cancellationToken);

        var productCodes = codes
            .SelectMany(x => new[] { x.ProductCode, x.RetailCode })
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x!.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(x => x, StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new ProductSearchNameIndex { Names = names, ProductCodes = productCodes };
    }

    public async Task<(List<ProductPublicRow> Rows, int TotalCount)> GetProductsByTypePageAsync(
        byte productTypeId,
        bool retailHomeStyle,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        IQueryable<Product> productsQuery;
        if (retailHomeStyle)
        {
            productsQuery = dbContext.Products.AsNoTracking()
                .Where(x =>
                    x.ProductTypeId == ProductCatalogCodes.TypeRetail
                    && x.Status != ProductCatalogCodes.StatusRejected
                    && (x.Status == ProductCatalogCodes.StatusActive
                        || x.Status == ProductCatalogCodes.StatusPaused
                        || (x.Status == ProductCatalogCodes.StatusUnderReview && x.IsApproved == true)));
        }
        else
        {
            productsQuery = dbContext.Products.AsNoTracking()
                .Where(x =>
                    x.ProductTypeId == productTypeId
                    && x.CategoryId == null
                    && x.Status != ProductCatalogCodes.StatusRejected
                    && (x.Status == ProductCatalogCodes.StatusActive
                        || x.Status == ProductCatalogCodes.StatusPaused
                        || (x.Status == ProductCatalogCodes.StatusUnderReview && x.IsApproved == true))
                    && (x.ProductTypeId != ProductCatalogCodes.TypeRequests || x.Quantity > 0));
        }

        var totalCount = await productsQuery.CountAsync(cancellationToken);
        var rows = await ProductQueryHelpers.SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);
        return (rows, totalCount);
    }

    public async Task<(List<ProductPublicRow> Rows, int TotalCount)> GetProductsByCategoryPageAsync(
        byte categoryId,
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var productsQuery = ProductQueryHelpers.ApplyHomeCatalogProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => x.CategoryId == categoryId);
        var totalCount = await productsQuery.CountAsync(cancellationToken);
        var rows = await ProductQueryHelpers.SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);
        return (rows, totalCount);
    }

    public async Task<(List<ProductPublicRow> Rows, int TotalCount)> GetFeaturedProductsPageAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default)
    {
        var productsQuery = ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
            .Where(x => x.IsFeatured);
        var totalCount = await productsQuery.CountAsync(cancellationToken);
        var rows = await ProductQueryHelpers.SelectPublicProductRows(productsQuery)
            .OrderByDescending(x => x.CreatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);
        return (rows, totalCount);
    }

    public async Task<List<ProductPublicRow>> SearchPublicProductsByNameAnyAsync(
        IReadOnlyList<string> matchWords,
        int take,
        CancellationToken cancellationToken = default)
    {
        var productsQuery = ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking());
        var uniqueWords = matchWords
            .Select(w => w.Trim())
            .Where(w => !string.IsNullOrWhiteSpace(w))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(16)
            .ToList();
        if (uniqueWords.Count == 0)
        {
            return [];
        }

        // One round-trip per source (products / translations) instead of 2×N word loops.
        IQueryable<Guid>? productIdUnion = null;
        IQueryable<Guid>? translationIdUnion = null;
        foreach (var word in uniqueWords)
        {
            var containsPattern = ToSqlLikePattern(word);
            var fromProducts = productsQuery
                .Where(x => EF.Functions.Like(x.NameEn ?? string.Empty, containsPattern))
                .Select(x => x.ProductId);
            productIdUnion = productIdUnion is null
                ? fromProducts
                : productIdUnion.Union(fromProducts);

            var fromNameTranslations = (
                    from t in dbContext.ContentTranslations.AsNoTracking()
                    join p in productsQuery on t.ProductId equals p.ProductId
                    where t.Scope == ContentTranslationScopes.Product
                          && t.ProductId != null
                          && t.Field == ContentTranslationFields.Name
                          && (EF.Functions.Like(t.TextAr ?? string.Empty, containsPattern)
                              || EF.Functions.Like(t.TextEn ?? string.Empty, containsPattern))
                    select t.ProductId!.Value)
                .Distinct();
            translationIdUnion = translationIdUnion is null
                ? fromNameTranslations
                : translationIdUnion.Union(fromNameTranslations);
        }

        var candidateIds = new HashSet<Guid>();
        if (productIdUnion is not null)
        {
            foreach (var id in await productIdUnion.ToListAsync(cancellationToken))
            {
                candidateIds.Add(id);
            }
        }

        if (translationIdUnion is not null)
        {
            foreach (var id in await translationIdUnion.ToListAsync(cancellationToken))
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
            .ToListAsync(cancellationToken);
        var nameTranslationRows = await dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId != null
                && candidateIds.Contains(t.ProductId.Value)
                && t.Field == ContentTranslationFields.Name)
            .Select(t => new { ProductId = t.ProductId!.Value, t.TextAr, t.TextEn })
            .ToListAsync(cancellationToken);
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

        return await ProductQueryHelpers.SelectPublicProductRows(
                productsQuery.Where(x => wholeWordIds.Contains(x.ProductId)))
            .OrderByDescending(x => x.CreatedAt)
            .Take(take)
            .ToListAsync(cancellationToken);
    }

    public Task<List<ProductNameTranslationRow>> GetProductNameTranslationsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId != null
                && productIds.Contains(t.ProductId.Value)
                && t.Field == ContentTranslationFields.Name)
            .Select(t => new ProductNameTranslationRow
            {
                ProductId = t.ProductId!.Value,
                TextAr = t.TextAr,
                TextEn = t.TextEn
            })
            .ToListAsync(cancellationToken);

    public Task<List<ProductMediaPathRow>> GetProductImagePathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.ProductImages.AsNoTracking()
            .Where(pi => productIds.Contains(pi.ProductId))
            .OrderBy(pi => pi.Id)
            .Select(pi => new ProductMediaPathRow { ProductId = pi.ProductId, Path = pi.ImagePath })
            .ToListAsync(cancellationToken);

    public Task<List<ProductMediaPathRow>> GetProductDocumentPathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.ProductDocuments.AsNoTracking()
            .Where(pd => productIds.Contains(pd.ProductId))
            .OrderBy(pd => pd.Id)
            .Select(pd => new ProductMediaPathRow { ProductId = pd.ProductId, Path = pd.DocumentPath })
            .ToListAsync(cancellationToken);

    public Task<List<ProductMediaPathRow>> GetProductVideoPathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.ProductVideos.AsNoTracking()
            .Where(v => productIds.Contains(v.ProductId))
            .OrderBy(v => v.Id)
            .Select(v => new ProductMediaPathRow
            {
                Id = v.Id,
                ProductId = v.ProductId,
                Path = v.VideoPath,
                VideoDurationSeconds = v.VideoDurationSeconds,
                IsMuted = v.IsMuted
            })
            .ToListAsync(cancellationToken);

    public async Task<Dictionary<byte, Category>> GetCategoriesByIdsAsync(
        IReadOnlyList<byte> categoryIds,
        CancellationToken cancellationToken = default)
    {
        if (categoryIds.Count == 0)
        {
            return new Dictionary<byte, Category>();
        }

        return await dbContext.Categories.AsNoTracking()
            .Where(c => categoryIds.Contains(c.CategoryId))
            .ToDictionaryAsync(c => c.CategoryId, cancellationToken);
    }

    public Task<List<AddressDisplayRow>> GetAddressDisplayRowsByIdsAsync(
        IReadOnlyList<Guid> addressIds,
        CancellationToken cancellationToken = default) =>
        dbContext.Addresses.AsNoTracking()
            .Where(a => addressIds.Contains(a.Id))
            .Select(a => new AddressDisplayRow
            {
                Id = a.Id,
                AddressLine1 = a.AddressLine1,
                AddressLine2 = a.AddressLine2,
                CityId = a.CityId
            })
            .ToListAsync(cancellationToken);

    public Task<string?> GetUserDisplayNameAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Users.AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => x.FullName)
            .FirstOrDefaultAsync(cancellationToken);

    public Task<List<OwnerListingRow>> GetOwnerListingsAsync(
        Guid ownerId,
        CancellationToken cancellationToken = default) =>
        dbContext.Products.AsNoTracking()
            .Where(x => x.OwnerId == ownerId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new OwnerListingRow
            {
                ProductId = x.ProductId,
                ProductCode = x.ProductCode,
                RetailCode = x.RetailCode,
                NameEn = x.NameEn,
                CreatedLanguage = x.CreatedLanguage,
                CategoryName = x.Category != null ? x.Category.NameEn : null,
                CategoryNameAr = x.Category != null ? x.Category.NameAr : null,
                CategoryImagePath = x.Category != null ? x.Category.ImgPath : null,
                ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : null,
                DescriptionEn = x.DescriptionEn,
                USDPrice = x.USDPrice,
                ProductTypeId = x.ProductTypeId,
                CategoryId = x.CategoryId,
                Currency = x.Currency,
                Quantity = x.Quantity,
                UnitName = x.Unit != null ? x.Unit.UnitNameEn : null,
                RetailPrice = x.RetailPrice,
                RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null,
                RetailUnitId = x.RetailUnitId,
                RetailQuantity = x.RetailQuantity,
                RetailPackaging = x.RetailPackaging,
                RetailPackagingDetails = x.RetailPackagingDetails,
                RetailDescriptionEn = x.RetailDescriptionEn,
                RequestTypeId = x.RequestTypeId,
                RequestTypeName = x.RequestType != null ? x.RequestType.NameEn : null,
                BookingPriceTypeId = x.BookingPriceTypeId,
                BookingPriceTypeName = x.BookingPriceType != null ? x.BookingPriceType.NameEn : null,
                MinimumOrderQuantity = x.MinimumOrderQuantity,
                MaximumOrderQuantity = x.MaximumOrderQuantity,
                Status = x.Status,
                IsApproved = x.IsApproved,
                DiscountPercentage = x.DiscountPercentage,
                DiscountDays = x.DiscountDays,
                ShippingDescriptionEn = x.ShippingDescriptionEn,
                ShippingDuration = x.ShippingDuration,
                OfferDuration = x.OfferDuration,
                SupplierNotesEn = x.SupplierNotesEn,
                Packaging = x.Packaging,
                PackagingDetails = x.PackagingDetails,
                Negotiable = x.Negotiable,
                IsFeatured = x.IsFeatured,
                ViewsCount = x.ViewsCount,
                VideoPath = x.VideoPath,
                VideoDurationSeconds = x.VideoDurationSeconds,
                OriginCountryName = x.OriginCountry != null ? x.OriginCountry.CountryNameEn : null,
                OriginCountryNameAr = x.OriginCountry != null ? x.OriginCountry.CountryNameAr : null,
                DestinationCountryName = x.DestinationCountry != null ? x.DestinationCountry.CountryNameEn : null,
                DestinationCountryNameAr = x.DestinationCountry != null ? x.DestinationCountry.CountryNameAr : null,
                LoadingPortName = x.LoadingPort != null ? x.LoadingPort.PortNameEn : null,
                LoadingPortNameAr = x.LoadingPort != null ? x.LoadingPort.PortNameAr : null,
                ArrivalPortName = x.ArrivalPort != null ? x.ArrivalPort.PortNameEn : null,
                ArrivalPortNameAr = x.ArrivalPort != null ? x.ArrivalPort.PortNameAr : null,
                CreatedAt = x.CreatedAt,
                UpdatedAt = x.UpdatedAt,
                AddressId = x.AddressId,
                Images = x.ProductImages.OrderBy(pi => pi.Id).Select(pi => pi.ImagePath).ToList(),
                Documents = x.ProductDocuments.OrderBy(pd => pd.Id).Select(pd => pd.DocumentPath).ToList()
            })
            .ToListAsync(cancellationToken);

    public Task<Dictionary<Guid, int>> GetPendingOfferCountsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        byte retailProductTypeId,
        byte awaitingSellerApprovalStatusId,
        CancellationToken cancellationToken = default)
    {
        const byte ordered = 1;
        const byte paid = 3;
        return (
            from o in dbContext.Orders.AsNoTracking()
            join p in dbContext.Products.AsNoTracking() on o.ProductId equals p.ProductId
            where productIds.Contains(o.ProductId)
                && !o.IsApproved
                && (
                    o.StatusId == awaitingSellerApprovalStatusId
                    || (p.ProductTypeId == retailProductTypeId
                        && !o.IsAdminApproved
                        && (o.StatusId == ordered || o.StatusId == paid)))
            group o by o.ProductId
            into g
            select new { ProductId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ProductId, x => x.Count, cancellationToken);
    }

    public Task<List<InternationalShippingPost>> GetOwnerShippingPostsAsync(
        Guid ownerId,
        CancellationToken cancellationToken = default) =>
        dbContext.InternationalShippingPosts.AsNoTracking()
            .Include(x => x.FromCountry)
            .Include(x => x.FromPort)
            .Include(x => x.ToCountry)
            .Include(x => x.ToPort)
            .Where(x => x.PublisherUserId == ownerId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

    public async Task<User?> GetUserByIdAsync(Guid userId, bool tracked, CancellationToken cancellationToken = default)
    {
        if (tracked)
        {
            return await dbContext.Users.FindAsync([userId], cancellationToken);
        }

        return await dbContext.Users.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    }

    public Task<string?> GetUserPhoneByIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Users.AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => x.PhoneNumber)
            .FirstOrDefaultAsync(cancellationToken);

    public Task<bool> AddressBelongsToUserAsync(
        Guid addressId,
        Guid userId,
        CancellationToken cancellationToken = default) =>
        dbContext.Addresses.AsNoTracking()
            .AnyAsync(x => x.Id == addressId && x.UserId == userId, cancellationToken);

    public Task<ProductType?> GetProductTypeByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.ProductTypes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.TypeNameEn.ToLower() == normalized, cancellationToken);
    }

    public Task<bool> ProductTypeExistsByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.ProductTypes.AsNoTracking()
            .AnyAsync(x => x.TypeNameEn.ToLower() == normalized, cancellationToken);
    }

    public Task<RequestType?> GetRequestTypeByIdAsync(byte id, CancellationToken cancellationToken = default) =>
        dbContext.RequestTypes.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    public Task<RequestType?> GetRequestTypeByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.RequestTypes
            .FirstOrDefaultAsync(x => x.NameEn.ToLower() == normalized, cancellationToken);
    }

    public Task<BookingPriceType?> GetBookingPriceTypeByIdAsync(byte id, CancellationToken cancellationToken = default) =>
        dbContext.BookingPriceTypes.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    public Task<BookingPriceType?> GetBookingPriceTypeByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.BookingPriceTypes
            .FirstOrDefaultAsync(x => x.NameEn.ToLower() == normalized, cancellationToken);
    }

    public Task<Category?> GetCategoryByIdAsync(byte id, CancellationToken cancellationToken = default) =>
        dbContext.Categories.AsNoTracking()
            .FirstOrDefaultAsync(x => x.CategoryId == id, cancellationToken);

    public Task<Category?> GetCategoryByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.Categories.AsNoTracking()
            .FirstOrDefaultAsync(
                x => (x.NameEn != null && x.NameEn.ToLower() == normalized)
                     || (x.NameAr != null && x.NameAr.ToLower() == normalized),
                cancellationToken);
    }

    public Task<bool> CategoryExistsByIdAsync(byte id, CancellationToken cancellationToken = default) =>
        dbContext.Categories.AsNoTracking().AnyAsync(x => x.CategoryId == id, cancellationToken);

    public Task<bool> CategoryExistsByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return dbContext.Categories.AsNoTracking()
            .AnyAsync(
                x => (x.NameEn != null && x.NameEn.ToLower() == normalized)
                     || (x.NameAr != null && x.NameAr.ToLower() == normalized),
                cancellationToken);
    }

    public Task<List<ProductEditTranslationHint>> GetProductEditTranslationHintsAsync(
        Guid productId,
        CancellationToken cancellationToken = default) =>
        dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId == productId
                && (t.Field == ContentTranslationFields.Name
                    || t.Field == ContentTranslationFields.Description
                    || t.Field == ContentTranslationFields.RetailDescription))
            .Select(t => new ProductEditTranslationHint
            {
                ProductId = productId,
                Field = t.Field,
                TextEn = t.TextEn,
                TextAr = t.TextAr
            })
            .ToListAsync(cancellationToken);

    public async Task TryAddMissedProductSearchAsync(
        MissedProductSearchInsert insert,
        CancellationToken cancellationToken = default)
    {
        var queryText = insert.Query.Length > 200 ? insert.Query[..200] : insert.Query;
        var since = DateTime.UtcNow.AddHours(-1);
        var duplicateExists = await dbContext.MissedProductSearches.AsNoTracking()
            .AnyAsync(
                x => x.QueryText == queryText
                     && x.UserId == insert.UserId
                     && x.CreatedAtUtc >= since,
                cancellationToken);
        if (duplicateExists)
        {
            return;
        }

        dbContext.MissedProductSearches.Add(new MissedProductSearch
        {
            Id = Guid.NewGuid(),
            QueryText = queryText,
            UserId = insert.UserId,
            UserDisplayName = insert.UserDisplayName,
            UserEmail = insert.UserEmail,
            UserPhone = insert.UserPhone,
            CreatedAtUtc = DateTime.UtcNow,
            Notes = insert.Notes is { Length: > 500 } ? insert.Notes[..500] : insert.Notes
        });
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> ExpireDueNonOfferListingsAsync(CancellationToken cancellationToken = default)
    {
        var utcNow = DateTime.UtcNow;
        var expired = await dbContext.Products
            .Where(x =>
                x.ProductTypeId != 3
                && x.Status == ProductCatalogCodes.StatusActive
                && x.DisplayExpiresAtUtc != null
                && x.DisplayExpiresAtUtc <= utcNow)
            .ToListAsync(cancellationToken);
        if (expired.Count == 0)
        {
            return 0;
        }

        foreach (var product in expired)
        {
            product.Status = ProductCatalogCodes.StatusPaused;
            product.UpdatedAt = utcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return expired.Count;
    }

    public async Task<int> ExpireDueOfferDiscountsAsync(CancellationToken cancellationToken = default)
    {
        var utcNow = DateTime.UtcNow;
        // SQL Server: expire only rows whose discount window already ended.
        var candidates = await dbContext.Products
            .Where(x =>
                x.ProductTypeId == 3
                && x.DiscountPercentage != null
                && x.DiscountPercentage > 0
                && x.DiscountDays != null
                && x.DiscountDays > 0
                && EF.Functions.DateDiffDay(x.CreatedAt, utcNow) >= x.DiscountDays)
            .ToListAsync(cancellationToken);
        if (candidates.Count == 0)
        {
            return 0;
        }

        var changed = 0;
        foreach (var product in candidates)
        {
            var factor = 1m - (product.DiscountPercentage!.Value / 100m);
            if (factor > 0)
            {
                product.USDPrice = decimal.Round(product.USDPrice / factor, 2, MidpointRounding.AwayFromZero);
            }

            product.DiscountPercentage = null;
            product.DiscountDays = null;
            product.UpdatedAt = utcNow;
            changed++;
        }

        if (changed == 0)
        {
            return 0;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return changed;
    }

    public Task<int?> GetAdDisplayDurationDaysAsync(CancellationToken cancellationToken = default) =>
        dbContext.SystemSettings.AsNoTracking()
            .Where(x => x.Id == 1)
            .Select(x => (int?)x.AdDisplayDurationDays)
            .FirstOrDefaultAsync(cancellationToken);

    public async Task AddInboxNotificationAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        await dbContext.Notifications.AddAsync(notification, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<Guid> GetOrCreateNotificationRouteIdAsync(string name, CancellationToken cancellationToken = default)
    {
        var existing = await dbContext.NotificationRoutes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var route = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await dbContext.NotificationRoutes.AddAsync(route, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return route.Id;
    }

    public async Task<byte> GetOrCreateNotificationTypeIdAsync(string name, CancellationToken cancellationToken = default)
    {
        var existing = await dbContext.NotificationTypes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var type = new NotificationType { Name = name };
        await dbContext.NotificationTypes.AddAsync(type, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return type.Id;
    }

    private async Task RemoveRangeAsync<TEntity>(
        IQueryable<TEntity> query,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        var items = await query.ToListAsync(cancellationToken);
        if (items.Count == 0)
        {
            return;
        }

        if (dbContext is not DbContext efContext)
        {
            throw new InvalidOperationException("Database context must support entity removal.");
        }

        efContext.Set<TEntity>().RemoveRange(items);
    }

    private static List<string> ResolveVideoPaths(Product product)
    {
        var paths = new List<string>();
        void Add(string? path)
        {
            if (string.IsNullOrWhiteSpace(path)) return;
            var trimmed = path.Trim();
            if (paths.Any(p => string.Equals(p, trimmed, StringComparison.OrdinalIgnoreCase))) return;
            paths.Add(trimmed);
        }

        Add(product.VideoPath);
        foreach (var video in product.ProductVideos.OrderBy(x => x.Id))
        {
            Add(video.VideoPath);
        }

        return paths;
    }

    private static string EscapeLikeLiteral(string value) =>
        value.Replace("[", "[[]").Replace("%", "[%]").Replace("_", "[_]");

    private static string ToSqlLikePattern(string query) =>
        "%" + EscapeLikeLiteral(query.Trim()) + "%";

    private static string ToExactLikePattern(string word) =>
        EscapeLikeLiteral(word.Trim());

    private static bool ContainsWholeWord(string? text, string word)
    {
        if (string.IsNullOrWhiteSpace(text) || string.IsNullOrWhiteSpace(word))
        {
            return false;
        }

        var needle = word.Trim();
        if (needle.Length == 0) return false;
        var haystack = text.Trim();
        if (haystack.Length == 0) return false;
        if (string.Equals(haystack, needle, StringComparison.OrdinalIgnoreCase)) return true;
        var pattern = $@"(?<![\p{{L}}\p{{N}}]){Regex.Escape(needle)}(?![\p{{L}}\p{{N}}])";
        return Regex.IsMatch(haystack, pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    private static ProductPublicRow MapAdoRow(ProductAdoRepository.DbPublicProductRow r) => new()
    {
        ProductId = r.ProductId,
        ProductCode = r.ProductCode,
        RetailCode = r.RetailCode,
        NameEn = r.NameEn,
        USDPrice = r.USDPrice,
        OwnerId = r.OwnerId,
        Quantity = r.Quantity,
        DescriptionEn = r.DescriptionEn,
        MinimumOrderQuantity = r.MinimumOrderQuantity,
        MaximumOrderQuantity = r.MaximumOrderQuantity,
        Status = r.Status,
        IsApproved = r.IsApproved,
        DiscountPercentage = r.DiscountPercentage,
        DiscountDays = r.DiscountDays,
        ShippingDescriptionEn = r.ShippingDescriptionEn,
        ShippingDuration = r.ShippingDuration,
        OfferDuration = r.OfferDuration,
        SupplierNotesEn = r.SupplierNotesEn,
        Packaging = r.Packaging,
        PackagingDetails = r.PackagingDetails,
        RetailPackaging = r.RetailPackaging,
        RetailPackagingDetails = r.RetailPackagingDetails,
        RetailDescriptionEn = r.RetailDescriptionEn,
        Negotiable = r.Negotiable,
        IsFeatured = r.IsFeatured,
        ViewsCount = r.ViewsCount,
        VideoPath = r.VideoPath,
        VideoDurationSeconds = r.VideoDurationSeconds,
        CreatedAt = r.CreatedAt,
        CategoryName = r.CategoryName,
        CategoryNameAr = r.CategoryNameAr,
        ProductTypeName = r.ProductTypeName,
        UnitName = r.UnitName,
        OriginCountryName = r.OriginCountryName,
        OriginCountryNameAr = r.OriginCountryNameAr,
        DestinationCountryName = r.DestinationCountryName,
        DestinationCountryNameAr = r.DestinationCountryNameAr,
        LoadingPortName = r.LoadingPortName,
        LoadingPortNameAr = r.LoadingPortNameAr,
        ArrivalPortName = r.ArrivalPortName,
        ArrivalPortNameAr = r.ArrivalPortNameAr,
        CategoryId = r.CategoryId,
        Currency = r.Currency,
        ProductTypeId = r.ProductTypeId,
        AddressId = r.AddressId,
        RetailPrice = r.RetailPrice,
        RetailUnitId = r.RetailUnitId,
        RetailQuantity = r.RetailQuantity,
        RetailUnitName = r.RetailUnitName,
        RequestTypeId = r.RequestTypeId,
        RequestTypeName = r.RequestTypeName,
        BookingPriceTypeId = r.BookingPriceTypeId,
        BookingPriceTypeName = r.BookingPriceTypeName
    };
}
