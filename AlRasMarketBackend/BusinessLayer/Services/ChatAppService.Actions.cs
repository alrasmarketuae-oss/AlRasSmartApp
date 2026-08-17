using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed partial class ChatAppService
{
    public async Task<ChatMessageDto> ForwardMessageAsync(
        string fromUserId,
        ForwardChatMessageRequest request,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.MessageId))
        {
            throw new ArgumentException("MessageId is required.");
        }

        var actingUserId = ParseUserId(fromUserId);
        var targetUserId = ParseUserId(request.ToUserId);
        if (actingUserId == targetUserId)
        {
            throw new ArgumentException("Cannot send a message to yourself.");
        }

        var original = await dbContext.ChatMessages
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.MessageId == request.MessageId, ct)
            ?? throw new KeyNotFoundException("Message not found.");

        await EnsureCanAccessMessageAsync(actingUserId, original, ct);

        if (original.IsDeleted)
        {
            throw new InvalidOperationException("Deleted messages cannot be forwarded.");
        }

        if (ChatE2eContentHelper.IsEncryptedEnvelope(original.Content))
        {
            throw new InvalidOperationException("Encrypted messages cannot be forwarded.");
        }

        await EnsureUserExistsAsync(targetUserId, ct);
        var (fromId, toId) = await ResolveSupportSendPartiesAsync(actingUserId, targetUserId, ct);

        var utcNow = DateTime.UtcNow;
        var copy = new ChatMessage
        {
            MessageId = Guid.NewGuid().ToString("N"),
            FromUserId = fromId,
            ToUserId = toId,
            MessageType = original.MessageType,
            Content = original.Content,
            SentAtUtc = utcNow,
            IsEdited = false,
            IsSeen = false,
            IsDelivered = false,
            IsForwarded = true,
        };

        await dbContext.ChatMessages.AddAsync(copy, ct);
        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(fromId, toId);

        return MapToDto(copy, utcNow);
    }

    public async Task<ChatMessageDeletedDto> DeleteMessageAsync(
        string userId,
        string messageId,
        string scope,
        CancellationToken ct = default)
    {
        var actingUserId = ParseUserId(userId);
        var normalizedScope = (scope ?? string.Empty).Trim().ToLowerInvariant();
        if (normalizedScope is not ("me" or "everyone"))
        {
            throw new ArgumentException("Scope must be 'me' or 'everyone'.");
        }

        var message = await dbContext.ChatMessages
            .FirstOrDefaultAsync(m => m.MessageId == messageId, ct)
            ?? throw new KeyNotFoundException("Message not found.");

        await EnsureCanAccessMessageAsync(actingUserId, message, ct);

        var inboxOwnerId = await ResolveInboxOwnerIdAsync(actingUserId, ct);
        var utcNow = DateTime.UtcNow;

        if (normalizedScope == "everyone")
        {
            if (message.FromUserId != actingUserId && message.FromUserId != inboxOwnerId)
            {
                throw new UnauthorizedAccessException("Only the sender can delete this message for everyone.");
            }

            message.IsDeleted = true;
            message.DeletedAtUtc = utcNow;
            message.Content = string.Empty;
            message.ReplyToMessageId = null;
            message.ReplyToPreview = null;
            message.ReplyToMessageType = null;
            message.IsEdited = false;
            await dbContext.SaveChangesAsync(ct);
            InvalidateConversationCache(message.FromUserId, message.ToUserId);

            var dto = MapToDto(message, utcNow);
            return new ChatMessageDeletedDto(
                MessageId: message.MessageId,
                FromUserId: message.FromUserId.ToString("D"),
                ToUserId: message.ToUserId.ToString("D"),
                Scope: "everyone",
                DeletedByUserId: actingUserId.ToString("D"),
                IsDeleted: true,
                Message: dto);
        }

        if (message.FromUserId == actingUserId || message.FromUserId == inboxOwnerId)
        {
            message.DeletedForFromUser = true;
        }
        else
        {
            message.DeletedForToUser = true;
        }

        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(message.FromUserId, message.ToUserId);

        return new ChatMessageDeletedDto(
            MessageId: message.MessageId,
            FromUserId: message.FromUserId.ToString("D"),
            ToUserId: message.ToUserId.ToString("D"),
            Scope: "me",
            DeletedByUserId: actingUserId.ToString("D"),
            IsDeleted: false,
            Message: null);
    }

    private async Task ApplyReplySnapshotAsync(
        ChatMessage message,
        Guid fromId,
        Guid toId,
        string? replyToMessageId,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(replyToMessageId))
        {
            return;
        }

        var original = await dbContext.ChatMessages
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.MessageId == replyToMessageId, ct)
            ?? throw new ArgumentException("The message you are replying to was not found.");

        var sameConversation =
            (original.FromUserId == fromId && original.ToUserId == toId) ||
            (original.FromUserId == toId && original.ToUserId == fromId);
        if (!sameConversation)
        {
            throw new ArgumentException("You can only reply to a message in this conversation.");
        }

        if (original.IsDeleted)
        {
            throw new InvalidOperationException("Deleted messages cannot be replied to.");
        }

        message.ReplyToMessageId = original.MessageId;
        message.ReplyToMessageType = original.MessageType;
        message.ReplyToPreview = Truncate(BuildPreview(original), 80);
    }

    private async Task EnsureCanAccessMessageAsync(
        Guid actingUserId,
        ChatMessage message,
        CancellationToken ct)
    {
        var inboxOwnerId = await ResolveInboxOwnerIdAsync(actingUserId, ct);
        var isParty =
            message.FromUserId == actingUserId ||
            message.ToUserId == actingUserId ||
            message.FromUserId == inboxOwnerId ||
            message.ToUserId == inboxOwnerId;

        if (!isParty || IsHiddenForParty(message, inboxOwnerId))
        {
            throw new KeyNotFoundException("Message not found.");
        }
    }

    private static bool IsHiddenForParty(ChatMessage message, Guid partyId) =>
        (message.FromUserId == partyId && message.DeletedForFromUser)
        || (message.ToUserId == partyId && message.DeletedForToUser);
}
