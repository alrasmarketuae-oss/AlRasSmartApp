namespace BusinessLayer.Helpers;

public static class WebRootFileHelper
{
    public static string BuildRelativePath(string folder, string fileName)
    {
        var normalizedFolder = folder.Trim('/').Replace('\\', '/');
        var normalizedFile = fileName.Trim().TrimStart('/');
        return $"/{normalizedFolder}/{normalizedFile}";
    }

    public static string EnsureDirectory(string webRootPath, params string[] segments)
    {
        var directory = Path.Combine(new[] { webRootPath }.Concat(segments).ToArray());
        Directory.CreateDirectory(directory);
        return directory;
    }

    public static string ToFullPath(string webRootPath, string relativePath)
    {
        var relative = relativePath.Trim().TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        return Path.Combine(webRootPath, relative);
    }

    public static string NormalizeStoredPath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return string.Empty;
        }

        var trimmed = path.Trim().Replace('\\', '/');
        return trimmed.StartsWith('/') ? trimmed : $"/{trimmed}";
    }

    /// <summary>
    /// Normalize DB paths or CDN URLs to a storage-relative path (/product-images/...).
    /// </summary>
    public static string NormalizeMediaReferencePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return string.Empty;
        }

        var value = path.Trim().Replace('\\', '/');
        if (value.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || value.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                value = new Uri(value).AbsolutePath;
            }
            catch
            {
                // keep as-is
            }
        }

        foreach (var marker in new[]
                 {
                     "/product-images/",
                     "/product-videos/",
                     "/product-documents/",
                     "/order-videos/",
                 })
        {
            var idx = value.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
            if (idx >= 0)
            {
                value = value[idx..];
                break;
            }
        }

        return value.StartsWith('/') ? value : $"/{value.TrimStart('/')}";
    }

    public static void TryDeleteRelativeFile(string webRootPath, string? relativePath, string? exceptFullPath = null)
    {
        if (string.IsNullOrWhiteSpace(relativePath))
        {
            return;
        }

        var fullPath = ToFullPath(webRootPath, relativePath);
        if (!File.Exists(fullPath))
        {
            return;
        }

        if (exceptFullPath is not null
            && string.Equals(Path.GetFullPath(fullPath), Path.GetFullPath(exceptFullPath), StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        File.Delete(fullPath);
    }

    public static void TryDeleteEmptyLegacySubfolder(string webRootPath, string? relativePath, params string[] flatRootSegments)
    {
        if (string.IsNullOrWhiteSpace(relativePath))
        {
            return;
        }

        var fileFullPath = ToFullPath(webRootPath, relativePath);
        var parentDir = Path.GetDirectoryName(fileFullPath);
        var flatRoot = Path.Combine(new[] { webRootPath }.Concat(flatRootSegments).ToArray());

        if (parentDir is null
            || !Directory.Exists(parentDir)
            || string.Equals(Path.GetFullPath(parentDir), Path.GetFullPath(flatRoot), StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        if (!Directory.EnumerateFileSystemEntries(parentDir).Any())
        {
            Directory.Delete(parentDir);
        }
    }
}
