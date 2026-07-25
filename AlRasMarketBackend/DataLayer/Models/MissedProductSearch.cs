namespace DataLayer.Models;

/// <summary>Logged when a customer searches a correctly spelled product name that is not in catalog.</summary>
public class MissedProductSearch
{
    public Guid Id { get; set; }

    public string QueryText { get; set; } = string.Empty;

    public Guid? UserId { get; set; }

    public string? UserDisplayName { get; set; }

    public string? UserEmail { get; set; }

    public string? UserPhone { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    /// <summary>Optional AI note (e.g. confirmed correctly spelled).</summary>
    public string? Notes { get; set; }

    public User? User { get; set; }
}
