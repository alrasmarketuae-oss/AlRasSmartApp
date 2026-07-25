using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace BusinessLayer.Caching;

/// <summary>
/// Version counters embedded in product cache keys. Local + Redis so multi-instance
/// invalidation is shared; Redis lag is refreshed every few seconds.
/// </summary>
public sealed class ProductCacheVersions
{
    public const int All = 0;
    public const int Featured = 1;
    public const int ByType = 2;
    public const int ByCategory = 3;
    public const int SearchNameIndex = 4;
    public const int Search = 5;
    public const int Detail = 6;
    private const int Count = 7;

    private static readonly string[] RedisKeys =
    [
        "products:ver:all",
        "products:ver:featured",
        "products:ver:by-type",
        "products:ver:by-category",
        "products:ver:search-names",
        "products:ver:search",
        "products:ver:detail"
    ];

    private readonly int[] local = new int[Count];
    private readonly int[] remote = new int[Count];
    private readonly object syncLock = new();
    private readonly IConnectionMultiplexer? redis;
    private readonly RedisOptions options;
    private readonly ILogger<ProductCacheVersions> logger;
    private long lastRemoteSyncTicks;

    public static ProductCacheVersions? Current { get; private set; }

    public ProductCacheVersions(
        IOptions<RedisOptions> options,
        ILogger<ProductCacheVersions> logger,
        IConnectionMultiplexer? redis = null)
    {
        this.options = options.Value;
        this.logger = logger;
        this.redis = redis;
        Current = this;
        _ = Task.Run(WarmRemoteAsync);
    }

    public int Get(int kind)
    {
        MaybeSyncFromRedis();
        var index = Clamp(kind);
        return Math.Max(
            Volatile.Read(ref local[index]),
            Volatile.Read(ref remote[index]));
    }

    public void BumpAll()
    {
        for (var i = 0; i < Count; i++)
        {
            Interlocked.Increment(ref local[i]);
        }

        _ = Task.Run(() => BumpRedisAsync(Enumerable.Range(0, Count).ToArray()));
    }

    public void BumpDetail()
    {
        Interlocked.Increment(ref local[Detail]);
        _ = Task.Run(() => BumpRedisAsync([Detail]));
    }

    public void BumpListViews()
    {
        Interlocked.Increment(ref local[All]);
        Interlocked.Increment(ref local[Featured]);
        Interlocked.Increment(ref local[ByType]);
        Interlocked.Increment(ref local[ByCategory]);
        Interlocked.Increment(ref local[Detail]);
        _ = Task.Run(() => BumpRedisAsync([All, Featured, ByType, ByCategory, Detail]));
    }

    private async Task WarmRemoteAsync()
    {
        try
        {
            await SyncFromRedisAsync().ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "Initial product cache version sync skipped");
        }
    }

    private void MaybeSyncFromRedis()
    {
        var now = Environment.TickCount64;
        if (now - Interlocked.Read(ref lastRemoteSyncTicks) < 2000)
        {
            return;
        }

        lock (syncLock)
        {
            if (Environment.TickCount64 - lastRemoteSyncTicks < 2000)
            {
                return;
            }

            lastRemoteSyncTicks = Environment.TickCount64;
        }

        _ = Task.Run(SyncFromRedisAsync);
    }

    private async Task SyncFromRedisAsync()
    {
        if (!options.Enabled || redis is null || !redis.IsConnected)
        {
            return;
        }

        try
        {
            var db = redis.GetDatabase();
            var values = await db.StringGetAsync(
                    RedisKeys.Select(k => (RedisKey)Prefixed(k)).ToArray())
                .ConfigureAwait(false);

            for (var i = 0; i < Count && i < values.Length; i++)
            {
                if (values[i].IsNullOrEmpty)
                {
                    continue;
                }

                if (int.TryParse((string?)values[i], out var parsed) && parsed > 0)
                {
                    Volatile.Write(ref remote[i], parsed);
                }
            }

            Interlocked.Exchange(ref lastRemoteSyncTicks, Environment.TickCount64);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to sync product cache versions from Redis");
        }
    }

    private async Task BumpRedisAsync(IReadOnlyList<int> kinds)
    {
        if (!options.Enabled || redis is null || !redis.IsConnected)
        {
            return;
        }

        try
        {
            var db = redis.GetDatabase();
            foreach (var kind in kinds)
            {
                var index = Clamp(kind);
                var value = await db.StringIncrementAsync(Prefixed(RedisKeys[index]))
                    .ConfigureAwait(false);
                Volatile.Write(ref remote[index], (int)Math.Min(value, int.MaxValue));
            }

            Interlocked.Exchange(ref lastRemoteSyncTicks, Environment.TickCount64);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to bump product cache versions in Redis");
        }
    }

    private string Prefixed(string key) =>
        string.IsNullOrWhiteSpace(options.InstanceName)
            ? key
            : options.InstanceName + key;

    private static int Clamp(int kind) =>
        kind < 0 || kind >= Count ? All : kind;
}
