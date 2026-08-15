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
        IEnumerable<Guid>? participantUserIds = null,
        CancellationToken cancellationToken = default,
        string eventType = "order_updated")
    {
        if (orderId <= 0)
        {
            return;
        }

        var payload = new
        {
            orderId,
            statusId,
            statusNameEn,
            statusNameAr,
            eventType = string.IsNullOrWhiteSpace(eventType) ? "order_updated" : eventType,
            updatedAtUtc = DateTime.UtcNow
        };

        try
        {
            await hubContext.Clients
                .Group(OrderHub.GetGroupName(orderId))
                .SendAsync("orderUpdated", payload, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed broadcasting orderUpdated for order {OrderId}", orderId);
        }

        if (participantUserIds == null)
        {
            return;
        }

        foreach (var userId in participantUserIds.Where(id => id != Guid.Empty).Distinct())
        {
            try
            {
                await hubContext.Clients
                    .Group(OrderHub.GetUserGroupName(userId.ToString()))
                    .SendAsync("orderUpdated", payload, cancellationToken);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Failed broadcasting orderUpdated for order {OrderId} to user {UserId}",
                    orderId,
                    userId);
            }
        }
    }
}
