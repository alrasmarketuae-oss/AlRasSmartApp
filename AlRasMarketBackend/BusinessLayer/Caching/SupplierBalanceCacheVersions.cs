namespace BusinessLayer.Caching;

/// <summary>Bumps supplier balance cache keys (RAM + Redis via TieredCache key versioning).</summary>
public static class SupplierBalanceCacheVersions
{
    private static readonly System.Collections.Concurrent.ConcurrentDictionary<Guid, long> Versions = new();

    public static long Current(Guid userId) =>
        Versions.TryGetValue(userId, out var version) ? version : 0;

    public static void Bump(Guid userId) =>
        Versions.AddOrUpdate(userId, 1, static (_, current) => current + 1);
}
