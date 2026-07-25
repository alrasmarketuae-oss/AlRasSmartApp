using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class RequestOfferMapper
{
    public static MyRequestOfferDto Map(
        Order order,
        Product product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        Guid viewerUserId)
    {
        var (unitPrice, totalPrice, currency) = ResolveDisplayedPrices(
            order,
            product,
            settings,
            categoryCommissions,
            viewerUserId);

        var isPendingSellerAction = !order.IsApproved
            && order.StatusId == OrderStatusCodes.AwaitingSellerApproval
            && order.IsAdminApproved;

        return new MyRequestOfferDto
        {
            OrderId = order.Id,
            ProductId = order.ProductId,
            ProductName = product.NameEn ?? string.Empty,
            Quantity = order.Quantity,
            UnitName = AdminOrderMapper.ResolveOrderUnitName(order, product),
            UnitPrice = unitPrice,
            TotalPrice = totalPrice,
            Currency = currency,
            UnitPriceFormatted = $"{unitPrice:0.00} {currency}",
            TotalPriceFormatted = $"{totalPrice:0.00} {currency}",
            StatusId = order.StatusId,
            StatusName = RequestOfferStatusLabels.ResolveNameEn(order),
            StatusAr = RequestOfferStatusLabels.ResolveNameAr(order),
            IsApproved = order.IsApproved,
            IsAdminApproved = order.IsAdminApproved,
            CanAccept = isPendingSellerAction,
            CanReject = isPendingSellerAction,
            CreatedAt = UtcDateTimeHelper.AsUtc(order.CreatedAt),
            PortName = order.Port?.PortNameEn,
            DestinationCountryName = order.Port?.Country?.CountryNameEn
                ?? product.DestinationCountry?.CountryNameEn,
            Notes = order.Notes,
            ImagePaths = order.Images?
                .OrderBy(x => x.Id)
                .Select(x => x.ImagePath)
                .Where(IsImagePath)
                .ToList() ?? [],
            DocumentPaths = order.Images?
                .OrderBy(x => x.Id)
                .Select(x => x.ImagePath)
                .Where(IsDocumentPath)
                .ToList() ?? []
        };
    }

    private static (decimal UnitPrice, decimal TotalPrice, string Currency) ResolveDisplayedPrices(
        Order order,
        Product product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        Guid viewerUserId)
    {
        // Request owner reviewing supplier offers: show customer-facing price with app commission.
        if (product.ProductTypeId == ProductTypeCodes.Requests
            && product.OwnerId == viewerUserId)
        {
            return AdminOrderPricingHelper.GetRequestOfferCustomerPrices(
                order,
                product,
                settings,
                categoryCommissions);
        }

        // Supplier / seller inbox: raw submitted or list price only.
        return ResolveSupplierFacingPrices(order, product);
    }

    private static (decimal UnitPrice, decimal TotalPrice, string Currency) ResolveSupplierFacingPrices(
        Order order,
        Product product)
    {
        var currency = ProductCurrencyHelper.Normalize(product.Currency, product.ProductTypeId);
        var qty = order.Quantity <= 0 ? 1m : order.Quantity;

        // Requests: submitted offer amount before app markup.
        if (product.ProductTypeId == ProductTypeCodes.Requests)
        {
            var (supplierUnit, supplierTotal) =
                AdminOrderPricingHelper.ResolveSubmittedOrderAmounts(order);
            return (supplierUnit, supplierTotal, currency);
        }

        // Retail channel only via IsRetailPurchase / pure retail — not UnitId match
        // (hybrid wholesale PO may share UnitId with RetailUnitId).
        var isRetailChannel = ProductTypeCodes.IsRetailOrder(order);

        if (isRetailChannel && product.RetailPrice is > 0)
        {
            var retailPresented = ProductPricePresenter.Present(
                product.RetailPrice.Value,
                ProductTypeCodes.Retail,
                "AED",
                usdToAedRate: 3.6725m);
            var retailUnit = retailPresented.Price;
            var retailTotal = decimal.Round(retailUnit * qty, 2, MidpointRounding.AwayFromZero);
            return (retailUnit, retailTotal, retailPresented.Currency);
        }

        // Offers / Booking / pure retail / wholesale: product base price × quantity.
        if (product.USDPrice > 0)
        {
            var presentTypeId = isRetailChannel
                ? ProductTypeCodes.Retail
                : ProductTypeCodes.WholesaleCommissionProductTypeId(product.CategoryId, product.ProductTypeId);
            var presentCurrency = isRetailChannel ? "AED" : product.Currency;
            var supplierPrice = ProductPricePresenter.Present(
                product.USDPrice,
                presentTypeId,
                presentCurrency,
                usdToAedRate: 3.6725m);
            var unit = supplierPrice.Price;
            var total = decimal.Round(unit * qty, 2, MidpointRounding.AwayFromZero);
            return (unit, total, supplierPrice.Currency);
        }

        var (fallbackUnit, fallbackTotal) =
            AdminOrderPricingHelper.ResolveSubmittedOrderAmounts(order);
        return (fallbackUnit, fallbackTotal, currency);
    }

    private static bool IsImagePath(string path)
    {
        var lower = path.ToLowerInvariant();
        return lower.EndsWith(".jpg")
            || lower.EndsWith(".jpeg")
            || lower.EndsWith(".png")
            || lower.EndsWith(".webp")
            || lower.EndsWith(".gif");
    }

    private static bool IsDocumentPath(string path) =>
        !string.IsNullOrWhiteSpace(path) && !IsImagePath(path);
}
