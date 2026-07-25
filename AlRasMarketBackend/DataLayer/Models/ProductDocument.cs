namespace DataLayer.Models;

public class ProductDocument
{
    public long Id { get; set; }
    public Guid ProductId { get; set; }
    public string DocumentPath { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Product? Product { get; set; }
}
