using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class ProductImageIndexingQueue : IProductImageIndexingQueue
{
    private readonly Channel<QueuedWorkItem<long>> _queue = Channel.CreateUnbounded<QueuedWorkItem<long>>(
        new UnboundedChannelOptions
        {
            SingleReader = false,
            SingleWriter = false
        });

    public ValueTask EnqueueAsync(long productImageId, CancellationToken cancellationToken = default)
    {
        if (productImageId <= 0)
        {
            return ValueTask.CompletedTask;
        }

        return _queue.Writer.WriteAsync(
            new QueuedWorkItem<long>(Guid.NewGuid().ToString("N"), productImageId),
            cancellationToken);
    }

    public ValueTask<QueuedWorkItem<long>> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}
