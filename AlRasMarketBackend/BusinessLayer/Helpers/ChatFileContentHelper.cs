using System.Text.Json;

namespace BusinessLayer.Helpers;

/// <summary>
/// Document messages keep the original file name next to the storage path, because the
/// stored object is renamed to a GUID. Content is JSON: {"path":..,"name":..,"size":..,"mime":..}.
/// </summary>
public static class ChatFileContentHelper
{
    public const string FolderPrefix = "/chat-files/";

    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".pdf",
        ".doc",
        ".docx",
        ".xls",
        ".xlsx",
        ".ppt",
        ".pptx",
        ".txt",
        ".csv",
        ".rtf",
        ".zip"
    };

    public static bool IsAllowedExtension(string extension) =>
        AllowedExtensions.Contains(extension);

    public static string AllowedExtensionsLabel =>
        string.Join(", ", AllowedExtensions.OrderBy(x => x, StringComparer.Ordinal));

    public static string GetContentType(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".pdf" => "application/pdf",
            ".doc" => "application/msword",
            ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            ".xls" => "application/vnd.ms-excel",
            ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            ".ppt" => "application/vnd.ms-powerpoint",
            ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            ".txt" => "text/plain",
            ".csv" => "text/csv",
            ".rtf" => "application/rtf",
            ".zip" => "application/zip",
            _ => "application/octet-stream"
        };

    public static string Serialize(string path, string fileName, long sizeBytes, string contentType) =>
        JsonSerializer.Serialize(new
        {
            path,
            name = fileName,
            size = sizeBytes,
            mime = contentType
        });

    /// <summary>Accepts the JSON payload or a bare <c>/chat-files/...</c> path.</summary>
    public static bool TryParse(string content, out ChatFileContent parsed)
    {
        parsed = default;
        if (string.IsNullOrWhiteSpace(content))
        {
            return false;
        }

        var trimmed = content.Trim();
        if (trimmed.StartsWith('{'))
        {
            try
            {
                using var doc = JsonDocument.Parse(trimmed);
                var root = doc.RootElement;
                if (root.ValueKind != JsonValueKind.Object
                    || !root.TryGetProperty("path", out var pathElement))
                {
                    return false;
                }

                var path = pathElement.GetString()?.Trim();
                if (string.IsNullOrWhiteSpace(path))
                {
                    return false;
                }

                var name = root.TryGetProperty("name", out var nameElement)
                    ? nameElement.GetString()?.Trim()
                    : null;
                var size = root.TryGetProperty("size", out var sizeElement)
                    && sizeElement.TryGetInt64(out var parsedSize)
                        ? parsedSize
                        : 0L;
                var mime = root.TryGetProperty("mime", out var mimeElement)
                    ? mimeElement.GetString()?.Trim()
                    : null;

                parsed = new ChatFileContent(
                    path,
                    string.IsNullOrWhiteSpace(name) ? Path.GetFileName(path) : name!,
                    size,
                    string.IsNullOrWhiteSpace(mime) ? GetContentType(Path.GetExtension(path)) : mime!);
                return true;
            }
            catch (JsonException)
            {
                return false;
            }
        }

        if (trimmed.StartsWith(FolderPrefix, StringComparison.OrdinalIgnoreCase))
        {
            parsed = new ChatFileContent(
                trimmed,
                Path.GetFileName(trimmed),
                0,
                GetContentType(Path.GetExtension(trimmed)));
            return true;
        }

        return false;
    }
}

public readonly record struct ChatFileContent(
    string Path,
    string FileName,
    long SizeBytes,
    string ContentType);
