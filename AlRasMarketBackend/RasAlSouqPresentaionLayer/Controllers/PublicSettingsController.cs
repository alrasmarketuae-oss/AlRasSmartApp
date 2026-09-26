using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/settings")]
[ApiController]
public class PublicSettingsController(IAdminSettingsAppService adminSettingsAppService) : ControllerBase
{
    /// <summary>Public commission rates for Terms &amp; Privacy (app + website).</summary>
    [HttpGet("commissions")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCommissions(CancellationToken cancellationToken = default)
    {
        var result = await adminSettingsAppService.GetPublicCommissionsAsync(cancellationToken);
        return Ok(result);
    }

    /// <summary>Latest / minimum app versions for Android &amp; iOS update prompts.</summary>
    [HttpGet("app-version")]
    [AllowAnonymous]
    public async Task<IActionResult> GetAppVersion(CancellationToken cancellationToken = default)
    {
        var result = await adminSettingsAppService.GetPublicAppVersionAsync(cancellationToken);
        return Ok(result);
    }
}
