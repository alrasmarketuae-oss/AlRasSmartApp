using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Admin endpoints for reviewing and approving company accounts.
/// </summary>
[Route("api/admin/companies")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
[RequireAdminPermission(AdminPermissions.UsersManage)]
public class AdminCompaniesController(
    IAdminCompaniesAppService adminCompaniesAppService) : ControllerBase
{
    private readonly IAdminCompaniesAppService _adminCompaniesAppService = adminCompaniesAppService;

    /// <summary>
    /// Returns all pending company accounts with licence and company images.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>List of pending seller accounts.</returns>
    [HttpGet("pending")]
    public async Task<IActionResult> GetPendingCompanies(CancellationToken cancellationToken)
    {
        var pending = await _adminCompaniesAppService.GetPendingCompaniesAsync(cancellationToken);
        return Ok(pending);
    }

    /// <summary>
    /// Approves a pending company account and sends background notifications.
    /// </summary>
    /// <param name="companyUserId">Company user id.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Approval status message.</returns>
    [HttpPost("{companyUserId}/approve")]
    public async Task<IActionResult> ApproveCompany(string companyUserId, CancellationToken cancellationToken)
    {
        try
        {
            var message = await _adminCompaniesAppService.ApproveCompanyAsync(companyUserId, cancellationToken);
            return Ok(new { message });
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

    /// <summary>
    /// Rejects a pending company account and sends the supplier a push notification and email with the reason.
    /// </summary>
    [HttpPost("{companyUserId}/reject")]
    public async Task<IActionResult> RejectCompany(
        string companyUserId,
        [FromBody] AdminRejectCompanyRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var message = await _adminCompaniesAppService.RejectCompanyAsync(
                companyUserId,
                request,
                cancellationToken);
            return Ok(new { message });
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
