using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Endpoints for managing user addresses.
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AddressesController(IAddressesAppService addressesAppService) : ControllerBase
{
    /// <summary>
    /// Returns the authenticated user's saved addresses (cached).
    /// </summary>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMine(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await addressesAppService.GetByUserAsync(userId, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Adds a new address for the authenticated user and returns its id.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Add([FromBody] AddAddressRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await addressesAppService.AddAsync(new AddAddressInput
            {
                UserId = userId,
                CityId = request.CityId,
                CountryId = request.CountryId,
                CityName = request.CityName,
                AddressLine1 = request.AddressLine1,
                AddressLine2 = request.AddressLine2
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

    /// <summary>
    /// Updates one of the authenticated user's addresses.
    /// </summary>
    [HttpPut("{addressId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(
        [FromRoute] Guid addressId,
        [FromBody] AddAddressRequest request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await addressesAppService.UpdateAsync(new UpdateAddressInput
            {
                UserId = userId,
                AddressId = addressId,
                CityId = request.CityId,
                CountryId = request.CountryId,
                CityName = request.CityName,
                AddressLine1 = request.AddressLine1,
                AddressLine2 = request.AddressLine2
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

    /// <summary>
    /// Deletes one of the authenticated user's addresses.
    /// </summary>
    [HttpDelete("{addressId:guid}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete([FromRoute] Guid addressId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            await addressesAppService.DeleteAsync(userId, addressId, cancellationToken);
            return Ok(new { addressId, deleted = true });
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

/// <summary>
/// Request body for adding an address.
/// </summary>
public sealed class AddAddressRequest
{
    /// <summary>
    /// City identifier from GET /api/geo/cities. Omit it to resolve by CountryId + CityName instead.
    /// </summary>
    public Guid? CityId { get; set; }

    /// <summary>
    /// Country identifier from GET /api/geo/countries. Required when CityId is omitted.
    /// </summary>
    public short? CountryId { get; set; }

    /// <summary>
    /// City name typed by the user. Matched against the country's cities and created when it is new.
    /// </summary>
    public string? CityName { get; set; }

    /// <summary>
    /// Primary address line.
    /// </summary>
    public string AddressLine1 { get; set; } = string.Empty;

    /// <summary>
    /// Secondary address line.
    /// </summary>
    public string? AddressLine2 { get; set; }
}
