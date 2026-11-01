namespace BusinessLayer.Interfaces;

public interface ISeoAppService
{
    /// <summary>XML sitemap (with Google image extension) for the public web shop.</summary>
    Task<string> GetSitemapXmlAsync(CancellationToken cancellationToken = default);

    Task<string> GetRobotsTxtAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Web shop index.html with product title/meta/Open Graph/JSON-LD and crawlable content injected.
    /// Returns null when the product is not publicly openable.
    /// </summary>
    Task<string?> GetProductHtmlAsync(Guid productId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Link-preview image: the first product photo URL (to redirect to), or a JPEG frame
    /// grabbed from the product video when the listing has no photos. Null when neither exists.
    /// </summary>
    Task<ProductPoster?> GetProductPosterAsync(Guid productId, CancellationToken cancellationToken = default);

    /// <summary>Plain SPA shell marked noindex, served for products that no longer exist.</summary>
    Task<string> GetNotFoundShellAsync(CancellationToken cancellationToken = default);
}

public sealed record ProductPoster(string? RedirectUrl, byte[]? Jpeg);
