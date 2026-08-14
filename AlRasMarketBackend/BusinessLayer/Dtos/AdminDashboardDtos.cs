namespace BusinessLayer.Dtos;

public sealed class AdminDashboardResponse
{
    public AdminStatsDto Stats { get; set; } = new();
    public IReadOnlyList<MonthlyProfitPointDto> MonthlyProfits { get; set; } = [];
    public IReadOnlyList<AdminRecentOrderDto> RecentOrders { get; set; } = [];
    public IReadOnlyList<AdminRecentUserDto> RecentUsers { get; set; } = [];
    public IReadOnlyList<AdminActivityItemDto> RecentActivity { get; set; } = [];
    public AdminSummaryCountsDto Summary { get; set; } = new();
    public AdminDashboardInsightsDto Insights { get; set; } = new();
    public AdminSalesSummaryDto SalesSummary { get; set; } = new();
}

public sealed class AdminDashboardInsightsDto
{
    public decimal AvgOrderValue { get; set; }
    public string AvgOrderValueFormatted { get; set; } = string.Empty;
    public decimal ConversionRate { get; set; }
    public int PendingOrders { get; set; }
    public decimal GrowthRate { get; set; }
}

public sealed class AdminSalesSummaryDto
{
    public decimal TotalSales { get; set; }
    public string TotalSalesFormatted { get; set; } = string.Empty;
    public decimal ThisMonth { get; set; }
    public string ThisMonthFormatted { get; set; } = string.Empty;
    public decimal GrowthPercent { get; set; }
}

public sealed class AdminStatsDto
{
    public AdminStatMetricDto TotalUsers { get; set; } = new();
    public AdminStatMetricDto ActiveSuppliers { get; set; } = new();
    public AdminStatMetricDto MonthlyOrders { get; set; } = new();
    public AdminSalesMetricDto TotalSales { get; set; } = new();
}

public sealed class AdminStatMetricDto
{
    public int Value { get; set; }
    public decimal ChangePercent { get; set; }
    public IReadOnlyList<decimal> Sparkline { get; set; } = [];
}

public sealed class AdminSalesMetricDto
{
    public decimal Value { get; set; }
    public string Formatted { get; set; } = string.Empty;
    public decimal ChangePercent { get; set; }
    public IReadOnlyList<decimal> Sparkline { get; set; } = [];
}

public sealed class MonthlyProfitPointDto
{
    public string Month { get; set; } = string.Empty;
    public string MonthAr { get; set; } = string.Empty;
    public decimal Value { get; set; }
}

