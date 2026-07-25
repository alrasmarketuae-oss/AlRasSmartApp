using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/missed-product-searches")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.SearchAccess)]
public class AdminMissedProductSearchesController(IMissedProductSearchAppService missedProductSearchAppService)
    : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] DateTime? fromUtc = null,
        [FromQuery] DateTime? toUtc = null,
        CancellationToken cancellationToken = default)
    {
        var result = await missedProductSearchAppService.GetPagedAsync(
            page,
            pageSize,
            search,
            fromUtc,
            toUtc,
            cancellationToken);
        return Ok(result);
    }
}
