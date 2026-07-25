namespace BusinessLayer.Helpers;

/// <summary>
/// Static Arabic labels for catalog metadata that has no DB *Ar column (units, product types, statuses).
/// </summary>
public static class CatalogLocalizationHelper
{
    public static string StatusNameEn(byte? status, bool? isApproved) =>
        ProductStatusCodes.ToDisplayName(status, isApproved);

    public static string StatusNameAr(byte? status, bool? isApproved) =>
        ProductStatusCodes.Normalize(status, isApproved) switch
        {
            ProductStatusCodes.UnderReview => "قيد المراجعة",
            ProductStatusCodes.Active => "نشط",
            ProductStatusCodes.Paused => "متوقف",
            ProductStatusCodes.Rejected => "مرفوض",
            _ => "غير معروف"
        };

    public static string ApprovalStatusEn(byte? status, bool? isApproved)
    {
        if (ProductStatusCodes.Normalize(status, isApproved) == ProductStatusCodes.Rejected)
        {
            return "Rejected";
        }

        return isApproved == true ? "Approved" : "Pending";
    }

    public static string ApprovalStatusAr(byte? status, bool? isApproved)
    {
        if (ProductStatusCodes.Normalize(status, isApproved) == ProductStatusCodes.Rejected)
        {
            return "مرفوض";
        }

        return isApproved == true ? "معتمد" : "قيد الانتظار";
    }

    public static string? ProductTypeNameAr(byte? productTypeId, string? productTypeNameEn)
    {
        if (productTypeId is ProductTypeCodes.Retail)
        {
            return "تجزئة";
        }

        if (productTypeId is ProductTypeCodes.Booking)
        {
            return "حجز";
        }

        if (productTypeId is ProductTypeCodes.Offers)
        {
            return "عروض";
        }

        if (productTypeId is ProductTypeCodes.Requests)
        {
            return "طلبات";
        }

        return TranslateProductTypeName(productTypeNameEn);
    }

    public static string? TranslateProductTypeName(string? nameEn)
    {
        if (string.IsNullOrWhiteSpace(nameEn))
        {
            return null;
        }

        return nameEn.Trim().ToLowerInvariant() switch
        {
            "retail" => "تجزئة",
            "wholesale" => "جملة",
            "booking" => "حجز",
            "offers" => "عروض",
            "requests" => "طلبات",
            "categories" or "category" => "فئات",
            _ => null
        };
    }

    public static string? UnitNameAr(string? unitNameEn)
    {
        if (string.IsNullOrWhiteSpace(unitNameEn))
        {
            return null;
        }

        var key = unitNameEn.Trim();
        if (UnitArByEn.TryGetValue(key, out var ar))
        {
            return ar;
        }

        // Case-insensitive fallback
        foreach (var pair in UnitArByEn)
        {
            if (string.Equals(pair.Key, key, StringComparison.OrdinalIgnoreCase))
            {
                return pair.Value;
            }
        }

        return null;
    }

    public static string? RequestTypeNameAr(byte? requestTypeId, string? requestTypeNameEn)
    {
        if (requestTypeId == 1 || string.Equals(requestTypeNameEn, "Local", StringComparison.OrdinalIgnoreCase))
        {
            return "محلي";
        }

        if (requestTypeId == 2 || string.Equals(requestTypeNameEn, "Reexport", StringComparison.OrdinalIgnoreCase))
        {
            return "إعادة تصدير";
        }

        return null;
    }

    private static readonly Dictionary<string, string> UnitArByEn = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Ton"] = "طن",
        ["Gram"] = "جرام",
        ["Kilogram"] = "كيلوجرام",
        ["Kg"] = "كجم",
        ["KG"] = "كجم",
        ["Carton"] = "كرتون",
        ["Bag"] = "كيس",
        ["Cup"] = "كوب",
        ["Box"] = "صندوق",
        ["Piece"] = "قطعة",
        ["Pcs"] = "قطعة",
        ["Liter"] = "لتر",
        ["Litre"] = "لتر",
        ["L"] = "لتر",
        ["Meter"] = "متر",
        ["Metre"] = "متر",
        ["Dozen"] = "دزينة",
        ["Pack"] = "عبوة",
        ["Set"] = "طقم",
        ["Barrel"] = "برميل",
        ["Container"] = "حاوية",
        ["Pallet"] = "منصة",
        ["Sack"] = "شوال",
        ["Bottle"] = "زجاجة",
        ["Can"] = "علبة",
        ["Unit"] = "وحدة",
    };
}
