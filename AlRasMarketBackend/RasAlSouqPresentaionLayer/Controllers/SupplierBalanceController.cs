using System.Security.Claims;
using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/supplier/balance")]
[ApiController]
[Authorize(Roles = "Seller")]
public class SupplierBalanceController(
    ISupplierBalanceService supplierBalanceService,
    IUserIbanAppService userIbanAppService,
    IWithdrawalRequestsAppService withdrawalRequestsAppService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetBalance(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var balance = await supplierBalanceService.GetBalanceAsync(userId.Value, cancellationToken);
        return Ok(new { balance });
    }

    [HttpGet("statement")]
    public async Task<IActionResult> GetStatement(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] byte? entryType = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var statement = await supplierBalanceService.GetStatementAsync(
            userId.Value,
            page,
            pageSize,
            entryType,
            cancellationToken);
        return Ok(statement);
    }

    [HttpGet("ibans")]
    public async Task<IActionResult> GetIbans(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var result = await userIbanAppService.GetMyIbansAsync(userId.Value.ToString("D"), cancellationToken);
        return Ok(result);
    }

    [HttpPost("ibans")]
    public async Task<IActionResult> AddIban([FromBody] BusinessLayer.Dtos.CreateUserIbanRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await userIbanAppService.AddMyIbanAsync(userId.Value.ToString("D"), request, cancellationToken);
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
    }

    [HttpGet("withdrawals")]
    public async Task<IActionResult> GetWithdrawals(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        var result = await withdrawalRequestsAppService.GetMyWithdrawalRequestsAsync(userId.Value.ToString("D"), cancellationToken);
        return Ok(result);
    }

    [HttpPost("withdrawals")]
    public async Task<IActionResult> CreateWithdrawal(
        [FromBody] BusinessLayer.Dtos.CreateWithdrawalRequestInput request,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Invalid token." });
        }

        try
        {
            var result = await withdrawalRequestsAppService.CreateMyWithdrawalRequestAsync(userId.Value.ToString("D"), request, cancellationToken);
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

    private Guid? GetUserId()
    {
        var idValue = User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");
        return Guid.TryParse(idValue, out var userId) ? userId : null;
    }
}
