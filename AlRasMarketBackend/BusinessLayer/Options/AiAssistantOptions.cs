namespace BusinessLayer.Options;

public sealed class AiAssistantOptions
{
    public const string SectionName = "AiAssistant";

    public bool Enabled { get; set; } = true;
    public string QdrantUrl { get; set; } = "http://localhost:6333";
    public string? QdrantApiKey { get; set; }
    public string Collection { get; set; } = "alras_knowledge_v3";
    public string EmbeddingModel { get; set; } = "text-embedding-3-small";
    public int EmbeddingDimensions { get; set; } = 1536;
    public string ChatModel { get; set; } = "gpt-4o-mini";
    public int RetrievalLimit { get; set; } = 10;
    /// <summary>
    /// Cosine floor for retrieval. Kept low because short questions score poorly
    /// against long chunks; grounding is enforced by the prompt, not by this filter.
    /// </summary>
    public double MinScore { get; set; } = 0.2;
}
