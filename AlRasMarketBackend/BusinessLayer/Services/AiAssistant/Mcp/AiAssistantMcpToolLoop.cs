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
        Func<string, CancellationToken, Task>? onThinkingStep = null,
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

                    if (onThinkingStep is not null)
                    {
                        await onThinkingStep(
                                DescribeToolCall(name),
                                cancellationToken)
                            .ConfigureAwait(false);
                    }

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

                    if (onThinkingStep is not null)
                    {
                        await onThinkingStep(
                                DescribeToolResult(name, result.Content),
                                cancellationToken)
                            .ConfigureAwait(false);
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

    private static string DescribeToolCall(string toolName) =>
        toolName switch
        {
            "get_my_last_order" => "بستدعي أداة: آخر طلب من طلباتي…",
            "get_my_purchase_summary" => "بستدعي أداة: ملخص مشترياتي / اشتريت بكام…",
            "explain_my_order_delay" => "بستدعي أداة: ليه الطلب متأخر (طلباتي)…",
            "get_my_sales_count" => "بستدعي أداة: المبيعات وطلبات الإعلانات…",
            "get_last_order_on_my_ads" => "بستدعي أداة: آخر طلب على إعلاناتي…",
            "explain_order_delay_on_my_ads" => "بستدعي أداة: تأخير طلب على الإعلان…",
            "find_cheapest_product" => "بستدعي أداة: أرخص منتج…",
            "find_most_expensive_product" => "بستدعي أداة: أغلى منتج…",
            "list_my_ads" => "بستدعي أداة: قائمة إعلاناتي…",
            "get_my_last_ad" => "بستدعي أداة: آخر إعلان نزلته…",
            "get_my_first_ad" => "بستدعي أداة: أول إعلان نزلته…",
            "update_ad_price_quantity" => "بستدعي أداة: تعديل السعر/الكمية…",
            "set_ad_listing_status" => "بستدعي أداة: إيقاف/تفعيل إعلان…",
            "mark_ad_sold_out" => "بستدعي أداة: تعليم نفاد الكمية…",
            "delete_ad" => "بستدعي أداة: حذف إعلان…",
            "list_my_ibans" => "بستدعي أداة: الآيبان والرصيد…",
            "create_withdrawal" => "بستدعي أداة: طلب سحب…",
            _ => $"بستدعي أداة: {toolName}…"
        };

    private static string DescribeToolResult(string toolName, string content)
    {
        try
        {
            using var doc = JsonDocument.Parse(content);
            if (doc.RootElement.TryGetProperty("ok", out var ok)
                && ok.ValueKind == JsonValueKind.False)
            {
                var err = doc.RootElement.TryGetProperty("error", out var e)
                    ? e.GetString()
                    : null;
                return string.IsNullOrWhiteSpace(err)
                    ? $"الأداة {toolName} رجّعت خطأ."
                    : $"الأداة {toolName}: {err}";
            }

            if (doc.RootElement.TryGetProperty("found", out var found)
                && found.ValueKind == JsonValueKind.False)
            {
                return $"الأداة {toolName}: مفيش بيانات مطابقة.";
            }
        }
        catch (JsonException)
        {
            // Fall through.
        }

        return $"وصل نتيجة من {toolName}.";
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
