using BusinessLayer.Dtos;
using DataLayer.Models;

namespace BusinessLayer.Interfaces;

public interface IOrdersAppService
{
    Task<object> PlaceOrderFromCartAsync(PlaceOrderInput input, CancellationToken cancellationToken = default);
    Task<object> PlaceBookingOrderAsync(CreateDirectOrderInput input, CancellationToken cancellationToken = default);
    Task<object> UpdateOrderStatusAsync(UpdateOrderStatusInput input, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrderCancellationReasonDto>> GetCancellationReasonsAsync(
        CancellationToken cancellationToken = default);
    Task<Guid> CreateOrdersFromPendingOrderAsync(Guid pendingOrderId, CancellationToken cancellationToken = default);
    Task<object> GetMyOrdersAsync(
        string userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<object> GetMyOffersAsync(
        string userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<object> GetOrderByIdAsync(string userId, long orderId, CancellationToken cancellationToken = default);
    Task<object> GetOffersForRequestAsync(
        string userId,
        string productId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default);
    Task<object> GetMyOffersOnMyRequestsAsync(
        string userId,
        int page,
        int pageSize,
        string? productId,
        byte? statusId,
        CancellationToken cancellationToken = default);
    Task<object> GetOrderVideosAsync(string userId, long orderId, CancellationToken cancellationToken = default);
    Task<object> UploadOrderVideoAsync(UploadOrderVideoInput input, CancellationToken cancellationToken = default);
    Task DeleteOrderVideoAsync(string userId, long orderId, long videoId, CancellationToken cancellationToken = default);
    Task<object> UploadOrderImageAsync(UploadOrderImageInput input, CancellationToken cancellationToken = default);
    Task DeleteOrderImageAsync(string userId, long orderId, long imageId, CancellationToken cancellationToken = default);
    Task<object> RequestOrderReturnAsync(RequestOrderReturnInput input, CancellationToken cancellationToken = default);
    Task<object> RespondToOrderReturnAsync(RespondToOrderReturnInput input, CancellationToken cancellationToken = default);
    Task<object> ApproveRequestOfferForAdminAsync(
        string adminUserId,
        long orderId,
        decimal? adminUnitPrice = null,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default);
    Task<object> SetRequestOfferAdvertiserPriceAsync(
        string adminUserId,
        long orderId,
        decimal adminUnitPrice,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default);
    Task<object> RejectRequestOfferForAdminAsync(
        string adminUserId,
        long orderId,
        string? reasonEn = null,
        string? reasonAr = null,
        CancellationToken cancellationToken = default);
    Task<object> SetCustomOrderStatusAsync(
        string adminUserId,
        long orderId,
        string statusNameEn,
        string statusNameAr,
        CancellationToken cancellationToken = default);
    Task<object> MarkOrderReceivedAsync(
        string adminUserId,
        long orderId,
        CancellationToken cancellationToken = default);
}

public interface IPaymentsAppService
{
    Task<CreateStripeCheckoutResult> CreateStripeCheckoutAsync(CreateStripeCheckoutInput input, CancellationToken cancellationToken = default);
    Task<Guid?> HandleWebhookAsync(string json, string signature, CancellationToken cancellationToken = default);
    Task<CheckoutStatusResult> GetCheckoutStatusAsync(string userId, string sessionId, CancellationToken cancellationToken = default);
    Task<ManualRefundResult> RefundCancelledOrderAsync(long orderId, CancellationToken cancellationToken = default);
}
