namespace DataLayer.Models;

/// <summary>Append-only admin action log (employee/super-admin mutations).</summary>
public class AdminAuditLog
{
    public Guid Id { get; set; }

    public Guid ActorUserId { get; set; }

    /// <summary>Snapshot of actor display name at write time.</summary>
    public string ActorName { get; set; } = string.Empty;

    /// <summary>Machine key, e.g. company.approve, product.reject, category.update.</summary>
    public string Action { get; set; } = string.Empty;

    /// <summary>Entity kind, e.g. Company, Product, Category, Settings.</summary>
    public string EntityType { get; set; } = string.Empty;

    public string? EntityId { get; set; }

    public string Summary { get; set; } = string.Empty;

    /// <summary>Optional JSON payload (old/new values, reasons, etc.).</summary>
    public string? DetailsJson { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public User? Actor { get; set; }
}
