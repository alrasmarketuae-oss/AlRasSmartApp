namespace DataLayer.Models;

/// <summary>
/// Single-row (Id = 1) marker that records the last successfully indexed AI
/// knowledge snapshot. Startup compares the current content hash / model /
/// chunk count against this row and only re-embeds when something changed.
/// </summary>
public sealed class AiKnowledgeIndexState
{
    public byte Id { get; set; } = 1;

    /// <summary>Deterministic SHA-256 (hex) of the ordered knowledge chunks + embedding config.</summary>
    public string ContentHash { get; set; } = string.Empty;

    /// <summary>Embedding model + dimensions the vectors were produced with.</summary>
    public string EmbeddingModel { get; set; } = string.Empty;

    public int ChunkCount { get; set; }

    public DateTime UpdatedAtUtc { get; set; }
}
