using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class ProductAutoModerationQueue : IProductAutoModerationQueue
{
    private readonly Channel<QueuedWorkItem<ProductAutoModerationWorkItem>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<ProductAutoModerationWorkItem>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(ProductAutoModerationWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(
            new QueuedWorkItem<ProductAutoModerationWorkItem>(Guid.NewGuid().ToString("N"), workItem),
            cancellationToken);

    public ValueTask<QueuedWorkItem<ProductAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}
