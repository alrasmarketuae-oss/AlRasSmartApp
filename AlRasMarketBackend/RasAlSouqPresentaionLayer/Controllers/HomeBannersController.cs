using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for home page banners.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class HomeBannersController(IHomeBannersAppService homeBannersAppService, IWebHostEnvironment environment) : ControllerBase
{
    private readonly IHomeBannersAppService _homeBannersAppService = homeBannersAppService;
    private readonly IWebHostEnvironment _environment = environment;

    private string WebRootPath =>
        _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

    private string? CurrentUserId =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    /// <summary>
    /// Uploads a home banner image with link and display order.
    /// Admin only.
    /// </summary>
    [HttpPost]
    [Authorize]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromForm] CreateHomeBannerRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(CurrentUserId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _homeBannersAppService.CreateAsync(new CreateHomeBannerInput
            {
                UserId = CurrentUserId,
                File = request.File,
                LinkUrl = request.LinkUrl,
                DisplayOrder = request.DisplayOrder,
                WebRootPath = WebRootPath
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
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Returns all home banners sorted by display order.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken = default)
    {
        var result = await _homeBannersAppService.GetAllAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Updates banner link, display order, and optionally the image.
    /// Admin only.
    /// </summary>
    [HttpPut("{bannerId:int}")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Update(
        [FromRoute] int bannerId,
        [FromForm] UpdateHomeBannerRequest request,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(CurrentUserId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _homeBannersAppService.UpdateAsync(new UpdateHomeBannerInput
            {
                UserId = CurrentUserId,
                BannerId = bannerId,
                LinkUrl = request.LinkUrl,
                DisplayOrder = request.DisplayOrder,
                File = request.File,
                WebRootPath = WebRootPath
            }, cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Deletes a banner and its physical image file.
    /// Admin only.
    /// </summary>
    [HttpDelete("{bannerId:int}")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] int bannerId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(CurrentUserId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await _homeBannersAppService.DeleteAsync(new DeleteHomeBannerInput
            {
                UserId = CurrentUserId,
                BannerId = bannerId,
                WebRootPath = WebRootPath
            }, cancellationToken);

            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
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
}

public sealed class CreateHomeBannerRequest
{
    public IFormFile? File { get; set; }
    public string LinkUrl { get; set; } = string.Empty;
    public short DisplayOrder { get; set; }
}

public sealed class UpdateHomeBannerRequest
{
    public string? LinkUrl { get; set; }
    public short? DisplayOrder { get; set; }
    public IFormFile? File { get; set; }
}
