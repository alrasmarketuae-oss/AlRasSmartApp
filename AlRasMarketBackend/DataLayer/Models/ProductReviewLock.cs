namespace DataLayer.Models;

/// <summary>
/// Exclusive review lock: one admin/employee at a time until approve/reject (or stale timeout).
/// </summary>
public class ProductReviewLock
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ProductId { get; set; }
    public Guid AgentUserId { get; set; }
    public DateTime LockedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime LastHeartbeatUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ReleasedAtUtc { get; set; }

    public Product? Product { get; set; }
    public User? AgentUser { get; set; }
}
