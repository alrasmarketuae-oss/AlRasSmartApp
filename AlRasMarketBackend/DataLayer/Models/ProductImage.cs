namespace DataLayer.Models;

public class ProductImage
{
    public long Id { get; set; }
    public Guid ProductId { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Product? Product { get; set; }
}
