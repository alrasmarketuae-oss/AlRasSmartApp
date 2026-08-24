using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using DataLayer.Seeding;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    private async Task<object> BuildPublicProductListPageAsync(
        IReadOnlyList<ProductPublicRow> products,
        int totalCount,
        int page,
        int pageSize,
        CancellationToken cancellationToken,
        bool projectRetailAsPrimary = false,
        bool includeRetailFields = true,
        bool expandHybridSearchChannels = false,
        bool hideRetailAndRequests = false)
    {
        var items = await BuildPublicProductListItemsAsync(
            products,
            cancellationToken,
            projectRetailAsPrimary: projectRetailAsPrimary,
            includeRetailFields: includeRetailFields,
            expandHybridSearchChannels: expandHybridSearchChannels,
            hideRetailAndRequests: hideRetailAndRequests);

        return new
        {
            count = items.Count,
            totalCount,
            page,
            pageSize,
            totalPages = totalCount == 0 ? 0 : (int)Math.Ceiling(totalCount / (double)pageSize),
            items
        };
    }

    private async Task<List<object>> BuildPublicProductListItemsAsync(
        IReadOnlyList<ProductPublicRow> products,
        CancellationToken cancellationToken,
        bool projectRetailAsPrimary = false,
        bool includeRetailFields = true,
        bool expandHybridSearchChannels = false,
        bool hideRetailAndRequests = false)
    {
        if (products.Count == 0)
        {
            return [];
        }

        products = FilterCatalogRowsForAudience(products, hideRetailAndRequests);
        if (products.Count == 0)
        {
            return [];
        }

        var productIds = products.Select(p => p.ProductId).ToList();
        var addressLookup = await LoadAddressTextLookupAsync(products.Select(p => p.AddressId), cancellationToken);

        var imagesLookup = await productData.GetProductImagePathsByProductIdsAsync(productIds, cancellationToken);
        var imagesDict = imagesLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.Select(x => x.Path).ToList());

        var documentsLookup = await productData.GetProductDocumentPathsByProductIdsAsync(productIds, cancellationToken);
        var documentsDict = documentsLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.Select(x => x.Path).ToList());

        var extraVideosLookup = await productData.GetProductVideoPathsByProductIdsAsync(productIds, cancellationToken);
        var extraVideosDict = extraVideosLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.ToList());

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        var (commissionSettings, categoryCommissions, usdToAedRate) = await GetPricingContextAsync(cancellationToken);

        var categoryIds = products
            .Where(p => p.CategoryId.HasValue)
            .Select(p => p.CategoryId!.Value)
            .Distinct()
            .ToList();

        var categoryLookup = await productData.GetCategoriesByIdsAsync(categoryIds, cancellationToken);

        // Search/image: hybrid (CategoryId + ProductTypeId) → retail card + category card.
        var projections = new List<(ProductPublicRow Row, bool ProjectRetail, bool IncludeRetail, string? Channel)>();
        foreach (var product in products)
        {
            if (expandHybridSearchChannels
                && ProductTypeCodes.IsHybridDualListing(product.CategoryId, product.ProductTypeId))
            {
                if (!hideRetailAndRequests)
                {
                    projections.Add((product, ProjectRetail: true, IncludeRetail: true, Channel: "retail"));
                }

                projections.Add((product, ProjectRetail: false, IncludeRetail: false, Channel: "category"));
            }
            else
            {
                var channel = projectRetailAsPrimary
                    && ProductTypeCodes.IsHybridDualListing(product.CategoryId, product.ProductTypeId)
                        ? "retail"
                        : null;
                projections.Add((product, projectRetailAsPrimary, includeRetailFields, channel));
            }
        }

        return projections.Select(entry =>
        {
            var x = entry.Row;
            var projectRetail = entry.ProjectRetail;
            var includeRetail = entry.IncludeRetail;
            var listingChannel = entry.Channel;

            var (unitPrice, discountPercentage, discountDays) = ResolveOfferPricing(x);
            var hasRetailPricing = ProductTypeCodes.HasRetailPricing(
                x.CategoryId,
                x.ProductTypeId,
                x.RetailPrice,
                x.RetailUnitId,
                x.RetailQuantity);

            // Wholesale uses category commission even when the hybrid is dual-listed as Retail.
            var wholesalePriced = BuildCustomerFacingPrice(
                unitPrice,
                ProductTypeCodes.WholesaleCommissionProductTypeId(x.CategoryId, x.ProductTypeId),
                x.CategoryId,
                x.Currency,
                commissionSettings,
                categoryCommissions,
                usdToAedRate);

            CustomerFacingPrice? retailPriced = null;
            if (hasRetailPricing && x.RetailPrice is > 0)
            {
                retailPriced = BuildCustomerFacingPrice(
                    x.RetailPrice.Value,
                    ProductTypeCodes.Retail,
                    categoryId: null,
                    "AED",
                    commissionSettings,
                    categoryCommissions,
                    usdToAedRate);
            }

            var useRetailPrimary = projectRetail && hasRetailPricing && retailPriced is not null;
            var priced = useRetailPrimary ? retailPriced!.Value : wholesalePriced;
            var displayQuantity = useRetailPrimary ? (x.RetailQuantity ?? 0) : x.Quantity;

            // Owner-facing (no commission): same currency presentation as My Ads.
            var wholesaleOwnerPriced = BuildSupplierFacingPrice(
                unitPrice,
                x.ProductTypeId,
                x.Currency,
                usdToAedRate);
            CustomerFacingPrice? retailOwnerPriced = null;
            if (hasRetailPricing && x.RetailPrice is > 0)
            {
                retailOwnerPriced = BuildSupplierFacingPrice(
                    x.RetailPrice.Value,
                    ProductTypeCodes.Retail,
                    "AED",
                    usdToAedRate);
            }

            var ownerPriced = useRetailPrimary && retailOwnerPriced is not null
                ? retailOwnerPriced.Value
                : wholesaleOwnerPriced;

            categoryLookup.TryGetValue(x.CategoryId ?? 0, out var category);
            var categoryNameEn = FirstNonEmpty(x.CategoryName, category?.NameEn);
            var categoryNameAr = FirstNonEmpty(x.CategoryNameAr, category?.NameAr);

            // Home / category browse: hybrids keep wholesale as primary and hide
            // retail payload + service ProductTypeId so the client treats them as catalog.
            var isHomeCatalogShape = !includeRetail
                && ProductTypeCodes.IsCategoryProduct(x.CategoryId, x.ProductTypeId);
            var responseProductTypeId = useRetailPrimary
                ? ProductTypeCodes.Retail
                : (isHomeCatalogShape ? null : x.ProductTypeId);
            var responseProductTypeNameEn = useRetailPrimary
                ? (x.ProductTypeName ?? "Retail")
                : (isHomeCatalogShape ? null : x.ProductTypeName);
            var responseProductTypeNameAr = responseProductTypeNameEn is null
                ? null
                : CatalogLocalizationHelper.ProductTypeNameAr(responseProductTypeId, responseProductTypeNameEn);

            var wholesaleUnitNameEn = x.UnitName;
            var wholesaleUnitNameAr = CatalogLocalizationHelper.UnitNameAr(x.UnitName);
            var retailUnitNameEn = includeRetail ? x.RetailUnitName : null;
            var retailUnitNameAr = includeRetail
                ? CatalogLocalizationHelper.UnitNameAr(x.RetailUnitName)
                : null;
            var displayUnitNameEn = useRetailPrimary ? retailUnitNameEn : wholesaleUnitNameEn;
            var displayUnitNameAr = useRetailPrimary ? retailUnitNameAr : wholesaleUnitNameAr;

            var statusNameEn = CatalogLocalizationHelper.StatusNameEn(x.Status, x.IsApproved);
            var statusNameAr = CatalogLocalizationHelper.StatusNameAr(x.Status, x.IsApproved);
            var approvalStatusEn = CatalogLocalizationHelper.ApprovalStatusEn(x.Status, x.IsApproved);
            var approvalStatusAr = CatalogLocalizationHelper.ApprovalStatusAr(x.Status, x.IsApproved);

            var requestTypeNameEn = ResolveRequestTypeName(x.RequestTypeId, x.RequestTypeName);
            var requestTypeNameAr = CatalogLocalizationHelper.RequestTypeNameAr(x.RequestTypeId, requestTypeNameEn);

            var videos = ProductVideoPathsHelper.ResolveVideoItems(
                x.VideoPath,
                x.VideoDurationSeconds,
                extraVideosDict.GetValueOrDefault(x.ProductId));
            var videoPaths = videos.Select(v => v.Path).ToList();

            translations.TryGetValue(x.ProductId, out var tr);
            var nameEn = FirstNonEmpty(tr?.NameEn, x.NameEn);
            var nameAr = FirstNonEmpty(tr?.NameAr, DetectLanguageHintIsArabic(x.NameEn) ? x.NameEn : null);
            var descriptionEn = FirstNonEmpty(tr?.DescriptionEn, x.DescriptionEn);
            var descriptionAr = FirstNonEmpty(
                tr?.DescriptionAr,
                DetectLanguageHintIsArabic(x.DescriptionEn) ? x.DescriptionEn : null);
            var retailDescriptionEn = includeRetail
                ? FirstNonEmpty(tr?.RetailDescriptionEn, x.RetailDescriptionEn)
                : null;
            var retailDescriptionAr = includeRetail
                ? FirstNonEmpty(
                    tr?.RetailDescriptionAr,
                    DetectLanguageHintIsArabic(x.RetailDescriptionEn) ? x.RetailDescriptionEn : null)
                : null;
            var supplierNotesEn = FirstNonEmpty(tr?.SupplierNotesEn, x.SupplierNotesEn);
            var supplierNotesAr = FirstNonEmpty(
                tr?.SupplierNotesAr,
                DetectLanguageHintIsArabic(x.SupplierNotesEn) ? x.SupplierNotesEn : null);
            var shippingDescriptionEn = FirstNonEmpty(tr?.ShippingDescriptionEn, x.ShippingDescriptionEn);
            var shippingDescriptionAr = FirstNonEmpty(
                tr?.ShippingDescriptionAr,
                DetectLanguageHintIsArabic(x.ShippingDescriptionEn) ? x.ShippingDescriptionEn : null);

            var primaryDescription = useRetailPrimary
                ? (string.IsNullOrWhiteSpace(x.RetailDescriptionEn) ? x.DescriptionEn : x.RetailDescriptionEn)
                : x.DescriptionEn;
            var primaryDescriptionEn = useRetailPrimary
                ? (FirstNonEmpty(retailDescriptionEn, descriptionEn) ?? primaryDescription)
                : descriptionEn;
            var primaryDescriptionAr = useRetailPrimary
                ? (FirstNonEmpty(retailDescriptionAr, descriptionAr))
                : descriptionAr;

            // Do not also emit x.NameEn / x.ShippingDescriptionEn / x.SupplierNotesEn:
            // with camelCase JSON those collide with nameEn / shippingDescriptionEn / supplierNotesEn
            // and System.Text.Json throws → 500 on every non-empty product list.
            return (object)new
            {
                x.ProductId,
                productCode = useRetailPrimary
                    ? (FirstNonEmpty(x.RetailCode, x.ProductCode))
                    : x.ProductCode,
                retailCode = x.RetailCode,
                nameEn,
                nameAr,
                price = priced.Price,
                currency = priced.Currency,
                priceAed = priced.PriceAed,
                usdPrice = priced.PriceUsd,
                ownerPrice = ownerPriced.Price,
                ownerCurrency = ownerPriced.Currency,
                ownerPriceAed = ownerPriced.PriceAed,
                ownerUsdPrice = ownerPriced.PriceUsd,
                ownerWholesalePrice = wholesaleOwnerPriced.Price,
                wholesalePrice = wholesalePriced.Price,
                wholesaleCurrency = wholesalePriced.Currency,
                wholesalePriceAed = wholesalePriced.PriceAed,
                usdPriceWholesale = wholesalePriced.PriceUsd,
                wholesaleQuantity = x.Quantity,
                wholesaleUnitName = wholesaleUnitNameEn,
                wholesaleUnitNameEn,
                wholesaleUnitNameAr,
                x.OwnerId,
                Quantity = displayQuantity,
                description = primaryDescription,
                descriptionEn = primaryDescriptionEn,
                descriptionAr = primaryDescriptionAr,
                wholesaleDescription = x.DescriptionEn,
                wholesaleDescriptionEn = descriptionEn,
                wholesaleDescriptionAr = descriptionAr,
                retailDescription = includeRetail ? x.RetailDescriptionEn : null,
                retailDescriptionEn,
                retailDescriptionAr,
                x.MinimumOrderQuantity,
                x.MaximumOrderQuantity,
                statusName = statusNameEn,
                statusNameEn,
                statusNameAr,
                approvalStatus = approvalStatusEn,
                approvalStatusEn,
                approvalStatusAr,
                DiscountPercentage = discountPercentage,
                DiscountDays = discountDays,
                shippingDescriptionEn,
                shippingDescriptionAr,
                shippingDuration = x.ShippingDuration ?? string.Empty,
                offerDuration = x.OfferDuration ?? string.Empty,
                supplierNotesEn,
                supplierNotesAr,
                packaging = useRetailPrimary
                    ? (x.RetailPackaging ?? x.Packaging)
                    : x.Packaging,
                packagingDetails = useRetailPrimary
                    ? (x.RetailPackagingDetails ?? x.PackagingDetails)
                    : x.PackagingDetails,
                wholesalePackaging = x.Packaging,
                wholesalePackagingDetails = x.PackagingDetails,
                retailPackaging = includeRetail ? x.RetailPackaging : null,
                retailPackagingDetails = includeRetail ? x.RetailPackagingDetails : null,
                x.Negotiable,
                x.IsFeatured,
                x.ViewsCount,
                videos = videos.Select(v => new
                {
                    v.Id,
                    path = v.Path,
                    videoPath = v.Path,
                    durationSeconds = v.DurationSeconds,
                    isMuted = v.IsMuted
                }),
                videoPath = videoPaths.FirstOrDefault(),
                videoPaths,
                videoDurationSeconds = videos.FirstOrDefault()?.DurationSeconds,
                CreatedAt = UtcDateTimeHelper.FormatApiDateTime(x.CreatedAt),
                categoryId = x.CategoryId,
                categoryName = categoryNameEn,
                categoryNameEn,
                categoryNameAr,
                categoryImagePath = category?.ImgPath,
                productTypeId = responseProductTypeId,
                productTypeName = responseProductTypeNameEn,
                productTypeNameEn = responseProductTypeNameEn,
                productTypeNameAr = responseProductTypeNameAr,
                unitName = displayUnitNameEn,
                unitNameEn = displayUnitNameEn,
                unitNameAr = displayUnitNameAr,
                originCountryName = x.OriginCountryName,
                originCountryNameEn = x.OriginCountryName,
                originCountryNameAr = x.OriginCountryNameAr,
                destinationCountryName = x.DestinationCountryName,
                destinationCountryNameEn = x.DestinationCountryName,
                destinationCountryNameAr = x.DestinationCountryNameAr,
                loadingPortName = x.LoadingPortName,
                loadingPortNameEn = x.LoadingPortName,
                loadingPortNameAr = x.LoadingPortNameAr,
                arrivalPortName = x.ArrivalPortName,
                arrivalPortNameEn = x.ArrivalPortName,
                arrivalPortNameAr = x.ArrivalPortNameAr,
                addressId = x.AddressId,
                address = ResolveAddressText(x.AddressId, addressLookup),
                hasRetailPricing = includeRetail && hasRetailPricing,
                retailPrice = includeRetail ? retailPriced?.Price : null,
                retailPriceAed = includeRetail ? retailPriced?.PriceAed : null,
                ownerRetailPrice = includeRetail ? retailOwnerPriced?.Price : null,
                ownerRetailPriceAed = includeRetail ? retailOwnerPriced?.PriceAed : null,
                retailUnitId = includeRetail ? x.RetailUnitId : null,
                retailUnitName = retailUnitNameEn,
                retailUnitNameEn,
                retailUnitNameAr,
                retailQuantity = includeRetail ? x.RetailQuantity : null,
                requestTypeId = x.RequestTypeId,
                requestTypeName = requestTypeNameEn,
                requestTypeNameEn,
                requestTypeNameAr,
                bookingPriceTypeId = x.BookingPriceTypeId,
                bookingPriceTypeName = ResolveBookingPriceTypeName(x.BookingPriceTypeId, x.BookingPriceTypeName),
                searchListingChannel = listingChannel,
                images = imagesDict.TryGetValue(x.ProductId, out var images)
                    ? images
                    : new List<string>(),
                documents = documentsDict.TryGetValue(x.ProductId, out var documents)
                    ? documents
                    : new List<string>()
            };
        }).ToList();
    }

    /// <summary>Always return Local / Reexport when RequestTypeId is set.</summary>
    private static string? ResolveRequestTypeName(byte? requestTypeId, string? requestTypeName)
    {
        if (!string.IsNullOrWhiteSpace(requestTypeName))
        {
            return requestTypeName.Trim();
        }

        return requestTypeId switch
        {
            1 => "Local",
            2 => "Reexport",
            _ => null
        };
    }

    private static string? ResolveBookingPriceTypeName(byte? bookingPriceTypeId, string? bookingPriceTypeName)
    {
        if (!string.IsNullOrWhiteSpace(bookingPriceTypeName))
        {
            return bookingPriceTypeName.Trim();
        }

        return bookingPriceTypeId switch
        {
            1 => "FOB",
            2 => "CNF",
            3 => "CIF",
            _ => null
        };
    }

    private static (int page, int pageSize) NormalizePaging(int page, int pageSize)
    {
        if (page < 1)
        {
            throw new ArgumentException("Page must be greater than or equal to 1.");
        }

        if (pageSize < 1 || pageSize > 100)
        {
            throw new ArgumentException("PageSize must be between 1 and 100.");
        }

        return (page, pageSize);
    }

}
