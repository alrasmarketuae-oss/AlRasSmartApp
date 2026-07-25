using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Geographic lookup endpoints.
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class GeoController(
    IInternationalShippingAppService internationalShippingAppService,
    IStaticReferenceCache staticReferenceCache) : ControllerBase
{
    [HttpGet("countries")]
    public async Task<IActionResult> GetCountries(CancellationToken cancellationToken = default)
    {
        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);
        var countries = staticReferenceCache.GetCountries()
            .Select(x => new
            {
                id = x.Id,
                countryId = x.Id,
                countryNameEn = x.CountryNameEn,
                countryNameAr = x.CountryNameAr,
                iso2Code = x.Iso2Code
            })
            .ToList();

        return Ok(new
        {
            count = countries.Count,
            items = countries
        });
    }

    /// <summary>
    /// Returns cities for a country. Pass countryName or countryId.
    /// </summary>
    [HttpGet("cities")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCities(
        [FromQuery] string? countryName,
        [FromQuery] short? countryId,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(countryName) && !countryId.HasValue)
        {
            return BadRequest(new { message = "countryName or countryId is required." });
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        try
        {
            var result = !string.IsNullOrWhiteSpace(countryName)
                ? staticReferenceCache.GetCitiesByCountryNameResponse(countryName)
                : staticReferenceCache.GetCitiesByCountryIdResponse(countryId!.Value);

            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Returns cities for a country by its English, Arabic, or ISO name.
    /// </summary>
    [HttpGet("countries/{countryName}/cities")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCitiesByCountryName(
        [FromRoute] string countryName,
        CancellationToken cancellationToken = default)
    {
        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        try
        {
            var result = staticReferenceCache.GetCitiesByCountryNameResponse(countryName);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    [HttpGet("units")]
    public async Task<IActionResult> GetUnits(CancellationToken cancellationToken = default)
    {
        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);
        var units = staticReferenceCache.GetUnits()
            .Select(x => new
            {
                x.Id,
                x.UnitNameEn
            });

        return Ok(units);
    }

    [HttpGet("roles")]
    public async Task<IActionResult> GetRoles(CancellationToken cancellationToken = default)
    {
        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);
        var roles = staticReferenceCache.GetRoles()
            .Select(x => new
            {
                x.Id,
                x.RoleName
            });

        return Ok(roles);
    }

    /// <summary>
    /// Returns all ports for a given country name.
    /// </summary>
    [HttpGet("countries/{countryName}/ports")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPortsByCountryName([FromRoute] string countryName, CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await internationalShippingAppService.GetPortsByCountryNameAsync(countryName, cancellationToken);
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
}
