using System.Text.Json;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace BusinessLayer.Services;

public sealed class RedisStreamOrderOfferAutoModerationQueue : IOrderOfferAutoModerationQueue
{
    private const string RelativeStream = "order:offer-auto-moderation";
    private const string Group = "order-offer-auto-moderation-workers";
    private const string Field = "payload";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly IDatabase _db;
    private readonly string _streamKey;
    private readonly string _consumerName;
    private readonly ILogger<RedisStreamOrderOfferAutoModerationQueue> _logger;
    private int _groupReady;

    public RedisStreamOrderOfferAutoModerationQueue(
        IConnectionMultiplexer redis,
        IOptions<RedisOptions> options,
        ILogger<RedisStreamOrderOfferAutoModerationQueue> logger)
    {
        _db = redis.GetDatabase();
        _streamKey = $"{options.Value.InstanceName}{RelativeStream}";
        _consumerName = $"{Environment.MachineName}-{Environment.ProcessId}-om";
        _logger = logger;
    }

    public async ValueTask EnqueueAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        await EnsureGroupAsync().ConfigureAwait(false);
        var payload = JsonSerializer.Serialize(workItem, JsonOptions);
        await _db.StreamAddAsync(_streamKey, Field, payload).ConfigureAwait(false);
    }

    public async ValueTask<QueuedWorkItem<OrderOfferAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken)
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

    private async Task<QueuedWorkItem<OrderOfferAutoModerationWorkItem>?> TryAutoClaimAsync()
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

    private QueuedWorkItem<OrderOfferAutoModerationWorkItem>? ParseEntry(StreamEntry entry)
    {
        var raw = entry.Values.FirstOrDefault(v => v.Name == Field).Value;
        if (raw.IsNullOrEmpty)
        {
            return null;
        }

        var item = JsonSerializer.Deserialize<OrderOfferAutoModerationWorkItem>((string)raw!, JsonOptions);
        return item is null ? null : new QueuedWorkItem<OrderOfferAutoModerationWorkItem>(entry.Id!, item);
    }
}
