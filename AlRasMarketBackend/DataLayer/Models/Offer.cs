namespace DataLayer.Models;

public class Offer
{
    public long Id { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public short CountryId { get; set; }
    public int PortId { get; set; }
    public string DeliveryWindow { get; set; } = string.Empty;
    public Guid ProductId { get; set; }
    public decimal RequestedQuantity { get; set; }
    public byte UnitId { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public byte StatusId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
    public Country? Country { get; set; }
    public Port? Port { get; set; }
    public Product? Product { get; set; }
    public Unit? Unit { get; set; }
    public OfferStatus? Status { get; set; }
    public ICollection<OfferOnRequestImage> Images { get; set; } = [];
    public ICollection<OfferOnRequestDocument> Documents { get; set; } = [];
}
