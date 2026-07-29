namespace BusinessLayer.Interfaces;

public sealed record ProductBackgroundWorkItem(
    Guid ProductId,
    string? NameEn,
    string? DescriptionEn,
    string? RetailDescriptionEn,
    string? SupplierNotesEn,
    string? ShippingDescriptionEn,
    bool QueueImageEmbeddingAfterTranslation);

/// <summary>Dequeued message from an in-process or Redis Stream queue.</summary>
public sealed record QueuedWorkItem<T>(string MessageId, T Payload);

public interface IProductBackgroundEventQueue
{
    ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken);
    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}

public interface IProductTranslationQueue
{
    ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<QueuedWorkItem<ProductBackgroundWorkItem>> DequeueAsync(CancellationToken cancellationToken);
    ValueTask AcknowledgeAsync(string messageId, CancellationToken cancellationToken = default);
}
