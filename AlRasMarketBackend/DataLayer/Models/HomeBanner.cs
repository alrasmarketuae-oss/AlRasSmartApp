namespace DataLayer.Models;

public class HomeBanner
{
    public int Id { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public string LinkUrl { get; set; } = string.Empty;
    public short DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
