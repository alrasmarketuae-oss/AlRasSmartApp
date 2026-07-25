using System.Text.Json;

namespace BusinessLayer.Helpers;

/// <summary>Detects hybrid E2E chat envelopes stored in ChatMessages.Content.</summary>
public static class ChatE2eContentHelper
{
    public const int EnvelopeVersion = 1;

    public static bool IsEncryptedEnvelope(string? content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return false;
        }

        var trimmed = content.Trim();
        if (trimmed.Length < 20 || trimmed[0] != '{')
        {
            return false;
        }

        try
        {
            using var doc = JsonDocument.Parse(trimmed);
            var root = doc.RootElement;
            if (!root.TryGetProperty("e2e", out var e2e) || e2e.ValueKind != JsonValueKind.True)
            {
                return false;
            }

            if (!root.TryGetProperty("v", out var version))
            {
                return false;
            }

            var v = version.ValueKind == JsonValueKind.Number
                ? version.GetInt32()
                : int.TryParse(version.GetString(), out var parsed) ? parsed : 0;
            return v == EnvelopeVersion
                && root.TryGetProperty("ct", out _)
                && root.TryGetProperty("iv", out _)
                && root.TryGetProperty("ek", out _);
        }
        catch (JsonException)
        {
            return false;
        }
    }
}
