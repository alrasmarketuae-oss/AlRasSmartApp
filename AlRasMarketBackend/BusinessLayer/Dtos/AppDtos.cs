using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Dtos;

public sealed class RegisterPersonInput
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? FcmToken { get; set; }
    public string? PreferredLanguage { get; set; }
}

public sealed class RegisterCompanyInput
{
    public string FullName { get; set; } = string.Empty;
    public string? CompanyName { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? LandNumber { get; set; }
    public string? LicenseNumber { get; set; }
    public string? FcmToken { get; set; }
    public string LicencePath { get; set; } = string.Empty;
    public List<string>? CompanyImagePaths { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public bool? IsCustomer { get; set; }
    public string? PreferredLanguage { get; set; }
}

public sealed class RegisterShippingCompanyInput
{
    public string CompanyName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? FcmToken { get; set; }
    public string? PreferredLanguage { get; set; }
}

public sealed class SendNotificationInput
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? TitleAr { get; set; }
    public string? BodyAr { get; set; }
    public string FromUserId { get; set; } = string.Empty;
    public string ToUserId { get; set; } = string.Empty;
    public byte TypeId { get; set; }
    public string Type { get; set; } = "notification";
    public string RouteId { get; set; } = string.Empty;
    public string ReferenceId { get; set; } = string.Empty;
}

public sealed class UploadCompanyImageInput
{
    public string UserId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public bool IsPrimary { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class UploadStagingAssetInput
{
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class UploadProductImageInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class UploadProductDocumentInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class UploadProductVideoInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class PresignProductImageInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class PresignProductDocumentInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public bool AllowAdminAccess { get; set; }
}

public sealed class PresignProductVideoInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool AllowAdminAccess { get; set; }
}

public sealed class ConfirmProductImageInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class ConfirmProductDocumentInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public bool AllowAdminAccess { get; set; }
}

public sealed class ConfirmProductVideoInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public byte? VideoDurationSeconds { get; set; }
    public bool AllowAdminAccess { get; set; }
}

public sealed class ConfirmProductAssetsBatchInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public IReadOnlyList<string> ImagePaths { get; set; } = Array.Empty<string>();
    public string? VideoPath { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool AllowAdminAccess { get; set; }
}

public sealed class PresignDraftImageInput
{
    public string OwnerId { get; set; } = string.Empty;
}

public sealed class PresignDraftVideoInput
{
    public string OwnerId { get; set; } = string.Empty;
    public string? FileName { get; set; }
    public string? ContentType { get; set; }
}

