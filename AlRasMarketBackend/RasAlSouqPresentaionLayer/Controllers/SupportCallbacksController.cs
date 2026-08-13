using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/support-callbacks")]
[ApiController]
public class SupportCallbacksController(ISupportCallbackAppService supportCallbackAppService) : ControllerBase
{
    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Create(
        [FromBody] CreateSupportCallbackRequestInput input,
        CancellationToken cancellationToken)
    {
        try
        {
            Guid? userId = null;
            var claim = User.FindFirstValue("EntityId")
                ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (Guid.TryParse(claim, out var parsed))
            {
                userId = parsed;
            }

            var result = await supportCallbackAppService.CreateAsync(userId, input, cancellationToken);
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
}
