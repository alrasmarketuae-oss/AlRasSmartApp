using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>
/// Consumes <see cref="RequestAdSupplierNotifyEvent"/> off the hot path and
/// fans out FCM/inbox to all suppliers without blocking create/submit.
/// </summary>
public sealed class RequestAdSupplierNotifyWorker(
    IRequestAdSupplierNotifyQueue eventQueue,
    IServiceScopeFactory scopeFactory,
    ILogger<RequestAdSupplierNotifyWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Request-ad supplier notify worker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            QueuedWorkItem<RequestAdSupplierNotifyEvent> message;
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
                var notifier = scope.ServiceProvider.GetRequiredService<RequestAdSupplierNotifier>();
                await notifier
                    .NotifySuppliersAsync(message.Payload, stoppingToken)
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
                    "Failed request-ad supplier notify for product {ProductId}",
                    message.Payload.ProductId);
            }
        }
    }
}
