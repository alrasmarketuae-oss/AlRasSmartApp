using BusinessLayer.Dtos;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Helpers;

public static class AdminOrderMapper
{
    public static IQueryable<Order> WithAdminListDetails(IQueryable<Order> query) =>
        query
            .Include(x => x.FromUser)
            .Include(x => x.ToUser)
            .Include(x => x.Status)
            .Include(x => x.Unit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Category)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductType)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.RequestType)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.RetailUnit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductImages)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductDocuments)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductVideos)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.OriginCountry)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.DestinationCountry)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.LoadingPort)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ArrivalPort)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Address!)
                    .ThenInclude(a => a.City)
            .Include(x => x.Images)
            .Include(x => x.Videos)
            .Include(x => x.Port)
                .ThenInclude(x => x!.Country)
            .Include(x => x.PendingOrder!)
                .ThenInclude(p => p!.Address!)
                    .ThenInclude(a => a!.City)
            .Include(x => x.AdminOfferPrice);

    /// <summary>Same as list includes, plus full status timeline for order detail.</summary>
    public static IQueryable<Order> WithAdminDetailDetails(IQueryable<Order> query) =>
        WithAdminListDetails(query).Include(x => x.StatusHistories);

    public static AdminOrderListItemDto Map(Order x)
    {
        var product = x.Product;
        var orderAssetPaths = x.Images
            .OrderBy(i => i.Id)
            .Select(i => new AdminOrderImageDto { Id = i.Id, Path = i.ImagePath })
            .ToList();

        var orderImages = orderAssetPaths.Where(i => IsImagePath(i.Path)).ToList();
        var orderDocuments = orderAssetPaths
            .Where(i => IsDocumentPath(i.Path))
            .Select(i => i.Path)
            .ToList();

        var productImagePaths = product?.ProductImages
            .OrderBy(i => i.Id)
            .Select(i => i.ImagePath)
            .Where(p => !string.IsNullOrWhiteSpace(p) && IsImagePath(p))
            .ToList() ?? [];

        var productDocumentPaths = product?.ProductDocuments
            .OrderBy(i => i.Id)
            .Select(i => i.DocumentPath)
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .ToList() ?? [];

        var productImage = productImagePaths.FirstOrDefault();

        var originCountry = product?.OriginCountry?.CountryNameEn;
        var destinationCountry = product?.DestinationCountry?.CountryNameEn;
        var loadingPort = product?.LoadingPort?.PortNameEn;
        var arrivalPort = product?.ArrivalPort?.PortNameEn;

        var isRequestOffer = product?.ProductTypeId == ProductTypeCodes.Requests;

        return new AdminOrderListItemDto
        {
            Id = x.Id,
            ProductId = x.ProductId,
            CustomerName = isRequestOffer
                ? x.ToUser?.FullName ?? "—"
                : x.FromUser?.FullName ?? "—",
            CustomerEmail = isRequestOffer
                ? x.ToUser?.Email ?? "—"
                : x.FromUser?.Email ?? "—",
            CustomerPhone = isRequestOffer
                ? x.ToUser?.PhoneNumber
                : x.FromUser?.PhoneNumber,
            CustomerUserId = isRequestOffer ? x.ToUserId : x.FromUserId,
            SupplierName = isRequestOffer
                ? x.FromUser != null
                    ? (x.FromUser.CompanyName ?? x.FromUser.FullName)
                    : "—"
                : x.ToUser != null
                    ? (x.ToUser.CompanyName ?? x.ToUser.FullName)
                    : "—",
            SupplierEmail = isRequestOffer
                ? x.FromUser?.Email ?? "—"
                : x.ToUser?.Email ?? "—",
            SupplierPhone = isRequestOffer
                ? x.FromUser?.PhoneNumber
                : x.ToUser?.PhoneNumber,
            SupplierUserId = isRequestOffer ? x.FromUserId : x.ToUserId,
            SupplierAvatarPath = isRequestOffer
                ? x.FromUser?.ImgPath
                : x.ToUser?.ImgPath,
            ProductName = product?.NameEn ?? "—",
            ProductNameEn = product?.NameEn,
            ProductNameAr = DetectArabicHint(product?.NameEn) ? product?.NameEn : null,
            ProductDescription = product?.DescriptionEn,
            ProductDescriptionEn = product?.DescriptionEn,
            ProductDescriptionAr = DetectArabicHint(product?.DescriptionEn) ? product?.DescriptionEn : null,
            ProductTypeName = ResolveOrderChannelTypeName(x, product),
            ProductTypeNameEn = ResolveOrderChannelTypeName(x, product),
            ProductTypeNameAr = ResolveOrderChannelTypeNameAr(x, product),
            RequestTypeId = product?.RequestTypeId,
            RequestTypeName = product?.RequestType?.NameEn,
            Negotiable = product?.Negotiable,
            OfferDuration = product?.OfferDuration,
            Packaging = product?.Packaging,
            PackagingDetails = product?.PackagingDetails,
            IsRetailPurchase = x.IsRetailPurchase,
            CategoryName = product?.Category?.NameEn ?? "—",
            CategoryNameEn = product?.Category?.NameEn,
            CategoryNameAr = string.IsNullOrWhiteSpace(product?.Category?.NameAr)
                ? null
                : product!.Category!.NameAr,
            CategoryId = product?.CategoryId,
            PrimaryImagePath = orderImages.FirstOrDefault()?.Path ?? productImage,
            UnitName = ResolveOrderUnitName(x, product),
            UnitNameEn = ResolveOrderUnitName(x, product),
            UnitNameAr = CatalogLocalizationHelper.UnitNameAr(ResolveOrderUnitName(x, product)),
            StatusId = x.StatusId,
            StatusName = RequestOfferStatusLabels.ResolveNameEn(x),
            StatusLabelAr = RequestOfferStatusLabels.ResolveNameAr(x),
            UnitPrice = x.UnitPrice,
            TotalPrice = x.TotalPrice,
            AmountFormatted = ProductCurrencyHelper.FormatPrice(
                x.TotalPrice + x.VatAed,
                ProductCurrencyHelper.Normalize(product?.Currency, product?.ProductTypeId)),
            Currency = ProductCurrencyHelper.Normalize(product?.Currency, product?.ProductTypeId),
            Quantity = x.Quantity,
            // Requests: ad quantity the client asked for. Other types: same as order line qty.
            RequestedQuantity = isRequestOffer && product is { Quantity: > 0 }
                ? product.Quantity
                : x.Quantity,
            ProductAvailableQuantity = product?.Quantity,
            ProductViewsCount = product?.ViewsCount ?? 0,
            PaymentMethod = x.PaymentMethod,
            PaymentMethodName = GetPaymentMethodName(x.PaymentMethod),
            CreatedAt = UtcDateTimeHelper.AsUtc(x.CreatedAt),
            IsApproved = x.IsApproved,
            IsAdminApproved = x.IsAdminApproved,
            Notes = x.Notes,
            VideoPaths = ResolveVideoPaths(x, product),
            Videos = x.Videos
                .OrderByDescending(v => v.CreatedAt)
                .Where(v => !string.IsNullOrWhiteSpace(v.VideoPath))
                .Select(v => new AdminOrderVideoDto { Id = v.Id, Path = v.VideoPath })
                .ToList(),
            Images = orderImages,
            DocumentPaths = orderDocuments,
            ProductImagePaths = productImagePaths,
            ProductDocumentPaths = productDocumentPaths,
            PortId = x.PortId,
            PortName = x.Port?.PortNameEn,
            PortCountryName = x.Port?.Country?.CountryNameEn,
            OriginCountryName = originCountry ?? string.Empty,
            DestinationCountryName = destinationCountry ?? string.Empty,
            LoadingPortName = loadingPort ?? string.Empty,
            ArrivalPortName = arrivalPort ?? string.Empty,
            ShippingDescription = product?.ShippingDescriptionEn ?? string.Empty,
            ShippingDuration = product?.ShippingDuration ?? string.Empty,
            ShippingRouteSummary = AdminShippingDisplayHelper.BuildRouteSummary(
                originCountry,
                loadingPort,
                destinationCountry,
                arrivalPort),
            ProductAddress = AdminShippingDisplayHelper.FormatProductAddress(product?.Address),
            VatAed = x.VatAed,
            ShippingCostAed = ResolveShippingCostAed(x),
            IsSelfPickup = ResolveIsSelfPickup(x),
            DeliveryAddressLine = ResolveDeliveryAddressLine(x),
            DeliveryCityName = ResolveDeliveryCityName(x),
            StripeSessionId = FirstNonEmpty(
                x.StripeSessionId,
                x.PendingOrder?.StripeSessionId),
            PaymentIntentId = FirstNonEmpty(x.PendingOrder?.PaymentIntentId),
            OrderGroupId = x.OrderGroupId,
            PendingOrderId = x.PendingOrderId ?? x.PendingOrder?.Id,
            StripeRefundId = FirstNonEmpty(
                x.StripeRefundId,
                x.PendingOrder?.StripeRefundId),
            RefundedAtUtc = x.RefundedAtUtc.HasValue
                ? UtcDateTimeHelper.AsUtc(x.RefundedAtUtc.Value)
                : x.PendingOrder?.RefundedAtUtc is { } pendingRefundedAt
                    ? UtcDateTimeHelper.AsUtc(pendingRefundedAt)
                    : null,
            IsRefunded = x.RefundedAtUtc.HasValue
                || x.PendingOrder?.RefundedAtUtc.HasValue == true
                || !string.IsNullOrWhiteSpace(x.StripeRefundId)
                || !string.IsNullOrWhiteSpace(x.PendingOrder?.StripeRefundId),
            ReturnReason = x.ReturnReason,
            ReturnMediaPaths = ParseReturnMediaPaths(x.ReturnMediaPathsJson),
            ReturnRequestedAtUtc = x.ReturnRequestedAtUtc.HasValue
                ? UtcDateTimeHelper.AsUtc(x.ReturnRequestedAtUtc.Value)
                : null,
            ReturnAdminResponse = x.ReturnAdminResponse,
            ReturnRespondedAtUtc = x.ReturnRespondedAtUtc.HasValue
                ? UtcDateTimeHelper.AsUtc(x.ReturnRespondedAtUtc.Value)
                : null,
            NeedsAttention = RequestOfferStatusLabels.NeedsAttention(x),
            CanMarkReceived = CanMarkReceived(x),
            StatusHistory = x.StatusHistories
                .OrderBy(h => h.CreatedAtUtc)
                .ThenBy(h => h.Id)
                .Select(h => new AdminOrderStatusHistoryDto
                {
                    Id = h.Id,
                    StatusId = h.StatusId,
                    StatusNameEn = RequestOfferStatusLabels.NormalizeDisplayEn(h.StatusNameEn),
                    StatusNameAr = RequestOfferStatusLabels.NormalizeDisplayAr(h.StatusNameAr),
                    CreatedAtUtc = UtcDateTimeHelper.AsUtc(h.CreatedAtUtc),
                })
                .ToList(),
        };
    }

    private static bool CanMarkReceived(Order x) =>
        x.IsApproved
        && ProductTypeCodes.UsesAdminCustomStatus(x.Product)
        && !RequestOfferStatusLabels.IsFulfillmentComplete(x.StatusId)
        && x.StatusId is not OrderStatusCodes.ReturnRequested;

    public static List<string> ParseReturnMediaPaths(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return [];
        }

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<List<string>>(json) ?? [];
        }
        catch
        {
            return [];
        }
    }

    private static decimal ResolveShippingCostAed(Order x) =>
        x.ShippingCostAed > 0 ? x.ShippingCostAed : x.PendingOrder?.ShippingCostAed ?? 0m;

    private static bool ResolveIsSelfPickup(Order x) =>
        x.IsSelfPickup || (x.PendingOrder?.IsSelfPickup ?? false);

    private static string? ResolveDeliveryAddressLine(Order x)
    {
        if (!string.IsNullOrWhiteSpace(x.DeliveryAddressLine))
        {
            return x.DeliveryAddressLine.Trim();
        }

        if (!string.IsNullOrWhiteSpace(x.PendingOrder?.DeliveryAddressLine))
        {
            return x.PendingOrder!.DeliveryAddressLine!.Trim();
        }

        var address = x.PendingOrder?.Address;
        if (address != null)
        {
            return FormatAddressSnapshot(address.AddressLine1, address.AddressLine2);
        }

        return null;
    }

    private static string? FormatAddressSnapshot(string? line1, string? line2)
    {
        var first = line1?.Trim() ?? string.Empty;
        var second = line2?.Trim() ?? string.Empty;
        if (string.IsNullOrEmpty(first))
        {
            return string.IsNullOrEmpty(second) ? null : second;
        }

        return string.IsNullOrEmpty(second) ? first : $"{first}, {second}";
    }

    private static string? ResolveDeliveryCityName(Order x) =>
        x.DeliveryCityName
        ?? x.PendingOrder?.DeliveryCityName
        ?? x.PendingOrder?.Address?.City?.CityName;

    private static string GetPaymentMethodName(byte paymentMethod) =>
        paymentMethod switch
        {
            (byte)PaymentMethod.Online => "Online",
            (byte)PaymentMethod.CashOnDelivery => "CashOnDelivery",
            _ => "Unknown"
        };

    private static bool IsImagePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return false;
        var lower = path.ToLowerInvariant();
        return lower.EndsWith(".jpg")
            || lower.EndsWith(".jpeg")
            || lower.EndsWith(".png")
            || lower.EndsWith(".webp")
            || lower.EndsWith(".gif")
            || lower.Contains("/product-images/")
            || lower.Contains("/order-images/")
            || lower.Contains("\\product-images\\")
            || lower.Contains("\\order-images\\");
    }

    private static bool IsDocumentPath(string? path) =>
        !string.IsNullOrWhiteSpace(path) && !IsImagePath(path);

    private static string? FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return null;
    }

    /// <summary>
    /// Category / hybrid ads: label the order channel, never raw ProductType "Retail".
    /// Cart retail → Retail; Purchase Order (wholesale) → Wholesale.
    /// </summary>
    private static string ResolveOrderChannelTypeName(Order order, Product? product)
    {
        if (product is null)
        {
            return "—";
        }

        var isCatalogOrHybrid = product.CategoryId is > 0
            || product.Category is not null
            || ProductTypeCodes.HasRetailStockConfigured(product)
            || ProductTypeCodes.IsCategoryProduct(product);

        if (isCatalogOrHybrid)
        {
            // Do not use IsRetailOrder here — hybrids keep ProductTypeId=Retail;
            // only IsRetailPurchase marks the cart channel.
            return order.IsRetailPurchase ? "Retail" : "Wholesale";
        }

        return product.ProductType?.TypeNameEn ?? "—";
    }

    private static string? ResolveOrderChannelTypeNameAr(Order order, Product? product)
    {
        var channelEn = ResolveOrderChannelTypeName(order, product);
        return CatalogLocalizationHelper.TranslateProductTypeName(channelEn)
            ?? CatalogLocalizationHelper.ProductTypeNameAr(product?.ProductTypeId, channelEn);
    }

    private static bool DetectArabicHint(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        foreach (var ch in text)
        {
            if (ch is >= '\u0600' and <= '\u06FF')
            {
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// Prefer the unit stored on the order line. Never silently replace a different
    /// order UnitId with the product/request ad unit (that made Kg offers show as Ton).
    /// </summary>
    public static string ResolveOrderUnitName(Order order, Product? product)
    {
        if (!string.IsNullOrWhiteSpace(order.Unit?.UnitNameEn))
        {
            return order.Unit!.UnitNameEn;
        }

        if (order.UnitId is byte orderUnitId)
        {
            if (product?.UnitId == orderUnitId
                && !string.IsNullOrWhiteSpace(product.Unit?.UnitNameEn))
            {
                return product.Unit!.UnitNameEn;
            }

            if (order.IsRetailPurchase
                && product?.RetailUnitId == orderUnitId
                && !string.IsNullOrWhiteSpace(product.RetailUnit?.UnitNameEn))
            {
                return product.RetailUnit!.UnitNameEn;
            }

            var known = FallbackUnitNameById(orderUnitId);
            if (known is not null)
            {
                return known;
            }
        }

        if (order.IsRetailPurchase
            && !string.IsNullOrWhiteSpace(product?.RetailUnit?.UnitNameEn))
        {
            return product!.RetailUnit!.UnitNameEn;
        }

        // Only when the order has no unit of its own.
        if (order.UnitId is null)
        {
            return product?.Unit?.UnitNameEn ?? "—";
        }

        // Unknown unit id and nav not loaded — do not invent the product/request unit.
        return "—";
    }

    /// <summary>Seed Units table ids (RasAlSouqDbContext) — used when Order.Unit nav is not loaded.</summary>
    private static string? FallbackUnitNameById(byte unitId) => unitId switch
    {
        1 => "Ton",
        2 => "Gram",
        3 => "Kilogram",
        4 => "Carton",
        5 => "Bag",
        6 => "Dozen",
        7 => "Box",
        8 => "Piece",
        _ => null
    };

    /// Prefer order-attached videos; fall back to the product listing videos.
    private static List<string> ResolveVideoPaths(Order order, Product? product)
    {
        var paths = order.Videos
            .OrderByDescending(v => v.CreatedAt)
            .Select(v => v.VideoPath)
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (paths.Count == 0 && product is not null)
        {
            return ProductVideoPathsHelper.ResolveAll(product);
        }

        return paths;
    }
}
