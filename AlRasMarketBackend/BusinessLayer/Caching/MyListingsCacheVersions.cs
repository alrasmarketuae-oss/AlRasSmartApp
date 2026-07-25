using System.Collections.Concurrent;

namespace BusinessLayer.Caching;

/// <summary>
/// Per-owner version counter so "my listings" cache invalidates after product mutations.
/// </summary>
public static class MyListingsCacheVersions
{
    private static readonly ConcurrentDictionary<Guid, long> Versions = new();

    public static long Get(Guid ownerId) => Versions.GetOrAdd(ownerId, 0);

    public static void Bump(Guid ownerId) =>
        Versions.AddOrUpdate(ownerId, 1, static (_, current) => current + 1);
}
