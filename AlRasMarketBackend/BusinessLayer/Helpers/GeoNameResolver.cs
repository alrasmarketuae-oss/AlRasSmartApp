using BusinessLayer.Dtos;

namespace BusinessLayer.Helpers;

/// <summary>
/// Normalization + pre-built indexes for all countries/ports in the catalog (~200 countries, ~17k ports).
/// Indexes are built once at startup inside <see cref="GeoNameIndex"/>.
/// </summary>
public static class GeoNameNormalizer
{
    public static string Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var s = value.Trim().ToLowerInvariant();
        s = s
            .Replace('أ', 'ا')
            .Replace('إ', 'ا')
            .Replace('آ', 'ا')
            .Replace('ة', 'ه')
            .Replace('ى', 'ي')
            .Replace('ؤ', 'و')
            .Replace('ئ', 'ي');

        s = s
            .Replace(".", " ", StringComparison.Ordinal)
            .Replace(",", " ", StringComparison.Ordinal)
            .Replace("-", " ", StringComparison.Ordinal)
            .Replace("_", " ", StringComparison.Ordinal)
            .Replace("'", " ", StringComparison.Ordinal)
            .Replace("\"", " ", StringComparison.Ordinal)
            .Replace("(", " ", StringComparison.Ordinal)
            .Replace(")", " ", StringComparison.Ordinal)
            .Replace("/", " ", StringComparison.Ordinal);

        while (s.Contains("  ", StringComparison.Ordinal))
        {
            s = s.Replace("  ", " ", StringComparison.Ordinal);
        }

        return s.Trim();
    }

    public static string NormalizePortQuery(string? value)
    {
        var s = Normalize(value);
        if (s.Length == 0)
        {
            return s;
        }

        ReadOnlySpan<string> prefixes =
        [
            "port of ",
            "port ",
            "harbour ",
            "harbor ",
            "terminal ",
            "mina ",
            "min ",
            "ميناء ",
            "ميناء",
            "مينا ",
            "مينا",
            "بورت ",
            "بورت",
        ];

        var changed = true;
        while (changed)
        {
            changed = false;
            foreach (var prefix in prefixes)
            {
                if (s.StartsWith(prefix, StringComparison.Ordinal))
                {
                    s = s[prefix.Length..].Trim();
                    changed = true;
                }
            }
        }

        ReadOnlySpan<string> suffixes =
        [
            " port",
            " terminal",
            " harbour",
            " harbor",
            " ميناء",
        ];

        foreach (var suffix in suffixes)
        {
            if (s.EndsWith(suffix, StringComparison.Ordinal) && s.Length > suffix.Length)
            {
                s = s[..^suffix.Length].Trim();
            }
        }

        return s.Trim();
    }

    internal static IEnumerable<string> ExpandCountryNameVariants(string? englishName)
    {
        if (string.IsNullOrWhiteSpace(englishName))
        {
            yield break;
        }

        var trimmed = englishName.Trim();
        yield return trimmed;

        string[] prefixes = ["The ", "the "];
        foreach (var prefix in prefixes)
        {
            if (trimmed.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                yield return trimmed[prefix.Length..].Trim();
            }
        }

        string[] leadingPhrases =
        [
            "Republic of ",
            "Kingdom of ",
            "State of ",
            "Islamic Republic of ",
            "People's Republic of ",
            "Democratic Republic of ",
            "United Republic of ",
            "Plurinational State of ",
            "Federated States of ",
        ];

        foreach (var phrase in leadingPhrases)
        {
            if (trimmed.StartsWith(phrase, StringComparison.OrdinalIgnoreCase))
            {
                yield return trimmed[phrase.Length..].Trim();
            }
        }
    }

    internal static IEnumerable<string> ExpandPortNameVariants(string? englishName, string? arabicName)
    {
        if (!string.IsNullOrWhiteSpace(englishName))
        {
            var trimmed = englishName.Trim();
            yield return trimmed;

            string[] suffixes = [" Port", " Terminal", " Harbour", " Harbor"];
            foreach (var suffix in suffixes)
            {
                if (trimmed.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
                {
                    yield return trimmed[..^suffix.Length].Trim();
                }
            }
        }

        if (!string.IsNullOrWhiteSpace(arabicName))
        {
            yield return arabicName.Trim();
        }
    }
}

