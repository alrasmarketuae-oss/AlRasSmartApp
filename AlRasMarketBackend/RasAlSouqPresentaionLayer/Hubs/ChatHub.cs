using System.Security.Claims;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace RasAlSouqPresentaionLayer.Hubs;

[Authorize]
public sealed class ChatHub(IChatAppService chatAppService, IHubContext<ChatHub> hubContext) : Hub
{
    public async Task JoinUserChat(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, GetGroupName(userId));

        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)
            || !string.Equals(currentUserId, userId, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var supportInboxOwnerId = await chatAppService.GetSupportInboxOwnerIdForViewerAsync(currentUserId);
        if (!string.IsNullOrWhiteSpace(supportInboxOwnerId))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, GetGroupName(supportInboxOwnerId));
        }
    }

    public async Task LeaveUserChat(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId))
        {
            return;
        }

        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetGroupName(userId));

        var currentUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(currentUserId)
            || !string.Equals(currentUserId, userId, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var supportInboxOwnerId = await chatAppService.GetSupportInboxOwnerIdForViewerAsync(currentUserId);
        if (!string.IsNullOrWhiteSpace(supportInboxOwnerId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetGroupName(supportInboxOwnerId));
        }
    }

    /// <summary>
    /// يُستدعى من تطبيق المستلم بعد استلام الرسالة فعلياً (SignalR receiveMessage).
    /// لا يُعلّم delivered عند الإرسال من السيرفر — فقط عند تأكيد الجهاز.
    /// </summary>
    public async Task AcknowledgeDelivery(string senderUserId)
    {
        var recipientUserId = GetCurrentUserId();
        if (string.IsNullOrWhiteSpace(recipientUserId) || string.IsNullOrWhiteSpace(senderUserId))
        {
            return;
        }

        var result = await chatAppService.MarkConversationDeliveredAsync(recipientUserId, senderUserId);
        if (result.MarkedCount < 1)
        {
            return;
        }

        await hubContext.Clients
            .Group(GetGroupName(result.FromUserId))
            .SendAsync("messagesDelivered", result);
    }

    internal static string GetGroupName(string userId) => $"UserChat_{userId}";

    private string? GetCurrentUserId() =>
        Context.User?.FindFirst("EntityId")?.Value
        ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}
