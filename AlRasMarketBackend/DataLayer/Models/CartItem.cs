namespace DataLayer.Models;

public class CartItem
{
    public long Id { get; set; }
    public Guid CartId { get; set; }
    public Guid ProductId { get; set; }
    public decimal Quantity { get; set; }
    public byte UnitId { get; set; }
    public decimal UnitPriceAed { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Cart? Cart { get; set; }
    public Product? Product { get; set; }
    public Unit? Unit { get; set; }
}
