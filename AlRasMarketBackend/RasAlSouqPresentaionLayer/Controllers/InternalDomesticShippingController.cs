using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/[controller]")]
[ApiController]
public class InternalDomesticShippingController(
    IInternalDomesticShippingAppService internalDomesticShippingAppService) : ControllerBase
{
    /// <summary>Returns all UAE emirate domestic shipping rates (cached).</summary>
    [HttpGet("emirates")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllRates(CancellationToken cancellationToken = default)
    {
        var result = await internalDomesticShippingAppService.GetAllRatesAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>Returns domestic shipping price for a specific emirate (cached).</summary>
    [HttpGet("price")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPriceByEmirate(
        [FromQuery] string emirate,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await internalDomesticShippingAppService.GetPriceByEmirateAsync(emirate, cancellationToken);
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
