namespace BusinessLayer.Interfaces;

/// <summary>
/// Queued after an order/offer is created and needs admin moderation
/// (Requests, Offers, Booking, Category with notes/media).
/// Same policy as product ads: video → admin only (no auto notify/reject);
/// no-video violations → reject; no-video clean → auto-approve.
/// </summary>
public sealed record OrderOfferAutoModerationWorkItem(long OrderId);

public interface IOrderOfferAutoModerationQueue
{
    ValueTask EnqueueAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<QueuedWorkItem<OrderOfferAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken);
    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}
