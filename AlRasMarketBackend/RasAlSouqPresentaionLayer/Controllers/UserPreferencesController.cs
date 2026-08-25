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

    /// <summary>Returns whether the user allows FCM/email notification delivery.</summary>
    [HttpGet("notifications")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetNotificationsPreference(CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await userPreferencesAppService.GetNotificationsPreferenceAsync(
                userId,
                cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>Turns push/email notifications on or off. In-app inbox still receives rows.</summary>
    [HttpPut("notifications")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateNotificationsPreference(
        [FromBody] UpdateNotificationsPreferenceRequest request,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await userPreferencesAppService.UpdateNotificationsPreferenceAsync(
                userId,
                new UpdateNotificationsPreferenceInput
                {
                    IsNotificationsOn = request.IsNotificationsOn,
                },
                cancellationToken);
            return Ok(result);
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

public sealed class UpdateNotificationsPreferenceRequest
{
    public bool IsNotificationsOn { get; set; } = true;
}
