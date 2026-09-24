using System.Text.RegularExpressions;
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

        // Prefer original casing/script for the push copy; matching uses NormalizeForMatch.
        var displayName = CollapseWhitespace(
            evt.SearchNames.FirstOrDefault(n => !string.IsNullOrWhiteSpace(n))
            ?? productNames[0]);
        if (displayName.Length == 0)
        {
            displayName = productNames[0];
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
            var normalized = NormalizeForMatch(raw);
            if (normalized.Length < MinQueryLength || !seen.Add(normalized))
            {
                continue;
            }

            result.Add(normalized);
        }

        return result;
    }

    /// <summary>
    /// Matches a missed-search query to product names.
    /// Exact name, substring, or any significant word from the query appearing as a
    /// whole token inside a multi-word product name (e.g. query "تفاح" vs "تفاح احمر طازج").
    /// </summary>
    internal static bool IsMatch(string? queryText, IReadOnlyList<string> productNames)
    {
        var query = NormalizeForMatch(queryText);
        if (query.Length < MinQueryLength)
        {
            return false;
        }

        var queryTokens = TokenizeSignificant(query);
        foreach (var name in productNames)
        {
            var normalizedName = NormalizeForMatch(name);
            if (normalizedName.Length < MinQueryLength)
            {
                continue;
            }

            if (string.Equals(query, normalizedName, StringComparison.Ordinal))
            {
                return true;
            }

            // Full-phrase containment either way (short query inside long name, or vice versa).
            if (query.Length >= MinSubstringLength
                && normalizedName.Length >= MinSubstringLength
                && (normalizedName.Contains(query, StringComparison.Ordinal)
                    || query.Contains(normalizedName, StringComparison.Ordinal)))
            {
                return true;
            }

            var nameTokens = TokenizeSignificant(normalizedName);
            if (queryTokens.Count == 0 || nameTokens.Count == 0)
            {
                continue;
            }

            // Word-level: any search word appears as a whole token in the product name
            // (or a name token appears as a whole word in a multi-word query).
            foreach (var qt in queryTokens)
            {
                foreach (var nt in nameTokens)
                {
                    if (string.Equals(qt, nt, StringComparison.Ordinal))
                    {
                        return true;
                    }

                    if (qt.Length >= MinSubstringLength
                        && nt.Length >= MinSubstringLength
                        && (nt.Contains(qt, StringComparison.Ordinal)
                            || qt.Contains(nt, StringComparison.Ordinal)))
                    {
                        return true;
                    }
                }

                if (ContainsWholeWord(normalizedName, qt))
                {
                    return true;
                }
            }

            foreach (var nt in nameTokens)
            {
                if (ContainsWholeWord(query, nt))
                {
                    return true;
                }
            }
        }

        return false;
    }

    /// <summary>
    /// Collapse whitespace, strip tatweel/diacritics, and unify common Arabic letter variants
    /// so "أديداس" matches "اديداس" and word tokens line up across EN/AR paste differences.
    /// </summary>
    private static string NormalizeForMatch(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var collapsed = CollapseWhitespace(value);

        Span<char> buffer = collapsed.Length <= 256
            ? stackalloc char[collapsed.Length]
            : new char[collapsed.Length];
        var written = 0;
        foreach (var ch in collapsed)
        {
            // Arabic tatweel + combining marks (harakat).
            if (ch is '\u0640' or (>= '\u064B' and <= '\u065F') or '\u0670')
            {
                continue;
            }

            var mapped = ch switch
            {
                'أ' or 'إ' or 'آ' or 'ٱ' => 'ا',
                'ى' => 'ي',
                'ة' => 'ه',
                'ؤ' => 'و',
                'ئ' => 'ي',
                _ => char.ToLowerInvariant(ch)
            };
            buffer[written++] = mapped;
        }

        return written == 0 ? string.Empty : new string(buffer[..written]);
    }

    private static List<string> TokenizeSignificant(string normalized)
    {
        if (normalized.Length == 0)
        {
            return [];
        }

        var tokens = new List<string>();
        var seen = new HashSet<string>(StringComparer.Ordinal);
        foreach (var part in normalized.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
        {
            // Also split on punctuation glued to words: "apple,", "iphone-15".
            var start = -1;
            for (var i = 0; i <= part.Length; i++)
            {
                var isWordChar = i < part.Length && (char.IsLetterOrDigit(part[i]) || part[i] == '_');
                if (isWordChar)
                {
                    if (start < 0)
                    {
                        start = i;
                    }

                    continue;
                }

                if (start < 0)
                {
                    continue;
                }

                var token = part[start..i];
                start = -1;
                if (token.Length < MinQueryLength || IsNoiseToken(token) || !seen.Add(token))
                {
                    continue;
                }

                tokens.Add(token);
            }
        }

        return tokens;
    }

    private static bool IsNoiseToken(string token) =>
        token is "a" or "an" or "the" or "of" or "and" or "or" or "for" or "with"
            or "from" or "to" or "in" or "on"
            or "من" or "في" or "على" or "إلي" or "الى" or "عن" or "مع"
            or "هذا" or "هذه" or "ذلك" or "تلك" or "او" or "أو" or "و" or "يا";

    /// <summary>
    /// True when <paramref name="word"/> appears as a full token in <paramref name="text"/>.
    /// </summary>
    private static bool ContainsWholeWord(string text, string word)
    {
        if (text.Length == 0 || word.Length == 0)
        {
            return false;
        }

        if (string.Equals(text, word, StringComparison.Ordinal))
        {
            return true;
        }

        var pattern = $@"(?<![\p{{L}}\p{{N}}]){Regex.Escape(word)}(?![\p{{L}}\p{{N}}])";
        return Regex.IsMatch(text, pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
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
