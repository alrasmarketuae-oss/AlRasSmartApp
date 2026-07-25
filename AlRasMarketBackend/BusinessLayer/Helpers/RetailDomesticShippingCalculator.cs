namespace BusinessLayer.Helpers;

/// <summary>Retail domestic shipping: emirate base + excess kg after free allowance.</summary>
public static class RetailDomesticShippingCalculator
{
    public const decimal FreeWeightKg = 10m;

    public static decimal CalculateTotalAed(decimal emirateBaseAed, decimal cartWeightKg, byte excessKgRateAed)
    {
        var baseFee = Math.Max(0m, emirateBaseAed);
        var excessKg = Math.Max(0m, cartWeightKg - FreeWeightKg);
        // Charge whole kg above free weight (ceil fractionals).
        var billableExcessKg = excessKg <= 0
            ? 0m
            : Math.Ceiling(excessKg);
        var excessFee = billableExcessKg * excessKgRateAed;
        return decimal.Round(baseFee + excessFee, 2, MidpointRounding.AwayFromZero);
    }

    public static decimal SumCartWeightKg(
        IEnumerable<(decimal Quantity, string? UnitNameEn, byte? PackagingKg)> lines)
    {
        decimal total = 0m;
        foreach (var line in lines)
        {
            total += LineWeightKg(line.Quantity, line.UnitNameEn, line.PackagingKg);
        }

        return decimal.Round(total, 3, MidpointRounding.AwayFromZero);
    }

    public static decimal LineWeightKg(decimal quantity, string? unitNameEn, byte? packagingKg)
    {
        if (quantity <= 0)
        {
            return 0m;
        }

        if (OrderUnitConversion.TryConvertToKilograms(quantity, unitNameEn ?? string.Empty, out var kg))
        {
            return kg;
        }

        // Non-weight units: packing weight (kg per unit) × quantity when configured.
        if (packagingKg is > 0)
        {
            return quantity * packagingKg.Value;
        }

        return 0m;
    }
}
