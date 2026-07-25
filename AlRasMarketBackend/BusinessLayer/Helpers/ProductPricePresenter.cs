namespace BusinessLayer.Helpers;

public readonly struct CustomerFacingPrice
{
    public decimal Price { get; init; }
    public string Currency { get; init; }
    public decimal PriceUsd { get; init; }
    public decimal? PriceAed { get; init; }
}

public static class ProductPricePresenter
{
    public static CustomerFacingPrice Present(
        decimal markedUpPrice,
        byte? productTypeId,
        string? productCurrency,
        decimal usdToAedRate)
    {
        var currency = ResolveCurrency(productCurrency, productTypeId);
        if (string.Equals(currency, "USD", StringComparison.OrdinalIgnoreCase))
        {
            return new CustomerFacingPrice
            {
                Price = markedUpPrice,
                Currency = "USD",
                PriceUsd = markedUpPrice,
                PriceAed = decimal.Round(markedUpPrice * usdToAedRate, 2, MidpointRounding.AwayFromZero)
            };
        }

        // Retail/local products store unit price in AED (USDPrice column holds AED amount).
        var aed = decimal.Round(markedUpPrice, 2, MidpointRounding.AwayFromZero);
        return new CustomerFacingPrice
        {
            Price = aed,
            Currency = "AED",
            PriceUsd = usdToAedRate > 0
                ? decimal.Round(aed / usdToAedRate, 2, MidpointRounding.AwayFromZero)
                : 0m,
            PriceAed = aed
        };
    }

    private static string ResolveCurrency(string? productCurrency, byte? productTypeId)
    {
        if (ProductTypeCodes.IsRetail(productTypeId))
        {
            return "AED";
        }

        if (!string.IsNullOrWhiteSpace(productCurrency))
        {
            var normalized = productCurrency.Trim().ToUpperInvariant();
            if (normalized is "USD" or "AED")
            {
                return normalized;
            }
        }

        return ProductTypeCodes.IsBooking(productTypeId) ? "USD" : "AED";
    }
}
