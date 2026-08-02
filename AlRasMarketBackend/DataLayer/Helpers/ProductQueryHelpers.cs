using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Helpers;

/// <summary>
/// Product status / type byte values used by catalog filters (kept in DataLayer so EF stays here).
/// Mirrors BusinessLayer ProductStatusCodes / ProductTypeCodes constants.
/// </summary>
public static class ProductCatalogCodes
{
    public const byte StatusUnderReview = 1;
    public const byte StatusActive = 2;
    public const byte StatusPaused = 3;
    public const byte StatusRejected = 5;

    public const byte TypeRetail = 1;
    public const byte TypeRequests = 4;
}

public static class ProductQueryHelpers
{
    public static IQueryable<Product> ApplyPublicProductFilter(IQueryable<Product> query)
    {
        var utcNow = DateTime.UtcNow;
        return query.Where(x =>
            (x.Status == ProductCatalogCodes.StatusActive
                || (x.Status == ProductCatalogCodes.StatusUnderReview && x.IsApproved == true))
            && (x.DisplayExpiresAtUtc == null || x.DisplayExpiresAtUtc > utcNow)
            && (x.ProductTypeId != ProductCatalogCodes.TypeRequests || x.Quantity > 0));
    }

    public static IQueryable<Product> ApplyHomeCatalogProductFilter(IQueryable<Product> query)
    {
        return query.Where(x =>
            x.CategoryId.HasValue
            && x.CategoryId.Value > 0
            && (x.ProductTypeId == null || x.ProductTypeId == ProductCatalogCodes.TypeRetail)
            && x.IsApproved == true
            && x.Status != ProductCatalogCodes.StatusRejected
            && (x.ProductTypeId != ProductCatalogCodes.TypeRequests || x.Quantity > 0)
            && (x.Status == ProductCatalogCodes.StatusActive
                || x.Status == ProductCatalogCodes.StatusPaused
                || (x.Status == ProductCatalogCodes.StatusUnderReview && x.IsApproved == true)));
    }

    public static IQueryable<ProductPublicRow> SelectPublicProductRows(IQueryable<Product> source) =>
        source.Select(x => new ProductPublicRow
        {
            ProductId = x.ProductId,
            ProductCode = x.ProductCode,
            RetailCode = x.RetailCode,
            NameEn = x.NameEn,
            USDPrice = x.USDPrice,
            OwnerId = x.OwnerId,
            Quantity = x.Quantity,
            DescriptionEn = x.DescriptionEn,
            MinimumOrderQuantity = x.MinimumOrderQuantity,
            MaximumOrderQuantity = x.MaximumOrderQuantity,
            Status = x.Status,
            IsApproved = x.IsApproved,
            DiscountPercentage = x.DiscountPercentage,
            DiscountDays = x.DiscountDays,
            ShippingDescriptionEn = x.ShippingDescriptionEn,
            ShippingDuration = x.ShippingDuration,
            OfferDuration = x.OfferDuration,
            SupplierNotesEn = x.SupplierNotesEn,
            Packaging = x.Packaging,
            PackagingDetails = x.PackagingDetails,
            RetailPackaging = x.RetailPackaging,
            RetailPackagingDetails = x.RetailPackagingDetails,
            RetailDescriptionEn = x.RetailDescriptionEn,
            Negotiable = x.Negotiable,
            IsFeatured = x.IsFeatured,
            ViewsCount = x.ViewsCount,
            VideoPath = x.VideoPath,
            VideoDurationSeconds = x.VideoDurationSeconds,
            CreatedAt = x.CreatedAt,
            CategoryName = x.Category != null ? x.Category.NameEn : null,
            CategoryNameAr = x.Category != null ? x.Category.NameAr : null,
            ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : null,
            UnitName = x.Unit != null ? x.Unit.UnitNameEn : null,
            OriginCountryName = x.OriginCountry != null ? x.OriginCountry.CountryNameEn : null,
            OriginCountryNameAr = x.OriginCountry != null ? x.OriginCountry.CountryNameAr : null,
            DestinationCountryName = x.DestinationCountry != null ? x.DestinationCountry.CountryNameEn : null,
            DestinationCountryNameAr = x.DestinationCountry != null ? x.DestinationCountry.CountryNameAr : null,
            LoadingPortName = x.LoadingPort != null ? x.LoadingPort.PortNameEn : null,
            LoadingPortNameAr = x.LoadingPort != null ? x.LoadingPort.PortNameAr : null,
            ArrivalPortName = x.ArrivalPort != null ? x.ArrivalPort.PortNameEn : null,
            ArrivalPortNameAr = x.ArrivalPort != null ? x.ArrivalPort.PortNameAr : null,
            CategoryId = x.CategoryId,
            Currency = x.Currency,
            ProductTypeId = x.ProductTypeId,
            AddressId = x.AddressId,
            RetailPrice = x.RetailPrice,
            RetailUnitId = x.RetailUnitId,
            RetailQuantity = x.RetailQuantity,
            RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null,
            RequestTypeId = x.RequestTypeId,
            RequestTypeName = x.RequestType != null ? x.RequestType.NameEn : null,
            BookingPriceTypeId = x.BookingPriceTypeId,
            BookingPriceTypeName = x.BookingPriceType != null ? x.BookingPriceType.NameEn : null
        });
}
