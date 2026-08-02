using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services.AiAssistant.Mcp;

/// <summary>
/// Runs OpenAI chat completions with MCP-style tool_calls until the model
/// returns a final text answer (or the round limit is hit).
/// </summary>
public sealed class AiAssistantMcpToolLoop(
    IAiAssistantToolsService toolsService,
    ILogger<AiAssistantMcpToolLoop> logger) : IAiAssistantMcpToolLoop
{
    private const int MaxToolRounds = 3;
    /// <summary>
    /// Hard cap: never apply more than one successful mutating account action
    /// per user turn (price/qty, pause/active, sold-out, delete, or withdrawal).
    /// </summary>
    private const int MaxSuccessfulMutationsPerTurn = 1;

    private static readonly HashSet<string> MutatingToolNames = new(StringComparer.Ordinal)
    {
        "update_ad_price_quantity",
        "set_ad_listing_status",
        "mark_ad_sold_out",
        "delete_ad",
        "create_withdrawal"
    };

    public async Task<string> CompleteWithToolsAsync(
        HttpClient httpClient,
        string apiKey,
        string chatModel,
        IList<object> messages,
        Guid? userId,
        CancellationToken cancellationToken = default)
    {
        var tools = toolsService.GetToolDefinitions();
        var successfulMutations = 0;

        for (var round = 0; round < MaxToolRounds; round++)
        {
            using var httpRequest = new HttpRequestMessage(
                HttpMethod.Post,
                "https://api.openai.com/v1/chat/completions");
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new Dictionary<string, object?>
            {
                ["model"] = chatModel,
                ["temperature"] = 0.1,
                ["max_tokens"] = 700,
                ["messages"] = messages,
                ["tools"] = tools,
                ["tool_choice"] = "auto"
            };

            httpRequest.Content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json");

            using var response = await httpClient.SendAsync(httpRequest, cancellationToken)
                .ConfigureAwait(false);
            var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException(
                    $"OpenAI assistant failed ({(int)response.StatusCode}): {json}");
            }

            using var doc = JsonDocument.Parse(json);
            var choice = doc.RootElement.GetProperty("choices")[0];
            var msg = choice.GetProperty("message");
            var finishReason = choice.TryGetProperty("finish_reason", out var fr)
                ? fr.GetString()
                : null;

            if (finishReason == "tool_calls" &&
                msg.TryGetProperty("tool_calls", out var toolCalls) &&
                toolCalls.ValueKind == JsonValueKind.Array &&
                toolCalls.GetArrayLength() > 0)
            {
                // Echo the assistant tool_calls message, then append each tool result.
                messages.Add(JsonSerializer.Deserialize<object>(msg.GetRawText())!);

                foreach (var tc in toolCalls.EnumerateArray())
                {
                    var id = tc.GetProperty("id").GetString() ?? Guid.NewGuid().ToString("N");
                    var fn = tc.GetProperty("function");
                    var name = fn.GetProperty("name").GetString() ?? "";
                    var args = fn.TryGetProperty("arguments", out var a)
                        ? a.GetString() ?? "{}"
                        : "{}";

                    if (MutatingToolNames.Contains(name)
                        && successfulMutations >= MaxSuccessfulMutationsPerTurn)
                    {
                        logger.LogWarning(
                            "Blocked mutating tool {Tool} for user {UserId}; already applied {Count} mutation(s) this turn.",
                            name,
                            userId,
                            successfulMutations);
                        messages.Add(new
                        {
                            role = "tool",
                            tool_call_id = id,
                            content = JsonSerializer.Serialize(new
                            {
                                ok = false,
                                blocked_bulk_update = true,
                                error =
                                    "Only ONE account-changing action is allowed per user message " +
                                    "(update price/qty, pause/active, sold-out, delete, or withdrawal). " +
                                    "Tell the user to send another message for the next change."
                            })
                        });
                        continue;
                    }

                    var result = await toolsService.ExecuteAsync(
                            userId,
                            new AiToolCall(id, name, args),
                            cancellationToken)
                        .ConfigureAwait(false);

                    if (MutatingToolNames.Contains(name)
                        && IsSuccessfulToolPayload(result.Content))
                    {
                        successfulMutations++;
                    }

                    messages.Add(new
                    {
                        role = "tool",
                        tool_call_id = result.CallId,
                        content = result.Content
                    });
                }

                continue;
            }

            return msg.TryGetProperty("content", out var contentEl)
                ? contentEl.GetString()?.Trim()
                    ?? throw new InvalidOperationException("OpenAI returned an empty assistant answer.")
                : throw new InvalidOperationException("OpenAI returned an empty assistant answer.");
        }

        logger.LogWarning("AI assistant exceeded the MCP tool-call limit ({MaxRounds}).", MaxToolRounds);
        throw new InvalidOperationException("AI assistant exceeded the tool-call limit.");
    }

    private static bool IsSuccessfulToolPayload(string content)
    {
        try
        {
            using var doc = JsonDocument.Parse(content);
            return doc.RootElement.TryGetProperty("ok", out var ok)
                   && ok.ValueKind == JsonValueKind.True;
        }
        catch (JsonException)
        {
            return false;
        }
    }
}
