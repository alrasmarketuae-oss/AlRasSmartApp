namespace BusinessLayer.Dtos;

public sealed class SystemSettingsDto
{
    public decimal RetailCommissionPercent { get; set; }
    public decimal BookingCommissionPercent { get; set; }
    public decimal RequestsCommissionPercent { get; set; }
    public decimal OffersCommissionPercent { get; set; }
    public decimal ShippingCommissionPercent { get; set; }
    public string AppName { get; set; } = string.Empty;
    public string? SupportEmail { get; set; }
    public string? PhoneNumber { get; set; }
    public string? LandlineNumber { get; set; }
    public string? Timezone { get; set; }
    public string? Address { get; set; }
    public decimal FeaturedAdPriceAed { get; set; }
    public int AdDisplayDurationDays { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public sealed class UpdateSystemSettingsInput
{
    public decimal RetailCommissionPercent { get; set; }
    public decimal BookingCommissionPercent { get; set; }
    public decimal RequestsCommissionPercent { get; set; }
    public decimal OffersCommissionPercent { get; set; }
    public decimal ShippingCommissionPercent { get; set; }
    public string AppName { get; set; } = string.Empty;
    public string? SupportEmail { get; set; }
    public string? PhoneNumber { get; set; }
    public string? LandlineNumber { get; set; }
    public string? Timezone { get; set; }
    public string? Address { get; set; }
    public decimal FeaturedAdPriceAed { get; set; }
    public int AdDisplayDurationDays { get; set; }
    public IReadOnlyList<UpdateCategoryCommissionInput>? CategoryCommissions { get; set; }
}

public sealed class CommissionSettingsSnapshot
{
    public decimal RetailCommissionPercent { get; init; }
    public decimal BookingCommissionPercent { get; init; }
    public decimal RequestsCommissionPercent { get; init; }
    public decimal OffersCommissionPercent { get; init; }
    public decimal ShippingCommissionPercent { get; init; }

    public static CommissionSettingsSnapshot Empty { get; } = new();
}

public sealed record CategoryCommissionDto(
    byte CategoryId,
    string NameEn,
    string NameAr,
    decimal CommissionPercent);

public sealed class UpdateCategoryCommissionInput
{
    public byte CategoryId { get; set; }
    public decimal CommissionPercent { get; set; }
}

public sealed class GeoCountrySnapshot
{
    public short Id { get; init; }
    public string CountryNameEn { get; init; } = string.Empty;
    public string? CountryNameAr { get; init; }
    public string Iso2Code { get; init; } = string.Empty;
}

public sealed class GeoPortSnapshot
{
    public int Id { get; init; }
    public short CountryId { get; init; }
    public string PortNameEn { get; init; } = string.Empty;
    public string? PortNameAr { get; init; }
    public string? UnLocode { get; init; }
}

public sealed class GeoCitySnapshot
{
    public Guid Id { get; init; }
    public string CityName { get; init; } = string.Empty;
    public short CountryId { get; init; }
}

public sealed class RoleSnapshot
{
    public byte Id { get; init; }
    public string RoleName { get; init; } = string.Empty;
}

public sealed class UnitSnapshot
{
    public byte Id { get; init; }
    public string UnitNameEn { get; init; } = string.Empty;
}

public sealed class ProductTypeSnapshot
{
    public byte Id { get; init; }
    public string TypeNameEn { get; init; } = string.Empty;
}

public sealed class CategorySnapshot
{
    public byte CategoryId { get; init; }
    public string NameEn { get; init; } = string.Empty;
    public string? NameAr { get; init; }
}

public sealed class RequestTypeSnapshot
{
    public byte Id { get; init; }
    public string NameEn { get; init; } = string.Empty;
}

public sealed class BookingPriceTypeSnapshot
{
    public byte Id { get; init; }
    public string NameEn { get; init; } = string.Empty;
}
