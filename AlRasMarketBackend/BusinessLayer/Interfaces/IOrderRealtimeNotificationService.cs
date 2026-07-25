namespace BusinessLayer.Interfaces;

public interface IOrderRealtimeNotificationService
{
    /// <summary>
    /// Pushes a lightweight order-changed event to clients watching this order (SignalR group).
    /// </summary>
    Task NotifyOrderUpdatedAsync(
        long orderId,
        byte? statusId = null,
        string? statusNameEn = null,
        string? statusNameAr = null,
        CancellationToken cancellationToken = default);
}
