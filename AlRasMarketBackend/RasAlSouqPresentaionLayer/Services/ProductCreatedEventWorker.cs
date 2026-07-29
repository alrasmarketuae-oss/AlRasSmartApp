using BusinessLayer.Interfaces;
using BusinessLayer.Services;
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
        if (eventQueue is DirectProductBackgroundEventQueue)
        {
            logger.LogInformation(
                "Product created event worker idle — events enqueue directly to the translation stream.");
            return;
        }

        logger.LogInformation("Product created event worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<ProductBackgroundWorkItem> message;
            try
            {
                message = await eventQueue.DequeueAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            try
            {
                await translationQueue.EnqueueAsync(message.Payload, stoppingToken).ConfigureAwait(false);
                await eventQueue.AcknowledgeAsync(message.MessageId, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to dispatch product background event for {ProductId}", message.Payload.ProductId);
            }
        }
    }
}
