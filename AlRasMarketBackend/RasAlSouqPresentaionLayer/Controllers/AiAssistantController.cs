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
                onThinkingStep: null,
                cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("correct-dictation")]
    [AllowAnonymous]
    [EnableRateLimiting("ai-assistant")]
    public async Task<ActionResult<AiAssistantCorrectDictationResult>> CorrectDictation(
        [FromBody] AiAssistantCorrectDictationRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await assistant.CorrectDictationAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// High-accuracy voice → text via OpenAI transcription (Whisper-class), then light polish.
    /// </summary>
    [HttpPost("transcribe-voice")]
    [AllowAnonymous]
    [EnableRateLimiting("ai-assistant")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = 10 * 1024 * 1024)]
    public async Task<ActionResult<AiAssistantCorrectDictationResult>> TranscribeVoice(
        IFormFile? audio,
        [FromForm] string? language,
        CancellationToken cancellationToken)
    {
        try
        {
            if (audio is null || audio.Length < 1)
            {
                return BadRequest(new { message = "Audio file is required." });
            }

            await using var stream = audio.OpenReadStream();
            var result = await assistant.TranscribeVoiceAsync(
                stream,
                audio.FileName,
                audio.ContentType,
                language,
                cancellationToken);
            return Ok(result);
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
