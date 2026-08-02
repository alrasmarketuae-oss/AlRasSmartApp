namespace BusinessLayer.Interfaces;

public sealed class ProductImageEmbedContext
{
    public string? ProductName { get; init; }
    public string? ProductNameAr { get; init; }
    public string? ProductCode { get; init; }
    public string? Description { get; init; }
    public string? RetailDescription { get; init; }
    public string? Packaging { get; init; }
    public string? PackagingDetails { get; init; }
    public string? CategoryName { get; init; }
    public string? ProductTypeName { get; init; }
    public string? SupplierNotes { get; init; }

    public string BuildCatalogText()
    {
        var parts = new List<string>();
        void Add(string? label, string? value)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                parts.Add(string.IsNullOrWhiteSpace(label)
                    ? value.Trim()
                    : $"{label}: {value.Trim()}");
            }
        }

        Add(null, ProductName);
        Add(null, ProductNameAr);
        Add("code", ProductCode);
        Add("type", ProductTypeName);
        Add("category", CategoryName);
        Add(null, Description);
        Add(null, RetailDescription);
        Add("packaging", Packaging);
        Add(null, PackagingDetails);
        Add(null, SupplierNotes);

        return string.Join(". ", parts);
    }
}

public interface IImageEmbeddingService
{
    /// <summary>
    /// CLIP embedding for a product photo.
    /// Uses image-only CLIP for both indexing and search (visual match).
    /// <paramref name="catalogContext"/> is reserved for payload/metadata callers.
    /// </summary>
    Task<float[]?> EmbedImageAsync(
        Stream imageStream,
        string? fileName = null,
        ProductImageEmbedContext? catalogContext = null,
        CancellationToken cancellationToken = default);
}
