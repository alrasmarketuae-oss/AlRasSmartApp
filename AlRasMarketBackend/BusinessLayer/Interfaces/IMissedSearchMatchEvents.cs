namespace BusinessLayer.Interfaces;

/// <summary>
/// Fired when a product becomes publicly searchable (e.g. admin approved).
/// Handled asynchronously so approve/search paths stay fast.
/// </summary>
public sealed record ProductBecameSearchableEvent(
    Guid ProductId,
    Guid? OwnerId,
    IReadOnlyList<string> SearchNames);

public interface IMissedSearchMatchEventPublisher
{
    ValueTask PublishProductBecameSearchableAsync(
        ProductBecameSearchableEvent evt,
        CancellationToken cancellationToken = default);
}

public interface IMissedSearchMatchEventQueue
{
    ValueTask EnqueueAsync(
        ProductBecameSearchableEvent workItem,
        CancellationToken cancellationToken = default);

    ValueTask<QueuedWorkItem<ProductBecameSearchableEvent>> DequeueAsync(
        CancellationToken cancellationToken);
}
