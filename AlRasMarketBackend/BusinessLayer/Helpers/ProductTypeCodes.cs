using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class ProductTypeCodes
{
    public const byte Retail = 1;
    public const byte Booking = 2;
    public const byte Offers = 3;
    public const byte Requests = 4;

    public static bool IsRetail(byte? productTypeId) => productTypeId == Retail;
    public static bool IsBooking(byte? productTypeId) => productTypeId == Booking;
    public static bool IsOffers(byte? productTypeId) => productTypeId == Offers;
    public static bool IsRequests(byte? productTypeId) => productTypeId == Requests;

    /// <summary>
    /// Catalog products under Categories. May also have ProductTypeId = Retail when dual-listed.
    /// </summary>
    public static bool IsCategoryProduct(byte? categoryId, byte? productTypeId) =>
        categoryId.HasValue
        && (!productTypeId.HasValue || productTypeId == Retail);

    /// <summary>
    /// Hybrid listing: both CategoryId and ProductTypeId are set (typically Retail dual-list).
    /// Search should surface these as two cards — retail channel + category channel.
    /// </summary>
    public static bool IsHybridDualListing(byte? categoryId, byte? productTypeId) =>
        categoryId is > 0 && productTypeId.HasValue;

    /// <summary>
    /// Company-customer app surfaces: Categories, Offers, Booking (not Retail or Requests).
    /// </summary>
    public static bool IsHiddenFromCompanyCustomerCatalog(
        byte? categoryId,
        byte? productTypeId,
        string? listingChannel = null)
    {
        if (IsRequests(productTypeId)) return true;
        if (string.Equals(listingChannel, "retail", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        // Pure retail ads (no category) are the Retail service tab only.
        if (IsRetail(productTypeId) && categoryId is not > 0)
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// Product type id for wholesale/category commission. Hybrids store ProductTypeId = Retail,
    /// but wholesale markup must use category rates (pass null so category commission wins).
    /// </summary>
    public static byte? WholesaleCommissionProductTypeId(byte? categoryId, byte? productTypeId) =>
        IsCategoryProduct(categoryId, productTypeId) ? null : productTypeId;

    public static bool IsCategoryProduct(Product? product) =>
        product is not null && IsCategoryProduct(product.CategoryId, product.ProductTypeId);

    /// <summary>
    /// Category product that also publishes optional retail price / unit / quantity.
    /// </summary>
    public static bool HasRetailPricing(Product? product) =>
        product is not null
        && HasRetailStockConfigured(product)
        && product.RetailQuantity is > 0;

    public static bool HasRetailPricing(
        byte? categoryId,
        byte? productTypeId,
        decimal? retailPrice,
        byte? retailUnitId,
        long? retailQuantity) =>
        HasRetailStockConfigured(categoryId, productTypeId, retailPrice, retailUnitId)
        && retailQuantity is > 0;

    /// <summary>
    /// Hybrid category listing has retail price + unit configured (qty may be zero after sell-out).
    /// </summary>
    public static bool HasRetailStockConfigured(Product? product) =>
        product is not null
        && HasRetailStockConfigured(
            product.CategoryId,
            product.ProductTypeId,
            product.RetailPrice,
            product.RetailUnitId);

    public static bool HasRetailStockConfigured(
        byte? categoryId,
        byte? productTypeId,
        decimal? retailPrice,
        byte? retailUnitId) =>
        categoryId.HasValue
        && (!productTypeId.HasValue || productTypeId == Retail)
        && retailPrice is > 0
        && retailUnitId.HasValue;

    /// <summary>
    /// Cart / hybrid retail orders must deduct and restore <see cref="Product.RetailQuantity"/>.
    /// Pure retail (ProductTypeId = Retail, no category retail fields) still uses Product.Quantity.
    /// Wholesale / category Purchase Orders keep <see cref="Order.IsRetailPurchase"/> = false.
    /// </summary>
    public static bool UsesRetailStockChannel(Order? order, Product? product) =>
        order is not null
        && product is not null
        && order.IsRetailPurchase
        && HasRetailStockConfigured(product);

    /// <summary>
    /// Pure retail listing OR category product with retail pricing enabled.
    /// </summary>
    public static bool IsRetailSellable(Product? product) =>
        product is not null
        && (IsRetail(product.ProductTypeId) || HasRetailPricing(product));

    /// <summary>
    /// Order placed on the retail channel (cart/pure retail), not wholesale on a hybrid listing.
    /// Hybrids keep ProductTypeId = Retail; only <see cref="Order.IsRetailPurchase"/> marks the retail channel.
    /// Pure retail (ProductTypeId = Retail, no category) is always treated as retail.
    /// </summary>
    public static bool IsRetailOrder(Order? order) =>
        order is not null
        && (order.IsRetailPurchase
            || (IsRetail(order.Product?.ProductTypeId)
                && !IsCategoryProduct(order.Product)));

    /// <summary>Types that sell/reserve from Product.Quantity stock.</summary>
    public static bool TracksSellableStock(byte? productTypeId, byte? categoryId = null) =>
        IsRetail(productTypeId)
        || IsBooking(productTypeId)
        || IsOffers(productTypeId)
        || IsCategoryProduct(categoryId, productTypeId);

    public static bool TracksSellableStock(Product? product) =>
        product is not null && TracksSellableStock(product.ProductTypeId, product.CategoryId);

    /// <summary>
    /// Offers, Requests, Booking &amp; Category: if the order has specification/media,
    /// admin must approve before the seller.
    /// </summary>
    public static bool UsesSpecOrMediaAdminGate(byte? productTypeId, byte? categoryId = null) =>
        IsOffers(productTypeId)
        || IsRequests(productTypeId)
        || IsBooking(productTypeId)
        || IsCategoryProduct(categoryId, productTypeId);

    public static bool UsesSpecOrMediaAdminGate(Product? product) =>
        product is not null && UsesSpecOrMediaAdminGate(product.ProductTypeId, product.CategoryId);

    /// <summary>
    /// Always seller-first when there is no spec/media gate: Booking and Category wholesale PO.
    /// Retail and spec/media types (Offers, Requests, Booking notes) go to admin dashboard first.
    /// </summary>
    public static bool StartsWithSellerApproval(byte? productTypeId, byte? categoryId = null) =>
        IsBooking(productTypeId)
        || IsCategoryProduct(categoryId, productTypeId);

    public static bool StartsWithSellerApproval(Product? product) =>
        product is not null && StartsWithSellerApproval(product.ProductTypeId, product.CategoryId);

    /// <summary>
    /// After seller accept, admin continues with free-text bilingual status only
    /// (no Paid / Shipping / Delivered workflow). Applies to all catalog order types.
    /// </summary>
    public static bool UsesAdminCustomStatus(byte? productTypeId, byte? categoryId = null) =>
        IsRetail(productTypeId)
        || IsBooking(productTypeId)
        || IsOffers(productTypeId)
        || IsRequests(productTypeId)
        || IsCategoryProduct(categoryId, productTypeId);

    public static bool UsesAdminCustomStatus(Product? product) =>
        product is not null && UsesAdminCustomStatus(product.ProductTypeId, product.CategoryId);

    /// <summary>
    /// Product types that may require admin moderation before seller accept
    /// (when the order still has IsAdminApproved = false).
    /// </summary>
    public static bool RequiresAdminModerationBeforeSellerApproval(
        byte? productTypeId,
        byte? categoryId = null) =>
        IsRetail(productTypeId)
        || productTypeId is Requests or Offers or Booking
        || IsCategoryProduct(categoryId, productTypeId);

    public static bool RequiresAdminModerationBeforeSellerApproval(Product? product) =>
        product is not null
        && RequiresAdminModerationBeforeSellerApproval(product.ProductTypeId, product.CategoryId);

    /// <summary>Visible to the seller before admin review.</summary>
    public static bool IsSellerVisibleWithoutAdminApproval(byte? productTypeId, byte? categoryId = null) =>
        StartsWithSellerApproval(productTypeId, categoryId);
}
