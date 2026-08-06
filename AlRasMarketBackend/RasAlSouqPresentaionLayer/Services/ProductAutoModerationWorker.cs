using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class ProductAutoModerationWorker(
    IServiceScopeFactory scopeFactory,
    IProductAutoModerationQueue queue,
    ILogger<ProductAutoModerationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Product auto-moderation worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<ProductAutoModerationWorkItem> message;
            try
            {
                message = await queue.DequeueAsync(stoppingToken).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var service = scope.ServiceProvider.GetRequiredService<IProductAutoModerationService>();
                await service.ProcessAsync(message.Payload, stoppingToken).ConfigureAwait(false);
                await queue.AcknowledgeAsync(message.MessageId, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Auto-moderation failed for product {ProductId}",
                    message.Payload.ProductId);
            }
        }
    }
}
