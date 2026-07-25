using BusinessLayer.Constants;
using System.Globalization;

namespace BusinessLayer.Helpers;

public static class AdminMappings
{
    public static bool IsCustomerCompanyAccount(byte roleId, bool? isCustomer) =>
        roleId == 2 && isCustomer == true;

    public static string GetRoleName(byte roleId, bool? isCustomer = null) =>
        IsCustomerCompanyAccount(roleId, isCustomer)
            ? "Customer"
            : roleId switch
            {
                1 => "Admin",
                2 => "Seller",
                3 => "Buyer",
                5 => "ShippingCompany",
                _ => "Unknown"
            };

    public static string GetRoleLabelAr(byte roleId, bool? isCustomer = null) =>
        IsCustomerCompanyAccount(roleId, isCustomer)
            ? "عميل"
            : roleId switch
            {
                1 => "مدير",
                2 => "مورد",
                3 => "مشتري",
                5 => "شركة شحن",
                _ => "غير معروف"
            };

    /// <summary>تسمية النوع كما في واجهة المستخدمين (مورد / عميل).</summary>
    public static string GetUserTypeLabelAr(byte roleId, bool? isCustomer = null) =>
        IsCustomerCompanyAccount(roleId, isCustomer)
            ? "عميل"
            : roleId switch
            {
                2 => "مورد",
                3 => "عميل",
                1 => "مدير",
                5 => "شركة شحن",
                _ => "غير معروف"
            };

    public static string GetUserStatusLabelAr(
        bool isActive,
        bool isVerified,
        byte roleId = 0,
        bool isRejected = false,
        bool isApproved = true,
        bool hasPendingProfileChanges = false)
    {
        if (isRejected)
        {
            return "مرفوض";
        }

        if (hasPendingProfileChanges)
        {
            return "بانتظار الموافقة";
        }

        if (!isActive)
        {
            if (RoleIds.RequiresAdminApproval(roleId) && !isApproved)
            {
                return "بانتظار الموافقة";
            }

            return "موقوف";
        }

        return isVerified ? "مكتمل" : "غير مكتمل";
    }

    public static string GetProductStatusLabelAr(byte? status, bool? isApproved) =>
        ProductStatusCodes.ToDisplayName(status, isApproved) switch
        {
            "Under Review" => "قيد المراجعة",
            "Active" => "نشط",
            "Paused" => "موقوف",
            "Rejected" => "مرفوض",
            _ => "غير معروف"
        };

    public static string GetOrderStatusLabelAr(byte statusId) =>
        OrderStatusCodes.GetNameAr(statusId);

    public static string FormatAmount(decimal amount) =>
        $"{amount.ToString("N0", CultureInfo.InvariantCulture)} AED";

    public static string GetTimeAgo(DateTime createdAt, DateTime utcNow)
    {
        var span = utcNow - UtcDateTimeHelper.AsUtc(createdAt);
        if (span.TotalMinutes < 1) return "الآن";
        if (span.TotalMinutes < 60) return $"منذ {(int)span.TotalMinutes} دقيقة";
        if (span.TotalHours < 24) return $"منذ {(int)span.TotalHours} ساعة";
        return $"منذ {(int)span.TotalDays} يوم";
    }

    public static string GetArabicMonth(int month) => month switch
    {
        1 => "يناير",
        2 => "فبراير",
        3 => "مارس",
        4 => "أبريل",
        5 => "مايو",
        6 => "يونيو",
        7 => "يوليو",
        8 => "أغسطس",
        9 => "سبتمبر",
        10 => "أكتوبر",
        11 => "نوفمبر",
        12 => "ديسمبر",
        _ => month.ToString()
    };

    public static decimal PercentChange(decimal current, decimal previous)
    {
        if (previous <= 0)
        {
            return current > 0 ? 100m : 0m;
        }

        return Math.Round((current - previous) / previous * 100m, 1);
    }

    public static bool IsProductEditResubmit(
        DateTime createdAt,
        DateTime? updatedAt,
        byte? status,
        bool? isApproved,
        string? pendingProductChanges = null)
    {
        // Real edit: snapshot captured while the previous live ad was approved.
        if (PendingProductChangeHelper.IndicatesPreviouslyApprovedEdit(pendingProductChanges))
        {
            return true;
        }

        // Accidental create-time PendingProductChanges (IsApproved=false) is not an edit.
        if (!string.IsNullOrWhiteSpace(pendingProductChanges))
        {
            return false;
        }

        return ProductStatusCodes.IsPendingReview(status, isApproved)
            && updatedAt.HasValue
            && updatedAt.Value > createdAt.AddMinutes(1);
    }
}
