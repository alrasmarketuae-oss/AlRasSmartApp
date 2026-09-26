using BusinessLayer.Constants;
using BusinessLayer.Dtos;
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
    [HttpPost]
    [RequireAdminPermission(AdminPermissions.UsersManage)]
    public async Task<IActionResult> CreateUser(
        [FromBody] CreateAdminUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.CreateUserAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPut("{userId}")]
    [RequireAdminPermission(AdminPermissions.UsersManage)]
    public async Task<IActionResult> UpdateUser(
        string userId,
        [FromBody] UpdateAdminUserRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.UpdateUserAsync(userId, request, cancellationToken);
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
            return Conflict(new { message = ex.Message });
        }
    }

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
        [FromQuery] bool? isCustomer = null,
        [FromQuery] bool pendingProfileEditsOnly = false,
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
            companiesOnly,
            isCustomer,
            pendingProfileEditsOnly);
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

    /// <summary>Convert company-customer (IsCustomer=true) Seller to supplier (IsCustomer=false).</summary>
    [HttpPost("{userId}/convert-to-supplier")]
    [RequireAdminPermission(AdminPermissions.UsersManage)]
    public async Task<IActionResult> ConvertToSupplier(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.ConvertCompanyCustomerToSupplierAsync(
                userId,
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

    /// <summary>Convert supplier (IsCustomer=false) Seller to company customer (IsCustomer=true).</summary>
    [HttpPost("{userId}/convert-to-company-customer")]
    [RequireAdminPermission(AdminPermissions.UsersManage)]
    public async Task<IActionResult> ConvertToCompanyCustomer(
        string userId,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminUsersAppService.ConvertSupplierToCompanyCustomerAsync(
                userId,
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
