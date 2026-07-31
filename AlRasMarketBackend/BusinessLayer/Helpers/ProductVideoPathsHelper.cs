using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class ProductVideoPathsHelper
{
    public const int MaxProductVideos = 5;

    public sealed record VideoItem(long Id, string Path, byte? DurationSeconds, bool IsMuted);

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

    public static List<string> ResolveAll(string? primaryVideoPath, IEnumerable<ProductVideo>? extraVideos) =>
        ResolveVideoItems(primaryVideoPath, null, extraVideos).Select(x => x.Path).ToList();

    public static List<string> ResolveAll(Product? product, IEnumerable<ProductVideo>? extraVideos = null) =>
        ResolveAll(product?.VideoPath, extraVideos ?? product?.ProductVideos);

    public static List<VideoItem> ResolveVideoItems(
        string? primaryVideoPath,
        byte? primaryVideoDurationSeconds,
        IEnumerable<ProductVideo>? videos)
    {
        var resolved = new List<VideoItem>();
        if (videos is not null)
        {
            foreach (var video in videos.OrderBy(x => x.Id))
            {
                AddUnique(resolved, new VideoItem(
                    video.Id,
                    video.VideoPath,
                    video.VideoDurationSeconds,
                    video.IsMuted));
            }
        }

        if (!string.IsNullOrWhiteSpace(primaryVideoPath)
            && !resolved.Any(v => string.Equals(v.Path, primaryVideoPath.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            AddUnique(resolved, new VideoItem(0, primaryVideoPath, primaryVideoDurationSeconds, true));
        }

        return resolved;
    }

    public static List<VideoItem> ResolveVideoItems(
        string? primaryVideoPath,
        byte? primaryVideoDurationSeconds,
        IEnumerable<DataLayer.Models.ProductMediaPathRow>? videos)
    {
        var resolved = new List<VideoItem>();
        if (videos is not null)
        {
            foreach (var video in videos.OrderBy(x => x.Id))
            {
                AddUnique(resolved, new VideoItem(
                    video.Id,
                    video.Path,
                    video.VideoDurationSeconds,
                    video.IsMuted));
            }
        }

        if (!string.IsNullOrWhiteSpace(primaryVideoPath)
            && !resolved.Any(v => string.Equals(v.Path, primaryVideoPath.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            AddUnique(resolved, new VideoItem(0, primaryVideoPath, primaryVideoDurationSeconds, true));
        }

        return resolved;
    }

    private static void AddUnique(List<VideoItem> videos, VideoItem video)
    {
        if (string.IsNullOrWhiteSpace(video.Path)
            || videos.Any(existing => string.Equals(existing.Path, video.Path.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        videos.Add(video with { Path = video.Path.Trim() });
    }

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
