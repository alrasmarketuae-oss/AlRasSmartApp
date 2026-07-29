using System.Text.Json;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace BusinessLayer.Services;

/// <summary>
/// Durable product background work via Redis Streams + consumer groups.
/// Survives API restarts and supports multiple API instances sharing one queue.
/// </summary>
public sealed class RedisStreamProductTranslationQueue : IProductTranslationQueue
{
    private const string RelativeStream = "product:translate";
    private const string Group = "translation-workers";
    private const string Field = "payload";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly IDatabase _db;
    private readonly string _streamKey;
    private readonly string _consumerName;
    private readonly ILogger<RedisStreamProductTranslationQueue> _logger;
    private int _groupReady;

    public RedisStreamProductTranslationQueue(
        IConnectionMultiplexer redis,
        IOptions<RedisOptions> options,
        ILogger<RedisStreamProductTranslationQueue> logger)
    {
        _db = redis.GetDatabase();
        _streamKey = $"{options.Value.InstanceName}{RelativeStream}";
        _consumerName = $"{Environment.MachineName}-{Environment.ProcessId}-tr";
        _logger = logger;
    }

    public async ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        await EnsureGroupAsync().ConfigureAwait(false);

        var payload = JsonSerializer.Serialize(workItem, JsonOptions);
        await _db.StreamAddAsync(_streamKey, Field, payload).ConfigureAwait(false);
    }

    public async ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken)
    {
        await EnsureGroupAsync().ConfigureAwait(false);

        while (!cancellationToken.IsCancellationRequested)
        {
            var claimed = await TryAutoClaimAsync().ConfigureAwait(false);
            if (claimed is not null)
            {
                return claimed;
            }

            var entries = await _db.StreamReadGroupAsync(
                    _streamKey,
                    Group,
                    _consumerName,
                    position: ">",
                    count: 1)
                .ConfigureAwait(false);

            if (entries is { Length: > 0 })
            {
                var parsed = ParseEntry(entries[0]);
                if (parsed is not null)
                {
                    return parsed;
                }
            }

            await Task.Delay(400, cancellationToken).ConfigureAwait(false);
        }

        throw new OperationCanceledException(cancellationToken);
    }

    public async ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(messageId))
        {
            return;
        }

        cancellationToken.ThrowIfCancellationRequested();
        await _db.StreamAcknowledgeAsync(_streamKey, Group, messageId).ConfigureAwait(false);
    }

    private async Task EnsureGroupAsync()
    {
        if (Interlocked.CompareExchange(ref _groupReady, 1, 0) == 1)
        {
            return;
        }

        try
        {
            await _db.StreamCreateConsumerGroupAsync(_streamKey, Group, "0-0", createStream: true)
                .ConfigureAwait(false);
            _logger.LogInformation("Redis stream consumer group ready: {Stream}/{Group}", _streamKey, Group);
        }
        catch (RedisServerException ex) when (ex.Message.Contains("BUSYGROUP", StringComparison.OrdinalIgnoreCase))
        {
            // already exists
        }
        catch
        {
            Interlocked.Exchange(ref _groupReady, 0);
            throw;
        }
    }

    private async Task<QueuedWorkItem<ProductBackgroundWorkItem>?> TryAutoClaimAsync()
    {
        try
        {
            var result = await _db.StreamAutoClaimAsync(
                    _streamKey,
                    Group,
                    _consumerName,
                    minIdleTimeInMs: 300_000,
                    startAtId: "0-0",
                    count: 1)
                .ConfigureAwait(false);

            if (result.ClaimedEntries is { Length: > 0 })
            {
                return ParseEntry(result.ClaimedEntries[0]);
            }
        }
        catch (RedisServerException)
        {
            // Redis < 6.2 or empty PEL — ignore
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "XAUTOCLAIM skipped on {Stream}", _streamKey);
        }

        return null;
    }

    private QueuedWorkItem<ProductBackgroundWorkItem>? ParseEntry(StreamEntry entry)
    {
        var raw = entry.Values.FirstOrDefault(v => v.Name == Field).Value;
        if (raw.IsNullOrEmpty)
        {
            return null;
        }

        var item = JsonSerializer.Deserialize<ProductBackgroundWorkItem>((string)raw!, JsonOptions);
        if (item is null)
        {
            return null;
        }

        return new QueuedWorkItem<ProductBackgroundWorkItem>(entry.Id!, item);
    }
}

