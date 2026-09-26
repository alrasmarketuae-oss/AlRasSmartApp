namespace BusinessLayer.Interfaces;

/// <summary>
/// Fired when a Requests ad becomes publicly live (admin approved).
/// Handled asynchronously so approve/create paths never wait on FCM fan-out.
/// </summary>
public sealed record RequestAdSupplierNotifyEvent(
    Guid ProductId,
    Guid? OwnerId,
    string? ProductNameEn,
    string? ProductNameAr);

public interface IRequestAdSupplierNotifyPublisher
{
    ValueTask PublishAsync(
        RequestAdSupplierNotifyEvent evt,
        CancellationToken cancellationToken = default);
}

public interface IRequestAdSupplierNotifyQueue
{
    ValueTask EnqueueAsync(
        RequestAdSupplierNotifyEvent workItem,
        CancellationToken cancellationToken = default);

    ValueTask<QueuedWorkItem<RequestAdSupplierNotifyEvent>> DequeueAsync(
        CancellationToken cancellationToken);
}
