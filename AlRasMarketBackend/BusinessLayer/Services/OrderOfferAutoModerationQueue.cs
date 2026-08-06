using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class OrderOfferAutoModerationQueue : IOrderOfferAutoModerationQueue
{
    private readonly Channel<QueuedWorkItem<OrderOfferAutoModerationWorkItem>> _queue =
        Channel.CreateUnbounded<QueuedWorkItem<OrderOfferAutoModerationWorkItem>>(
            new UnboundedChannelOptions
            {
                SingleReader = true,
                SingleWriter = false
            });

    public ValueTask EnqueueAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(
            new QueuedWorkItem<OrderOfferAutoModerationWorkItem>(Guid.NewGuid().ToString("N"), workItem),
            cancellationToken);

    public ValueTask<QueuedWorkItem<OrderOfferAutoModerationWorkItem>> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);

    public ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default) =>
        ValueTask.CompletedTask;
}