/// <summary>
/// Pre-built O(1) lookup indexes for the full geo catalog. Built once when reference cache loads.
/// </summary>
public sealed class GeoNameIndex
{
    private const int AutoMatchMinScore = 72;
    private const int SuggestionMinScore = 45;

    /// <summary>
    /// Cross-name aliases when users say the long/common form but DB stores the short canonical English name.
    /// Key = ISO-3166 alpha-2. Kept small — everything else comes from CountryNameEn/Ar in the DB.
    /// </summary>
    private static readonly Dictionary<string, string[]> ExtraCountryAliasesByIso2 =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["AE"] = ["United Arab Emirates", "U.A.E.", "U A E", "Emirates", "الإمارات", "الامارات", "الامارات العربيه المتحده", "الإمارات العربية المتحدة"],
            ["SA"] = ["Saudi Arabia", "KSA", "Kingdom of Saudi Arabia", "السعودية", "السعوديه", "المملكة العربية السعودية"],
            ["US"] = ["United States", "United States of America", "USA", "U.S.A.", "America", "الولايات المتحدة"],
            ["GB"] = ["United Kingdom", "UK", "U.K.", "Great Britain", "England", "بريطانيا", "المملكة المتحدة"],
            ["CN"] = ["China", "PRC", "People's Republic of China", "الصين"],
            ["KR"] = ["South Korea", "Korea", "Republic of Korea", "كوريا"],
            ["RU"] = ["Russia", "Russian Federation", "روسيا"],
            ["IR"] = ["Iran", "Islamic Republic of Iran", "إيران", "ايران"],
            ["TR"] = ["Turkey", "Türkiye", "Turkiye", "تركيا"],
            ["NL"] = ["Netherlands", "Holland", "The Netherlands", "هولندا"],
        };

    private readonly IReadOnlyList<GeoCountrySnapshot> _countries;
    private readonly Dictionary<short, IReadOnlyList<GeoPortSnapshot>> _portsByCountry;
    private readonly Dictionary<string, GeoCountrySnapshot> _countryAliases;
    private readonly Dictionary<short, Dictionary<string, GeoPortSnapshot>> _portAliasesByCountry;
    private readonly Dictionary<string, GeoPortSnapshot> _portByUnLocode;

    private GeoNameIndex(
        IReadOnlyList<GeoCountrySnapshot> countries,
        Dictionary<short, IReadOnlyList<GeoPortSnapshot>> portsByCountry,
        Dictionary<string, GeoCountrySnapshot> countryAliases,
        Dictionary<short, Dictionary<string, GeoPortSnapshot>> portAliasesByCountry,
        Dictionary<string, GeoPortSnapshot> portByUnLocode)
    {
        _countries = countries;
        _portsByCountry = portsByCountry;
        _countryAliases = countryAliases;
        _portAliasesByCountry = portAliasesByCountry;
        _portByUnLocode = portByUnLocode;
    }

    public int CountryAliasCount => _countryAliases.Count;

    public int PortAliasCount => _portAliasesByCountry.Values.Sum(x => x.Count);

    public static GeoNameIndex Build(
        IReadOnlyList<GeoCountrySnapshot> countries,
        IReadOnlyList<GeoPortSnapshot> ports)
    {
        var countryAliases = new Dictionary<string, GeoCountrySnapshot>(StringComparer.Ordinal);
        foreach (var country in countries)
        {
            RegisterCountryAlias(countryAliases, country, GeoNameNormalizer.Normalize(country.CountryNameEn));
            RegisterCountryAlias(countryAliases, country, GeoNameNormalizer.Normalize(country.CountryNameAr));
            RegisterCountryAlias(countryAliases, country, GeoNameNormalizer.Normalize(country.Iso2Code));

            foreach (var variant in GeoNameNormalizer.ExpandCountryNameVariants(country.CountryNameEn))
            {
                RegisterCountryAlias(countryAliases, country, GeoNameNormalizer.Normalize(variant));
            }

            if (ExtraCountryAliasesByIso2.TryGetValue(country.Iso2Code, out var extras))
            {
                foreach (var extra in extras)
                {
                    RegisterCountryAlias(countryAliases, country, GeoNameNormalizer.Normalize(extra));
                }
            }
        }

        var portsByCountry = ports
            .GroupBy(x => x.CountryId)
            .ToDictionary(g => g.Key, g => (IReadOnlyList<GeoPortSnapshot>)g.ToList());

        var portAliasesByCountry = new Dictionary<short, Dictionary<string, GeoPortSnapshot>>();
        var portByUnLocode = new Dictionary<string, GeoPortSnapshot>(StringComparer.OrdinalIgnoreCase);

        foreach (var port in ports)
        {
            if (!portAliasesByCountry.TryGetValue(port.CountryId, out var map))
            {
                map = new Dictionary<string, GeoPortSnapshot>(StringComparer.Ordinal);
                portAliasesByCountry[port.CountryId] = map;
            }

            RegisterPortAlias(map, port, GeoNameNormalizer.NormalizePortQuery(port.PortNameEn));
            RegisterPortAlias(map, port, GeoNameNormalizer.NormalizePortQuery(port.PortNameAr));
            RegisterPortAlias(map, port, GeoNameNormalizer.Normalize(port.PortNameEn));
            RegisterPortAlias(map, port, GeoNameNormalizer.Normalize(port.PortNameAr));

            foreach (var variant in GeoNameNormalizer.ExpandPortNameVariants(port.PortNameEn, port.PortNameAr))
            {
                RegisterPortAlias(map, port, GeoNameNormalizer.NormalizePortQuery(variant));
                RegisterPortAlias(map, port, GeoNameNormalizer.Normalize(variant));
            }

            if (!string.IsNullOrWhiteSpace(port.UnLocode))
            {
                var code = port.UnLocode.Trim();
                portByUnLocode.TryAdd(code, port);
                RegisterPortAlias(map, port, GeoNameNormalizer.Normalize(code));
            }
        }

        return new GeoNameIndex(
            countries,
            portsByCountry,
            countryAliases,
            portAliasesByCountry,
            portByUnLocode);
    }

    public GeoCountrySnapshot? ResolveCountry(string? input)
    {
        if (string.IsNullOrWhiteSpace(input) || _countries.Count == 0)
        {
            return null;
        }

        var norm = GeoNameNormalizer.Normalize(input);
        if (norm.Length == 0)
        {
            return null;
        }

        if (_countryAliases.TryGetValue(norm, out var exact))
        {
            return exact;
        }

        return PickBest(
            _countries,
            norm,
            c => new[]
            {
                GeoNameNormalizer.Normalize(c.CountryNameEn),
                GeoNameNormalizer.Normalize(c.CountryNameAr),
                GeoNameNormalizer.Normalize(c.Iso2Code),
            },
            AutoMatchMinScore);
    }

    public GeoPortSnapshot? ResolvePort(string? input, short countryId)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return null;
        }

        if (!_portsByCountry.TryGetValue(countryId, out var ports) || ports.Count == 0)
        {
            return null;
        }

        var raw = input.Trim();
        if (raw.Length is >= 5 and <= 6
            && _portByUnLocode.TryGetValue(raw, out var byCode)
            && byCode.CountryId == countryId)
        {
            return byCode;
        }

        var norm = GeoNameNormalizer.NormalizePortQuery(input);
        if (norm.Length == 0)
        {
            return null;
        }

        if (_portAliasesByCountry.TryGetValue(countryId, out var map)
            && map.TryGetValue(norm, out var exact))
        {
            return exact;
        }

        return PickBest(
            ports,
            norm,
            p => new[]
            {
                GeoNameNormalizer.NormalizePortQuery(p.PortNameEn),
                GeoNameNormalizer.NormalizePortQuery(p.PortNameAr),
                GeoNameNormalizer.Normalize(p.UnLocode),
            },
            AutoMatchMinScore);
    }

    public GeoPortSnapshot? ResolvePortGlobal(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return null;
        }

        var raw = input.Trim();
        if (raw.Length is >= 5 and <= 6
            && _portByUnLocode.TryGetValue(raw, out var byCode))
        {
            return byCode;
        }

        var norm = GeoNameNormalizer.NormalizePortQuery(input);
        if (norm.Length == 0)
        {
            return null;
        }

        foreach (var map in _portAliasesByCountry.Values)
        {
            if (map.TryGetValue(norm, out var exact))
            {
                return exact;
            }
        }

        GeoPortSnapshot? best = null;
        var bestScore = 0;
        foreach (var ports in _portsByCountry.Values)
        {
            var candidate = PickBest(
                ports,
                norm,
                p => new[]
                {
                    GeoNameNormalizer.NormalizePortQuery(p.PortNameEn),
                    GeoNameNormalizer.NormalizePortQuery(p.PortNameAr),
                    GeoNameNormalizer.Normalize(p.UnLocode),
                },
                AutoMatchMinScore);
            if (candidate is null)
            {
                continue;
            }

            var score = BestScore(
                norm,
                candidate.PortNameEn,
                candidate.PortNameAr,
                candidate.UnLocode);
            if (score > bestScore)
            {
                bestScore = score;
                best = candidate;
            }
        }

        return best;
    }

    public IReadOnlyList<GeoCountrySnapshot> SuggestCountries(string? input, int max = 5)
    {
        if (string.IsNullOrWhiteSpace(input) || _countries.Count == 0)
        {
            return Array.Empty<GeoCountrySnapshot>();
        }

        var norm = GeoNameNormalizer.Normalize(input);
        return _countries
            .Select(c => (Country: c, Score: BestScore(norm, c.CountryNameEn, c.CountryNameAr, c.Iso2Code)))
            .Where(x => x.Score >= SuggestionMinScore)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Country.CountryNameEn, StringComparer.OrdinalIgnoreCase)
            .Take(max)
            .Select(x => x.Country)
            .ToList();
    }

    public IReadOnlyList<GeoPortSnapshot> SuggestPorts(string? input, short countryId, int max = 8)
    {
        if (string.IsNullOrWhiteSpace(input)
            || !_portsByCountry.TryGetValue(countryId, out var ports)
            || ports.Count == 0)
        {
            return Array.Empty<GeoPortSnapshot>();
        }

        var norm = GeoNameNormalizer.NormalizePortQuery(input);
        return ports
            .Select(p => (Port: p, Score: BestScore(norm, p.PortNameEn, p.PortNameAr, p.UnLocode)))
            .Where(x => x.Score >= SuggestionMinScore)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Port.PortNameEn, StringComparer.OrdinalIgnoreCase)
            .Take(max)
            .Select(x => x.Port)
            .ToList();
    }

    public static int ScoreMatch(string? left, string? right) =>
        ScoreNormalized(GeoNameNormalizer.Normalize(left), GeoNameNormalizer.Normalize(right));

    public static bool MatchesQuery(string query, params string?[] values)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return true;
        }

        var qNorm = GeoNameNormalizer.Normalize(query);
        var qPortNorm = GeoNameNormalizer.NormalizePortQuery(query);
        foreach (var value in values)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                continue;
            }

            if (value.Contains(query.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            var vNorm = GeoNameNormalizer.Normalize(value);
            if (ScoreNormalized(qNorm, vNorm) >= SuggestionMinScore)
            {
                return true;
            }

            var vPortNorm = GeoNameNormalizer.NormalizePortQuery(value);
            if (ScoreNormalized(qPortNorm, vPortNorm) >= SuggestionMinScore)
            {
                return true;
            }
        }

        return false;
    }

    private static void RegisterCountryAlias(
        Dictionary<string, GeoCountrySnapshot> map,
        GeoCountrySnapshot country,
        string? alias)
    {
        if (string.IsNullOrWhiteSpace(alias))
        {
            return;
        }

        map.TryAdd(alias, country);
    }

    private static void RegisterPortAlias(
        Dictionary<string, GeoPortSnapshot> map,
        GeoPortSnapshot port,
        string? alias)
    {
        if (string.IsNullOrWhiteSpace(alias))
        {
            return;
        }

        map.TryAdd(alias, port);
    }

    private static T? PickBest<T>(
        IReadOnlyList<T> items,
        string queryNorm,
        Func<T, string?[]> candidateSelectors,
        int minScore)
    {
        T? best = default;
        var bestScore = 0;
        foreach (var item in items)
        {
            foreach (var candidate in candidateSelectors(item))
            {
                if (string.IsNullOrWhiteSpace(candidate))
                {
                    continue;
                }

                var score = ScoreNormalized(queryNorm, candidate);
                if (score > bestScore)
                {
                    bestScore = score;
                    best = item;
                }
            }
        }

        return bestScore >= minScore ? best : default;
    }

    private static int BestScore(string queryNorm, params string?[] candidates)
    {
        var best = 0;
        foreach (var candidate in candidates)
        {
            if (string.IsNullOrWhiteSpace(candidate))
            {
                continue;
            }

            best = Math.Max(best, ScoreNormalized(queryNorm, GeoNameNormalizer.Normalize(candidate)));
            best = Math.Max(
                best,
                ScoreNormalized(
                    GeoNameNormalizer.NormalizePortQuery(queryNorm),
                    GeoNameNormalizer.NormalizePortQuery(candidate)));
        }

        return best;
    }

    private static int ScoreNormalized(string queryNorm, string candidateNorm)
    {
        if (string.IsNullOrEmpty(queryNorm) || string.IsNullOrEmpty(candidateNorm))
        {
            return 0;
        }

        if (queryNorm == candidateNorm)
        {
            return 100;
        }

        if (candidateNorm.StartsWith(queryNorm, StringComparison.Ordinal)
            || queryNorm.StartsWith(candidateNorm, StringComparison.Ordinal))
        {
            var shorter = Math.Min(queryNorm.Length, candidateNorm.Length);
            var longer = Math.Max(queryNorm.Length, candidateNorm.Length);
            return 78 + (shorter * 20 / Math.Max(longer, 1));
        }

        if (candidateNorm.Contains(queryNorm, StringComparison.Ordinal)
            || queryNorm.Contains(candidateNorm, StringComparison.Ordinal))
        {
            return 68 + Math.Min(queryNorm.Length, candidateNorm.Length);
        }

        var qTokens = queryNorm.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        var cTokens = candidateNorm.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (qTokens.Length == 0 || cTokens.Length == 0)
        {
            return 0;
        }

        var matched = qTokens.Count(token =>
            cTokens.Any(ct =>
                ct.Contains(token, StringComparison.Ordinal)
                || token.Contains(ct, StringComparison.Ordinal)));

        if (matched == 0)
        {
            return 0;
        }

        return 45 + (matched * 100 / qTokens.Length);
    }
}

