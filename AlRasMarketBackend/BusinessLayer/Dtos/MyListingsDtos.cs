namespace BusinessLayer.Dtos;

public sealed class MyListingsResponse
{
    public string OwnerName { get; set; } = string.Empty;
    public string ProductCount { get; set; } = "0";
    public string ShippingPostCount { get; set; } = "0";
    /// <summary>شرح الحقول للمطور/التطبيق — ليس بيانات إعلان.</summary>
    public string ProductsShippingHelp { get; set; } = string.Empty;
    public string ShippingPostsHelp { get; set; } = string.Empty;
    public IReadOnlyList<MyProductListingDto> Products { get; set; } = Array.Empty<MyProductListingDto>();
    public IReadOnlyList<MyShippingPostListingDto> ShippingPosts { get; set; } = Array.Empty<MyShippingPostListingDto>();
}

/// <summary>
/// تفاصيل شحن المنتج: مسار التحميل/الوصول (إلزامي عند الإنشاء) + ملاحظات نصية اختيارية.
/// </summary>
public sealed class MyProductShippingInfoDto
{
    public string RouteFromCountry { get; set; } = string.Empty;
    public string RouteFromCountryAr { get; set; } = string.Empty;
    public string RouteFromPort { get; set; } = string.Empty;
    public string RouteFromPortAr { get; set; } = string.Empty;
    public string RouteToCountry { get; set; } = string.Empty;
    public string RouteToCountryAr { get; set; } = string.Empty;
    public string RouteToPort { get; set; } = string.Empty;
    public string RouteToPortAr { get; set; } = string.Empty;
    public string RouteSummary { get; set; } = string.Empty;
    public string ShippingDuration { get; set; } = string.Empty;
    public string AdditionalShippingNotes { get; set; } = string.Empty;
    public string? AdditionalShippingNotesEn { get; set; }
    public string? AdditionalShippingNotesAr { get; set; }
    public string HasRouteInformation { get; set; } = "No";
}

public sealed class MyProductListingDto
{
    public string ProductId { get; set; } = string.Empty;
    public string ProductCode { get; set; } = string.Empty;
    public string? RetailCode { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? NameAr { get; set; }
    /// <summary>Language the seller used when creating the ad (<c>en</c> / <c>ar</c>).</summary>
    public string CreatedLanguage { get; set; } = "en";
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryNameEn { get; set; }
    public string? CategoryNameAr { get; set; }
    public string CategoryId { get; set; } = string.Empty;
    public string CategoryImagePath { get; set; } = string.Empty;
    public byte? ProductTypeId { get; set; }
    public string ProductTypeName { get; set; } = string.Empty;
    public string? ProductTypeNameEn { get; set; }
    public string? ProductTypeNameAr { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? DescriptionEn { get; set; }
    public string? DescriptionAr { get; set; }
    public string Price { get; set; } = string.Empty;
    public string Currency { get; set; } = "USD";
    public string? PriceAed { get; set; }
    public string PriceUsd { get; set; } = string.Empty;
    public string Quantity { get; set; } = string.Empty;
    public string UnitName { get; set; } = string.Empty;
    public string? UnitNameEn { get; set; }
    public string? UnitNameAr { get; set; }
    public string MinimumOrderQuantity { get; set; } = string.Empty;
    public string MaximumOrderQuantity { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? StatusNameEn { get; set; }
    public string? StatusNameAr { get; set; }
    /// <summary>Normalized listing status (1 review, 2 active, 3 paused, 5 rejected).</summary>
    public byte ListingStatusCode { get; set; }
    public bool IsApproved { get; set; }
    public string ApprovalStatus { get; set; } = string.Empty;
    public string? ApprovalStatusEn { get; set; }
    public string? ApprovalStatusAr { get; set; }
    public string DiscountPercentage { get; set; } = string.Empty;
    public string DiscountDays { get; set; } = string.Empty;
    public string OfferDuration { get; set; } = string.Empty;
    /// <summary>Top-level copy of Shipping.ShippingDuration for easier mobile edit preload.</summary>
    public string ShippingDuration { get; set; } = string.Empty;
    public MyProductShippingInfoDto Shipping { get; set; } = new();
    public string SupplierNotes { get; set; } = string.Empty;
    public string? SupplierNotesEn { get; set; }
    public string? SupplierNotesAr { get; set; }
    public byte? Packaging { get; set; }
    public string PackagingDetails { get; set; } = string.Empty;
    public string Negotiable { get; set; } = string.Empty;
    public string IsFeatured { get; set; } = string.Empty;
    public string ViewsCount { get; set; } = string.Empty;
    public string VideoPath { get; set; } = string.Empty;
    public List<string> VideoPaths { get; set; } = [];
    public string VideoDurationSeconds { get; set; } = string.Empty;
    public IReadOnlyList<ProductVideoDto> Videos { get; set; } = [];
    public string? AddressId { get; set; }
    public string? Address { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
    public string UpdatedAt { get; set; } = string.Empty;
    /// <summary>Pending offers/orders awaiting seller action on this listing.</summary>
    public string PendingOffersCount { get; set; } = "0";
    public bool HasRetailPricing { get; set; }
    public string RetailPrice { get; set; } = string.Empty;
    public string RetailUnitName { get; set; } = string.Empty;
    public string? RetailUnitNameEn { get; set; }
    public string? RetailUnitNameAr { get; set; }
    public string RetailQuantity { get; set; } = string.Empty;
    public byte? RetailPackaging { get; set; }
    public string RetailPackagingDetails { get; set; } = string.Empty;
    public string RetailDescription { get; set; } = string.Empty;
    public string? RetailDescriptionEn { get; set; }
    public string? RetailDescriptionAr { get; set; }
    public string? RequestTypeId { get; set; }
    public string? RequestTypeName { get; set; }
    public string? RequestTypeNameEn { get; set; }
    public string? RequestTypeNameAr { get; set; }
    public string? BookingPriceTypeId { get; set; }
    public string? BookingPriceTypeName { get; set; }
    public IReadOnlyList<string> Images { get; set; } = Array.Empty<string>();
    public IReadOnlyList<string> Documents { get; set; } = Array.Empty<string>();
}

public sealed class ProductVideoDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
    public string VideoPath { get; set; } = string.Empty;
    public byte? DurationSeconds { get; set; }
    public bool IsMuted { get; set; }
}

public sealed class MyShippingPostListingDto
{
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public string PriceUsd { get; set; } = string.Empty;
    public string ShippingCostUsd { get; set; } = string.Empty;
    public string Container20ftPriceUsd { get; set; } = string.Empty;
    public string Container40ftPriceUsd { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string CreatedAt { get; set; } = string.Empty;
}
