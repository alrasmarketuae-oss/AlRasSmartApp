using System.Security.Claims;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace RasAlSouqPresentaionLayer.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AiAssistantController(IAiAssistantAppService assistant) : ControllerBase
{
    [HttpPost("ask")]
    [AllowAnonymous]
    [EnableRateLimiting("ai-assistant")]
    public async Task<ActionResult<AiAssistantAnswer>> Ask(
        [FromBody] AiAssistantAskRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            Guid? userId = null;
            var raw = User.FindFirst("EntityId")?.Value
                ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst("sub")?.Value;
            if (Guid.TryParse(raw, out var parsed))
            {
                userId = parsed;
            }

            var result = await assistant.AskAsync(
                userId,
                request,
                history: null,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
