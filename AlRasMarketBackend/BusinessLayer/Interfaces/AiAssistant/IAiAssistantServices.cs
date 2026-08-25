using System.Collections.Generic;
using System.Linq;

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

    /// <summary>
    /// Prior chat turns (client-supplied). The service keeps at most the last 8
    /// (15 during ad-creation flows).
    /// </summary>
    public List<AiAssistantHistoryMessageDto>? History { get; set; }

    /// <summary>Current UI route, e.g. /orders/123 or /ads.</summary>
    public string? PagePath { get; set; }

    /// <summary>
    /// Snapshot of the page the user is viewing (JSON or plain text). Used so
    /// answers can reference on-screen admin/dashboard data.
    /// </summary>
    public string? PageContext { get; set; }

    /// <summary>e.g. admin_dashboard, landing, mobile.</summary>
    public string? ClientSource { get; set; }
}

public sealed class AiAssistantHistoryMessageDto
{
    public string Role { get; set; } = "user";
    public string Content { get; set; } = string.Empty;
}

public sealed class AiAssistantCorrectDictationRequest
{
    public string Text { get; set; } = string.Empty;
    public string Language { get; set; } = "en";
}

public sealed record AiAssistantCorrectDictationResult(string Text);

public sealed record AiProductListingDto(
    Guid ProductId,
    string? ProductCode,
    string? NameEn,
    string? NameAr,
    decimal Price,
    string? Currency,
    decimal? UsdPrice,
    decimal? PriceAed,
    long Quantity,
    string? UnitName,
    byte? CategoryId,
    byte? ProductTypeId,
    string? ProductTypeName,
    string? SearchListingChannel,
    bool HasRetailPricing = false,
    IReadOnlyList<string>? Images = null)
{
    /// <summary>
    /// Plain JSON map the Flutter chat parser understands (never anonymous objects).
    /// </summary>
    public Dictionary<string, object?> ToChatJson()
    {
        var displayName = string.IsNullOrWhiteSpace(NameEn) ? NameAr : NameEn;
        return new Dictionary<string, object?>
        {
            ["productId"] = ProductId.ToString("D"),
            ["ProductId"] = ProductId.ToString("D"),
            ["id"] = ProductId.ToString("D"),
            ["productCode"] = ProductCode,
            ["productName"] = displayName,
            ["nameEn"] = NameEn,
            ["nameAr"] = NameAr,
            ["price"] = Price,
            ["displayPrice"] = Price,
            ["currency"] = Currency,
            ["usdPrice"] = UsdPrice,
            ["priceUsd"] = UsdPrice,
            ["priceAed"] = PriceAed,
            ["quantity"] = Quantity,
            ["Quantity"] = Quantity,
            ["unitName"] = UnitName,
            ["UnitName"] = UnitName,
            ["categoryId"] = CategoryId,
            ["productTypeId"] = ProductTypeId,
            ["productTypeName"] = ProductTypeName,
            ["searchListingChannel"] = SearchListingChannel,
            ["hasRetailPricing"] = HasRetailPricing,
            ["images"] = Images?.ToList() ?? new List<string>(),
            ["Images"] = Images?.ToList() ?? new List<string>()
        };
    }
}

public sealed record AiAssistantAnswer(
    string Answer,
    string Language,
    bool UsedKnowledge,
    IReadOnlyList<string> Sources,
    bool OfferSupportCallback = false,
    IReadOnlyList<AiProductListingDto>? Listings = null,
    IReadOnlyList<string>? ThinkingSteps = null);

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

public sealed record AiKnowledgeReindexResult(
    bool Reindexed,
    int ChunkCount,
    string ContentHash,
    string Reason);

public interface IAiKnowledgeIndexer
{
    /// <summary>
    /// Re-embeds and upserts the knowledge base only when its content hash,
    /// embedding model, or chunk count differs from the last successful run
    /// (unless <paramref name="force"/> is set). The persisted marker is updated
    /// only after Qdrant confirms the upsert, so a mid-run crash re-tries safely.
    /// </summary>
    Task<AiKnowledgeReindexResult> ReindexAsync(
        bool force,
        CancellationToken cancellationToken = default);
}

public interface IAiAssistantAppService
{
    Task<AiAssistantAnswer> AskAsync(
        Guid? userId,
        AiAssistantAskRequest request,
        IReadOnlyList<AiAssistantHistoryMessage>? history = null,
        Func<string, CancellationToken, Task>? onThinkingStep = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Cleans speech-to-text mistakes so the AI "listens" and returns corrected text
    /// for the user to review before sending.
    /// </summary>
    Task<AiAssistantCorrectDictationResult> CorrectDictationAsync(
        AiAssistantCorrectDictationRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Transcribes raw microphone audio with OpenAI Whisper-class models
    /// (much more accurate than on-device STT for Arabic and English).
    /// </summary>
    Task<AiAssistantCorrectDictationResult> TranscribeVoiceAsync(
        Stream audioStream,
        string fileName,
        string? contentType,
        string? language,
        CancellationToken cancellationToken = default);
}
