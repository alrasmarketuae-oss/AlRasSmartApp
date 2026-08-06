using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/products")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ProductsView)]
public class AdminProductsController(
    IAdminProductsAppService adminProductsAppService,
    IProductAssetsAppService productAssetsAppService,
    IWebHostEnvironment environment) : ControllerBase
{
    private readonly IWebHostEnvironment _environment = environment;

    /// <summary>
    /// قائمة الإعلانات للأدمن مع فلاتر: approval=pending|approved|all
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetProductStats(CancellationToken cancellationToken = default)
    {
        var result = await adminProductsAppService.GetProductStatsAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Rebuild CLIP vectors for all product images (name + specs fused with image).
    /// </summary>
    [HttpPost("reindex-image-vectors")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    public async Task<IActionResult> ReindexImageVectors(CancellationToken cancellationToken = default)
    {
        var result = await adminProductsAppService.ReindexImageVectorsAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] string? approval = "pending",
        [FromQuery] byte? categoryId = null,
        [FromQuery] byte? status = null,
        [FromQuery] byte? productTypeId = null,
        [FromQuery] byte? excludeProductTypeId = null,
        [FromQuery] DateTime? createdFrom = null,
        [FromQuery] DateTime? createdTo = null,
        [FromQuery] bool? hasPendingOffers = null,
        [FromQuery] bool? editResubmitOnly = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminProductsAppService.GetProductsAsync(
            page,
            pageSize,
            search,
            approval,
            categoryId,
            status,
            productTypeId,
            excludeProductTypeId,
            createdFrom,
            createdTo,
            hasPendingOffers,
            editResubmitOnly,
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("lookups")]
    public async Task<IActionResult> GetLookups(CancellationToken cancellationToken = default)
    {
        var result = await adminProductsAppService.GetLookupsAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet("{productId}")]
    public async Task<IActionResult> GetById(string productId, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminProductsAppService.GetProductByIdAsync(productId, cancellationToken);
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

    [HttpPut("{productId}")]
    public async Task<IActionResult> Update(
        string productId,
        [FromBody] AdminUpdateProductRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminProductsAppService.UpdateProductAsync(productId, request, cancellationToken);
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("pending")]
    public Task<IActionResult> GetPending(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default) =>
        GetProducts(page, pageSize, search, "pending", null, null, null, null, null, null, null, null, cancellationToken);

    [HttpPost("{productId}/approve")]
    public async Task<IActionResult> Approve(
        string productId,
        [FromBody] AdminRejectProductRequest? request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var message = await adminProductsAppService.ApproveProductAsync(
                productId,
                request,
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{productId}/reject")]
    public async Task<IActionResult> Reject(
        string productId,
        [FromBody] AdminRejectProductRequest? request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var message = await adminProductsAppService.RejectProductAsync(
                productId,
                request ?? new AdminRejectProductRequest(),
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

    [HttpPost("{productId}/images/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadImage(
        string productId,
        [FromForm] UploadProductAssetRequest request,
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
            var result = await productAssetsAppService.UploadImageAsync(new UploadProductImageInput
            {
                ProductId = productId,
                OwnerId = userId,
                File = request.File,
                WebRootPath = root,
                AllowAdminAccess = true
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
    }

    [HttpDelete("{productId}/images/{imageId:long}")]
    public async Task<IActionResult> DeleteImage(
        string productId,
        long imageId,
        CancellationToken cancellationToken = default)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        try
        {
            var message = await adminProductsAppService.DeleteProductImageAsync(
                productId,
                imageId,
                webRoot,
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

    [HttpPost("{productId}/videos/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(110 * 1024 * 1024)]
    public async Task<IActionResult> UploadVideo(
        string productId,
        [FromForm] UploadAdminProductVideoRequest request,
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
            var result = await productAssetsAppService.UploadVideoAsync(new UploadProductVideoInput
            {
                ProductId = productId,
                OwnerId = userId,
                File = request.File,
                VideoDurationSeconds = request.VideoDurationSeconds,
                WebRootPath = root,
                AllowAdminAccess = true,
                ReplaceVideoPath = request.ReplaceVideoPath
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

    [HttpDelete("{productId}/videos")]
    public async Task<IActionResult> DeleteVideo(
        string productId,
        [FromQuery] string path,
        CancellationToken cancellationToken = default)
    {
        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        try
        {
            var message = await adminProductsAppService.DeleteProductVideoAsync(
                productId,
                path,
                webRoot,
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
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    [HttpPut("{productId}/videos/mute")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    public async Task<IActionResult> SetVideoMute(
        string productId,
        [FromBody] SetProductVideoMuteRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminProductsAppService.SetProductVideoMutedAsync(
                productId,
                request.Path,
                request.IsMuted,
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

    [HttpDelete("{productId}")]
    public async Task<IActionResult> Delete(string productId, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

        try
        {
            var message = await adminProductsAppService.DeleteProductAsync(
                productId,
                userId,
                webRoot,
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                message = "Failed to delete product.",
                detail = ex.InnerException?.Message ?? ex.Message
            });
        }
    }
}

public sealed class UploadAdminProductVideoRequest
{
    public IFormFile? File { get; set; }
    public byte VideoDurationSeconds { get; set; }
    public string? ReplaceVideoPath { get; set; }
}
