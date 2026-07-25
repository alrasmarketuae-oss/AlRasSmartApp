using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using DataLayer.Models;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Helpers;

public static class AdminOrderPricingHelper
{
    public static void ApplyPricingFields(
        AdminOrderListItemDto dto,
        Order order,
        Product? product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate)
    {
        if (product is null)
        {
            return;
        }

        // Channel is only IsRetailPurchase / pure retail — never infer from UnitId
        // (wholesale and retail often share the same unit on hybrid ads).
        var isRetailChannel = ProductTypeCodes.IsRetailOrder(order);

        var commissionProductTypeId = isRetailChannel
            ? ProductTypeCodes.Retail
            : ProductTypeCodes.WholesaleCommissionProductTypeId(product.CategoryId, product.ProductTypeId);

        var commissionCategoryId = isRetailChannel ? null : product.CategoryId;

        var commissionPercent = CustomerPriceCalculator.ResolveCommissionPercent(
            commissionProductTypeId,
            commissionCategoryId,
            settings,
            categoryCommissions);

        if (product.ProductTypeId == ProductTypeCodes.Requests)
        {
            ApplySubmittedOrderPricing(dto, order, product, commissionPercent);
            return;
        }

        var supplierBasePrice = isRetailChannel && product.RetailPrice is > 0
            ? product.RetailPrice.Value
            : product.USDPrice;

        var markedUpUsd = CustomerPriceCalculator.ApplyProductMarkup(
            supplierBasePrice,
            commissionProductTypeId,
            commissionCategoryId,
            settings,
            categoryCommissions);

        // Hybrids keep ProductTypeId=Retail; wholesale must present with category currency (USD).
        var presentTypeId = isRetailChannel
            ? ProductTypeCodes.Retail
            : ProductTypeCodes.WholesaleCommissionProductTypeId(product.CategoryId, product.ProductTypeId);
        var presentCurrency = isRetailChannel
            ? "AED"
            : product.Currency;

        var supplierPrice = ProductPricePresenter.Present(
            supplierBasePrice,
            presentTypeId,
            presentCurrency,
            usdToAedRate);

        var customerPrice = ProductPricePresenter.Present(
            markedUpUsd,
            presentTypeId,
            presentCurrency,
            usdToAedRate);

        var supplierUnitPrice = supplierPrice.Price;
        var customerUnitPrice = customerPrice.Price;
        var supplierTotalPrice = decimal.Round(supplierUnitPrice * order.Quantity, 2, MidpointRounding.AwayFromZero);
        var customerTotalPrice = decimal.Round(customerUnitPrice * order.Quantity, 2, MidpointRounding.AwayFromZero);
        var appProfitAmount = decimal.Round(customerTotalPrice - supplierTotalPrice, 2, MidpointRounding.AwayFromZero);

        dto.Currency = customerPrice.Currency;
        dto.CommissionPercent = commissionPercent;
        dto.SupplierUnitPrice = supplierUnitPrice;
        dto.SupplierTotalPrice = supplierTotalPrice;
        dto.CustomerUnitPrice = customerUnitPrice;
        dto.CustomerTotalPrice = customerTotalPrice;
        dto.AppProfitAmount = appProfitAmount;
        dto.ChargedUnitPrice = order.UnitPrice;
        dto.ChargedTotalPrice = decimal.Round(order.TotalPrice + order.VatAed, 2, MidpointRounding.AwayFromZero);
        dto.SupplierUnitPriceFormatted = FormatPrice(supplierUnitPrice, supplierPrice.Currency);
        dto.SupplierTotalPriceFormatted = FormatPrice(supplierTotalPrice, supplierPrice.Currency);
        dto.CustomerUnitPriceFormatted = FormatPrice(customerUnitPrice, customerPrice.Currency);
        dto.CustomerTotalPriceFormatted = FormatPrice(customerTotalPrice, customerPrice.Currency);
        dto.AppProfitFormatted = FormatPrice(appProfitAmount, customerPrice.Currency);
        dto.AmountFormatted = dto.CustomerTotalPriceFormatted;

        if (order.VatAed > 0)
        {
            var chargedTotal = dto.ChargedTotalPrice;
            dto.CustomerTotalPrice = chargedTotal;
            dto.CustomerTotalPriceFormatted = FormatPrice(chargedTotal, customerPrice.Currency);
            dto.AmountFormatted = dto.CustomerTotalPriceFormatted;
        }
    }

