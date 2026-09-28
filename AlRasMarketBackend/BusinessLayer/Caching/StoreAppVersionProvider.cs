using System.Text.Json;
using System.Text.RegularExpressions;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Caching;

/// <summary>
/// Reads the live store versions so update prompts work without manual admin input.
/// iOS uses the public iTunes lookup API; Google Play has no public API, so the
/// version is parsed from the store page. Results are cached; failures keep the
/// last known value.
/// </summary>
public sealed partial class StoreAppVersionProvider(
    IHttpClientFactory httpClientFactory,
    ILogger<StoreAppVersionProvider> logger) : IStoreAppVersionProvider
{
    public const string HttpClientName = nameof(StoreAppVersionProvider);

    private static readonly TimeSpan CacheDuration = TimeSpan.FromHours(1);
    private static readonly TimeSpan FailureRetryAfter = TimeSpan.FromMinutes(10);

    private readonly SemaphoreSlim _lock = new(1, 1);
    private StoreAppVersions _cached = new(null, null);
    private DateTime _refreshAfterUtc = DateTime.MinValue;

    public async Task<StoreAppVersions> GetAsync(
        string androidStoreUrl,
        string iosStoreUrl,
        CancellationToken cancellationToken = default)
    {
        if (DateTime.UtcNow < _refreshAfterUtc)
        {
            return _cached;
        }

        await _lock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (DateTime.UtcNow < _refreshAfterUtc)
            {
                return _cached;
            }

            var androidTask = FetchAndroidVersionAsync(androidStoreUrl, cancellationToken);
            var iosTask = FetchIosVersionAsync(iosStoreUrl, cancellationToken);
            await Task.WhenAll(androidTask, iosTask).ConfigureAwait(false);

            var android = androidTask.Result ?? _cached.AndroidVersion;
            var ios = iosTask.Result ?? _cached.IosVersion;
            _cached = new StoreAppVersions(android, ios);
            _refreshAfterUtc = DateTime.UtcNow +
                (androidTask.Result is null || iosTask.Result is null ? FailureRetryAfter : CacheDuration);
            return _cached;
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task<string?> FetchIosVersionAsync(string storeUrl, CancellationToken cancellationToken)
    {
        var appId = IosAppIdRegex().Match(storeUrl);
        if (!appId.Success)
        {
            return null;
        }

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            var url = $"https://itunes.apple.com/lookup?id={appId.Groups[1].Value}&t={DateTime.UtcNow.Ticks}";
            await using var stream = await client.GetStreamAsync(url, cancellationToken).ConfigureAwait(false);
            using var json = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken)
                .ConfigureAwait(false);
            if (json.RootElement.TryGetProperty("results", out var results) &&
                results.ValueKind == JsonValueKind.Array &&
                results.GetArrayLength() > 0 &&
                results[0].TryGetProperty("version", out var version))
            {
                return NormalizeVersion(version.GetString());
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException || !cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning(ex, "Failed to read App Store version");
        }

        return null;
    }

    private async Task<string?> FetchAndroidVersionAsync(string storeUrl, CancellationToken cancellationToken)
    {
        var packageId = AndroidPackageRegex().Match(storeUrl);
        if (!packageId.Success)
        {
            return null;
        }

        try
        {
            var client = httpClientFactory.CreateClient(HttpClientName);
            var url = $"https://play.google.com/store/apps/details?id={packageId.Groups[1].Value}&hl=en&gl=us";
            var html = await client.GetStringAsync(url, cancellationToken).ConfigureAwait(false);
            var match = PlayVersionRegex().Match(html);
            return match.Success ? NormalizeVersion(match.Groups[1].Value) : null;
        }
        catch (Exception ex) when (ex is not OperationCanceledException || !cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning(ex, "Failed to read Google Play version");
        }

        return null;
    }

    private static string? NormalizeVersion(string? value)
    {
        var trimmed = value?.Trim();
        return string.IsNullOrWhiteSpace(trimmed) ? null : trimmed;
    }

    [GeneratedRegex(@"/id(\d+)", RegexOptions.IgnoreCase)]
    private static partial Regex IosAppIdRegex();

    [GeneratedRegex(@"[?&]id=([\w.]+)", RegexOptions.IgnoreCase)]
    private static partial Regex AndroidPackageRegex();

    [GeneratedRegex(@"\[\[\[""(\d+(?:\.\d+)+)""\]\]")]
    private static partial Regex PlayVersionRegex();
}
