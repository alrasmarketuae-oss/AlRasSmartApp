using System.Collections.Concurrent;

namespace BusinessLayer.Caching;

/// <summary>Per-user version for invalidating cached address lists.</summary>
public static class UserAddressesCache
{
    private static readonly ConcurrentDictionary<Guid, int> Versions = new();

    public static int GetVersion(Guid userId) =>
        Versions.TryGetValue(userId, out var version) ? version : 0;

    public static void Bump(Guid userId) =>
        Versions.AddOrUpdate(userId, 1, static (_, current) => current + 1);
}
