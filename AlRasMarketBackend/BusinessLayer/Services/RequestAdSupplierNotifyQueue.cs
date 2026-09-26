using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

/// <summary>In-process channel queue for "new request ad → all suppliers" FCM fan-out.</summary>
public sealed class RequestAdSupplierNotifyQueue : IRequestAdSupplierNotifyQueue
{
    private readonly Channel<QueuedWorkItem<RequestAdSupplierNotifyEvent>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<RequestAdSupplierNotifyEvent>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(
        RequestAdSupplierNotifyEvent workItem,
        CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(
            new QueuedWorkItem<RequestAdSupplierNotifyEvent>(Guid.NewGuid().ToString("N"), workItem),
            cancellationToken);

    public ValueTask<QueuedWorkItem<RequestAdSupplierNotifyEvent>> DequeueAsync(
        CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);
}

public sealed class RequestAdSupplierNotifyPublisher(
    IRequestAdSupplierNotifyQueue queue) : IRequestAdSupplierNotifyPublisher
{
    public ValueTask PublishAsync(
        RequestAdSupplierNotifyEvent evt,
        CancellationToken cancellationToken = default)
    {
        if (evt.ProductId == Guid.Empty)
        {
            return ValueTask.CompletedTask;
        }

        return queue.EnqueueAsync(evt, cancellationToken);
    }
}
