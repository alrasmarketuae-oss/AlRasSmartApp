using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Helpers;

public static class AdminUserTextHelper
{
    public static void ApplyToUserListItem(AdminUserListItemDto dto, UserFieldTranslations? tr)
    {
        if (tr is null)
        {
            return;
        }

        dto.FullNameEn = AdminProductTextHelper.PreferOrNull(
            tr.FullNameEn,
            AdminProductTextHelper.LooksLikeArabic(dto.FullName) ? null : dto.FullName,
            tr.FullNameAr);
        dto.FullNameAr = AdminProductTextHelper.PreferOrNull(
            tr.FullNameAr,
            AdminProductTextHelper.LooksLikeArabic(dto.FullName) ? dto.FullName : null,
            tr.FullNameEn);
        dto.CompanyNameEn = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameEn,
            AdminProductTextHelper.LooksLikeArabic(dto.CompanyName) ? null : dto.CompanyName,
            tr.CompanyNameAr);
        dto.CompanyNameAr = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameAr,
            AdminProductTextHelper.LooksLikeArabic(dto.CompanyName) ? dto.CompanyName : null,
            tr.CompanyNameEn);
    }

    public static void ApplyToUserDetail(AdminUserDetailDto dto, UserFieldTranslations? tr)
    {
        if (tr is null)
        {
            return;
        }

        dto.FullNameEn = AdminProductTextHelper.PreferOrNull(
            tr.FullNameEn,
            AdminProductTextHelper.LooksLikeArabic(dto.FullName) ? null : dto.FullName,
            tr.FullNameAr);
        dto.FullNameAr = AdminProductTextHelper.PreferOrNull(
            tr.FullNameAr,
            AdminProductTextHelper.LooksLikeArabic(dto.FullName) ? dto.FullName : null,
            tr.FullNameEn);
        dto.CompanyNameEn = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameEn,
            AdminProductTextHelper.LooksLikeArabic(dto.CompanyName) ? null : dto.CompanyName,
            tr.CompanyNameAr);
        dto.CompanyNameAr = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameAr,
            AdminProductTextHelper.LooksLikeArabic(dto.CompanyName) ? dto.CompanyName : null,
            tr.CompanyNameEn);
    }

    public static void ApplyCustomerNames(AdminOrderListItemDto dto, UserFieldTranslations? tr)
    {
        if (tr is null)
        {
            return;
        }

        dto.CustomerNameEn = AdminProductTextHelper.PreferOrNull(
            tr.FullNameEn,
            AdminProductTextHelper.LooksLikeArabic(dto.CustomerName) ? null : dto.CustomerName,
            tr.FullNameAr);
        dto.CustomerNameAr = AdminProductTextHelper.PreferOrNull(
            tr.FullNameAr,
            AdminProductTextHelper.LooksLikeArabic(dto.CustomerName) ? dto.CustomerName : null,
            tr.FullNameEn);
    }

    public static void ApplySupplierNames(AdminOrderListItemDto dto, UserFieldTranslations? tr)
    {
        if (tr is null)
        {
            return;
        }

        var legacy = dto.SupplierName;
        dto.SupplierNameEn = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameEn,
            tr.FullNameEn,
            AdminProductTextHelper.LooksLikeArabic(legacy) ? null : legacy,
            tr.CompanyNameAr,
            tr.FullNameAr);
        dto.SupplierNameAr = AdminProductTextHelper.PreferOrNull(
            tr.CompanyNameAr,
            tr.FullNameAr,
            AdminProductTextHelper.LooksLikeArabic(legacy) ? legacy : null,
            tr.CompanyNameEn,
            tr.FullNameEn);
    }
}
