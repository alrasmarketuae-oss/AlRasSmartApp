using DataLayer.Models;

namespace DataLayer.Interfaces;

/// <summary>
/// Order data access — Business calls methods only (no DbSet / EF leak).
/// </summary>
public interface IOrderDataAccess
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    Task AddOrderAsync(Order order, CancellationToken cancellationToken = default);
    Task AddPendingOrderAsync(PendingOrder pendingOrder, CancellationToken cancellationToken = default);
    Task AddOrderVideoAsync(OrderVideo orderVideo, CancellationToken cancellationToken = default);
    Task AddOrderImageAsync(OrderImage orderImage, CancellationToken cancellationToken = default);
    void RemoveOrderVideo(OrderVideo orderVideo);
    void RemoveOrderImage(OrderImage orderImage);
    void RemoveCartItems(IEnumerable<CartItem> cartItems);

    Task<User?> GetUserByIdAsync(Guid userId, bool tracked = true, CancellationToken cancellationToken = default);
    Task<User?> GetUserByIdAsNoTrackingAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Product?> GetProductForOrderAsync(Guid productId, CancellationToken cancellationToken = default);
    Task<Dictionary<Guid, Product>> GetProductsByIdsWithUnitsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);
    Task<Order?> GetOrderByIdTrackedAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithProductForStatusAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithProductForReturnAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithProductForReturnResponseAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithVideosAsync(long orderId, CancellationToken cancellationToken = default);
    Task<OrderVideo?> GetOrderVideoWithOrderAsync(
        long videoId,
        long orderId,
        CancellationToken cancellationToken = default);
    Task<OrderImage?> GetOrderImageWithOrderAsync(
        long imageId,
        long orderId,
        CancellationToken cancellationToken = default);
    Task<int> CountOrderImagesAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithListDetailsAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithDetailDetailsAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Order?> GetOrderWithProductAsNoTrackingAsync(long orderId, CancellationToken cancellationToken = default);
    Task<Cart?> GetCartForCheckoutAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<Cart?> GetCartWithItemsAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<PendingOrder?> GetPendingOrderWithItemsAsync(Guid pendingOrderId, CancellationToken cancellationToken = default);
    Task<Address?> GetAddressForUserAsync(
        Guid addressId,
        Guid userId,
        CancellationToken cancellationToken = default);
    Task<Address?> GetAddressByUserCityLineAsync(
        Guid userId,
        Guid cityId,
        string addressLine1Lower,
        CancellationToken cancellationToken = default);
    Task<Guid?> GetProductOwnerIdAsync(Guid productId, CancellationToken cancellationToken = default);
    Task<Product?> GetProductAsNoTrackingAsync(Guid productId, CancellationToken cancellationToken = default);
    Task<int> CountPendingSellerActionsAsync(Guid productId, CancellationToken cancellationToken = default);

    Task<(List<Order> Orders, int TotalCount)> GetMyOrdersPageAsync(
        Guid userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<(List<Order> Orders, int TotalCount)> GetMyOffersPageAsync(
        Guid userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<(List<Order> Orders, int TotalCount)> GetOffersForRequestPageAsync(
        Guid productId,
        bool isAdminViewer,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<(List<Order> Orders, int TotalCount)> GetMyOffersOnMyRequestsPageAsync(
        Guid userId,
        int page,
        int pageSize,
        Guid? productId,
        byte? statusId,
        CancellationToken cancellationToken = default);

    Task<List<OrderProductNotifyMeta>> GetProductNotifyMetaByIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default);
    Task<List<OrderNotifyUserRow>> GetUsersNotifyByIdsAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken = default);
    Task<List<OrderNotifyUserRow>> GetAdminFcmRecipientsAsync(CancellationToken cancellationToken = default);
    Task<List<OrderNotifyUserRow>> GetAdminNotifyRecipientsAsync(CancellationToken cancellationToken = default);
    Task<OrderNotifyUserRow?> GetUserNotifyByIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<string?> GetProductNameEnAsync(Guid productId, CancellationToken cancellationToken = default);
    Task<List<OrderNotifyUserRow>> GetUsersByIdsAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken = default);
    Task AddInboxNotificationAsync(Notification notification, CancellationToken cancellationToken = default);
    Task<Guid> GetOrCreateNotificationRouteIdAsync(string name, CancellationToken cancellationToken = default);
    Task<byte> GetOrCreateNotificationTypeIdAsync(string name, CancellationToken cancellationToken = default);

    Task<AdminOrderStatsRow> GetAdminOrderStatsAsync(CancellationToken cancellationToken = default);
    Task<Order?> GetAdminVisibleOrderWithDetailDetailsAsync(
        long orderId,
        CancellationToken cancellationToken = default);
    Task<PendingPayment?> GetPendingPaymentByOrderIdAsync(
        long orderId,
        CancellationToken cancellationToken = default);
    Task<(List<Order> Orders, int TotalCount)> GetAdminOrdersPageAsync(
        AdminOrdersPageFilter filter,
        CancellationToken cancellationToken = default);
    Task<List<OrderGroupSiblingRow>> GetOrderGroupSiblingsAsync(
        IReadOnlyList<Guid> groupIds,
        CancellationToken cancellationToken = default);

    Task<List<OrderCancellationReason>> GetActiveCancellationReasonsAsync(
        CancellationToken cancellationToken = default);

    Task<OrderCancellationReason?> GetCancellationReasonByIdAsync(
        byte id,
        CancellationToken cancellationToken = default);
}
