using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>Resolves a visitor IP to an ISO country code (e.g. "EG", "AE"), cached per IP.</summary>
public sealed class NasserGeoLocator(HttpClient http, IMemoryCache cache, ILogger<NasserGeoLocator> logger)
{
    private static readonly TimeSpan CacheFor = TimeSpan.FromHours(24);

    public async Task<string?> CountryAsync(string? ip, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(ip) || !IPAddress.TryParse(ip, out var parsed) || IPAddress.IsLoopback(parsed))
        {
            return null;
        }

        var key = $"nasser-geo:{ip}";
        if (cache.TryGetValue(key, out string? cached))
        {
            return cached;
        }

        var country = await TryIpApiAsync(ip, cancellationToken) ?? await TryIpWhoAsync(ip, cancellationToken);
        cache.Set(key, country, country is null ? TimeSpan.FromMinutes(10) : CacheFor);
        return country;
    }

    private async Task<string?> TryIpApiAsync(string ip, CancellationToken ct)
    {
        try
        {
            var text = (await http.GetStringAsync($"https://ipapi.co/{ip}/country/", ct)).Trim();
            return IsCode(text) ? text.ToUpperInvariant() : null;
        }
        catch (Exception ex) when (ex is not OperationCanceledException || !ct.IsCancellationRequested)
        {
            logger.LogDebug(ex, "ipapi.co lookup failed for {Ip}", ip);
            return null;
        }
    }

    private async Task<string?> TryIpWhoAsync(string ip, CancellationToken ct)
    {
        try
        {
            await using var stream = await http.GetStreamAsync($"https://ipwho.is/{ip}?fields=success,country_code", ct);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
            return doc.RootElement.TryGetProperty("country_code", out var code) && IsCode(code.GetString())
                ? code.GetString()!.ToUpperInvariant()
                : null;
        }
        catch (Exception ex) when (ex is not OperationCanceledException || !ct.IsCancellationRequested)
        {
            logger.LogDebug(ex, "ipwho.is lookup failed for {Ip}", ip);
            return null;
        }
    }

    private static bool IsCode(string? value) =>
        value is { Length: 2 } && char.IsAsciiLetter(value[0]) && char.IsAsciiLetter(value[1]);
}
