namespace DataLayer.Models;

public class InternalDomesticShippingRate
{
    public byte Id { get; set; }
    public string EmirateNameEn { get; set; } = string.Empty;
    public string EmirateNameAr { get; set; } = string.Empty;
    public decimal PriceAed { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
