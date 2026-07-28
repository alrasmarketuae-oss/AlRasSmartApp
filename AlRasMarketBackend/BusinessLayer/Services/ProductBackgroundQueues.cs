using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class ProductBackgroundEventQueue : IProductBackgroundEventQueue
{
    private readonly Channel<ProductBackgroundWorkItem> _queue = Channel.CreateUnbounded<ProductBackgroundWorkItem>(
        new UnboundedChannelOptions
        {
            SingleReader = true,
            SingleWriter = false
        });

    public ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(workItem, cancellationToken);

    public ValueTask<ProductBackgroundWorkItem> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);
}

public sealed class ProductTranslationQueue : IProductTranslationQueue
{
    private readonly Channel<ProductBackgroundWorkItem> _queue = Channel.CreateUnbounded<ProductBackgroundWorkItem>(
        new UnboundedChannelOptions
        {
            SingleReader = true,
            SingleWriter = false
        });

    public ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default) =>
        _queue.Writer.WriteAsync(workItem, cancellationToken);

    public ValueTask<ProductBackgroundWorkItem> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);
}
