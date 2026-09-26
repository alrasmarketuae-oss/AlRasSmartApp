namespace BusinessLayer.Interfaces;

/// <summary>
/// Private storage for the Nasser portfolio (chats, uploaded/generated images, call requests).
/// Lives in its own SQLite file and folder — never in the marketplace database or CDN.
/// </summary>
public interface INasserPortfolioStore
{
    Task RecordExchangeAsync(NasserExchangeRecord record, CancellationToken cancellationToken = default);

    Task RecordLeadAsync(NasserLeadRecord record, CancellationToken cancellationToken = default);

    Task<NasserPage<NasserConversationSummary>> ListConversationsAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default);

    Task<NasserConversationDetail?> GetConversationAsync(string id, CancellationToken cancellationToken = default);

    Task<bool> DeleteConversationAsync(string id, CancellationToken cancellationToken = default);

    Task<NasserPage<NasserLeadRecord>> ListLeadsAsync(int page, int pageSize, CancellationToken cancellationToken = default);

    Task<NasserStats> GetStatsAsync(CancellationToken cancellationToken = default);

    /// <summary>Returns the absolute path of a stored image, or null if the name is invalid or missing.</summary>
    string? ResolveImagePath(string fileName);
}

public sealed record NasserVisitor(string? Ip, string? Country, string? UserAgent);

public sealed class NasserExchangeRecord
{
    public string ConversationId { get; init; } = string.Empty;
    public string Locale { get; init; } = "en";
    public NasserVisitor Visitor { get; init; } = new(null, null, null);
    public string UserText { get; init; } = string.Empty;
    public byte[]? UserImageJpeg { get; init; }
    public string AssistantText { get; init; } = string.Empty;
    public byte[]? AssistantImagePng { get; init; }
    public string? Phone { get; init; }
}

public sealed class NasserLeadRecord
{
    public long Id { get; init; }
    public DateTimeOffset CreatedAt { get; init; }
    public string Phone { get; init; } = string.Empty;
    public string? Name { get; init; }
    public string? Source { get; init; }
    public string? Locale { get; init; }
    public string? Ip { get; init; }
    public string? Country { get; init; }
    public string? UserAgent { get; init; }
    public string? ConversationId { get; init; }
}

public sealed record NasserPage<T>(IReadOnlyList<T> Items, int Total, int Page, int PageSize);

public sealed record NasserConversationSummary(
    string Id,
    DateTimeOffset CreatedAt,
    DateTimeOffset LastAt,
    string? Ip,
    string? Country,
    string? UserAgent,
    string? Locale,
    string? Phone,
    int MessageCount,
    int ImageCount,
    string? Preview);

public sealed record NasserStoredMessage(
    long Id,
    string Role,
    string Text,
    string? ImageFile,
    DateTimeOffset CreatedAt);

public sealed record NasserConversationDetail(
    NasserConversationSummary Conversation,
    IReadOnlyList<NasserStoredMessage> Messages);

public sealed record NasserStats(int Conversations, int Messages, int Images, int Leads, int ConversationsToday);
