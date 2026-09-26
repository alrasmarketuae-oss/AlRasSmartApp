using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using RasAlSouqPresentaionLayer.Services;

namespace RasAlSouqPresentaionLayer.Controllers;

[Route("api/nasser-portfolio")]
[ApiController]
[AllowAnonymous]
public class NasserPortfolioController(
    INasserPortfolioAppService nasserPortfolioAppService,
    NasserImageQuota imageQuota,
    INasserPortfolioStore store,
    NasserGeoLocator geoLocator,
    ILogger<NasserPortfolioController> logger) : ControllerBase
{
    private static readonly Regex PhonePattern = new(@"\+?\d[\d\s\-()]{7,18}\d", RegexOptions.Compiled);
    private static readonly Regex ConversationIdPattern = new(@"^[A-Za-z0-9\-]{8,64}$", RegexOptions.Compiled);

    private static readonly JsonSerializerOptions Json = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public sealed class LeadBody
    {
        public string Phone { get; set; } = string.Empty;
        public string? Name { get; set; }
        public string? Locale { get; set; }
        public string? Source { get; set; }
        public string? ConversationId { get; set; }
    }

    [HttpPost("leads")]
    public async Task<IActionResult> SubmitLead(
        [FromBody] LeadBody body,
        CancellationToken cancellationToken)
    {
        try
        {
            await nasserPortfolioAppService.SubmitLeadAsync(
                new NasserPortfolioLeadInput
                {
                    Phone = body.Phone,
                    Name = body.Name,
                    Locale = body.Locale,
                    Source = body.Source
                },
                cancellationToken);
            var visitor = await ResolveVisitorAsync(CancellationToken.None);
            await store.RecordLeadAsync(
                new NasserLeadRecord
                {
                    Phone = body.Phone.Trim(),
                    Name = body.Name,
                    Source = body.Source,
                    Locale = body.Locale,
                    Ip = visitor.Ip,
                    Country = visitor.Country,
                    UserAgent = visitor.UserAgent,
                    ConversationId = SafeConversationId(body.ConversationId)
                },
                CancellationToken.None);
            return Ok(new { ok = true });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = ex.Message });
        }
    }

    [HttpGet("ai/quota")]
    public IActionResult Quota() =>
        Ok(new { imagesLeft = imageQuota.Remaining(HttpContext), limit = NasserImageQuota.Limit });

    /// <summary>
    /// Streams the reply as NDJSON events: meta, image (optional), delta*, done | error.
    /// </summary>
    [HttpPost("ai/chat")]
    [RequestSizeLimit(20 * 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = 20 * 1024 * 1024)]
    public async Task Chat(CancellationToken cancellationToken)
    {
        NasserPortfolioPreparedChat chat;
        string? conversationId;
        try
        {
            var form = await Request.ReadFormAsync(cancellationToken);
            conversationId = SafeConversationId(form["conversationId"].ToString())
                             ?? Guid.NewGuid().ToString("N");
            chat = await nasserPortfolioAppService.PrepareChatAsync(
                new NasserPortfolioChatInput
                {
                    Message = form["message"].ToString(),
                    Locale = form["locale"].ToString(),
                    Image = form.Files.GetFile("image"),
                    History = ParseHistory(form["history"].ToString())
                },
                cancellationToken);
        }
        catch (Exception ex) when (ex is ArgumentException or InvalidOperationException)
        {
            Response.StatusCode = ex is ArgumentException
                ? StatusCodes.Status400BadRequest
                : StatusCodes.Status503ServiceUnavailable;
            await Response.WriteAsJsonAsync(new { message = ex.Message }, cancellationToken);
            return;
        }

        var visitor = await ResolveVisitorAsync(cancellationToken);
        chat.Country = visitor.Country;

        var remaining = imageQuota.Remaining(HttpContext);
        var imageLimitReached = chat.ImageRequested && remaining == 0;
        var willGenerate = chat.ImageRequested && !imageLimitReached;

        Response.ContentType = "application/x-ndjson; charset=utf-8";
        Response.Headers.CacheControl = "no-cache";
        Response.Headers["X-Accel-Buffering"] = "no";
        HttpContext.Features.Get<IHttpResponseBodyFeature>()?.DisableBuffering();

        // Flush meta immediately so the client can show the skeleton while OpenAI works
        await WriteEventAsync(
            new { type = "meta", imagesLeft = remaining, imageLimitReached, generatingImage = willGenerate },
            cancellationToken);

        byte[]? image = null;
        if (willGenerate)
        {
            image = await nasserPortfolioAppService.CreateImageAsync(chat, cancellationToken);
            if (image is not null)
            {
                remaining = imageQuota.Consume(HttpContext);
                await WriteEventAsync(
                    new { type = "meta", imagesLeft = remaining, imageLimitReached = false, generatingImage = false },
                    cancellationToken);
                await WriteEventAsync(
                    new { type = "image", base64 = Convert.ToBase64String(image), contentType = "image/jpeg" },
                    cancellationToken);
            }
            else
            {
                await WriteEventAsync(
                    new { type = "meta", imagesLeft = remaining, imageLimitReached = false, generatingImage = false },
                    cancellationToken);
            }
        }

        var reply = new StringBuilder();
        try
        {
            await foreach (var delta in nasserPortfolioAppService
                               .StreamReplyAsync(chat, imageLimitReached, image is not null, cancellationToken)
                               .WithCancellation(cancellationToken))
            {
                reply.Append(delta);
                await WriteEventAsync(new { type = "delta", text = delta }, cancellationToken);
            }

            await WriteEventAsync(new { type = "done" }, cancellationToken);
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Nasser portfolio chat stream failed.");
            await WriteEventAsync(new { type = "error" }, CancellationToken.None);
        }
        finally
        {
            if (conversationId is not null)
            {
                await store.RecordExchangeAsync(
                    new NasserExchangeRecord
                    {
                        ConversationId = conversationId,
                        Locale = chat.Locale,
                        Visitor = visitor,
                        UserText = chat.Message,
                        UserImageJpeg = chat.CompressedJpeg,
                        AssistantText = reply.ToString(),
                        AssistantImagePng = image,
                        Phone = PhonePattern.Match(chat.Message) is { Success: true } m ? m.Value.Trim() : null
                    },
                    CancellationToken.None);
            }
        }
    }

    private async Task<NasserVisitor> ResolveVisitorAsync(CancellationToken cancellationToken)
    {
        var visitor = NasserVisitorInfo.Visitor(HttpContext);
        return visitor.Country is not null
            ? visitor
            : visitor with { Country = await geoLocator.CountryAsync(visitor.Ip, cancellationToken) };
    }

    private static string? SafeConversationId(string? raw) =>
        !string.IsNullOrWhiteSpace(raw) && ConversationIdPattern.IsMatch(raw) ? raw : null;

    private async Task WriteEventAsync(object payload, CancellationToken cancellationToken)
    {
        await Response.WriteAsync(JsonSerializer.Serialize(payload, Json) + "\n", cancellationToken);
        await Response.Body.FlushAsync(cancellationToken);
    }

    private static IReadOnlyList<NasserPortfolioChatTurn> ParseHistory(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return [];
        }

        try
        {
            return JsonSerializer.Deserialize<List<NasserPortfolioChatTurn>>(raw, Json) ?? [];
        }
        catch (JsonException)
        {
            return [];
        }
    }
}
