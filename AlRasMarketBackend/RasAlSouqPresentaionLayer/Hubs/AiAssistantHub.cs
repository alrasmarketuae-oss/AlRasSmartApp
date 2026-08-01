using System.Collections.Concurrent;
using System.Globalization;
using System.Security.Claims;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace RasAlSouqPresentaionLayer.Hubs;

/// <summary>
/// Dedicated short-lived AI session. History is keyed by a client session id so
/// it survives SignalR auto-reconnects, and expires so chat context does not leak.
/// </summary>
public sealed class AiAssistantHub(IAiAssistantAppService assistant) : Hub
{
    private const int MaxHistoryMessages = 8;
    private const int MaxRequestsPerMinute = 12;
    private static readonly TimeSpan SessionLifetime = TimeSpan.FromMinutes(30);
    private static readonly ConcurrentDictionary<string, SessionState> Sessions = new();

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        PruneExpiredSessions();
        await base.OnDisconnectedAsync(exception);
    }

    public Task Ask(string message, string language) => AskInSession(message, language, null);

    public async Task AskInSession(string message, string language, string? sessionId)
    {
        var text = (message ?? string.Empty).Trim();
        if (text.Length is < 1 or > 2000)
        {
            await Clients.Caller.SendAsync(
                "aiError",
                new { message = "Message must be between 1 and 2000 characters." },
                Context.ConnectionAborted);
            return;
        }

        var session = Sessions.GetOrAdd(ResolveSessionKey(sessionId), _ => new SessionState());
        if (!session.TryConsumeRequest())
        {
            await Clients.Caller.SendAsync(
                "aiError",
                new { message = "Too many requests. Please wait a minute." },
                Context.ConnectionAborted);
            return;
        }

        await Clients.Caller.SendAsync(
            "aiThinking",
            new { isThinking = true },
            Context.ConnectionAborted);

        try
        {
            var result = await assistant.AskAsync(
                GetCurrentUserId(),
                new AiAssistantAskRequest { Message = text, Language = language },
                session.Snapshot(),
                Context.ConnectionAborted);

            session.Add("user", text);
            session.Add("assistant", result.Answer);

            await Clients.Caller.SendAsync(
                "aiResponseStarted",
                new { language = result.Language },
                Context.ConnectionAborted);

            foreach (var chunk in SplitTextElements(result.Answer, 4))
            {
                await Clients.Caller.SendAsync(
                    "aiDelta",
                    new { text = chunk },
                    Context.ConnectionAborted);
                await Task.Delay(8, Context.ConnectionAborted);
            }

            await Clients.Caller.SendAsync(
                "aiResponseCompleted",
                new
                {
                    answer = result.Answer,
                    result.Language,
                    result.UsedKnowledge,
                    result.Sources
                },
                Context.ConnectionAborted);
        }
        catch (OperationCanceledException)
        {
            // Client closed the AI screen; OnDisconnected clears the session.
        }
        catch
        {
            await Clients.Caller.SendAsync(
                "aiError",
                new { message = "AI Assistant is unavailable right now." },
                CancellationToken.None);
        }
        finally
        {
            if (!Context.ConnectionAborted.IsCancellationRequested)
            {
                await Clients.Caller.SendAsync(
                    "aiThinking",
                    new { isThinking = false },
                    Context.ConnectionAborted);
            }
        }
    }

    public Task ClearSession() => ClearSessionById(null);

    public Task ClearSessionById(string? sessionId)
    {
        Sessions.TryRemove(ResolveSessionKey(sessionId), out _);
        PruneExpiredSessions();
        return Task.CompletedTask;
    }

    /// <summary>
    /// A client-supplied id keeps history across auto-reconnects, which assign a
    /// new ConnectionId. It is namespaced per user so ids cannot be guessed across accounts.
    /// </summary>
    private string ResolveSessionKey(string? sessionId)
    {
        var owner = GetCurrentUserId()?.ToString() ?? $"anon:{Context.ConnectionId}";
        var clean = (sessionId ?? string.Empty).Trim();
        if (clean.Length is 0 or > 64) return $"{owner}|conn:{Context.ConnectionId}";
        return $"{owner}|s:{clean}";
    }

    private static void PruneExpiredSessions()
    {
        var cutoff = DateTime.UtcNow - SessionLifetime;
        foreach (var entry in Sessions)
        {
            if (entry.Value.LastUsedUtc < cutoff)
            {
                Sessions.TryRemove(entry.Key, out _);
            }
        }
    }

    private Guid? GetCurrentUserId()
    {
        var raw = Context.User?.FindFirst("EntityId")?.Value
            ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? Context.User?.FindFirst("sub")?.Value;
        return Guid.TryParse(raw, out var userId) ? userId : null;
    }

    private static IEnumerable<string> SplitTextElements(string value, int size)
    {
        var elements = new List<string>();
        var enumerator = StringInfo.GetTextElementEnumerator(value);
        while (enumerator.MoveNext())
        {
            elements.Add(enumerator.GetTextElement());
            if (elements.Count == size)
            {
                yield return string.Concat(elements);
                elements.Clear();
            }
        }

        if (elements.Count > 0)
        {
            yield return string.Concat(elements);
        }
    }

    private sealed class SessionState
    {
        private readonly object _lock = new();
        private readonly Queue<AiAssistantHistoryMessage> _history = new();
        private readonly Queue<DateTime> _requestTimes = new();

        public DateTime LastUsedUtc { get; private set; } = DateTime.UtcNow;

        public void Add(string role, string content)
        {
            lock (_lock)
            {
                LastUsedUtc = DateTime.UtcNow;
                _history.Enqueue(new AiAssistantHistoryMessage(role, content));
                while (_history.Count > MaxHistoryMessages)
                {
                    _history.Dequeue();
                }
            }
        }

        public IReadOnlyList<AiAssistantHistoryMessage> Snapshot()
        {
            lock (_lock)
            {
                return _history.ToList();
            }
        }

        public bool TryConsumeRequest()
        {
            lock (_lock)
            {
                LastUsedUtc = DateTime.UtcNow;
                var cutoff = DateTime.UtcNow.AddMinutes(-1);
                while (_requestTimes.TryPeek(out var oldest) && oldest < cutoff)
                {
                    _requestTimes.Dequeue();
                }

                if (_requestTimes.Count >= MaxRequestsPerMinute)
                {
                    return false;
                }

                _requestTimes.Enqueue(DateTime.UtcNow);
                return true;
            }
        }
    }
}
