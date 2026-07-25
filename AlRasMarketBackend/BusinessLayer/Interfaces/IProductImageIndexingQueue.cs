namespace BusinessLayer.Interfaces;

public interface IProductImageIndexingQueue
{
    ValueTask EnqueueAsync(long productImageId, CancellationToken cancellationToken = default);

    ValueTask<long> DequeueAsync(CancellationToken cancellationToken);
}

public interface IProductImageVectorIndexingProcessor
{
    Task IndexProductImageAsync(long productImageId, CancellationToken cancellationToken = default);
}