    /// <summary>
    /// Sets checkout amounts actually charged to the customer (line + VAT + domestic shipping share).
    /// Does not change commission / supplier pricing fields.
    /// </summary>
    public static void ApplyChargedCheckoutAmounts(AdminOrderListItemDto dto, Order order)
    {
        var currency = ProductCurrencyHelper.Normalize(dto.Currency);
        var hasAedCheckoutExtras = order.VatAed > 0
            || ResolveCheckoutShippingAed(order) > 0
            || order.PendingOrderId.HasValue;

        // Direct product orders (Requests offers / Booking / Offers): grand total =
        // customer total with commission. Retail cart checkout keeps AED VAT/shipping path.
        if (!hasAedCheckoutExtras)
        {
            var productTotal = dto.CustomerTotalPrice > 0
                ? dto.CustomerTotalPrice
                : decimal.Round(order.TotalPrice, 2, MidpointRounding.AwayFromZero);

            dto.ChargedShippingAed = 0m;
            dto.ShippingCostAed = 0m;
            dto.ChargedGrandTotalAed = string.Equals(currency, "AED", StringComparison.OrdinalIgnoreCase)
                ? productTotal
                : 0m;
            dto.ChargedTotalPrice = productTotal;
            dto.ChargedGrandTotalFormatted = FormatPrice(productTotal, currency);
            dto.AmountFormatted = dto.ChargedGrandTotalFormatted;
            return;
        }

        var lineProductsAndVat = decimal.Round(order.TotalPrice + order.VatAed, 2, MidpointRounding.AwayFromZero);
        var shippingAed = ResolveCheckoutShippingAed(order);
        var grandTotal = decimal.Round(lineProductsAndVat + shippingAed, 2, MidpointRounding.AwayFromZero);

        dto.ChargedShippingAed = shippingAed;
        dto.ChargedGrandTotalAed = grandTotal;
        dto.ShippingCostAed = shippingAed;
        dto.ChargedGrandTotalFormatted = FormatPrice(grandTotal, "AED");
        dto.ChargedTotalPrice = grandTotal;
        dto.AmountFormatted = dto.ChargedGrandTotalFormatted;
    }

    private static decimal ResolveCheckoutShippingAed(Order order)
    {
        if (order.IsSelfPickup || order.PendingOrder?.IsSelfPickup == true)
        {
            return 0m;
        }

        var pending = order.PendingOrder;
        var cartShipping = pending?.ShippingCostAed ?? 0m;
        if (cartShipping <= 0 && order.ShippingCostAed > 0)
        {
            cartShipping = order.ShippingCostAed;
        }

        if (cartShipping <= 0)
        {
            return 0m;
        }

        if (pending is not null && pending.SubtotalAed > 0 && order.TotalPrice > 0)
        {
            return decimal.Round(
                cartShipping * order.TotalPrice / pending.SubtotalAed,
                2,
                MidpointRounding.AwayFromZero);
        }

        return cartShipping;
    }

    public static OrderDetailDto ToCustomerFacingDetail(
        Order order,
        Product product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions)
    {
        var detail = OrderResponseMapper.ToDetail(order);
        if (product.ProductTypeId != ProductTypeCodes.Requests)
        {
            return detail;
        }

        var commissionPercent = CustomerPriceCalculator.ResolveCommissionPercent(
            product.ProductTypeId,
            product.CategoryId,
            settings,
            categoryCommissions);

        var (supplierUnitPrice, supplierTotalPrice) = ResolveSubmittedOrderAmounts(order);
        var (customerUnitPrice, customerTotalPrice) = ApplyRequestsCommission(
            supplierUnitPrice,
            supplierTotalPrice,
            commissionPercent);

        return new OrderDetailDto
        {
            Id = detail.Id,
            FromUserId = detail.FromUserId,
            ToUserId = detail.ToUserId,
            ProductId = detail.ProductId,
            Quantity = detail.Quantity,
            UnitPrice = customerUnitPrice,
            TotalPrice = customerTotalPrice,
            CreatedAt = detail.CreatedAt,
            StatusId = detail.StatusId,
            Status = detail.Status,
            StatusAr = detail.StatusAr,
            OrderGroupId = detail.OrderGroupId,
            PendingOrderId = detail.PendingOrderId,
            PaymentMethod = detail.PaymentMethod,
            PaymentMethodName = detail.PaymentMethodName,
            StripeSessionId = detail.StripeSessionId,
            UnitId = detail.UnitId,
            IsApproved = detail.IsApproved,
            Notes = detail.Notes,
            PortId = detail.PortId,
            PortName = detail.PortName,
            ImagePaths = detail.ImagePaths,
            VideoPaths = detail.VideoPaths
        };
    }

