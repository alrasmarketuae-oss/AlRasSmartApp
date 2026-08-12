using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Authorization;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/admin/chat")]
[ApiController]
[Authorize(Roles = "Admin,Employee")]
public sealed class AdminChatController(IAdminChatReportAppService chatReportAppService) : ControllerBase
{
    /// <summary>
    /// Builds an AI admin report from decrypted chat messages plus the participant's ad catalog.
    /// </summary>
    [HttpPost("company-report")]
    [RequireAdminPermission(AdminPermissions.ChatAccess)]
    public async Task<ActionResult<AdminChatCompanyReportDto>> GenerateCompanyReport(
        [FromBody] AdminChatCompanyReportRequest request,
        CancellationToken cancellationToken = default)
    {
        var result = await chatReportAppService.GenerateCompanyReportAsync(request, cancellationToken);
        return Ok(result);
    }
}
