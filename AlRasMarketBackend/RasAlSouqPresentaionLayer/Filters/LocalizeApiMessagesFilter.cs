using System.Text.Json;
using System.Text.Json.Nodes;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace RasAlSouqPresentaionLayer.Filters;

public sealed class LocalizeApiMessagesFilter(IUserLanguageResolver languageResolver) : IAsyncResultFilter
{
    private static readonly string[] LocalizableKeys = ["message", "Message", "detail", "Detail", "title", "Title"];

    public async Task OnResultExecutionAsync(ResultExecutingContext context, ResultExecutionDelegate next)
    {
        if (context.Result is ObjectResult { Value: not null } objectResult)
        {
            var statusCode = objectResult.StatusCode ?? context.HttpContext.Response.StatusCode;
            if (statusCode >= 400 || ContainsUserFacingText(objectResult.Value))
            {
                var language = await languageResolver.ResolveAsync(cancellationToken: context.HttpContext.RequestAborted);
                objectResult.Value = LocalizeValue(objectResult.Value, language);
            }
        }

        await next();
    }

    private static bool ContainsUserFacingText(object value)
    {
        if (value is string text)
        {
            return !string.IsNullOrWhiteSpace(text);
        }

        var json = JsonSerializer.Serialize(value);
        var node = JsonSerializer.Deserialize<JsonNode>(json);
        if (node is not JsonObject obj)
        {
            return false;
        }

        foreach (var key in LocalizableKeys)
        {
            if (obj.TryGetPropertyValue(key, out var token)
                && token is JsonValue jsonValue
                && !string.IsNullOrWhiteSpace(jsonValue.GetValue<string>()))
            {
                return true;
            }
        }

        return false;
    }

    private static object LocalizeValue(object value, string language)
    {
        if (value is string text)
        {
            return UserMessages.Localize(text, language);
        }

        var json = JsonSerializer.Serialize(value);
        var node = JsonSerializer.Deserialize<JsonNode>(json);
        if (node is JsonObject obj)
        {
            LocalizeJsonObject(obj, language);
            return JsonSerializer.Deserialize<object>(obj.ToJsonString()) ?? value;
        }

        return value;
    }

    private static void LocalizeJsonObject(JsonObject obj, string language)
    {
        foreach (var key in LocalizableKeys)
        {
            if (obj.TryGetPropertyValue(key, out var token)
                && token is JsonValue jsonValue)
            {
                var text = jsonValue.GetValue<string>();
                if (!string.IsNullOrWhiteSpace(text))
                {
                    obj[key] = UserMessages.Localize(text, language);
                }
            }
        }
    }
}
