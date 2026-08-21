using BusinessLayer.Dtos;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class CustomerPricingHelper
{
    public static CustomerFacingPrice BuildCustomerFacingPrice(
        decimal baseUnitPrice,
        byte? productTypeId,
        byte? categoryId,
        string? productCurrency,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate)
    {
        var markedUp = CustomerPriceCalculator.ApplyProductMarkup(
            baseUnitPrice,
            productTypeId,
            categoryId,
            settings,
            categoryCommissions);

        return CustomerPriceCalculator.RoundUpToQuarter(
            ProductPricePresenter.Present(
                markedUp,
                productTypeId,
                ResolveProductCurrency(productTypeId, productCurrency),
                usdToAedRate));
    }

    public static decimal ResolveCartUnitPriceAed(
        Product product,
        string requestedUnitNameEn,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate)
    {
        if (ProductTypeCodes.HasRetailPricing(product))
        {
            if (product.RetailUnit is null || product.RetailPrice is not > 0)
            {
                throw new InvalidOperationException("Product retail unit/price is not set.");
            }

            var retailUnitName = product.RetailUnit.UnitNameEn;
            var markedUpInRetailUnit = CustomerPriceCalculator.ApplyProductMarkup(
                product.RetailPrice.Value,
                ProductTypeCodes.Retail,
                categoryId: null,
                settings,
                categoryCommissions);

            var markedUpInRequestedUnit = retailUnitName.Equals(requestedUnitNameEn, StringComparison.OrdinalIgnoreCase)
                ? markedUpInRetailUnit
                : OrderUnitConversion.ConvertPrice(
                    markedUpInRetailUnit,
                    retailUnitName,
                    requestedUnitNameEn);

            var presentedRetail = CustomerPriceCalculator.RoundUpToQuarter(
                ProductPricePresenter.Present(
                    markedUpInRequestedUnit,
                    ProductTypeCodes.Retail,
                    "AED",
                    usdToAedRate));

            return ToCartAmountAed(presentedRetail, usdToAedRate);
        }

        if (product.Unit is null)
        {
            throw new InvalidOperationException("Product unit is not set.");
        }

        var productUnitName = product.Unit.UnitNameEn;
        var markedUpInProductUnit = CustomerPriceCalculator.ApplyProductMarkup(
            product.USDPrice,
            ProductTypeCodes.WholesaleCommissionProductTypeId(product.CategoryId, product.ProductTypeId),
            product.CategoryId,
            settings,
            categoryCommissions);

        var markedUpInRequested = productUnitName.Equals(requestedUnitNameEn, StringComparison.OrdinalIgnoreCase)
            ? markedUpInProductUnit
            : OrderUnitConversion.ConvertPrice(
                markedUpInProductUnit,
                productUnitName,
                requestedUnitNameEn);

        var presented = CustomerPriceCalculator.RoundUpToQuarter(
            ProductPricePresenter.Present(
                markedUpInRequested,
                product.ProductTypeId,
                ResolveProductCurrency(product.ProductTypeId, product.Currency),
                usdToAedRate));

        return ToCartAmountAed(presented, usdToAedRate);
    }

    public static decimal ResolveCommissionPercent(
        Product product,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions) =>
        CustomerPriceCalculator.ResolveCommissionPercent(
            ProductTypeCodes.HasRetailPricing(product) ? ProductTypeCodes.Retail : product.ProductTypeId,
            product.CategoryId,
            settings,
            categoryCommissions);

    public static string ResolveProductCurrency(byte? productTypeId, string? productCurrency)
    {
        if (ProductTypeCodes.IsRetail(productTypeId))
        {
            return "AED";
        }

        return ProductCurrencyHelper.Normalize(productCurrency, productTypeId);
    }

    private static decimal ToCartAmountAed(CustomerFacingPrice presented, decimal usdToAedRate)
    {
        decimal amount;
        if (string.Equals(presented.Currency, "USD", StringComparison.OrdinalIgnoreCase))
        {
            amount = presented.PriceAed
                ?? decimal.Round(presented.PriceUsd * usdToAedRate, 2, MidpointRounding.AwayFromZero);
        }
        else
        {
            amount = presented.Price;
        }

        return CustomerPriceCalculator.RoundUpToQuarter(amount);
    }
}
