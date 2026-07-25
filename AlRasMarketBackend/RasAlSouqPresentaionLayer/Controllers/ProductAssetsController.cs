using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for uploading product images and product documents.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProductAssetsController(IProductAssetsAppService productAssetsAppService, IWebHostEnvironment environment) : ControllerBase
{
    private readonly IProductAssetsAppService _productAssetsAppService = productAssetsAppService;
    private readonly IWebHostEnvironment _environment = environment;

    /// <summary>
    /// Uploads one image file for a product.
    /// DEV: any authenticated user. PRODUCTION: owner or admin only (see commented blocks).
    /// </summary>
    [HttpPost("{productId}/images/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadProductImage([FromRoute] string productId, [FromForm] UploadProductAssetRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _productAssetsAppService.UploadImageAsync(new UploadProductImageInput
            {
                ProductId = productId,
                OwnerId = userId,
                File = request.File,
                WebRootPath = root,
                // PRODUCTION: فعّل السطر التالي عند إرجاع التحقق من الملكية في ProductAssetsAppService
                // AllowAdminAccess = User.IsInRole("Admin"),
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        // PRODUCTION: أزل التعليق عند تفعيل UnauthorizedAccessException في الـ service
        /*
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        */
    }

    /// <summary>
    /// Deletes one product image by storage path (company owner edit flow).
    /// </summary>
    [HttpDelete("{productId}/images")]
    public async Task<IActionResult> DeleteProductImageByPath(
        [FromRoute] string productId,
        [FromQuery] string path,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var message = await _productAssetsAppService.DeleteImageByPathAsync(
                productId,
                path,
                userId,
                root,
                cancellationToken);
            return Ok(new { message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Uploads one document file for a product.
    /// DEV: any authenticated user. PRODUCTION: owner or admin only (see commented blocks).
    /// </summary>
    [HttpPost("{productId}/documents/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> UploadProductDocument([FromRoute] string productId, [FromForm] UploadProductAssetRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _productAssetsAppService.UploadDocumentAsync(new UploadProductDocumentInput
            {
                ProductId = productId,
                OwnerId = userId,
                File = request.File,
                WebRootPath = root,
                // PRODUCTION: فعّل السطر التالي عند إرجاع التحقق من الملكية في ProductAssetsAppService
                // AllowAdminAccess = User.IsInRole("Admin"),
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        // PRODUCTION: أزل التعليق عند تفعيل UnauthorizedAccessException في الـ service
        /*
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        */
    }

    /// <summary>
    /// Uploads one video file for a product (supports multiple videos per listing).
    /// </summary>
    [HttpPost("{productId}/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(110 * 1024 * 1024)]
    public async Task<IActionResult> UploadProductVideo(
        [FromRoute] string productId,
        [FromForm] UploadProductVideoRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await _productAssetsAppService.UploadVideoAsync(new UploadProductVideoInput
            {
                ProductId = productId,
                OwnerId = userId,
                File = request.File,
                VideoDurationSeconds = request.VideoDurationSeconds,
                WebRootPath = root,
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}

public sealed class UploadProductAssetRequest
{
    public IFormFile? File { get; set; }
}

public sealed class UploadProductVideoRequest
{
    public IFormFile? File { get; set; }
    public byte? VideoDurationSeconds { get; set; }
}
