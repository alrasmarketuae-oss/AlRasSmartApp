namespace BusinessLayer.Options;

public sealed class MeilisearchOptions
{
    public const string SectionName = "Meilisearch";

    /// <summary>When false, product search/suggest fall back to SQL / legacy name index.</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>Local / Docker default: http://localhost:7700</summary>
    public string Url { get; set; } = "http://localhost:7700";

    /// <summary>Must match MEILI_MASTER_KEY (or a search/admin key).</summary>
    public string ApiKey { get; set; } = "alras-meili-master-key-change-me";

    public string IndexUid { get; set; } = "products";

    /// <summary>Max hits fetched from Meili before SQL hydrate + paging.</summary>
    public int MaxSearchHits { get; set; } = 500;

    public int SuggestLimit { get; set; } = 8;

    /// <summary>Full reindex on API start when the index is empty or missing.</summary>
    public bool BootstrapOnStartup { get; set; } = true;
}
