using System.Collections.Concurrent;
using BusinessLayer.Interfaces.AiAssistant;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Shopping;

public sealed class AiAsyncToolJobRegistry(
    IOptions<AiShoppingAgentOptions> options,
    ILogger<AiAsyncToolJobRegistry> logger) : IAiAsyncToolJobRegistry
{
    private readonly AiShoppingAgentOptions _options = options.Value;
    private readonly ConcurrentDictionary<string, Job> _jobs = new(StringComparer.Ordinal);

    public async Task<string> StartAsync(
        string sessionKey,
        string turnId,
        string callId,
        string toolName,
        Func<CancellationToken, Task<string>> work,
        CancellationToken linkedToken)
    {
        if (ActiveJobCount(sessionKey) >= _options.MaxAsyncJobs)
        {
            return """{"ok":false,"error":"async_job_limit","message":"Too many background searches. Try again shortly."}""";
        }

        var cts = CancellationTokenSource.CreateLinkedTokenSource(linkedToken);
        if (_options.ToolTimeoutSeconds > 0)
        {
            cts.CancelAfter(TimeSpan.FromSeconds(_options.ToolTimeoutSeconds));
        }

        var job = new Job
        {
            SessionKey = sessionKey,
            TurnId = turnId,
            CallId = callId,
            ToolName = toolName,
            Cts = cts,
            StartedAtUtc = DateTime.UtcNow
        };

        var key = JobKey(sessionKey, callId);
        if (!_jobs.TryAdd(key, job))
        {
            cts.Dispose();
            return """{"ok":false,"error":"duplicate_call_id","message":"Tool call already registered."}""";
        }

        _ = Task.Run(async () =>
        {
            try
            {
                var json = await work(cts.Token).ConfigureAwait(false);
                job.ResultJson = json;
                job.Completed = true;
                job.Success = true;
            }
            catch (OperationCanceledException)
            {
                job.Completed = true;
                job.Cancelled = true;
                job.ResultJson =
                    """{"ok":false,"error":"cancelled","message":"The search was cancelled."}""";
                logger.LogInformation(
                    "AiShopping async job cancelled session={Session} turn={Turn} tool={Tool} callId={CallId}",
                    sessionKey,
                    turnId,
                    toolName,
                    callId);
            }
            catch (Exception ex)
            {
                job.Completed = true;
                job.Success = false;
                job.ResultJson =
                    """{"ok":false,"error":"tool_failed","message":"The operation failed. Please try again."}""";
                logger.LogWarning(
                    ex,
                    "AiShopping async job failed session={Session} tool={Tool} callId={CallId}",
                    sessionKey,
                    toolName,
                    callId);
            }
            finally
            {
                job.CompletedAtUtc = DateTime.UtcNow;
                try
                {
                    cts.Dispose();
                }
                catch
                {
                    // ignore
                }
            }
        }, CancellationToken.None);

        // For phase 1–4 we still await completion inside the turn (async flag on schema
        // prepares for true mid-turn continuation; registry already supports cancel).
        while (!job.Completed)
        {
            if (linkedToken.IsCancellationRequested)
            {
                CancelTurn(sessionKey, turnId, "parent_cancelled");
                break;
            }

            await Task.Delay(40, CancellationToken.None).ConfigureAwait(false);
        }

        _jobs.TryRemove(key, out _);
        return job.ResultJson ?? """{"ok":false,"error":"empty"}""";
    }

    public void CancelTurn(string sessionKey, string turnId, string reason)
    {
        foreach (var pair in _jobs)
        {
            var job = pair.Value;
            if (!string.Equals(job.SessionKey, sessionKey, StringComparison.Ordinal)
                || !string.Equals(job.TurnId, turnId, StringComparison.Ordinal))
            {
                continue;
            }

            try
            {
                job.Cts.Cancel();
            }
            catch
            {
                // ignore
            }

            logger.LogInformation(
                "AiShopping cancel turn session={Session} turn={Turn} callId={CallId} reason={Reason}",
                sessionKey,
                turnId,
                job.CallId,
                reason);
        }
    }

    public void CancelSession(string sessionKey, string reason)
    {
        foreach (var pair in _jobs)
        {
            if (!string.Equals(pair.Value.SessionKey, sessionKey, StringComparison.Ordinal))
            {
                continue;
            }

            try
            {
                pair.Value.Cts.Cancel();
            }
            catch
            {
                // ignore
            }
        }

        logger.LogInformation("AiShopping cancel session={Session} reason={Reason}", sessionKey, reason);
    }

    public int ActiveJobCount(string sessionKey) =>
        _jobs.Count(x =>
            string.Equals(x.Value.SessionKey, sessionKey, StringComparison.Ordinal) && !x.Value.Completed);

    private static string JobKey(string sessionKey, string callId) => $"{sessionKey}|{callId}";

    private sealed class Job
    {
        public required string SessionKey { get; init; }
        public required string TurnId { get; init; }
        public required string CallId { get; init; }
        public required string ToolName { get; init; }
        public required CancellationTokenSource Cts { get; init; }
        public DateTime StartedAtUtc { get; init; }
        public DateTime? CompletedAtUtc { get; set; }
        public bool Completed { get; set; }
        public bool Success { get; set; }
        public bool Cancelled { get; set; }
        public string? ResultJson { get; set; }
    }
}
