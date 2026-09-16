using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces.AiAssistant;
using BusinessLayer.Options;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Shopping;

/// <summary>
/// Minimal Responses API HTTP client (no NuGet OpenAI SDK). Steering WebSocket is phase 5+.
/// </summary>
public sealed class AiResponsesApiClient(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    IOptions<AiShoppingAgentOptions> options,
    ILogger<AiResponsesApiClient> logger) : IAiResponsesApiClient
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly AiShoppingAgentOptions _options = options.Value;

    public async Task<AiResponsesCreateResult> CreateAsync(
        AiResponsesCreateRequest request,
        CancellationToken cancellationToken)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            return Fail("OpenAI API key is not configured.");
        }

        using var http = httpClientFactory.CreateClient(nameof(AiResponsesApiClient));
        using var message = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/responses");
        message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

        var body = new Dictionary<string, object?>
        {
            ["model"] = request.Model,
            ["instructions"] = request.Instructions,
            ["input"] = request.Input,
            ["tools"] = request.Tools,
            ["store"] = request.Store,
            ["max_output_tokens"] = request.MaxOutputTokens,
            ["reasoning"] = new Dictionary<string, object?>
            {
                ["effort"] = NormalizeEffort(request.ReasoningEffort)
            }
        };

        if (!string.IsNullOrWhiteSpace(request.PreviousResponseId))
        {
            body["previous_response_id"] = request.PreviousResponseId;
        }

        if (!string.IsNullOrWhiteSpace(request.PromptCacheKey))
        {
            body["prompt_cache_key"] = request.PromptCacheKey;
        }

        message.Content = new StringContent(
            JsonSerializer.Serialize(body),
            Encoding.UTF8,
            "application/json");

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(Math.Max(5, _options.TimeoutSeconds)));

        try
        {
            using var response = await http.SendAsync(message, timeoutCts.Token).ConfigureAwait(false);
            var json = await response.Content.ReadAsStringAsync(timeoutCts.Token).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "AiShopping Responses API failed status={Status} bodyLength={Len}",
                    (int)response.StatusCode,
                    json.Length);
                return Fail($"OpenAI Responses error {(int)response.StatusCode}");
            }

            return Parse(json);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return Fail("OpenAI request timed out.");
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "AiShopping Responses API transport failure");
            return Fail("OpenAI is temporarily unavailable.");
        }
    }

    private static string NormalizeEffort(string? effort)
    {
        var value = (effort ?? "low").Trim().ToLowerInvariant();
        return value switch
        {
            "medium" or "high" or "xhigh" or "low" => value,
            "max" => "high", // never default to max
            _ => "low"
        };
    }

    private static AiResponsesCreateResult Parse(string json)
    {
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;
        var responseId = root.TryGetProperty("id", out var idEl) ? idEl.GetString() : null;
        var status = root.TryGetProperty("status", out var stEl) ? stEl.GetString() : null;

        var inputTokens = ReadUsage(root, "input_tokens");
        var outputTokens = ReadUsage(root, "output_tokens");
        var cached = 0;
        if (root.TryGetProperty("usage", out var usage)
            && usage.TryGetProperty("input_tokens_details", out var details)
            && details.TryGetProperty("cached_tokens", out var cachedEl)
            && cachedEl.TryGetInt32(out var cachedVal))
        {
            cached = cachedVal;
        }

        var text = new StringBuilder();
        var calls = new List<AiResponsesFunctionCall>();

        if (root.TryGetProperty("output", out var output) && output.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in output.EnumerateArray())
            {
                var type = item.TryGetProperty("type", out var typeEl) ? typeEl.GetString() : null;
                if (string.Equals(type, "message", StringComparison.OrdinalIgnoreCase))
                {
                    if (item.TryGetProperty("content", out var content)
                        && content.ValueKind == JsonValueKind.Array)
                    {
                        foreach (var part in content.EnumerateArray())
                        {
                            if (part.TryGetProperty("text", out var textEl))
                            {
                                text.Append(textEl.GetString());
                            }
                            else if (part.TryGetProperty("type", out var pt)
                                     && pt.GetString() == "output_text"
                                     && part.TryGetProperty("text", out var ot))
                            {
                                text.Append(ot.GetString());
                            }
                        }
                    }
                }
                else if (string.Equals(type, "function_call", StringComparison.OrdinalIgnoreCase))
                {
                    var callId = item.TryGetProperty("call_id", out var c)
                        ? c.GetString()
                        : item.TryGetProperty("id", out var i) ? i.GetString() : null;
                    var name = item.TryGetProperty("name", out var n) ? n.GetString() : null;
                    var args = item.TryGetProperty("arguments", out var a) ? a.GetString() : "{}";
                    var async = item.TryGetProperty("async", out var asy) && asy.ValueKind == JsonValueKind.True;
                    if (!string.IsNullOrWhiteSpace(callId) && !string.IsNullOrWhiteSpace(name))
                    {
                        calls.Add(new AiResponsesFunctionCall
                        {
                            CallId = callId!,
                            Name = name!,
                            ArgumentsJson = string.IsNullOrWhiteSpace(args) ? "{}" : args!,
                            Async = async
                        });
                    }
                }
            }
        }

        // Some Responses payloads put assistant text in output_text convenience field.
        if (text.Length == 0
            && root.TryGetProperty("output_text", out var outputText)
            && outputText.ValueKind == JsonValueKind.String)
        {
            text.Append(outputText.GetString());
        }

        return new AiResponsesCreateResult
        {
            Ok = true,
            ResponseId = responseId,
            Status = status,
            AssistantText = text.ToString().Trim(),
            FunctionCalls = calls,
            InputTokens = inputTokens,
            CachedInputTokens = cached,
            OutputTokens = outputTokens,
            RawJson = json
        };
    }

    private static int ReadUsage(JsonElement root, string name)
    {
        if (root.TryGetProperty("usage", out var usage)
            && usage.TryGetProperty(name, out var el)
            && el.TryGetInt32(out var value))
        {
            return value;
        }

        return 0;
    }

    private static AiResponsesCreateResult Fail(string message) =>
        new()
        {
            Ok = false,
            ErrorMessage = message
        };
}
