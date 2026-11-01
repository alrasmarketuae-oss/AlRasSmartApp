using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

/// <summary>
/// Logout and password changes bump <see cref="DataLayer.Models.User.AuthStamp"/>.
/// A token stays valid only while its "ver" claim matches the stored stamp.
/// </summary>
public sealed class AuthSessionGuard(IRasAlSouqDbContext dbContext, IMemoryCache cache)
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(20);

    public async Task<int?> GetStampAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var key = CacheKey(userId);
        if (cache.TryGetValue(key, out int cached))
        {
            return cached;
        }

        var stamp = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => (int?)x.AuthStamp)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (stamp is null)
        {
            return null;
        }

        cache.Set(key, stamp.Value, CacheTtl);
        return stamp;
    }

    public async Task RevokeAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            .ConfigureAwait(false);
        if (user is null)
        {
            cache.Remove(CacheKey(userId));
            return;
        }

        user.AuthStamp++;
        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
        cache.Set(CacheKey(userId), user.AuthStamp, CacheTtl);
    }

    public void Remember(Guid userId, int stamp) => cache.Set(CacheKey(userId), stamp, CacheTtl);

    private static string CacheKey(Guid userId) => $"auth-stamp:{userId:D}";
}
