using BusinessLayer.Dtos;

namespace BusinessLayer.Helpers;

public static class CustomerPriceCalculator
{
    public static decimal ApplyProductMarkup(
        decimal baseUsdPrice,
        byte? productTypeId,
        byte? categoryId,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions)
    {
        // Request ads show the customer's target price as entered.
        // Platform commission is applied later on supplier offers, not on the ad listing.
        if (productTypeId == ProductTypeCodes.Requests)
        {
            return baseUsdPrice;
        }

        var percent = ResolveCommissionPercentInternal(productTypeId, categoryId, settings, categoryCommissions);
        return ApplyPercentMarkup(baseUsdPrice, percent);
    }

    public static decimal ApplyProductMarkup(
        decimal baseUsdPrice,
        byte? productTypeId,
        CommissionSettingsSnapshot settings) =>
        ApplyProductMarkup(baseUsdPrice, productTypeId, categoryId: null, settings, categoryCommissions: EmptyCategoryCommissions);

    public static decimal ApplyShippingMarkup(decimal baseUsdPrice, CommissionSettingsSnapshot settings) =>
        ApplyPercentMarkup(baseUsdPrice, settings.ShippingCommissionPercent);

    public static decimal ApplyPercentMarkup(decimal basePrice, decimal percent)
    {
        if (basePrice <= 0 || percent <= 0)
        {
            return basePrice;
        }

        return decimal.Round(basePrice * (1 + percent / 100m), 2, MidpointRounding.AwayFromZero);
    }

    /// <summary>
    /// Inverse of <see cref="ApplyPercentMarkup"/> for historical order economics
    /// derived from locked customer (marked-up) amounts.
    /// </summary>
    public static decimal RemovePercentMarkup(decimal markedUpPrice, decimal percent)
    {
        if (markedUpPrice <= 0 || percent <= 0)
        {
            return markedUpPrice;
        }

        return decimal.Round(markedUpPrice / (1 + percent / 100m), 2, MidpointRounding.AwayFromZero);
    }

    public static decimal ResolveCommissionPercent(
        byte? productTypeId,
        byte? categoryId,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions) =>
        ResolveCommissionPercentInternal(productTypeId, categoryId, settings, categoryCommissions);

    private static decimal ResolveCommissionPercentInternal(
        byte? productTypeId,
        byte? categoryId,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions)
    {
        // Retail channel always uses retail commission — including hybrids that also have a category.
        // Category % must not be applied to retail price / retail cart lines.
        if (productTypeId == ProductTypeCodes.Retail)
        {
            return settings.RetailCommissionPercent;
        }

        if (categoryId.HasValue
            && categoryCommissions.TryGetValue(categoryId.Value, out var categoryPercent)
            && categoryPercent > 0)
        {
            return categoryPercent;
        }

        return productTypeId switch
        {
            ProductTypeCodes.Booking => settings.BookingCommissionPercent,
            ProductTypeCodes.Offers => settings.OffersCommissionPercent,
            ProductTypeCodes.Requests => settings.RequestsCommissionPercent,
            _ => 0m
        };
    }

    private static readonly IReadOnlyDictionary<byte, decimal> EmptyCategoryCommissions =
        new Dictionary<byte, decimal>();
}
