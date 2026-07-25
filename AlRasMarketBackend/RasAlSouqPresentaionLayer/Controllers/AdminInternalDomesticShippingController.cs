using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/internal-shipping")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.SettingsManage)]
public class AdminInternalDomesticShippingController(
    IInternalDomesticShippingAppService internalDomesticShippingAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetRates(CancellationToken cancellationToken = default)
    {
        var result = await internalDomesticShippingAppService.GetAllRatesAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateRates(
        [FromBody] UpdateInternalDomesticShippingRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await internalDomesticShippingAppService.UpdateRatesAsync(new UpdateInternalDomesticShippingInput
            {
                Rates = request.Rates?.Select(x => new UpdateInternalDomesticShippingRateInput
                {
                    Id = x.Id,
                    PriceAed = x.PriceAed
                }).ToList() ?? [],
                ExcessKgRateAed = request.ExcessKgRateAed
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
}

public sealed class UpdateInternalDomesticShippingRequest
{
    public List<UpdateInternalDomesticShippingRateRequest>? Rates { get; set; }

    /// <summary>AED charged per kg above free 10 kg (0–255).</summary>
    public byte? ExcessKgRateAed { get; set; }
}

public sealed class UpdateInternalDomesticShippingRateRequest
{
    public byte Id { get; set; }
    public decimal PriceAed { get; set; }
}
