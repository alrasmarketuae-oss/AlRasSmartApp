using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/search")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.SearchAccess)]
public class AdminGlobalSearchController(IAdminGlobalSearchAppService adminGlobalSearchAppService) : ControllerBase
{
    [HttpGet("suggest")]
    public async Task<IActionResult> Suggest(
        [FromQuery] string? q,
        [FromQuery] int limit = 8,
        CancellationToken cancellationToken = default)
    {
        var items = await adminGlobalSearchAppService.GetSuggestionsAsync(q, limit, cancellationToken);
        return Ok(new { items });
    }

    [HttpGet]
    public async Task<IActionResult> Search(
        [FromQuery] string? q,
        CancellationToken cancellationToken = default)
    {
        var result = await adminGlobalSearchAppService.SearchAsync(q, cancellationToken);
        return Ok(result);
    }
}
