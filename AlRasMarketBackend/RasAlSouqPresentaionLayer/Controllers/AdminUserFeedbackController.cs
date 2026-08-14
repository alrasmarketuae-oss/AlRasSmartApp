using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;
using System.Security.Claims;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/user-feedback")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.ChatAccess)]
public class AdminUserFeedbackController(IUserFeedbackAppService userFeedbackAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetPaged(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] string? type = null,
        CancellationToken cancellationToken = default)
    {
        var result = await userFeedbackAppService.GetPagedAsync(
            page,
            pageSize,
            search,
            status,
            type,
            cancellationToken);
        return Ok(result);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(
        Guid id,
        [FromBody] UpdateUserFeedbackStatusInput input,
        CancellationToken cancellationToken)
    {
        try
        {
            var claim = User.FindFirstValue("EntityId")
                ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(claim, out var adminUserId))
            {
                return Unauthorized();
            }

            var result = await userFeedbackAppService.UpdateStatusAsync(
                id,
                adminUserId,
                input,
                cancellationToken);
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
