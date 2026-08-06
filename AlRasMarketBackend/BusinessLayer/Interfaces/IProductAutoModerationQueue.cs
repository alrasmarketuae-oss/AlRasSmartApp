namespace BusinessLayer.Interfaces;

/// <summary>
/// Queued after SubmitForAdminReview / owner edit, before CLIP indexing.
/// Applies to all ad types (Offers, Requests, Booking, Category).
/// Violations → auto-reject; video (clean otherwise) → admin dashboard;
/// no video + clean → auto-approve. Same scan on create and edit/resubmit.
/// </summary>
public sealed record ProductAutoModerationWorkItem(
    Guid ProductId,
    /// <summary>
    /// When true, skip auto approve/reject and leave for admin (e.g. explicit ops override).
    /// Normal create/edit/resubmit paths pass false.
    /// </summary>
    bool RequireManualReview);

public interface IProductAutoModerationQueue
{
    ValueTask EnqueueAsync(ProductAutoModerationWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<QueuedWorkItem<ProductAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken);
    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}
