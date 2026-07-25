namespace BusinessLayer.Interfaces;

/// <summary>
/// Two-tier cache: process memory first, then Redis, then caller loads from DB.
/// </summary>
public interface ITieredCache
{
    Task<object?> GetAsync(string key, CancellationToken cancellationToken = default);

    Task SetAsync(
        string key,
        object value,
        TimeSpan absoluteExpiration,
        CancellationToken cancellationToken = default);

    bool IsRedisConnected { get; }
}
