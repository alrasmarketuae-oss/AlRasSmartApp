namespace DataLayer.Models;

/// <summary>
/// Flattened public product row used by catalog queries (EF projection / ADO mapping).
/// </summary>
public sealed class ProductPublicRow
{
    public Guid ProductId { get; set; }
    public string? ProductCode { get; set; }
    public string? NameEn { get; set; }
    public decimal USDPrice { get; set; }
    public Guid? OwnerId { get; set; }
    public long Quantity { get; set; }
    public string? DescriptionEn { get; set; }
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
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    public string? RetailDescriptionEn { get; set; }
    public bool? Negotiable { get; set; }
    public bool IsFeatured { get; set; }
    public long ViewsCount { get; set; }
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool IsVideoMuted { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? CategoryName { get; set; }
    public string? CategoryNameAr { get; set; }
    public string? ProductTypeName { get; set; }
    public string? UnitName { get; set; }
    public string? OriginCountryName { get; set; }
    public string? OriginCountryNameAr { get; set; }
    public string? DestinationCountryName { get; set; }
    public string? DestinationCountryNameAr { get; set; }
    public string? LoadingPortName { get; set; }
    public string? LoadingPortNameAr { get; set; }
    public string? ArrivalPortName { get; set; }
    public string? ArrivalPortNameAr { get; set; }
    public byte? CategoryId { get; set; }
    public string Currency { get; set; } = "AED";
    public byte? ProductTypeId { get; set; }
    public Guid? AddressId { get; set; }
    public decimal? RetailPrice { get; set; }
    public byte? RetailUnitId { get; set; }
    public long? RetailQuantity { get; set; }
    public string? RetailUnitName { get; set; }
    public byte? RequestTypeId { get; set; }
    public string? RequestTypeName { get; set; }
    public byte? BookingPriceTypeId { get; set; }
    public string? BookingPriceTypeName { get; set; }
}
