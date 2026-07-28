using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/finance")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.FinanceView)]
public class AdminFinanceController(IAdminFinanceAppService adminFinanceAppService) : ControllerBase
{
    [HttpGet("withdrawals")]
    public async Task<IActionResult> GetWithdrawals(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? statusId = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        var result = await adminFinanceAppService.GetWithdrawalRequestsAsync(
            new AdminGetWithdrawalRequestsInput
            {
                Page = page,
                PageSize = pageSize,
                StatusId = statusId,
                Search = search
            },
            cancellationToken);
        return Ok(result);
    }

    [HttpGet("companies/{userId}")]
    public async Task<IActionResult> GetCompanyProfile(string userId, CancellationToken cancellationToken)
    {
        try
        {
            var result = await adminFinanceAppService.GetCompanyFinanceProfileAsync(userId, cancellationToken);
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

    [HttpGet("companies/{userId}/statement")]
    public async Task<IActionResult> GetCompanyStatement(
        string userId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await adminFinanceAppService.GetCompanyBalanceStatementAsync(userId, page, pageSize, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("withdrawals/{withdrawalRequestId}/mark-paid")]
    [RequireAdminPermission(AdminPermissions.FinanceManage)]
    public async Task<IActionResult> MarkWithdrawalPaid(
        string withdrawalRequestId,
        [FromBody] AdminMarkWithdrawalPaidInput request,
        CancellationToken cancellationToken)
    {
        var adminUserId = GetUserId();
        if (adminUserId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await adminFinanceAppService.MarkWithdrawalPaidAsync(
                adminUserId,
                withdrawalRequestId,
                request,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }

    private string? GetUserId() =>
        User.FindFirst("EntityId")?.Value
        ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst("sub")?.Value;
}
