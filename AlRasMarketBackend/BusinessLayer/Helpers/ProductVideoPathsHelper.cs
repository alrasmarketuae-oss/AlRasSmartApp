using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class ProductVideoPathsHelper
{
    public const int MaxProductVideos = 5;

    public static List<string> ResolveAll(string? primaryVideoPath, IEnumerable<string>? extraVideoPaths)
    {
        var paths = new List<string>();
        AddUnique(paths, primaryVideoPath);
        if (extraVideoPaths is not null)
        {
            foreach (var path in extraVideoPaths)
            {
                AddUnique(paths, path);
            }
        }

        return paths;
    }

    public static List<string> ResolveAll(string? primaryVideoPath, IEnumerable<ProductVideo>? extraVideos)
    {
        var paths = new List<string>();
        AddUnique(paths, primaryVideoPath);

        if (extraVideos is not null)
        {
            foreach (var video in extraVideos.OrderBy(x => x.Id))
            {
                AddUnique(paths, video.VideoPath);
            }
        }

        return paths;
    }

    public static List<string> ResolveAll(Product? product, IEnumerable<ProductVideo>? extraVideos = null) =>
        ResolveAll(product?.VideoPath, extraVideos ?? product?.ProductVideos);

    private static void AddUnique(List<string> paths, string? path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return;
        }

        var trimmed = path.Trim();
        if (paths.Any(existing => string.Equals(existing, trimmed, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        paths.Add(trimmed);
    }
}
