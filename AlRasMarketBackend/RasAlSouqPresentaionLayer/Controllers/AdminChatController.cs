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

    /// <summary>
    /// AI translation of a single chat message: Arabic → English, otherwise → Arabic.
    /// </summary>
    [HttpPost("translate")]
    [RequireAdminPermission(AdminPermissions.ChatAccess)]
    public async Task<ActionResult<AdminChatTranslateDto>> Translate(
        [FromBody] AdminChatTranslateRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            return Ok(await chatReportAppService.TranslateMessageAsync(request, cancellationToken));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, new { message = ex.Message });
        }
    }
}
