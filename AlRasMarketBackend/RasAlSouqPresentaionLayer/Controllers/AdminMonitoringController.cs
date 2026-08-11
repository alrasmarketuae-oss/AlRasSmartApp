using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/monitoring")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.MonitoringView)]
public class AdminMonitoringController(IAdminMonitoringAppService monitoringAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetOverview(
        [FromQuery] string? range = "1h",
        CancellationToken cancellationToken = default)
    {
        var result = await monitoringAppService.GetOverviewAsync(range, cancellationToken);
        return Ok(result);
    }
}
