using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

/// <summary>In-process channel queue for missed-search match notifications.</summary>
public sealed class MissedSearchMatchEventQueue : IMissedSearchMatchEventQueue
{
    private readonly Channel<QueuedWorkItem<ProductBecameSearchableEvent>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<ProductBecameSearchableEvent>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(
        ProductBecameSearchableEvent workItem,
        CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(
            new QueuedWorkItem<ProductBecameSearchableEvent>(Guid.NewGuid().ToString("N"), workItem),
            cancellationToken);

    public ValueTask<QueuedWorkItem<ProductBecameSearchableEvent>> DequeueAsync(
        CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);
}

public sealed class MissedSearchMatchEventPublisher(
    IMissedSearchMatchEventQueue queue) : IMissedSearchMatchEventPublisher
{
    public ValueTask PublishProductBecameSearchableAsync(
        ProductBecameSearchableEvent evt,
        CancellationToken cancellationToken = default)
    {
        if (evt.ProductId == Guid.Empty || evt.SearchNames.Count == 0)
        {
            return ValueTask.CompletedTask;
        }

        return queue.EnqueueAsync(evt, cancellationToken);
    }
}
