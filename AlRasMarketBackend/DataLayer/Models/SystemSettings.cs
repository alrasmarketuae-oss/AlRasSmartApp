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

    /// <summary>Latest Android versionName (e.g. 1.0.46). Soft prompt when installed is older.</summary>
    public string? AndroidLatestVersion { get; set; }
    /// <summary>Latest iOS CFBundleShortVersionString (e.g. 1.0.46).</summary>
    public string? IosLatestVersion { get; set; }
    /// <summary>Minimum Android version; below this is a blocking force-update.</summary>
    public string? AndroidMinVersion { get; set; }
    /// <summary>Minimum iOS version; below this is a blocking force-update.</summary>
    public string? IosMinVersion { get; set; }
    public string? AndroidStoreUrl { get; set; }
    public string? IosStoreUrl { get; set; }
    /// <summary>Optional Arabic/English message shown in the update dialog.</summary>
    public string? AppUpdateMessageAr { get; set; }
    public string? AppUpdateMessageEn { get; set; }

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
