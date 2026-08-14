using BusinessLayer.Options;

namespace BusinessLayer.Helpers;

public static class ImageEmbeddingIndexingGate
{
    /// <summary>
    /// Automatic CLIP indexing on catalog changes (upload, publish, moderation).
    /// Manual admin reindex is not gated by this flag.
    /// </summary>
    public static bool ShouldAutoIndexOnCatalogChange(ImageEmbeddingOptions options) =>
        options.Enabled && options.AutoIndexOnCatalogChanges;
}
