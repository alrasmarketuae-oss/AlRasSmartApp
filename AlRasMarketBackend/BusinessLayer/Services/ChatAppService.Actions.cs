using System.Text.RegularExpressions;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed partial class ChatAppService
{
    private static readonly Regex AskSupplierReplyMarker =
        new(@"ASK_SUPPLIER_REPLY\s*:", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    private static readonly Regex AskSupplierProductMarker =
        new(@"ASK_SUPPLIER_PRODUCT:\s*([0-9a-fA-F-]{36})", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    private static readonly Regex AskSupplierRequesterMarker =
        new(@"ASK_SUPPLIER_REQUESTER:\s*([0-9a-fA-F-]{36})", RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    /// <summary>
    /// Supplier answered YES/NO on a price ask → copy that reply into the original
    /// asker's support thread. Admin still keeps the supplier→admin message.
    /// </summary>
    public async Task<ChatMessageDto?> TryRelayAskSupplierReplyToRequesterAsync(
        ChatMessageDto supplierToAdminReply,
        CancellationToken ct = default)
    {
        var content = supplierToAdminReply.Content?.Trim() ?? string.Empty;
        if (content.Length == 0 || !AskSupplierReplyMarker.IsMatch(content))
        {
            return null;
        }

        if (!Guid.TryParse(supplierToAdminReply.FromUserId, out var supplierId) ||
            !Guid.TryParse(supplierToAdminReply.ToUserId, out var toUserId))
        {
            return null;
        }

        var supportAdminId = await GetSupportAdminUserIdAsync(ct);

        // Only relay replies that landed on the shared support inbox (supplier → admin).
        if (toUserId != supportAdminId || supplierId == supportAdminId)
        {
            return null;
        }

        var requesterId = TryExtractRequesterUserId(content);
        if (requesterId is null)
        {
            requesterId = await FindRequesterFromPriorAskAsync(
                supportAdminId,
                supplierId,
                TryExtractProductId(content),
                ct);
        }

        if (requesterId is null ||
            requesterId == supportAdminId ||
            requesterId == supplierId)
        {
            return null;
        }

        await EnsureUserExistsAsync(requesterId.Value, ct);

        var utcNow = DateTime.UtcNow;
        var copy = new ChatMessage
        {
            MessageId = Guid.NewGuid().ToString("N"),
            FromUserId = supportAdminId,
            ToUserId = requesterId.Value,
            MessageType = ChatMessageType.Text,
            Content = content,
            SentAtUtc = utcNow,
            IsEdited = false,
            IsSeen = false,
            IsDelivered = false,
            IsForwarded = true,
        };

        await dbContext.ChatMessages.AddAsync(copy, ct);
        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(supportAdminId, requesterId.Value);
        InvalidateSupportCaches(requesterId.Value, supportAdminId);

        return MapToDto(copy, utcNow);
    }

    private static Guid? TryExtractRequesterUserId(string content)
    {
        var match = AskSupplierRequesterMarker.Match(content);
        if (!match.Success || !Guid.TryParse(match.Groups[1].Value, out var id))
        {
            return null;
        }

        return id;
    }

    private static string? TryExtractProductId(string content)
    {
        var match = AskSupplierProductMarker.Match(content);
        return match.Success ? match.Groups[1].Value.Trim() : null;
    }

    private async Task<Guid?> FindRequesterFromPriorAskAsync(
        Guid supportAdminId,
        Guid supplierId,
        string? productId,
        CancellationToken ct)
    {
        var recentAsks = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(m =>
                !m.IsDeleted &&
                m.MessageType == ChatMessageType.Text &&
                ((m.FromUserId == supportAdminId && m.ToUserId == supplierId) ||
                 (m.FromUserId == supplierId && m.ToUserId == supportAdminId)) &&
                m.Content.Contains("ASK_SUPPLIER_PRICE") &&
                m.Content.Contains("ASK_SUPPLIER_REQUESTER"))
            .OrderByDescending(m => m.SentAtUtc)
            .Select(m => m.Content)
            .Take(30)
            .ToListAsync(ct);

        foreach (var ask in recentAsks)
        {
            if (!string.IsNullOrWhiteSpace(productId) &&
                ask.IndexOf(productId, StringComparison.OrdinalIgnoreCase) < 0)
            {
                continue;
            }

            var requesterId = TryExtractRequesterUserId(ask);
            if (requesterId.HasValue)
            {
                return requesterId;
            }
        }

        return null;
    }

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
