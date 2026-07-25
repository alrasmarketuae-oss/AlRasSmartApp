using System.Security.Claims;
using System.Text.Json;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class AdminAuditLogAppService(
    IRasAlSouqDbContext dbContext,
    IHttpContextAccessor httpContextAccessor,
    IMemoryCache cache) : IAdminAuditLogAppService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false
    };

    private static int _listCacheVersion;

    public async Task WriteAsync(
        string action,
        string entityType,
        string? entityId,
        string summary,
        object? details = null,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(action) || string.IsNullOrWhiteSpace(entityType))
        {
            return;
        }

        var actorUserId = ResolveActorUserId();
        if (actorUserId is null)
        {
            return;
        }

        var actorName = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == actorUserId.Value)
            .Select(x => x.FullName)
            .FirstOrDefaultAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(actorName))
        {
            actorName = "Unknown";
        }

        string? detailsJson = null;
        if (details is not null)
        {
            detailsJson = details is string s
                ? s
                : JsonSerializer.Serialize(details, JsonOptions);
        }

        dbContext.AdminAuditLogs.Add(new AdminAuditLog
        {
            Id = Guid.NewGuid(),
            ActorUserId = actorUserId.Value,
            ActorName = actorName.Trim(),
            Action = action.Trim(),
            EntityType = entityType.Trim(),
            EntityId = string.IsNullOrWhiteSpace(entityId) ? null : entityId.Trim(),
            Summary = Truncate(summary.Trim(), 500),
            DetailsJson = detailsJson,
            CreatedAtUtc = DateTime.UtcNow
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        Interlocked.Increment(ref _listCacheVersion);
    }

    public async Task<object> GetPagedAsync(
        int page,
        int pageSize,
        string? search,
        string? action,
        string? entityType,
        DateTime? fromUtc,
        DateTime? toUtc,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var searchTerm = search?.Trim();
        var actionFilter = action?.Trim();
        var entityFilter = entityType?.Trim();
        var from = NormalizeUtc(fromUtc);
        var to = NormalizeUtc(toUtc);

        var cacheKey =
            $"admin:audit-logs:v{_listCacheVersion}:p{page}:s{pageSize}:q{searchTerm}:a{actionFilter}:e{entityFilter}:f{from:O}:t{to:O}";

        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var query = dbContext.AdminAuditLogs.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var term = searchTerm.ToLowerInvariant();
            query = query.Where(x =>
                x.ActorName.ToLower().Contains(term)
                || x.Summary.ToLower().Contains(term)
                || (x.EntityId != null && x.EntityId.ToLower().Contains(term))
                || x.Action.ToLower().Contains(term));
        }

        if (!string.IsNullOrWhiteSpace(actionFilter))
        {
            query = query.Where(x => x.Action == actionFilter);
        }

        if (!string.IsNullOrWhiteSpace(entityFilter))
        {
            query = query.Where(x => x.EntityType == entityFilter);
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
                actorUserId = x.ActorUserId.ToString("D"),
                actorName = x.ActorName,
                action = x.Action,
                entityType = x.EntityType,
                entityId = x.EntityId,
                summary = x.Summary,
                detailsJson = x.DetailsJson,
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
                x.actorUserId,
                x.actorName,
                x.action,
                x.entityType,
                x.entityId,
                x.summary,
                x.detailsJson,
                x.createdAtUtc,
                ageSeconds = Math.Max(0, (int)(utcNow - DateTime.SpecifyKind(x.createdAtUtc, DateTimeKind.Utc)).TotalSeconds)
            }).ToList()
        };

        cache.Set(cacheKey, result, TimeSpan.FromSeconds(45));
        return result;
    }

    private Guid? ResolveActorUserId()
    {
        var user = httpContextAccessor.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        var raw = user.FindFirst("EntityId")?.Value
            ?? user.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? user.FindFirst("sub")?.Value;

        return Guid.TryParse(raw, out var id) ? id : null;
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

    private static string Truncate(string value, int max)
        => value.Length <= max ? value : value[..max];
}
