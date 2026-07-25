using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for category management by admin.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CategoriesController(ICategoriesAppService categoriesAppService, IWebHostEnvironment environment) : ControllerBase
{
    /// <summary>
    /// Returns visible categories for the mobile app (excludes IsHide = true).
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken = default)
    {
        var result = await categoriesAppService.GetAllAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Returns all categories for admin management, including hidden ones.
    /// </summary>
    [HttpGet("manage")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> GetAllForAdmin(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await categoriesAppService.GetAllForAdminAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Shows or hides a category from the mobile app.
    /// </summary>
    [HttpPatch("{categoryId:int}/visibility")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SetVisibility(
        [FromRoute] int categoryId,
        [FromBody] SetCategoryVisibilityRequest request,
        CancellationToken cancellationToken = default)
    {
        if (categoryId < byte.MinValue || categoryId > byte.MaxValue)
        {
            return BadRequest(new { message = "Invalid category id." });
        }

        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await categoriesAppService.SetHideAsync(new SetCategoryHideInput
            {
                UserId = userId,
                CategoryId = (byte)categoryId,
                IsHide = request.IsHide
            }, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Creates a new category.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await categoriesAppService.CreateAsync(new CreateCategoryInput
            {
                UserId = userId,
                NameEn = request.NameEn,
                NameAr = request.NameAr,
                ImgPath = request.ImgPath
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Updates existing category.
    /// </summary>
    [HttpPut("{categoryId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Update([FromRoute] int categoryId, [FromBody] UpdateCategoryRequest request, CancellationToken cancellationToken = default)
    {
        if (categoryId < byte.MinValue || categoryId > byte.MaxValue)
        {
            return BadRequest(new { message = "Invalid category id." });
        }

        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await categoriesAppService.UpdateAsync(new UpdateCategoryInput
            {
                UserId = userId,
                CategoryId = (byte)categoryId,
                NameEn = request.NameEn,
                NameAr = request.NameAr,
                ImgPath = request.ImgPath
            }, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Uploads and compresses category image.
    /// </summary>
    [HttpPost("{categoryId:int}/image/upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UploadImage([FromRoute] int categoryId, [FromForm] UploadCategoryImageRequest request, CancellationToken cancellationToken = default)
    {
        if (categoryId < byte.MinValue || categoryId > byte.MaxValue)
        {
            return BadRequest(new { message = "Invalid category id." });
        }

        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await categoriesAppService.UploadImageAsync(new UploadCategoryImageInput
            {
                UserId = userId,
                CategoryId = (byte)categoryId,
                File = request.File,
                WebRootPath = root
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
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    /// <summary>
    /// Permanently deletes a category (unlinks products first).
    /// </summary>
    [HttpDelete("{categoryId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete([FromRoute] int categoryId, CancellationToken cancellationToken = default)
    {
        if (categoryId < byte.MinValue || categoryId > byte.MaxValue)
        {
            return BadRequest(new { message = "Invalid category id." });
        }

        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var root = environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var result = await categoriesAppService.DeleteAsync(new DeleteCategoryInput
            {
                UserId = userId,
                CategoryId = (byte)categoryId,
                WebRootPath = root
            }, cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }
}

public sealed class CreateCategoryRequest
{
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string ImgPath { get; set; } = string.Empty;
}

public sealed class UpdateCategoryRequest
{
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string? ImgPath { get; set; }
}

public sealed class UploadCategoryImageRequest
{
    public IFormFile? File { get; set; }
}

public sealed class SetCategoryVisibilityRequest
{
    public bool IsHide { get; set; }
}
