namespace DataLayer.Models;

public class OrderVideo
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public string VideoPath { get; set; } = string.Empty;
    public Guid UploadedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Order? Order { get; set; }
}
