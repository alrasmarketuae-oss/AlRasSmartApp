using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Crawlable endpoints for the web shop (shop.alrasmarketapp.com proxies
/// /sitemap.xml, /robots.txt and /product/* here).
/// </summary>
[Route("api/seo")]
[ApiController]
[AllowAnonymous]
[ApiExplorerSettings(IgnoreApi = true)]
public class SeoController(ISeoAppService seoAppService) : ControllerBase
{
    [HttpGet("sitemap.xml")]
    public async Task<IActionResult> Sitemap(CancellationToken cancellationToken = default)
    {
        var xml = await seoAppService.GetSitemapXmlAsync(cancellationToken);
        Response.Headers.CacheControl = "public,max-age=1800";
        return Content(xml, "application/xml; charset=utf-8");
    }

    [HttpGet("robots.txt")]
    public async Task<IActionResult> Robots(CancellationToken cancellationToken = default)
    {
        var text = await seoAppService.GetRobotsTxtAsync(cancellationToken);
        Response.Headers.CacheControl = "public,max-age=86400";
        return Content(text, "text/plain; charset=utf-8");
    }

    /// <summary>Link-preview image (og:image): redirects to the first photo, or a frame from the video.</summary>
    [HttpGet("product/{productId:guid}/poster.jpg")]
    public async Task<IActionResult> Poster([FromRoute] Guid productId, CancellationToken cancellationToken = default)
    {
        var poster = await seoAppService.GetProductPosterAsync(productId, cancellationToken);
        if (poster is null)
        {
            return NotFound();
        }

        Response.Headers.CacheControl = "public,max-age=43200";
        return poster.Jpeg is { } jpeg ? File(jpeg, "image/jpeg") : Redirect(poster.RedirectUrl!);
    }

    /// <summary>Product page HTML (SPA shell + injected SEO tags); the slug segment is cosmetic.</summary>
    [HttpGet("product/{productId:guid}")]
    [HttpGet("product/{productId:guid}/{slug}")]
    public async Task<IActionResult> Product([FromRoute] Guid productId, CancellationToken cancellationToken = default)
    {
        var html = await seoAppService.GetProductHtmlAsync(productId, cancellationToken);
        if (html is null)
        {
            Response.Headers["X-Robots-Tag"] = "noindex";
            var shell = await seoAppService.GetNotFoundShellAsync(cancellationToken);
            return new ContentResult { StatusCode = StatusCodes.Status404NotFound, Content = shell, ContentType = "text/html; charset=utf-8" };
        }

        Response.Headers.CacheControl = "public,max-age=300";
        return Content(html, "text/html; charset=utf-8");
    }
}
