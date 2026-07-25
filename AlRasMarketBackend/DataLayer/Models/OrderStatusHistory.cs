namespace DataLayer.Models;

/// <summary>Append-only bilingual status timeline for an order (manual + system labels).</summary>
public class OrderStatusHistory
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public byte StatusId { get; set; }
    public string StatusNameEn { get; set; } = string.Empty;
    public string StatusNameAr { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public Guid? CreatedByUserId { get; set; }

    public Order? Order { get; set; }
}
