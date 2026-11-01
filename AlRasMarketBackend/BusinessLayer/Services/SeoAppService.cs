using System.Diagnostics;
using System.Globalization;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Xml;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

/// <summary>
/// Crawlable surface for the React web shop: sitemap (with image entries), robots.txt and
/// product pages rendered as the SPA index.html plus injected head tags and static content.
/// </summary>
public sealed partial class SeoAppService(
    IRasAlSouqDbContext db,
    IProductsAppService productsAppService,
    IMediaUrlResolver mediaUrlResolver,
    IHttpClientFactory httpClientFactory,
    IMemoryCache memoryCache,
    IOptions<SeoOptions> options,
    ILogger<SeoAppService> logger) : ISeoAppService
{
    private const string SitemapCacheKey = "seo:sitemap:v1";
    private const string IndexHtmlCacheKey = "seo:index-html:v1";
    private const string ProductHtmlCachePrefix = "seo:product-html:v2:";
    private const string PosterCachePrefix = "seo:poster:v1:";
    private static readonly SemaphoreSlim FrameGate = new(2, 2);
    private const int MaxImagesPerProduct = 5;
    private static readonly JsonSerializerOptions WebJson = new(JsonSerializerDefaults.Web);
    private static readonly string[] VideoExtensions = [".mp4", ".mov", ".webm", ".m4v", ".avi", ".mkv"];

    private SeoOptions Settings => options.Value;
    private string ShopBase => Settings.ShopBaseUrl.TrimEnd('/');

    public async Task<string> GetSitemapXmlAsync(CancellationToken cancellationToken = default)
    {
        if (memoryCache.TryGetValue(SitemapCacheKey, out string? cached) && cached is not null)
        {
            return cached;
        }

        var publicProducts = ProductQueryHelpers.ApplyPublicProductFilter(db.Products.AsNoTracking());

        var products = await publicProducts
            .OrderByDescending(p => p.CreatedAt)
            .Take(Math.Clamp(Settings.MaxSitemapProducts, 1, 49000))
            .Select(p => new { p.ProductId, p.NameEn, p.CreatedAt, p.UpdatedAt })
            .ToListAsync(cancellationToken);

        var englishNames = await db.ContentTranslations.AsNoTracking()
            .Where(t => t.Scope == ContentTranslationScopes.Product
                && t.Field == ContentTranslationFields.Name
                && t.ProductId != null
                && t.TextEn != null && t.TextEn != "")
            .Join(publicProducts, t => t.ProductId, p => (Guid?)p.ProductId, (t, p) => new { p.ProductId, t.TextEn })
            .ToListAsync(cancellationToken);
        var nameById = englishNames
            .GroupBy(x => x.ProductId)
            .ToDictionary(g => g.Key, g => g.First().TextEn);

        var images = await db.ProductImages.AsNoTracking()
            .Join(publicProducts, i => i.ProductId, p => p.ProductId, (i, p) => new { i.ProductId, i.Id, i.ImagePath })
            .Where(x => x.ImagePath != "")
            .ToListAsync(cancellationToken);
        var imagesById = images
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.OrderBy(x => x.Id)
                    .Select(x => x.ImagePath)
                    .Where(path => !IsVideoPath(path))
                    .Take(MaxImagesPerProduct)
                    .ToList());

        var categories = await db.Categories.AsNoTracking()
            .Where(c => !c.IsHide)
            .OrderBy(c => c.CategoryId)
            .Select(c => c.CategoryId)
            .ToListAsync(cancellationToken);

        var builder = new StringBuilder(capacity: 256 * (products.Count + 8));
        var settings = new XmlWriterSettings { Encoding = new UTF8Encoding(false), Indent = false, Async = false };
        using (var sw = new Utf8StringWriter(builder))
        using (var xml = XmlWriter.Create(sw, settings))
        {
            const string sitemapNs = "http://www.sitemaps.org/schemas/sitemap/0.9";
            const string imageNs = "http://www.google.com/schemas/sitemap-image/1.1";
            xml.WriteStartDocument();
            xml.WriteStartElement("urlset", sitemapNs);
            xml.WriteAttributeString("xmlns", "image", null, imageNs);

            WriteUrl(xml, sitemapNs, $"{ShopBase}/", null, "daily", "1.0");
            WriteUrl(xml, sitemapNs, $"{ShopBase}/categories", null, "weekly", "0.6");
            foreach (var categoryId in categories)
            {
                WriteUrl(xml, sitemapNs, $"{ShopBase}/category/{categoryId}", null, "daily", "0.7");
            }

            foreach (var p in products)
            {
                var name = FirstNonEmpty(nameById.GetValueOrDefault(p.ProductId), p.NameEn) ?? string.Empty;
                xml.WriteStartElement("url", sitemapNs);
                xml.WriteElementString("loc", sitemapNs, ProductUrl(p.ProductId, name));
                xml.WriteElementString("lastmod", sitemapNs, (p.UpdatedAt ?? p.CreatedAt).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture));
                xml.WriteElementString("changefreq", sitemapNs, "weekly");
                xml.WriteElementString("priority", sitemapNs, "0.8");
                foreach (var path in imagesById.GetValueOrDefault(p.ProductId) ?? [])
                {
                    var url = mediaUrlResolver.ToPublicUrl(path);
                    if (string.IsNullOrWhiteSpace(url))
                    {
                        continue;
                    }

                    xml.WriteStartElement("image", "image", imageNs);
                    xml.WriteElementString("image", "loc", imageNs, url);
                    xml.WriteEndElement();
                }

                xml.WriteEndElement();
            }

            xml.WriteEndElement();
            xml.WriteEndDocument();
        }

        var result = builder.ToString();
        memoryCache.Set(SitemapCacheKey, result, TimeSpan.FromMinutes(30));
        return result;
    }

    public Task<string> GetRobotsTxtAsync(CancellationToken cancellationToken = default)
    {
        var robots = new StringBuilder()
            .AppendLine("User-agent: *")
            .AppendLine("Allow: /")
            .AppendLine("Disallow: /cart")
            .AppendLine("Disallow: /orders")
            .AppendLine("Disallow: /chat")
            .AppendLine("Disallow: /profile")
            .AppendLine("Disallow: /login")
            .AppendLine("Disallow: /register")
            .AppendLine()
            .AppendLine($"Sitemap: {ShopBase}/sitemap.xml")
            .ToString();
        return Task.FromResult(robots);
    }

    public async Task<string?> GetProductHtmlAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"{ProductHtmlCachePrefix}{productId:D}";
        if (memoryCache.TryGetValue(cacheKey, out string? cached) && cached is not null)
        {
            return cached;
        }

        if (await LoadProductAsync(productId, cancellationToken) is not { } item)
        {
            return null;
        }

        var shell = await GetIndexHtmlAsync(cancellationToken);
        var html = RenderProductPage(shell, productId, item);
        memoryCache.Set(cacheKey, html, TimeSpan.FromMinutes(5));
        return html;
    }

    public async Task<ProductPoster?> GetProductPosterAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"{PosterCachePrefix}{productId:D}";
        if (memoryCache.TryGetValue(cacheKey, out ProductPoster? cached))
        {
            return cached;
        }

        if (await LoadProductAsync(productId, cancellationToken) is not { } item)
        {
            return null;
        }

        ProductPoster? poster = null;
        var images = ImageUrls(item);
        if (images.Count > 0)
        {
            poster = new ProductPoster(images[0], null);
        }
        else if (VideoUrls(item).FirstOrDefault() is { } videoUrl)
        {
            var jpeg = await GrabVideoFrameAsync(videoUrl, cancellationToken);
            poster = jpeg is null ? null : new ProductPoster(null, jpeg);
        }

        memoryCache.Set(cacheKey, poster, poster is null ? TimeSpan.FromMinutes(10) : TimeSpan.FromHours(12));
        return poster;
    }

    private async Task<JsonElement?> LoadProductAsync(Guid productId, CancellationToken cancellationToken)
    {
        try
        {
            var raw = await productsAppService.GetByIdAsync(productId.ToString("D"), false, cancellationToken);
            var root = raw is JsonElement je ? je : JsonSerializer.SerializeToElement(raw, WebJson);
            return TryGetProperty(root, "item", out var item) && item.ValueKind == JsonValueKind.Object ? item : null;
        }
        catch (KeyNotFoundException)
        {
            return null;
        }
        catch (ArgumentException)
        {
            return null;
        }
    }

    /// <summary>One JPEG frame (max 1200px wide) read straight from the CDN video with ffmpeg.</summary>
    private async Task<byte[]?> GrabVideoFrameAsync(string videoUrl, CancellationToken cancellationToken)
    {
        if (!await FrameGate.WaitAsync(TimeSpan.FromSeconds(30), cancellationToken))
        {
            return null;
        }

        try
        {
            foreach (var seek in new[] { "1", "0" })
            {
                var frame = await RunFfmpegFrameAsync(videoUrl, seek, cancellationToken);
                if (frame is { Length: > 0 })
                {
                    return frame;
                }
            }

            return null;
        }
        finally
        {
            FrameGate.Release();
        }
    }

    private async Task<byte[]?> RunFfmpegFrameAsync(string videoUrl, string seekSeconds, CancellationToken cancellationToken)
    {
        var start = new ProcessStartInfo
        {
            FileName = "ffmpeg",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };
        foreach (var arg in new[]
                 {
                     "-hide_banner", "-loglevel", "error", "-ss", seekSeconds, "-i", videoUrl,
                     "-frames:v", "1", "-vf", "scale='min(1200,iw)':-2", "-q:v", "3", "-f", "image2", "-c:v", "mjpeg", "pipe:1",
                 })
        {
            start.ArgumentList.Add(arg);
        }

        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(25));
        Process? process = null;
        try
        {
            process = Process.Start(start);
            if (process is null)
            {
                return null;
            }

            using var output = new MemoryStream();
            var copyTask = process.StandardOutput.BaseStream.CopyToAsync(output, timeout.Token);
            var errorTask = process.StandardError.ReadToEndAsync(timeout.Token);
            await Task.WhenAll(copyTask, errorTask, process.WaitForExitAsync(timeout.Token));
            if (process.ExitCode != 0)
            {
                logger.LogWarning("SEO poster: ffmpeg exited {Code} for {Url}: {Error}", process.ExitCode, videoUrl, errorTask.Result);
                return null;
            }

            return output.ToArray();
        }
        catch (Exception ex) when (ex is OperationCanceledException or System.ComponentModel.Win32Exception or InvalidOperationException)
        {
            logger.LogWarning(ex, "SEO poster: could not grab a frame from {Url}", videoUrl);
            try
            {
                if (process is { HasExited: false })
                {
                    process.Kill(entireProcessTree: true);
                }
            }
            catch (InvalidOperationException)
            {
            }

            return null;
        }
        finally
        {
            process?.Dispose();
        }
    }

    public async Task<string> GetNotFoundShellAsync(CancellationToken cancellationToken = default)
    {
        var shell = await GetIndexHtmlAsync(cancellationToken);
        return shell.Replace("</head>", "<meta name=\"robots\" content=\"noindex\" /></head>", StringComparison.OrdinalIgnoreCase);
    }

    private string RenderProductPage(string shell, Guid productId, JsonElement item)
    {
        var nameEn = FirstNonEmpty(Str(item, "nameEn"), Str(item, "productName")) ?? "Product";
        var nameAr = Str(item, "nameAr");
        var descriptionEn = Clean(FirstNonEmpty(Str(item, "descriptionEn"), Str(item, "description")));
        var descriptionAr = Clean(Str(item, "descriptionAr"));
        var categoryEn = FirstNonEmpty(Str(item, "categoryNameEn"), Str(item, "categoryName"));
        var categoryAr = Str(item, "categoryNameAr");
        var categoryId = Str(item, "categoryId");
        var productCode = Str(item, "productCode");
        var quantity = Str(item, "quantity");
        var unit = FirstNonEmpty(Str(item, "unitNameEn"), Str(item, "unitName"));
        var typeName = FirstNonEmpty(Str(item, "productTypeNameEn"), Str(item, "productTypeName"));
        var origin = FirstNonEmpty(Str(item, "originCountryNameEn"), Str(item, "originCountryName"));
        var images = ImageUrls(item);
        var videos = VideoUrls(item);
        var url = ProductUrl(productId, nameEn);
        var previewImage = images.Count > 0
            ? images[0]
            : videos.Count > 0
                ? $"{Settings.ApiPublicBaseUrl.TrimEnd('/')}/api/seo/product/{productId:D}/poster.jpg"
                : $"{ShopBase}/assets/logo/logo.png";

        var title = string.IsNullOrWhiteSpace(nameAr) || nameAr == nameEn
            ? $"{nameEn} | {Settings.SiteName}"
            : $"{nameEn} | {nameAr} | {Settings.SiteName}";
        var quantityText = string.Join(' ', new[] { quantity, unit }.Where(v => !string.IsNullOrWhiteSpace(v)));
        var facts = new[]
            {
                categoryEn is null ? null : $"Category: {categoryEn}",
                typeName is null ? null : $"Type: {typeName}",
                quantityText.Length == 0 ? null : $"Quantity: {quantityText}",
                origin is null ? null : $"Origin: {origin}",
                productCode is null ? null : $"Code: {productCode}",
            }
            .Where(f => f is not null);
        var summary = string.Join(" · ", facts);
        var blurb = FirstNonEmpty(descriptionEn, descriptionAr);
        var metaDescription = Truncate(
            FirstNonEmpty(blurb, summary.Length > 0 ? summary : null)
                ?? $"{nameEn}{(categoryEn is null ? "" : $" — {categoryEn}")} on Al Ras Smart, the B2B marketplace for suppliers and buyers.",
            160);
        var previewDescription = Truncate(
            string.Join(" — ", new[] { summary, blurb }.Where(v => !string.IsNullOrWhiteSpace(v))) is { Length: > 0 } rich
                ? rich
                : metaDescription,
            300);

        var jsonLd = new Dictionary<string, object?>
        {
            ["@context"] = "https://schema.org",
            ["@type"] = "Product",
            ["name"] = nameEn,
            ["alternateName"] = nameAr,
            ["description"] = FirstNonEmpty(descriptionEn, descriptionAr),
            ["image"] = images.Count > 0 ? images : new List<string> { previewImage },
            ["sku"] = productCode ?? productId.ToString("D"),
            ["productID"] = productId.ToString("D"),
            ["category"] = categoryEn,
            ["url"] = url,
            ["brand"] = new Dictionary<string, object?> { ["@type"] = "Brand", ["name"] = "Al Ras Smart" },
        };
        if (Settings.IncludePrices && decimal.TryParse(Str(item, "price"), NumberStyles.Any, CultureInfo.InvariantCulture, out var price) && price > 0)
        {
            jsonLd["offers"] = new Dictionary<string, object?>
            {
                ["@type"] = "Offer",
                ["url"] = url,
                ["price"] = price.ToString("0.##", CultureInfo.InvariantCulture),
                ["priceCurrency"] = (Str(item, "currency") ?? "AED").ToUpperInvariant(),
                ["availability"] = "https://schema.org/InStock",
            };
        }

        var breadcrumbs = new List<object>
        {
            new Dictionary<string, object?> { ["@type"] = "ListItem", ["position"] = 1, ["name"] = "Al Ras Smart", ["item"] = $"{ShopBase}/" },
        };
        if (categoryEn is not null && int.TryParse(categoryId, out var catId) && catId > 0)
        {
            breadcrumbs.Add(new Dictionary<string, object?> { ["@type"] = "ListItem", ["position"] = 2, ["name"] = categoryEn, ["item"] = $"{ShopBase}/category/{catId}" });
        }

        breadcrumbs.Add(new Dictionary<string, object?> { ["@type"] = "ListItem", ["position"] = breadcrumbs.Count + 1, ["name"] = nameEn, ["item"] = url });

        var ldJson = JsonSerializer.Serialize(
            new object[]
            {
                jsonLd.Where(kv => kv.Value is not null).ToDictionary(kv => kv.Key, kv => kv.Value),
                new Dictionary<string, object?> { ["@context"] = "https://schema.org", ["@type"] = "BreadcrumbList", ["itemListElement"] = breadcrumbs },
            });

        var e = (string? value) => WebUtility.HtmlEncode(value ?? string.Empty);
        var head = new StringBuilder()
            .Append($"<title>{e(title)}</title>")
            .Append($"<meta name=\"description\" content=\"{e(metaDescription)}\" />")
            .Append($"<link rel=\"canonical\" href=\"{e(url)}\" />")
            .Append("<meta name=\"robots\" content=\"index,follow,max-image-preview:large\" />")
            .Append("<meta property=\"og:type\" content=\"product\" />")
            .Append($"<meta property=\"og:site_name\" content=\"{e(Settings.SiteName)}\" />")
            .Append($"<meta property=\"og:title\" content=\"{e(title)}\" />")
            .Append($"<meta property=\"og:description\" content=\"{e(previewDescription)}\" />")
            .Append($"<meta property=\"og:url\" content=\"{e(url)}\" />")
            .Append("<meta property=\"og:locale\" content=\"en_US\" />")
            .Append("<meta property=\"og:locale:alternate\" content=\"ar_AE\" />")
            .Append($"<meta property=\"og:image\" content=\"{e(previewImage)}\" />")
            .Append($"<meta property=\"og:image:secure_url\" content=\"{e(previewImage)}\" />")
            .Append($"<meta property=\"og:image:alt\" content=\"{e(nameEn)}\" />")
            .Append("<meta name=\"twitter:card\" content=\"summary_large_image\" />")
            .Append($"<meta name=\"twitter:title\" content=\"{e(title)}\" />")
            .Append($"<meta name=\"twitter:description\" content=\"{e(previewDescription)}\" />")
            .Append($"<meta name=\"twitter:image\" content=\"{e(previewImage)}\" />");
        if (videos.Count > 0)
        {
            head.Append($"<meta property=\"og:video\" content=\"{e(videos[0])}\" />")
                .Append($"<meta property=\"og:video:secure_url\" content=\"{e(videos[0])}\" />")
                .Append("<meta property=\"og:video:type\" content=\"video/mp4\" />");
        }

        if (productCode is not null)
        {
            head.Append($"<meta property=\"product:retailer_item_id\" content=\"{e(productCode)}\" />");
        }

        head.Append($"<script type=\"application/ld+json\">{ldJson}</script>");

        var body = new StringBuilder()
            .Append("<main style=\"max-width:760px;margin:0 auto;padding:16px;font-family:Inter,Cairo,system-ui,sans-serif;color:#16233a\">")
            .Append($"<nav aria-label=\"Breadcrumb\" style=\"font-size:13px\"><a href=\"{e(ShopBase)}/\">Al Ras Smart</a>");
        if (categoryEn is not null && int.TryParse(categoryId, out var catId2) && catId2 > 0)
        {
            body.Append($" › <a href=\"{e(ShopBase)}/category/{catId2}\">{e(categoryEn)}</a>");
        }

        body.Append("</nav>")
            .Append($"<h1 style=\"font-size:24px\">{e(nameEn)}</h1>");
        if (!string.IsNullOrWhiteSpace(nameAr) && nameAr != nameEn)
        {
            body.Append($"<h2 lang=\"ar\" dir=\"rtl\" style=\"font-size:20px\">{e(nameAr)}</h2>");
        }

        for (var i = 0; i < images.Count; i++)
        {
            var alt = i == 0 ? nameEn : $"{nameEn} — {i + 1}";
            body.Append($"<img src=\"{e(images[i])}\" alt=\"{e(alt)}\" style=\"max-width:100%;height:auto;border-radius:12px\" loading=\"{(i == 0 ? "eager" : "lazy")}\" />");
        }

        if (images.Count == 0 && videos.Count > 0)
        {
            body.Append($"<video src=\"{e(videos[0])}\" poster=\"{e(previewImage)}\" controls muted playsinline preload=\"metadata\" style=\"max-width:100%;border-radius:12px\"></video>");
        }

        if (descriptionEn is not null)
        {
            body.Append($"<p style=\"white-space:pre-line\">{e(descriptionEn)}</p>");
        }

        if (descriptionAr is not null && descriptionAr != descriptionEn)
        {
            body.Append($"<p lang=\"ar\" dir=\"rtl\" style=\"white-space:pre-line\">{e(descriptionAr)}</p>");
        }

        body.Append("<ul>");
        AppendFact(body, "Category", JoinBilingual(categoryEn, categoryAr));
        AppendFact(body, "Type", typeName);
        AppendFact(body, "Quantity", quantityText);
        AppendFact(body, "Origin", origin);
        AppendFact(body, "Product code", productCode);
        body.Append("</ul>")
            .Append($"<p><a href=\"{e(url)}\">View {e(nameEn)} on Al Ras Smart</a></p>")
            .Append("</main>");

        var html = HtmlTagRegex().Replace(shell, "<html lang=\"en\" dir=\"ltr\">", 1);
        html = TitleRegex().Replace(html, string.Empty);
        html = MetaDescriptionRegex().Replace(html, string.Empty);
        html = OpenGraphRegex().Replace(html, string.Empty);
        html = html.Replace("</head>", head + "</head>", StringComparison.OrdinalIgnoreCase);
        var rootContent = $"<div id=\"root\">{body}</div>";
        html = RootRegex().Replace(html, _ => rootContent, 1);
        return html;
    }

    private async Task<string> GetIndexHtmlAsync(CancellationToken cancellationToken)
    {
        if (memoryCache.TryGetValue(IndexHtmlCacheKey, out string? cached) && cached is not null)
        {
            return cached;
        }

        try
        {
            var client = httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(8);
            var html = await client.GetStringAsync($"{ShopBase}/index.html", cancellationToken);
            if (html.Contains("id=\"root\"", StringComparison.OrdinalIgnoreCase))
            {
                memoryCache.Set(IndexHtmlCacheKey, html, TimeSpan.FromMinutes(10));
                return html;
            }
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            logger.LogWarning(ex, "SEO: could not fetch web shop index.html from {ShopBase}", ShopBase);
        }

        const string fallback = "<!doctype html><html lang=\"en\"><head><meta charset=\"UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" /></head><body><div id=\"root\"></div></body></html>";
        memoryCache.Set(IndexHtmlCacheKey, fallback, TimeSpan.FromMinutes(1));
        return fallback;
    }

    private List<string> ImageUrls(JsonElement item)
    {
        var urls = new List<string>();
        if (!TryGetProperty(item, "images", out var images) || images.ValueKind != JsonValueKind.Array)
        {
            return urls;
        }

        foreach (var entry in images.EnumerateArray())
        {
            var path = entry.ValueKind == JsonValueKind.String
                ? entry.GetString()
                : entry.ValueKind == JsonValueKind.Object
                    ? FirstNonEmpty(Str(entry, "path"), Str(entry, "imagePath"))
                    : null;
            if (string.IsNullOrWhiteSpace(path) || IsVideoPath(path))
            {
                continue;
            }

            var url = mediaUrlResolver.ToPublicUrl(path);
            if (!string.IsNullOrWhiteSpace(url) && !urls.Contains(url))
            {
                urls.Add(url);
            }

            if (urls.Count >= MaxImagesPerProduct)
            {
                break;
            }
        }

        return urls;
    }

    /// <summary>Same order as the web/app media list: <c>videoPath</c>, <c>videos[]</c>, <c>videoPaths[]</c>, then video files in <c>images</c>.</summary>
    private List<string> VideoUrls(JsonElement item)
    {
        var urls = new List<string>();
        void Add(string? path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return;
            }

            var url = mediaUrlResolver.ToPublicUrl(path);
            if (!string.IsNullOrWhiteSpace(url) && !urls.Contains(url))
            {
                urls.Add(url);
            }
        }

        Add(Str(item, "videoPath"));
        if (TryGetProperty(item, "videos", out var videos) && videos.ValueKind == JsonValueKind.Array)
        {
            foreach (var v in videos.EnumerateArray())
            {
                Add(v.ValueKind == JsonValueKind.String ? v.GetString() : v.ValueKind == JsonValueKind.Object ? FirstNonEmpty(Str(v, "path"), Str(v, "videoPath"), Str(v, "url")) : null);
            }
        }

        if (TryGetProperty(item, "videoPaths", out var paths) && paths.ValueKind == JsonValueKind.Array)
        {
            foreach (var v in paths.EnumerateArray())
            {
                Add(v.ValueKind == JsonValueKind.String ? v.GetString() : null);
            }
        }

        if (TryGetProperty(item, "images", out var images) && images.ValueKind == JsonValueKind.Array)
        {
            foreach (var entry in images.EnumerateArray())
            {
                var path = entry.ValueKind == JsonValueKind.String ? entry.GetString() : entry.ValueKind == JsonValueKind.Object ? FirstNonEmpty(Str(entry, "path"), Str(entry, "imagePath")) : null;
                if (path is not null && IsVideoPath(path))
                {
                    Add(path);
                }
            }
        }

        return urls;
    }

    private string ProductUrl(Guid productId, string name)
    {
        var slug = Slugify(name);
        return slug.Length == 0 ? $"{ShopBase}/product/{productId:D}" : $"{ShopBase}/product/{productId:D}/{Uri.EscapeDataString(slug)}";
    }

    /// <summary>Must stay identical to <c>slugify</c> in WebApp/src/products/productLinks.ts.</summary>
    public static string Slugify(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var normalized = value.Normalize(NormalizationForm.FormKD);
        var sb = new StringBuilder(normalized.Length);
        foreach (var ch in normalized)
        {
            if ((ch >= '\u0300' && ch <= '\u036f') || (ch >= '\u064B' && ch <= '\u065F'))
            {
                continue;
            }

            sb.Append(ch);
        }

        var lower = sb.ToString().ToLowerInvariant();
        var dashed = SlugSeparatorRegex().Replace(lower, "-").Trim('-');
        return dashed.Length > 80 ? dashed[..80] : dashed;
    }

    private static void WriteUrl(XmlWriter xml, string ns, string loc, DateTime? lastmod, string changefreq, string priority)
    {
        xml.WriteStartElement("url", ns);
        xml.WriteElementString("loc", ns, loc);
        if (lastmod.HasValue)
        {
            xml.WriteElementString("lastmod", ns, lastmod.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture));
        }

        xml.WriteElementString("changefreq", ns, changefreq);
        xml.WriteElementString("priority", ns, priority);
        xml.WriteEndElement();
    }

    private static void AppendFact(StringBuilder body, string label, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            body.Append($"<li><strong>{WebUtility.HtmlEncode(label)}:</strong> {WebUtility.HtmlEncode(value)}</li>");
        }
    }

    private static string? JoinBilingual(string? en, string? ar) =>
        string.IsNullOrWhiteSpace(ar) || ar == en ? en : string.IsNullOrWhiteSpace(en) ? ar : $"{en} / {ar}";

    private static bool IsVideoPath(string path)
    {
        var clean = path.Split('?')[0];
        return VideoExtensions.Any(ext => clean.EndsWith(ext, StringComparison.OrdinalIgnoreCase));
    }

    private static string? Clean(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static string Truncate(string value, int max)
    {
        var flat = WhitespaceRegex().Replace(value, " ").Trim();
        return flat.Length <= max ? flat : flat[..(max - 1)].TrimEnd() + "…";
    }

    private static string? FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v))?.Trim();

    private static bool TryGetProperty(JsonElement obj, string name, out JsonElement value)
    {
        if (obj.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in obj.EnumerateObject())
            {
                if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
                {
                    value = property.Value;
                    return true;
                }
            }
        }

        value = default;
        return false;
    }

    private static string? Str(JsonElement obj, string name)
    {
        if (!TryGetProperty(obj, name, out var value))
        {
            return null;
        }

        var text = value.ValueKind switch
        {
            JsonValueKind.String => value.GetString(),
            JsonValueKind.Number => value.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => null,
        };
        return string.IsNullOrWhiteSpace(text) ? null : text.Trim();
    }

    [GeneratedRegex(@"<html[^>]*>", RegexOptions.IgnoreCase)]
    private static partial Regex HtmlTagRegex();

    [GeneratedRegex(@"<title>[\s\S]*?</title>", RegexOptions.IgnoreCase)]
    private static partial Regex TitleRegex();

    [GeneratedRegex(@"<meta\s+name=""description""[\s\S]*?/?>", RegexOptions.IgnoreCase)]
    private static partial Regex MetaDescriptionRegex();

    [GeneratedRegex(@"<meta\s+(?:property|name)=""(?:og|twitter):[a-z_:]+""[^>]*>", RegexOptions.IgnoreCase)]
    private static partial Regex OpenGraphRegex();

    [GeneratedRegex(@"<div id=""root""></div>", RegexOptions.IgnoreCase)]
    private static partial Regex RootRegex();

    [GeneratedRegex(@"[^a-z0-9\u0600-\u06FF]+")]
    private static partial Regex SlugSeparatorRegex();

    [GeneratedRegex(@"\s+")]
    private static partial Regex WhitespaceRegex();

    private sealed class Utf8StringWriter(StringBuilder builder) : StringWriter(builder, CultureInfo.InvariantCulture)
    {
        public override Encoding Encoding => new UTF8Encoding(false);
    }
}
