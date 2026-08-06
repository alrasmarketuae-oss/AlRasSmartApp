using System.Text.RegularExpressions;

namespace BusinessLayer.Helpers;

/// <summary>
/// Fast text scan for seller contact / promotion that must not appear in ad specs.
/// </summary>
public static partial class AdContactPolicyScanner
{
    public sealed record Hit(string Kind, string Sample);

    public static IReadOnlyList<Hit> Scan(params string?[] fields)
    {
        var hits = new List<Hit>();
        foreach (var field in fields)
        {
            if (string.IsNullOrWhiteSpace(field))
            {
                continue;
            }

            var text = field.Trim();
            CollectPhones(hits, text);
            Collect(hits, EmailPattern(), text, "email");
            Collect(hits, UrlPattern(), text, "url");
            Collect(hits, SocialHandlePattern(), text, "social");
            Collect(hits, ContactKeywordPattern(), text, "contact_keyword");
            Collect(hits, WhatsAppPattern(), text, "whatsapp");
            Collect(hits, InsultPattern(), text, "insult");
        }

        return hits;
    }

    public static bool HasViolations(params string?[] fields) => Scan(fields).Count > 0;

    private static void CollectPhones(List<Hit> hits, string text)
    {
        foreach (Match match in PhonePattern().Matches(text))
        {
            if (!match.Success)
            {
                continue;
            }

            var digitCount = 0;
            foreach (var ch in match.Value)
            {
                if (char.IsDigit(ch))
                {
                    digitCount++;
                }
            }

            // Quantities/prices often have few digits; real phones are longer.
            if (digitCount < 8)
            {
                continue;
            }

            AddHit(hits, "phone", match.Value);
            if (hits.Count >= 12)
            {
                return;
            }
        }
    }

    private static void Collect(List<Hit> hits, Regex regex, string text, string kind)
    {
        foreach (Match match in regex.Matches(text))
        {
            if (!match.Success)
            {
                continue;
            }

            AddHit(hits, kind, match.Value);
            if (hits.Count >= 12)
            {
                return;
            }
        }
    }

    private static void AddHit(List<Hit> hits, string kind, string raw)
    {
        var sample = raw.Trim();
        if (sample.Length > 48)
        {
            sample = sample[..48] + "…";
        }

        if (hits.Exists(h => h.Kind == kind && h.Sample == sample))
        {
            return;
        }

        hits.Add(new Hit(kind, sample));
    }

    [GeneratedRegex(
        @"(?:\+|00)?\d[\d\s\-().]{6,}\d",
        RegexOptions.CultureInvariant)]
    private static partial Regex PhonePattern();

    [GeneratedRegex(
        @"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex EmailPattern();

    [GeneratedRegex(
        @"(?:https?://|www\.)[^\s]+",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex UrlPattern();

    [GeneratedRegex(
        @"@[a-zA-Z0-9._]{3,}",
        RegexOptions.CultureInvariant)]
    private static partial Regex SocialHandlePattern();

    [GeneratedRegex(
        @"\b(?:whats?\s*app|واتس(?:اب)?|واتساب)\b",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex WhatsAppPattern();

    [GeneratedRegex(
        @"(?:للتواصل|اتصل(?:وا)?(?:\s*بنا)?|تواصل(?:وا)?(?:\s*معنا)?|رقم\s*(?:الجوال|الهاتف|الموبايل|الواتس)|call\s*us|contact\s*us|phone\s*number|mobile\s*number|reach\s*us)",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex ContactKeywordPattern();

    /// <summary>
    /// Common Arabic/English insults (fast path). LLM text scan covers disguised variants.
    /// </summary>
    [GeneratedRegex(
        @"\b(?:fuck|fucking|shit|bitch|asshole|bastard|dick|pussy|cunt|slut|whore|" +
        @"كس|كسم|كسام|شرموط|شرموطة|عرص|منيوك|زب|طيز|خول|قحبة|ابن\s*الكلب|يا\s*كلب|" +
        @"يلعن|انعل|لعن\s*أب|لعن\s*ام|يلعنك|يلعنكم)\b",
        RegexOptions.CultureInvariant | RegexOptions.IgnoreCase)]
    private static partial Regex InsultPattern();
}
