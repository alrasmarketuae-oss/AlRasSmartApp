using BusinessLayer.Dtos;
using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class CartItemHelper
{
    public static decimal ResolveCustomerUnitPriceAed(
        Product product,
        string requestedUnitNameEn,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate) =>
        CustomerPricingHelper.ResolveCartUnitPriceAed(
            product,
            requestedUnitNameEn,
            settings,
            categoryCommissions,
            usdToAedRate);

    public static decimal ToTotalPriceAed(decimal quantity, decimal unitPriceAed) =>
        decimal.Round(quantity * unitPriceAed, 2, MidpointRounding.AwayFromZero);

    public static string? ResolvePrimaryImagePath(Product? product) =>
        product?.ProductImages
            .OrderBy(x => x.Id)
            .Select(x => x.ImagePath)
            .FirstOrDefault(path => !string.IsNullOrWhiteSpace(path));

    public static string? ResolvePrimaryVideoPath(Product? product)
    {
        if (product is null)
        {
            return null;
        }

        return ProductVideoPathsHelper
            .ResolveAll(product)
            .FirstOrDefault(path => !string.IsNullOrWhiteSpace(path));
    }
}