    private static void ApplySubmittedOrderPricing(
        AdminOrderListItemDto dto,
        Order order,
        Product product,
        decimal commissionPercent)
    {
        var (supplierUnitPrice, supplierTotalPrice) = ResolveSubmittedOrderAmounts(order);
        var (customerUnitPrice, customerTotalPrice) = ApplyRequestsCommission(
            supplierUnitPrice,
            supplierTotalPrice,
            commissionPercent);
        var appProfitAmount = decimal.Round(customerTotalPrice - supplierTotalPrice, 2, MidpointRounding.AwayFromZero);
        var currency = ProductCurrencyHelper.Normalize(product.Currency, product.ProductTypeId);

        dto.Currency = currency;
        dto.CommissionPercent = commissionPercent;
        dto.SupplierUnitPrice = supplierUnitPrice;
        dto.SupplierTotalPrice = supplierTotalPrice;
        dto.CustomerUnitPrice = customerUnitPrice;
        dto.CustomerTotalPrice = customerTotalPrice;
        dto.AppProfitAmount = appProfitAmount;
        dto.ChargedUnitPrice = customerUnitPrice;
        dto.ChargedTotalPrice = customerTotalPrice;
        dto.UnitPrice = customerUnitPrice;
        dto.TotalPrice = customerTotalPrice;
        dto.SupplierUnitPriceFormatted = FormatPrice(supplierUnitPrice, currency);
        dto.SupplierTotalPriceFormatted = FormatPrice(supplierTotalPrice, currency);
        dto.CustomerUnitPriceFormatted = FormatPrice(customerUnitPrice, currency);
        dto.CustomerTotalPriceFormatted = FormatPrice(customerTotalPrice, currency);
        dto.AppProfitFormatted = FormatPrice(appProfitAmount, currency);
        dto.AmountFormatted = dto.CustomerTotalPriceFormatted;
    }

    public static (decimal CustomerUnitPrice, decimal CustomerTotalPrice, string Currency) GetRequestOfferCustomerPrices(
        Order order,
        Product product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions)
    {
        var commissionPercent = CustomerPriceCalculator.ResolveCommissionPercent(
            product.ProductTypeId,
            product.CategoryId,
            settings,
            categoryCommissions);

        var (supplierUnitPrice, supplierTotalPrice) = ResolveSubmittedOrderAmounts(order);
        var (customerUnitPrice, customerTotalPrice) = ApplyRequestsCommission(
            supplierUnitPrice,
            supplierTotalPrice,
            commissionPercent);
        var currency = ProductCurrencyHelper.Normalize(product.Currency, product.ProductTypeId);

        return (customerUnitPrice, customerTotalPrice, currency);
    }

