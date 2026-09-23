using BusinessLayer.Caching;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Matches newly searchable products against pending missed searches and sends FCM
/// (+ inbox) to the users who searched. Runs only from the background event worker.
/// </summary>
public sealed class MissedSearchProductAvailableNotifier(
    IRasAlSouqDbContext dbContext,
    IProductDataAccess productData,
    IFcmNotificationService fcmNotificationService,
    ILogger<MissedSearchProductAvailableNotifier> logger)
{
    private static readonly TimeSpan LookbackWindow = TimeSpan.FromDays(180);
    private const int MaxPendingRows = 5000;
    private const int MinQueryLength = 2;
    private const int MinSubstringLength = 3;

    public async Task NotifyMatchingSearchersAsync(
        ProductBecameSearchableEvent evt,
        CancellationToken cancellationToken = default)
    {
        var productNames = NormalizeNames(evt.SearchNames);
        if (productNames.Count == 0)
        {
            return;
        }

        var since = DateTime.UtcNow.Subtract(LookbackWindow);
        var pending = await dbContext.MissedProductSearches
            .Where(x =>
                x.NotifiedAtUtc == null
                && x.UserId != null
                && x.CreatedAtUtc >= since)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Take(MaxPendingRows)
            .Select(x => new PendingMissedSearch(x.Id, x.UserId!.Value, x.QueryText))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        if (pending.Count == 0)
        {
            return;
        }

        var matchedByUser = new Dictionary<Guid, List<Guid>>();
        foreach (var row in pending)
        {
            if (evt.OwnerId.HasValue && row.UserId == evt.OwnerId.Value)
            {
                continue;
            }

            if (!IsMatch(row.QueryText, productNames))
            {
                continue;
            }

            if (!matchedByUser.TryGetValue(row.UserId, out var ids))
            {
                ids = [];
                matchedByUser[row.UserId] = ids;
            }

            ids.Add(row.Id);
        }

        if (matchedByUser.Count == 0)
        {
            return;
        }

        var userIds = matchedByUser.Keys.ToList();
        var users = await dbContext.Users
            .AsNoTracking()
            .Where(x => userIds.Contains(x.Id))
            .Select(x => new
            {
                x.Id,
                x.FcmToken,
                x.PreferredLanguage,
                x.IsNotificationsOn
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        var displayName = productNames[0];
        var productIdText = evt.ProductId.ToString("D");
        var notifiedAt = DateTime.UtcNow;
        var allMatchedRowIds = matchedByUser.Values.SelectMany(x => x).Distinct().ToList();

        // Mark rows first so a crash mid-send does not re-spam on retry of the same event.
        var rowsToUpdate = await dbContext.MissedProductSearches
            .Where(x => allMatchedRowIds.Contains(x.Id) && x.NotifiedAtUtc == null)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var row in rowsToUpdate)
        {
            row.NotifiedAtUtc = notifiedAt;
            row.MatchedProductId = evt.ProductId;
        }

        if (rowsToUpdate.Count > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);
            MissedProductSearchAppService.InvalidateListCache();
        }

        byte? typeId = null;
        Guid? routeId = null;

        foreach (var user in users)
        {
            if (!matchedByUser.ContainsKey(user.Id))
            {
                continue;
            }

            var (titleEn, bodyEn, titleAr, bodyAr) = NotificationMessages.MissedSearchProductAvailable(
                displayName);

            var (pushTitle, pushBody) = NotificationMessages.PickOptional(
                user.PreferredLanguage,
                titleEn,
                bodyEn,
                titleAr,
                bodyAr);

            try
            {
                typeId ??= await productData
                    .GetOrCreateNotificationTypeIdAsync("missed_search_product_available", cancellationToken)
                    .ConfigureAwait(false);
                routeId ??= await productData
                    .GetOrCreateNotificationRouteIdAsync("product-detail", cancellationToken)
                    .ConfigureAwait(false);

                await productData.AddInboxNotificationAsync(
                    new Notification
                    {
                        Id = Guid.NewGuid(),
                        Title = Truncate(titleEn, 255),
                        TitleAr = Truncate(titleAr, 255),
                        Body = Truncate(bodyEn, 1000),
                        BodyAr = Truncate(bodyAr, 1000),
                        FromUserId = user.Id,
                        ToUserId = user.Id,
                        TypeId = typeId.Value,
                        RouteId = routeId.Value,
                        ReferenceId = productIdText,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    },
                    cancellationToken).ConfigureAwait(false);

                NotificationCacheVersions.Bump(user.Id);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Failed to persist missed-search inbox notification for user {UserId} product {ProductId}",
                    user.Id,
                    evt.ProductId);
            }

            if (!NotificationDeliveryPrefs.AllowsPushAndEmail(user.IsNotificationsOn)
                || string.IsNullOrWhiteSpace(user.FcmToken))
            {
                continue;
            }

            try
            {
                await fcmNotificationService.SendNotificationAsync(
                    user.FcmToken,
                    new FcmNotificationPayload
                    {
                        Title = pushTitle,
                        Body = pushBody,
                        Type = "missed_search_product_available",
                        RouteId = "product-detail",
                        ReferenceId = productIdText,
                        Data = new Dictionary<string, string>
                        {
                            ["searchQuery"] = displayName,
                            ["productId"] = productIdText
                        }
                    },
                    cancellationToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Failed to send missed-search FCM to user {UserId} for product {ProductId}",
                    user.Id,
                    evt.ProductId);
            }
        }

        logger.LogInformation(
            "Missed-search notify: product {ProductId} matched {UserCount} user(s), {RowCount} row(s).",
            evt.ProductId,
            matchedByUser.Count,
            allMatchedRowIds.Count);
    }

    private static List<string> NormalizeNames(IReadOnlyList<string> names)
    {
        var result = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var raw in names)
        {
            var normalized = CollapseWhitespace(raw);
            if (normalized.Length < MinQueryLength || !seen.Add(normalized))
            {
                continue;
            }

            result.Add(normalized);
        }

        return result;
    }

    internal static bool IsMatch(string? queryText, IReadOnlyList<string> productNames)
    {
        var query = CollapseWhitespace(queryText);
        if (query.Length < MinQueryLength)
        {
            return false;
        }

        foreach (var name in productNames)
        {
            if (string.Equals(query, name, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            if (query.Length >= MinSubstringLength
                && name.Length >= MinSubstringLength
                && (name.Contains(query, StringComparison.OrdinalIgnoreCase)
                    || query.Contains(name, StringComparison.OrdinalIgnoreCase)))
            {
                return true;
            }
        }

        return false;
    }

    private static string CollapseWhitespace(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return string.Join(
            ' ',
            value.Trim().Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
    }

    private static string Truncate(string? value, int maxLen)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= maxLen ? trimmed : trimmed[..(maxLen - 1)] + "…";
    }

    private sealed record PendingMissedSearch(Guid Id, Guid UserId, string QueryText);
}
