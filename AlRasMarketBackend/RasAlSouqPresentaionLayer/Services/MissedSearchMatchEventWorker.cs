using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>
/// Consumes <see cref="ProductBecameSearchableEvent"/> off the hot path and
/// notifies users who previously logged a matching missed product search.
/// </summary>
public sealed class MissedSearchMatchEventWorker(
    IMissedSearchMatchEventQueue eventQueue,
    IServiceScopeFactory scopeFactory,
    ILogger<MissedSearchMatchEventWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Missed-search match event worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<ProductBecameSearchableEvent> message;
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
                await using var scope = scopeFactory.CreateAsyncScope();
                var notifier = scope.ServiceProvider
                    .GetRequiredService<MissedSearchProductAvailableNotifier>();
                await notifier
                    .NotifyMatchingSearchersAsync(message.Payload, stoppingToken)
                    .ConfigureAwait(false);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogError(
                    ex,
                    "Failed missed-search match notify for product {ProductId}",
                    message.Payload.ProductId);
            }
        }
    }
}
