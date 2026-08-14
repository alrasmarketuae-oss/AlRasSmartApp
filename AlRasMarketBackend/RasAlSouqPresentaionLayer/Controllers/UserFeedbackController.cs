using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/user-feedback")]
[ApiController]
public class UserFeedbackController(IUserFeedbackAppService userFeedbackAppService) : ControllerBase
{
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create(
        [FromBody] CreateUserFeedbackInput input,
        CancellationToken cancellationToken)
    {
        try
        {
            var claim = User.FindFirstValue("EntityId")
                ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(claim, out var userId))
            {
                return Unauthorized();
            }

            var result = await userFeedbackAppService.CreateAsync(userId, input, cancellationToken);
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
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
