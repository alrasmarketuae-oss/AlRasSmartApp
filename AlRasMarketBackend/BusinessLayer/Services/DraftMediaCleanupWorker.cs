using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Periodic best-effort cleanup of orphaned draft media objects in R2.
///
/// Primary cleanup path: the mobile client calls DELETE /api/ProductAssets/draft when
/// the user removes a media item or abandons the create-ad form without publishing.
///
/// This worker handles any drafts that slip through (e.g. app crash before cleanup).
/// Since IFileStorage does not expose a ListObjects API, cleanup relies on the
/// client sending explicit deletes; this worker currently only logs a reminder.
///
/// If ListObjects is added to IFileStorage in the future, replace the body of
/// RunCleanupAsync with: list objects under product-images/drafts/ and
/// product-videos/drafts/ older than 24 h, then delete those not referenced in
/// the ProductImages / ProductVideos tables.
/// </summary>
public sealed class DraftMediaCleanupWorker(
    ILogger<DraftMediaCleanupWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation(
            "DraftMediaCleanupWorker started — runs every {Hours} hours.",
            Interval.TotalHours);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunCleanupAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "DraftMediaCleanupWorker iteration failed.");
            }

            await Task.Delay(Interval, stoppingToken);
        }

        logger.LogInformation("DraftMediaCleanupWorker stopped.");
    }

    private Task RunCleanupAsync(CancellationToken cancellationToken)
    {
        // IFileStorage does not currently expose ListObjects.
        // Client-side cleanup (DELETE /api/ProductAssets/draft) is the primary mechanism.
        // When IFileStorage gains list support, implement orphan detection here:
        //   1. List objects under product-images/drafts/ and product-videos/drafts/.
        //   2. Filter objects whose LastModified is older than 24 h.
        //   3. Query ProductImages + ProductVideos to exclude referenced paths.
        //   4. Delete the remaining orphans via IFileStorage.DeleteAsync.
        logger.LogDebug(
            "DraftMediaCleanupWorker: no-op (IFileStorage has no ListObjects). " +
            "Relying on client-side draft cleanup.");
        return Task.CompletedTask;
    }
}
