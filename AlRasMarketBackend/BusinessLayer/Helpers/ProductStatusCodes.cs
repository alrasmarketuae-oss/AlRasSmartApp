namespace BusinessLayer.Helpers;

/// <summary>
/// حالات الإعلان/المنتج: Under Review (1) → Active (2) → Paused (3) | Rejected (5)
/// </summary>
public static class ProductStatusCodes
{
    public const byte UnderReview = 1;
    public const byte Active = 2;
    public const byte Paused = 3;
    public const byte Rejected = 5;

    private const byte LegacyUnderReview = 4;

    public static byte Normalize(byte? status, bool? isApproved = null)
    {
        if (!status.HasValue || status == 0)
        {
            return UnderReview;
        }

        return status.Value switch
        {
            Active => Active,
            Paused => Paused,
            Rejected => Rejected,
            LegacyUnderReview => UnderReview,
            UnderReview => isApproved == true ? Active : UnderReview,
            _ => UnderReview
        };
    }

    public static string ToDisplayName(byte? status, bool? isApproved = null) =>
        Normalize(status, isApproved) switch
        {
            UnderReview => "Under Review",
            Active => "Active",
            Paused => "Paused",
            Rejected => "Rejected",
            _ => "Unknown"
        };

    public static bool IsPubliclyVisible(byte? status, bool? isApproved) =>
        Normalize(status, isApproved) == Active;

    public static bool IsPendingReview(byte? status, bool? isApproved) =>
        Normalize(status, isApproved) == UnderReview;

    public static bool IsValidForSupplierUpdate(byte? status) =>
        status is Active or Paused;
}
