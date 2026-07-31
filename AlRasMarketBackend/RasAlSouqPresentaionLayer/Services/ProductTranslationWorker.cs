using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using BusinessLayer.Services;
using DataLayer.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class ProductTranslationWorker(
    IServiceScopeFactory scopeFactory,
    IProductTranslationQueue translationQueue,
    IProductImageIndexingQueue imageIndexingQueue,
    IOptions<ImageEmbeddingOptions> imageEmbeddingOptions,
    ILogger<ProductTranslationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Product translation worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<ProductBackgroundWorkItem> message;
            try
            {
                message = await translationQueue.DequeueAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            var workItem = message.Payload;
            await using var scope = scopeFactory.CreateAsyncScope();
            try
            {
                var translator = scope.ServiceProvider.GetRequiredService<IContentTranslationService>();
                await translator.UpsertProductFieldsAsync(
                    workItem.ProductId,
                    workItem.NameEn,
                    workItem.DescriptionEn,
                    workItem.RetailDescriptionEn,
                    workItem.SupplierNotesEn,
                    workItem.ShippingDescriptionEn).ConfigureAwait(false);
                ProductsAppService.InvalidateListingCaches();

                try
                {
                    var textSync = scope.ServiceProvider.GetRequiredService<ProductTextSearchSyncService>();
                    await textSync.UpsertProductAsync(workItem.ProductId, stoppingToken).ConfigureAwait(false);
                }
                catch (Exception syncEx)
                {
                    logger.LogWarning(
                        syncEx,
                        "Meilisearch sync after translation failed for {ProductId}",
                        workItem.ProductId);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background product translation failed for {ProductId}", workItem.ProductId);
            }

            if (workItem.QueueImageEmbeddingAfterTranslation && imageEmbeddingOptions.Value.Enabled)
            {
                try
                {
                    var productData = scope.ServiceProvider.GetRequiredService<IProductDataAccess>();
                    var imageIds = await productData.GetProductImageIdsByProductIdAsync(workItem.ProductId).ConfigureAwait(false);
                    foreach (var imageId in imageIds)
                    {
                        await imageIndexingQueue.EnqueueAsync(imageId, stoppingToken).ConfigureAwait(false);
                    }
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "CLIP reindex after translation failed for {ProductId}", workItem.ProductId);
                }
            }

            try
            {
                await translationQueue.AcknowledgeAsync(message.MessageId, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to ACK translation message {MessageId}", message.MessageId);
            }
        }
    }
}
