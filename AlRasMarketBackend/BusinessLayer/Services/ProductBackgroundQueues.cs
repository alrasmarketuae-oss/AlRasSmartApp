using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class ProductBackgroundEventQueue : IProductBackgroundEventQueue
{
    private readonly Channel<QueuedWorkItem<ProductBackgroundWorkItem>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<ProductBackgroundWorkItem>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(new QueuedWorkItem<ProductBackgroundWorkItem>(Guid.NewGuid().ToString("N"), workItem), cancellationToken);

    public ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}

public sealed class ProductTranslationQueue : IProductTranslationQueue
{
    private readonly Channel<QueuedWorkItem<ProductBackgroundWorkItem>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<ProductBackgroundWorkItem>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(new QueuedWorkItem<ProductBackgroundWorkItem>(Guid.NewGuid().ToString("N"), workItem), cancellationToken);

    public ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}

/// <summary>
/// When Redis Streams own translation, product-created events enqueue straight
/// into the translation stream (no in-process hop / no ProductCreatedEventWorker).
/// </summary>
public sealed class DirectProductBackgroundEventQueue(IProductTranslationQueue translationQueue)
    : IProductBackgroundEventQueue
{
    public ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default) =>
        translationQueue.EnqueueAsync(workItem, cancellationToken);

    public ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken) =>
        throw new NotSupportedException("Direct product background events are enqueued into the translation stream.");

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}
