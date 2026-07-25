namespace BusinessLayer.Helpers;

/// <summary>
/// Maps UAE city / emirate labels to canonical English emirate names used for domestic shipping rates.
/// </summary>
public static class UaeEmirateResolver
{
    private static readonly (string En, string Ar)[] Emirates =
    [
        ("Abu Dhabi", "أبو ظبي"),
        ("Dubai", "دبي"),
        ("Sharjah", "الشارقة"),
        ("Ajman", "عجمان"),
        ("Umm Al Quwain", "أم القيوين"),
        ("Ras Al Khaimah", "رأس الخيمة"),
        ("Fujairah", "الفجيرة")
    ];

    public static string? ResolveCanonicalEnglishName(string? candidate)
    {
        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        var normalized = Normalize(candidate);
        foreach (var (en, ar) in Emirates)
        {
            var enNorm = Normalize(en);
            var arNorm = Normalize(ar);
            if (normalized == enNorm ||
                normalized == arNorm ||
                normalized.StartsWith(enNorm + " ", StringComparison.Ordinal) ||
                normalized.StartsWith(arNorm + " ", StringComparison.Ordinal))
            {
                return en;
            }
        }

        return null;
    }

    private static string Normalize(string value) =>
        value.Trim().ToLowerInvariant();
}
