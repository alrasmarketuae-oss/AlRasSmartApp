namespace BusinessLayer.Helpers;

/// <summary>
/// Normalizes admin search queries — strips punctuation/parentheses like the frontend searchNormalize.ts.
/// </summary>
public static class AdminSearchNormalizer
{
    public static string Normalize(string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return string.Empty;
        }

        var normalized = query.Trim().ToLowerInvariant();
        normalized = System.Text.RegularExpressions.Regex.Replace(
            normalized,
            @"[()\[\]{}«»""'""''،,:;!?./\\|@#%&*+=<>~`]",
            " ");
        normalized = System.Text.RegularExpressions.Regex.Replace(normalized, @"\s+", " ").Trim();
        return normalized;
    }

    public static IReadOnlyList<string> SplitWords(string? text)
    {
        var normalized = Normalize(text);
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return [];
        }

        return normalized
            .Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .Where(word => word.Length >= 2)
            .ToList();
    }
}
