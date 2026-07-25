namespace DataLayer.Models;

public class ProductVideo
{
    public long Id { get; set; }
    public Guid ProductId { get; set; }
    public string VideoPath { get; set; } = string.Empty;
    public byte? VideoDurationSeconds { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Product? Product { get; set; }
}
