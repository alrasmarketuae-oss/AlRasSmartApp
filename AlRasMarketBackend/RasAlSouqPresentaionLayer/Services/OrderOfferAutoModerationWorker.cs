using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

public sealed class OrderOfferAutoModerationWorker(
    IServiceScopeFactory scopeFactory,
    IOrderOfferAutoModerationQueue queue,
    ILogger<OrderOfferAutoModerationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Order-offer auto-moderation worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<OrderOfferAutoModerationWorkItem> message;
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
                var service = scope.ServiceProvider.GetRequiredService<IOrderOfferAutoModerationService>();
                await service.ProcessAsync(message.Payload, stoppingToken).ConfigureAwait(false);
                await queue.AcknowledgeAsync(message.MessageId, stoppingToken).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Order-offer auto-moderation failed for order {OrderId}", message.Payload.OrderId);
            }
        }
    }
}