    /// <summary>
    /// My Offers (submitter view): show the raw offer amount without app commission markup.
    /// Call after <see cref="ApplyPricingFields"/> / <see cref="ApplyChargedCheckoutAmounts"/>.
    /// </summary>
    public static void ApplySupplierFacingOfferDisplay(AdminOrderListItemDto dto, Order order, Product? product)
    {
        var (supplierUnitPrice, supplierTotalPrice) = ResolveSubmittedOrderAmounts(order);
        var currency = ProductCurrencyHelper.Normalize(product?.Currency, product?.ProductTypeId);
        var formatted = FormatPrice(supplierTotalPrice, currency);
        var unitFormatted = FormatPrice(supplierUnitPrice, currency);

        dto.Currency = currency;
        dto.UnitPrice = supplierUnitPrice;
        dto.TotalPrice = supplierTotalPrice;
        dto.SupplierUnitPrice = supplierUnitPrice;
        dto.SupplierTotalPrice = supplierTotalPrice;
        dto.CustomerUnitPrice = supplierUnitPrice;
        dto.CustomerTotalPrice = supplierTotalPrice;
        dto.AppProfitAmount = 0m;
        dto.ChargedUnitPrice = supplierUnitPrice;
        dto.ChargedTotalPrice = supplierTotalPrice;
        dto.ChargedShippingAed = 0m;
        dto.ChargedGrandTotalAed = string.Equals(currency, "AED", StringComparison.OrdinalIgnoreCase)
            ? supplierTotalPrice
            : 0m;
        dto.SupplierUnitPriceFormatted = unitFormatted;
        dto.SupplierTotalPriceFormatted = formatted;
        dto.CustomerUnitPriceFormatted = unitFormatted;
        dto.CustomerTotalPriceFormatted = formatted;
        dto.AppProfitFormatted = FormatPrice(0m, currency);
        dto.ChargedGrandTotalFormatted = formatted;
        dto.AmountFormatted = formatted;
    }

    private static (decimal CustomerUnitPrice, decimal CustomerTotalPrice) ApplyRequestsCommission(
        decimal supplierUnitPrice,
        decimal supplierTotalPrice,
        decimal commissionPercent) =>
        (
            CustomerPriceCalculator.ApplyPercentMarkup(supplierUnitPrice, commissionPercent),
            CustomerPriceCalculator.ApplyPercentMarkup(supplierTotalPrice, commissionPercent));

    public static (decimal SupplierUnitPrice, decimal SupplierTotalPrice) ResolveSubmittedOrderAmounts(Order order)
    {
        var quantity = order.Quantity <= 0 ? 1 : order.Quantity;
        var storedUnit = decimal.Round(order.UnitPrice, 2, MidpointRounding.AwayFromZero);
        var storedTotal = decimal.Round(order.TotalPrice, 2, MidpointRounding.AwayFromZero);
        var totalFromUnit = decimal.Round(storedUnit * quantity, 2, MidpointRounding.AwayFromZero);

        if (storedTotal > totalFromUnit)
        {
            return (
                decimal.Round(storedTotal / quantity, 2, MidpointRounding.AwayFromZero),
                storedTotal);
        }

        if (storedUnit > 0)
        {
            return (storedUnit, totalFromUnit);
        }

        if (storedTotal > 0)
        {
            var unit = quantity > 1
                ? decimal.Round(storedTotal / quantity, 2, MidpointRounding.AwayFromZero)
                : storedTotal;
            return (unit, storedTotal);
        }

        return (0m, 0m);
    }

    public static (decimal UnitPrice, decimal TotalPrice) NormalizeRequestsOrderAmounts(
        decimal quantity,
        decimal inputUnitPrice,
        decimal inputTotalPrice)
    {
        var qty = quantity <= 0 ? 1 : quantity;
        var unit = decimal.Round(inputUnitPrice, 2, MidpointRounding.AwayFromZero);
        var total = decimal.Round(inputTotalPrice, 2, MidpointRounding.AwayFromZero);
        var totalFromUnit = decimal.Round(unit * qty, 2, MidpointRounding.AwayFromZero);

        if (total >= totalFromUnit - 0.01m)
        {
            if (total > totalFromUnit + 0.01m)
            {
                unit = qty > 1
                    ? decimal.Round(total / qty, 2, MidpointRounding.AwayFromZero)
                    : total;
            }

            return (unit, total >= totalFromUnit ? total : totalFromUnit);
        }

        unit = total;
        total = decimal.Round(unit * qty, 2, MidpointRounding.AwayFromZero);
        return (unit, total);
    }

    public static decimal GetUsdToAedRate(IConfiguration configuration) =>
        CurrencyConversionHelper.GetUsdToAedRate(configuration);

    private static string FormatPrice(decimal amount, string currency) =>
        $"{amount:0.00} {currency}";
}
