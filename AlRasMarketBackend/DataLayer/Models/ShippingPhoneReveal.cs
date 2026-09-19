namespace DataLayer.Models;

/// <summary>Logged when a user taps "show number" on a shipping ad.</summary>
public class ShippingPhoneReveal
{
    public Guid Id { get; set; }

    public Guid ViewerUserId { get; set; }

    public Guid ShippingCompanyUserId { get; set; }

    public long PostId { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public User? ViewerUser { get; set; }

    public User? ShippingCompanyUser { get; set; }

    public InternationalShippingPost? Post { get; set; }
}
