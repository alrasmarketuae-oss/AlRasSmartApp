namespace DataLayer.Models;

/// <summary>Legacy online-payment tracker for orders created before the pending-order checkout flow.</summary>
public class PendingPayment
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public string StripeSessionId { get; set; } = string.Empty;
    public string? PaymentIntentId { get; set; }
    public string? StripeRefundId { get; set; }
    public DateTime? RefundedAtUtc { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Order? Order { get; set; }
}
