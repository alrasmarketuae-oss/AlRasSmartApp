using System.Collections.Concurrent;
using BusinessLayer.Interfaces.AiAssistant;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services.AiAssistant.Shopping;

public sealed class AiShoppingIdempotencyStore : IAiShoppingIdempotencyStore
{
    private static readonly TimeSpan Ttl = TimeSpan.FromMinutes(30);
    private readonly ConcurrentDictionary<string, Entry> _entries = new(StringComparer.Ordinal);

    public bool TryBegin(string key, out object? existingResult)
    {
        Prune();
        existingResult = null;
        var created = new Entry { StartedAtUtc = DateTime.UtcNow, InFlight = true };
        if (_entries.TryAdd(key, created))
        {
            return true;
        }

        if (_entries.TryGetValue(key, out var existing) && existing.Completed)
        {
            existingResult = existing.Result;
            return false;
        }

        // Another call is in-flight for the same key — treat as duplicate.
        existingResult = new { ok = false, error = "duplicate_in_flight", message = "The same action is already running." };
        return false;
    }

    public void Complete(string key, object result)
    {
        _entries.AddOrUpdate(
            key,
            _ => new Entry
            {
                StartedAtUtc = DateTime.UtcNow,
                Completed = true,
                InFlight = false,
                Result = result
            },
            (_, prev) =>
            {
                prev.Completed = true;
                prev.InFlight = false;
                prev.Result = result;
                prev.CompletedAtUtc = DateTime.UtcNow;
                return prev;
            });
    }

    private void Prune()
    {
        var cutoff = DateTime.UtcNow - Ttl;
        foreach (var pair in _entries)
        {
            var stamp = pair.Value.CompletedAtUtc ?? pair.Value.StartedAtUtc;
            if (stamp < cutoff)
            {
                _entries.TryRemove(pair.Key, out _);
            }
        }
    }

    private sealed class Entry
    {
        public DateTime StartedAtUtc { get; set; }
        public DateTime? CompletedAtUtc { get; set; }
        public bool InFlight { get; set; }
        public bool Completed { get; set; }
        public object? Result { get; set; }
    }
}

public sealed class AiShoppingObservability(ILogger<AiShoppingObservability> logger) : IAiShoppingObservability
{
    public void LogRequestStart(AiShoppingObsContext ctx) =>
        logger.LogInformation(
            "AiShopping start session={SessionId} user={UserIdHash} model={Model} reasoning={Reasoning}",
            ctx.SessionId,
            ctx.UserIdHash,
            ctx.Model,
            ctx.ReasoningEffort);

    public void LogRequestEnd(AiShoppingObsContext ctx, bool success, string? denyOrError = null) =>
        logger.LogInformation(
            "AiShopping end session={SessionId} user={UserIdHash} ok={Ok} responseId={ResponseId} tools={Tools} inTok={In} cachedTok={Cached} outTok={Out} usd={Usd} ms={Ms} error={Error}",
            ctx.SessionId,
            ctx.UserIdHash,
            success,
            ctx.ResponseId,
            ctx.ToolCalls,
            ctx.InputTokens,
            ctx.CachedInputTokens,
            ctx.OutputTokens,
            ctx.EstimatedUsd,
            ctx.DurationMs,
            denyOrError);

    public void LogTool(
        AiShoppingObsContext ctx,
        string toolName,
        bool success,
        double durationMs,
        bool async,
        bool cancelled = false) =>
        logger.LogInformation(
            "AiShopping tool session={SessionId} turn={TurnId} tool={Tool} ok={Ok} async={Async} cancelled={Cancelled} ms={Ms}",
            ctx.SessionId,
            ctx.TurnId,
            toolName,
            success,
            async,
            cancelled,
            durationMs);
}
