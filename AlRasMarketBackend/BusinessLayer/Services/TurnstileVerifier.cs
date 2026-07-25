using System.Net.Http.Json;
using System.Text.Json.Serialization;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class TurnstileVerifier(
    IHttpClientFactory httpClientFactory,
    IOptions<CloudflareTurnstileOptions> options,
    ILogger<TurnstileVerifier> logger) : ITurnstileVerifier
{
    private const string SiteVerifyUrl =
        "https://challenges.cloudflare.com/turnstile/v0/siteverify";

    public async Task EnsureValidAsync(
        string? token,
        string? remoteIp,
        CancellationToken cancellationToken = default)
    {
        var opts = options.Value;
        if (!opts.IsConfigured)
        {
            logger.LogWarning("Turnstile secret is not configured; skipping verification.");
            return;
        }

        if (string.IsNullOrWhiteSpace(token))
        {
            throw new UnauthorizedAccessException("Human verification is required.");
        }

        var secret = opts.ResolveSecret();
        var client = httpClientFactory.CreateClient(nameof(TurnstileVerifier));

        using var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["secret"] = secret,
            ["response"] = token.Trim(),
            ["remoteip"] = remoteIp?.Trim() ?? string.Empty
        });

        using var response = await client.PostAsync(SiteVerifyUrl, content, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            logger.LogWarning(
                "Turnstile siteverify HTTP {StatusCode}",
                (int)response.StatusCode);
            throw new UnauthorizedAccessException("Human verification failed.");
        }

        var payload = await response.Content.ReadFromJsonAsync<SiteVerifyResponse>(
            cancellationToken: cancellationToken);

        if (payload?.Success != true)
        {
            var codes = payload?.ErrorCodes is { Count: > 0 }
                ? string.Join(", ", payload.ErrorCodes)
                : "unknown";
            logger.LogWarning("Turnstile verification rejected: {Codes}", codes);
            throw new UnauthorizedAccessException("Human verification failed.");
        }
    }

    private sealed class SiteVerifyResponse
    {
        [JsonPropertyName("success")]
        public bool Success { get; set; }

        [JsonPropertyName("error-codes")]
        public List<string>? ErrorCodes { get; set; }
    }
}
