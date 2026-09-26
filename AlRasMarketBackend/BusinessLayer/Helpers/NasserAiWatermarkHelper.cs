using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace BusinessLayer.Helpers;

public static class NasserAiWatermarkHelper
{
    private static readonly Lazy<byte[]?> WatermarkBytes = new(LoadWatermarkBytes);

    public static async Task<byte[]> ApplyAsync(byte[] imageBytes, CancellationToken cancellationToken = default)
    {
        var mark = WatermarkBytes.Value;
        if (mark is null || mark.Length == 0)
        {
            return imageBytes;
        }

        using var image = await Image.LoadAsync(new MemoryStream(imageBytes), cancellationToken)
            .ConfigureAwait(false);
        using var watermark = await Image.LoadAsync(new MemoryStream(mark), cancellationToken)
            .ConfigureAwait(false);

        // Small mark — faster composite, less visual noise
        var target = Math.Clamp(Math.Min(image.Width, image.Height) / 8, 48, 112);
        using var stamp = watermark.Clone(x => x.Resize(target, target));

        var pad = Math.Max(8, image.Width / 80);
        var x = Math.Max(0, image.Width - stamp.Width - pad);
        var y = Math.Max(0, image.Height - stamp.Height - pad);

        image.Mutate(ctx => ctx.DrawImage(stamp, new Point(x, y), 0.88f));

        await using var ms = new MemoryStream();
        await image.SaveAsJpegAsync(
                ms,
                new JpegEncoder { Quality = 88, SkipMetadata = true },
                cancellationToken)
            .ConfigureAwait(false);
        return ms.ToArray();
    }

    private static byte[]? LoadWatermarkBytes()
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Assets", "nasser-ai-watermark.png"),
            Path.Combine(AppContext.BaseDirectory, "nasser-ai-watermark.png"),
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "BusinessLayer", "Assets", "nasser-ai-watermark.png")),
        };

        foreach (var path in candidates)
        {
            if (File.Exists(path))
            {
                return File.ReadAllBytes(path);
            }
        }

        return null;
    }
}
