namespace BusinessLayer.Helpers;

/// <summary>
/// Synonym clusters for intelligent admin search (Arabic + English).
/// Each cluster links related words to a dashboard section.
/// </summary>
public static class AdminSearchKnowledge
{
    public sealed record SearchCluster(
        string Id,
        string Section,
        string Route,
        string LabelEn,
        string LabelAr,
        params string[] Terms);

    public static readonly IReadOnlyList<SearchCluster> Clusters =
    [
        new("dashboard", "dashboard", "/", "Dashboard", "لوحة التحكم",
            "dashboard", "home", "overview", "summary", "stats", "statistics", "analytics",
            "لوحة", "لوحة التحكم", "الرئيسية", "إحصائيات", "تقارير", "ملخص", "مبيعات", "أرباح"),

        new("users", "users", "/users", "Users & suppliers", "المستخدمين",
            "user", "users", "supplier", "suppliers", "company", "companies", "client", "clients",
            "مستخدم", "مستخدمين", "المستخدمين", "مورد", "موردين", "شركة", "شركات", "عميل", "عملاء",
            "pending supplier", "approve supplier", "تفعيل", "موافقة", "license", "رخصة",
            "مراجعة", "مراجعة مستخدم", "مراجعة مورد", "بانتظار الموافقة", "مورد جديد"),

        new("user-documents", "users", "/users", "Supplier documents", "مستندات المورد",
            "licence", "license file", "ملف الرخصة", "رخصة تجارية", "رقم الرخصة", "company photos",
            "صور الشركة", "commercial register", "السجل التجاري", "tax number", "الرقم الضريبي",
            "reject supplier", "رفض", "رفض مورد", "سبب الرفض", "approve company", "شركة بانتظار"),

        new("ads", "ads", "/ads", "Ads & products", "الإعلانات",
            "ad", "ads", "product", "products", "listing", "إعلان", "إعلانات", "الإعلانات",
            "منتج", "منتجات", "retail", "booking", "offer", "offers", "request", "requests",
            "تجزئة", "بوكنج", "حجز", "featured", "مميز", "pending ad", "approved ad", "سعر", "وصف"),

        new("orders", "orders", "/orders", "Orders", "الطلبات",
            "order", "orders", "purchase", "payment", "payments", "invoice", "stripe",
            "طلب", "طلبات", "الطلبات", "شراء", "دفع", "فاتورة", "حالة الطلب", "order status",
            "delivered", "cancelled", "ملغي", "تسليم", "قيد الشحن", "pending order"),

        new("shipping", "shipping", "/shipping", "Shipping", "الشحن",
            "ship", "shipping", "shipment", "cargo", "freight", "logistics", "container", "port",
            "شحن", "الشحن", "شحنات", "ناقل", "شركة شحن", "شركات الشحن", "شحن دولي", "ميناء", "حاوية"),

        new("categories", "categories", "/categories", "Categories", "الأقسام",
            "category", "categories", "section", "classification", "قسم", "أقسام", "الأقسام",
            "تصنيف", "تصنيفات", "فئة", "فئات", "add category", "إضافة قسم"),

        new("notifications", "notifications", "/notifications", "Notifications", "الإشعارات",
            "notification", "notifications", "push", "fcm", "broadcast", "firebase",
            "إشعار", "إشعارات", "الإشعارات", "إرسال إشعار", "سجل الإشعارات", "جمهور",
            "مستخدم واحد", "notify suppliers", "notify shipping"),

        new("settings", "settings", "/settings", "Settings", "الإعدادات",
            "setting", "settings", "config", "system settings", "إعدادات", "الإعدادات",
            "إعدادات النظام", "password", "كلمة المرور", "تغيير كلمة المرور", "أمان"),

        new("settings-app-name", "settings", "/settings", "App name", "اسم التطبيق",
            "app name", "application name", "brand name", "app title", "platform name",
            "اسم التطبيق", "اسم البرنامج", "اسم المنصة", "اسم", "تطبيق", "التطبيق",
            "الراس الذكي", "سوق راس", "راس السوق", "ras al souq", "ras alsouq", "Ras Al Souq",
            "RasAlSouq", "rasalsouq", "راس", "الراس", "سوق", "معلومات التطبيق", "app info",
            "تطبيق الراس الذكي", "Al Ras Smart", "al ras app", "AlRasApp"),

        new("settings-support", "settings", "/settings", "Support contact", "بيانات الدعم",
            "support email", "support phone", "contact email", "phone number", "landline", "timezone", "address",
            "البريد الإلكتروني للدعم", "بريد الدعم", "رقم الهاتف", "رقم الأرضي", "المنطقة الزمنية", "عنوان", "العنوان"),

        new("settings-commissions", "settings", "/settings", "Commissions", "العمولات",
            "commission", "commissions", "profit", "margin", "fee", "percent",
            "عمولة", "عمولات", "العمولات", "ربح", "أرباح", "نسبة", "نسب الأرباح",
            "retail commission", "booking commission", "shipping commission", "عمولة التجزئة", "عمولة الشحن"),

        new("settings-ads-config", "settings", "/settings", "Ad settings", "إعدادات الإعلانات",
            "featured ad price", "ad duration", "ad display days", "display duration", "listing duration",
            "ad lifetime", "ad visibility days", "display period", "ad display duration", "expiration days",
            "سعر الإعلان المميز (درهم)", "سعر الإعلان المميز", "إعلان مميز", "مدة ظهور الإعلان (يوم)",
            "مدة ظهور الإعلان", "مدة ظهور الاعلان", "مدة الظهور", "مدة ظهور", "ظهور الإعلان",
            "أيام الظهور", "ايام الظهور", "عدد أيام الإعلان", "مدة الإعلان", "مدة الاعلان",
            "مدة نشر الإعلان", "أيام النشر", "إعدادات الإعلانات", "درهم", "adDisplayDurationDays",
            "featuredAdPriceAed", "promoted ad price", "premium ad price", "ترقية إعلان"),

        new("chat", "chat", "/chat", "Chat", "المحادثة",
            "chat", "conversation", "messaging", "inbox", "محادثة", "المحادثة", "دردشة", "مراسلة"),

        new("pending-users", "users", "/users", "Pending suppliers", "موردين بانتظار الموافقة",
            "pending supplier", "pending company", "pending user", "مورد بانتظار", "موردين بانتظار",
            "شركات بانتظار", "تسجيل جديد", "new registration", "awaiting activation"),

        new("pending", "ads", "/ads", "Pending approval", "بانتظار الموافقة",
            "pending", "waiting", "review", "under review", "unapproved", "awaiting",
            "بانتظار", "مراجعة", "قيد المراجعة", "بانتظار الموافقة", "pending approval"),

        new("finance", "orders", "/orders", "Payments", "المدفوعات",
            "money", "revenue", "sales", "stripe", "usd", "aed", "payment", "refund",
            "مال", "إيراد", "مبلغ", "دفع اونلاين", "استرداد"),
    ];

