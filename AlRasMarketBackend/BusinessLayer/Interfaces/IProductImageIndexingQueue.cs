namespace BusinessLayer.Interfaces;

public interface IProductImageIndexingQueue
{
    ValueTask EnqueueAsync(long productImageId, CancellationToken cancellationToken = default);

    ValueTask<QueuedWorkItem<long>> DequeueAsync(CancellationToken cancellationToken);

    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}

public interface IProductImageVectorIndexingProcessor
{
    Task IndexProductImageAsync(long productImageId, CancellationToken cancellationToken = default);
}
