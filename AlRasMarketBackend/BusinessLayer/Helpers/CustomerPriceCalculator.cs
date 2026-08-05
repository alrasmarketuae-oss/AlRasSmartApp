using BusinessLayer.Dtos;

namespace BusinessLayer.Helpers;

public static class CustomerPriceCalculator
{
    /// <summary>
    /// Display markdown for Request ads: customer-facing listing price is 1% below
    /// the requester's entered target (e.g. 100 → 99). Stored <c>USDPrice</c> is unchanged.
    /// </summary>
    public const decimal RequestListingMarkdownPercent = 1m;

    public static decimal ApplyProductMarkup(
        decimal baseUsdPrice,
        byte? productTypeId,
        byte? categoryId,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions)
    {
        // Request ads: show target price minus 1% on public/customer responses.
        // Platform commission on supplier offers is applied separately at order time.
        if (productTypeId == ProductTypeCodes.Requests)
        {
            return ApplyPercentMarkdown(baseUsdPrice, RequestListingMarkdownPercent);
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
    /// Subtracts <paramref name="percent"/> from <paramref name="basePrice"/>
    /// (e.g. 1% of 100 → 99).
    /// </summary>
    public static decimal ApplyPercentMarkdown(decimal basePrice, decimal percent)
    {
        if (basePrice <= 0 || percent <= 0)
        {
            return basePrice;
        }

        if (percent >= 100m)
        {
            return 0m;
        }

        return decimal.Round(basePrice * (1 - percent / 100m), 2, MidpointRounding.AwayFromZero);
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