    public static IReadOnlyList<string> ExpandQuery(string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return [];
        }

        var normalized = AdminSearchNormalizer.Normalize(query);
        var terms = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { normalized };

        foreach (var word in AdminSearchNormalizer.SplitWords(normalized))
        {
            terms.Add(word);
        }

        foreach (var cluster in Clusters)
        {
            if (ScoreCluster(normalized, cluster) > 0)
            {
                foreach (var term in cluster.Terms)
                {
                    if (term.Length >= 2)
                    {
                        terms.Add(term.ToLowerInvariant());
                    }
                }
            }
        }

        foreach (var cluster in Clusters)
        {
            foreach (var term in cluster.Terms)
            {
                if (term.Length < 3) continue;

                if (FuzzyMatches(normalized, term) || terms.Any(q => FuzzyMatches(q, term)))
                {
                    terms.Add(term.ToLowerInvariant());
                    foreach (var related in cluster.Terms.Where(x => x.Length >= 3).Take(12))
                    {
                        terms.Add(related.ToLowerInvariant());
                    }
                }
            }
        }

        return terms.Where(t => t.Length >= 2).Take(32).ToList();
    }

    public static string BuildSectionRoute(string route, string query)
    {
        var trimmed = query.Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return route;
        }

        var separator = route.Contains('?') ? "&" : "?";
        return $"{route}{separator}search={Uri.EscapeDataString(trimmed)}";
    }

    public static int ScoreCluster(string query, SearchCluster cluster)
    {
        var best = Math.Max(
            ScoreQueryAgainstText(query, cluster.LabelEn),
            ScoreQueryAgainstText(query, cluster.LabelAr));

        foreach (var term in cluster.Terms)
        {
            best = Math.Max(best, ScoreQueryAgainstText(query, term));
        }

        return best;
    }

    public static int ScoreQueryAgainstText(string query, string text)
    {
        if (string.IsNullOrWhiteSpace(query) || string.IsNullOrWhiteSpace(text))
        {
            return 0;
        }

        var normalizedQuery = AdminSearchNormalizer.Normalize(query);
        var normalizedText = AdminSearchNormalizer.Normalize(text);
        var queryWords = AdminSearchNormalizer.SplitWords(normalizedQuery);
        var textWords = AdminSearchNormalizer.SplitWords(normalizedText);
        var isMultiWordQuery = queryWords.Count >= 2;

        var best = ScoreTerm(normalizedQuery, normalizedText);
        if (best >= 70)
        {
            return best;
        }

        if (isMultiWordQuery)
        {
            var matched = 0;
            foreach (var queryWord in queryWords)
            {
                var wordHit = textWords.Any(textWord => ScoreTerm(queryWord, textWord) >= 70)
                    || ScoreTerm(queryWord, normalizedText) >= 55;
                if (wordHit)
                {
                    matched++;
                }
            }

            var ratio = queryWords.Count == 0 ? 0 : (double)matched / queryWords.Count;
            if (ratio >= 1)
            {
                best = Math.Max(best, queryWords.Count >= 3 ? 100 : 95);
            }
            else if (ratio >= 0.75)
            {
                best = Math.Max(best, 88);
            }
            else if (ratio >= 0.5)
            {
                best = Math.Max(best, 72);
            }
            else
            {
                foreach (var queryWord in queryWords)
                {
                    best = Math.Max(best, Math.Min(ScoreTerm(queryWord, normalizedText), 55));
                    foreach (var textWord in textWords)
                    {
                        best = Math.Max(best, Math.Min(ScoreTerm(queryWord, textWord), 55));
                    }
                }
            }

            return best;
        }

        foreach (var queryWord in queryWords)
        {
            best = Math.Max(best, ScoreTerm(queryWord, normalizedText));
            foreach (var textWord in textWords)
            {
                best = Math.Max(best, ScoreTerm(queryWord, textWord));
            }
        }

        foreach (var textWord in textWords)
        {
            best = Math.Max(best, ScoreTerm(normalizedQuery, textWord));
        }

        return best;
    }

    private static int ClusterSpecificity(SearchCluster cluster)
    {
        if (cluster.Id.StartsWith("field-", StringComparison.Ordinal)) return 50;
        if (cluster.Id.StartsWith("settings-", StringComparison.Ordinal)) return 40;
        if (cluster.Id.StartsWith("user-", StringComparison.Ordinal)) return 35;
        if (cluster.Id.StartsWith("ui-labels-", StringComparison.Ordinal)) return 20;

        var generic = new HashSet<string>(StringComparer.Ordinal)
        {
            "ads", "users", "orders", "shipping", "categories",
            "notifications", "settings", "dashboard", "chat",
        };
        return generic.Contains(cluster.Id) ? 0 : 10;
    }

    public static IReadOnlyList<AdminSearchSuggestionDto> GetSuggestions(string? query, int limit = 8)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return Clusters.Take(limit).Select(c => new AdminSearchSuggestionDto
            {
                Text = c.LabelEn,
                TextAr = c.LabelAr,
                Section = c.Section,
                Route = c.Route,
                Kind = "section"
            }).ToList();
        }

        var trimmedQuery = query.Trim();
        var normalized = AdminSearchNormalizer.Normalize(trimmedQuery);
        var scored = new List<(SearchCluster Cluster, string Term, int Score)>();

        foreach (var cluster in Clusters)
        {
            var clusterScore = ScoreCluster(normalized, cluster);
            if (clusterScore > 0)
            {
                scored.Add((cluster, cluster.LabelEn, clusterScore + 15));
            }

            foreach (var term in cluster.Terms)
            {
                var score = ScoreQueryAgainstText(normalized, term);
                if (score > 0)
                {
                    scored.Add((cluster, term, score));
                }
            }
        }

        return scored
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Term.Length)
            .Take(limit)
            .Select(x => new AdminSearchSuggestionDto
            {
                Text = x.Term,
                TextAr = x.Cluster.LabelAr,
                Section = x.Cluster.Section,
                Route = BuildSectionRoute(x.Cluster.Route, trimmedQuery),
                Kind = "keyword"
            })
            .ToList();
    }

    public static string ResolvePrimaryRoute(string? query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return "/search";
        }

        var trimmed = query.Trim();
        if (trimmed.Contains('@'))
        {
            return BuildSectionRoute("/users", trimmed);
        }

        var normalized = AdminSearchNormalizer.Normalize(trimmed);
        var best = Clusters
            .Select(c => new
            {
                Cluster = c,
                Score = ScoreCluster(normalized, c),
                Specificity = ClusterSpecificity(c),
            })
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.Specificity)
            .FirstOrDefault();

        if (best is { Score: >= 35 })
        {
            return BuildSectionRoute(best.Cluster.Route, trimmed);
        }

        return $"/search?q={Uri.EscapeDataString(trimmed)}";
    }

    private static int ScoreTerm(string query, string term)
    {
        if (string.IsNullOrWhiteSpace(term)) return 0;
        var q = AdminSearchNormalizer.Normalize(query);
        var t = AdminSearchNormalizer.Normalize(term);
        if (string.IsNullOrWhiteSpace(q) || string.IsNullOrWhiteSpace(t)) return 0;
        if (t == q) return 100;
        if (t.StartsWith(q, StringComparison.Ordinal)) return 80;
        if (q.StartsWith(t, StringComparison.Ordinal)) return 70;
        if (t.Contains(q, StringComparison.Ordinal)) return 55;
        if (q.Contains(t, StringComparison.Ordinal)) return 45;
        return FuzzyMatches(q, t) ? 35 : 0;
    }

    private static bool FuzzyMatches(string a, string b)
    {
        if (string.IsNullOrWhiteSpace(a) || string.IsNullOrWhiteSpace(b)) return false;
        a = a.ToLowerInvariant();
        b = b.ToLowerInvariant();
        if (Math.Abs(a.Length - b.Length) > 2) return false;

        var distance = LevenshteinDistance(a, b);
        var threshold = a.Length <= 4 ? 1 : 2;
        return distance <= threshold;
    }

    private static int LevenshteinDistance(string a, string b)
    {
        var n = a.Length;
        var m = b.Length;
        var d = new int[n + 1, m + 1];
        for (var i = 0; i <= n; i++) d[i, 0] = i;
        for (var j = 0; j <= m; j++) d[0, j] = j;
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
}

