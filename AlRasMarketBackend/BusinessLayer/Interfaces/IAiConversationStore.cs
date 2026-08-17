using DataLayer.Models;

namespace BusinessLayer.Interfaces;

public sealed record AiConversationListItemDto(
    Guid Id,
    Guid UserId,
    string ClientSessionId,
    string? TitlePreview,
    string LastMessageAtUtc,
    int MessageCount,
    string? CompanyName,
    string? ContactFullName,
    string? CompanyImageUrl,
    string? ProfileImageUrl,
    bool IsCompanyAccount);

public sealed record AiConversationMessageDto(
    long Id,
    string Role,
    string Content,
    string Language,
    bool? UsedKnowledge,
    IReadOnlyList<string>? Sources,
    string CreatedAtUtc,
    IReadOnlyList<AiProductListingDto>? Listings = null,
    IReadOnlyList<string>? ThinkingSteps = null);

public sealed record AiConversationMessagesPageDto(
    IReadOnlyList<AiConversationMessageDto> Messages,
    bool HasMore,
    long? NextBeforeMessageId);

public sealed record AiConversationListPageDto(
    IReadOnlyList<AiConversationListItemDto> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);

public interface IAiConversationStore
{
    Task<Guid> GetOrCreateConversationAsync(
        Guid userId,
        string clientSessionId,
        CancellationToken cancellationToken = default);

    Task AppendUserMessageAsync(
        Guid conversationId,
        string content,
        string language,
        CancellationToken cancellationToken = default);

    Task AppendAssistantMessageAsync(
        Guid conversationId,
        string content,
        string language,
        bool usedKnowledge,
        IReadOnlyList<string>? sources,
        IReadOnlyList<AiProductListingDto>? listings = null,
        IReadOnlyList<string>? thinkingSteps = null,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AiAssistantHistoryMessage>> GetRecentHistoryAsync(
        Guid conversationId,
        int maxMessages = 15,
        CancellationToken cancellationToken = default);

    Task<AiConversationMessagesPageDto> GetMessagesPageAsync(
        Guid conversationId,
        int limit = 50,
        long? beforeMessageId = null,
        CancellationToken cancellationToken = default);

    Task<AiConversationListPageDto> ListForUserAsync(
        Guid userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default);

    Task<AiConversationListPageDto> ListForAdminAsync(
        Guid? userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default);

    Task<bool> UserOwnsConversationAsync(
        Guid userId,
        Guid conversationId,
        CancellationToken cancellationToken = default);
}
