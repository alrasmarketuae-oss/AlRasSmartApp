using System.Net.Http.Headers;
using System.Text;
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
/// Catalog-local image embedding:
/// 1) Vision extracts visible OCR/packaging cues (no world product guessing for search),
/// 2) text-embedding-3-small embeds that fingerprint,
/// 3) Qdrant compares only against your ads.
/// </summary>
public sealed class OpenAiCatalogImageEmbeddingService(
    HttpClient httpClient,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    IConfigurationAccessor configurationAccessor,
    ILogger<OpenAiCatalogImageEmbeddingService> logger) : IImageEmbeddingService
{
    private readonly ImageEmbeddingOptions _options = embeddingOptions.Value;

    public async Task<float[]?> EmbedImageAsync(
        Stream imageStream,
        string? fileName = null,
        ProductImageEmbedContext? catalogContext = null,
        CancellationToken cancellationToken = default)
    {
        // Legacy OpenAI vision→text path kept for reference; CLIP is the active embedder.
        // Catalog text is ignored here — use ClipHttpEmbeddingService.
        _ = catalogContext;
        if (!_options.Enabled)
        {
            return null;
        }

        var apiKey = configurationAccessor.OpenAiApiKey;
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            logger.LogWarning("OpenAI ApiKey missing — cannot embed product image.");
            return null;
        }

        await using var buffered = new MemoryStream();
        await imageStream.CopyToAsync(buffered, cancellationToken).ConfigureAwait(false);
        if (buffered.Length == 0)
        {
            return null;
        }

        buffered.Position = 0;
        using var image = await Image.LoadAsync(buffered, cancellationToken).ConfigureAwait(false);
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
        await image.SaveAsJpegAsync(ms, new JpegEncoder { Quality = 80 }, cancellationToken).ConfigureAwait(false);
        var jpegBytes = ms.ToArray();
        var fingerprint = await BuildVisualFingerprintAsync(apiKey, jpegBytes, fileName, cancellationToken)
            .ConfigureAwait(false);
        if (string.IsNullOrWhiteSpace(fingerprint))
        {
            return null;
        }

        return await EmbedTextAsync(apiKey, fingerprint, cancellationToken).ConfigureAwait(false);
    }

    private async Task<string?> BuildVisualFingerprintAsync(
        string apiKey,
        byte[] jpegBytes,
        string? fileName,
        CancellationToken cancellationToken)
    {
        var dataUrl = $"data:image/jpeg;base64,{Convert.ToBase64String(jpegBytes)}";
        var prompt =
            "You extract a catalog-matching fingerprint from a product photo.\n" +
            "Return ONLY JSON:\n" +
            "{\n" +
            "  \"ocrText\": \"exact readable text on packaging (Arabic/English)\",\n" +
            "  \"brandText\": \"brand if printed\",\n" +
            "  \"productNameText\": \"product name if printed on pack\",\n" +
            "  \"colors\": [\"main colors\"],\n" +
            "  \"packaging\": \"bottle/box/bag/can/other + shape\",\n" +
            "  \"visualKeywords\": [\"distinctive visible traits\"]\n" +
            "}\n" +
            "Rules:\n" +
            "- Prefer exact printed text over guessing.\n" +
            "- Do NOT invent a global retail category or substitute a different product name.\n" +
            "- If text is unreadable, leave ocr/brand/name empty and describe only visible traits.\n";

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/chat/completions");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(
            JsonSerializer.Serialize(new
            {
                model = _options.VisionModel,
                temperature = 0,
                max_tokens = 400,
                response_format = new { type = "json_object" },
                messages = new object[]
                {
                    new { role = "system", content = "You output compact JSON fingerprints for product-image similarity." },
                    new
                    {
                        role = "user",
                        content = new object[]
                        {
                            new { type = "text", text = prompt },
                            new { type = "image_url", image_url = new { url = dataUrl, detail = "low" } }
                        }
                    }
                }
            }),
            Encoding.UTF8,
            "application/json");

        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Vision fingerprint failed ({Status}) for {File}: {Body}",
                (int)response.StatusCode,
                fileName,
                Truncate(body));
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(body);
            var content = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();
            return NormalizeFingerprint(content);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed parsing vision fingerprint for {File}", fileName);
            return null;
        }
    }

    private async Task<float[]?> EmbedTextAsync(
        string apiKey,
        string text,
        CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/embeddings");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(
            JsonSerializer.Serialize(new
            {
                model = _options.EmbeddingModel,
                input = text,
                dimensions = _options.EmbeddingDimensions
            }),
            Encoding.UTF8,
            "application/json");

        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var body = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning("Embedding failed ({Status}): {Body}", (int)response.StatusCode, Truncate(body));
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(body);
            var arr = doc.RootElement.GetProperty("data")[0].GetProperty("embedding");
            var vector = new float[arr.GetArrayLength()];
            var i = 0;
            foreach (var el in arr.EnumerateArray())
            {
                vector[i++] = el.GetSingle();
            }

            return vector;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed parsing embedding response");
            return null;
        }
    }

    private static string? NormalizeFingerprint(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;
            var parts = new List<string>();
            Add(parts, "ocr", ReadString(root, "ocrText"));
            Add(parts, "brand", ReadString(root, "brandText"));
            Add(parts, "name", ReadString(root, "productNameText"));
            Add(parts, "packaging", ReadString(root, "packaging"));

            if (root.TryGetProperty("colors", out var colors) && colors.ValueKind == JsonValueKind.Array)
            {
                var joined = string.Join(' ', colors.EnumerateArray()
                    .Select(x => x.GetString()?.Trim())
                    .Where(x => !string.IsNullOrWhiteSpace(x)));
                Add(parts, "colors", joined);
            }

            if (root.TryGetProperty("visualKeywords", out var keys) && keys.ValueKind == JsonValueKind.Array)
            {
                var joined = string.Join(' ', keys.EnumerateArray()
                    .Select(x => x.GetString()?.Trim())
                    .Where(x => !string.IsNullOrWhiteSpace(x)));
                Add(parts, "traits", joined);
            }

            var text = string.Join(" | ", parts);
            return string.IsNullOrWhiteSpace(text) ? json.Trim() : text;
        }
        catch
        {
            return json.Trim();
        }
    }

    private static void Add(List<string> parts, string label, string? value)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            parts.Add($"{label}:{value.Trim()}");
        }
    }

    private static string ReadString(JsonElement root, string name) =>
        root.TryGetProperty(name, out var el) && el.ValueKind == JsonValueKind.String
            ? el.GetString()?.Trim() ?? string.Empty
            : string.Empty;

    private static string Truncate(string? value) =>
        string.IsNullOrEmpty(value) ? string.Empty : value.Length <= 300 ? value : value[..300];
}

/// <summary>Thin accessor so embedding service does not take full IConfiguration in every call site.</summary>
public interface IConfigurationAccessor
{
    string? OpenAiApiKey { get; }
}

public sealed class ConfigurationAccessor(Microsoft.Extensions.Configuration.IConfiguration configuration)
    : IConfigurationAccessor
{
    public string? OpenAiApiKey => configuration["OpenAI:ApiKey"];
}
