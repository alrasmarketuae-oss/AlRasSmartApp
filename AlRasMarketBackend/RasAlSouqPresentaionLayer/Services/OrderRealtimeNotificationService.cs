using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.SignalR;
using RasAlSouqPresentaionLayer.Hubs;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class OrderRealtimeNotificationService(
    IHubContext<OrderHub> hubContext,
    ILogger<OrderRealtimeNotificationService> logger) : IOrderRealtimeNotificationService
{
    public async Task NotifyOrderUpdatedAsync(
        long orderId,
        byte? statusId = null,
        string? statusNameEn = null,
        string? statusNameAr = null,
        CancellationToken cancellationToken = default)
    {
        if (orderId <= 0)
        {
            return;
        }

        try
        {
            await hubContext.Clients
                .Group(OrderHub.GetGroupName(orderId))
                .SendAsync(
                    "orderUpdated",
                    new
                    {
                        orderId,
                        statusId,
                        statusNameEn,
                        statusNameAr,
                        updatedAtUtc = DateTime.UtcNow
                    },
                    cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed broadcasting orderUpdated for order {OrderId}", orderId);
        }
    }
}
