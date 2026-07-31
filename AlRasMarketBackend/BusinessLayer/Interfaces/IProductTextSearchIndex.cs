namespace BusinessLayer.Interfaces;

public sealed class ProductTextSearchDocument
{
    public Guid ProductId { get; set; }
    public string? ProductCode { get; set; }
    public string? NameEn { get; set; }
    public string? NameAr { get; set; }
    public string? CategoryNameEn { get; set; }
    public string? CategoryNameAr { get; set; }
    public string? ProductTypeName { get; set; }
    public string? DescriptionEn { get; set; }
    public string? DescriptionAr { get; set; }
    public string? RetailDescriptionEn { get; set; }
    public string? RetailDescriptionAr { get; set; }
    public string? SupplierNotesEn { get; set; }
    public string? SupplierNotesAr { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public string? ShippingDescriptionAr { get; set; }

    /// <summary>Labels offered to autocomplete (names + code).</summary>
    public List<string> SuggestLabels { get; set; } = [];

    public long CreatedAtUnix { get; set; }
    public bool IsPublic { get; set; }
}

public sealed class ProductTextSearchHit
{
    public Guid ProductId { get; set; }
    public long CreatedAtUnix { get; set; }
}

public sealed class ProductTextSearchPage
{
    public IReadOnlyList<ProductTextSearchHit> Hits { get; init; } = [];
    public int EstimatedTotal { get; init; }
}

/// <summary>
/// Fast text index for product search + autocomplete.
/// Full product payloads (images, videos, bilingual fields) still come from SQL.
/// </summary>
public interface IProductTextSearchIndex
{
    bool IsEnabled { get; }

    Task EnsureIndexAsync(CancellationToken cancellationToken = default);

    Task UpsertAsync(ProductTextSearchDocument document, CancellationToken cancellationToken = default);

    Task UpsertManyAsync(
        IReadOnlyList<ProductTextSearchDocument> documents,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(Guid productId, CancellationToken cancellationToken = default);

    Task<ProductTextSearchPage> SearchAsync(
        string query,
        int limit,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<string>> SuggestAsync(
        string query,
        int limit,
        CancellationToken cancellationToken = default);

    Task<long> GetDocumentCountAsync(CancellationToken cancellationToken = default);
}
