using System.Collections.Concurrent;
using BusinessLayer.Interfaces.AiAssistant;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Shopping;

/// <summary>
/// Pre-flight and post-usage cost protection. Not reporting-only.
/// </summary>
public sealed class AiShoppingCostGuard(
    IOptions<AiShoppingAgentOptions> options,
    ILogger<AiShoppingCostGuard> logger) : IAiShoppingCostGuard
{
    private readonly AiShoppingAgentOptions _options = options.Value;
    private readonly ConcurrentDictionary<string, DayBucket> _userDay = new(StringComparer.Ordinal);
    private readonly ConcurrentDictionary<string, int> _sessionCounts = new(StringComparer.Ordinal);
    private DayBucket _globalDay = new(DateOnly.FromDateTime(DateTime.UtcNow));
    private readonly object _globalLock = new();

    public AiShoppingCostDecision TryBeginRequest(Guid? userId, string sessionId, string reasoningEffort)
    {
        var day = DateOnly.FromDateTime(DateTime.UtcNow);
        EnsureGlobalDay(day);

        var sessionKey = NormalizeSession(userId, sessionId);
        var sessionCount = _sessionCounts.AddOrUpdate(sessionKey, 1, (_, n) => n + 1);
        if (sessionCount > _options.MaxAstraRequestsPerSession)
        {
            _sessionCounts.AddOrUpdate(sessionKey, 0, (_, n) => Math.Max(0, n - 1));
            return Deny(
                "session_request_limit",
                "You reached the AI request limit for this chat session. Start a new chat or try later.",
                "وصلت للحد الأقصى لطلبات المساعد في هذه الجلسة. ابدأ محادثة جديدة أو حاول لاحقًا.");
        }

        // Reserve a pessimistic budget (~1k in / 400 out) before calling OpenAI.
        var reserveUsd = EstimateUsd(1_000, 0, 400);
        if (reasoningEffort is "high" or "xhigh" or "max")
        {
            reserveUsd *= 2.5m;
        }

        lock (_globalLock)
        {
            if (_globalDay.Day != day)
            {
                _globalDay = new DayBucket(day);
            }

            if (_globalDay.EstimatedUsd + reserveUsd > _options.MaxEstimatedUsdGlobalPerDay)
            {
                _sessionCounts.AddOrUpdate(sessionKey, 0, (_, n) => Math.Max(0, n - 1));
                logger.LogWarning("AiShopping global daily cost limit reached day={Day}", day);
                return Deny(
                    "global_cost_limit",
                    "AI shopping is temporarily unavailable due to usage limits. Please try later.",
                    "مساعد التسوق غير متاح مؤقتًا بسبب حدود الاستخدام. حاول لاحقًا.");
            }
        }

        if (userId is Guid uid)
        {
            var userKey = $"{day:yyyyMMdd}:{uid:D}";
            var bucket = _userDay.GetOrAdd(userKey, _ => new DayBucket(day));
            lock (bucket.Gate)
            {
                if (bucket.EstimatedUsd + reserveUsd > _options.MaxEstimatedUsdPerUserPerDay)
                {
                    _sessionCounts.AddOrUpdate(sessionKey, 0, (_, n) => Math.Max(0, n - 1));
                    return Deny(
                        "user_cost_limit",
                        "You reached today's AI usage limit. Please try again tomorrow.",
                        "وصلت لحد استخدام المساعد اليوم. حاول مرة أخرى غدًا.");
                }

                // Soft-reserve so concurrent requests cannot all pass the gate.
                bucket.EstimatedUsd += reserveUsd;
                bucket.ReservedUsd += reserveUsd;
            }
        }

        return new AiShoppingCostDecision(true, null, null, null);
    }

    public void RecordUsage(
        Guid? userId,
        string sessionId,
        int inputTokens,
        int cachedInputTokens,
        int outputTokens,
        string reasoningEffort)
    {
        var actual = EstimateUsd(inputTokens, cachedInputTokens, outputTokens);
        var day = DateOnly.FromDateTime(DateTime.UtcNow);
        EnsureGlobalDay(day);

        lock (_globalLock)
        {
            _globalDay.EstimatedUsd += actual;
            _globalDay.Requests++;
        }

        if (userId is not Guid uid)
        {
            return;
        }

        var reserveUsd = EstimateUsd(1_000, 0, 400);
        if (reasoningEffort is "high" or "xhigh" or "max")
        {
            reserveUsd *= 2.5m;
        }

        var userKey = $"{day:yyyyMMdd}:{uid:D}";
        var bucket = _userDay.GetOrAdd(userKey, _ => new DayBucket(day));
        lock (bucket.Gate)
        {
            bucket.EstimatedUsd = Math.Max(0, bucket.EstimatedUsd - bucket.ReservedUsd) + actual;
            bucket.ReservedUsd = Math.Max(0, bucket.ReservedUsd - reserveUsd);
            bucket.Requests++;
        }
    }

    public decimal EstimateUsd(int inputTokens, int cachedInputTokens, int outputTokens)
    {
        var billableInput = Math.Max(0, inputTokens - cachedInputTokens);
        var inputCost = billableInput / 1_000_000m * _options.EstimatedInputUsdPerMTok;
        var cachedCost = Math.Max(0, cachedInputTokens) / 1_000_000m * _options.EstimatedCachedInputUsdPerMTok;
        var outputCost = Math.Max(0, outputTokens) / 1_000_000m * _options.EstimatedOutputUsdPerMTok;
        return Math.Round(inputCost + cachedCost + outputCost, 6);
    }

    private void EnsureGlobalDay(DateOnly day)
    {
        lock (_globalLock)
        {
            if (_globalDay.Day != day)
            {
                _globalDay = new DayBucket(day);
            }
        }
    }

    private static string NormalizeSession(Guid? userId, string sessionId) =>
        $"{userId?.ToString("D") ?? "anon"}|{sessionId.Trim()}";

    private static AiShoppingCostDecision Deny(string code, string en, string ar) =>
        new(false, code, en, ar);

    private sealed class DayBucket(DateOnly day)
    {
        public DateOnly Day { get; } = day;
        public decimal EstimatedUsd { get; set; }
        public decimal ReservedUsd { get; set; }
        public int Requests { get; set; }
        public object Gate { get; } = new();
    }
}
