using System.Net.Http.Headers;
using System.Net.Http.Json;
using BusinessLayer.Options;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Voice;

/// <summary>
/// Side-channel OpenAI TTS for short user-facing wait phrases.
/// Does not block the Realtime response path.
/// </summary>
public sealed class AiVoiceProgressSpeechService(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    IOptions<AiVoiceAgentOptions> options,
    ILogger<AiVoiceProgressSpeechService> logger)
{
    public async Task<byte[]?> SynthesizePcmAsync(
        string phrase,
        string voice,
        CancellationToken cancellationToken)
    {
        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(phrase))
        {
            return null;
        }

        try
        {
            var client = httpClientFactory.CreateClient("OpenAiVoiceProgress");
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/audio/speech");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            request.Content = JsonContent.Create(new
            {
                model = options.Value.ProgressSpeechModel,
                voice,
                input = phrase,
                response_format = "pcm",
                speed = 1.05
            });

            using var response = await client.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "Voice progress speech HTTP {Status}",
                    (int)response.StatusCode);
                return null;
            }

            return await response.Content.ReadAsByteArrayAsync(cancellationToken).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Voice progress speech failed");
            return null;
        }
    }
}
