using BusinessLayer.Constants;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/users")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.UsersView)]
public class AdminUsersController(IAdminUsersAppService adminUsersAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetUsers(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? roleId = null,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? joinedFrom = null,
        [FromQuery] DateTime? joinedTo = null,
        [FromQuery] bool companiesOnly = false,
        CancellationToken cancellationToken = default)
    {
        var result = await adminUsersAppService.GetUsersAsync(
            page,
            pageSize,
            roleId,
            search,
            status,
            joinedFrom,
            joinedTo,
            cancellationToken,
            companiesOnly);
        return Ok(result);
    }

    [HttpGet("{userId}")]
    public async Task<IActionResult> GetUser(string userId, CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.GetUserByIdAsync(userId, cancellationToken);
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

    [HttpPatch("{userId}/active")]
    public async Task<IActionResult> SetUserActive(
        string userId,
        [FromBody] SetUserActiveRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.SetUserActiveAsync(
                userId,
                request.IsActive,
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{userId}")]
    [RequireAdminPermission(AdminPermissions.UsersManage)]
    public async Task<IActionResult> DeleteUser(string userId, CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.DeleteUserAsync(userId, cancellationToken);
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
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

public sealed class SetUserActiveRequest
{
    public bool IsActive { get; set; }
}
