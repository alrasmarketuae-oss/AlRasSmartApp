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
    /// TEMP TEST: multipart upload disabled — media must go mobile → R2 (presign + confirm).
    /// </summary>
    [HttpPost("{productId}/images/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public Task<IActionResult> UploadProductImage([FromRoute] string productId, [FromForm] UploadProductAssetRequest request, CancellationToken cancellationToken = default)
    {
        // DISABLED for direct-upload verification — uncomment body below to restore multipart fallback.
        return Task.FromResult<IActionResult>(StatusCode(
            StatusCodes.Status410Gone,
            new { message = "Multipart upload disabled. Use presign + direct R2 PUT + confirm." }));

        /*
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
        */
    }

    /// <summary>
    /// Issues a short-lived R2 PUT URL so the mobile client uploads bytes directly.
    /// Falls back to multipart /images/upload when R2 is not configured.
    /// </summary>
    [HttpPost("{productId}/images/presign")]
    public async Task<IActionResult> PresignProductImage(
        [FromRoute] string productId,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.PresignImageUploadAsync(
                new PresignProductImageInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registers a product image after the client finished PUT to the presigned URL.
    /// Same DB / CLIP / review side effects as multipart upload.
    /// </summary>
    [HttpPost("{productId}/images/confirm")]
    public async Task<IActionResult> ConfirmProductImage(
        [FromRoute] string productId,
        [FromBody] ConfirmProductAssetRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.ConfirmImageUploadAsync(
                new ConfirmProductImageInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    Path = request.Path ?? string.Empty,
                },
                cancellationToken);
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
    /// TEMP TEST: multipart upload disabled — media must go mobile → R2 (presign + confirm).
    /// </summary>
    [HttpPost("{productId}/documents/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public Task<IActionResult> UploadProductDocument([FromRoute] string productId, [FromForm] UploadProductAssetRequest request, CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IActionResult>(StatusCode(
            StatusCodes.Status410Gone,
            new { message = "Multipart upload disabled. Use presign + direct R2 PUT + confirm." }));

        /*
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
        */
    }

    [HttpPost("{productId}/documents/presign")]
    public async Task<IActionResult> PresignProductDocument(
        [FromRoute] string productId,
        [FromBody] PresignProductAssetRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.PresignDocumentUploadAsync(
                new PresignProductDocumentInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    FileName = request.FileName,
                    ContentType = request.ContentType,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost("{productId}/documents/confirm")]
    public async Task<IActionResult> ConfirmProductDocument(
        [FromRoute] string productId,
        [FromBody] ConfirmProductAssetRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.ConfirmDocumentUploadAsync(
                new ConfirmProductDocumentInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    Path = request.Path ?? string.Empty,
                },
                cancellationToken);
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
    }

    /// <summary>
    /// TEMP TEST: multipart upload disabled — media must go mobile → R2 (presign + confirm).
    /// </summary>
    [HttpPost("{productId}/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(110 * 1024 * 1024)]
    public Task<IActionResult> UploadProductVideo(
        [FromRoute] string productId,
        [FromForm] UploadProductVideoRequest request,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IActionResult>(StatusCode(
            StatusCodes.Status410Gone,
            new { message = "Multipart upload disabled. Use presign + direct R2 PUT + confirm." }));

        /*
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
        */
    }

    [HttpPost("{productId}/videos/presign")]
    public async Task<IActionResult> PresignProductVideo(
        [FromRoute] string productId,
        [FromBody] PresignProductVideoBodyRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.PresignVideoUploadAsync(
                new PresignProductVideoInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    FileName = request.FileName,
                    ContentType = request.ContentType,
                    VideoDurationSeconds = request.VideoDurationSeconds,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Issues a presigned PUT URL for a draft image (before the product exists).
    /// Path: product-images/drafts/{userId}/{guid}.jpg
    /// </summary>
    [HttpPost("draft/images/presign")]
    public async Task<IActionResult> PresignDraftImage(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.PresignDraftImageUploadAsync(
                new PresignDraftImageInput { OwnerId = userId },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Issues a presigned PUT URL for a draft video (before the product exists).
    /// Path: product-videos/drafts/{userId}/{guid}{ext}
    /// </summary>
    [HttpPost("draft/videos/presign")]
    public async Task<IActionResult> PresignDraftVideo(
        [FromBody] PresignDraftVideoBodyRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.PresignDraftVideoUploadAsync(
                new PresignDraftVideoInput
                {
                    OwnerId = userId,
                    FileName = request.FileName,
                    ContentType = request.ContentType,
                },
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a draft R2 object. Only objects under product-*/drafts/{callerUserId}/ are allowed.
    /// </summary>
    [HttpDelete("draft")]
    public async Task<IActionResult> DeleteDraft(
        [FromBody] DeleteDraftRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await _productAssetsAppService.DeleteDraftAsync(
                new DeleteDraftInput
                {
                    OwnerId = userId,
                    Path = request.Path ?? string.Empty,
                },
                cancellationToken);
            return Ok(new { message = "Draft deleted." });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    [HttpPost("{productId}/videos/confirm")]
    public async Task<IActionResult> ConfirmProductVideo(
        [FromRoute] string productId,
        [FromBody] ConfirmProductVideoBodyRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.ConfirmVideoUploadAsync(
                new ConfirmProductVideoInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    Path = request.Path ?? string.Empty,
                    VideoDurationSeconds = request.VideoDurationSeconds,
                },
                cancellationToken);
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

    /// <summary>
    /// Confirms many draft/final images (+ optional video) in one request / SaveChanges.
    /// Preferred after create when drafts were uploaded while filling the form.
    /// </summary>
    [HttpPost("{productId}/assets/confirm-batch")]
    public async Task<IActionResult> ConfirmProductAssetsBatch(
        [FromRoute] string productId,
        [FromBody] ConfirmProductAssetsBatchBodyRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _productAssetsAppService.ConfirmProductAssetsBatchAsync(
                new ConfirmProductAssetsBatchInput
                {
                    ProductId = productId,
                    OwnerId = userId,
                    ImagePaths = request.ImagePaths ?? [],
                    VideoPath = request.VideoPath,
                    VideoDurationSeconds = request.VideoDurationSeconds,
                },
                cancellationToken);
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

public sealed class PresignProductAssetRequest
{
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
}

public sealed class PresignProductVideoBodyRequest
{
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public byte? VideoDurationSeconds { get; set; }
}

public sealed class ConfirmProductAssetRequest
{
    public string? Path { get; set; }
}

public sealed class ConfirmProductVideoBodyRequest
{
    public string? Path { get; set; }
    public byte? VideoDurationSeconds { get; set; }
}

public sealed class ConfirmProductAssetsBatchBodyRequest
{
    public List<string>? ImagePaths { get; set; }
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
}

public sealed class PresignDraftVideoBodyRequest
{
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
}

public sealed class DeleteDraftRequest
{
    public string? Path { get; set; }
}
