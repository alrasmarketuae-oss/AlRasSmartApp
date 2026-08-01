using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class OpenAiTextEmbeddingService(
    HttpClient httpClient,
    IConfiguration configuration,
    IOptions<AiAssistantOptions> options) : IAiTextEmbeddingService
{
    private readonly AiAssistantOptions _options = options.Value;

    public async Task<float[]> EmbedAsync(string text, CancellationToken cancellationToken = default)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");
        }

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            "https://api.openai.com/v1/embeddings");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        request.Content = new StringContent(
            JsonSerializer.Serialize(new
            {
                model = _options.EmbeddingModel,
                input = text.Trim(),
                dimensions = _options.EmbeddingDimensions
            }),
            Encoding.UTF8,
            "application/json");

        using var response = await httpClient.SendAsync(request, cancellationToken).ConfigureAwait(false);
        var json = await response.Content.ReadAsStringAsync(cancellationToken).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"OpenAI embedding failed ({(int)response.StatusCode}): {json}");
        }

        using var doc = JsonDocument.Parse(json);
        return doc.RootElement
            .GetProperty("data")[0]
            .GetProperty("embedding")
            .EnumerateArray()
            .Select(x => x.GetSingle())
            .ToArray();
    }
}
