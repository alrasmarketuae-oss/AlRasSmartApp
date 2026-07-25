using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/settings")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.SettingsView)]
public class AdminSettingsController(IAdminSettingsAppService adminSettingsAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetSettings(CancellationToken cancellationToken = default)
    {
        var result = await adminSettingsAppService.GetSettingsAsync(cancellationToken);
        return Ok(result);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateSettings(
        [FromBody] UpdateSystemSettingsRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminSettingsAppService.UpdateSettingsAsync(new UpdateSystemSettingsInput
            {
                RetailCommissionPercent = request.RetailCommissionPercent,
                BookingCommissionPercent = request.BookingCommissionPercent,
                RequestsCommissionPercent = request.RequestsCommissionPercent,
                OffersCommissionPercent = request.OffersCommissionPercent,
                ShippingCommissionPercent = request.ShippingCommissionPercent,
                AppName = request.AppName ?? string.Empty,
                SupportEmail = request.SupportEmail,
                PhoneNumber = request.PhoneNumber,
                LandlineNumber = request.LandlineNumber,
                Timezone = request.Timezone,
                Address = request.Address,
                FeaturedAdPriceAed = request.FeaturedAdPriceAed,
                AdDisplayDurationDays = request.AdDisplayDurationDays,
                CategoryCommissions = request.CategoryCommissions?.Select(x => new UpdateCategoryCommissionInput
                {
                    CategoryId = x.CategoryId,
                    CommissionPercent = x.CommissionPercent
                }).ToList()
            }, cancellationToken);

            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public sealed class UpdateSystemSettingsRequest
{
    public decimal RetailCommissionPercent { get; set; }
    public decimal BookingCommissionPercent { get; set; }
    public decimal RequestsCommissionPercent { get; set; }
    public decimal OffersCommissionPercent { get; set; }
    public decimal ShippingCommissionPercent { get; set; }
    public string? AppName { get; set; }
    public string? SupportEmail { get; set; }
    public string? PhoneNumber { get; set; }
    public string? LandlineNumber { get; set; }
    public string? Timezone { get; set; }
    public string? Address { get; set; }
    public decimal FeaturedAdPriceAed { get; set; }
    public int AdDisplayDurationDays { get; set; }
    public List<UpdateCategoryCommissionRequest>? CategoryCommissions { get; set; }
}

public sealed class UpdateCategoryCommissionRequest
{
    public byte CategoryId { get; set; }
    public decimal CommissionPercent { get; set; }
}
