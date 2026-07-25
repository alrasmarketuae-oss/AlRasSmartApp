using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UserPreferencesController(IUserPreferencesAppService userPreferencesAppService) : ControllerBase
{
    /// <summary>Returns the authenticated user's preferred language.</summary>
    [HttpGet("language")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPreferredLanguage(CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await userPreferencesAppService.GetPreferredLanguageAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>Updates the authenticated user's preferred language.</summary>
    [HttpPut("language")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePreferredLanguage(
        [FromBody] UpdatePreferredLanguageRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await userPreferencesAppService.UpdatePreferredLanguageAsync(
                userId,
                new UpdatePreferredLanguageInput { Language = request.Language },
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

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
}

public sealed class UpdatePreferredLanguageRequest
{
    public string Language { get; set; } = "en";
}
