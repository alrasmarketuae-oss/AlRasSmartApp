using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class MissedProductSearchAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache) : IMissedProductSearchAppService
{
    private static int _listCacheVersion;

    public static void InvalidateListCache() => Interlocked.Increment(ref _listCacheVersion);

    public async Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        DateTime? fromUtc,
        DateTime? toUtc,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var searchTerm = search?.Trim();
        var from = NormalizeUtc(fromUtc);
        var to = NormalizeUtc(toUtc);

        var cacheKey =
            $"admin:missed-product-searches:v{_listCacheVersion}:p{page}:s{pageSize}:q{searchTerm}:f{from:O}:t{to:O}";

        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var query = dbContext.MissedProductSearches.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLowerInvariant();
            query = query.Where(x =>
                x.QueryText.ToLower().Contains(term)
                || (x.UserDisplayName != null && x.UserDisplayName.ToLower().Contains(term))
                || (x.UserEmail != null && x.UserEmail.ToLower().Contains(term))
                || (x.UserPhone != null && x.UserPhone.ToLower().Contains(term)));
        }

        if (from.HasValue)
        {
            query = query.Where(x => x.CreatedAtUtc >= from.Value);
        }

        if (to.HasValue)
        {
            query = query.Where(x => x.CreatedAtUtc <= to.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                id = x.Id.ToString("D"),
                queryText = x.QueryText,
                userId = x.UserId.HasValue ? x.UserId.Value.ToString("D") : null,
                userDisplayName = x.UserDisplayName,
                userEmail = x.UserEmail,
                userPhone = x.UserPhone,
                notes = x.Notes,
                createdAtUtc = x.CreatedAtUtc
            })
            .ToListAsync(cancellationToken);

        var utcNow = DateTime.UtcNow;
        var result = new
        {
            page,
            pageSize,
            totalCount,
            totalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            serverUtcNow = utcNow,
            items = items.Select(x => new
            {
                x.id,
                x.queryText,
                x.userId,
                x.userDisplayName,
                x.userEmail,
                x.userPhone,
                x.notes,
                x.createdAtUtc,
                ageSeconds = Math.Max(
                    0,
                    (int)(utcNow - DateTime.SpecifyKind(x.createdAtUtc, DateTimeKind.Utc)).TotalSeconds)
            }).ToList()
        };

        cache.Set(cacheKey, result, TimeSpan.FromSeconds(45));
        return result;
    }

    private static DateTime? NormalizeUtc(DateTime? value)
    {
        if (value is null) return null;
        return value.Value.Kind switch
        {
            DateTimeKind.Utc => value.Value,
            DateTimeKind.Local => value.Value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value.Value, DateTimeKind.Utc)
        };
    }
}
