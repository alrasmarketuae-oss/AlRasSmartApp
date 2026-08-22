using DataLayer.Models;

namespace BusinessLayer.Helpers;

/// <summary>
/// Seller-facing My Ads status — separates manual pause from auto-pause (sold out / display expiry).
/// </summary>
public static class MyListingStatusHelper
{
    public static bool IsListingSoldOut(OwnerListingRow product) =>
        !ProductTypeCodes.IsRequests(product.ProductTypeId) && product.Quantity <= 0;

    public static bool IsSellerPaused(OwnerListingRow product, DateTime utcNow)
    {
        if (ProductStatusCodes.Normalize(product.Status, product.IsApproved) != ProductStatusCodes.Paused)
        {
            return false;
        }

        if (IsListingSoldOut(product))
        {
            return false;
        }

        // Display expiry hides the ad publicly but must not count as seller "Paused".
        if (product.DisplayExpiresAtUtc != null && product.DisplayExpiresAtUtc <= utcNow)
        {
            return false;
        }

        return true;
    }
}
