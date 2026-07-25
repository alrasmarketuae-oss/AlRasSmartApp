using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/ports")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ShippingView)]
public class AdminPortsController(IPortNameArBackfillService portNameArBackfillService) : ControllerBase
{
    /// <summary>
    /// Fills Ports.PortNameAr for rows still null using OpenAI (batched).
    /// Call repeatedly until RemainingAfter is 0.
    /// </summary>
    [HttpPost("backfill-arabic")]
    public async Task<IActionResult> BackfillArabic(
        [FromQuery] int batchSize = 40,
        [FromQuery] int maxBatches = 5,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await portNameArBackfillService.BackfillAsync(
                batchSize,
                maxBatches,
                cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
