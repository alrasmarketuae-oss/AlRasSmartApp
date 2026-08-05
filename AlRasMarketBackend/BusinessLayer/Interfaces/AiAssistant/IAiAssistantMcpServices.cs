namespace BusinessLayer.Interfaces;

public sealed record AiToolCall(string Id, string Name, string ArgumentsJson);

public sealed record AiToolResult(string CallId, string Name, string Content);

/// <summary>
/// MCP-style tools the in-app AI assistant can call (price/qty, cheapest product, sales).
/// </summary>
public interface IAiAssistantToolsService
{
    IReadOnlyList<object> GetToolDefinitions();

    Task<AiToolResult> ExecuteAsync(
        Guid? userId,
        AiToolCall call,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Compact catalog of the seller's ad names for the chat system prompt.
    /// </summary>
    Task<string?> BuildSellerAdsCatalogAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// OpenAI chat loop that executes MCP tool_calls via <see cref="IAiAssistantToolsService"/>.
/// </summary>
public interface IAiAssistantMcpToolLoop
{
    Task<string> CompleteWithToolsAsync(
        HttpClient httpClient,
        string apiKey,
        string chatModel,
        IList<object> messages,
        Guid? userId,
        string responseLanguage = "en",
        Func<string, CancellationToken, Task>? onThinkingStep = null,
        CancellationToken cancellationToken = default);
}
