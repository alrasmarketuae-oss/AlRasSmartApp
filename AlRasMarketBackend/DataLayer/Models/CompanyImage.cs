namespace DataLayer.Models;

public class CompanyImage
{
    public long Id { get; set; }
    public Guid UserId { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
