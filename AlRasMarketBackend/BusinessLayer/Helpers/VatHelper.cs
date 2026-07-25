namespace BusinessLayer.Helpers;

/// <summary>UAE VAT applied to retail cart checkout (5%).</summary>
public static class VatHelper
{
    public const decimal Rate = 0.05m;

    public static decimal CalculateVat(decimal subtotalAed) =>
        subtotalAed <= 0
            ? 0m
            : decimal.Round(subtotalAed * Rate, 2, MidpointRounding.AwayFromZero);

    public static decimal CalculateGrandTotal(decimal subtotalAed, decimal shippingAed) =>
        decimal.Round(subtotalAed + CalculateVat(subtotalAed) + Math.Max(0, shippingAed), 2, MidpointRounding.AwayFromZero);

    public static IReadOnlyList<decimal> AllocateVat(
        IReadOnlyList<decimal> lineSubtotals,
        decimal totalVat)
    {
        if (lineSubtotals.Count == 0 || totalVat <= 0)
        {
            return lineSubtotals.Select(_ => 0m).ToList();
        }

        var subtotal = lineSubtotals.Sum();
        if (subtotal <= 0)
        {
            return lineSubtotals.Select(_ => 0m).ToList();
        }

        var allocations = new List<decimal>(lineSubtotals.Count);
        var allocated = 0m;

        for (var i = 0; i < lineSubtotals.Count; i++)
        {
            if (i == lineSubtotals.Count - 1)
            {
                allocations.Add(decimal.Round(totalVat - allocated, 2, MidpointRounding.AwayFromZero));
                continue;
            }

            var share = decimal.Round(totalVat * lineSubtotals[i] / subtotal, 2, MidpointRounding.AwayFromZero);
            allocations.Add(share);
            allocated += share;
        }

        return allocations;
    }

    public static decimal AllocateLineVat(decimal lineSubtotal, decimal orderSubtotal, decimal orderVat)
    {
        if (lineSubtotal <= 0 || orderSubtotal <= 0 || orderVat <= 0)
        {
            return 0m;
        }

        return decimal.Round(orderVat * lineSubtotal / orderSubtotal, 2, MidpointRounding.AwayFromZero);
    }
}
