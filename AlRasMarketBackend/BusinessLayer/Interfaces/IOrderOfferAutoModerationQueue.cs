namespace BusinessLayer.Interfaces;

/// <summary>
/// Queued after an order/offer is created and needs admin moderation
/// (Requests, Offers, Booking, Category with notes/media).
/// Same policy as product ads: video or image/contact-on-photo → admin only;
/// no-video text violations → reject; no-video clean → manual admin approval.
/// </summary>
public sealed record OrderOfferAutoModerationWorkItem(long OrderId);

public interface IOrderOfferAutoModerationQueue
{
    ValueTask EnqueueAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<QueuedWorkItem<OrderOfferAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken);
    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}
