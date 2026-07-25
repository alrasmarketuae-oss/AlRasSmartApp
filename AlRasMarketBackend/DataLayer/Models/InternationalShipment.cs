namespace DataLayer.Models;

public class InternationalShipment
{
    public long Id { get; set; }
    public string ShipmentCode { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public Guid ProviderUserId { get; set; }
    public byte StatusId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public Order? Order { get; set; }
    public User? ProviderUser { get; set; }
    public ShipmentStatus? Status { get; set; }
}