public sealed class RedisStreamProductImageIndexingQueue : IProductImageIndexingQueue
{
    private const string RelativeStream = "product:clip";
    private const string Group = "clip-workers";
    private const string Field = "imageId";

    private readonly IDatabase _db;
    private readonly string _streamKey;
    private readonly string _consumerName;
    private readonly ILogger<RedisStreamProductImageIndexingQueue> _logger;
    private int _groupReady;

    public RedisStreamProductImageIndexingQueue(
        IConnectionMultiplexer redis,
        IOptions<RedisOptions> options,
        ILogger<RedisStreamProductImageIndexingQueue> logger)
    {
        _db = redis.GetDatabase();
        _streamKey = $"{options.Value.InstanceName}{RelativeStream}";
        _consumerName = $"{Environment.MachineName}-{Environment.ProcessId}-clip";
        _logger = logger;
    }

    public async ValueTask EnqueueAsync(long productImageId, CancellationToken cancellationToken = default)
    {
        if (productImageId <= 0)
        {
            return;
        }

        cancellationToken.ThrowIfCancellationRequested();
        await EnsureGroupAsync().ConfigureAwait(false);
        await _db.StreamAddAsync(_streamKey, Field, productImageId.ToString()).ConfigureAwait(false);
    }

    public async ValueTask<QueuedWorkItem<long>> DequeueAsync(CancellationToken cancellationToken)
    {
        await EnsureGroupAsync().ConfigureAwait(false);

        while (!cancellationToken.IsCancellationRequested)
        {
            var claimed = await TryAutoClaimAsync().ConfigureAwait(false);
            if (claimed is not null)
            {
                return claimed;
            }

            var entries = await _db.StreamReadGroupAsync(
                    _streamKey,
                    Group,
                    _consumerName,
                    position: ">",
                    count: 1)
                .ConfigureAwait(false);

            if (entries is { Length: > 0 })
            {
                var parsed = ParseEntry(entries[0]);
                if (parsed is not null)
                {
                    return parsed;
                }
            }

            await Task.Delay(400, cancellationToken).ConfigureAwait(false);
        }

        throw new OperationCanceledException(cancellationToken);
    }

    public async ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(messageId))
        {
            return;
        }

        cancellationToken.ThrowIfCancellationRequested();
        await _db.StreamAcknowledgeAsync(_streamKey, Group, messageId).ConfigureAwait(false);
    }

    private async Task EnsureGroupAsync()
    {
        if (Interlocked.CompareExchange(ref _groupReady, 1, 0) == 1)
        {
            return;
        }

        try
        {
            await _db.StreamCreateConsumerGroupAsync(_streamKey, Group, "0-0", createStream: true)
                .ConfigureAwait(false);
            _logger.LogInformation("Redis stream consumer group ready: {Stream}/{Group}", _streamKey, Group);
        }
        catch (RedisServerException ex) when (ex.Message.Contains("BUSYGROUP", StringComparison.OrdinalIgnoreCase))
        {
            // already exists
        }
        catch
        {
            Interlocked.Exchange(ref _groupReady, 0);
            throw;
        }
    }

    private async Task<QueuedWorkItem<long>?> TryAutoClaimAsync()
    {
        try
        {
            var result = await _db.StreamAutoClaimAsync(
                    _streamKey,
                    Group,
                    _consumerName,
                    minIdleTimeInMs: 300_000,
                    startAtId: "0-0",
                    count: 1)
                .ConfigureAwait(false);

            if (result.ClaimedEntries is { Length: > 0 })
            {
                return ParseEntry(result.ClaimedEntries[0]);
            }
        }
        catch (RedisServerException)
        {
            // ignore
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "XAUTOCLAIM skipped on {Stream}", _streamKey);
        }

        return null;
    }

    private static QueuedWorkItem<long>? ParseEntry(StreamEntry entry)
    {
        var raw = entry.Values.FirstOrDefault(v => v.Name == Field).Value;
        if (raw.IsNullOrEmpty || !long.TryParse((string)raw!, out var imageId) || imageId <= 0)
        {
            return null;
        }

        return new QueuedWorkItem<long>(entry.Id!, imageId);
    }
}
