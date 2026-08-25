using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RasAlSouqPresentaionLayer.Hubs;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>
/// Event-driven side effects after a chat message is saved: SignalR, FCM, admin alerts.
/// Keeps the write path fast — persistence happens in <see cref="IChatAppService"/> first.
/// </summary>
public sealed class ChatMessageRealtimeHandler(
    IHubContext<ChatHub> chatHub,
    IFcmNotificationService fcmService,
    IRasAlSouqDbContext dbContext,
    IAdminRealtimeNotificationService adminRealtimeNotificationService) : IChatMessageCreatedHandler
{
    private const byte AdminRoleId = 1;

    public async Task HandleAsync(ChatMessageCreatedEvent evt, CancellationToken cancellationToken = default)
    {
        var result = evt.Message;

        try
        {
            await chatHub.Clients
                .Group(ChatHub.GetGroupName(result.ToUserId))
                .SendAsync("receiveMessage", result, cancellationToken);
        }
        catch
        {
            // ignore realtime failures
        }

        try
        {
            await SendChatPushIfNeededAsync(result, cancellationToken);
        }
        catch
        {
            // ignore push failures
        }

        try
        {
            await adminRealtimeNotificationService.NotifyAdminChatMessageAsync(
                result.ToUserId,
                result.FromUserId,
                cancellationToken);
        }
        catch
        {
            // ignore admin alert failures
        }
    }

    private async Task SendChatPushIfNeededAsync(ChatMessageDto result, CancellationToken ct)
    {
        if (!Guid.TryParse(result.ToUserId, out var recipientId) ||
            !Guid.TryParse(result.FromUserId, out var senderId))
        {
            return;
        }

        var userIds = new[] { recipientId, senderId };
        var users = await dbContext.Users
            .AsNoTracking()
            .Where(u => userIds.Contains(u.Id))
            .Select(u => new ChatPushUserInfo(
                u.Id,
                u.RoleId,
                u.FcmToken,
                u.FullName,
                u.CompanyName,
                u.PreferredLanguage,
                u.IsNotificationsOn))
            .ToListAsync(ct);

        var recipient = users.FirstOrDefault(u => u.Id == recipientId);
        var sender = users.FirstOrDefault(u => u.Id == senderId);

        if (recipient is null || recipient.RoleId == AdminRoleId)
        {
            return;
        }

        if (!NotificationDeliveryPrefs.AllowsPushAndEmail(recipient.IsNotificationsOn))
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(recipient.FcmToken))
        {
            return;
        }

        var senderName = ResolveChatSenderName(sender, recipient.PreferredLanguage);
        var preview = NotificationMessages.BuildChatPushBody(
            recipient.PreferredLanguage,
            result.MessageType,
            result.Content);

        await fcmService.SendNotificationAsync(recipient.FcmToken!, new FcmNotificationPayload
        {
            Title = senderName,
            Body = preview,
            Type = "chat_message",
            ReferenceId = result.MessageId,
            RouteId = result.FromUserId,
            Data = new Dictionary<string, string>
            {
                ["messageType"] = result.MessageType.ToString(),
                ["fromUserId"] = result.FromUserId,
                ["toUserId"] = result.ToUserId,
                ["senderName"] = senderName,
                ["messagePreview"] = preview,
                ["sentAtUtc"] = result.SentAtUtc,
            }
        }, ct);
    }

    private static string ResolveChatSenderName(ChatPushUserInfo? sender, string? recipientLanguage)
    {
        if (sender is null)
        {
            return NotificationMessages.ChatFallbackSenderName(recipientLanguage);
        }

        if (sender.RoleId == AdminRoleId)
        {
            if (!string.IsNullOrWhiteSpace(sender.CompanyName))
            {
                return sender.CompanyName.Trim();
            }

            if (!string.IsNullOrWhiteSpace(sender.FullName))
            {
                return sender.FullName.Trim();
            }

            return NotificationMessages.ChatAdminSenderName(recipientLanguage);
        }

        if (!string.IsNullOrWhiteSpace(sender.CompanyName))
        {
            return sender.CompanyName.Trim();
        }

        return string.IsNullOrWhiteSpace(sender.FullName)
            ? NotificationMessages.ChatUserFallbackName(recipientLanguage)
            : sender.FullName.Trim();
    }

    private sealed record ChatPushUserInfo(
        Guid Id,
        byte RoleId,
        string? FcmToken,
        string FullName,
        string? CompanyName,
        string PreferredLanguage,
        bool IsNotificationsOn);
}
