using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class OrdersAppService
{
    private async Task ApplyOrderProductTranslationsAsync(
        IReadOnlyList<AdminOrderListItemDto> items,
        CancellationToken cancellationToken)
    {
        if (items.Count == 0)
        {
            return;
        }

        var productIds = items
            .Select(x => x.ProductId)
            .Where(id => id != Guid.Empty)
            .Distinct()
            .ToList();
        if (productIds.Count == 0)
        {
            return;
        }

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        foreach (var dto in items)
        {
            translations.TryGetValue(dto.ProductId, out var tr);

            var rawNameEn = FirstNonEmpty(dto.ProductNameEn, dto.ProductName);
            var rawDescriptionEn = FirstNonEmpty(dto.ProductDescriptionEn, dto.ProductDescription);

            var nameEn = FirstNonEmpty(
                tr?.NameEn,
                DetectArabicHint(rawNameEn) ? null : rawNameEn);
            var nameAr = FirstNonEmpty(
                tr?.NameAr,
                dto.ProductNameAr,
                DetectArabicHint(rawNameEn) ? rawNameEn : null);
            var descriptionEn = FirstNonEmpty(
                tr?.DescriptionEn,
                DetectArabicHint(rawDescriptionEn) ? null : rawDescriptionEn);
            var descriptionAr = FirstNonEmpty(
                tr?.DescriptionAr,
                dto.ProductDescriptionAr,
                DetectArabicHint(rawDescriptionEn) ? rawDescriptionEn : null);

            if (!string.IsNullOrWhiteSpace(nameEn))
            {
                dto.ProductNameEn = nameEn;
                dto.ProductName = nameEn;
            }
            else if (DetectArabicHint(rawNameEn))
            {
                // Legacy Arabic stored in NameEn — clear English slot.
                dto.ProductNameEn = null;
                if (!string.IsNullOrWhiteSpace(nameAr))
                {
                    dto.ProductName = nameAr;
                }
            }

            if (!string.IsNullOrWhiteSpace(nameAr))
            {
                dto.ProductNameAr = nameAr;
            }

            if (!string.IsNullOrWhiteSpace(descriptionEn))
            {
                dto.ProductDescriptionEn = descriptionEn;
                dto.ProductDescription = descriptionEn;
            }
            else if (DetectArabicHint(rawDescriptionEn))
            {
                dto.ProductDescriptionEn = null;
                if (!string.IsNullOrWhiteSpace(descriptionAr))
                {
                    dto.ProductDescription = descriptionAr;
                }
            }

            if (!string.IsNullOrWhiteSpace(descriptionAr))
            {
                dto.ProductDescriptionAr = descriptionAr;
            }
        }
    }

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

    private bool IsStripeConfigured()
    {
        var secretKey = configuration["Stripe:SecretKey"] ?? string.Empty;
        return !string.IsNullOrWhiteSpace(secretKey)
            && !secretKey.Contains("change_me", StringComparison.OrdinalIgnoreCase);
    }


    /// <summary>Puts sellable stock back when support approves a retail return.</summary>
    private void RestoreStockOnReturnApproved(Order order)
    {
        if (!order.StockQuantityDeducted || order.Product is null)
        {
            return;
        }

        var restoreQuantity = ResolveQuantityInProductUnits(order, order.Product);
        if (restoreQuantity <= 0)
        {
            return;
        }

        ApplyStockRestore(order, order.Product, restoreQuantity);
        order.StockQuantityDeducted = false;
    }

    private void TryDeductStockOnOrderApproval(Order order)
    {
        if (order.StockQuantityDeducted || order.Product is null)
        {
            return;
        }

        var product = order.Product;

        // Request offers submitted in a different unit than the request ad:
        // accepting must not reduce the request's remaining quantity.
        if (ProductTypeCodes.IsRequests(product.ProductTypeId)
            && order.UnitId.HasValue
            && product.UnitId.HasValue
            && order.UnitId.Value != product.UnitId.Value)
        {
            return;
        }

        var deductQuantity = ResolveQuantityInProductUnits(order, product);

        if (deductQuantity <= 0)
        {
            throw new InvalidOperationException("Order quantity must be greater than zero.");
        }

        var (_, availableStock) = ResolveOrderStockChannel(order, product);
        if (deductQuantity > (decimal)availableStock)
        {
            throw new InvalidOperationException(
                $"Requested quantity ({deductQuantity}) exceeds available quantity ({availableStock}) for '{product.NameEn}'.");
        }

        ApplyStockDeduction(order, product, deductQuantity);
        order.StockQuantityDeducted = true;

        // Offers/Requests/Booking/Category ads pause when remaining wholesale quantity hits zero.
        // Retail-channel (hybrid) sales only deplete RetailQuantity — do not pause the wholesale ad.
        if (!ProductTypeCodes.UsesRetailStockChannel(order, product)
            && product.Quantity <= 0
            && (ProductTypeCodes.IsOffers(product.ProductTypeId)
                || ProductTypeCodes.IsRequests(product.ProductTypeId)
                || ProductTypeCodes.IsBooking(product.ProductTypeId)
                || ProductTypeCodes.IsCategoryProduct(product)))
        {
            product.Status = ProductStatusCodes.Paused;
        }
    }

    private static (Unit? Unit, long Quantity) ResolveRetailChannelStock(Product product)
    {
        if (ProductTypeCodes.HasRetailStockConfigured(product))
        {
            return (product.RetailUnit, product.RetailQuantity ?? 0);
        }

        return (product.Unit, product.Quantity);
    }

    private static (Unit? Unit, long Quantity) ResolveOrderStockChannel(Order order, Product product)
    {
        // Cart retail (hybrid) only — category/wholesale PO always uses Product.Quantity.
        if (ProductTypeCodes.UsesRetailStockChannel(order, product))
        {
            return (product.RetailUnit, product.RetailQuantity ?? 0);
        }

        return (product.Unit, product.Quantity);
    }

    private decimal ResolveQuantityInProductUnits(Order order, Product product)
    {
        var useRetailStock = ProductTypeCodes.UsesRetailStockChannel(order, product);
        var (stockUnit, _) = ResolveOrderStockChannel(order, product);
        byte? stockUnitId = useRetailStock
            ? product.RetailUnitId
            : product.UnitId;

        if (stockUnit is null || !order.UnitId.HasValue || order.UnitId == stockUnitId)
        {
            return order.Quantity;
        }

        var orderUnit = staticReferenceCache.FindUnitById(order.UnitId.Value);
        if (orderUnit is null)
        {
            return order.Quantity;
        }

        return OrderUnitConversion.ConvertQuantity(
            order.Quantity,
            orderUnit.UnitNameEn,
            stockUnit.UnitNameEn);
    }

    private static void ApplyStockDeduction(Order order, Product product, decimal quantity)
    {
        if (ProductTypeCodes.UsesRetailStockChannel(order, product))
        {
            product.RetailQuantity = (long)Math.Max(0, (decimal)(product.RetailQuantity ?? 0) - quantity);
        }
        else
        {
            // Wholesale / category / booking / offers / pure retail catalog stock.
            product.Quantity = (long)Math.Max(0, (decimal)product.Quantity - quantity);
        }

        product.UpdatedAt = DateTime.UtcNow;
    }

    private static void ApplyStockRestore(Order order, Product product, decimal quantity)
    {
        if (ProductTypeCodes.UsesRetailStockChannel(order, product))
        {
            product.RetailQuantity = (long)((decimal)(product.RetailQuantity ?? 0) + quantity);
        }
        else
        {
            product.Quantity = (long)((decimal)product.Quantity + quantity);
        }

        product.UpdatedAt = DateTime.UtcNow;
    }

    private static void ValidateDirectOrderQuantity(Product product, decimal quantity)
    {
        if (product.MinimumOrderQuantity.HasValue && quantity < product.MinimumOrderQuantity.Value)
        {
            throw new InvalidOperationException(
                $"Minimum order quantity is {product.MinimumOrderQuantity.Value}.");
        }

        if (product.MaximumOrderQuantity.HasValue && quantity > product.MaximumOrderQuantity.Value)
        {
            throw new InvalidOperationException(
                $"Maximum order quantity is {product.MaximumOrderQuantity.Value}.");
        }

        if (ProductTypeCodes.TracksSellableStock(product)
            && quantity > (decimal)product.Quantity)
        {
            throw new InvalidOperationException(
                $"Requested quantity ({quantity}) exceeds available quantity ({product.Quantity}).");
        }
    }

    private GeoPortSnapshot? ResolveOrderPort(Product product, string? portName)
    {
        if (!ProductTypeCodes.IsBooking(product.ProductTypeId))
        {
            if (!string.IsNullOrWhiteSpace(portName))
            {
                throw new ArgumentException("Port is only allowed for booking orders.");
            }

            return null;
        }

        if (string.IsNullOrWhiteSpace(portName))
        {
            throw new ArgumentException("PortName is required for booking orders.");
        }

        var port = staticReferenceCache.FindPortByName(portName.Trim())
            ?? throw new ArgumentException($"Port '{portName.Trim()}' was not found.");

        return port;
    }


    private static void EnsureUserCanUpdateStatus(User user, Order order, byte targetStatusId)
    {
        var isAdmin = user.RoleId == 1;
        var isBuyer = order.FromUserId == user.Id;
        var isSeller = order.ToUserId == user.Id;

        if (isAdmin)
        {
            return;
        }

        var allowed = (targetStatusId, isBuyer, isSeller) switch
        {
            (OrderStatusCodes.Approved, _, true) => true,
            (OrderStatusCodes.Paid, true, _) => true,
            // Shipping/delivery: admin-only for Retail; Offers/Category/Requests use custom text status.
            (OrderStatusCodes.Shipping, _, true) =>
                ProductTypeCodes.IsRetailOrder(order) == false
                && !ProductTypeCodes.UsesAdminCustomStatus(order.Product),
            (OrderStatusCodes.Delivered, _, true) =>
                ProductTypeCodes.IsRetailOrder(order) == false
                && !ProductTypeCodes.UsesAdminCustomStatus(order.Product),
            (OrderStatusCodes.PaidToSupplier, _, true) => true,
            (OrderStatusCodes.ReturnRequested, true, _) => true,
            (OrderStatusCodes.Cancelled, true, _) when order.StatusId is OrderStatusCodes.Ordered
                or OrderStatusCodes.AwaitingSellerApproval
                or OrderStatusCodes.Approved
                or OrderStatusCodes.Paid
                or OrderStatusCodes.Delivered => true,
            (OrderStatusCodes.Cancelled, _, true) => true,
            _ => false
        };

        if (!allowed)
        {
            throw new UnauthorizedAccessException("You are not allowed to update the order to this status.");
        }
    }

    private async Task EnsureUserCanAccessOrderAsync(Guid userId, Order order, CancellationToken cancellationToken)
    {
        if (order.FromUserId == userId || order.ToUserId == userId)
        {
            return;
        }

        // Product owner may view track/history even if ToUserId was stored differently.
        var ownerId = order.Product?.OwnerId;
        if (ownerId is null && order.ProductId != Guid.Empty)
        {
            ownerId = await orderData.GetProductOwnerIdAsync(order.ProductId, cancellationToken);
        }

        if (ownerId == userId)
        {
            return;
        }

        var user = await orderData.GetUserByIdAsync(userId, cancellationToken: cancellationToken);
        if (user?.RoleId == 1)
        {
            return;
        }

        throw new UnauthorizedAccessException("You are not allowed to access this order.");
    }

    private async Task EnsureUserCanViewRequestOffersAsync(Guid userId, Product product, CancellationToken cancellationToken)
    {
        if (product.OwnerId == userId)
        {
            return;
        }

        var user = await orderData.GetUserByIdAsync(userId, cancellationToken: cancellationToken);
        if (user?.RoleId == 1)
        {
            return;
        }

        throw new UnauthorizedAccessException("You are not allowed to view offers for this request.");
    }

    private static string? NormalizeNotes(string? notes)
    {
        if (string.IsNullOrWhiteSpace(notes))
        {
            return null;
        }

        var trimmed = notes.Trim();
        return trimmed.Length > 2000 ? trimmed[..2000] : trimmed;
    }

    private static void EnsureOnlinePaymentAllowed(Product product, PaymentMethod paymentMethod)
    {
        if (paymentMethod != PaymentMethod.Online)
        {
            return;
        }

        if (!ProductTypeCodes.IsRetailSellable(product))
        {
            var typeName = product.ProductType?.TypeNameEn ?? "Non-Retail";
            throw new InvalidOperationException(
                $"Online payment is only allowed for Retail products. '{product.NameEn}' is type '{typeName}'.");
        }
    }

    private async Task<Product> ResolveProductByIdAsync(Guid productId, CancellationToken cancellationToken)
    {
        return await orderData.GetProductForOrderAsync(productId, cancellationToken)
            ?? throw new KeyNotFoundException($"Product '{productId}' was not found.");
    }

    private static PaymentMethod ParsePaymentMethod(string? paymentMethodName)
    {
        if (string.IsNullOrWhiteSpace(paymentMethodName))
        {
            return PaymentMethod.CashOnDelivery;
        }

        return paymentMethodName.Trim().ToLowerInvariant() switch
        {
            "online" => PaymentMethod.Online,
            "cashondelivery" or "cash on delivery" or "cod" => PaymentMethod.CashOnDelivery,
            _ => throw new ArgumentException(
                "PaymentMethodName must be 'Online' or 'CashOnDelivery'.")
        };
    }

    private static List<string> NormalizeOrderAssetPaths(
        IReadOnlyList<string>? paths,
        string expectedFolder,
        string assetKind)
    {
        if (paths is null || paths.Count == 0)
        {
            return [];
        }

        var normalizedFolder = expectedFolder.Trim('/').ToLowerInvariant();
        var result = new List<string>();

        foreach (var rawPath in paths)
        {
            if (string.IsNullOrWhiteSpace(rawPath))
            {
                continue;
            }

            var path = WebRootFileHelper.NormalizeStoredPath(rawPath);
            var folderSegment = path.TrimStart('/').Split('/').FirstOrDefault()?.ToLowerInvariant();
            if (!string.Equals(folderSegment, normalizedFolder, StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException(
                    $"Each {assetKind} path must be stored under '/{expectedFolder}/'.");
            }

            if (!result.Contains(path, StringComparer.OrdinalIgnoreCase))
            {
                result.Add(path);
            }
        }

        return result;
    }

    /// <summary>
    /// Resolves the first status for a newly placed order.
    /// Booking / Category / Requests / Offers: admin only when the buyer added
    /// notes/specs or media; otherwise the order goes straight to the seller.
    /// Retail and other types still start at the admin dashboard.
    /// </summary>
    private static (byte StatusId, bool IsAdminApproved) ResolveInitialOrderStatus(
        Product product,
        byte paymentMethod,
        string? notes,
        int imageCount,
        int documentCount,
        int videoCount,
        decimal offerUnitPrice = 0m)
    {
        // Supplier bid below the request listing price always waits for admin,
        // even when there are no notes/media (those would otherwise skip admin).
        if (AdminOrderPricingHelper.IsRequestOfferBelowListingPrice(offerUnitPrice, product))
        {
            return (OrderStatusCodes.Ordered, false);
        }

        if (ProductTypeCodes.UsesSpecOrMediaAdminGate(product))
        {
            return ResolveSpecOrMediaGateStatus(notes, imageCount, documentCount, videoCount);
        }

        if (ProductTypeCodes.StartsWithSellerApproval(product))
        {
            return (OrderStatusCodes.AwaitingSellerApproval, true);
        }

        return (ResolveNewOrderStatus(product.ProductTypeId, paymentMethod), false);
    }

    /// <summary>Cart lines usually have notes only (no staged media paths).</summary>
    private static (byte StatusId, bool IsAdminApproved) ResolveInitialOrderStatusForCartLine(
        byte? productTypeId,
        byte? categoryId,
        string? notes)
    {
        if (ProductTypeCodes.UsesSpecOrMediaAdminGate(productTypeId, categoryId))
        {
            return ResolveSpecOrMediaGateStatus(notes, imageCount: 0, documentCount: 0, videoCount: 0);
        }

        if (ProductTypeCodes.StartsWithSellerApproval(productTypeId, categoryId))
        {
            return (OrderStatusCodes.AwaitingSellerApproval, true);
        }

        // Pure retail cart → admin dashboard first.
        return (ResolveNewOrderStatus(productTypeId, paymentMethod: 0), false);
    }

    private static (byte StatusId, bool IsAdminApproved) ResolveSpecOrMediaGateStatus(
        string? notes,
        int imageCount,
        int documentCount,
        int videoCount)
    {
        var hasSpecOrMedia = !string.IsNullOrWhiteSpace(notes)
            || imageCount > 0
            || documentCount > 0
            || videoCount > 0;

        // Spec and/or media → admin reviews first.
        if (hasSpecOrMedia)
        {
            return (OrderStatusCodes.Ordered, false);
        }

        // No spec and no media → seller/advertiser directly.
        return (OrderStatusCodes.AwaitingSellerApproval, true);
    }

    /// <summary>
    /// Default initial status for types that are not seller-first or offer/request flows.
    /// </summary>
    private static byte ResolveNewOrderStatus(byte? productTypeId, byte paymentMethod) =>
        OrderStatusCodes.Ordered;

    private sealed record CheckoutFulfillmentSnapshot(
        decimal ShippingCostAed,
        bool IsSelfPickup,
        string? DeliveryAddressLine,
        string? DeliveryCityName,
        decimal? DeliveryLatitude = null,
        decimal? DeliveryLongitude = null);

    private async Task<(Guid? AddressId, CheckoutFulfillmentSnapshot? Fulfillment)> ResolveCheckoutAddressAsync(
        PlaceOrderInput input,
        Guid userId,
        CancellationToken cancellationToken)
    {
        if (input.IsSelfPickup == true)
        {
            return (null, null);
        }

        if (input.AddressId.HasValue && input.AddressId.Value != Guid.Empty)
        {
            var address = await orderData.GetAddressForUserAsync(
                    input.AddressId.Value,
                    userId,
                    cancellationToken)
                ?? throw new KeyNotFoundException("Address not found.");

            var city = staticReferenceCache.FindCityById(address.CityId);
            var country = city is null ? null : staticReferenceCache.FindCountryById(city.CountryId);
            var addressLine = FormatCheckoutAddress(address, city?.CityName, country?.CountryNameEn);

            var shippingCostAed = decimal.Round(
                Math.Max(0, input.ShippingCostAed ?? 0),
                2,
                MidpointRounding.AwayFromZero);

            return (
                address.Id,
                new CheckoutFulfillmentSnapshot(
                    shippingCostAed,
                    false,
                    addressLine,
                    city?.CityName,
                    address.Latitude,
                    address.Longitude));
        }

        if (!string.IsNullOrWhiteSpace(input.AddressLine) && !string.IsNullOrWhiteSpace(input.CityName))
        {
            var city = staticReferenceCache.FindCityByName(input.CityName);
            if (city is not null)
            {
                var address = await orderData.GetAddressByUserCityLineAsync(
                    userId,
                    city.Id,
                    input.AddressLine!.Trim().ToLower(),
                    cancellationToken);

                if (address is not null)
                {
                    var country = staticReferenceCache.FindCountryById(city.CountryId);
                    var shippingCostAed = decimal.Round(
                        Math.Max(0, input.ShippingCostAed ?? 0),
                        2,
                        MidpointRounding.AwayFromZero);
                    var addressLine = FormatCheckoutAddress(address, city.CityName, country?.CountryNameEn);

                    return (
                        address.Id,
                        new CheckoutFulfillmentSnapshot(
                            shippingCostAed,
                            false,
                            addressLine,
                            city.CityName,
                            address.Latitude,
                            address.Longitude));
                }
            }
        }

        return (null, null);
    }

    private static CheckoutFulfillmentSnapshot BuildCheckoutFulfillmentSnapshot(
        PlaceOrderInput input,
        decimal shippingCostAed)
    {
        var isSelfPickup = input.IsSelfPickup == true;
        var cityName = NormalizeCheckoutText(input.CityName);
        var addressLine = NormalizeCheckoutText(input.AddressLine);

        if (isSelfPickup)
        {
            return new CheckoutFulfillmentSnapshot(0m, true, null, null);
        }

        return new CheckoutFulfillmentSnapshot(
            decimal.Round(Math.Max(0, shippingCostAed), 2, MidpointRounding.AwayFromZero),
            false,
            addressLine,
            cityName);
    }

    private static string? FormatCheckoutAddress(Address address, string? cityName, string? countryName)
    {
        var formatted = AddressTextFormatter.ToDisplayText(address, cityName, countryName);
        if (string.IsNullOrWhiteSpace(formatted))
        {
            formatted = string.IsNullOrWhiteSpace(address.AddressLine2)
                ? address.AddressLine1?.Trim()
                : $"{address.AddressLine1.Trim()}, {address.AddressLine2.Trim()}";
        }

        if (string.IsNullOrWhiteSpace(formatted))
        {
            return null;
        }

        return formatted.Length <= 1000 ? formatted : formatted[..1000];
    }

    private static string? NormalizeCheckoutText(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return trimmed.Length > 500 ? trimmed[..500] : trimmed;
    }

    private decimal ResolveRetailDomesticShippingAed(
        string? cityName,
        decimal fallback,
        decimal cartWeightKg)
    {
        var emirate = UaeEmirateResolver.ResolveCanonicalEnglishName(cityName);
        if (emirate is null)
        {
            return fallback;
        }

        try
        {
            var provider = serviceProvider.GetRequiredService<IInternalDomesticShippingProvider>();
            dynamic response = provider.GetPriceByEmirateResponse(emirate);
            decimal basePrice = response.priceAed;
            var excessRate = provider.GetExcessKgRateAed();
            return RetailDomesticShippingCalculator.CalculateTotalAed(
                basePrice,
                cartWeightKg,
                excessRate);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to resolve domestic shipping for city {CityName}", cityName);
        }

        return fallback;
    }

    private static IEnumerable<Guid> ResolveOrderParticipantUserIds(Order order)
    {
        yield return order.FromUserId;

        if (order.ToUserId != Guid.Empty)
        {
            yield return order.ToUserId;
        }

        var ownerId = order.Product?.OwnerId ?? Guid.Empty;
        if (ownerId != Guid.Empty && ownerId != order.ToUserId)
        {
            yield return ownerId;
        }
    }
}
