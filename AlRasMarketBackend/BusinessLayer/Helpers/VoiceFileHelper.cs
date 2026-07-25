namespace BusinessLayer.Helpers;

public static class VoiceFileHelper
{
    private static readonly HashSet<string> AllowedExtensions =
    [
        ".webm", ".ogg", ".mp3", ".m4a", ".wav", ".aac", ".caf", ".3gp", ".3gpp", ".amr"
    ];

    public static string ResolveVoiceExtension(string fileName, string? contentType, ReadOnlySpan<byte> header)
    {
        var fromContent = DetectExtensionFromHeader(header);
        if (fromContent is not null)
        {
            return fromContent;
        }

        var fromContentType = ExtensionFromContentType(contentType);
        if (fromContentType is not null)
        {
            return fromContentType;
        }

        var fromName = Path.GetExtension(fileName).ToLowerInvariant();
        if (AllowedExtensions.Contains(fromName))
        {
            return NormalizeExtension(fromName);
        }

        throw new ArgumentException(
            "Unsupported audio format. Allowed: .webm, .ogg, .mp3, .m4a, .wav, .aac, .caf, .3gp, .amr");
    }

    public static string GetContentTypeFromFile(string fullPath)
    {
        var header = new byte[16];
        var read = 0;
        using (var stream = File.OpenRead(fullPath))
        {
            read = stream.Read(header, 0, header.Length);
        }

        var fromHeader = DetectExtensionFromHeader(header.AsSpan(0, read));
        if (fromHeader is not null)
        {
            return GetContentType($"file{fromHeader}");
        }

        return GetContentType(fullPath);
    }

    public static string GetContentType(string? relativePath)
    {
        var extension = Path.GetExtension(relativePath ?? string.Empty).ToLowerInvariant();
        return extension switch
        {
            ".m4a" or ".mp4" or ".aac" => "audio/mp4",
            ".caf" => "audio/x-caf",
            ".webm" or ".weba" => "audio/webm",
            ".ogg" => "audio/ogg",
            ".wav" => "audio/wav",
            ".mp3" => "audio/mpeg",
            ".3gp" or ".3gpp" => "audio/3gpp",
            ".amr" => "audio/amr",
            _ => "application/octet-stream"
        };
    }

    public static string? DetectExtensionFromHeader(ReadOnlySpan<byte> header)
    {
        if (header.Length >= 4 && header[0] == 0x1A && header[1] == 0x45 && header[2] == 0xDF && header[3] == 0xA3)
        {
            return ".webm";
        }

        if (header.Length >= 4 && header[0] == (byte)'c' && header[1] == (byte)'a' && header[2] == (byte)'f' && header[3] == (byte)'f')
        {
            return ".caf";
        }

        if (header.Length >= 4 && header[0] == (byte)'O' && header[1] == (byte)'g' && header[2] == (byte)'g' && header[3] == (byte)'S')
        {
            return ".ogg";
        }

        if (header.Length >= 12 && header[0] == (byte)'R' && header[1] == (byte)'I' && header[2] == (byte)'F' && header[3] == (byte)'F')
        {
            return ".wav";
        }

        if (header.Length >= 3 && header[0] == (byte)'I' && header[1] == (byte)'D' && header[2] == (byte)'3')
        {
            return ".mp3";
        }

        if (header.Length >= 8 && header[4] == (byte)'f' && header[5] == (byte)'t' && header[6] == (byte)'y' && header[7] == (byte)'p')
        {
            return ResolveIsoBmffExtension(header);
        }

        if (header.Length >= 6 && header[0] == (byte)'#' && header[1] == (byte)'!' && header[2] == (byte)'A' && header[3] == (byte)'M' && header[4] == (byte)'R')
        {
            return ".amr";
        }

        return null;
    }

    private static string ResolveIsoBmffExtension(ReadOnlySpan<byte> header)
    {
        if (header.Length >= 12)
        {
            var brand = System.Text.Encoding.ASCII.GetString(header.Slice(8, Math.Min(4, header.Length - 8)));
            if (brand.StartsWith("3gp", StringComparison.OrdinalIgnoreCase))
            {
                return ".3gp";
            }
        }

        return ".m4a";
    }

    private static string? ExtensionFromContentType(string? contentType)
    {
        if (string.IsNullOrWhiteSpace(contentType))
        {
            return null;
        }

        var mime = contentType.Split(';', 2)[0].Trim().ToLowerInvariant();
        return mime switch
        {
            "audio/webm" => ".webm",
            "audio/ogg" => ".ogg",
            "audio/wav" or "audio/x-wav" => ".wav",
            "audio/mpeg" or "audio/mp3" => ".mp3",
            "audio/mp4" or "audio/aac" or "audio/x-m4a" or "audio/m4a" => ".m4a",
            "audio/x-caf" or "audio/caf" => ".caf",
            "audio/3gpp" or "audio/3gp" => ".3gp",
            "audio/amr" => ".amr",
            "application/octet-stream" => null,
            _ => null
        };
    }

    private static string NormalizeExtension(string extension) =>
        extension switch
        {
            ".3gpp" => ".3gp",
            _ => extension
        };
}
