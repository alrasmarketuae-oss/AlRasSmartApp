using System.Diagnostics;
using System.Globalization;
using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace BusinessLayer.Services;

public sealed class AdminMonitoringAppService(
    HttpClient http,
    ILogger<AdminMonitoringAppService> logger,
    IServiceProvider services) : IAdminMonitoringAppService
{
    private const string QHttp = "sum(rate(http_requests_received_total[5m]))";
    private const string Q5xx = "sum(rate(http_requests_received_total{code=~\"5..\"}[5m]))";
    private const string Qp95 =
        "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))";
    private const string Qp50 =
        "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))";
    private const string QRedisUp = "redis_up";
    private const string QRedisMem = "redis_memory_used_bytes";
    private const string QWorkingSet = "process_working_set_bytes";
    private const string QCpu = "rate(process_cpu_seconds_total[1m]) * 100";

    public async Task<AdminMonitoringOverviewDto> GetOverviewAsync(
        string? range,
        CancellationToken cancellationToken = default)
    {
        var window = NormalizeRange(range);
        var now = DateTime.UtcNow;
        var (start, step) = WindowBounds(now, window);

        var dto = new AdminMonitoringOverviewDto
        {
            ServerUtcNow = now,
            Range = window,
        };

        try
        {
            var httpNow = QueryInstantAsync(QHttp, cancellationToken);
            var errNow = QueryInstantAsync(Q5xx, cancellationToken);
            var p95Now = QueryInstantAsync(Qp95, cancellationToken);
            var p50Now = QueryInstantAsync(Qp50, cancellationToken);
            var redisNow = QueryInstantAsync(QRedisUp, cancellationToken);
            var redisMemNow = QueryInstantAsync(QRedisMem, cancellationToken);
            var wsNow = QueryInstantAsync(QWorkingSet, cancellationToken);
            var cpuNow = QueryInstantAsync(QCpu, cancellationToken);
            var httpRange = QueryRangeAsync(QHttp, start, now, step, cancellationToken);
            var errRange = QueryRangeAsync(Q5xx, start, now, step, cancellationToken);
            var p95Range = QueryRangeAsync(Qp95, start, now, step, cancellationToken);
            var p50Range = QueryRangeAsync(Qp50, start, now, step, cancellationToken);
            var targets = QueryTargetsAsync(cancellationToken);

            await Task.WhenAll(
                httpNow, errNow, p95Now, p50Now, redisNow, redisMemNow, wsNow, cpuNow,
                httpRange, errRange, p95Range, p50Range, targets).ConfigureAwait(false);

            dto.PrometheusReachable = targets.Result.Count > 0
                || httpNow.Result is not null
                || redisNow.Result is not null;
            dto.Snapshot = new AdminMonitoringSnapshotDto
            {
                HttpRequestsPerSec = httpNow.Result ?? 0,
                Http5xxPerSec = errNow.Result ?? 0,
                HttpP95Seconds = p95Now.Result ?? 0,
                HttpP50Seconds = p50Now.Result ?? 0,
                RedisUp = (redisNow.Result ?? 0) >= 1,
                RedisMemoryBytes = redisMemNow.Result,
                ApiWorkingSetBytes = wsNow.Result ?? Process.GetCurrentProcess().WorkingSet64,
                ApiCpuPercent = cpuNow.Result,
            };
            dto.Series = new AdminMonitoringSeriesDto
            {
                HttpRequestsPerSec = httpRange.Result,
                Http5xxPerSec = errRange.Result,
                HttpP95Seconds = p95Range.Result,
                HttpP50Seconds = p50Range.Result,
            };
            dto.Targets = targets.Result;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Prometheus monitoring query failed.");
            dto.PrometheusReachable = false;
            dto.Snapshot.ApiWorkingSetBytes = Process.GetCurrentProcess().WorkingSet64;
        }

        if (!dto.Snapshot.RedisUp)
        {
            dto.Snapshot.RedisUp = await TryPingRedisAsync(cancellationToken).ConfigureAwait(false);
        }

        dto.Snapshot.ApiWorkingSetBytes ??= Process.GetCurrentProcess().WorkingSet64;
        return dto;
    }

    private async Task<double?> QueryInstantAsync(string query, CancellationToken ct)
    {
        var path = $"api/v1/query?query={Uri.EscapeDataString(query)}";
        using var doc = await GetJsonAsync(path, ct).ConfigureAwait(false);
        return ReadScalar(doc);
    }

    private async Task<List<AdminMonitoringPointDto>> QueryRangeAsync(
        string query,
        DateTime start,
        DateTime end,
        string step,
        CancellationToken ct)
    {
        var path =
            $"api/v1/query_range?query={Uri.EscapeDataString(query)}" +
            $"&start={ToUnix(start)}&end={ToUnix(end)}&step={Uri.EscapeDataString(step)}";
        using var doc = await GetJsonAsync(path, ct).ConfigureAwait(false);
        return ReadSeries(doc);
    }

    private async Task<List<AdminMonitoringTargetDto>> QueryTargetsAsync(CancellationToken ct)
    {
        using var doc = await GetJsonAsync("api/v1/targets", ct).ConfigureAwait(false);
        var list = new List<AdminMonitoringTargetDto>();
        if (doc is null) return list;
        if (!doc.RootElement.TryGetProperty("data", out var data)) return list;
        if (!data.TryGetProperty("activeTargets", out var targets) ||
            targets.ValueKind != JsonValueKind.Array)
        {
            return list;
        }

        foreach (var item in targets.EnumerateArray())
        {
            var labels = item.TryGetProperty("labels", out var lbl) ? lbl : default;
            list.Add(new AdminMonitoringTargetDto
            {
                Job = ReadString(labels, "job"),
                Instance = ReadString(labels, "instance"),
                Health = item.TryGetProperty("health", out var health)
                    ? health.GetString() ?? "unknown"
                    : "unknown",
            });
        }

        return list;
    }

    private async Task<JsonDocument?> GetJsonAsync(string relativePath, CancellationToken ct)
    {
        try
        {
            using var response = await http.GetAsync(relativePath, ct).ConfigureAwait(false);
            if (!response.IsSuccessStatusCode) return null;
            await using var stream = await response.Content.ReadAsStreamAsync(ct).ConfigureAwait(false);
            return await JsonDocument.ParseAsync(stream, cancellationToken: ct).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "Prometheus request failed: {Path}", relativePath);
            return null;
        }
    }

    private static double? ReadScalar(JsonDocument? doc)
    {
        var sample = FirstResult(doc);
        if (sample is null) return null;
        if (!sample.Value.TryGetProperty("value", out var value) ||
            value.ValueKind != JsonValueKind.Array ||
            value.GetArrayLength() < 2)
        {
            return null;
        }

        return ParseNumber(value[1]);
    }

    private static List<AdminMonitoringPointDto> ReadSeries(JsonDocument? doc)
    {
        var points = new List<AdminMonitoringPointDto>();
        var sample = FirstResult(doc);
        if (sample is null) return points;
        if (!sample.Value.TryGetProperty("values", out var values) ||
            values.ValueKind != JsonValueKind.Array)
        {
            return points;
        }

        foreach (var pair in values.EnumerateArray())
        {
            if (pair.ValueKind != JsonValueKind.Array || pair.GetArrayLength() < 2) continue;
            var unix = pair[0].ValueKind == JsonValueKind.Number ? pair[0].GetDouble() : 0;
            var v = ParseNumber(pair[1]);
            if (v is null) continue;
            points.Add(new AdminMonitoringPointDto
            {
                T = DateTimeOffset.FromUnixTimeMilliseconds((long)(unix * 1000d)).UtcDateTime,
                V = v.Value,
            });
        }

        return points;
    }

    private static JsonElement? FirstResult(JsonDocument? doc)
    {
        if (doc is null) return null;
        if (!doc.RootElement.TryGetProperty("data", out var data)) return null;
        if (!data.TryGetProperty("result", out var result) ||
            result.ValueKind != JsonValueKind.Array ||
            result.GetArrayLength() == 0)
        {
            return null;
        }

        return result[0];
    }

    private static double? ParseNumber(JsonElement el)
    {
        if (el.ValueKind == JsonValueKind.Number && el.TryGetDouble(out var n)) return n;
        if (el.ValueKind == JsonValueKind.String &&
            double.TryParse(el.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed) &&
            !double.IsNaN(parsed) &&
            !double.IsInfinity(parsed))
        {
            return parsed;
        }

        return null;
    }

    private static string ReadString(JsonElement labels, string key)
    {
        if (labels.ValueKind == JsonValueKind.Object &&
            labels.TryGetProperty(key, out var value))
        {
            return value.GetString() ?? string.Empty;
        }

        return string.Empty;
    }

    private async Task<bool> TryPingRedisAsync(CancellationToken ct)
    {
        try
        {
            var mux = services.GetService<IConnectionMultiplexer>();
            if (mux is null || !mux.IsConnected) return false;
            await mux.GetDatabase().PingAsync().WaitAsync(ct).ConfigureAwait(false);
            return true;
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "Redis ping for monitoring failed.");
            return false;
        }
    }

    private static string NormalizeRange(string? range)
    {
        return range?.Trim().ToLowerInvariant() switch
        {
            "6h" => "6h",
            "24h" => "24h",
            _ => "1h",
        };
    }

    private static (DateTime Start, string Step) WindowBounds(DateTime now, string range)
    {
        return range switch
        {
            "6h" => (now.AddHours(-6), "1m"),
            "24h" => (now.AddHours(-24), "5m"),
            _ => (now.AddHours(-1), "15s"),
        };
    }

    private static string ToUnix(DateTime utc) =>
        new DateTimeOffset(DateTime.SpecifyKind(utc, DateTimeKind.Utc))
            .ToUnixTimeSeconds()
            .ToString(CultureInfo.InvariantCulture);
}
