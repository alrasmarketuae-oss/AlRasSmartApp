namespace DataLayer.Models;

/// <summary>Admin broadcast push notification log.</summary>
public class AdminPushNotification
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? TitleAr { get; set; }
    public string? BodyAr { get; set; }

    /// <summary>All | Suppliers | Clients | Shipping | SingleUser</summary>
    public string Audience { get; set; } = string.Empty;

    public Guid? TargetUserId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Guid? CreatedByAdminId { get; set; }
    public int SentCount { get; set; }
    public int FailedCount { get; set; }
    public string? Type { get; set; }

    public User? TargetUser { get; set; }
}
