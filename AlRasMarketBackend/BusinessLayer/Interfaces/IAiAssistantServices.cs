namespace BusinessLayer.Interfaces;

public sealed record AiKnowledgeChunk(
    string Id,
    string Source,
    string Title,
    string Language,
    IReadOnlyList<string> Audiences,
    string Content);

public sealed record AiKnowledgeHit(
    string Source,
    string Title,
    string Content,
    double Score);

public sealed class AiAssistantAskRequest
{
    public string Message { get; set; } = string.Empty;
    public string Language { get; set; } = "en";
}

public sealed record AiAssistantAnswer(
    string Answer,
    string Language,
    bool UsedKnowledge,
    IReadOnlyList<string> Sources);

public sealed record AiAssistantHistoryMessage(string Role, string Content);

public interface IAiTextEmbeddingService
{
    Task<float[]> EmbedAsync(string text, CancellationToken cancellationToken = default);
}

public interface IAiKnowledgeIndex
{
    Task EnsureCollectionAsync(CancellationToken cancellationToken = default);
    Task<long> GetCountAsync(CancellationToken cancellationToken = default);
    Task UpsertAsync(
        IReadOnlyList<(AiKnowledgeChunk Chunk, float[] Vector)> chunks,
        CancellationToken cancellationToken = default);
    /// <summary>
    /// Pass <paramref name="minScore"/> to override the configured similarity floor,
    /// for example a relaxed retry when the strict pass returns nothing.
    /// </summary>
    Task<IReadOnlyList<AiKnowledgeHit>> SearchAsync(
        float[] vector,
        string audience,
        int limit,
        CancellationToken cancellationToken = default,
        double? minScore = null);
}

public interface IAiAssistantAppService
{
    Task<AiAssistantAnswer> AskAsync(
        Guid? userId,
        AiAssistantAskRequest request,
        IReadOnlyList<AiAssistantHistoryMessage>? history = null,
        CancellationToken cancellationToken = default);
}
