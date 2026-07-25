namespace BusinessLayer.Caching;

/// <summary>
/// Version for invalidating the public categories list cache.
/// </summary>
public static class CategoriesListCache
{
    private static int _version;

    public static int Version => System.Threading.Volatile.Read(ref _version);

    public static void Bump() => System.Threading.Interlocked.Increment(ref _version);
}
