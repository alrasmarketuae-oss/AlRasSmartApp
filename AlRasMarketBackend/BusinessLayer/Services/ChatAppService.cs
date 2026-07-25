using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Services;

public sealed partial class ChatAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache,
    IConfiguration configuration,
    IAdminPermissionService permissionService,
    IMediaStorageService mediaStorage) : IChatAppService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(3);
    private static readonly TimeSpan OnlineThreshold = TimeSpan.FromMinutes(5);
    private const string ChatImagesFolder = "chat-images";
    private const string ChatVoiceFolder = "chat-voice";
    private const string ChatVideosFolder = "chat-videos";
    private const long MaxChatVideoBytes = 30L * 1024 * 1024;

    public async Task<ChatInboxDto> GetMyInboxAsync(string userId, CancellationToken ct = default)
    {
        var viewerId = ParseUserId(userId);
        var inboxOwnerId = await ResolveInboxOwnerIdAsync(viewerId, ct);
        var isSharedSupportInbox = inboxOwnerId != viewerId;
        var cacheKey = isSharedSupportInbox
            ? ChatCacheKeys.InboxForViewer(inboxOwnerId, viewerId)
            : ChatCacheKeys.Inbox(inboxOwnerId);

        if (!isSharedSupportInbox
            && cache.TryGetValue(cacheKey, out ChatInboxDto? cached)
            && cached is not null)
        {
            return cached with { FromCache = true };
        }

        var contacts = await BuildContactsAsync(inboxOwnerId, viewerId, ct);
        var myLastSeen = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == viewerId)
            .Select(x => x.LastSeenAtUtc)
            .FirstOrDefaultAsync(ct);

        var totalUnread = contacts.Sum(c => c.UnreadCount);

        var inbox = new ChatInboxDto(
            Contacts: contacts,
            MyLastSeenAtUtc: FormatUtc(myLastSeen),
            TotalUnreadCount: totalUnread,
            FromCache: false);

        if (!isSharedSupportInbox)
        {
            cache.Set(cacheKey, inbox, CacheTtl);
        }

        return inbox;
    }

    public async Task<ChatUnreadSummaryDto> GetUnreadCountAsync(string userId, CancellationToken ct = default)
    {
        var viewerId = ParseUserId(userId);
        var inboxOwnerId = await ResolveInboxOwnerIdAsync(viewerId, ct);
        var isSharedSupportInbox = inboxOwnerId != viewerId;
        var cacheKey = isSharedSupportInbox
            ? ChatCacheKeys.UnreadForViewer(inboxOwnerId, viewerId)
            : ChatCacheKeys.Unread(inboxOwnerId);

        if (!isSharedSupportInbox
            && cache.TryGetValue(cacheKey, out ChatUnreadSummaryDto? cached)
            && cached is not null)
        {
            return cached;
        }

        var query = dbContext.ChatMessages
            .AsNoTracking()
            .Where(m => m.ToUserId == inboxOwnerId && !m.IsSeen);

        int count;
        if (isSharedSupportInbox && !await IsSuperAdminUserAsync(viewerId, ct))
        {
            var lockedByOthers = await dbContext.ChatSupportAssignments
                .AsNoTracking()
                .Where(x => x.ReleasedAtUtc == null && x.AgentUserId != viewerId)
                .Select(x => x.CustomerUserId)
                .ToListAsync(ct);

            count = lockedByOthers.Count == 0
                ? await query.CountAsync(ct)
                : await query.CountAsync(m => !lockedByOthers.Contains(m.FromUserId), ct);
        }
        else
        {
            count = await query.CountAsync(ct);
        }

        var summary = new ChatUnreadSummaryDto(count);

        if (!isSharedSupportInbox)
        {
            cache.Set(cacheKey, summary, CacheTtl);
        }

        return summary;
    }

    public async Task<IReadOnlyList<ChatContactDto>> SearchConversationsAsync(
        string userId,
        string query,
        CancellationToken ct = default)
    {
        var ownerId = ParseUserId(userId);
        var inboxOwnerId = await ResolveInboxOwnerIdAsync(ownerId, ct);
        var term = query.Trim();
        if (term.Length < 2)
        {
            return [];
        }

        var contacts = await BuildContactsAsync(inboxOwnerId, ownerId, ct);
        if (contacts.Count == 0)
        {
            return [];
        }

        var matchingOtherIds = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(m =>
                (m.FromUserId == ownerId || m.ToUserId == ownerId) &&
                m.MessageType == ChatMessageType.Text &&
                m.Content.Contains(term) && !m.Content.Contains("\"e2e\":true"))
            .Select(m => m.FromUserId == ownerId ? m.ToUserId : m.FromUserId)
            .Distinct()
            .ToListAsync(ct);

        var messageMatchSet = matchingOtherIds.ToHashSet();

        return contacts
            .Where(c =>
                c.DisplayName.Contains(term, StringComparison.OrdinalIgnoreCase) ||
                (Guid.TryParse(c.ContactUserId, out var contactId) && messageMatchSet.Contains(contactId)))
            .OrderByDescending(c => c.LastMessageSentAtUtc)
            .ToList();
    }

    public async Task<IReadOnlyList<ChatMessageDto>> GetConversationAsync(
        string userId,
        string otherUserId,
        CancellationToken ct = default)
    {
        var actingUserId = ParseUserId(userId);
        var otherId = ParseUserId(otherUserId);
        await EnsureUserExistsAsync(otherId, ct);

        var (viewerId, partnerId) = await ResolveSupportViewerPartiesAsync(actingUserId, otherId, ct);

        var cacheKey = ChatCacheKeys.Thread(viewerId, partnerId);
        if (cache.TryGetValue(cacheKey, out IReadOnlyList<ChatMessageDto>? cached) && cached is not null)
        {
            return cached;
        }

        var messages = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(m =>
                (m.FromUserId == viewerId && m.ToUserId == partnerId) ||
                (m.FromUserId == partnerId && m.ToUserId == viewerId))
            .OrderBy(m => m.SentAtUtc)
            .ToListAsync(ct);

        var utcNow = DateTime.UtcNow;
        var result = messages.Select(m => MapToDto(m, utcNow)).ToList();
        cache.Set(cacheKey, result, CacheTtl);
        return result;
    }

    public async Task<ChatMessageDto> CreateMessageAsync(
        string fromUserId,
        CreateChatMessageRequest request,
        CancellationToken ct = default)
    {
        var actingUserId = ParseUserId(fromUserId);
        var targetUserId = ParseUserId(request.ToUserId);

        if (actingUserId == targetUserId)
        {
            throw new ArgumentException("Cannot send a message to yourself.");
        }

        await EnsureUserExistsAsync(targetUserId, ct);
        ValidateMessageContent(request.MessageType, request.Content);

        var (fromId, toId) = await ResolveSupportSendPartiesAsync(actingUserId, targetUserId, ct);

        var utcNow = DateTime.UtcNow;
        var message = new ChatMessage
        {
            MessageId = Guid.NewGuid().ToString("N"),
            FromUserId = fromId,
            ToUserId = toId,
            MessageType = MapMessageType(request.MessageType),
            Content = request.Content.Trim(),
            SentAtUtc = utcNow,
            IsEdited = false,
            IsSeen = false,
            IsDelivered = false
        };

        await dbContext.ChatMessages.AddAsync(message, ct);
        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(fromId, toId);

        return MapToDto(message, utcNow);
    }

    public async Task<ChatMessageDto> UpdateMessageAsync(
        string userId,
        string messageId,
        UpdateChatMessageRequest request,
        CancellationToken ct = default)
    {
        var ownerId = ParseUserId(userId);
        var message = await dbContext.ChatMessages
            .FirstOrDefaultAsync(m => m.MessageId == messageId, ct)
            ?? throw new KeyNotFoundException("Message not found.");

        if (message.FromUserId != ownerId)
        {
            throw new UnauthorizedAccessException("Only the sender can edit this message.");
        }

        if (message.MessageType != ChatMessageType.Text)
        {
            throw new InvalidOperationException("Only text messages can be edited.");
        }

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new ArgumentException("Content is required.");
        }

        message.Content = request.Content.Trim();
        message.IsEdited = true;
        message.EditedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(ct);

        InvalidateConversationCache(message.FromUserId, message.ToUserId);
        return MapToDto(message, DateTime.UtcNow);
    }

    public async Task<int> MarkConversationSeenAsync(
        string viewerUserId,
        string otherUserId,
        CancellationToken ct = default)
    {
        var actingViewerId = ParseUserId(viewerUserId);
        var otherId = ParseUserId(otherUserId);
        var (viewerId, partnerId) = await ResolveSupportViewerPartiesAsync(actingViewerId, otherId, ct);
        var utcNow = DateTime.UtcNow;

        var messages = await dbContext.ChatMessages
            .Where(m =>
                m.FromUserId == partnerId &&
                m.ToUserId == viewerId &&
                !m.IsSeen)
            .ToListAsync(ct);

        if (messages.Count == 0)
        {
            return 0;
        }

        foreach (var message in messages)
        {
            message.IsSeen = true;
            message.SeenAtUtc = utcNow;
        }

        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(viewerId, partnerId);
        return messages.Count;
    }

    public async Task<ChatMessagesDeliveredDto> MarkConversationDeliveredAsync(
        string recipientUserId,
        string otherUserId,
        CancellationToken ct = default)
    {
        var actingRecipientId = ParseUserId(recipientUserId);
        var otherId = ParseUserId(otherUserId);
        var (recipientId, senderId) = await ResolveSupportViewerPartiesAsync(actingRecipientId, otherId, ct);
        var utcNow = DateTime.UtcNow;

        var messages = await dbContext.ChatMessages
            .Where(m =>
                m.FromUserId == senderId &&
                m.ToUserId == recipientId &&
                !m.IsDelivered)
            .ToListAsync(ct);

        if (messages.Count == 0)
        {
            return new ChatMessagesDeliveredDto(
                senderId.ToString("D"),
                recipientId.ToString("D"),
                [],
                FormatUtc(utcNow)!,
                0);
        }

        foreach (var message in messages)
        {
            message.IsDelivered = true;
            message.DeliveredAtUtc = utcNow;
        }

        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(recipientId, senderId);

        return new ChatMessagesDeliveredDto(
            senderId.ToString("D"),
            recipientId.ToString("D"),
            messages.Select(m => m.MessageId).ToList(),
            FormatUtc(utcNow)!,
            messages.Count);
    }

    public async Task<(ChatMessageDto Message, ChatMessagesDeliveredDto? DeliveryEvent)> TryMarkMessageDeliveredAsync(
        string messageId,
        CancellationToken ct = default)
    {
        var message = await dbContext.ChatMessages
            .FirstOrDefaultAsync(m => m.MessageId == messageId, ct)
            ?? throw new KeyNotFoundException("Message not found.");

        var utcNow = DateTime.UtcNow;
        if (message.IsDelivered)
        {
            return (MapToDto(message, utcNow), null);
        }

        message.IsDelivered = true;
        message.DeliveredAtUtc = utcNow;
        await dbContext.SaveChangesAsync(ct);
        InvalidateConversationCache(message.FromUserId, message.ToUserId);

        var deliveryEvent = new ChatMessagesDeliveredDto(
            message.FromUserId.ToString("D"),
            message.ToUserId.ToString("D"),
            [message.MessageId],
            FormatUtc(utcNow)!,
            1);

        return (MapToDto(message, utcNow), deliveryEvent);
    }

    public async Task<ChatPresenceDto> UpdatePresenceAsync(string userId, CancellationToken ct = default)
    {
        var parsedId = ParseUserId(userId);
        var user = await dbContext.Users.FirstOrDefaultAsync(x => x.Id == parsedId, ct)
            ?? throw new KeyNotFoundException("User not found.");

        var utcNow = DateTime.UtcNow;
        user.LastSeenAtUtc = utcNow;
        await dbContext.SaveChangesAsync(ct);

        return new ChatPresenceDto(
            UserId: parsedId.ToString("D"),
            LastSeenAtUtc: FormatUtc(utcNow),
            IsOnline: true);
    }

    public async Task<ChatUploadResultDto> UploadMediaAsync(
        string userId,
        ChatApiMessageType messageType,
        IFormFile file,
        string webRootPath,
        CancellationToken ct = default)
    {
        _ = ParseUserId(userId);

        if (file is null || file.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        return messageType switch
        {
            ChatApiMessageType.Image => await UploadImageAsync(file, webRootPath, ct),
            ChatApiMessageType.Voice => await UploadVoiceAsync(file, webRootPath, ct),
            ChatApiMessageType.Video => await UploadVideoAsync(file, webRootPath, ct),
            _ => throw new ArgumentException("Upload supports image, voice, and video messages only.")
        };
    }

    public async Task<ChatUploadImagesResultDto> UploadImagesAsync(
        string userId,
        IReadOnlyList<IFormFile> files,
        string webRootPath,
        CancellationToken ct = default)
    {
        _ = ParseUserId(userId);
        _ = webRootPath;

        if (files is null || files.Count == 0)
        {
            throw new ArgumentException("At least one image file is required.");
        }

        if (files.Count > 10)
        {
            throw new ArgumentException("You can upload up to 10 images at once.");
        }

        var paths = new List<string>(files.Count);
        foreach (var file in files)
        {
            if (file is null || file.Length == 0)
            {
                continue;
            }

            var fileName = $"{Guid.NewGuid():N}.jpg";
            var relativePath = await mediaStorage.SaveCompressedJpegAsync(
                file,
                ChatImagesFolder,
                fileName,
                ImageCompressionOptions.Chat,
                ct);
            paths.Add(relativePath);
        }

        if (paths.Count == 0)
        {
            throw new ArgumentException("At least one valid image file is required.");
        }

        var content = ChatImageContentHelper.SerializeImagePaths(paths);
        return new ChatUploadImagesResultDto(paths, content, ChatApiMessageType.Image);
    }

    private async Task<ChatUploadResultDto> UploadImageAsync(
        IFormFile file,
        string webRootPath,
        CancellationToken ct)
    {
        _ = webRootPath;
        var fileName = $"{Guid.NewGuid():N}.jpg";
        var relativePath = await mediaStorage.SaveCompressedJpegAsync(
            file,
            ChatImagesFolder,
            fileName,
            ImageCompressionOptions.Chat,
            ct);

        return new ChatUploadResultDto(relativePath, ChatApiMessageType.Image, null);
    }

    private async Task<ChatUploadResultDto> UploadVoiceAsync(
        IFormFile file,
        string webRootPath,
        CancellationToken ct)
    {
        _ = webRootPath;
        var header = new byte[16];
        var headerLength = 0;
        await using (var peek = file.OpenReadStream())
        {
            headerLength = await peek.ReadAsync(header.AsMemory(0, header.Length), ct);
        }

        var extension = VoiceFileHelper.ResolveVoiceExtension(
            file.FileName,
            file.ContentType,
            header.AsSpan(0, headerLength));

        var fileName = $"{Guid.NewGuid():N}{extension}";
        string relativePath;

        if (extension is ".m4a" or ".mp4")
        {
            var tempPath = Path.Combine(Path.GetTempPath(), fileName);
            try
            {
                await using (var output = File.Create(tempPath))
                await using (var input = file.OpenReadStream())
                {
                    await input.CopyToAsync(output, ct);
                }

                await Mp4FastStartHelper.TryOptimizeInPlaceAsync(tempPath, ct);
                var bytes = await File.ReadAllBytesAsync(tempPath, ct);
                relativePath = await mediaStorage.SaveBytesAsync(
                    bytes,
                    ChatVoiceFolder,
                    fileName,
                    VoiceFileHelper.GetContentType(fileName),
                    ct);
            }
            finally
            {
                try
                {
                    if (File.Exists(tempPath))
                    {
                        File.Delete(tempPath);
                    }
                }
                catch
                {
                    // Best-effort temp cleanup.
                }
            }
        }
        else
        {
            relativePath = await mediaStorage.SaveFormFileAsync(
                file,
                ChatVoiceFolder,
                fileName,
                VoiceFileHelper.GetContentType(fileName),
                ct);
        }

        return new ChatUploadResultDto(
            relativePath,
            ChatApiMessageType.Voice,
            VoiceFileHelper.GetContentType(relativePath));
    }

    private async Task<ChatUploadResultDto> UploadVideoAsync(
        IFormFile file,
        string webRootPath,
        CancellationToken ct)
    {
        _ = webRootPath;
        if (file.Length > MaxChatVideoBytes)
        {
            throw new ArgumentException("Video file must be 30 MB or smaller.");
        }

        var extension = Path.GetExtension(file.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = file.ContentType?.ToLowerInvariant() switch
            {
                "video/quicktime" => ".mov",
                "video/webm" => ".webm",
                _ => ".mp4"
            };
        }

        extension = extension.ToLowerInvariant();
        if (extension is not (".mp4" or ".mov" or ".webm" or ".m4v"))
        {
            throw new ArgumentException("Only MP4, MOV, and WebM videos are supported.");
        }

        var fileName = $"{Guid.NewGuid():N}{extension}";
        var mimeType = extension switch
        {
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "video/mp4"
        };

        var relativePath = await mediaStorage.SaveFormFileAsync(
            file,
            ChatVideosFolder,
            fileName,
            mimeType,
            ct);

        return new ChatUploadResultDto(relativePath, ChatApiMessageType.Video, mimeType);
    }

    private async Task<IReadOnlyList<ChatContactDto>> BuildContactsAsync(
        Guid inboxOwnerId,
        Guid viewerUserId,
        CancellationToken ct)
    {
        var messages = await dbContext.ChatMessages
            .AsNoTracking()
            .Where(m => m.FromUserId == inboxOwnerId || m.ToUserId == inboxOwnerId)
            .ToListAsync(ct);

        if (messages.Count == 0)
        {
            return [];
        }

        var utcNow = DateTime.UtcNow;
        var grouped = messages
            .Select(m =>
            {
                var otherId = m.FromUserId == inboxOwnerId ? m.ToUserId : m.FromUserId;
                return new { OtherUserId = otherId, Message = m };
            })
            .GroupBy(x => x.OtherUserId)
            .Select(g =>
            {
                var lastMessage = g.OrderByDescending(x => x.Message.SentAtUtc).First().Message;
                var unread = g.Count(x =>
                    x.Message.FromUserId != inboxOwnerId &&
                    x.Message.ToUserId == inboxOwnerId &&
                    !x.Message.IsSeen);

                return new
                {
                    g.Key,
                    LastMessage = lastMessage,
                    UnreadCount = unread
                };
            })
            .ToList();

        var otherIds = grouped.Select(x => x.Key).ToList();
        var users = await dbContext.Users
            .AsNoTracking()
            .Where(u => otherIds.Contains(u.Id))
            .Select(u => new
            {
                u.Id,
                u.FullName,
                u.CompanyName,
                u.ImgPath,
                u.LastSeenAtUtc
            })
            .ToListAsync(ct);

        var userMap = users.ToDictionary(x => x.Id);
        var isSupportInbox = inboxOwnerId != viewerUserId;
        var viewerIsSuperAdmin = await IsSuperAdminUserAsync(viewerUserId, ct);
        var assignments = isSupportInbox
            ? await LoadActiveAssignmentsAsync(otherIds, ct)
            : new Dictionary<Guid, ChatSupportAssignment>();

        Dictionary<Guid, string>? agentNames = null;
        if (assignments.Count > 0)
        {
            var agentIds = assignments.Values.Select(x => x.AgentUserId).Distinct().ToList();
            agentNames = await dbContext.Users.AsNoTracking()
                .Where(x => agentIds.Contains(x.Id))
                .ToDictionaryAsync(x => x.Id, x => x.FullName, ct);
        }

        return grouped
            .Select(item =>
            {
                userMap.TryGetValue(item.Key, out var user);
                var displayName = !string.IsNullOrWhiteSpace(user?.CompanyName)
                    ? user!.CompanyName!
                    : user?.FullName ?? item.Key.ToString("D");

                var lastMsg = item.LastMessage;
                var lastSeen = user?.LastSeenAtUtc;
                var isOnline = lastSeen.HasValue && utcNow - lastSeen.Value <= OnlineThreshold;

                string? assignedAgentId = null;
                string? assignedAgentName = null;
                var isAssignedToMe = false;
                var isLockedByOtherAgent = false;

                if (assignments.TryGetValue(item.Key, out var assignment))
                {
                    assignedAgentId = assignment.AgentUserId.ToString("D");
                    assignedAgentName = agentNames?.GetValueOrDefault(assignment.AgentUserId);
                    isAssignedToMe = assignment.AgentUserId == viewerUserId;
                    isLockedByOtherAgent = !viewerIsSuperAdmin && assignment.AgentUserId != viewerUserId;
                }

                var unreadCount = isLockedByOtherAgent ? 0 : item.UnreadCount;

                return new ChatContactDto(
                    ContactUserId: item.Key.ToString("D"),
                    DisplayName: displayName,
                    AvatarUrl: user?.ImgPath,
                    LastMessagePreview: BuildPreview(lastMsg),
                    LastMessageType: lastMsg.MessageType.ToString(),
                    LastMessageRelativeTime: FormatRelativeTime(utcNow, lastMsg.SentAtUtc),
                    LastMessageSentAtUtc: FormatUtc(lastMsg.SentAtUtc),
                    UnreadCount: unreadCount,
                    ContactLastSeenAtUtc: FormatUtc(lastSeen),
                    IsOnline: isOnline,
                    AssignedAgentId: assignedAgentId,
                    AssignedAgentName: assignedAgentName,
                    IsAssignedToMe: isAssignedToMe,
                    IsLockedByOtherAgent: isLockedByOtherAgent);
            })
            .OrderByDescending(c => c.LastMessageSentAtUtc)
            .ToList();
    }

    private static string BuildPreview(ChatMessage message)
    {
        if (ChatE2eContentHelper.IsEncryptedEnvelope(message.Content))
        {
            return "🔒 رسالة مشفرة";
        }

        return message.MessageType switch
        {
            ChatMessageType.Text => Truncate(message.Content, 120),
            ChatMessageType.Voice => "رسالة صوتية",
            ChatMessageType.Image => ChatImageContentHelper.TryParseImagePaths(message.Content, out var imagePaths)
                ? ChatImageContentHelper.BuildPreview(imagePaths)
                : "صورة",
            ChatMessageType.Location => "موقع",
            ChatMessageType.Video => "فيديو",
            _ => message.Content
        };
    }

    private static string Truncate(string value, int maxLength)
    {
        var trimmed = value.Trim();
        return trimmed.Length <= maxLength ? trimmed : $"{trimmed[..maxLength]}…";
    }

    private void InvalidateConversationCache(Guid userA, Guid userB)
    {
        foreach (var key in ChatCacheKeys.KeysForConversation(userA, userB))
        {
            cache.Remove(key);
        }
    }

    private async Task EnsureUserExistsAsync(Guid userId, CancellationToken ct)
    {
        var exists = await dbContext.Users.AsNoTracking().AnyAsync(x => x.Id == userId, ct);
        if (!exists)
        {
            throw new KeyNotFoundException("User not found.");
        }
    }

    private static Guid ParseUserId(string userId)
    {
        if (!Guid.TryParse(userId, out var parsed))
        {
            throw new ArgumentException("Invalid user id.");
        }

        return parsed;
    }

    private static void ValidateMessageContent(ChatApiMessageType messageType, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("Content is required.");
        }

        // Hybrid E2E envelope is opaque to the server.
        if (ChatE2eContentHelper.IsEncryptedEnvelope(content))
        {
            return;
        }

        if (messageType == ChatApiMessageType.Image
            && !ChatImageContentHelper.TryParseImagePaths(content.Trim(), out _))
        {
            throw new ArgumentException("Image content must be a chat image path or images JSON payload.");
        }

        if (messageType == ChatApiMessageType.Location)
        {
            try
            {
                using var doc = JsonDocument.Parse(content);
                if (!doc.RootElement.TryGetProperty("lat", out _)
                    || !doc.RootElement.TryGetProperty("lng", out _))
                {
                    throw new ArgumentException("Location content must include lat and lng.");
                }
            }
            catch (JsonException)
            {
                throw new ArgumentException("Location content must be valid JSON.");
            }
        }

        if (messageType == ChatApiMessageType.Video)
        {
            var trimmed = content.Trim();
            if (!trimmed.StartsWith("/chat-videos/", StringComparison.OrdinalIgnoreCase)
                || trimmed.Contains("..", StringComparison.Ordinal))
            {
                throw new ArgumentException("Video content must be a chat video path.");
            }
        }
    }

    private static ChatMessageType MapMessageType(ChatApiMessageType type) =>
        type switch
        {
            ChatApiMessageType.Text => ChatMessageType.Text,
            ChatApiMessageType.Voice => ChatMessageType.Voice,
            ChatApiMessageType.Image => ChatMessageType.Image,
            ChatApiMessageType.Location => ChatMessageType.Location,
            ChatApiMessageType.Video => ChatMessageType.Video,
            _ => ChatMessageType.Text
        };

    private static ChatApiMessageType MapApiMessageType(ChatMessageType type) =>
        type switch
        {
            ChatMessageType.Text => ChatApiMessageType.Text,
            ChatMessageType.Voice => ChatApiMessageType.Voice,
            ChatMessageType.Image => ChatApiMessageType.Image,
            ChatMessageType.Location => ChatApiMessageType.Location,
            ChatMessageType.Video => ChatApiMessageType.Video,
            _ => ChatApiMessageType.Text
        };

    private static string? GetVideoContentType(string content)
    {
        var extension = Path.GetExtension(content).ToLowerInvariant();
        return extension switch
        {
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            ".m4v" => "video/x-m4v",
            _ => "video/mp4"
        };
    }

    private static ChatMessageDto MapToDto(ChatMessage message, DateTime utcNow) =>
        new(
            MessageId: message.MessageId,
            FromUserId: message.FromUserId.ToString("D"),
            ToUserId: message.ToUserId.ToString("D"),
            MessageType: MapApiMessageType(message.MessageType),
            Content: message.Content,
            SentAtUtc: FormatUtc(message.SentAtUtc)!,
            RelativeTime: FormatRelativeTime(utcNow, message.SentAtUtc),
            IsEdited: message.IsEdited,
            IsSeen: message.IsSeen,
            SeenAtUtc: FormatUtc(message.SeenAtUtc),
            IsDelivered: message.IsDelivered,
            DeliveredAtUtc: FormatUtc(message.DeliveredAtUtc),
            MediaMimeType: message.MessageType switch
            {
                ChatMessageType.Voice => VoiceFileHelper.GetContentType(message.Content),
                ChatMessageType.Video => GetVideoContentType(message.Content),
                _ => null
            });

    private static string? FormatUtc(DateTime? value) =>
        value.HasValue ? UtcDateTimeHelper.FormatApiDateTime(value.Value) : null;

    private static string FormatRelativeTime(DateTime utcNow, DateTime sentAtUtc)
    {
        var diff = UtcDateTimeHelper.AsUtc(utcNow) - UtcDateTimeHelper.AsUtc(sentAtUtc);

        if (diff.TotalSeconds < 60)
        {
            return "الآن";
        }

        if (diff.TotalMinutes < 60)
        {
            return $"{(int)diff.TotalMinutes} دقيقة";
        }

        if (diff.TotalHours < 24)
        {
            return $"{(int)diff.TotalHours} ساعة";
        }

        if (diff.TotalDays < 7)
        {
            return $"{(int)diff.TotalDays} يوم";
        }

        var weeks = (int)(diff.TotalDays / 7);
        if (weeks < 4)
        {
            return $"{weeks} أسبوع";
        }

        var months = (int)(diff.TotalDays / 30);
        if (months < 12)
        {
            return $"{months} شهر";
        }

        var years = (int)(diff.TotalDays / 365);
        return $"{years} سنة";
    }

    public async Task<ChatPublicKeyDto?> GetPublicKeyAsync(string targetUserId, CancellationToken ct = default)
    {
        var userId = ParseUserId(targetUserId);
        var row = await dbContext.ChatUserKeys.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == userId, ct);
        if (row is null || string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
        {
            return null;
        }

        return new ChatPublicKeyDto(userId.ToString("D"), row.PublicKeySpkiBase64.Trim());
    }

    public async Task<ChatPublicKeyDto> UpsertMyPublicKeyAsync(
        string userId,
        UpsertChatPublicKeyRequest request,
        CancellationToken ct = default)
    {
        var id = ParseUserId(userId);
        var publicKey = RequireSpki(request.PublicKeySpkiBase64);
        await EnsureUserExistsAsync(id, ct);

        var row = await dbContext.ChatUserKeys.FirstOrDefaultAsync(x => x.UserId == id, ct);
        if (row is null)
        {
            row = new ChatUserKey { UserId = id };
            await dbContext.ChatUserKeys.AddAsync(row, ct);
        }

        // Server is the multi-device source of truth: keep existing *wrapped* keypair.
        // Allow one-time migration from legacy plaintext private → password-wrapped.
        var existingPrivate = row.SupportPrivateKeyPkcs8Base64;
        var hasWrappedPair = !string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64)
            && IsPasswordWrappedPrivateKey(existingPrivate);
        if (hasWrappedPair)
        {
            row.UpdatedAtUtc = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(ct);
            return new ChatPublicKeyDto(id.ToString("D"), row.PublicKeySpkiBase64);
        }

        if (string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
        {
            row.PublicKeySpkiBase64 = publicKey;
        }

        if (!string.IsNullOrWhiteSpace(request.PrivateKeyPkcs8Base64))
        {
            row.SupportPrivateKeyPkcs8Base64 = RequirePkcs8(request.PrivateKeyPkcs8Base64);
            if (string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
            {
                row.PublicKeySpkiBase64 = publicKey;
            }
        }
        else if (string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
        {
            row.PublicKeySpkiBase64 = publicKey;
        }

        row.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(ct);
        return new ChatPublicKeyDto(id.ToString("D"), row.PublicKeySpkiBase64);
    }

    public async Task<ChatMyPrivateKeyDto?> GetMyPrivateKeyAsync(
        string userId,
        CancellationToken ct = default)
    {
        var id = ParseUserId(userId);
        var row = await dbContext.ChatUserKeys.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == id, ct);
        if (row is null
            || string.IsNullOrWhiteSpace(row.SupportPrivateKeyPkcs8Base64)
            || string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
        {
            return null;
        }

        return new ChatMyPrivateKeyDto(
            id.ToString("D"),
            row.SupportPrivateKeyPkcs8Base64.Trim(),
            row.PublicKeySpkiBase64.Trim());
    }

    public async Task<ChatPublicKeyDto> UpsertSupportKeysAsync(
        string actingUserId,
        UpsertSupportChatKeysRequest request,
        CancellationToken ct = default)
    {
        var actingId = ParseUserId(actingUserId);
        if (!await IsSupportStaffAsync(actingId, ct))
        {
            throw new UnauthorizedAccessException("Only support staff can manage the support encryption keys.");
        }

        var supportId = await GetSupportAdminUserIdAsync(ct);
        var publicKey = RequireSpki(request.PublicKeySpkiBase64);
        var privateKey = RequirePkcs8(request.PrivateKeyPkcs8Base64);

        var row = await dbContext.ChatUserKeys.FirstOrDefaultAsync(x => x.UserId == supportId, ct);
        if (row is null)
        {
            row = new ChatUserKey { UserId = supportId };
            await dbContext.ChatUserKeys.AddAsync(row, ct);
        }

        // Do not rotate wrapped support keys from a second browser/device.
        // Allow migrating legacy plaintext → password-wrapped once.
        if (!string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64)
            && IsPasswordWrappedPrivateKey(row.SupportPrivateKeyPkcs8Base64))
        {
            return new ChatPublicKeyDto(supportId.ToString("D"), row.PublicKeySpkiBase64);
        }

        if (string.IsNullOrWhiteSpace(row.PublicKeySpkiBase64))
        {
            row.PublicKeySpkiBase64 = publicKey;
        }

        row.SupportPrivateKeyPkcs8Base64 = privateKey;
        row.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(ct);
        return new ChatPublicKeyDto(supportId.ToString("D"), row.PublicKeySpkiBase64);
    }

    public async Task<ChatSupportPrivateKeyDto?> GetSupportPrivateKeyAsync(
        string actingUserId,
        CancellationToken ct = default)
    {
        var actingId = ParseUserId(actingUserId);
        if (!await IsSupportStaffAsync(actingId, ct))
        {
            throw new UnauthorizedAccessException("Only support staff can load the support private key.");
        }

        var supportId = await GetSupportAdminUserIdAsync(ct);
        var row = await dbContext.ChatUserKeys.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == supportId, ct);
        if (row is null || string.IsNullOrWhiteSpace(row.SupportPrivateKeyPkcs8Base64))
        {
            return null;
        }

        return new ChatSupportPrivateKeyDto(
            supportId.ToString("D"),
            row.SupportPrivateKeyPkcs8Base64.Trim());
    }

    private static bool IsPasswordWrappedPrivateKey(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var trimmed = value.Trim();
        return trimmed.StartsWith('{')
            && (trimmed.Contains("\"wrapped\":true", StringComparison.Ordinal)
                || trimmed.Contains("\"wrapped\": true", StringComparison.Ordinal));
    }

    private static string RequireSpki(string? value)
    {
        if (string.IsNullOrWhiteSpace(value) || value.Trim().Length < 40)
        {
            throw new ArgumentException("Public key is required.");
        }

        var trimmed = value.Trim();
        if (trimmed.StartsWith('{') && trimmed.Contains("\"kty\"", StringComparison.Ordinal))
        {
            return trimmed;
        }

        try
        {
            _ = Convert.FromBase64String(trimmed);
        }
        catch (FormatException)
        {
            throw new ArgumentException("Public key must be JWK JSON or Base64 SPKI.");
        }

        return trimmed;
    }

    private static string RequirePkcs8(string? value)
    {
        if (string.IsNullOrWhiteSpace(value) || value.Trim().Length < 40)
        {
            throw new ArgumentException("Private key is required.");
        }

        var trimmed = value.Trim();
        if (trimmed.StartsWith('{') && (
                trimmed.Contains("\"kty\"", StringComparison.Ordinal)
                || trimmed.Contains("\"wrapped\":true", StringComparison.Ordinal)
                || trimmed.Contains("\"wrapped\": true", StringComparison.Ordinal)))
        {
            return trimmed;
        }

        try
        {
            _ = Convert.FromBase64String(trimmed);
        }
        catch (FormatException)
        {
            throw new ArgumentException("Private key must be JWK JSON, password-wrapped JSON, or Base64 PKCS8.");
        }

        return trimmed;
    }
}
