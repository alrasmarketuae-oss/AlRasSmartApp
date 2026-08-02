namespace DataLayer.Models;

public class Product
{
    public Guid ProductId { get; set; } = Guid.NewGuid();
    public string? ProductCode { get; set; }
    /// <summary>
    /// Separate public code for the retail channel on hybrid (category + retail) listings.
    /// Null when retail pricing is not enabled.
    /// </summary>
    public string? RetailCode { get; set; }
    public string? NameEn { get; set; }
    /// <summary>
    /// App UI language when the seller authored the ad (<c>en</c> / <c>ar</c>).
    /// Used by My Listings / edit to show the original authored text first.
    /// </summary>
    public string CreatedLanguage { get; set; } = "en";
    public decimal USDPrice { get; set; }
    public string Currency { get; set; } = "AED";
    public byte? CategoryId { get; set; }
    public byte? ProductTypeId { get; set; }
    public Guid? OwnerId { get; set; }
    public long Quantity { get; set; }
    public string? DescriptionEn { get; set; }
    public int? MinimumOrderQuantity { get; set; }
    public byte? Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DisplayExpiresAtUtc { get; set; }
    public bool? IsApproved { get; set; }
    /// <summary>
    /// False while client is still uploading images/videos after create/update.
    /// Admin pending lists and realtime alerts wait until this is true.
    /// </summary>
    public bool IsReadyForAdminReview { get; set; } = true;
    /// <summary>
    /// JSON snapshot of the previous approved/live ad while a seller edit awaits admin decision.
    /// Live row = proposed changes; this column = old values (including image paths).
    /// </summary>
    public string? PendingProductChanges { get; set; }
    public byte? DiscountPercentage { get; set; }
    public short? DiscountDays { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public string? SupplierNotesEn { get; set; }
    /// <summary>Optional packing type id (1–255). Null = not set.</summary>
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    public byte? UnitId { get; set; }
    public short? OriginCountryId { get; set; }
    public short? DestinationCountryId { get; set; }
    public int? LoadingPortId { get; set; }
    public int? ArrivalPortId { get; set; }
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public string? ShippingDuration { get; set; }
    public string? OfferDuration { get; set; }
    public Guid? AddressId { get; set; }
    public int? MaximumOrderQuantity { get; set; }
    public bool? Negotiable { get; set; }
    public bool IsFeatured { get; set; }
    public long ViewsCount { get; set; }

    /// <summary>Optional retail channel price (AED) for category products that also sell retail.</summary>
    public decimal? RetailPrice { get; set; }
    public byte? RetailUnitId { get; set; }
    public long? RetailQuantity { get; set; }
    /// <summary>Retail-channel packing kg (hybrid category ads only).</summary>
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    /// <summary>Retail-channel specifications text (hybrid category ads only).</summary>
    public string? RetailDescriptionEn { get; set; }
    public byte? RequestTypeId { get; set; }
    /// <summary>Optional Incoterm for Booking ads only (FOB / CNF / CIF).</summary>
    public byte? BookingPriceTypeId { get; set; }

    public Category? Category { get; set; }
    public ProductType? ProductType { get; set; }
    public RequestType? RequestType { get; set; }
    public BookingPriceType? BookingPriceType { get; set; }
    public Unit? Unit { get; set; }
    public Unit? RetailUnit { get; set; }
    public User? Owner { get; set; }
    public Country? OriginCountry { get; set; }
    public Country? DestinationCountry { get; set; }
    public Port? LoadingPort { get; set; }
    public Port? ArrivalPort { get; set; }
    public Address? Address { get; set; }
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<ProductImage> ProductImages { get; set; } = new List<ProductImage>();
    public ICollection<ProductDocument> ProductDocuments { get; set; } = new List<ProductDocument>();
    public ICollection<ProductVideo> ProductVideos { get; set; } = new List<ProductVideo>();
}
