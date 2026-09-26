using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>Legacy portfolio inbox — moved to NasserChatBackend /api/admin/inbox.</summary>
[Route("api/nasser-portfolio/admin")]
[ApiController]
[AllowAnonymous]
[ApiExplorerSettings(IgnoreApi = true)]
public class NasserPortfolioAdminController : ControllerBase
{
    [HttpPost("{**path}")]
    [HttpGet("{**path}")]
    [HttpDelete("{**path}")]
    [HttpPost]
    [HttpGet]
    public IActionResult Moved() =>
        StatusCode(StatusCodes.Status410Gone, new
        {
            message = "Portfolio inbox moved to https://api.nasser.chat/api/admin/inbox"
        });
}
