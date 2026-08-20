using System.Collections.Concurrent;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using BusinessLayer.Options;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.AiAssistant.Voice;

/// <summary>
/// Side-channel wait phrases. PCM is cached in-memory after the first TTS
/// synthesis so repeat progress audio costs nothing.
/// </summary>
public sealed class AiVoiceProgressSpeechService(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    IOptions<AiVoiceAgentOptions> options,
    ILogger<AiVoiceProgressSpeechService> logger)
{
    private readonly ConcurrentDictionary<string, byte[]> _pcmCache = new(StringComparer.Ordinal);

    public async Task WarmCacheAsync(
        IEnumerable<string> phrases,
        string voice,
        CancellationToken cancellationToken)
    {
        foreach (var phrase in phrases)
        {
            if (string.IsNullOrWhiteSpace(phrase))
            {
                continue;
            }

            _ = await SynthesizePcmAsync(phrase, voice, cancellationToken).ConfigureAwait(false);
        }
    }

    public async Task<byte[]?> SynthesizePcmAsync(
        string phrase,
        string voice,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(phrase))
        {
            return null;
        }

        var cacheKey = $"{voice.Trim().ToLowerInvariant()}|{phrase.Trim()}";
        if (_pcmCache.TryGetValue(cacheKey, out var cached))
        {
            return cached;
        }

        var apiKey = configuration["OpenAI:ApiKey"];
        if (string.IsNullOrWhiteSpace(apiKey))
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

            var pcm = await response.Content.ReadAsByteArrayAsync(cancellationToken).ConfigureAwait(false);
            if (pcm.Length > 0)
            {
                _pcmCache[cacheKey] = pcm;
                logger.LogInformation(
                    "Voice progress PCM cached voice={Voice} chars={Chars} bytes={Bytes}",
                    voice,
                    phrase.Length,
                    pcm.Length);
            }

            return pcm;
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
