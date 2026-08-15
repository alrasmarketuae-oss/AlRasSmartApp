using System.Security.Claims;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for international shipping posts and route search.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class InternationalShippingController(IInternationalShippingAppService internationalShippingAppService) : ControllerBase
{
    /// <summary>
    /// Creates a new international shipping post by the authenticated supplier.
    /// </summary>
    [HttpPost("posts")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CreatePost([FromBody] CreateInternationalShippingPostRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst("EntityId")?.Value ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await internationalShippingAppService.CreatePostAsync(new CreateInternationalShippingPostInput
            {
                PublisherUserId = userId,
                FromCountryName = request.FromCountryName,
                FromPortName = request.FromPortName,
                ToCountryName = request.ToCountryName,
                ToPortName = request.ToPortName,
                PriceUsd = request.PriceUsd,
                ShippingCostUsd = request.ShippingCostUsd,
                PhoneNumber = request.PhoneNumber,
                Container20ftPriceUsd = request.Container20ftPriceUsd,
                Container40ftPriceUsd = request.Container40ftPriceUsd,
                MinDurationDays = request.MinDurationDays,
                MaxDurationDays = request.MaxDurationDays,
                Details = request.Details
               
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
    /// Searches shipping posts by origin/destination country and port names.
    /// </summary>
    [HttpGet("search")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Search(
        [FromQuery] string? fromCountryName,
        [FromQuery] string? fromPortName,
        [FromQuery] string? toCountryName,
        [FromQuery] string? toPortName,
        CancellationToken cancellationToken = default)
    {
        var result = await internationalShippingAppService.SearchAsync(new SearchInternationalShippingInput
        {
            FromCountryName = fromCountryName,
            FromPortName = fromPortName,
            ToCountryName = toCountryName,
            ToPortName = toPortName
        }, cancellationToken);

        return Ok(result);
    }
}

public sealed class CreateInternationalShippingPostRequest
{
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal PriceUsd { get; set; }
    public decimal ShippingCostUsd { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public decimal? Container20ftPriceUsd { get; set; }
    public decimal? Container40ftPriceUsd { get; set; }
    public int? MinDurationDays { get; set; }
    public int? MaxDurationDays { get; set; }
    public string? Details { get; set; }
}
