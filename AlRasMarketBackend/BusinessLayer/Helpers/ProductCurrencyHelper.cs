namespace BusinessLayer.Helpers;

public static class ProductCurrencyHelper
{
    public static string Normalize(string? currency, byte? productTypeId = null)
    {
        if (ProductTypeCodes.IsRetail(productTypeId))
        {
            return "AED";
        }

        // Booking ads are always priced in USD.
        if (ProductTypeCodes.IsBooking(productTypeId))
        {
            return "USD";
        }

        if (!string.IsNullOrWhiteSpace(currency))
        {
            var normalized = currency.Trim().ToUpperInvariant();
            if (normalized is "USD" or "AED")
            {
                return normalized;
            }
        }

        return "AED";
    }

    public static string FormatPrice(decimal amount, string? currency)
    {
        var normalized = Normalize(currency);
        return normalized == "USD"
            ? $"${amount:N2}"
            : $"{amount:N2} AED";
    }

    public static string ToStripeCurrency(string currency) =>
        Normalize(currency).ToLowerInvariant();
}
