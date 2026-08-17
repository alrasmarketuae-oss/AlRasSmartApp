using DataLayer.Models;

namespace DataLayer.Interfaces;

/// <summary>
/// Product data access — Business calls methods only (no DbSet / EF leak).
/// </summary>
public interface IProductDataAccess
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    Task<string> InsertProductAsync(Product product, CancellationToken cancellationToken = default);

    Task<List<ProductPublicRow>> GetProductsByIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);

    Task<string> AllocateProductCodeAsync(CancellationToken cancellationToken = default);

    Task<Product?> GetProductByIdTrackedAsync(Guid productId, CancellationToken cancellationToken = default);

    Task<Product?> GetProductWithMediaForDeleteAsync(Guid productId, CancellationToken cancellationToken = default);

    Task<ProductMediaSnapshot> GetProductMediaPathsForSnapshotAsync(
        Guid productId,
        CancellationToken cancellationToken = default);

    Task<List<long>> GetProductImageIdsByProductIdAsync(
        Guid productId,
        CancellationToken cancellationToken = default);

    Task<ProductDeleteCascadeResult> DeleteProductCascadeAsync(
        Product product,
        CancellationToken cancellationToken = default);

    Task<ProductOrderDeleteMediaResult> DeleteProductOrdersAndDependentsAsync(
        Guid productId,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> GetHomeCatalogPageAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<List<ProductPublicRow>> GetPublicProductsByCodeAsync(
        string productCode,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<ProductPublicRow?> GetPublicProductByIdAsync(
        Guid productId,
        CancellationToken cancellationToken = default);

    Task<ProductPublicRow?> GetPublicProductByCodeExactAsync(
        string productCode,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// tokenWordGroups: for each query token, the token plus its synonyms (OR within group, AND across groups).
    /// Whole-word filtering is applied inside DataLayer (same logic as before).
    /// </summary>
    Task<(List<ProductPublicRow> Products, int TotalCount)> SearchPublicCatalogByTokenWordsAsync(
        IReadOnlyList<IReadOnlyList<string>> tokenWordGroups,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Products, int TotalCount)> SearchPublicCatalogByNameLooseAsync(
        string queryText,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<ProductSearchNameIndex> GetSearchNameIndexAsync(CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> GetProductsByTypePageAsync(
        byte productTypeId,
        bool retailHomeStyle,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> GetProductsByCategoryPageAsync(
        byte categoryId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> GetFeaturedProductsPageAsync(
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<List<ProductPublicRow>> SearchPublicProductsByNameAnyAsync(
        IReadOnlyList<string> matchWords,
        int take,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> SearchPublicProductsByNameAnyPageAsync(
        IReadOnlyList<string> matchWords,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<(List<ProductPublicRow> Rows, int TotalCount)> GetPublicProductsByCategoryPageAsync(
        byte categoryId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<List<ProductNameTranslationRow>> GetProductNameTranslationsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);

    Task<List<ProductMediaPathRow>> GetProductImagePathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);

    Task<List<ProductMediaPathRow>> GetProductDocumentPathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);

    Task<List<ProductMediaPathRow>> GetProductVideoPathsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);

    Task<Dictionary<byte, Category>> GetCategoriesByIdsAsync(
        IReadOnlyList<byte> categoryIds,
        CancellationToken cancellationToken = default);

    Task<List<AddressDisplayRow>> GetAddressDisplayRowsByIdsAsync(
        IReadOnlyList<Guid> addressIds,
        CancellationToken cancellationToken = default);

    Task<string?> GetUserDisplayNameAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<List<OwnerListingRow>> GetOwnerListingsAsync(
        Guid ownerId,
        CancellationToken cancellationToken = default);

    Task<Dictionary<Guid, int>> GetPendingOfferCountsByProductIdsAsync(
        IReadOnlyList<Guid> productIds,
        byte retailProductTypeId,
        byte awaitingSellerApprovalStatusId,
        CancellationToken cancellationToken = default);

    Task<List<InternationalShippingPost>> GetOwnerShippingPostsAsync(
        Guid ownerId,
        CancellationToken cancellationToken = default);

    Task<User?> GetUserByIdAsync(Guid userId, bool tracked, CancellationToken cancellationToken = default);

    Task<string?> GetUserPhoneByIdAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<bool> AddressBelongsToUserAsync(
        Guid addressId,
        Guid userId,
        CancellationToken cancellationToken = default);

    Task<ProductType?> GetProductTypeByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<bool> ProductTypeExistsByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<RequestType?> GetRequestTypeByIdAsync(byte id, CancellationToken cancellationToken = default);

    Task<RequestType?> GetRequestTypeByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<BookingPriceType?> GetBookingPriceTypeByIdAsync(byte id, CancellationToken cancellationToken = default);

    Task<BookingPriceType?> GetBookingPriceTypeByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<Category?> GetCategoryByIdAsync(byte id, CancellationToken cancellationToken = default);

    Task<Category?> GetCategoryByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<bool> CategoryExistsByIdAsync(byte id, CancellationToken cancellationToken = default);

    Task<bool> CategoryExistsByNameAsync(string name, CancellationToken cancellationToken = default);

    Task<List<ProductEditTranslationHint>> GetProductEditTranslationHintsAsync(
        Guid productId,
        CancellationToken cancellationToken = default);

    Task TryAddMissedProductSearchAsync(
        MissedProductSearchInsert insert,
        CancellationToken cancellationToken = default);

    Task<int> ExpireDueNonOfferListingsAsync(CancellationToken cancellationToken = default);

    Task<int> ExpireDueOfferDiscountsAsync(CancellationToken cancellationToken = default);

    Task<int?> GetAdDisplayDurationDaysAsync(CancellationToken cancellationToken = default);

    Task AddInboxNotificationAsync(Notification notification, CancellationToken cancellationToken = default);

    Task<Guid> GetOrCreateNotificationRouteIdAsync(string name, CancellationToken cancellationToken = default);

    Task<byte> GetOrCreateNotificationTypeIdAsync(string name, CancellationToken cancellationToken = default);
}
