using System.Text.Json;

namespace BusinessLayer.Helpers;

public static class ChatImageContentHelper
{
    public static bool TryParseImagePaths(string content, out IReadOnlyList<string> paths)
    {
        paths = [];
        if (string.IsNullOrWhiteSpace(content))
        {
            return false;
        }

        var trimmed = content.Trim();
        if (trimmed.StartsWith('{') && trimmed.Contains("\"images\"", StringComparison.Ordinal))
        {
            try
            {
                using var doc = JsonDocument.Parse(trimmed);
                if (doc.RootElement.TryGetProperty("images", out var imagesElement)
                    && imagesElement.ValueKind == JsonValueKind.Array)
                {
                    var list = imagesElement.EnumerateArray()
                        .Select(x => x.GetString()?.Trim())
                        .Where(x => !string.IsNullOrWhiteSpace(x))
                        .Select(x => x!)
                        .ToList();

                    if (list.Count > 0)
                    {
                        paths = list;
                        return true;
                    }
                }
            }
            catch (JsonException)
            {
                return false;
            }
        }

        if (trimmed.StartsWith("/chat-images/", StringComparison.OrdinalIgnoreCase))
        {
            paths = [trimmed];
            return true;
        }

        return false;
    }

    public static string SerializeImagePaths(IEnumerable<string> paths)
    {
        var normalized = paths
            .Select(x => x.Trim())
            .Where(x => x.Length > 0)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (normalized.Count == 0)
        {
            throw new ArgumentException("At least one image path is required.");
        }

        if (normalized.Count == 1)
        {
            return normalized[0];
        }

        return JsonSerializer.Serialize(new { images = normalized });
    }

    public static string BuildPreview(IReadOnlyList<string> paths) =>
        paths.Count switch
        {
            0 => "صورة",
            1 => "صورة",
            _ => $"{paths.Count} صور"
        };
}
