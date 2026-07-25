using DataLayer.Models;

namespace BusinessLayer.Helpers;

public static class StripeCheckoutHelper
{
    public static (string StripeCurrency, string CurrencyCode, decimal Amount) Resolve(
        PendingOrder order,
        string? requestedCurrency,
        decimal? requestedAmount,
        decimal usdToAedRate)
    {
        var currency = ProductCurrencyHelper.Normalize(requestedCurrency ?? "AED");
        var amount = order.TotalPriceAed;

        amount = decimal.Round(amount, 2, MidpointRounding.AwayFromZero);
        if (amount <= 0)
        {
            throw new InvalidOperationException("Order total must be greater than zero.");
        }

        if (requestedAmount.HasValue && requestedAmount.Value > 0)
        {
            var expectedFromClient = decimal.Round(requestedAmount.Value, 2, MidpointRounding.AwayFromZero);
            if (Math.Abs(expectedFromClient - amount) > 0.01m)
            {
                throw new InvalidOperationException(
                    $"Checkout amount mismatch. Expected {amount:0.00} {currency}, received {expectedFromClient:0.00}.");
            }
        }

        return (ProductCurrencyHelper.ToStripeCurrency(currency), currency, amount);
    }
}
