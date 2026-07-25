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

    public static string ResolveName(ProductFieldTranslations? tr, string? legacyNameEn) =>
        Prefer(legacyNameEn, tr?.NameEn, tr?.NameAr);

    public static string? ResolveDescription(ProductFieldTranslations? tr, string? legacyDescriptionEn) =>
        PreferOrNull(legacyDescriptionEn, tr?.DescriptionEn, tr?.DescriptionAr);

    public static string? ResolveRetailDescription(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(legacy, tr?.RetailDescriptionEn, tr?.RetailDescriptionAr);

    public static string? ResolveSupplierNotes(ProductFieldTranslations? tr, string? legacy) =>
        PreferOrNull(legacy, tr?.SupplierNotesEn, tr?.SupplierNotesAr);

    public static string ResolveShippingDescription(ProductFieldTranslations? tr, string? legacy) =>
        Prefer(legacy, tr?.ShippingDescriptionEn, tr?.ShippingDescriptionAr);

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
