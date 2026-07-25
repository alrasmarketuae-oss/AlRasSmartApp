namespace DataLayer.Models;

public class SystemSettings
{
    public byte Id { get; set; } = 1;
    public decimal RetailCommissionPercent { get; set; }
    public decimal BookingCommissionPercent { get; set; }
    public decimal RequestsCommissionPercent { get; set; }
    public decimal OffersCommissionPercent { get; set; }
    public decimal ShippingCommissionPercent { get; set; }
    public string AppName { get; set; } = "تطبيق الراس";
    public string? SupportEmail { get; set; }
    public string? PhoneNumber { get; set; }
    public string? LandlineNumber { get; set; }
    public string? Timezone { get; set; }
    public string? Address { get; set; }
    public decimal FeaturedAdPriceAed { get; set; }
    public int AdDisplayDurationDays { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
