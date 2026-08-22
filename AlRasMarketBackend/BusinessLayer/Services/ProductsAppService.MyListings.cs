using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    private static readonly TimeSpan MyListingsTtl = TimeSpan.FromMinutes(2);

    private static readonly JsonSerializerOptions MyListingsJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public async Task<MyListingsResponse> GetMyListingsAsync(string ownerId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(ownerId, out var parsedOwnerId))
        {
            throw new ArgumentException("Invalid owner id.");
        }

        var version = MyListingsCacheVersions.Get(parsedOwnerId);
        var cacheKey = $"products:my-listings:v{version}:{parsedOwnerId:N}";
        var cached = await tieredCache.GetAsync(cacheKey, cancellationToken);
        var fromCache = TryReadMyListings(cached);
        if (fromCache is not null)
        {
            return fromCache;
        }

        var ownerName = await productData.GetUserDisplayNameAsync(parsedOwnerId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var rawProducts = await productData.GetOwnerListingsAsync(parsedOwnerId, cancellationToken);

        var addressLookup = await LoadAddressTextLookupAsync(rawProducts.Select(x => x.AddressId), cancellationToken);
        var usdToAedRate = GetUsdToAedRate();

        var productIds = rawProducts.Select(x => x.ProductId).ToList();
        var pendingOffersByProduct = await productData.GetPendingOfferCountsByProductIdsAsync(
            productIds,
            ProductTypeCodes.Retail,
            OrderStatusCodes.AwaitingSellerApproval,
            cancellationToken);

        var extraVideosLookup = await productData.GetProductVideoPathsByProductIdsAsync(productIds, cancellationToken);

        var extraVideosDict = extraVideosLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.ToList());

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        var utcNow = UtcDateTimeHelper.UtcNow;
        var products = rawProducts.Select(x =>
        {
            var priced = BuildSupplierFacingPrice(x.USDPrice, x.ProductTypeId, x.Currency, usdToAedRate);
            var addressText = ResolveAddressText(x.AddressId, addressLookup);
            var videos = ProductVideoPathsHelper.ResolveVideoItems(
                x.VideoPath,
                x.VideoDurationSeconds,
                extraVideosDict.GetValueOrDefault(x.ProductId));
            var videoPaths = videos.Select(v => v.Path).ToList();
            translations.TryGetValue(x.ProductId, out var tr);
            var createdLanguage = ResolveCreatedLanguage(x.CreatedLanguage, x.NameEn, tr?.NameAr);
            var nameEn = FirstNonEmpty(tr?.NameEn, x.NameEn) ?? string.Empty;
            var nameAr = FirstNonEmpty(tr?.NameAr, DetectLanguageHintIsArabic(x.NameEn) ? x.NameEn : null);
            var descriptionEn = FirstNonEmpty(tr?.DescriptionEn, x.DescriptionEn) ?? string.Empty;
            var descriptionAr = FirstNonEmpty(
                tr?.DescriptionAr,
                DetectLanguageHintIsArabic(x.DescriptionEn) ? x.DescriptionEn : null);
            var retailDescriptionEn = FirstNonEmpty(tr?.RetailDescriptionEn, x.RetailDescriptionEn);
            var retailDescriptionAr = FirstNonEmpty(
                tr?.RetailDescriptionAr,
                DetectLanguageHintIsArabic(x.RetailDescriptionEn) ? x.RetailDescriptionEn : null);
            var supplierNotesEn = FirstNonEmpty(tr?.SupplierNotesEn, x.SupplierNotesEn);
            var supplierNotesAr = FirstNonEmpty(
                tr?.SupplierNotesAr,
                DetectLanguageHintIsArabic(x.SupplierNotesEn) ? x.SupplierNotesEn : null);
            var shippingNotesEn = FirstNonEmpty(tr?.ShippingDescriptionEn, x.ShippingDescriptionEn);
            var shippingNotesAr = FirstNonEmpty(
                tr?.ShippingDescriptionAr,
                DetectLanguageHintIsArabic(x.ShippingDescriptionEn) ? x.ShippingDescriptionEn : null);
            var displayName = NotificationMessages.IsArabic(createdLanguage)
                ? (FirstNonEmpty(nameAr, nameEn) ?? string.Empty)
                : (FirstNonEmpty(nameEn, nameAr) ?? string.Empty);
            var displayDescription = NotificationMessages.IsArabic(createdLanguage)
                ? (FirstNonEmpty(descriptionAr, descriptionEn) ?? string.Empty)
                : (FirstNonEmpty(descriptionEn, descriptionAr) ?? string.Empty);
            var displayRetailDescription = NotificationMessages.IsArabic(createdLanguage)
                ? FirstNonEmpty(retailDescriptionAr, retailDescriptionEn)
                : FirstNonEmpty(retailDescriptionEn, retailDescriptionAr);
            var displaySupplierNotes = NotificationMessages.IsArabic(createdLanguage)
                ? FirstNonEmpty(supplierNotesAr, supplierNotesEn)
                : FirstNonEmpty(supplierNotesEn, supplierNotesAr);
            var preferAr = NotificationMessages.IsArabic(createdLanguage);
            var unitNameEn = x.UnitName ?? string.Empty;
            var unitNameAr = CatalogLocalizationHelper.UnitNameAr(x.UnitName);
            var retailUnitNameEn = x.RetailUnitName ?? string.Empty;
            var retailUnitNameAr = CatalogLocalizationHelper.UnitNameAr(x.RetailUnitName);
            var statusEn = CatalogLocalizationHelper.StatusNameEn(x.Status, x.IsApproved);
            var statusAr = CatalogLocalizationHelper.StatusNameAr(x.Status, x.IsApproved);
            var approvalEn = CatalogLocalizationHelper.ApprovalStatusEn(x.Status, x.IsApproved);
            var approvalAr = CatalogLocalizationHelper.ApprovalStatusAr(x.Status, x.IsApproved);
            var productTypeNameEn = x.ProductTypeName ?? string.Empty;
            var productTypeNameAr = CatalogLocalizationHelper.ProductTypeNameAr(x.ProductTypeId, x.ProductTypeName);
            var categoryNameEn = x.CategoryName ?? string.Empty;
            var categoryNameAr = x.CategoryNameAr ?? string.Empty;
            var displayCategory = preferAr
                ? (FirstNonEmpty(categoryNameAr, categoryNameEn) ?? string.Empty)
                : (FirstNonEmpty(categoryNameEn, categoryNameAr) ?? string.Empty);
            var displayUnit = preferAr
                ? (FirstNonEmpty(unitNameAr, unitNameEn) ?? string.Empty)
                : (FirstNonEmpty(unitNameEn, unitNameAr) ?? string.Empty);
            var displayRetailUnit = preferAr
                ? (FirstNonEmpty(retailUnitNameAr, retailUnitNameEn) ?? string.Empty)
                : (FirstNonEmpty(retailUnitNameEn, retailUnitNameAr) ?? string.Empty);
            var displayStatus = preferAr
                ? (FirstNonEmpty(statusAr, statusEn) ?? string.Empty)
                : (FirstNonEmpty(statusEn, statusAr) ?? string.Empty);
            var displayApproval = preferAr
                ? (FirstNonEmpty(approvalAr, approvalEn) ?? string.Empty)
                : (FirstNonEmpty(approvalEn, approvalAr) ?? string.Empty);
            var displayProductType = preferAr
                ? (FirstNonEmpty(productTypeNameAr, productTypeNameEn) ?? string.Empty)
                : (FirstNonEmpty(productTypeNameEn, productTypeNameAr) ?? string.Empty);
            var displayShippingNotes = preferAr
                ? FirstNonEmpty(shippingNotesAr, shippingNotesEn)
                : FirstNonEmpty(shippingNotesEn, shippingNotesAr);
            var requestTypeNameEn = !string.IsNullOrWhiteSpace(x.RequestTypeName)
                ? x.RequestTypeName
                : x.RequestTypeId switch
                {
                    1 => "Local",
                    2 => "Reexport",
                    _ => null
                };
            var shipping = BuildMyProductShipping(
                x.OriginCountryName,
                x.OriginCountryNameAr,
                x.LoadingPortName,
                x.LoadingPortNameAr,
                x.DestinationCountryName,
                x.DestinationCountryNameAr,
                x.ArrivalPortName,
                x.ArrivalPortNameAr,
                displayShippingNotes,
                x.ShippingDuration,
                preferAr);
            shipping.AdditionalShippingNotesEn = shippingNotesEn ?? string.Empty;
            shipping.AdditionalShippingNotesAr = shippingNotesAr ?? string.Empty;

            return new MyProductListingDto
        {
            ProductId = x.ProductId.ToString(),
            ProductCode = x.ProductCode ?? string.Empty,
            RetailCode = x.RetailCode,
            ProductName = displayName,
            NameEn = nameEn,
            NameAr = nameAr,
            CreatedLanguage = createdLanguage,
            CategoryName = displayCategory,
            CategoryNameEn = categoryNameEn,
            CategoryNameAr = categoryNameAr,
            CategoryId = x.CategoryId?.ToString() ?? string.Empty,
            CategoryImagePath = x.CategoryImagePath ?? string.Empty,
            ProductTypeId = x.ProductTypeId,
            ProductTypeName = displayProductType,
            ProductTypeNameEn = productTypeNameEn,
            ProductTypeNameAr = productTypeNameAr,
            Description = displayDescription,
            DescriptionEn = descriptionEn,
            DescriptionAr = descriptionAr,
            Price = priced.Price.ToString("0.##"),
            Currency = priced.Currency,
            PriceAed = priced.PriceAed?.ToString("0.##"),
            PriceUsd = x.USDPrice.ToString("0.##"),
            Quantity = x.Quantity.ToString(),
            UnitName = displayUnit,
            UnitNameEn = unitNameEn,
            UnitNameAr = unitNameAr,
            MinimumOrderQuantity = x.MinimumOrderQuantity?.ToString() ?? string.Empty,
            MaximumOrderQuantity = x.MaximumOrderQuantity?.ToString() ?? string.Empty,
            Status = displayStatus,
            StatusNameEn = statusEn,
            StatusNameAr = statusAr,
            ListingStatusCode = ProductStatusCodes.Normalize(x.Status, x.IsApproved),
            IsSellerPaused = MyListingStatusHelper.IsSellerPaused(x, utcNow),
            IsListingSoldOut = MyListingStatusHelper.IsListingSoldOut(x),
            IsApproved = x.IsApproved == true,
            ApprovalStatus = displayApproval,
            ApprovalStatusEn = approvalEn,
            ApprovalStatusAr = approvalAr,
            DiscountPercentage = x.DiscountPercentage?.ToString() ?? string.Empty,
            DiscountDays = x.DiscountDays?.ToString() ?? string.Empty,
            OfferDuration = x.OfferDuration ?? string.Empty,
            ShippingDuration = x.ShippingDuration ?? string.Empty,
            Shipping = shipping,
            SupplierNotes = displaySupplierNotes ?? string.Empty,
            SupplierNotesEn = supplierNotesEn,
            SupplierNotesAr = supplierNotesAr,
            Packaging = x.Packaging,
            PackagingDetails = x.PackagingDetails ?? string.Empty,
            Negotiable = ToYesNoText(x.Negotiable),
            IsFeatured = ToYesNoText(x.IsFeatured),
            ViewsCount = x.ViewsCount.ToString(),
            VideoPath = videoPaths.FirstOrDefault() ?? string.Empty,
            VideoPaths = videoPaths,
            VideoDurationSeconds = videos.FirstOrDefault()?.DurationSeconds?.ToString() ?? string.Empty,
            Videos = videos.Select(v => new ProductVideoDto
            {
                Id = v.Id,
                Path = v.Path,
                VideoPath = v.Path,
                DurationSeconds = v.DurationSeconds,
                IsMuted = v.IsMuted
            }).ToList(),
            AddressId = x.AddressId?.ToString(),
            Address = x.AddressId.HasValue ? addressText : null,
            CreatedAt = FormatDateTimeText(x.CreatedAt),
            UpdatedAt = FormatDateTimeText(x.UpdatedAt),
            PendingOffersCount = pendingOffersByProduct.GetValueOrDefault(x.ProductId).ToString(),
            HasRetailPricing = ProductTypeCodes.HasRetailPricing(
                x.CategoryId,
                x.ProductTypeId,
                x.RetailPrice,
                x.RetailUnitId,
                x.RetailQuantity),
            RetailPrice = x.RetailPrice is > 0 ? x.RetailPrice.Value.ToString("0.##") : string.Empty,
            RetailUnitName = displayRetailUnit,
            RetailUnitNameEn = retailUnitNameEn,
            RetailUnitNameAr = retailUnitNameAr,
            RetailQuantity = x.RetailQuantity is > 0 ? x.RetailQuantity.Value.ToString() : string.Empty,
            RetailPackaging = x.RetailPackaging,
            RetailPackagingDetails = x.RetailPackagingDetails ?? string.Empty,
            RetailDescription = displayRetailDescription ?? string.Empty,
            RetailDescriptionEn = retailDescriptionEn,
            RetailDescriptionAr = retailDescriptionAr,
            RequestTypeId = x.RequestTypeId?.ToString(),
            RequestTypeName = requestTypeNameEn,
            RequestTypeNameEn = requestTypeNameEn,
            RequestTypeNameAr = CatalogLocalizationHelper.RequestTypeNameAr(x.RequestTypeId, requestTypeNameEn),
            BookingPriceTypeId = x.BookingPriceTypeId?.ToString(),
            BookingPriceTypeName = !string.IsNullOrWhiteSpace(x.BookingPriceTypeName)
                ? x.BookingPriceTypeName
                : x.BookingPriceTypeId switch
                {
                    1 => "FOB",
                    2 => "CNF",
                    3 => "CIF",
                    _ => null
                },
            Images = x.Images,
            Documents = x.Documents
        };
        }).ToList();

        var rawShippingPosts = await productData.GetOwnerShippingPostsAsync(parsedOwnerId, cancellationToken);

        var shippingPosts = rawShippingPosts.Select(x => new MyShippingPostListingDto
        {
            FromCountryName = x.FromCountry?.CountryNameEn ?? string.Empty,
            FromPortName = x.FromPort?.PortNameEn ?? string.Empty,
            ToCountryName = x.ToCountry?.CountryNameEn ?? string.Empty,
            ToPortName = x.ToPort?.PortNameEn ?? string.Empty,
            PriceUsd = x.PriceUsd.ToString("0.##"),
            ShippingCostUsd = x.ShippingCostUsd.ToString("0.##"),
            Container20ftPriceUsd = x.Container20ftPriceUsd?.ToString("0.##") ?? string.Empty,
            Container40ftPriceUsd = x.Container40ftPriceUsd?.ToString("0.##") ?? string.Empty,
            PhoneNumber = x.PhoneNumber,
            CreatedAt = FormatDateTimeText(x.CreatedAt)
        }).ToList();

        var response = new MyListingsResponse
        {
            OwnerName = ownerName,
            ProductCount = products.Count.ToString(),
            ShippingPostCount = shippingPosts.Count.ToString(),
            ProductsShippingHelp =
                "لكل منتج: shipping.routeSummary = مسار الشحن (بلد وميناء التحميل → بلد وميناء الوصول) يُملأ عند إنشاء الإعلان. " +
                "shipping.additionalShippingNotes = ملاحظات نصية اختيارية (قد تكون فارغة). " +
                "إذا كانت الحقول فارغة فغالباً المنتج قديم أو لم يُكمل المورد بيانات المسار.",
            ShippingPostsHelp =
                "shippingPosts = إعلانات شحن دولي منفصلة (خدمة نقل بين موانئ) وليست شحن المنتج. " +
                "القائمة فارغة إذا لم ينشر المستخدم إعلان شحن عبر /api/InternationalShipping/posts.",
            Products = products,
            ShippingPosts = shippingPosts
        };

        await tieredCache.SetAsync(cacheKey, response, MyListingsTtl, cancellationToken);
        return response;
    }

    private static MyListingsResponse? TryReadMyListings(object? cached)
    {
        if (cached is MyListingsResponse response)
        {
            return response;
        }

        if (cached is JsonElement element)
        {
            try
            {
                return element.Deserialize<MyListingsResponse>(MyListingsJsonOptions);
            }
            catch
            {
                return null;
            }
        }

        return null;
    }

    private static MyProductShippingInfoDto BuildMyProductShipping(
        string? originCountry,
        string? originCountryAr,
        string? loadingPort,
        string? loadingPortAr,
        string? destinationCountry,
        string? destinationCountryAr,
        string? arrivalPort,
        string? arrivalPortAr,
        string? additionalNotes,
        string? shippingDuration,
        bool preferArabic = false)
    {
        static string Pick(bool ar, string? en, string? arText) =>
            ar
                ? (string.IsNullOrWhiteSpace(arText) ? (en ?? string.Empty) : arText)
                : (string.IsNullOrWhiteSpace(en) ? (arText ?? string.Empty) : en);

        var fromCountry = Pick(preferArabic, originCountry, originCountryAr);
        var toCountry = Pick(preferArabic, destinationCountry, destinationCountryAr);
        // Port catalog Arabic is incomplete — keep English for ports.
        var fromPort = loadingPort ?? string.Empty;
        var toPort = arrivalPort ?? string.Empty;

        var hasRoute = !string.IsNullOrWhiteSpace(fromCountry)
            || !string.IsNullOrWhiteSpace(toCountry)
            || !string.IsNullOrWhiteSpace(fromPort)
            || !string.IsNullOrWhiteSpace(toPort);

        var routeSummary = string.Empty;
        if (hasRoute)
        {
            var from = string.IsNullOrWhiteSpace(fromPort)
                ? fromCountry
                : $"{fromCountry} ({fromPort})";
            var to = string.IsNullOrWhiteSpace(toPort)
                ? toCountry
                : $"{toCountry} ({toPort})";
            if (!string.IsNullOrWhiteSpace(from) && !string.IsNullOrWhiteSpace(to))
            {
                routeSummary = preferArabic ? $"من {from} → إلى {to}" : $"From {from} → To {to}";
            }
            else if (!string.IsNullOrWhiteSpace(to))
            {
                routeSummary = to;
            }
            else
            {
                routeSummary = from;
            }
        }

        return new MyProductShippingInfoDto
        {
            RouteFromCountry = fromCountry,
            RouteFromCountryAr = originCountryAr ?? string.Empty,
            RouteFromPort = fromPort,
            RouteFromPortAr = loadingPortAr ?? string.Empty,
            RouteToCountry = toCountry,
            RouteToCountryAr = destinationCountryAr ?? string.Empty,
            RouteToPort = toPort,
            RouteToPortAr = arrivalPortAr ?? string.Empty,
            RouteSummary = routeSummary,
            ShippingDuration = shippingDuration ?? string.Empty,
            AdditionalShippingNotes = additionalNotes ?? string.Empty,
            HasRouteInformation = hasRoute ? "Yes" : "No"
        };
    }
}
