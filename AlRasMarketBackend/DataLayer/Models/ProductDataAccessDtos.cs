namespace DataLayer.Models;

public sealed class ProductMediaPathRow
{
    public Guid ProductId { get; set; }
    public string Path { get; set; } = string.Empty;
}

public sealed class ProductMediaSnapshot
{
    public List<string> ImagePaths { get; set; } = [];
    public List<string> DocumentPaths { get; set; } = [];
    public List<string> ExtraVideoPaths { get; set; } = [];
}

public sealed class ProductDeleteCascadeResult
{
    public Guid? OwnerId { get; set; }
    public List<long> ImageIds { get; set; } = [];
    public List<string> ImagePaths { get; set; } = [];
    public List<string> DocumentPaths { get; set; } = [];
    public List<string> VideoPaths { get; set; } = [];
}

public sealed class ProductOrderDeleteMediaResult
{
    public List<string> OrderImagePaths { get; set; } = [];
    public List<string> OrderVideoPaths { get; set; } = [];
}

public sealed class AddressDisplayRow
{
    public Guid Id { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public Guid CityId { get; set; }
}

public sealed class ProductNameTranslationRow
{
    public Guid ProductId { get; set; }
    public string? TextAr { get; set; }
    public string? TextEn { get; set; }
}

public sealed class ProductEditTranslationHint
{
    public Guid ProductId { get; set; }
    public string Field { get; set; } = string.Empty;
    public string? TextEn { get; set; }
    public string? TextAr { get; set; }
}

public sealed class OwnerListingRow
{
    public Guid ProductId { get; set; }
    public string? ProductCode { get; set; }
    public string? NameEn { get; set; }
    public string? CreatedLanguage { get; set; }
    public string? CategoryName { get; set; }
    public string? CategoryNameAr { get; set; }
    public string? CategoryImagePath { get; set; }
    public string? ProductTypeName { get; set; }
    public string? DescriptionEn { get; set; }
    public decimal USDPrice { get; set; }
    public byte? ProductTypeId { get; set; }
    public byte? CategoryId { get; set; }
    public string Currency { get; set; } = "AED";
    public long Quantity { get; set; }
    public string? UnitName { get; set; }
    public decimal? RetailPrice { get; set; }
    public string? RetailUnitName { get; set; }
    public byte? RetailUnitId { get; set; }
    public long? RetailQuantity { get; set; }
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    public string? RetailDescriptionEn { get; set; }
    public byte? RequestTypeId { get; set; }
    public string? RequestTypeName { get; set; }
    public byte? BookingPriceTypeId { get; set; }
    public string? BookingPriceTypeName { get; set; }
    public int? MinimumOrderQuantity { get; set; }
    public int? MaximumOrderQuantity { get; set; }
    public byte? Status { get; set; }
    public bool? IsApproved { get; set; }
    public byte? DiscountPercentage { get; set; }
    public short? DiscountDays { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public string? ShippingDuration { get; set; }
    public string? OfferDuration { get; set; }
    public string? SupplierNotesEn { get; set; }
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    public bool? Negotiable { get; set; }
    public bool IsFeatured { get; set; }
    public long ViewsCount { get; set; }
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool IsVideoMuted { get; set; }
    public string? OriginCountryName { get; set; }
    public string? OriginCountryNameAr { get; set; }
    public string? DestinationCountryName { get; set; }
    public string? DestinationCountryNameAr { get; set; }
    public string? LoadingPortName { get; set; }
    public string? LoadingPortNameAr { get; set; }
    public string? ArrivalPortName { get; set; }
    public string? ArrivalPortNameAr { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public Guid? AddressId { get; set; }
    public List<string> Images { get; set; } = [];
    public List<string> Documents { get; set; } = [];
}

public sealed class ProductSearchNameIndex
{
    public List<string> Names { get; set; } = [];
    public List<string> ProductCodes { get; set; } = [];
}

public sealed class MissedProductSearchInsert
{
    public Guid? UserId { get; set; }
    public string Query { get; set; } = string.Empty;
    public string? UserDisplayName { get; set; }
    public string? UserEmail { get; set; }
    public string? UserPhone { get; set; }
    public string? Notes { get; set; }
}
