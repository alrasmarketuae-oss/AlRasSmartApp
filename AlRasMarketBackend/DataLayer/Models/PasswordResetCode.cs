namespace DataLayer.Models;

public class PasswordResetCode
{
    public long Id { get; set; }
    public Guid UserId { get; set; }
    public string ProviderName { get; set; } = string.Empty;
    public string Destination { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
