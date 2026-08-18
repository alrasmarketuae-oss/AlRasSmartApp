using System.Text.Json;
using System.Text.Json.Nodes;

namespace BusinessLayer.Services.AiAssistant.Voice;

/// <summary>
/// Chat Completions tools are { type, function: { name, description, parameters } }.
/// Realtime sessions expect a flattened { type, name, description, parameters }.
/// </summary>
public static class AiVoiceRealtimeToolSchema
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = null
    };

    public static JsonArray ToRealtimeTools(IReadOnlyList<object> chatToolDefinitions)
    {
        var element = JsonSerializer.SerializeToElement(chatToolDefinitions, SerializerOptions);
        var result = new JsonArray();
        if (element.ValueKind != JsonValueKind.Array)
        {
            return result;
        }

        foreach (var item in element.EnumerateArray())
        {
            if (item.TryGetProperty("function", out var function)
                && function.ValueKind == JsonValueKind.Object)
            {
                var node = new JsonObject
                {
                    ["type"] = "function",
                    ["name"] = function.TryGetProperty("name", out var name)
                        ? name.GetString()
                        : "",
                    ["description"] = function.TryGetProperty("description", out var description)
                        ? description.GetString()
                        : "",
                };
                if (function.TryGetProperty("parameters", out var parameters))
                {
                    node["parameters"] = JsonNode.Parse(parameters.GetRawText());
                }

                result.Add(node);
                continue;
            }

            result.Add(JsonNode.Parse(item.GetRawText()));
        }

        return result;
    }
}
