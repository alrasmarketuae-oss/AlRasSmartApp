using System.Collections.Concurrent;

namespace BusinessLayer.Caching;

/// <summary>
/// Per-user version counter so notification list / unread caches invalidate after writes.
/// </summary>
public static class NotificationCacheVersions
{
    private static readonly ConcurrentDictionary<Guid, long> Versions = new();

    public static long Get(Guid userId) => Versions.GetOrAdd(userId, 0);

    public static void Bump(Guid userId) =>
        Versions.AddOrUpdate(userId, 1, static (_, current) => current + 1);
}
