using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

/// <summary>
/// Periodic cleanup of orphaned draft media objects in R2/local storage.
///
/// Primary cleanup path: mobile client DELETE /api/ProductAssets/draft when the user
/// removes media or abandons create-ad without publishing.
///
/// This worker deletes draft objects older than 24h that are not referenced by
/// ProductImages / ProductVideos (covers app crashes / missed client deletes).
/// </summary>
public sealed class DraftMediaCleanupWorker(
    IServiceScopeFactory scopeFactory,
    ILogger<DraftMediaCleanupWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);
    private static readonly TimeSpan MaxDraftAge = TimeSpan.FromHours(24);
    private static readonly string[] DraftPrefixes =
    [
        "/product-images/drafts/",
        "/product-videos/drafts/",
        "product-images/drafts/",
        "product-videos/drafts/",
    ];

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation(
            "DraftMediaCleanupWorker started — runs every {Hours} hours.",
            Interval.TotalHours);

        // First pass shortly after boot, then on interval.
        try
        {
            await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
            return;
        }

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

    private async Task RunCleanupAsync(CancellationToken cancellationToken)
    {
        using var scope = scopeFactory.CreateScope();
        var storage = scope.ServiceProvider.GetRequiredService<IFileStorage>();
        var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();

        var cutoff = DateTimeOffset.UtcNow - MaxDraftAge;
        var candidates = new List<StoredObjectInfo>();

        foreach (var prefix in DraftPrefixes.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var listed = await storage.ListAsync(prefix, cancellationToken);
            candidates.AddRange(listed.Where(o => o.LastModified <= cutoff));
        }

        if (candidates.Count == 0)
        {
            logger.LogDebug("DraftMediaCleanupWorker: no aged draft objects found.");
            return;
        }

        // Normalize to trailing-trimmed relative paths for comparison.
        static string Norm(string path) =>
            "/" + (path ?? string.Empty).Replace('\\', '/').Trim().TrimStart('/');

        var imagePaths = await db.ProductImages
            .AsNoTracking()
            .Where(i => i.ImagePath != null)
            .Select(i => i.ImagePath!)
            .ToListAsync(cancellationToken);
        var videoPaths = await db.ProductVideos
            .AsNoTracking()
            .Where(v => v.VideoPath != null)
            .Select(v => v.VideoPath!)
            .ToListAsync(cancellationToken);

        var referenced = new HashSet<string>(
            imagePaths.Concat(videoPaths).Select(Norm),
            StringComparer.OrdinalIgnoreCase);

        var deleted = 0;
        foreach (var obj in candidates)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var path = Norm(obj.RelativePath);
            if (!path.Contains("/drafts/", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (referenced.Contains(path))
            {
                continue;
            }

            await storage.DeleteAsync(path, cancellationToken);
            deleted++;
        }

        logger.LogInformation(
            "DraftMediaCleanupWorker: deleted {Deleted} orphan draft object(s) older than {Hours}h.",
            deleted,
            MaxDraftAge.TotalHours);
    }
}
