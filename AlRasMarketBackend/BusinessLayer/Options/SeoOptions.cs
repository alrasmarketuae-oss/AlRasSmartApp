namespace BusinessLayer.Options;

public sealed class SeoOptions
{
    public const string SectionName = "Seo";

    /// <summary>Public web shop origin used for canonical URLs and to fetch the SPA index.html.</summary>
    public string ShopBaseUrl { get; set; } = "https://shop.alrasmarketapp.com";

    /// <summary>Public API origin; link-preview posters for video-only products are served from here.</summary>
    public string ApiPublicBaseUrl { get; set; } = "https://api.alrasmarketapp.com";

    public string SiteName { get; set; } = "Merge Spice | ميرج سبايس";

    /// <summary>Guests never see prices in the apps, so prices stay out of crawlable HTML unless enabled.</summary>
    public bool IncludePrices { get; set; }

    public int MaxSitemapProducts { get; set; } = 45000;
}
