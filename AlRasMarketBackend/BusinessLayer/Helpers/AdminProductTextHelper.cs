using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Helpers;

/// <summary>
/// Resolves product text for admin UI from ContentTranslations, skipping
/// corrupted legacy varchar values (Arabic stored as "????") and treating
/// Arabic script in legacy *En columns as Arabic source text.
/// </summary>
public static class AdminProductTextHelper
{
    public static bool IsUsable(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var significant = value.Where(c => !char.IsWhiteSpace(c)).ToArray();
        if (significant.Length == 0)
        {
            return false;
        }

        // Non-Unicode varchar columns turn Arabic into question marks.
        return !significant.All(c => c == '?');
    }

    /// <summary>
    /// True when the text is predominantly Arabic script (same heuristic as public product mapping).
    /// </summary>
    public static bool LooksLikeArabic(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        var arabic = 0;
        var latin = 0;
        foreach (var ch in text)
        {
            if (ch is >= '\u0600' and <= '\u06FF')
            {
                arabic++;
            }
            else if (char.IsLetter(ch))
            {
                latin++;
            }
        }

        return arabic > 0 && arabic >= latin;
    }

    public static string Prefer(params string?[] values)
    {
        foreach (var value in values)
        {
            if (IsUsable(value))
            {
                return value!.Trim();
            }
        }

        return string.Empty;
    }

    public static string? PreferOrNull(params string?[] values)
    {
        var text = Prefer(values);
        return string.IsNullOrEmpty(text) ? null : text;
    }

    public static bool IsArabicLanguage(string? language) =>
        language?.StartsWith("ar", StringComparison.OrdinalIgnoreCase) == true;

    /// <summary>Legacy *En column value usable as English (not Arabic script).</summary>
    private static string? EnglishLegacy(string? legacy) =>
        IsUsable(legacy) && !LooksLikeArabic(legacy) ? legacy : null;

    /// <summary>Legacy *En column value that is actually Arabic source text.</summary>
    private static string? ArabicLegacy(string? legacy) =>
        IsUsable(legacy) && LooksLikeArabic(legacy) ? legacy : null;

    public static string ResolveName(ProductFieldTranslations? tr, string? legacyNameEn) =>
        Prefer(tr?.NameEn, EnglishLegacy(legacyNameEn), tr?.NameAr, ArabicLegacy(legacyNameEn));

    public static string ResolveNameForLocale(
        ProductFieldTranslations? tr,
        string? legacyNameEn,
        string? language) =>
        IsArabicLanguage(language)
            ? Prefer(tr?.NameAr, ArabicLegacy(legacyNameEn), tr?.NameEn, EnglishLegacy(legacyNameEn))
            : Prefer(tr?.NameEn, EnglishLegacy(legacyNameEn), tr?.NameAr, ArabicLegacy(legacyNameEn));

    public static string? ResolveDescription(ProductFieldTranslations? tr, string? legacyDescriptionEn) =>
        PreferOrNull(
            tr?.DescriptionEn,
            EnglishLegacy(legacyDescriptionEn),
            tr?.DescriptionAr,
            ArabicLegacy(legacyDescriptionEn));

    public static string? ResolveDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacyDescriptionEn,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(
                tr?.DescriptionAr,
                ArabicLegacy(legacyDescriptionEn),
                tr?.DescriptionEn,
                EnglishLegacy(legacyDescriptionEn))
            : PreferOrNull(
                tr?.DescriptionEn,
                EnglishLegacy(legacyDescriptionEn),
                tr?.DescriptionAr,
                ArabicLegacy(legacyDescriptionEn));

    public static string? ResolveRetailDescription(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(
            tr?.RetailDescriptionEn,
            EnglishLegacy(legacy),
            tr?.RetailDescriptionAr,
            ArabicLegacy(legacy));

    public static string? ResolveRetailDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(
                tr?.RetailDescriptionAr,
                ArabicLegacy(legacy),
                tr?.RetailDescriptionEn,
                EnglishLegacy(legacy))
            : PreferOrNull(
                tr?.RetailDescriptionEn,
                EnglishLegacy(legacy),
                tr?.RetailDescriptionAr,
                ArabicLegacy(legacy));

    public static string? ResolveSupplierNotes(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(
            tr?.SupplierNotesEn,
            EnglishLegacy(legacy),
            tr?.SupplierNotesAr,
            ArabicLegacy(legacy));

    public static string? ResolveSupplierNotesForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(
                tr?.SupplierNotesAr,
                ArabicLegacy(legacy),
                tr?.SupplierNotesEn,
                EnglishLegacy(legacy))
            : PreferOrNull(
                tr?.SupplierNotesEn,
                EnglishLegacy(legacy),
                tr?.SupplierNotesAr,
                ArabicLegacy(legacy));

    public static string ResolveShippingDescription(ProductFieldTranslations? tr, string? legacy) =>
        Prefer(
            tr?.ShippingDescriptionEn,
            EnglishLegacy(legacy),
            tr?.ShippingDescriptionAr,
            ArabicLegacy(legacy));

    public static string ResolveShippingDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? Prefer(
                tr?.ShippingDescriptionAr,
                ArabicLegacy(legacy),
                tr?.ShippingDescriptionEn,
                EnglishLegacy(legacy))
            : Prefer(
                tr?.ShippingDescriptionEn,
                EnglishLegacy(legacy),
                tr?.ShippingDescriptionAr,
                ArabicLegacy(legacy));

    public static string LocalizeCategoryName(
        byte? categoryId,
        string fallbackEn,
        IStaticReferenceCache cache,
        string? language)
    {
        if (categoryId is > 0)
        {
            var category = cache.FindCategoryById(categoryId.Value);
            if (category is not null)
            {
                return IsArabicLanguage(language) && IsUsable(category.NameAr)
                    ? category.NameAr!.Trim()
                    : category.NameEn;
            }
        }

        return fallbackEn;
    }

    public static string LocalizeCountryName(
        short? countryId,
        string? fallbackEn,
        IStaticReferenceCache cache,
        string? language)
    {
        if (countryId is > 0)
        {
            var country = cache.FindCountryById(countryId.Value);
            if (country is not null)
            {
                return IsArabicLanguage(language)
                    ? Prefer(country.CountryNameAr, country.CountryNameEn)
                    : Prefer(country.CountryNameEn, country.CountryNameAr);
            }
        }

        return fallbackEn ?? string.Empty;
    }

    public static string LocalizePortName(
        int? portId,
        string? fallbackEn,
        IStaticReferenceCache cache,
        string? language)
    {
        if (portId is > 0)
        {
            var port = cache.FindPortById(portId.Value);
            if (port is not null)
            {
                return IsArabicLanguage(language)
                    ? Prefer(port.PortNameAr, port.PortNameEn)
                    : Prefer(port.PortNameEn, port.PortNameAr);
            }
        }

        return fallbackEn ?? string.Empty;
    }

    public static void ApplyToOrderDto(
        AdminOrderListItemDto dto,
        ProductFieldTranslations? tr,
        string? legacyNameEn,
        string? legacyDescriptionEn,
        string? legacyShippingDescriptionEn)
    {
        var name = ResolveName(tr, legacyNameEn);
        if (!string.IsNullOrEmpty(name))
        {
            dto.ProductName = name;
        }

        var description = ResolveDescription(tr, legacyDescriptionEn);
        if (description is not null)
        {
            dto.ProductDescription = description;
        }

        var shipping = ResolveShippingDescription(tr, legacyShippingDescriptionEn);
        if (!string.IsNullOrEmpty(shipping))
        {
            dto.ShippingDescription = shipping;
        }
    }
}
