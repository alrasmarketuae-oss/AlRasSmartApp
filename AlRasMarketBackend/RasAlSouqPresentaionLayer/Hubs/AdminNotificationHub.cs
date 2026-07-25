using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace RasAlSouqPresentaionLayer.Hubs;

[Authorize(Roles = "Admin,Employee")]
public sealed class AdminNotificationHub : Hub
{
    public const string GroupName = "AdminNotifications";

    public static string GetAgentGroupName(string userId) => $"AdminAgent_{userId}";

    public async Task JoinAdminNotifications()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName);

        var userId = GetCurrentUserId();
        if (!string.IsNullOrWhiteSpace(userId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, GetAgentGroupName(userId));
        }
    }

    public async Task LeaveAdminNotifications()
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName);

        var userId = GetCurrentUserId();
        if (!string.IsNullOrWhiteSpace(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetAgentGroupName(userId));
        }
    }

    private string? GetCurrentUserId() =>
        Context.User?.FindFirst("EntityId")?.Value
        ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}
