namespace BusinessLayer.Helpers;

internal static class OrderUnitConversion
{
    public static decimal ConvertQuantity(decimal qty, string fromUnit, string toUnit)
    {
        if (fromUnit.Equals(toUnit, StringComparison.OrdinalIgnoreCase))
        {
            return qty;
        }

        if (TryGetWeightFactor(fromUnit, out var fromFactor) && TryGetWeightFactor(toUnit, out var toFactor))
        {
            var quantityInKg = qty * fromFactor;
            return quantityInKg / toFactor;
        }

        throw new InvalidOperationException($"Cannot convert quantity from '{fromUnit}' to '{toUnit}'.");
    }

    public static decimal ConvertPrice(decimal basePrice, string baseUnit, string targetUnit)
    {
        if (baseUnit.Equals(targetUnit, StringComparison.OrdinalIgnoreCase))
        {
            return basePrice;
        }

        if (TryGetWeightFactor(baseUnit, out var baseFactor) && TryGetWeightFactor(targetUnit, out var targetFactor))
        {
            return basePrice * (targetFactor / baseFactor);
        }

        throw new InvalidOperationException($"Cannot convert price from '{baseUnit}' to '{targetUnit}'.");
    }

    private static bool TryGetWeightFactor(string unitName, out decimal factorToKilogram)
    {
        switch (unitName.Trim().ToLowerInvariant())
        {
            case "gram":
            case "g":
            case "grams":
                factorToKilogram = 0.001m;
                return true;
            case "kilogram":
            case "kg":
            case "kgs":
            case "kilo":
            case "kilos":
                factorToKilogram = 1m;
                return true;
            case "ton":
            case "tons":
            case "tonne":
            case "tonnes":
                factorToKilogram = 1000m;
                return true;
            default:
                factorToKilogram = 0m;
                return false;
        }
    }

    public static bool TryConvertToKilograms(decimal quantity, string unitName, out decimal kilograms)
    {
        if (TryGetWeightFactor(unitName, out var factorToKilogram) && factorToKilogram > 0)
        {
            kilograms = quantity * factorToKilogram;
            return true;
        }

        kilograms = 0m;
        return false;
    }
}
