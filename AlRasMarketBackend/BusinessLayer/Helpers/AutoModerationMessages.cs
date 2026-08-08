namespace BusinessLayer.Helpers;

/// <summary>
/// Canonical auto-moderation rejection texts. These are stored in the seller-facing
/// SupplierNotes field while an ad is rejected so the seller can see why. They must
/// NOT survive into the public ad details after the ad is approved, so approval clears
/// any SupplierNotes value that matches one of these reasons.
/// </summary>
public static class AutoModerationMessages
{
    /// <summary>
    /// Fixed closing hint appended to every auto-moderation reason. Used as a stable
    /// marker so a rejection reason (even a specific, dynamically built one) is never
    /// mistaken for a public note and is cleared on approval.
    /// </summary>
    public const string ResubmitHintEn = "Remove the violations, then edit and resubmit — we will scan again.";

    public const string ResubmitHintAr = "أزل المخالفات ثم عدّل الإعلان وأعد الإرسال — سنعيد الفحص.";

    // Legacy generic reasons (kept so previously stored notes are still recognised).
    public const string RejectReasonEn =
        "Contains insults/profanity, phone/contact details, WhatsApp, website, seller/company name, " +
        "seller logo, or commercial brand logo (including in the ad title). " +
        "Origin country and product specs (e.g. Sudanese peanuts) are allowed. " +
        "Remove violations, then edit and resubmit — we will scan again.";

    public const string RejectReasonAr =
        "يحتوي على ألفاظ نابية/إساءة أو رقم هاتف أو بيانات تواصل أو واتساب أو موقع أو اسم شركة/بائع " +
        "أو شعار البائع أو شعار ماركة (بما في ذلك اسم الإعلان). " +
        "مسموح ببلد المنشأ والمواصفات (مثل: حبوب سودانية). " +
        "أزل المخالفات ثم عدّل الإعلان وأعد الإرسال — سنعيد الفحص بنفس المنطق.";

    /// <summary>
    /// Builds a clear, seller-facing rejection reason (English + Arabic) that names the
    /// specific violation categories detected. Callers choose which language to show
    /// based on the ad's created language.
    /// </summary>
    public static (string En, string Ar) BuildReason(IEnumerable<string>? violationKinds)
    {
        var kinds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var kind in violationKinds ?? [])
        {
            if (!string.IsNullOrWhiteSpace(kind))
            {
                kinds.Add(kind.Trim().ToLowerInvariant());
            }
        }

        bool Has(params string[] candidates) => candidates.Any(kinds.Contains);

        var en = new List<string>();
        var ar = new List<string>();

        void AddCategory(bool present, string english, string arabic)
        {
            if (present)
            {
                en.Add(english);
                ar.Add(arabic);
            }
        }

        AddCategory(
            Has("phone", "whatsapp", "email", "url", "social", "contact_keyword", "qr_contact"),
            "contact details (phone, WhatsApp, email, website, or a social handle)",
            "بيانات تواصل (هاتف أو واتساب أو بريد إلكتروني أو موقع أو حساب تواصل اجتماعي)");

        AddCategory(
            Has("insult", "profanity", "hate"),
            "insults or inappropriate language",
            "ألفاظ نابية أو غير لائقة");

        AddCategory(
            Has("seller_company_name", "seller_logo", "watermark"),
            "your store/company name or a logo/watermark",
            "اسم متجرك/شركتك أو شعارك أو علامة مائية");

        AddCategory(
            Has("brand_name", "product_brand", "brand_logo"),
            "a commercial brand name or trademark logo",
            "اسم علامة تجارية أو شعار ماركة");

        if (en.Count == 0)
        {
            en.Add("content that violates our ad policy");
            ar.Add("محتوى يخالف سياسة الإعلانات");
        }

        var reasonEn =
            $"Your ad was rejected because it contains {JoinEnglish(en)}. " +
            "Origin country and product specifications (e.g. Sudanese peanuts) are allowed. " +
            ResubmitHintEn;

        var reasonAr =
            $"تم رفض إعلانك لأنه يحتوي على {JoinArabic(ar)}. " +
            "مسموح ببلد المنشأ ومواصفات المنتج (مثل: حبوب سودانية). " +
            ResubmitHintAr;

        return (reasonEn, reasonAr);
    }

    private static string JoinEnglish(IReadOnlyList<string> parts)
    {
        if (parts.Count == 1) return parts[0];
        if (parts.Count == 2) return $"{parts[0]} and {parts[1]}";
        return $"{string.Join(", ", parts.Take(parts.Count - 1))}, and {parts[^1]}";
    }

    private static string JoinArabic(IReadOnlyList<string> parts)
    {
        if (parts.Count == 1) return parts[0];
        return $"{string.Join("، ", parts.Take(parts.Count - 1))} و{parts[^1]}";
    }

    /// <summary>
    /// True when the supplied text is an auto-moderation rejection reason that should
    /// never appear in the public ad details (e.g. after an approve following a reject).
    /// Detected by the stable closing hint so dynamic, specific reasons are covered too.
    /// </summary>
    public static bool IsAutoModerationRejectionNote(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        var trimmed = text.Trim();
        return trimmed.Contains(ResubmitHintEn, StringComparison.OrdinalIgnoreCase)
            || trimmed.Contains(ResubmitHintAr, StringComparison.Ordinal)
            || string.Equals(trimmed, RejectReasonEn, StringComparison.OrdinalIgnoreCase)
            || string.Equals(trimmed, RejectReasonAr, StringComparison.Ordinal);
    }
}
