namespace DataLayer.Models;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string FullName { get; set; } = string.Empty;
    public string? FcmToken { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? HashedPassword { get; set; }
    public byte RoleId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastSeenAtUtc { get; set; }
    public string? ImgPath { get; set; }
    public string LoginProviderName { get; set; } = "Local";
    public bool IsActive { get; set; } = true;
    public bool IsApproved { get; set; }
    public bool IsRejected { get; set; }
    public string? RejectionReason { get; set; }
    /// <summary>JSON snapshot of company fields awaiting admin approval.</summary>
    public string? PendingProfileChanges { get; set; }
    public bool IsVerified { get; set; }
    public string? PhoneNumber { get; set; }
    public string? LandNumber { get; set; }
    public string? LicencePath { get; set; }
    public string? LicenseNumber { get; set; }
    public string? CompanyName { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public bool? IsCustomer { get; set; }
    public string PreferredLanguage { get; set; } = "en";
    /// <summary>When false, skip FCM/email delivery but still store in-app notifications.</summary>
    public bool IsNotificationsOn { get; set; } = true;

    public Role? Role { get; set; }
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<Order> OrdersFrom { get; set; } = new List<Order>();
    public ICollection<Order> OrdersTo { get; set; } = new List<Order>();
    public ICollection<Address> Addresses { get; set; } = new List<Address>();
    public ICollection<CompanyImage> CompanyImages { get; set; } = new List<CompanyImage>();
    public ICollection<Cart> Carts { get; set; } = new List<Cart>();
}
