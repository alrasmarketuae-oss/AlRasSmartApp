using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

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

        var owner = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == parsedOwnerId)
            .Select(x => new { x.FullName })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var rawProducts = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.OwnerId == parsedOwnerId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.ProductId,
                x.ProductCode,
                x.NameEn,
                x.CreatedLanguage,
                CategoryName = x.Category != null ? x.Category.NameEn : null,
                CategoryNameAr = x.Category != null ? x.Category.NameAr : null,
                CategoryImagePath = x.Category != null ? x.Category.ImgPath : null,
                ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : null,
                x.DescriptionEn,
                x.USDPrice,
                x.ProductTypeId,
                x.CategoryId,
                x.Currency,
                x.Quantity,
                UnitName = x.Unit != null ? x.Unit.UnitNameEn : null,
                x.RetailPrice,
                RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null,
                x.RetailUnitId,
                x.RetailQuantity,
                x.RetailPackaging,
                x.RetailPackagingDetails,
                x.RetailDescriptionEn,
                x.RequestTypeId,
                RequestTypeName = x.RequestType != null ? x.RequestType.NameEn : null,
                x.BookingPriceTypeId,
                BookingPriceTypeName = x.BookingPriceType != null ? x.BookingPriceType.NameEn : null,
                x.MinimumOrderQuantity,
                x.MaximumOrderQuantity,
                x.Status,
                x.IsApproved,
                x.DiscountPercentage,
                x.DiscountDays,
                x.ShippingDescriptionEn,
                x.ShippingDuration,
                x.OfferDuration,
                x.SupplierNotesEn,
                x.Packaging,
                x.PackagingDetails,
                x.Negotiable,
                x.IsFeatured,
                x.ViewsCount,
                x.VideoPath,
                x.VideoDurationSeconds,
                x.IsVideoMuted,
                OriginCountryName = x.OriginCountry != null ? x.OriginCountry.CountryNameEn : null,
                OriginCountryNameAr = x.OriginCountry != null ? x.OriginCountry.CountryNameAr : null,
                DestinationCountryName = x.DestinationCountry != null ? x.DestinationCountry.CountryNameEn : null,
                DestinationCountryNameAr = x.DestinationCountry != null ? x.DestinationCountry.CountryNameAr : null,
                LoadingPortName = x.LoadingPort != null ? x.LoadingPort.PortNameEn : null,
                LoadingPortNameAr = x.LoadingPort != null ? x.LoadingPort.PortNameAr : null,
                ArrivalPortName = x.ArrivalPort != null ? x.ArrivalPort.PortNameEn : null,
                ArrivalPortNameAr = x.ArrivalPort != null ? x.ArrivalPort.PortNameAr : null,
                x.CreatedAt,
                x.UpdatedAt,
                x.AddressId,
                Images = x.ProductImages.OrderBy(pi => pi.Id).Select(pi => pi.ImagePath).ToList(),
                Documents = x.ProductDocuments.OrderBy(pd => pd.Id).Select(pd => pd.DocumentPath).ToList()
            })
            .ToListAsync(cancellationToken);

        var addressLookup = await LoadAddressTextLookupAsync(rawProducts.Select(x => x.AddressId), cancellationToken);
        var usdToAedRate = GetUsdToAedRate();

        var productIds = rawProducts.Select(x => x.ProductId).ToList();
        var pendingOffersByProduct = await (
            from o in dbContext.Orders.AsNoTracking()
            join p in dbContext.Products.AsNoTracking() on o.ProductId equals p.ProductId
            where productIds.Contains(o.ProductId)
                && !o.IsApproved
                && (
                    o.StatusId == OrderStatusCodes.AwaitingSellerApproval
                    || (p.ProductTypeId == ProductTypeCodes.Retail
                        && !o.IsAdminApproved
                        && (o.StatusId == OrderStatusCodes.Ordered
                            || o.StatusId == OrderStatusCodes.Paid)))
            group o by o.ProductId
            into g
            select new { ProductId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ProductId, x => x.Count, cancellationToken);

        var extraVideosLookup = productIds.Count == 0
            ? []
            : await dbContext.ProductVideos
                .AsNoTracking()
                .Where(v => productIds.Contains(v.ProductId))
                .OrderBy(v => v.Id)
                .Select(v => new { v.ProductId, v.VideoPath })
                .ToListAsync(cancellationToken);

        var extraVideosDict = extraVideosLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.Select(x => x.VideoPath).ToList());

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        var products = rawProducts.Select(x =>
        {
            var priced = BuildSupplierFacingPrice(x.USDPrice, x.ProductTypeId, x.Currency, usdToAedRate);
            var addressText = ResolveAddressText(x.AddressId, addressLookup);
            var videoPaths = ProductVideoPathsHelper.ResolveAll(
                x.VideoPath,
                extraVideosDict.GetValueOrDefault(x.ProductId));
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
            VideoDurationSeconds = x.VideoDurationSeconds?.ToString() ?? string.Empty,
            IsVideoMuted = x.IsVideoMuted,
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

        var rawShippingPosts = await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .Where(x => x.PublisherUserId == parsedOwnerId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                FromCountryName = x.FromCountry != null ? x.FromCountry.CountryNameEn : null,
                FromPortName = x.FromPort != null ? x.FromPort.PortNameEn : null,
                ToCountryName = x.ToCountry != null ? x.ToCountry.CountryNameEn : null,
                ToPortName = x.ToPort != null ? x.ToPort.PortNameEn : null,
                x.PriceUsd,
                x.ShippingCostUsd,
                x.Container20ftPriceUsd,
                x.Container40ftPriceUsd,
                x.PhoneNumber,
                x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var shippingPosts = rawShippingPosts.Select(x => new MyShippingPostListingDto
        {
            FromCountryName = x.FromCountryName ?? string.Empty,
            FromPortName = x.FromPortName ?? string.Empty,
            ToCountryName = x.ToCountryName ?? string.Empty,
            ToPortName = x.ToPortName ?? string.Empty,
            PriceUsd = x.PriceUsd.ToString("0.##"),
            ShippingCostUsd = x.ShippingCostUsd.ToString("0.##"),
            Container20ftPriceUsd = x.Container20ftPriceUsd.ToString("0.##"),
            Container40ftPriceUsd = x.Container40ftPriceUsd.ToString("0.##"),
            PhoneNumber = x.PhoneNumber,
            CreatedAt = FormatDateTimeText(x.CreatedAt)
        }).ToList();

        var response = new MyListingsResponse
        {
            OwnerName = owner.FullName,
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
