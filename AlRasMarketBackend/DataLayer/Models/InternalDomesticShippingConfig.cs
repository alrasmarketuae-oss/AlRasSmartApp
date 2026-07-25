namespace DataLayer.Models;

/// Singleton (Id = 1) config for UAE domestic retail shipping weight rules.
public class InternalDomesticShippingConfig
{
    public byte Id { get; set; } = 1;

    /// <summary>AED charged per kg above the free weight threshold (0–255).</summary>
    public byte ExcessKgRateAed { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
