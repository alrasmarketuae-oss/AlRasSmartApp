namespace DataLayer.Models;

public class OfferOnRequestImage
{
    public long Id { get; set; }
    public long OfferId { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Offer? Offer { get; set; }
}
