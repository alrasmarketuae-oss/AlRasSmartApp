namespace BusinessLayer.Interfaces;

public sealed record ProductBackgroundWorkItem(
    Guid ProductId,
    string? NameEn,
    string? DescriptionEn,
    string? RetailDescriptionEn,
    string? SupplierNotesEn,
    string? ShippingDescriptionEn,
    bool QueueImageEmbeddingAfterTranslation);

public interface IProductBackgroundEventQueue
{
    ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<ProductBackgroundWorkItem> DequeueAsync(CancellationToken cancellationToken);
}

public interface IProductTranslationQueue
{
    ValueTask EnqueueAsync(ProductBackgroundWorkItem workItem, CancellationToken cancellationToken = default);
    ValueTask<ProductBackgroundWorkItem> DequeueAsync(CancellationToken cancellationToken);
}
