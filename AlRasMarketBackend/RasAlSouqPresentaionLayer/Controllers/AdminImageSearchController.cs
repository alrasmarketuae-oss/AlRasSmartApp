using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/image-search")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ProductsView)]
public class AdminImageSearchController(
    IAdminImageSearchAppService imageSearchAppService,
    IClipReferenceImageAppService clipReferenceImageAppService) : ControllerBase
{
    [HttpGet("status")]
    public async Task<IActionResult> GetStatus(CancellationToken cancellationToken = default)
    {
        var result = await imageSearchAppService.GetStatusAsync(cancellationToken);
        return Ok(result);
    }

    [HttpGet("reference-images")]
    public async Task<IActionResult> GetReferenceImages(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var result = await clipReferenceImageAppService.GetReferenceImagesAsync(
            page,
            pageSize,
            search,
            cancellationToken);
        return Ok(result);
    }

    [HttpPost("reference-images")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(50 * 1024 * 1024)]
    public async Task<IActionResult> UploadReferenceImages(
        [FromForm] UploadClipReferenceImagesRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var adminIdRaw = User.FindFirst("EntityId")?.Value
                ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? adminId = Guid.TryParse(adminIdRaw, out var parsed) ? parsed : null;

            var files = request.Files ?? [];
            var result = await clipReferenceImageAppService.UploadReferenceImagesAsync(
                request.ProductName ?? string.Empty,
                request.ProductNameAr,
                request.ProductCode,
                files,
                adminId,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("reference-images/{id:long}")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    public async Task<IActionResult> DeleteReferenceImage(long id, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await clipReferenceImageAppService.DeleteReferenceImageAsync(id, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPost("reference-images/reindex")]
    [RequireAdminPermission(AdminPermissions.ProductsManage)]
    public async Task<IActionResult> ReindexReferenceImages(CancellationToken cancellationToken = default)
    {
        var result = await clipReferenceImageAppService.ReindexReferenceImagesAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPost("test")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> TestSearch(
        [FromForm] AdminImageSearchTestRequest request,
        CancellationToken cancellationToken = default)
    {
        if (request.File is null || request.File.Length == 0)
        {
            return BadRequest(new { message = "Image file is required." });
        }

        var extension = Path.GetExtension(request.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(extension))
        {
            return BadRequest(new { message = "Unsupported image format. Allowed: .jpg, .jpeg, .png, .webp" });
        }

        await using var stream = request.File.OpenReadStream();
        var result = await imageSearchAppService.TestSearchAsync(stream, request.File.FileName, cancellationToken);
        return Ok(result);
    }
}

public sealed class AdminImageSearchTestRequest
{
    public IFormFile? File { get; set; }
}

public sealed class UploadClipReferenceImagesRequest
{
    public string? ProductName { get; set; }

    public string? ProductNameAr { get; set; }

    public string? ProductCode { get; set; }

    public List<IFormFile>? Files { get; set; }
}
