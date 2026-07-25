using DataLayer.Models;

namespace BusinessLayer.Interfaces;

public enum ChatApiMessageType : byte
{
    Text = 1,
    Voice = 2,
    Image = 3,
    Location = 4,
    Video = 5
}

public sealed record ChatContactDto(
    string ContactUserId,
    string DisplayName,
    string? AvatarUrl,
    string? LastMessagePreview,
    string? LastMessageType,
    string? LastMessageRelativeTime,
    string? LastMessageSentAtUtc,
    int UnreadCount,
    string? ContactLastSeenAtUtc,
    bool IsOnline,
    string? AssignedAgentId = null,
    string? AssignedAgentName = null,
    bool IsAssignedToMe = false,
    bool IsLockedByOtherAgent = false);

public sealed record ChatSupportAssignmentDto(
    string CustomerUserId,
    string? AssignedAgentId,
    string? AssignedAgentName,
    bool IsAssignedToMe,
    bool IsLockedByOtherAgent,
    string? AssignedAtUtc,
    bool IsNewAssignment = false);

public sealed record ChatMessageDto(
    string MessageId,
    string FromUserId,
    string ToUserId,
    ChatApiMessageType MessageType,
    string Content,
    string SentAtUtc,
    string RelativeTime,
    bool IsEdited,
    bool IsSeen,
    string? SeenAtUtc,
    bool IsDelivered,
    string? DeliveredAtUtc,
    string? MediaMimeType,
    string? SupportAgentId = null,
    string? SupportAgentName = null);

public sealed record ChatSupportSessionDto(
    string AgentUserId,
    string AgentName,
    string AssignedAtUtc,
    string? ReleasedAtUtc,
    bool IsActive);

public sealed record ChatConversationDetailsDto(
    IReadOnlyList<ChatMessageDto> Messages,
    IReadOnlyList<ChatSupportSessionDto> SupportSessions,
    string? ActiveAgentId,
    string? ActiveAgentName);

public sealed record ChatInboxDto(
    IReadOnlyList<ChatContactDto> Contacts,
    string? MyLastSeenAtUtc,
    int TotalUnreadCount,
    bool FromCache);

public sealed record ChatUnreadSummaryDto(
    int TotalUnread);

public sealed record CreateChatMessageRequest(
    string ToUserId,
    ChatApiMessageType MessageType,
    string Content);

public sealed record UpdateChatMessageRequest(
    string Content);

public sealed record MarkConversationSeenRequest(
    string OtherUserId);

public sealed record MarkConversationDeliveredRequest(
    string OtherUserId);

public sealed record ChatUploadResultDto(
    string Content,
    ChatApiMessageType MessageType,
    string? MediaMimeType);

public sealed record ChatUploadImagesResultDto(
    IReadOnlyList<string> Paths,
    string Content,
    ChatApiMessageType MessageType);

public sealed record ChatMessagesDeliveredDto(
    string FromUserId,
    string ToUserId,
    IReadOnlyList<string> MessageIds,
    string DeliveredAtUtc,
    int MarkedCount);

public sealed record ChatPresenceDto(
    string UserId,
    string? LastSeenAtUtc,
    bool IsOnline);

public sealed record ChatPublicKeyDto(
    string UserId,
    string PublicKeySpkiBase64);

public sealed record UpsertChatPublicKeyRequest(
    string PublicKeySpkiBase64,
    string? PrivateKeyPkcs8Base64 = null);

public sealed record UpsertSupportChatKeysRequest(
    string PublicKeySpkiBase64,
    string PrivateKeyPkcs8Base64);

public sealed record ChatSupportPrivateKeyDto(
    string UserId,
    string PrivateKeyPkcs8Base64);

/// <summary>Authenticated user's own private key backup (multi-device sync).</summary>
public sealed record ChatMyPrivateKeyDto(
    string UserId,
    string PrivateKeyPkcs8Base64,
    string PublicKeySpkiBase64);

public interface IChatAppService
{
    Task<ChatInboxDto> GetMyInboxAsync(string userId, CancellationToken ct = default);

    Task<ChatUnreadSummaryDto> GetUnreadCountAsync(string userId, CancellationToken ct = default);

    Task<IReadOnlyList<ChatContactDto>> SearchConversationsAsync(
        string userId,
        string query,
        CancellationToken ct = default);

    Task<IReadOnlyList<ChatMessageDto>> GetConversationAsync(
        string userId,
        string otherUserId,
        CancellationToken ct = default);

    Task<ChatConversationDetailsDto> GetConversationDetailsAsync(
        string userId,
        string otherUserId,
        CancellationToken ct = default);

    Task<ChatMessageDto> CreateMessageAsync(
        string fromUserId,
        CreateChatMessageRequest request,
        CancellationToken ct = default);

    Task<ChatMessageDto> UpdateMessageAsync(
        string userId,
        string messageId,
        UpdateChatMessageRequest request,
        CancellationToken ct = default);

    Task<int> MarkConversationSeenAsync(
        string viewerUserId,
        string otherUserId,
        CancellationToken ct = default);

    Task<ChatMessagesDeliveredDto> MarkConversationDeliveredAsync(
        string recipientUserId,
        string otherUserId,
        CancellationToken ct = default);

    Task<(ChatMessageDto Message, ChatMessagesDeliveredDto? DeliveryEvent)> TryMarkMessageDeliveredAsync(
        string messageId,
        CancellationToken ct = default);

    Task<ChatPresenceDto> UpdatePresenceAsync(string userId, CancellationToken ct = default);

    Task<ChatSupportAssignmentDto> ClaimSupportConversationAsync(
        string agentUserId,
        string customerUserId,
        CancellationToken ct = default);

    Task<ChatSupportAssignmentDto?> ReleaseSupportConversationAsync(
        string agentUserId,
        string customerUserId,
        CancellationToken ct = default);

    Task<ChatSupportAssignmentDto?> GetSupportAssignmentAsync(
        string viewerUserId,
        string customerUserId,
        CancellationToken ct = default);

    /// <summary>
    /// Returns the shared support inbox user id when the viewer is support staff
    /// but not the inbox owner; otherwise null.
    /// </summary>
    Task<string?> GetSupportInboxOwnerIdForViewerAsync(
        string viewerUserId,
        CancellationToken ct = default);

    Task<ChatUploadResultDto> UploadMediaAsync(
        string userId,
        ChatApiMessageType messageType,
        Microsoft.AspNetCore.Http.IFormFile file,
        string webRootPath,
        CancellationToken ct = default);

    Task<ChatUploadImagesResultDto> UploadImagesAsync(
        string userId,
        IReadOnlyList<Microsoft.AspNetCore.Http.IFormFile> files,
        string webRootPath,
        CancellationToken ct = default);

    Task<ChatPublicKeyDto?> GetPublicKeyAsync(string targetUserId, CancellationToken ct = default);

    Task<ChatPublicKeyDto> UpsertMyPublicKeyAsync(
        string userId,
        UpsertChatPublicKeyRequest request,
        CancellationToken ct = default);

    Task<ChatMyPrivateKeyDto?> GetMyPrivateKeyAsync(
        string userId,
        CancellationToken ct = default);

    Task<ChatPublicKeyDto> UpsertSupportKeysAsync(
        string actingUserId,
        UpsertSupportChatKeysRequest request,
        CancellationToken ct = default);

    Task<ChatSupportPrivateKeyDto?> GetSupportPrivateKeyAsync(
        string actingUserId,
        CancellationToken ct = default);
}
