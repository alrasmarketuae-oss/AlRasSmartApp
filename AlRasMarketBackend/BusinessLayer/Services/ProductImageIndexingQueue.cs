using System.Threading.Channels;
using BusinessLayer.Interfaces;

namespace BusinessLayer.Services;

public sealed class ProductImageIndexingQueue : IProductImageIndexingQueue
{
    private readonly Channel<long> _queue = Channel.CreateUnbounded<long>(new UnboundedChannelOptions
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

        return _queue.Writer.WriteAsync(productImageId, cancellationToken);
    }

    public ValueTask<long> DequeueAsync(CancellationToken cancellationToken) =>
        _queue.Reader.ReadAsync(cancellationToken);
}
