namespace DataLayer.Models;

public class PendingOrder
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid FromUserId { get; set; }
    public Guid? AddressId { get; set; }
    public decimal ShippingCostAed { get; set; }
    public decimal SubtotalAed { get; set; }
    public decimal VatAed { get; set; }
    public decimal TotalPriceUsd { get; set; }
    public decimal TotalPriceAed { get; set; }
    public string? CheckoutCurrency { get; set; }
    public decimal? CheckoutAmount { get; set; }
    public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.Online;
    public string? StripeSessionId { get; set; }
    public string? PaymentIntentId { get; set; }
    public string? StripeRefundId { get; set; }
    public DateTime? RefundedAtUtc { get; set; }
    public bool IsPaymentCompleted { get; set; }
    public Guid? FinalOrderGroupId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? Notes { get; set; }
    public bool IsSelfPickup { get; set; }
    public string? DeliveryAddressLine { get; set; }
    public string? DeliveryCityName { get; set; }
    public decimal? DeliveryLatitude { get; set; }
    public decimal? DeliveryLongitude { get; set; }

    public User? FromUser { get; set; }
    public Address? Address { get; set; }
    public ICollection<PendingOrderItem> Items { get; set; } = [];
}
