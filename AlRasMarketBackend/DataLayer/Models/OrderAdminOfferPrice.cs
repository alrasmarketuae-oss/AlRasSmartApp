namespace DataLayer.Models;

/// <summary>
/// Admin-set price shown to the request-ad owner. The supplier still sees
/// <see cref="Order.UnitPrice"/> / <see cref="Order.TotalPrice"/>.
/// </summary>
public class OrderAdminOfferPrice
{
    public long OrderId { get; set; }
    public decimal AdminUnitPrice { get; set; }
    public decimal AdminTotalPrice { get; set; }
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    public Guid? UpdatedByAdminUserId { get; set; }

    public Order? Order { get; set; }
}
