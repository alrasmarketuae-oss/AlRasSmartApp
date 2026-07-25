namespace DataLayer.Models;

public class OfferOnNegotiable
{
    public long Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public decimal OfferedPrice { get; set; }
    public byte UnitId { get; set; }
    public decimal BaseUnitPrice { get; set; }
    public decimal RequestedQuantity { get; set; }
    public byte StatusId { get; set; } = 1;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Product? Product { get; set; }
    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
    public Unit? Unit { get; set; }
    public OfferStatus? Status { get; set; }
}
