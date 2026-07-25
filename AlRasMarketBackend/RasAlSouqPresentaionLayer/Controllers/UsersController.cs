using System.Security.Claims;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/users")]
[ApiController]
[Authorize]
public class UsersController(IProfileAppService profileAppService) : ControllerBase
{
    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile(CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var profile = await profileAppService.GetMyProfileAsync(userId, cancellationToken);
            return Ok(profile);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile(
        [FromBody] UpdateProfileRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        try
        {
            var profile = await profileAppService.UpdateMyProfileAsync(
                userId,
                new UpdateProfileInput
                {
                    FullName = request.FullName,
                    PhoneNumber = request.PhoneNumber,
                    BirthDate = request.BirthDate,
                    CompanyName = request.CompanyName,
                    CommercialRegister = request.CommercialRegister,
                    TaxNumber = request.TaxNumber,
                    LandNumber = request.LandNumber
                },
                cancellationToken);
            return Ok(profile);
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

    [HttpPut("me/image")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> UploadMyProfileImage(
        [FromForm] UploadProfileImageRequest request,
        [FromServices] IWebHostEnvironment environment,
        CancellationToken cancellationToken)
    {
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        if (request.File is null || request.File.Length == 0)
        {
            return BadRequest(new { message = "File is required." });
        }

        try
        {
            var profile = await profileAppService.UploadMyProfileImageAsync(
                userId,
                new UploadProfileImageInput
                {
                    File = request.File,
                    WebRootPath = environment.WebRootPath
                },
                cancellationToken);
            return Ok(profile);
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

    private string? GetCurrentUserId() =>
        User.FindFirstValue("EntityId")
        ?? User.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? User.FindFirstValue(ClaimTypes.Name)
        ?? User.FindFirstValue("sub");
}

public sealed class UpdateProfileRequest
{
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? CompanyName { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? LandNumber { get; set; }
}

public sealed class UploadProfileImageRequest
{
    public IFormFile? File { get; set; }
}
