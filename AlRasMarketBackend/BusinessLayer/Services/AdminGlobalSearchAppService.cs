using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class AdminGlobalSearchAppService(
    IRasAlSouqDbContext dbContext,
    IContentTranslationService contentTranslationService) : IAdminGlobalSearchAppService
{
    private const int LimitPerSection = 6;

    public Task<IReadOnlyList<AdminSearchSuggestionDto>> GetSuggestionsAsync(
        string? query,
        int limit = 8,
        CancellationToken cancellationToken = default)
    {
        limit = limit is < 1 or > 20 ? 8 : limit;
        return Task.FromResult(AdminSearchKnowledge.GetSuggestions(query, limit));
    }

    public async Task<AdminGlobalSearchResultDto> SearchAsync(
        string? query,
        CancellationToken cancellationToken = default)
    {
        var trimmed = query?.Trim() ?? string.Empty;
        var terms = AdminSearchKnowledge.ExpandQuery(trimmed).ToList();
        if (trimmed.Length >= 2 && !terms.Contains(trimmed, StringComparer.OrdinalIgnoreCase))
        {
            terms.Insert(0, trimmed.ToLowerInvariant());
        }

        var result = new AdminGlobalSearchResultDto
        {
            Query = trimmed,
            ExpandedTerms = terms,
            PrimaryRoute = string.IsNullOrWhiteSpace(trimmed) ? "/search" : AdminSearchKnowledge.ResolvePrimaryRoute(trimmed),
            Suggestions = AdminSearchKnowledge.GetSuggestions(trimmed, 8)
        };

        if (string.IsNullOrWhiteSpace(trimmed))
        {
            result.Sections = BuildSectionHits(trimmed, terms);
            return result;
        }

        result.Ads = await SearchAdsAsync(terms, cancellationToken);
        result.Users = await SearchUsersAsync(terms, cancellationToken);
        result.Orders = await SearchOrdersAsync(terms, cancellationToken);
        result.Shipping = await SearchShippingAsync(terms, cancellationToken);
        result.Categories = await SearchCategoriesAsync(terms, cancellationToken);
        result.Sections = BuildSectionHits(trimmed, terms);

        return result;
    }

    private static AdminGlobalSearchSectionDto BuildSectionHits(string query, IReadOnlyList<string> terms)
    {
        var hits = AdminSearchKnowledge.Clusters
            .Select(cluster =>
            {
                var score = string.IsNullOrWhiteSpace(query)
                    ? 1
                    : AdminSearchKnowledge.ScoreCluster(query, cluster);

                return new { cluster, score };
            })
            .Where(x => x.score > 0)
            .OrderByDescending(x => x.score)
            .Take(8)
            .Select(x => new AdminGlobalSearchHitDto
            {
                Id = x.cluster.Id,
                Title = x.cluster.LabelEn,
                Subtitle = x.cluster.LabelAr,
                Route = AdminSearchKnowledge.BuildSectionRoute(x.cluster.Route, query),
                Meta = x.cluster.Section
            })
            .ToList();

        return new AdminGlobalSearchSectionDto
        {
            Section = "sections",
            Route = "/search",
            Total = hits.Count,
            Items = hits
        };
    }

    private async Task<AdminGlobalSearchSectionDto> SearchAdsAsync(
        IReadOnlyList<string> terms,
        CancellationToken cancellationToken)
    {
        var ids = await CollectIdsAsync(
            terms,
            async term =>
            {
                var t = term.ToLowerInvariant();
                return await dbContext.Products.AsNoTracking()
                    .Where(x =>
                        (x.NameEn != null && x.NameEn.ToLower().Contains(t)) ||
                        (x.DescriptionEn != null && x.DescriptionEn.ToLower().Contains(t)) ||
                        (x.Owner != null && x.Owner.FullName.ToLower().Contains(t)) ||
                        (x.Owner != null && x.Owner.Email.ToLower().Contains(t)) ||
                        (x.Owner != null && x.Owner.CompanyName != null && x.Owner.CompanyName.ToLower().Contains(t)) ||
                        (x.Category != null && x.Category.NameEn.ToLower().Contains(t)) ||
                        dbContext.ContentTranslations.Any(ct =>
                            ct.ProductId == x.ProductId
                            && ct.Scope == ContentTranslationScopes.Product
                            && (ct.Field == ContentTranslationFields.Name
                                || ct.Field == ContentTranslationFields.Description)
                            && ((ct.TextEn != null && ct.TextEn.ToLower().Contains(t))
                                || (ct.TextAr != null && ct.TextAr.ToLower().Contains(t)))))
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => x.ProductId)
                    .Take(LimitPerSection)
                    .ToListAsync(cancellationToken);
            });

        if (ids.Count == 0)
        {
            return Section("ads", "/ads", 0, []);
        }

        var items = await dbContext.Products.AsNoTracking()
            .Where(x => ids.Contains(x.ProductId))
            .Include(x => x.Owner)
            .Include(x => x.Category)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.ProductId,
                x.NameEn,
                OwnerLabel = x.Owner != null ? (x.Owner.CompanyName ?? x.Owner.FullName) : null,
                CategoryName = x.Category != null ? x.Category.NameEn : null
            })
            .ToListAsync(cancellationToken);

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            items.Select(x => x.ProductId),
            cancellationToken);

        var hits = items.Select(x =>
        {
            translations.TryGetValue(x.ProductId, out var tr);
            return new AdminGlobalSearchHitDto
            {
                Id = x.ProductId.ToString(),
                Title = AdminProductTextHelper.ResolveName(tr, x.NameEn) is { Length: > 0 } name
                    ? name
                    : "—",
                Subtitle = x.OwnerLabel,
                Route = $"/ads/{x.ProductId}",
                Meta = x.CategoryName
            };
        }).ToList();

        return Section("ads", "/ads", hits.Count, hits);
    }

    private async Task<AdminGlobalSearchSectionDto> SearchUsersAsync(
        IReadOnlyList<string> terms,
        CancellationToken cancellationToken)
    {
        var ids = await CollectIdsAsync(
            terms,
            async term =>
            {
                var t = term.ToLowerInvariant();
                return await dbContext.Users.AsNoTracking()
                    .Where(x =>
                        x.FullName.ToLower().Contains(t) ||
                        x.Email.ToLower().Contains(t) ||
                        (x.CompanyName != null && x.CompanyName.ToLower().Contains(t)) ||
                        (x.PhoneNumber != null && x.PhoneNumber.Contains(t)))
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => x.Id)
                    .Take(LimitPerSection)
                    .ToListAsync(cancellationToken);
            });

        if (ids.Count == 0)
        {
            return Section("users", "/users", 0, []);
        }

        var items = await dbContext.Users.AsNoTracking()
            .Include(x => x.Role)
            .Where(x => ids.Contains(x.Id))
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminGlobalSearchHitDto
            {
                Id = x.Id.ToString(),
                Title = x.CompanyName ?? x.FullName,
                Subtitle = x.Email,
                Route = $"/users/{x.Id}",
                Meta = AdminMappings.GetRoleName(x.RoleId, x.IsCustomer)
            })
            .ToListAsync(cancellationToken);

        return Section("users", "/users", items.Count, items);
    }

    private async Task<AdminGlobalSearchSectionDto> SearchOrdersAsync(
        IReadOnlyList<string> terms,
        CancellationToken cancellationToken)
    {
        var ids = await CollectLongIdsAsync(
            terms,
            async term =>
            {
                var t = term.ToLowerInvariant();
                if (long.TryParse(term, out var orderId))
                {
                    return await dbContext.Orders.AsNoTracking()
                        .Where(x => x.Id == orderId)
                        .Select(x => x.Id)
                        .Take(1)
                        .ToListAsync(cancellationToken);
                }

                return await dbContext.Orders.AsNoTracking()
                    .Where(x =>
                        (x.FromUser != null && x.FromUser.FullName.ToLower().Contains(t)) ||
                        (x.FromUser != null && x.FromUser.Email.ToLower().Contains(t)) ||
                        (x.ToUser != null && x.ToUser.FullName.ToLower().Contains(t)) ||
                        (x.ToUser != null && x.ToUser.Email.ToLower().Contains(t)) ||
                        (x.Product != null && x.Product.NameEn != null && x.Product.NameEn.ToLower().Contains(t)) ||
                        dbContext.ContentTranslations.Any(ct =>
                            ct.ProductId == x.ProductId
                            && ct.Scope == ContentTranslationScopes.Product
                            && ct.Field == ContentTranslationFields.Name
                            && ((ct.TextEn != null && ct.TextEn.ToLower().Contains(t))
                                || (ct.TextAr != null && ct.TextAr.ToLower().Contains(t)))) ||
                        (x.Notes != null && x.Notes.ToLower().Contains(t)))
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => x.Id)
                    .Take(LimitPerSection)
                    .ToListAsync(cancellationToken);
            });

        if (ids.Count == 0)
        {
            return Section("orders", "/orders", 0, []);
        }

        var items = await dbContext.Orders.AsNoTracking()
            .Include(x => x.FromUser)
            .Include(x => x.Product)
            .Include(x => x.Status)
            .Where(x => ids.Contains(x.Id))
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                FromUserName = x.FromUser != null ? x.FromUser.FullName : null,
                ProductId = x.Product != null ? (Guid?)x.Product.ProductId : null,
                ProductNameEn = x.Product != null ? x.Product.NameEn : null,
                StatusName = x.Status != null ? x.Status.Name : null
            })
            .ToListAsync(cancellationToken);

        var productIds = items
            .Where(x => x.ProductId.HasValue)
            .Select(x => x.ProductId!.Value)
            .Distinct()
            .ToList();
        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        var hits = items.Select(x =>
        {
            string? meta = x.StatusName;
            if (x.ProductId.HasValue)
            {
                translations.TryGetValue(x.ProductId.Value, out var tr);
                var name = AdminProductTextHelper.ResolveName(tr, x.ProductNameEn);
                meta = string.IsNullOrEmpty(name) ? x.StatusName : name;
            }

            return new AdminGlobalSearchHitDto
            {
                Id = x.Id.ToString(),
                Title = $"Order #{x.Id}",
                Subtitle = x.FromUserName,
                Route = $"/orders?search={x.Id}",
                Meta = meta
            };
        }).ToList();

        return Section("orders", "/orders", hits.Count, hits);
    }

    private async Task<AdminGlobalSearchSectionDto> SearchShippingAsync(
        IReadOnlyList<string> terms,
        CancellationToken cancellationToken)
    {
        var providerIds = dbContext.InternationalShippingPosts
            .Select(x => x.PublisherUserId)
            .Distinct();

        var ids = await CollectIdsAsync(
            terms,
            async term =>
            {
                var t = term.ToLowerInvariant();
                return await dbContext.Users.AsNoTracking()
                    .Where(x => providerIds.Contains(x.Id))
                    .Where(x =>
                        x.FullName.ToLower().Contains(t) ||
                        (x.CompanyName != null && x.CompanyName.ToLower().Contains(t)) ||
                        x.Email.ToLower().Contains(t))
                    .OrderByDescending(x => x.CreatedAt)
                    .Select(x => x.Id)
                    .Take(LimitPerSection)
                    .ToListAsync(cancellationToken);
            });

        if (ids.Count == 0)
        {
            return Section("shipping", "/shipping", 0, []);
        }

        var items = await dbContext.Users.AsNoTracking()
            .Where(x => ids.Contains(x.Id))
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminGlobalSearchHitDto
            {
                Id = x.Id.ToString(),
                Title = x.CompanyName ?? x.FullName,
                Subtitle = x.Email,
                Route = $"/shipping/{x.Id}",
                Meta = "Shipping provider"
            })
            .ToListAsync(cancellationToken);

        return Section("shipping", "/shipping", items.Count, items);
    }

    private async Task<AdminGlobalSearchSectionDto> SearchCategoriesAsync(
        IReadOnlyList<string> terms,
        CancellationToken cancellationToken)
    {
        var ids = await CollectByteIdsAsync(
            terms,
            async term =>
            {
                var t = term.ToLowerInvariant();
                return await dbContext.Categories.AsNoTracking()
                    .Where(x => x.NameEn.ToLower().Contains(t))
                    .OrderBy(x => x.NameEn)
                    .Select(x => x.CategoryId)
                    .Take(LimitPerSection)
                    .ToListAsync(cancellationToken);
            });

        if (ids.Count == 0)
        {
            return Section("categories", "/categories", 0, []);
        }

        var items = await dbContext.Categories.AsNoTracking()
            .Where(x => ids.Contains(x.CategoryId))
            .Select(x => new AdminGlobalSearchHitDto
            {
                Id = x.CategoryId.ToString(),
                Title = x.NameEn,
                Route = "/categories",
                Meta = "Category"
            })
            .ToListAsync(cancellationToken);

        return Section("categories", "/categories", items.Count, items);
    }

    private static async Task<List<Guid>> CollectIdsAsync(
        IReadOnlyList<string> terms,
        Func<string, Task<List<Guid>>> fetch)
    {
        var ids = new HashSet<Guid>();
        foreach (var term in terms.Take(10))
        {
            foreach (var id in await fetch(term))
            {
                ids.Add(id);
                if (ids.Count >= LimitPerSection) return ids.ToList();
            }
        }
        return ids.ToList();
    }

    private static async Task<List<long>> CollectLongIdsAsync(
        IReadOnlyList<string> terms,
        Func<string, Task<List<long>>> fetch)
    {
        var ids = new HashSet<long>();
        foreach (var term in terms.Take(10))
        {
            foreach (var id in await fetch(term))
            {
                ids.Add(id);
                if (ids.Count >= LimitPerSection) return ids.ToList();
            }
        }
        return ids.ToList();
    }

    private static async Task<List<byte>> CollectByteIdsAsync(
        IReadOnlyList<string> terms,
        Func<string, Task<List<byte>>> fetch)
    {
        var ids = new HashSet<byte>();
        foreach (var term in terms.Take(10))
        {
            foreach (var id in await fetch(term))
            {
                ids.Add(id);
                if (ids.Count >= LimitPerSection) return ids.ToList();
            }
        }
        return ids.ToList();
    }

    private static AdminGlobalSearchSectionDto Section(
        string section,
        string route,
        int total,
        IReadOnlyList<AdminGlobalSearchHitDto> items) =>
        new()
        {
            Section = section,
            Route = route,
            Total = total,
            Items = items
        };
}
