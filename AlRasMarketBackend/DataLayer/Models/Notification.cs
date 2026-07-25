namespace DataLayer.Models;

public class Notification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string? TitleAr { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public byte TypeId { get; set; }
    public Guid RouteId { get; set; }
    public string Body { get; set; } = string.Empty;
    public string? BodyAr { get; set; }
    public string ReferenceId { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
    public NotificationType? Type { get; set; }
    public NotificationRoute? Route { get; set; }
}
