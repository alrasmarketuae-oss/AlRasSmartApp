using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Helpers;

public static class CurrencyConversionHelper
{
    public static decimal GetUsdToAedRate(IConfiguration configuration)
    {
        var configured = configuration["Stripe:UsdToAedRate"];
        return decimal.TryParse(configured, out var rate) && rate > 0 ? rate : 3.6725m;
    }
}
