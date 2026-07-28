using BusinessLayer.Interfaces;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class ProductCreatedEventWorker(
    IProductBackgroundEventQueue eventQueue,
    IProductTranslationQueue translationQueue,
    ILogger<ProductCreatedEventWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Product created event worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            ProductBackgroundWorkItem workItem;
            try
            {
                workItem = await eventQueue.DequeueAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            try
            {
                await translationQueue.EnqueueAsync(workItem, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to dispatch product background event for {ProductId}", workItem.ProductId);
            }
        }
    }
}
