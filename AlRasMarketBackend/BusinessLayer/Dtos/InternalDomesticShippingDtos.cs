namespace BusinessLayer.Dtos;

public sealed class InternalDomesticShippingRateDto
{
    public byte Id { get; set; }
    public string EmirateNameEn { get; set; } = string.Empty;
    public string EmirateNameAr { get; set; } = string.Empty;
    public decimal PriceAed { get; set; }
}

public sealed class UpdateInternalDomesticShippingRateInput
{
    public byte Id { get; set; }
    public decimal PriceAed { get; set; }
}

public sealed class UpdateInternalDomesticShippingInput
{
    public List<UpdateInternalDomesticShippingRateInput> Rates { get; set; } = [];

    /// <summary>Optional. AED / kg after free 10 kg (0–255).</summary>
    public byte? ExcessKgRateAed { get; set; }
}

public sealed class UpdatePreferredLanguageInput
{
    public string Language { get; set; } = "en";
}
