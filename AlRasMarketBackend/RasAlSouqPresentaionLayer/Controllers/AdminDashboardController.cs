using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Admin dashboard statistics, charts, and activity feeds.
/// </summary>
[Route("api/admin/dashboard")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.DashboardView)]
public class AdminDashboardController(IAdminDashboardAppService adminDashboardAppService) : ControllerBase
{
    private readonly IAdminDashboardAppService _adminDashboardAppService = adminDashboardAppService;

    /// <summary>
    /// Returns dashboard stats, monthly sales chart, recent orders, users, and activity.
    /// Order sales metrics are based on delivered orders only.
    /// Optional <paramref name="createdFrom"/> / <paramref name="createdTo"/> filter the period (UTC dates).
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetDashboard(
        [FromQuery] DateTime? createdFrom,
        [FromQuery] DateTime? createdTo,
        CancellationToken cancellationToken)
    {
        var dashboard = await _adminDashboardAppService.GetDashboardAsync(
            createdFrom,
            createdTo,
            cancellationToken);
        return Ok(dashboard);
    }
}