public sealed class AdminSearchSuggestionDto
{
    public string Text { get; set; } = string.Empty;
    public string TextAr { get; set; } = string.Empty;
    public string Section { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string Kind { get; set; } = "keyword";
}

public sealed class AdminGlobalSearchResultDto
{
    public string Query { get; set; } = string.Empty;
    public IReadOnlyList<string> ExpandedTerms { get; set; } = [];
    public string PrimaryRoute { get; set; } = "/search";
    public IReadOnlyList<AdminSearchSuggestionDto> Suggestions { get; set; } = [];
    public AdminGlobalSearchSectionDto Ads { get; set; } = new();
    public AdminGlobalSearchSectionDto Users { get; set; } = new();
    public AdminGlobalSearchSectionDto Orders { get; set; } = new();
    public AdminGlobalSearchSectionDto Shipping { get; set; } = new();
    public AdminGlobalSearchSectionDto Categories { get; set; } = new();
    public AdminGlobalSearchSectionDto Sections { get; set; } = new();
}

public sealed class AdminGlobalSearchSectionDto
{
    public string Section { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public int Total { get; set; }
    public IReadOnlyList<AdminGlobalSearchHitDto> Items { get; set; } = [];
}

public sealed class AdminGlobalSearchHitDto
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Subtitle { get; set; }
    public string Route { get; set; } = string.Empty;
    public string? Meta { get; set; }
}
