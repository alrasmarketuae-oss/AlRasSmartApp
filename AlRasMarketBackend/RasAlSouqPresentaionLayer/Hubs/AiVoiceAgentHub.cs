using System.Security.Claims;
using BusinessLayer.Options;
using BusinessLayer.Services.AiAssistant.Voice;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Options;

namespace RasAlSouqPresentaionLayer.Hubs;

/// <summary>
/// Flutter streams PCM16 audio here. The server holds the OpenAI Realtime WebSocket
/// so the app never receives a permanent API key.
/// </summary>
[AllowAnonymous]
public sealed class AiVoiceAgentHub(
    AiVoiceAgentSessionManager sessions,
    IOptions<AiVoiceAgentOptions> options,
    ILogger<AiVoiceAgentHub> logger) : Hub
{
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        if (exception is not null)
        {
            logger.LogWarning(
                exception,
                "Voice hub disconnected connectionId={ConnectionId}",
                Context.ConnectionId);
        }
        else
        {
            logger.LogInformation(
                "Voice hub disconnected connectionId={ConnectionId}",
                Context.ConnectionId);
        }

        try
        {
            await sessions.StopAsync(Context.ConnectionId).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice hub stop session failed connectionId={ConnectionId}", Context.ConnectionId);
        }

        await base.OnDisconnectedAsync(exception).ConfigureAwait(false);
    }

    public async Task StartSession(string language, string? voiceGender)
    {
        if (!options.Value.Enabled)
        {
            await Clients.Caller.SendAsync(
                "voiceError",
                new { message = "Voice agent is disabled." },
                Context.ConnectionAborted);
            return;
        }

        try
        {
            var connectionId = Context.ConnectionId;
            var caller = Clients.Caller;
            await sessions.StartAsync(
                connectionId,
                GetCurrentUserId(),
                language,
                voiceGender,
                async (eventName, payload, ct) =>
                {
                    try
                    {
                        await caller.SendAsync(eventName, payload, ct).ConfigureAwait(false);
                    }
                    catch (OperationCanceledException)
                    {
                        // client left
                    }
                    catch (Exception sendEx)
                    {
                        logger.LogWarning(
                            sendEx,
                            "Voice hub client send failed connectionId={ConnectionId} event={Event}",
                            connectionId,
                            eventName);
                    }
                },
                Context.ConnectionAborted).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // client left
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice StartSession failed connectionId={ConnectionId}", Context.ConnectionId);
            await Clients.Caller.SendAsync(
                "voiceError",
                new { message = "مقدرناش نفتح الجلسة الصوتية دلوقتي. حاول تاني." },
                CancellationToken.None);
        }
    }

    public async Task SendAudioChunk(string pcmBase64)
    {
        if (string.IsNullOrWhiteSpace(pcmBase64) || pcmBase64.Length > 200_000)
        {
            return;
        }

        if (!sessions.TryGet(Context.ConnectionId, out var session))
        {
            return;
        }

        try
        {
            await session.SendAudioBase64Async(pcmBase64, Context.ConnectionAborted).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // ignore
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice SendAudioChunk failed connectionId={ConnectionId}", Context.ConnectionId);
        }
    }

    public async Task InterruptAgent()
    {
        if (!sessions.TryGet(Context.ConnectionId, out var session))
        {
            return;
        }

        try
        {
            await session.InterruptAsync(Context.ConnectionAborted).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // ignore
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice InterruptAgent failed connectionId={ConnectionId}", Context.ConnectionId);
        }
    }

    public async Task StopSession()
    {
        try
        {
            await sessions.StopAsync(Context.ConnectionId).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice StopSession failed connectionId={ConnectionId}", Context.ConnectionId);
        }
    }

    private Guid? GetCurrentUserId()
    {
        var raw = Context.User?.FindFirst("EntityId")?.Value
            ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? Context.User?.FindFirst("sub")?.Value;
        return Guid.TryParse(raw, out var userId) ? userId : null;
    }
}