/// <summary>Backward-compatible static entry points delegating to a supplied index or normalizer.</summary>
public static class GeoNameResolver
{
    public static string Normalize(string? value) => GeoNameNormalizer.Normalize(value);

    public static string NormalizePortQuery(string? value) => GeoNameNormalizer.NormalizePortQuery(value);

    public static GeoCountrySnapshot? ResolveCountry(string? input, IReadOnlyList<GeoCountrySnapshot> countries)
    {
        var index = GeoNameIndex.Build(countries, Array.Empty<GeoPortSnapshot>());
        return index.ResolveCountry(input);
    }

    public static GeoPortSnapshot? ResolvePort(string? input, IReadOnlyList<GeoPortSnapshot> ports) =>
        GeoNameIndex.Build(Array.Empty<GeoCountrySnapshot>(), ports).ResolvePortGlobal(input);

    public static IReadOnlyList<GeoCountrySnapshot> SuggestCountries(
        string? input,
        IReadOnlyList<GeoCountrySnapshot> countries,
        int max = 5) =>
        GeoNameIndex.Build(countries, Array.Empty<GeoPortSnapshot>()).SuggestCountries(input, max);

    public static IReadOnlyList<GeoPortSnapshot> SuggestPorts(
        string? input,
        IReadOnlyList<GeoPortSnapshot> ports,
        int max = 8)
    {
        if (ports.Count == 0)
        {
            return Array.Empty<GeoPortSnapshot>();
        }

        var countryId = ports[0].CountryId;
        return GeoNameIndex.Build(Array.Empty<GeoCountrySnapshot>(), ports).SuggestPorts(input, countryId, max);
    }

    public static int ScoreMatch(string? left, string? right) => GeoNameIndex.ScoreMatch(left, right);

    public static bool MatchesQuery(string query, params string?[] values) =>
        GeoNameIndex.MatchesQuery(query, values);
}
