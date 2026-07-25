using System.Security.Claims;
using DataLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace RasAlSouqPresentaionLayer.Hubs;

[Authorize]
public sealed class OrderHub(IRasAlSouqDbContext dbContext) : Hub
{
    public async Task JoinOrder(long orderId)
    {
        if (orderId <= 0)
        {
            return;
        }

        var userId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(userId) || !Guid.TryParse(userId, out var parsedUserId))
        {
            return;
        }

        var canJoin = await dbContext.Orders
            .AsNoTracking()
            .AnyAsync(o =>
                o.Id == orderId
                && (o.FromUserId == parsedUserId
                    || o.ToUserId == parsedUserId
                    || (o.Product != null && o.Product.OwnerId == parsedUserId)));

        if (!canJoin)
        {
            // Admins/employees may also watch any order.
            var isStaff = await dbContext.Users
                .AsNoTracking()
                .AnyAsync(u => u.Id == parsedUserId && (u.RoleId == 1 || u.RoleId == 4));
            if (!isStaff)
            {
                return;
            }
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, GetGroupName(orderId));
    }

    public async Task LeaveOrder(long orderId)
    {
        if (orderId <= 0)
        {
            return;
        }

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetGroupName(orderId));
    }

    internal static string GetGroupName(long orderId) => $"Order_{orderId}";

    private string? GetCurrentUserId() =>
        Context.User?.FindFirst("EntityId")?.Value
        ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}
