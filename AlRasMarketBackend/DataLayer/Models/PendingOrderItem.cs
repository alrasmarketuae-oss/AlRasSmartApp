namespace DataLayer.Models;

public class PendingOrderItem
{
    public long Id { get; set; }
    public Guid PendingOrderId { get; set; }
    public Guid ProductId { get; set; }
    public Guid ToUserId { get; set; }
    public byte UnitId { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPriceUsd { get; set; }
    public decimal UnitPriceAed { get; set; }
    public decimal LineTotalAed { get; set; }

    public PendingOrder? PendingOrder { get; set; }
    public Product? Product { get; set; }
    public User? ToUser { get; set; }
    public Unit? Unit { get; set; }
}
