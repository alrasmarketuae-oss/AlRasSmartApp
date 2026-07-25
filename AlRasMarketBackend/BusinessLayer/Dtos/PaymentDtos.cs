using DataLayer.Models;
using BusinessLayer.Helpers;

namespace BusinessLayer.Dtos;

public sealed class OrderDetailDto
{
    public long Id { get; init; }
    public Guid FromUserId { get; init; }
    public Guid ToUserId { get; init; }
    public Guid ProductId { get; init; }
    public decimal Quantity { get; init; }
    public decimal UnitPrice { get; init; }
    public decimal TotalPrice { get; init; }
    public DateTime CreatedAt { get; init; }
    public byte StatusId { get; init; }
    public string Status { get; init; } = string.Empty;
    public string StatusAr { get; init; } = string.Empty;
    public Guid? OrderGroupId { get; init; }
    public Guid? PendingOrderId { get; init; }
    public byte PaymentMethod { get; init; }
    public string PaymentMethodName { get; init; } = string.Empty;
    public string? StripeSessionId { get; init; }
    public byte? UnitId { get; init; }
    public bool IsApproved { get; init; }
    public string? Notes { get; init; }
    public int? PortId { get; init; }
    public string? PortName { get; init; }
    public IReadOnlyList<string> ImagePaths { get; init; } = [];
    public IReadOnlyList<string> VideoPaths { get; init; } = [];
    public string? StripeRefundId { get; init; }
    public DateTime? RefundedAtUtc { get; init; }
    public bool IsRefunded { get; init; }
}

public sealed class CreateDirectOrderInput
{
    public string AuthenticatedUserId { get; set; } = string.Empty;
    public string ToUserId { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string? SupplierEmail { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public string PaymentMethodName { get; set; } = "CashOnDelivery";
    public string? Notes { get; set; }
    public List<string>? ImagePaths { get; set; }
    public List<string>? VideoPaths { get; set; }
    public List<string>? DocumentPaths { get; set; }
    public string? PortName { get; set; }
}

public sealed class PlaceOrderInput
{
    public string UserId { get; set; } = string.Empty;
    public Guid? AddressId { get; set; }
    public string? AddressLine { get; set; }
    public string? CityName { get; set; }
    public string PaymentMethodName { get; set; } = "Online";
    public decimal? ShippingCostAed { get; set; }
    public bool? IsSelfPickup { get; set; }
    public string? Notes { get; set; }
}

public sealed class UpdateOrderStatusInput
{
    public string UserId { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public byte StatusId { get; set; }
}

public sealed class CreateStripeCheckoutInput
{
    public string UserId { get; set; } = string.Empty;
    public string OrderId { get; set; } = string.Empty;
    public string? Currency { get; set; }
    public decimal? Amount { get; set; }
    /// <summary>When "mobile", Stripe redirects back into the app via deep link.</summary>
    public string? Client { get; set; }
}

public sealed class CreateStripeCheckoutResult
{
    public string SessionId { get; init; } = string.Empty;
    public string? CheckoutUrl { get; init; }
    public string Currency { get; init; } = "AED";
    public decimal Amount { get; init; }
}

public sealed class CheckoutStatusResult
{
    public string Status { get; init; } = string.Empty;
    public string? OrderGroupId { get; init; }
    public byte? OrderStatusId { get; init; }
}

public sealed class ManualRefundResult
{
    public string OrderGroupId { get; init; } = string.Empty;
    public string RefundId { get; init; } = string.Empty;
    public DateTime RefundedAtUtc { get; init; }
}

public sealed class UploadOrderVideoInput
{
    public string UserId { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public Microsoft.AspNetCore.Http.IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class UploadOrderImageInput
{
    public string UserId { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public Microsoft.AspNetCore.Http.IFormFile? File { get; set; }
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class MyRequestOfferDto
{
    public long OrderId { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public string UnitName { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public string Currency { get; set; } = "AED";
    public string UnitPriceFormatted { get; set; } = string.Empty;
    public string TotalPriceFormatted { get; set; } = string.Empty;
    public byte StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public bool IsApproved { get; set; }
    public bool IsAdminApproved { get; set; }
    public bool CanAccept { get; set; }
    public bool CanReject { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? PortName { get; set; }
    public string? DestinationCountryName { get; set; }
    public string? Notes { get; set; }
    public List<string> ImagePaths { get; set; } = [];
    public List<string> DocumentPaths { get; set; } = [];
}

public sealed class RequestOrderReturnInput
{
    public string UserId { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public string Reason { get; set; } = string.Empty;
    public List<Microsoft.AspNetCore.Http.IFormFile> MediaFiles { get; set; } = [];
    public string WebRootPath { get; set; } = string.Empty;
}

public sealed class RespondToOrderReturnInput
{
    public string AdminUserId { get; set; } = string.Empty;
    public long OrderId { get; set; }
    public string Response { get; set; } = string.Empty;
    /// <summary>When true, support approved the return (refund online payments).</summary>
    public bool Approved { get; set; } = true;
}