public sealed class AdminRecentOrderDto
{
    public long Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public byte StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public decimal TotalPrice { get; set; }
    public string AmountFormatted { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public sealed class AdminRecentUserDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? FullNameEn { get; set; }
    public string? FullNameAr { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string RoleLabelAr { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string? ImgPath { get; set; }
}

public sealed class AdminActivityItemDto
{
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string TimeAgo { get; set; } = string.Empty;
}

public sealed class AdminSummaryCountsDto
{
    public int PendingCompanies { get; set; }
    public int TotalProducts { get; set; }
    public int TotalOffers { get; set; }
    public int UnreadNotifications { get; set; }
}

public sealed class AdminPagedResult<T>
{
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages { get; set; }
    public IReadOnlyList<T> Items { get; set; } = [];
}

public sealed class AdminUserListItemDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? FullNameEn { get; set; }
    public string? FullNameAr { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public byte RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string RoleLabelAr { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool IsVerified { get; set; }
    public bool IsRejected { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ImgPath { get; set; }
    public string? CompanyName { get; set; }
    public string? CompanyNameEn { get; set; }
    public string? CompanyNameAr { get; set; }
    public string TypeLabelAr { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public bool IsCustomer { get; set; }
    public bool HasPendingProfileChanges { get; set; }
    public bool CanApprove { get; set; }
    public int OrdersCount { get; set; }
}

public sealed class AdminUserCompanyImageDto
{
    public long Id { get; set; }
    public string ImagePath { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
}

public sealed class AdminUserDetailDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? FullNameEn { get; set; }
    public string? FullNameAr { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? LandNumber { get; set; }
    public byte RoleId { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string RoleLabelAr { get; set; } = string.Empty;
    public string TypeLabelAr { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool IsVerified { get; set; }
    public bool IsRejected { get; set; }
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? ImgPath { get; set; }
    public string? CompanyName { get; set; }
    public string? CompanyNameEn { get; set; }
    public string? CompanyNameAr { get; set; }
    public string? LicenseNumber { get; set; }
    public string? LicencePath { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public PendingCompanyProfileChangeDto? PendingProfileChanges { get; set; }
    public IReadOnlyList<AdminUserCompanyImageDto> CompanyImages { get; set; } = [];
    public int OrdersCount { get; set; }
    public bool IsCustomer { get; set; }
    public bool CanApprove { get; set; }
    public bool CanDeactivate { get; set; }
    public bool CanDelete { get; set; }
}

public sealed class PendingCompanyProfileChangeDto
{
    public string? CompanyName { get; set; }
    public string? CompanyNameEn { get; set; }
    public string? CompanyNameAr { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? Website { get; set; }
    public string? LandNumber { get; set; }
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
}

public sealed class AdminOrderStatsDto
{
    public int TotalOrders { get; set; }
    public decimal TotalOrdersChangePercent { get; set; }
    public int OrderedCount { get; set; }
    public int ShippingCount { get; set; }
    public int DeliveredCount { get; set; }
}

public sealed class AdminOrderListItemDto
{
    public long Id { get; set; }
    public Guid ProductId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerNameEn { get; set; }
    public string? CustomerNameAr { get; set; }
    public string CustomerEmail { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
    public Guid? CustomerUserId { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public string? SupplierNameEn { get; set; }
    public string? SupplierNameAr { get; set; }
    public string SupplierEmail { get; set; } = string.Empty;
    public string? SupplierPhone { get; set; }
    public Guid? SupplierUserId { get; set; }
    public string? SupplierAvatarPath { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductNameEn { get; set; }
    public string? ProductNameAr { get; set; }
    public string? ProductDescription { get; set; }
    public string? ProductDescriptionEn { get; set; }
    public string? ProductDescriptionAr { get; set; }
    public string ProductTypeName { get; set; } = string.Empty;
    public string? ProductTypeNameEn { get; set; }
    public string? ProductTypeNameAr { get; set; }
    /// <summary>Product Local / Rexport price type id.</summary>
    public byte? RequestTypeId { get; set; }
    /// <summary>Product Local / Rexport price type name.</summary>
    public string? RequestTypeName { get; set; }
    public bool? Negotiable { get; set; }
    public string? OfferDuration { get; set; }
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    /// <summary>True for cart/hybrid retail channel; false for wholesale/category Purchase Order.</summary>
    public bool IsRetailPurchase { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? CategoryNameEn { get; set; }
    public string? CategoryNameAr { get; set; }
    public byte? CategoryId { get; set; }
    public string? PrimaryImagePath { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public string? UnitNameEn { get; set; }
    public string? UnitNameAr { get; set; }
    public byte StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public string AmountFormatted { get; set; } = string.Empty;
    public string Currency { get; set; } = "AED";
    public decimal CommissionPercent { get; set; }
    public decimal SupplierUnitPrice { get; set; }
    public decimal SupplierTotalPrice { get; set; }
    public decimal CustomerUnitPrice { get; set; }
    public decimal CustomerTotalPrice { get; set; }
    public decimal AppProfitAmount { get; set; }
    public decimal ChargedUnitPrice { get; set; }
    public decimal ChargedTotalPrice { get; set; }
    public string SupplierUnitPriceFormatted { get; set; } = string.Empty;
    public string SupplierTotalPriceFormatted { get; set; } = string.Empty;
    public string CustomerUnitPriceFormatted { get; set; } = string.Empty;
    public string CustomerTotalPriceFormatted { get; set; } = string.Empty;
    public string AppProfitFormatted { get; set; } = string.Empty;
    /// <summary>Request-ad listing unit price the supplier saw (1% markdown of stored USDPrice).</summary>
    public decimal ListingUnitPrice { get; set; }
    public string ListingUnitPriceFormatted { get; set; } = string.Empty;
    /// <summary>True when the supplier unit price is below the request listing unit price.</summary>
    public bool IsBelowListingPrice { get; set; }
    public bool HasAdminAdvertiserPrice { get; set; }
    public decimal? AdminAdvertiserUnitPrice { get; set; }
    public decimal? AdminAdvertiserTotalPrice { get; set; }
    public string AdminAdvertiserUnitPriceFormatted { get; set; } = string.Empty;
    public string AdminAdvertiserTotalPriceFormatted { get; set; } = string.Empty;
    /// <summary>Order/offer line quantity (what the buyer ordered or supplier offered).</summary>
    public decimal Quantity { get; set; }
    /// <summary>
    /// Requests: quantity required on the request ad (Product.Quantity).
    /// Other types: same as <see cref="Quantity"/> (order line).
    /// </summary>
    public decimal RequestedQuantity { get; set; }
    /// <summary>Current product catalog quantity (stock for retail/offers; required qty for requests).</summary>
    public long? ProductAvailableQuantity { get; set; }
    /// <summary>Views count of the related product/ad.</summary>
    public long ProductViewsCount { get; set; }
    public byte PaymentMethod { get; set; }
    public string PaymentMethodName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsApproved { get; set; }
    public bool IsAdminApproved { get; set; }
    public string? Notes { get; set; }
    public List<string> VideoPaths { get; set; } = [];
    /// <summary>Order-attached videos with ids (for admin delete/trim). Empty when only product videos exist.</summary>
    public List<AdminOrderVideoDto> Videos { get; set; } = [];
    public List<AdminOrderImageDto> Images { get; set; } = [];
    public List<string> DocumentPaths { get; set; } = [];
    public List<string> ProductImagePaths { get; set; } = [];
    public List<string> ProductDocumentPaths { get; set; } = [];
    public int? PortId { get; set; }
    public string? PortName { get; set; }
    /// <summary>Country of the order-selected booking port (Port.Country).</summary>
    public string? PortCountryName { get; set; }
    public string OriginCountryName { get; set; } = string.Empty;
    public string DestinationCountryName { get; set; } = string.Empty;
    public string LoadingPortName { get; set; } = string.Empty;
    public string ArrivalPortName { get; set; } = string.Empty;
    public string ShippingDescription { get; set; } = string.Empty;
    public string ShippingRouteSummary { get; set; } = string.Empty;
    public string ShippingDuration { get; set; } = string.Empty;
    public string? ProductAddress { get; set; }
    public decimal VatAed { get; set; }
    public decimal ShippingCostAed { get; set; }
    public bool IsSelfPickup { get; set; }
    public string? DeliveryAddressLine { get; set; }
    public string? DeliveryCityName { get; set; }
    public decimal ChargedShippingAed { get; set; }
    public decimal ChargedGrandTotalAed { get; set; }
    public string ChargedGrandTotalFormatted { get; set; } = string.Empty;
    /// <summary>Stripe Checkout Session ID (cs_…).</summary>
    public string? StripeSessionId { get; set; }
    /// <summary>Stripe PaymentIntent ID (pi_…) from the pending checkout row.</summary>
    public string? PaymentIntentId { get; set; }
    /// <summary>Checkout group id linking split retail orders from one payment.</summary>
    public Guid? OrderGroupId { get; set; }
    /// <summary>Pending checkout row id that created this order after Stripe payment.</summary>
    public Guid? PendingOrderId { get; set; }
    public string? StripeRefundId { get; set; }
    public DateTime? RefundedAtUtc { get; set; }
    public bool IsRefunded { get; set; }
    public string? ReturnReason { get; set; }
    public List<string> ReturnMediaPaths { get; set; } = [];
    public DateTime? ReturnRequestedAtUtc { get; set; }
    public string? ReturnAdminResponse { get; set; }
    public DateTime? ReturnRespondedAtUtc { get; set; }
    /// <summary>True when seller-approved or unfinished retail — dashboard blink cue.</summary>
    public bool NeedsAttention { get; set; }
    /// <summary>True when admin can mark the order as Received (final).</summary>
    public bool CanMarkReceived { get; set; }
    public List<AdminOrderStatusHistoryDto> StatusHistory { get; set; } = [];
}

public sealed class ApproveRequestOfferRequest
{
    /// <summary>Unit price shown to the request-ad owner. Supplier order amounts stay unchanged.</summary>
    public decimal? AdminUnitPrice { get; set; }
    public decimal? AdminTotalPrice { get; set; }
}

public sealed class AdminOrderStatusHistoryDto
{
    public long Id { get; set; }
    public byte StatusId { get; set; }
    public string StatusNameEn { get; set; } = string.Empty;
    public string StatusNameAr { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
}

public sealed class AdminOrderImageDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
}

public sealed class AdminOrderVideoDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
}

public sealed class AdminNotificationListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string FromUserName { get; set; } = string.Empty;
    public string ToUserName { get; set; } = string.Empty;
}

public sealed class AdminPushNotificationListItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public Guid? TargetUserId { get; set; }
    public string? TargetUserName { get; set; }
    public string CreatedAt { get; set; } = string.Empty;
    public int SentCount { get; set; }
    public int FailedCount { get; set; }
    public string? Type { get; set; }
}

public sealed class AdminSendPushNotificationRequest
{
    public string Audience { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string? TitleAr { get; set; }
    public string? BodyAr { get; set; }
    public string? Type { get; set; }
    public string? TargetUserId { get; set; }
}

public sealed class AdminProductStatsDto
{
    public int TotalAds { get; set; }
    public decimal TotalAdsChangePercent { get; set; }
    public int OffersCount { get; set; }
    public int RetailCount { get; set; }
    public int BookingCount { get; set; }
}

public class AdminProductListItemDto
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal PriceUsd { get; set; }
    public string Currency { get; set; } = "AED";
    public string PriceFormatted { get; set; } = string.Empty;
    public long Quantity { get; set; }
    public bool? Negotiable { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public byte? CategoryId { get; set; }
    public byte? ProductTypeId { get; set; }
    public string ProductTypeName { get; set; } = string.Empty;
    public string UnitName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string? OwnerCompanyName { get; set; }
    public string OwnerEmail { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsEditResubmit { get; set; }
    public string? PrimaryImagePath { get; set; }
    public IReadOnlyList<string> ImagePaths { get; set; } = [];
    public string OriginCountryName { get; set; } = string.Empty;
    public string DestinationCountryName { get; set; } = string.Empty;
    public string LoadingPortName { get; set; } = string.Empty;
    public string ArrivalPortName { get; set; } = string.Empty;
    public string ShippingDescription { get; set; } = string.Empty;
    public string ShippingRouteSummary { get; set; } = string.Empty;
    public string ShippingDuration { get; set; } = string.Empty;
    public string OfferDuration { get; set; } = string.Empty;
    public string? ProductAddress { get; set; }
    /// <summary>Supplier offers on request ads awaiting admin review.</summary>
    public int PendingOffersCount { get; set; }
    /// <summary>
    /// Supplier offers on this request ad that are still in progress (not yet
    /// delivered/received, cancelled, or returned). Drives the request-row blink.
    /// </summary>
    public int ActiveOffersCount { get; set; }
    public bool HasRetailPricing { get; set; }
    public decimal? RetailPrice { get; set; }
    public string? RetailUnitName { get; set; }
    public long? RetailQuantity { get; set; }
    public byte? RequestTypeId { get; set; }
    public string? RequestTypeName { get; set; }
    public byte? BookingPriceTypeId { get; set; }
    public string? BookingPriceTypeName { get; set; }
    public byte? Packaging { get; set; }
    public string? PackagingDetails { get; set; }
    /// <summary>Optional dual retail details (hybrid category ads only).</summary>
    public string? RetailDescription { get; set; }
    /// <summary>Retail-channel packing type id 1–255.</summary>
    public byte? RetailPackaging { get; set; }
    public string? RetailPackagingDetails { get; set; }
}

public sealed class AdminProductImageDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
}

public sealed class AdminProductDocumentDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
}

public sealed class AdminProductVideoDto
{
    public long Id { get; set; }
    public string Path { get; set; } = string.Empty;
    public bool IsMuted { get; set; }
    public byte? DurationSeconds { get; set; }
}

public sealed class AdminProductDetailDto : AdminProductListItemDto
{
    public byte? UnitId { get; set; }
    public byte? StatusId { get; set; }
    public long ViewsCount { get; set; }
    public string? OwnerPhone { get; set; }
    public string? OwnerCity { get; set; }
    public string? SupplierNotesEn { get; set; }
    public string? VideoPath { get; set; }
    public IReadOnlyList<string> VideoPaths { get; set; } = [];
    public byte? VideoDurationSeconds { get; set; }
    public IReadOnlyList<AdminProductVideoDto> Videos { get; set; } = [];
    public IReadOnlyList<AdminProductImageDto> Images { get; set; } = [];
    public IReadOnlyList<AdminProductDocumentDto> Documents { get; set; } = [];
    /// <summary>Previous vs proposed values while a seller edit awaits review.</summary>
    public AdminPendingProductEditDto? PendingEdit { get; set; }
}

public sealed class AdminPendingProductEditDto
{
    public string? PreviousName { get; set; }
    public string? ProposedName { get; set; }
    public string? PreviousDescription { get; set; }
    public string? ProposedDescription { get; set; }
    public decimal PreviousPrice { get; set; }
    public decimal ProposedPrice { get; set; }
    public string? PreviousCurrency { get; set; }
    public string? ProposedCurrency { get; set; }
    public long PreviousQuantity { get; set; }
    public long ProposedQuantity { get; set; }
    public string? PreviousVideoPath { get; set; }
    public string? ProposedVideoPath { get; set; }
    public IReadOnlyList<string> PreviousImagePaths { get; set; } = [];
    public IReadOnlyList<string> ProposedImagePaths { get; set; } = [];
    public IReadOnlyList<string> PreviousDocumentPaths { get; set; } = [];
    public IReadOnlyList<string> ProposedDocumentPaths { get; set; } = [];
}

public sealed class AdminProductLookupsDto
{
    public IReadOnlyList<AdminLookupItemDto> ProductTypes { get; set; } = [];
    public IReadOnlyList<AdminLookupItemDto> Units { get; set; } = [];
}

public sealed class AdminLookupItemDto
{
    public byte Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public sealed class AdminShippingProviderListItemDto
{
    public Guid Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? ImgPath { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? CityName { get; set; }
    public bool IsActive { get; set; }
    public int TotalShipments { get; set; }
    public int PostCount { get; set; }
    public DateTime RegistrationDate { get; set; }
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public string RouteSummary { get; set; } = string.Empty;
}

public sealed class AdminShippingProviderDetailDto
{
    public Guid Id { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? ImgPath { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? LandNumber { get; set; }
    public string? CommercialRegister { get; set; }
    public string? TaxNumber { get; set; }
    public string? CityName { get; set; }
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
    public string Container20ftPriceFormatted { get; set; } = string.Empty;
    public string Container40ftPriceFormatted { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public bool RegistrationLinkSent { get; set; }
    public DateTime RegistrationDate { get; set; }
    public AdminShippingStatsDto Stats { get; set; } = new();
    public IReadOnlyList<AdminShipmentLogItemDto> Shipments { get; set; } = [];
    public string FullName { get; set; } = string.Empty;
    public short FromCountryId { get; set; }
    public int FromPortId { get; set; }
    public short ToCountryId { get; set; }
    public int ToPortId { get; set; }
    public string FromCountryName { get; set; } = string.Empty;
    public string? FromCountryNameAr { get; set; }
    public string FromPortName { get; set; } = string.Empty;
    public string? FromPortUnLocode { get; set; }
    public string ToCountryName { get; set; } = string.Empty;
    public string? ToCountryNameAr { get; set; }
    public string ToPortName { get; set; } = string.Empty;
    public string? ToPortUnLocode { get; set; }
    public string RouteSummary { get; set; } = string.Empty;
    public string RouteSummaryAr { get; set; } = string.Empty;
    public long LatestPostId { get; set; }
    public byte PostStatus { get; set; }
    public string PostStatusLabelAr { get; set; } = string.Empty;
    public bool IsPostApproved { get; set; }
    public bool CanApprovePost { get; set; }
}

public sealed class AdminShippingStatsDto
{
    public int TotalShipments { get; set; }
    public int Completed { get; set; }
    public int InDelivery { get; set; }
    public int Late { get; set; }
    public decimal SuccessRate { get; set; }
}

public sealed class AdminShipmentLogItemDto
{
    public long Id { get; set; }
    public string ShipmentCode { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public byte StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string StatusLabelAr { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public sealed class AdminCreateShippingProviderInput
{
    public string CompanyName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? FullNameEn { get; set; }
    public string? FullNameAr { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
}

public sealed class AdminUpdateShippingProviderInput
{
    public string CompanyName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? FullNameEn { get; set; }
    public string? FullNameAr { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string FromCountryName { get; set; } = string.Empty;
    public string FromPortName { get; set; } = string.Empty;
    public string ToCountryName { get; set; } = string.Empty;
    public string ToPortName { get; set; } = string.Empty;
    public decimal Container20ftPriceUsd { get; set; }
    public decimal Container40ftPriceUsd { get; set; }
}

public sealed class AdminUploadShippingProviderImageInput
{
    public string ProviderUserId { get; set; } = string.Empty;
    public Microsoft.AspNetCore.Http.IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}
