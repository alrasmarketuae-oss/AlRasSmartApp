using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Helpers;

/// <summary>
/// Resolves product text for admin UI from ContentTranslations, skipping
/// corrupted legacy varchar values (Arabic stored as "????").
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

    public static string ResolveName(ProductFieldTranslations? tr, string? legacyNameEn) =>
        Prefer(legacyNameEn, tr?.NameEn, tr?.NameAr);

    public static string ResolveNameForLocale(
        ProductFieldTranslations? tr,
        string? legacyNameEn,
        string? language) =>
        IsArabicLanguage(language)
            ? Prefer(tr?.NameAr, tr?.NameEn, legacyNameEn)
            : Prefer(legacyNameEn, tr?.NameEn, tr?.NameAr);

    public static string? ResolveDescription(ProductFieldTranslations? tr, string? legacyDescriptionEn) =>
        PreferOrNull(legacyDescriptionEn, tr?.DescriptionEn, tr?.DescriptionAr);

    public static string? ResolveDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacyDescriptionEn,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(tr?.DescriptionAr, tr?.DescriptionEn, legacyDescriptionEn)
            : PreferOrNull(legacyDescriptionEn, tr?.DescriptionEn, tr?.DescriptionAr);

    public static string? ResolveRetailDescription(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(legacy, tr?.RetailDescriptionEn, tr?.RetailDescriptionAr);

    public static string? ResolveRetailDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(tr?.RetailDescriptionAr, tr?.RetailDescriptionEn, legacy)
            : PreferOrNull(legacy, tr?.RetailDescriptionEn, tr?.RetailDescriptionAr);

    public static string? ResolveSupplierNotes(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(legacy, tr?.SupplierNotesEn, tr?.SupplierNotesAr);

    public static string? ResolveSupplierNotesForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? PreferOrNull(tr?.SupplierNotesAr, tr?.SupplierNotesEn, legacy)
            : PreferOrNull(legacy, tr?.SupplierNotesEn, tr?.SupplierNotesAr);

    public static string ResolveShippingDescription(ProductFieldTranslations? tr, string? legacy) =>
        Prefer(legacy, tr?.ShippingDescriptionEn, tr?.ShippingDescriptionAr);

    public static string ResolveShippingDescriptionForLocale(
        ProductFieldTranslations? tr,
        string? legacy,
        string? language) =>
        IsArabicLanguage(language)
            ? Prefer(tr?.ShippingDescriptionAr, tr?.ShippingDescriptionEn, legacy)
            : Prefer(legacy, tr?.ShippingDescriptionEn, tr?.ShippingDescriptionAr);

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
