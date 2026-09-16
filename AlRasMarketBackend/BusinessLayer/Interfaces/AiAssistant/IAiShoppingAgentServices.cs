using BusinessLayer.Interfaces;

namespace BusinessLayer.Interfaces.AiAssistant;

public interface IAiShoppingAccessGate
{
    bool IsGloballyEnabled();
    bool IsAllowed(Guid? userId, Guid? companyId = null);
    bool ShouldRouteToShoppingAgent(Guid? userId, string message, Guid? companyId = null);
}

public interface IAiShoppingCostGuard
{
    AiShoppingCostDecision TryBeginRequest(Guid? userId, string sessionId, string reasoningEffort);
    void RecordUsage(
        Guid? userId,
        string sessionId,
        int inputTokens,
        int cachedInputTokens,
        int outputTokens,
        string reasoningEffort);
    decimal EstimateUsd(int inputTokens, int cachedInputTokens, int outputTokens);
}

public sealed record AiShoppingCostDecision(
    bool Allowed,
    string? DenyReasonCode,
    string? DenyMessageEn,
    string? DenyMessageAr);

public interface IAiShoppingSessionStore
{
    AiShoppingSessionState GetOrCreate(Guid? userId, string clientSessionId);
    void Reset(Guid? userId, string clientSessionId);
    void CancelActiveTurn(Guid? userId, string clientSessionId, string reason);
}

public sealed class AiShoppingSessionState
{
    public string SessionKey { get; init; } = "";
    public Guid? UserId { get; init; }
    public string ClientSessionId { get; init; } = "";
    public string? PreviousResponseId { get; set; }
    public string? ActiveTurnId { get; set; }
    public int AstraRequestCount { get; set; }
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    public CancellationTokenSource? ActiveTurnCts { get; set; }
}

public interface IAiShoppingIdempotencyStore
{
    bool TryBegin(string key, out object? existingResult);
    void Complete(string key, object result);
}

public interface IAiAsyncToolJobRegistry
{
    Task<string> StartAsync(
        string sessionKey,
        string turnId,
        string callId,
        string toolName,
        Func<CancellationToken, Task<string>> work,
        CancellationToken linkedToken);

    void CancelTurn(string sessionKey, string turnId, string reason);
    void CancelSession(string sessionKey, string reason);
    int ActiveJobCount(string sessionKey);
}

public interface IAiResponsesApiClient
{
    Task<AiResponsesCreateResult> CreateAsync(
        AiResponsesCreateRequest request,
        CancellationToken cancellationToken);
}

public sealed class AiResponsesCreateRequest
{
    public required string Model { get; init; }
    public required string Instructions { get; init; }
    public required object Input { get; init; }
    public required IReadOnlyList<object> Tools { get; init; }
    public string ReasoningEffort { get; init; } = "low";
    public string? PreviousResponseId { get; init; }
    public string? PromptCacheKey { get; init; }
    public int MaxOutputTokens { get; init; } = 700;
    public bool Store { get; init; } = true;
}

public sealed class AiResponsesCreateResult
{
    public bool Ok { get; init; }
    public string? ResponseId { get; init; }
    public string? Status { get; init; }
    public string? AssistantText { get; init; }
    public IReadOnlyList<AiResponsesFunctionCall> FunctionCalls { get; init; } = [];
    public int InputTokens { get; init; }
    public int CachedInputTokens { get; init; }
    public int OutputTokens { get; init; }
    public string? ErrorMessage { get; init; }
    public string? RawJson { get; init; }
}

public sealed class AiResponsesFunctionCall
{
    public required string CallId { get; init; }
    public required string Name { get; init; }
    public required string ArgumentsJson { get; init; }
    public bool Async { get; init; }
}

public interface IAiShoppingToolsService
{
    IReadOnlyList<object> GetToolDefinitions(bool enableAsyncTools);
    Task<AiShoppingToolExecutionResult> ExecuteAsync(
        Guid userId,
        string sessionKey,
        string turnId,
        string callId,
        string toolName,
        string argumentsJson,
        bool asyncPreferred,
        CancellationToken cancellationToken);
}

public sealed class AiShoppingToolExecutionResult
{
    public bool Ok { get; init; }
    public string PayloadJson { get; init; } = "{}";
    public bool StartedAsync { get; init; }
    public string? ErrorCode { get; init; }
    public IReadOnlyList<AiProductListingDto>? Listings { get; init; }
}

public interface IAiShoppingAgentService
{
    Task<AiAssistantAnswer> AskAsync(
        Guid? userId,
        string clientSessionId,
        AiAssistantAskRequest request,
        Func<string, CancellationToken, Task>? onThinkingStep,
        CancellationToken cancellationToken);
}

public interface IAiShoppingObservability
{
    void LogRequestStart(AiShoppingObsContext ctx);
    void LogRequestEnd(AiShoppingObsContext ctx, bool success, string? denyOrError = null);
    void LogTool(
        AiShoppingObsContext ctx,
        string toolName,
        bool success,
        double durationMs,
        bool async,
        bool cancelled = false);
}

public sealed class AiShoppingObsContext
{
    public string SessionId { get; init; } = "";
    public string? UserIdHash { get; init; }
    public string? TurnId { get; set; }
    public string? ResponseId { get; set; }
    public string Model { get; set; } = "";
    public string ReasoningEffort { get; set; } = "low";
    public int InputTokens { get; set; }
    public int CachedInputTokens { get; set; }
    public int OutputTokens { get; set; }
    public decimal EstimatedUsd { get; set; }
    public double DurationMs { get; set; }
    public int ToolCalls { get; set; }
}
