using BusinessLayer.Constants;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.StaticFiles;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Serves media assets through the API pipeline (CORS + auth) so the admin
/// dashboard can canvas/fetch images (blur/download). Always streams bytes —
/// never redirects to the public CDN (CDN has no CORS for the dashboard origin).
/// </summary>
[Route("api/admin/assets")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ProductsView)]
public class AdminAssetsController(
    IMediaStorageService mediaStorage) : ControllerBase
{
    private static readonly HashSet<string> AllowedFolders = new(StringComparer.OrdinalIgnoreCase)
    {
        "product-images",
        "product-videos",
        "product-documents",
        "images",
        "branding",
        "company-images",
        "company-licences",
        "chat-images",
        "chat-voice",
        "chat-videos",
        "chat-files",
        "home-banners",
        "order-videos",
        "order-returns",
    };

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string path, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return BadRequest(new { message = "path is required." });
        }

        var relative = NormalizeAssetPath(path);
        if (relative is null)
        {
            return BadRequest(new { message = "Invalid asset path." });
        }

        var folder = relative.Split('/', StringSplitOptions.RemoveEmptyEntries).FirstOrDefault();
        if (folder is null || !AllowedFolders.Contains(folder))
        {
            return BadRequest(new { message = "Asset folder is not allowed." });
        }

        var normalized = "/" + relative;
        var stream = await mediaStorage.OpenReadAsync(normalized, cancellationToken);
        if (stream is null)
        {
            return NotFound(new { message = "File not found." });
        }

        var provider = new FileExtensionContentTypeProvider();
        if (!provider.TryGetContentType(relative, out var contentType))
        {
            contentType = "application/octet-stream";
        }

        var fileName = Path.GetFileName(relative);
        Response.Headers.CacheControl = "private, max-age=60";
        Response.Headers.ContentDisposition = $"inline; filename=\"{fileName}\"";

        return File(stream, contentType, enableRangeProcessing: true);
    }

    private static string? NormalizeAssetPath(string path)
    {
        var trimmed = path.Trim();
        if (trimmed.Contains("..", StringComparison.Ordinal))
        {
            return null;
        }

        if (Uri.TryCreate(trimmed, UriKind.Absolute, out var absolute))
        {
            trimmed = absolute.AbsolutePath;
        }

        trimmed = trimmed.Replace('\\', '/').Trim('/');
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return null;
        }

        if (trimmed.StartsWith("api/", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return WebRootFileHelper.NormalizeStoredPath("/" + trimmed).TrimStart('/');
    }
}
