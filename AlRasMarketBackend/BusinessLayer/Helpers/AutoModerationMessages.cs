namespace BusinessLayer.Helpers;

/// <summary>
/// Canonical auto-moderation rejection texts. These are stored in the seller-facing
/// SupplierNotes field while an ad is rejected so the seller can see why. They must
/// NOT survive into the public ad details after the ad is approved, so approval clears
/// any SupplierNotes value that matches one of these reasons.
/// </summary>
public static class AutoModerationMessages
{
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
    /// True when the supplied text is an auto-moderation rejection reason that should
    /// never appear in the public ad details (e.g. after an approve following a reject).
    /// </summary>
    public static bool IsAutoModerationRejectionNote(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        var trimmed = text.Trim();
        return string.Equals(trimmed, RejectReasonEn, StringComparison.OrdinalIgnoreCase)
            || string.Equals(trimmed, RejectReasonAr, StringComparison.Ordinal);
    }
}
