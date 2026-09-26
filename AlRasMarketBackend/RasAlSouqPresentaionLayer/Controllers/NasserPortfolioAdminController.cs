using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Services;

namespace RasAlSouqPresentaionLayer.Controllers;

/// <summary>
/// Private inbox for the Nasser portfolio. Uses its own login (not marketplace accounts)
/// and reads only the portfolio SQLite store.
/// </summary>
[Route("api/nasser-portfolio/admin")]
[ApiController]
[AllowAnonymous]
[ApiExplorerSettings(IgnoreApi = true)]
public class NasserPortfolioAdminController(
    NasserAdminAuth auth,
    INasserPortfolioStore store) : ControllerBase
{
    public sealed class LoginBody
    {
        public string? Username { get; set; }
        public string? Password { get; set; }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginBody body)
    {
        if (!auth.Enabled)
        {
            return NotFound();
        }

        if (auth.IsLockedOut(HttpContext))
        {
            return StatusCode(StatusCodes.Status429TooManyRequests, new { message = "Too many attempts. Try later." });
        }

        var token = auth.Login(HttpContext, body.Username, body.Password);
        if (token is null)
        {
            await Task.Delay(Random.Shared.Next(400, 900));
            return Unauthorized(new { message = "Invalid credentials." });
        }

        return Ok(new { token, expiresAt = DateTimeOffset.UtcNow.Add(NasserAdminAuth.TokenLifetime) });
    }

    [HttpGet("stats")]
    public async Task<IActionResult> Stats(CancellationToken cancellationToken) =>
        !auth.Validate(HttpContext) ? Unauthorized() : Ok(await store.GetStatsAsync(cancellationToken));

    [HttpGet("conversations")]
    public async Task<IActionResult> Conversations(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 30,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default) =>
        !auth.Validate(HttpContext)
            ? Unauthorized()
            : Ok(await store.ListConversationsAsync(page, pageSize, search, cancellationToken));

    [HttpGet("conversations/{id}")]
    public async Task<IActionResult> Conversation(string id, CancellationToken cancellationToken)
    {
        if (!auth.Validate(HttpContext))
        {
            return Unauthorized();
        }

        var detail = await store.GetConversationAsync(id, cancellationToken);
        return detail is null ? NotFound() : Ok(detail);
    }

    [HttpDelete("conversations/{id}")]
    public async Task<IActionResult> DeleteConversation(string id, CancellationToken cancellationToken)
    {
        if (!auth.Validate(HttpContext))
        {
            return Unauthorized();
        }

        return await store.DeleteConversationAsync(id, cancellationToken) ? NoContent() : NotFound();
    }

    [HttpGet("leads")]
    public async Task<IActionResult> Leads(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default) =>
        !auth.Validate(HttpContext)
            ? Unauthorized()
            : Ok(await store.ListLeadsAsync(page, pageSize, cancellationToken));

    [HttpGet("images/{fileName}")]
    public IActionResult Image(string fileName)
    {
        if (!auth.Validate(HttpContext))
        {
            return Unauthorized();
        }

        var path = store.ResolveImagePath(fileName);
        if (path is null)
        {
            return NotFound();
        }

        Response.Headers.CacheControl = "private, no-store";
        return PhysicalFile(path, fileName.EndsWith(".png", StringComparison.Ordinal) ? "image/png" : "image/jpeg");
    }
}
