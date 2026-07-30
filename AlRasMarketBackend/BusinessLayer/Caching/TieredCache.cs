using System.Text.Json;
using System.Text.Json.Serialization;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace BusinessLayer.Caching;

public sealed class TieredCache : ITieredCache
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private readonly IMemoryCache memoryCache;
    private readonly IConnectionMultiplexer? redis;
    private readonly RedisOptions options;
    private readonly ILogger<TieredCache> logger;

    public TieredCache(
        IMemoryCache memoryCache,
        IOptions<RedisOptions> options,
        ILogger<TieredCache> logger,
        IConnectionMultiplexer? redis = null)
    {
        this.memoryCache = memoryCache;
        this.options = options.Value;
        this.logger = logger;
        this.redis = redis;
    }

    public bool IsRedisConnected =>
        options.Enabled && redis is not null && redis.IsConnected;

    public async Task<object?> GetAsync(string key, CancellationToken cancellationToken = default)
    {
        if (memoryCache.TryGetValue(key, out object? memoryValue) && memoryValue is not null)
        {
            return memoryValue;
        }

        if (!IsRedisConnected || redis is null)
        {
            return null;
        }

        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            var db = redis.GetDatabase();
            var redisKey = Prefixed(key);
            var payload = await db.StringGetAsync(redisKey).ConfigureAwait(false);
            if (payload.IsNullOrEmpty)
            {
                return null;
            }

            var element = JsonSerializer.Deserialize<JsonElement>((string)payload!);
            var ttl = await db.KeyTimeToLiveAsync(redisKey).ConfigureAwait(false);
            var memoryTtl = ttl is { } remaining && remaining > TimeSpan.Zero
                ? remaining
                : TimeSpan.FromMinutes(2);
            memoryCache.Set(key, element, memoryTtl);
            return element;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Redis GET failed for {CacheKey}; falling through to DB path", key);
            return null;
        }
    }

    public async Task SetAsync(
        string key,
        object value,
        TimeSpan absoluteExpiration,
        CancellationToken cancellationToken = default)
    {
        memoryCache.Set(key, value, absoluteExpiration);

        if (!IsRedisConnected || redis is null)
        {
            return;
        }

        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            var json = JsonSerializer.Serialize(value, JsonOptions);
            var db = redis.GetDatabase();
            await db.StringSetAsync(Prefixed(key), json, absoluteExpiration).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Redis SET failed for {CacheKey}; memory cache still updated", key);
        }
    }

    public async Task RemoveAsync(string key, CancellationToken cancellationToken = default)
    {
        memoryCache.Remove(key);

        if (!IsRedisConnected || redis is null)
        {
            return;
        }

        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            await redis.GetDatabase().KeyDeleteAsync(Prefixed(key)).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Redis DELETE failed for {CacheKey}", key);
        }
    }

    private string Prefixed(string key) =>
        string.IsNullOrWhiteSpace(options.InstanceName)
            ? key
            : options.InstanceName + key;
}
