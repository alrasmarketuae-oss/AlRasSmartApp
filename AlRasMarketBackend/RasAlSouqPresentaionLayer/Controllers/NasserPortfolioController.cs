using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Legacy portfolio routes — permanently moved to NasserChatBackend (api.nasser.chat).
/// Kept as 410 Gone so old clients get a clear migration signal.
/// </summary>
[Route("api/nasser-portfolio")]
[ApiController]
[AllowAnonymous]
public class NasserPortfolioController : ControllerBase
{
    [HttpPost("leads")]
    [HttpGet("ai/quota")]
    [HttpPost("ai/chat")]
    [HttpGet("{**path}")]
    [HttpPost("{**path}")]
    public IActionResult Moved() =>
        StatusCode(StatusCodes.Status410Gone, new
        {
            message =
                "Nasser chat / images moved to https://api.nasser.chat. " +
                "Use /api/ai/chat, /api/leads, and /api/admin/inbox on that host."
        });
}
