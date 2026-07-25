namespace DataLayer.Models;

public class OfferOnRequestDocument
{
    public long Id { get; set; }
    public long OfferId { get; set; }
    public string DocumentPath { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Offer? Offer { get; set; }
}
