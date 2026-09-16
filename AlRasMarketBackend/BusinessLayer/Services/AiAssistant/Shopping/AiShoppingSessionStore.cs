using System.Collections.Concurrent;
using BusinessLayer.Interfaces.AiAssistant;

namespace BusinessLayer.Services.AiAssistant.Shopping;

public sealed class AiShoppingSessionStore : IAiShoppingSessionStore
{
    private static readonly TimeSpan Ttl = TimeSpan.FromHours(2);
    private readonly ConcurrentDictionary<string, AiShoppingSessionState> _sessions = new(StringComparer.Ordinal);

    public AiShoppingSessionState GetOrCreate(Guid? userId, string clientSessionId)
    {
        Prune();
        var key = BuildKey(userId, clientSessionId);
        return _sessions.GetOrAdd(key, _ => new AiShoppingSessionState
        {
            SessionKey = key,
            UserId = userId,
            ClientSessionId = clientSessionId.Trim(),
            UpdatedAtUtc = DateTime.UtcNow
        });
    }

    public void Reset(Guid? userId, string clientSessionId)
    {
        var key = BuildKey(userId, clientSessionId);
        if (_sessions.TryRemove(key, out var state))
        {
            try
            {
                state.ActiveTurnCts?.Cancel();
                state.ActiveTurnCts?.Dispose();
            }
            catch
            {
                // ignore
            }
        }
    }

    public void CancelActiveTurn(Guid? userId, string clientSessionId, string reason)
    {
        var state = GetOrCreate(userId, clientSessionId);
        try
        {
            state.ActiveTurnCts?.Cancel();
        }
        catch
        {
            // ignore
        }

        state.ActiveTurnId = null;
        state.UpdatedAtUtc = DateTime.UtcNow;
        _ = reason;
    }

    private void Prune()
    {
        var cutoff = DateTime.UtcNow - Ttl;
        foreach (var pair in _sessions)
        {
            if (pair.Value.UpdatedAtUtc < cutoff)
            {
                _sessions.TryRemove(pair.Key, out _);
            }
        }
    }

    public static string BuildKey(Guid? userId, string clientSessionId) =>
        $"{userId?.ToString("D") ?? "anon"}|s:{(clientSessionId ?? string.Empty).Trim()}";
}
