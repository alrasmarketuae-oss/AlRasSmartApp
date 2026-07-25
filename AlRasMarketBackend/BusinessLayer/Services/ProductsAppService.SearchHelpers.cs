using System.Data;
using System.Text.RegularExpressions;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using DataLayer.Seeding;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    private static string NormalizeSearchQuery(string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            throw new ArgumentException("Search query is required.");
        }

        var normalized = query.Trim();
        if (normalized.Length < 2)
        {
            throw new ArgumentException("Search query must be at least 2 characters.");
        }

        return normalized;
    }

    private static string EscapeLikeLiteral(string value) =>
        value.Replace("[", "[[]").Replace("%", "[%]").Replace("_", "[_]");

    /// <summary>Substring LIKE — candidate fetch + image search only (always followed by whole-word filter for text search).</summary>
    private static string ToSqlLikePattern(string query) =>
        "%" + EscapeLikeLiteral(query.Trim()) + "%";

    private static string ToExactLikePattern(string word) =>
        EscapeLikeLiteral(word.Trim());

    /// <summary>
    /// True when <paramref name="word"/> appears as a full token in <paramref name="text"/>.
    /// "فاخر" matches "شوكو فاخر"; "كو" / "كوك" do not match "كوكو".
    /// Uses Unicode letter/digit boundaries (not SQL LIKE substring).
    /// </summary>
    private static bool ContainsWholeWord(string? text, string word)
    {
        if (string.IsNullOrWhiteSpace(text) || string.IsNullOrWhiteSpace(word))
        {
            return false;
        }

        var needle = word.Trim();
        if (needle.Length == 0)
        {
            return false;
        }

        var haystack = text.Trim();
        if (haystack.Length == 0)
        {
            return false;
        }

        if (string.Equals(haystack, needle, StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Lookaround: left/right must not be a letter or digit (blocks كو inside كوكو).
        var pattern = $@"(?<![\p{{L}}\p{{N}}]){Regex.Escape(needle)}(?![\p{{L}}\p{{N}}])";
        return Regex.IsMatch(haystack, pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }

    private static IEnumerable<string> ResolveSearchSynonyms(string token)
    {
        var t = (token ?? string.Empty).Trim();
        if (t.Length == 0)
        {
            yield break;
        }

        if (IsCocoaToken(t))
        {
            yield return "Cocoa";
            yield return "كاكو";
            yield return "كوكو";
            yield return "كاكاو";
            yield return "كاكاوه";
        }

        if (IsCardamomToken(t))
        {
            yield return "Cardamom";
            yield return "هيل";
            yield return "الهيل";
        }

        if (IsCoffeeToken(t))
        {
            yield return "Coffee";
            yield return "قهوة";
            yield return "بن";
        }

        if (IsTeaToken(t))
        {
            yield return "Tea";
            yield return "شاي";
            yield return "الشاي";
        }
    }

    private static bool IsCocoaToken(string t) =>
        t.Equals("cocoa", StringComparison.OrdinalIgnoreCase)
        || t.Equals("coco", StringComparison.OrdinalIgnoreCase)
        || t.Equals("kakao", StringComparison.OrdinalIgnoreCase)
        || t is "كاكو" or "كوكو" or "كاكاو" or "كاكاوه" or "كاكاوية";

    private static bool IsCardamomToken(string t) =>
        t.Equals("cardamom", StringComparison.OrdinalIgnoreCase)
        || t.Equals("cardamon", StringComparison.OrdinalIgnoreCase)
        || t is "هيل" or "الهيل" or "حب الهان";

    private static bool IsCoffeeToken(string t) =>
        t.Equals("coffee", StringComparison.OrdinalIgnoreCase)
        || t is "قهوة" or "بن" or "القهوة";

    private static bool IsTeaToken(string t) =>
        t.Equals("tea", StringComparison.OrdinalIgnoreCase)
        || t is "شاي" or "الشاي";

    /// <summary>
    /// True when <paramref name="corrected"/> looks like a typo fix of <paramref name="original"/>,
    /// not a substitution with an unrelated product name.
    /// </summary>
    private static bool IsPlausibleSpellingCorrection(string original, string corrected)
    {
        var a = (original ?? string.Empty).Trim();
        var b = (corrected ?? string.Empty).Trim();
        if (a.Length < 2 || b.Length < 2)
        {
            return false;
        }

        if (string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Containment only when the shorter side is long enough (blocks short Arabic stems).
        var shorter = a.Length <= b.Length ? a : b;
        var longer = a.Length <= b.Length ? b : a;
        if (shorter.Length >= 4
            && longer.Contains(shorter, StringComparison.OrdinalIgnoreCase)
            && shorter.Length >= (int)Math.Ceiling(longer.Length * 0.6))
        {
            return true;
        }

        var distance = LevenshteinDistance(
            a.ToLowerInvariant(),
            b.ToLowerInvariant());
        var maxLen = Math.Max(a.Length, b.Length);
        // Strict: at most 1–2 edits; never treat a totally different word as a typo.
        var maxDistance = maxLen <= 5 ? 1 : 2;
        return distance > 0 && distance <= maxDistance;
    }

    private static bool IsSearchStopToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return true;
        }

        var t = token.Trim();
        // Block letter-level search (كو must not match كوكو). Allow known short product words.
        if (t.Length < 3 && !ShortAllowedSearchTokens.Contains(t))
        {
            return true;
        }

        return SearchStopTokens.Contains(t);
    }

    private static readonly HashSet<string> ShortAllowedSearchTokens = new(StringComparer.OrdinalIgnoreCase)
    {
        "بن", "tea", "kg"
    };

    private static readonly HashSet<string> SearchStopTokens = new(StringComparer.OrdinalIgnoreCase)
    {
        "a", "an", "the", "of", "and", "or", "for", "with", "from", "to", "in", "on",
        "من", "في", "على", "إلى", "الى", "عن", "مع", "هذا", "هذه", "ذلك", "تلك",
        "التي", "الذي", "او", "أو", "و", "يا"
    };

    private static int LevenshteinDistance(string a, string b)
    {
        var n = a.Length;
        var m = b.Length;
        var d = new int[n + 1, m + 1];
        for (var i = 0; i <= n; i++)
        {
            d[i, 0] = i;
        }

        for (var j = 0; j <= m; j++)
        {
            d[0, j] = j;
        }

        for (var i = 1; i <= n; i++)
        {
            for (var j = 1; j <= m; j++)
            {
                var cost = a[i - 1] == b[j - 1] ? 0 : 1;
                d[i, j] = Math.Min(
                    Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1),
                    d[i - 1, j - 1] + cost);
            }
        }

        return d[n, m];
    }

    private static readonly HashSet<string> ImageSearchStopWords = new(StringComparer.OrdinalIgnoreCase)
    {
        "a", "an", "the", "of", "and", "or", "for", "with", "from", "to", "in", "on",
        "green", "red", "black", "white", "yellow", "brown", "blue",
        "whole", "dried", "fresh", "organic", "pure", "natural", "premium", "best",
        "quality", "grade", "raw", "fine", "extra",
        "pods", "pod", "seeds", "seed", "beans", "bean", "powder", "ground",
        "pack", "packs", "bag", "bags", "box", "boxes", "bulk",
        "اخضر", "أخضر", "احمر", "أحمر", "اسود", "أسود", "ابيض", "أبيض"
    };

    /// <summary>
    /// Tokens from AI image suggestions: full phrases + significant words
    /// (so "Cardamom" / "فاخر" match as 1st or 2nd word in the ad name).
    /// </summary>
    private static List<string> BuildImageSearchTokens(IEnumerable<string> names)
    {
        var ordered = new List<string>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        void Add(string? value)
        {
            var trimmed = value?.Trim();
            if (string.IsNullOrWhiteSpace(trimmed) || trimmed.Length < 2)
            {
                return;
            }

            // Multi-word phrases are kept; single stop/color words are skipped.
            var isMultiWord = trimmed.Contains(' ');
            if (!isMultiWord && (IsSearchStopToken(trimmed) || ImageSearchStopWords.Contains(trimmed)))
            {
                return;
            }

            if (!seen.Add(trimmed))
            {
                return;
            }

            ordered.Add(trimmed);
        }

        foreach (var name in names)
        {
            Add(name);
        }

        foreach (var name in names)
        {
            var parts = name.Split(
                [' ', '-', '_', '/', ',', '.', '(', ')', '،', '؛'],
                StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            foreach (var part in parts)
            {
                if (part.Length < 3 || ImageSearchStopWords.Contains(part) || IsSearchStopToken(part))
                {
                    continue;
                }

                Add(part);
            }
        }

        return ordered.Take(12).ToList();
    }

    private static int ScoreImageNameMatch(
        IReadOnlyList<string> suggestedNames,
        IReadOnlyList<string> tokens,
        IEnumerable<string?> nameTexts)
    {
        var names = nameTexts
            .Where(n => !string.IsNullOrWhiteSpace(n))
            .Select(n => n!)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (names.Count == 0)
        {
            return 0;
        }

        bool NameHas(string word) => names.Any(n => ContainsWholeWord(n, word));

        var score = 0;
        var matchWords = new List<string>();
        foreach (var token in tokens)
        {
            matchWords.Add(token);
            matchWords.AddRange(ResolveSearchSynonyms(token));
        }

        foreach (var suggested in suggestedNames)
        {
            if (string.IsNullOrWhiteSpace(suggested))
            {
                continue;
            }

            matchWords.Add(suggested);
            matchWords.AddRange(ResolveSearchSynonyms(suggested));

            var significantParts = suggested
                .Split([' ', '-', '_', '/', ',', '.'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Where(p => p.Length >= 2 && !IsSearchStopToken(p) && !ImageSearchStopWords.Contains(p))
                .ToList();

            if (significantParts.Count > 0
                && significantParts.All(p => NameHas(p) || ResolveSearchSynonyms(p).Any(NameHas)))
            {
                score += 100;
            }
            else if (NameHas(suggested) || ResolveSearchSynonyms(suggested).Any(NameHas))
            {
                score += 100;
            }
        }

        foreach (var word in matchWords
                     .Select(w => w.Trim())
                     .Where(w => w.Length >= 2)
                     .Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (NameHas(word))
            {
                score += 20 + Math.Min(word.Length, 20);
            }
        }

        return score;
    }


    private async Task ExpireDueListingsAsync(CancellationToken cancellationToken)
    {
        await ExpireDueOfferDiscountsAsync(cancellationToken);

        var utcNow = UtcDateTimeHelper.UtcNow;
        var expired = await dbContext.Products
            .Where(x =>
                x.ProductTypeId != ProductTypeCodes.Offers
                && x.Status == ProductStatusCodes.Active
                && x.DisplayExpiresAtUtc != null
                && x.DisplayExpiresAtUtc <= utcNow)
            .ToListAsync(cancellationToken);

        if (expired.Count == 0)
        {
            return;
        }

        foreach (var product in expired)
        {
            product.Status = ProductStatusCodes.Paused;
            product.UpdatedAt = utcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateListingCaches();
    }

    /// <summary>
    /// When an offer discount window ends, restore full price and clear discount fields.
    /// The listing stays active until the owner or admin deletes it.
    /// </summary>
    private async Task ExpireDueOfferDiscountsAsync(CancellationToken cancellationToken)
    {
        var utcNow = UtcDateTimeHelper.UtcNow;
        var candidates = await dbContext.Products
            .Where(x =>
                x.ProductTypeId == ProductTypeCodes.Offers
                && x.DiscountPercentage != null
                && x.DiscountPercentage > 0
                && x.DiscountDays != null
                && x.DiscountDays > 0)
            .ToListAsync(cancellationToken);

        if (candidates.Count == 0)
        {
            return;
        }

        var changed = false;
        foreach (var product in candidates)
        {
            var endsAt = UtcDateTimeHelper.AsUtc(product.CreatedAt).AddDays(product.DiscountDays!.Value);
            if (utcNow < endsAt)
            {
                continue;
            }

            var factor = 1m - (product.DiscountPercentage!.Value / 100m);
            if (factor > 0)
            {
                product.USDPrice = decimal.Round(
                    product.USDPrice / factor,
                    2,
                    MidpointRounding.AwayFromZero);
            }

            product.DiscountPercentage = null;
            product.DiscountDays = null;
            product.UpdatedAt = utcNow;
            changed = true;
        }

        if (!changed)
        {
            return;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateListingCaches();
    }

    private async Task ApplyAdDisplayExpiryAsync(Product product, CancellationToken cancellationToken)
    {
        if (IsOfferProduct(product.ProductTypeId))
        {
            product.DisplayExpiresAtUtc = null;
            return;
        }

        var durationDays = await GetAdDisplayDurationDaysAsync(cancellationToken);
        product.DisplayExpiresAtUtc = UtcDateTimeHelper.ComputeAdExpiresAtUtc(UtcDateTimeHelper.UtcNow, durationDays);
    }

    private async Task<int> GetAdDisplayDurationDaysAsync(CancellationToken cancellationToken) =>
        await dbContext.SystemSettings
            .AsNoTracking()
            .Where(x => x.Id == 1)
            .Select(x => x.AdDisplayDurationDays)
            .FirstOrDefaultAsync(cancellationToken);
}
