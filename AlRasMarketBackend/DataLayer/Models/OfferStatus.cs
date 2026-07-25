namespace DataLayer.Models;

public class OfferStatus
{
    public byte Id { get; set; }
    public string NameEn { get; set; } = string.Empty;

    public ICollection<Offer> Offers { get; set; } = new List<Offer>();
    public ICollection<OfferOnNegotiable> OffersOnNegotiable { get; set; } = new List<OfferOnNegotiable>();
}
