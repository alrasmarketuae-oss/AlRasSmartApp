namespace BusinessLayer.Options;

public sealed class QdrantOptions
{
    public const string SectionName = "Qdrant";

    /// <summary>Local default: http://localhost:6333</summary>
    public string Url { get; set; } = "http://localhost:6333";

    public string? ApiKey { get; set; }

    public string Collection { get; set; } = "product_images_clip_v2";

    /// <summary>Must match CLIP embedding size (multilingual ViT-B/32 = 512).</summary>
    public int VectorSize { get; set; } = 512;

    public int HnswM { get; set; } = 16;

    public int HnswEfConstruct { get; set; } = 128;

    public int SearchEf { get; set; } = 96;

    /// <summary>Minimum cosine similarity to keep a hit (CLIP scale is lower than OpenAI text embeds).</summary>
    public float MinScore { get; set; } = 0.75f;

    /// <summary>Keep hits within this distance of the best score (cluster of near matches).</summary>
    public float ScoreClusterWindow { get; set; } = 0.03f;

    public int MaxResults { get; set; } = 12;
}

public sealed class ImageEmbeddingOptions
{
    public const string SectionName = "ImageEmbedding";

    /// <summary>Base URL of the CLIP FastAPI service (e.g. http://localhost:8088).</summary>
    public string ClipServiceUrl { get; set; } = "http://localhost:8088";

    /// <summary>CLIP model output size (multilingual ViT-B/32 = 512).</summary>
    public int EmbeddingDimensions { get; set; } = 512;

    /// <summary>Weight of the image vector when fusing with catalog text (index only).</summary>
    public float ClipImageWeight { get; set; } = 1.0f;

    /// <summary>Weight of name/specs text vector when fusing (index only).</summary>
    public float ClipTextWeight { get; set; } = 0.0f;

    public bool Enabled { get; set; } = true;

    /// <summary>
    /// When false, new/edited ads do not enqueue CLIP indexing automatically.
    /// Admin manual reindex from the dashboard still runs.
    /// </summary>
    public bool AutoIndexOnCatalogChanges { get; set; } = true;

    /// <summary>Parallel background workers for CLIP + Qdrant upsert.</summary>
    public int MaxConcurrentIndexingJobs { get; set; } = 2;

    /// <summary>
    /// Keep the center fraction of the image before CLIP embed (product assumed centered).
    /// 0.75 = crop ~12.5% from each edge. Set to 1 to disable.
    /// </summary>
    public float CenterCropRatio { get; set; } = 0.75f;

    // Legacy OpenAI fields kept so old appsettings do not break binding.
    public string VisionModel { get; set; } = "gpt-4o-mini";
    public string EmbeddingModel { get; set; } = "text-embedding-3-small";
}
