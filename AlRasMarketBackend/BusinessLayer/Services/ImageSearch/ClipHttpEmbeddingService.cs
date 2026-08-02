using System.Net.Http.Headers;
using System.Text.Json;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace BusinessLayer.Services.ImageSearch;

/// <summary>
/// CLIP image embeddings via the local clip-service.
/// Index and search both use image-only vectors so visual similarity is not
/// pulled toward unrelated products that share similar catalog text.
/// </summary>
public sealed class ClipHttpEmbeddingService(
    HttpClient httpClient,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    ILogger<ClipHttpEmbeddingService> logger) : IImageEmbeddingService
{
    private readonly ImageEmbeddingOptions _options = embeddingOptions.Value;

    public async Task<float[]?> EmbedImageAsync(
        Stream imageStream,
        string? fileName = null,
        ProductImageEmbedContext? catalogContext = null,
        CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            return null;
        }

        if (string.IsNullOrWhiteSpace(_options.ClipServiceUrl))
        {
            logger.LogWarning("ImageEmbedding:ClipServiceUrl is empty — cannot embed with CLIP.");
            return null;
        }

        await using var buffered = new MemoryStream();
        await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
        if (buffered.Length == 0)
        {
            return null;
        }

        buffered.Position = 0;
        // Mobile already sends a small JPEG for search — skip ImageSharp re-encode.
        byte[] jpegBytes;
        if (LooksLikeJpeg(buffered) && buffered.Length is > 0 and <= 120_000)
        {
            jpegBytes = buffered.ToArray();
        }
        else
        {
            jpegBytes = await ToJpegBytesAsync(buffered, _options.CenterCropRatio, cancellationToken)
                .ConfigureAwait(false);
        }

        if (jpegBytes.Length == 0)
        {
            return null;
        }

        // Image-only for both index and query. Text fusion skewed matches toward
        // products with similar names/categories even when the photo differed.
        _ = catalogContext;
        return await EmbedImageOnlyAsync(jpegBytes, fileName, cancellationToken).ConfigureAwait(false);
    }

    private async Task<float[]?> EmbedImageOnlyAsync(
        byte[] jpegBytes,
        string? fileName,
        CancellationToken cancellationToken)
    {
        using var content = new MultipartFormDataContent();
        var imageContent = new ByteArrayContent(jpegBytes);
        imageContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        content.Add(imageContent, "file", string.IsNullOrWhiteSpace(fileName) ? "query.jpg" : fileName);

        using var response = await httpClient
            .PostAsync(CombineUrl("embed/image"), content, cancellationToken)
            .ConfigureAwait(false);
        return await ReadVectorAsync(response, fileName, cancellationToken).ConfigureAwait(false);
    }

    private async Task<float[]?> EmbedMultimodalAsync(
        byte[] jpegBytes,
        string? fileName,
        string catalogText,
        CancellationToken cancellationToken)
    {
        using var content = new MultipartFormDataContent();
        var imageContent = new ByteArrayContent(jpegBytes);
        imageContent.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        content.Add(imageContent, "file", string.IsNullOrWhiteSpace(fileName) ? "product.jpg" : fileName);
        content.Add(new StringContent(catalogText), "text");
        content.Add(new StringContent(_options.ClipImageWeight.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture)), "image_weight");
        content.Add(new StringContent(_options.ClipTextWeight.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture)), "text_weight");

        using var response = await httpClient
            .PostAsync(CombineUrl("embed/multimodal"), content, cancellationToken)
            .ConfigureAwait(false);
        return await ReadVectorAsync(response, fileName, cancellationToken).ConfigureAwait(false);
    }

    private async Task<float[]?> ReadVectorAsync(
        HttpResponseMessage response,
        string? fileName,
        CancellationToken cancellationToken)
    {
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "CLIP embed failed ({Status}) for {File}: {Body}",
                (int)response.StatusCode,
                fileName,
                Truncate(body));
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(body);
            var arr = doc.RootElement.GetProperty("vector");
            var vector = new float[arr.GetArrayLength()];
            var i = 0;
            foreach (var el in arr.EnumerateArray())
            {
                vector[i++] = el.GetSingle();
            }

            if (_options.EmbeddingDimensions > 0 && vector.Length != _options.EmbeddingDimensions)
            {
                logger.LogWarning(
                    "CLIP dim mismatch for {File}: got {Got}, expected {Expected}",
                    fileName,
                    vector.Length,
                    _options.EmbeddingDimensions);
            }

            return vector;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed parsing CLIP response for {File}", fileName);
            return null;
        }
    }

    private static bool LooksLikeJpeg(MemoryStream stream)
    {
        if (stream.Length < 3)
        {
            return false;
        }

        var pos = stream.Position;
        try
        {
            stream.Position = 0;
            Span<byte> header = stackalloc byte[3];
            var read = stream.Read(header);
            return read == 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
        }
        finally
        {
            stream.Position = pos;
        }
    }

    private static async Task<byte[]> ToJpegBytesAsync(
        Stream stream,
        float centerCropRatio,
        CancellationToken cancellationToken)
    {
        using var image = await Image.LoadAsync(stream, cancellationToken).ConfigureAwait(false);

        // Assume the product sits in the center — trim background-heavy edges.
        var ratio = Math.Clamp(centerCropRatio, 0.4f, 1f);
        if (ratio < 0.999f)
        {
            var cropW = Math.Max(1, (int)Math.Round(image.Width * ratio));
            var cropH = Math.Max(1, (int)Math.Round(image.Height * ratio));
            var x = (image.Width - cropW) / 2;
            var y = (image.Height - cropH) / 2;
            image.Mutate(ctx => ctx.Crop(new Rectangle(x, y, cropW, cropH)));
        }

        const int maxSide = 1024;
        if (image.Width > maxSide || image.Height > maxSide)
        {
            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Mode = ResizeMode.Max,
                Size = new Size(maxSide, maxSide)
            }));
        }

        await using var ms = new MemoryStream();
        await image.SaveAsJpegAsync(ms, new JpegEncoder { Quality = 85 }, cancellationToken).ConfigureAwait(false);
        return ms.ToArray();
    }

    private string CombineUrl(string relative)
    {
        var baseUrl = _options.ClipServiceUrl.TrimEnd('/') + "/";
        return new Uri(new Uri(baseUrl), relative.TrimStart('/')).ToString();
    }

    private static string Truncate(string? value) =>
        string.IsNullOrEmpty(value) ? string.Empty : value.Length <= 300 ? value : value[..300];
}
