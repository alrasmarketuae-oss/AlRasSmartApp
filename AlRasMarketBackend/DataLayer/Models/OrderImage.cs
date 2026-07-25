namespace DataLayer.Models;

public class OrderImage
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public Guid UploadedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Order? Order { get; set; }
}
