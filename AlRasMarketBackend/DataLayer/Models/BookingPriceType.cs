namespace DataLayer.Models;

/// <summary>Booking Incoterms: FOB / CNF / CIF.</summary>
public class BookingPriceType
{
    public byte Id { get; set; }
    public string NameEn { get; set; } = string.Empty;

    public ICollection<Product> Products { get; set; } = new List<Product>();
}
