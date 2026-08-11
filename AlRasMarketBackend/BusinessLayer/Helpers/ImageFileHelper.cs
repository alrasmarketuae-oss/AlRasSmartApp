using Microsoft.AspNetCore.Http;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace BusinessLayer.Helpers;

public sealed class ImageCompressionOptions
{
    public int MaxBytes { get; init; } = 500 * 1024;
    public int MaxSide { get; init; } = 1920;
    public int InitialQuality { get; init; } = 85;
    public int MinQuality { get; init; } = 55;
    public int QualityStep { get; init; } = 5;
    public bool AutoOrient { get; init; } = true;
    public bool EnforceByteTarget { get; init; } = true;

    public static ImageCompressionOptions WebStandard { get; } = new();

    /// <summary>
    /// Faster preset for product image upload API responsiveness.
    /// Disables "encode-under-byte-limit" loop to avoid blocking requests for large images.
    /// </summary>
    public static ImageCompressionOptions ProductUploadFast { get; } = new()
    {
        MaxSide = 1600,
        InitialQuality = 80,
        AutoOrient = true,
        EnforceByteTarget = false
    };

    public static ImageCompressionOptions Chat { get; } = new()
    {
        MaxBytes = 450 * 1024,
        MaxSide = 1600,
        InitialQuality = 82,
        MinQuality = 60,
        QualityStep = 5,
        AutoOrient = true,
        EnforceByteTarget = true
    };

    public static ImageCompressionOptions SearchVision { get; } = new()
    {
        MaxBytes = 350 * 1024,
        MaxSide = 1280,
        InitialQuality = 80,
        MinQuality = 55,
        QualityStep = 5,
        AutoOrient = true,
        EnforceByteTarget = true
    };

    /// <summary>
    /// Higher-fidelity preset for policy OCR (phone / company name on sacks and labels).
    /// Does not shrink to a byte budget so printed text stays readable.
    /// </summary>
    public static ImageCompressionOptions ModerationVision { get; } = new()
    {
        MaxBytes = 900 * 1024,
        MaxSide = 1920,
        InitialQuality = 88,
        MinQuality = 75,
        QualityStep = 5,
        AutoOrient = true,
        EnforceByteTarget = false
    };
}

public static class ImageFileHelper
{
    public static Task SaveCompressedJpegAsync(
        IFormFile file,
        string outputPath,
        CancellationToken cancellationToken = default) =>
        SaveCompressedJpegAsync(file, outputPath, ImageCompressionOptions.WebStandard, cancellationToken);

    public static async Task SaveCompressedJpegAsync(
        IFormFile file,
        string outputPath,
        ImageCompressionOptions options,
        CancellationToken cancellationToken = default)
    {
        var compressed = await CompressToJpegBytesAsync(file, options, cancellationToken);
        await File.WriteAllBytesAsync(outputPath, compressed, cancellationToken);
    }

    public static async Task<byte[]> CompressToJpegBytesAsync(
        IFormFile file,
        ImageCompressionOptions options,
        CancellationToken cancellationToken = default)
    {
        await using var input = file.OpenReadStream();
        return await CompressToJpegBytesAsync(input, options, cancellationToken).ConfigureAwait(false);
    }

    public static async Task<byte[]> CompressToJpegBytesAsync(
        Stream input,
        ImageCompressionOptions options,
        CancellationToken cancellationToken = default)
    {
        using var image = await Image.LoadAsync(input, cancellationToken).ConfigureAwait(false);

        if (options.AutoOrient)
        {
            image.Mutate(x => x.AutoOrient());
        }

        var maxSide = Math.Max(image.Width, image.Height);
        if (maxSide > options.MaxSide)
        {
            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Mode = ResizeMode.Max,
                Size = new Size(options.MaxSide, options.MaxSide)
            }));
        }

        if (options.EnforceByteTarget)
        {
            return await EncodeUnderByteLimitAsync(image, options, cancellationToken).ConfigureAwait(false);
        }

        return await EncodeOnceAsync(image, options.InitialQuality, cancellationToken).ConfigureAwait(false);
    }

    private static async Task<byte[]> EncodeUnderByteLimitAsync(
        Image image,
        ImageCompressionOptions options,
        CancellationToken cancellationToken)
    {
        var quality = options.InitialQuality;
        while (quality >= options.MinQuality)
        {
            var bytes = await EncodeOnceAsync(image, quality, cancellationToken);
            if (bytes.Length <= options.MaxBytes)
            {
                return bytes;
            }

            quality -= options.QualityStep;
        }

        using var fallbackImage = image.Clone(ctx =>
        {
            var maxSide = Math.Max(image.Width, image.Height);
            if (maxSide > 960)
            {
                ctx.Resize(new ResizeOptions
                {
                    Mode = ResizeMode.Max,
                    Size = new Size(960, 960)
                });
            }
        });

        return await EncodeOnceAsync(fallbackImage, options.MinQuality, cancellationToken);
    }

    private static async Task<byte[]> EncodeOnceAsync(
        Image image,
        int quality,
        CancellationToken cancellationToken)
    {
        await using var ms = new MemoryStream();
        await image.SaveAsJpegAsync(
            ms,
            new JpegEncoder
            {
                Quality = quality,
                SkipMetadata = true
            },
            cancellationToken);
        return ms.ToArray();
    }
}