public sealed class DeleteDraftInput
{
    public string OwnerId { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
}

public sealed class UploadCompanyLicenceInput
{
    public string UserId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public class CreateProductInput
{
    public string OwnerId { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    /// <summary>App UI language when authoring (<c>en</c> / <c>ar</c>). Set on create only, it uses at profile account to retuen the ad to the user with the listed language.</summary>
    public string? CreatedLanguage { get; set; }
    public decimal USDPrice { get; set; }
    public string? Currency { get; set; }
    public long Quantity { get; set; }
    public string? DescriptionEn { get; set; }
    public string? ProductTypeName { get; set; }
    public string? ProductType { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public string? OriginCountryName { get; set; }
    public string? DestinationCountryName { get; set; }
    public string? LoadingPortName { get; set; }
    public string? ArrivalPortName { get; set; }
    public string? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string? Category { get; set; }
    public string? Categories { get; set; }
    public int? MinimumOrderQuantity { get; set; }
    public int? MaximumOrderQuantity { get; set; }
    public byte? Status { get; set; }
    public byte? DiscountPercentage { get; set; }
    public short? DiscountDays { get; set; }
    public string? ShippingDescriptionEn { get; set; }
    public string? SupplierNotesEn { get; set; }
    /// <summary>Optional packing type id (1–255).</summary>
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    public bool? Negotiable { get; set; }
    public IFormFile? ProductVideoFile { get; set; }
    public byte? VideoDurationSeconds { get; set; }
    public bool? IsVideoMuted { get; set; }
    public string? ShippingDuration { get; set; }
    public string? OfferDuration { get; set; }
    public string? AddressId { get; set; }
    public string? WebRootPath { get; set; }

    /// <summary>Optional retail channel for category products only.</summary>
    public decimal? RetailPrice { get; set; }
    public string? RetailUnitName { get; set; }
    public long? RetailQuantity { get; set; }
    /// <summary>When false on update, clears retail pricing columns.</summary>
    public bool? EnableRetailPricing { get; set; }
    /// <summary>Retail packing kg (1–255) for hybrid category ads.</summary>
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
    /// <summary>Retail specifications text for hybrid category ads.</summary>
    public string? RetailDescriptionEn { get; set; }

    /// <summary>Requests / Offers / Categories: Local or Rexport (name or id).</summary>
    public string? RequestTypeName { get; set; }
    public byte? RequestTypeId { get; set; }
    /// <summary>Booking Incoterm name: FOB / CNF / CIF.</summary>
    public string? BookingPriceTypeName { get; set; }
    public byte? BookingPriceTypeId { get; set; }

    /// <summary>
    /// Draft image paths already uploaded to R2 (product-images/drafts/…).
    /// Attached in the same create request — skips per-image confirm round-trips.
    /// </summary>
    public List<string>? DraftImagePaths { get; set; }

    /// <summary>Draft video path already on R2 under product-videos/drafts/…</summary>
    public string? DraftVideoPath { get; set; }

    /// <summary>Required when <see cref="DraftVideoPath"/> is set.</summary>
    public byte? DraftVideoDurationSeconds { get; set; }
}

public sealed class UpdateProductInput : CreateProductInput
{
    public string ProductId { get; set; } = string.Empty;
    public bool AllowAdminUpdate { get; set; }
}

public sealed class DeleteProductInput
{
    public string ProductId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string? WebRootPath { get; set; }
    /// <summary>حذف من لوحة الأدمن — يتجاوز التحقق من ملكية المورد.</summary>
    public bool AllowAdminDelete { get; set; }
}

public sealed class AdminUpdateProductRequest
{
    public string NameEn { get; set; } = string.Empty;
    public decimal USDPrice { get; set; }
    public long Quantity { get; set; }
    public string? DescriptionEn { get; set; }
    public byte? CategoryId { get; set; }
    public string ProductTypeName { get; set; } = string.Empty;
    public string UnitName { get; set; } = string.Empty;
    public string? Currency { get; set; }
    public string? SupplierNotesEn { get; set; }
    public bool? IsVideoMuted { get; set; }
}

public sealed class AdminRejectProductRequest
{
    public string? SupplierNotesEn { get; set; }
    public string? SupplierNotesAr { get; set; }
}

public sealed class AdminRejectCompanyRequest
{
    public string Reason { get; set; } = string.Empty;
}

/// <summary>
/// إيقاف الإعلان (IsActive=false) أو إعادة تنشيطه (IsActive=true) من قِبل صاحب الإعلان.
/// </summary>
public sealed class SetProductListingStatusInput
{
    public string ProductId { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public sealed class GetProductsByTypeInput
{
    public string ProductTypeName { get; set; } = string.Empty;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class GetProductsByCategoryInput
{
    public byte CategoryId { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class GetProductsInput
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public sealed class SearchProductsInput
{
    public string Query { get; set; } = string.Empty;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;

    /// <summary>Optional authenticated customer id (from JWT) for missed-search logging.</summary>
    public string? SearcherUserId { get; set; }
}

public sealed class ProductSearchSpellCheckResult
{
    public bool IsMisspelled { get; set; }
    public string? CorrectedName { get; set; }
}

/// <summary>
/// Vision result for image product search: prefer label name/brand when readable,
/// otherwise fall back to category noun guesses (singular/plural).
/// </summary>
public sealed class ImageProductVisionResult
{
    public string DetectedProductName { get; init; } = string.Empty;
    public string DetectedBrand { get; init; } = string.Empty;
    /// <summary>Catalog search tokens (detected name/brand, or category guesses).</summary>
    public IReadOnlyList<string> SearchNames { get; init; } = Array.Empty<string>();
    /// <summary>Category-style guesses always produced for fallback.</summary>
    public IReadOnlyList<string> FallbackNames { get; init; } = Array.Empty<string>();
    public bool HasDetectedProductName =>
        !string.IsNullOrWhiteSpace(DetectedProductName);
}

public sealed class AddAddressInput
{
    public string UserId { get; set; } = string.Empty;
    public Guid CityId { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
}

public sealed class AddressListItemDto
{
    public Guid AddressId { get; set; }
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public short? CountryId { get; set; }
    public string? CountryNameEn { get; set; }
    public string? CountryNameAr { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
}

public sealed class CreateOfferInput
{
    public string FromUserId { get; set; } = string.Empty;
    public string ToUserId { get; set; } = string.Empty;
    public string CountryName { get; set; } = string.Empty;
    public string PortName { get; set; } = string.Empty;
    public string DeliveryWindow { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public decimal RequestedQuantity { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public List<string>? ImagePaths { get; set; }
    public List<string>? DocumentPaths { get; set; }
}

public sealed class CreateOfferOnNegotiableInput
{
    public string FromUserId { get; set; } = string.Empty;
    public string ToUserId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public decimal OfferedPrice { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal BaseUnitPrice { get; set; }
    public decimal RequestedQuantity { get; set; }
}

public sealed class CreateInternationalShippingPostInput
{
    public string PublisherUserId { get; set; } = string.Empty;
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal PriceUsd { get; set; }
    public decimal ShippingCostUsd { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
    public int? MinDurationDays { get; set; }
    public int? MaxDurationDays { get; set; }
    public string? Details { get; set; }
}

public sealed class UpdateInternationalShippingPostInput
{
    public string UserId { get; set; } = string.Empty;
    public long PostId { get; set; }
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
    public int? MinDurationDays { get; set; }
    public int? MaxDurationDays { get; set; }
    public string? Details { get; set; }
    public string PhoneNumber { get; set; } = string.Empty;
}

public sealed class SearchInternationalShippingInput
{
    public string? FromCountryName { get; set; }
    public string? FromPortName { get; set; }
    public string? ToCountryName { get; set; }
    public string? ToPortName { get; set; }
}

public sealed class AddCartItemInput
{
    public string UserId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string UnitName { get; set; } = string.Empty;
}

public sealed class ReduceCartItemInput
{
    public string UserId { get; set; } = string.Empty;
    public long CartItemId { get; set; }
    public decimal Quantity { get; set; }
}

public sealed class RemoveCartItemInput
{
    public string UserId { get; set; } = string.Empty;
    public long CartItemId { get; set; }
}

public sealed class CreateCategoryInput
{
    public string UserId { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string ImgPath { get; set; } = string.Empty;
}

public sealed class UpdateCategoryInput
{
    public string UserId { get; set; } = string.Empty;
    public byte CategoryId { get; set; }
    public string NameEn { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public string? ImgPath { get; set; }
}

public sealed class SetCategoryHideInput
{
    public string UserId { get; set; } = string.Empty;
    public byte CategoryId { get; set; }
    public bool IsHide { get; set; }
}

public sealed class UploadCategoryImageInput
{
    public string UserId { get; set; } = string.Empty;
    public byte CategoryId { get; set; }
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class DeleteCategoryInput
{
    public string UserId { get; set; } = string.Empty;
    public byte CategoryId { get; set; }
    public string? WebRootPath { get; set; }
}

public sealed class CreateHomeBannerInput
{
    public string UserId { get; set; } = string.Empty;
    public IFormFile? File { get; set; }
    public string LinkUrl { get; set; } = string.Empty;
    public short DisplayOrder { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class DeleteHomeBannerInput
{
    public string UserId { get; set; } = string.Empty;
    public int BannerId { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class UpdateHomeBannerInput
{
    public string UserId { get; set; } = string.Empty;
    public int BannerId { get; set; }
    public string? LinkUrl { get; set; }
    public short? DisplayOrder { get; set; }
    public IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}
