namespace DataLayer.Models;

public class Order
{
    public long Id { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public Guid ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public byte StatusId { get; set; }
    public Guid? OrderGroupId { get; set; }
    public Guid? PendingOrderId { get; set; }
    public PendingOrder? PendingOrder { get; set; }
    public byte PaymentMethod { get; set; }
    public string? StripeSessionId { get; set; }
    public byte? UnitId { get; set; }
    public Unit? Unit { get; set; }
    public bool IsApproved { get; set; }
    /// <summary>Admin preliminary approval (non-retail) or final approval with stock deduction (retail).</summary>
    public bool IsAdminApproved { get; set; }
    public string? Notes { get; set; }
    /// <summary>Optional bilingual display label set by workflow or admin free-text status update.</summary>
    public string? CustomStatusNameEn { get; set; }
    /// <summary>Optional bilingual display label set by workflow or admin free-text status update.</summary>
    public string? CustomStatusNameAr { get; set; }
    /// <summary>True when product stock was reduced at direct order placement (POST /api/Orders with productId).</summary>
    public bool StockQuantityDeducted { get; set; }
    /// <summary>
    /// True when this order was placed via the retail channel (cart checkout),
    /// including category products that expose optional retail pricing.
    /// </summary>
    public bool IsRetailPurchase { get; set; }
    /// <summary>VAT (5%) allocated to this order line at checkout.</summary>
    public decimal VatAed { get; set; }
    /// <summary>Domestic shipping fee for the cart checkout (AED).</summary>
    public decimal ShippingCostAed { get; set; }
    /// <summary>True when the buyer chose self-pickup instead of delivery.</summary>
    public bool IsSelfPickup { get; set; }
    /// <summary>Snapshot of buyer delivery address line at checkout.</summary>
    public string? DeliveryAddressLine { get; set; }
    /// <summary>Snapshot of buyer delivery city/emirate at checkout.</summary>
    public string? DeliveryCityName { get; set; }
    public decimal? DeliveryLatitude { get; set; }
    public decimal? DeliveryLongitude { get; set; }
    /// <summary>Selected port for booking orders.</summary>
    public int? PortId { get; set; }
    public string? StripeRefundId { get; set; }
    public DateTime? RefundedAtUtc { get; set; }

    /// <summary>Buyer return reason (retail after delivery).</summary>
    public string? ReturnReason { get; set; }
    /// <summary>JSON array of media paths (images/videos) attached to the return request.</summary>
    public string? ReturnMediaPathsJson { get; set; }
    public DateTime? ReturnRequestedAtUtc { get; set; }
    /// <summary>Admin reply to the return request.</summary>
    public string? ReturnAdminResponse { get; set; }
    public DateTime? ReturnRespondedAtUtc { get; set; }

    public User? FromUser { get; set; }
    public User? ToUser { get; set; }
    public Product? Product { get; set; }
    public OrderStatus? Status { get; set; }
    public Port? Port { get; set; }
    public ICollection<OrderVideo> Videos { get; set; } = [];
    public ICollection<OrderImage> Images { get; set; } = [];
    public ICollection<OrderStatusHistory> StatusHistories { get; set; } = [];
    public OrderAdminOfferPrice? AdminOfferPrice { get; set; }
}
