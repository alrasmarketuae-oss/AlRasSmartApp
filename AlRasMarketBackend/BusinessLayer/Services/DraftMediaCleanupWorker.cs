using BusinessLayer.Helpers;
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
/// This worker deletes draft objects older than 7 days that are not referenced anywhere
/// in the database (covers app crashes / missed client deletes).
/// </summary>
public sealed class DraftMediaCleanupWorker(
    IServiceScopeFactory scopeFactory,
    ILogger<DraftMediaCleanupWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(6);
    private static readonly TimeSpan MaxDraftAge = TimeSpan.FromDays(30);
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

        var referenced = await LoadAllReferencedMediaPathsAsync(db, cancellationToken);
        if (referenced.Count == 0)
        {
            logger.LogWarning(
                "DraftMediaCleanupWorker: skipped — no referenced media paths loaded from database.");
            return;
        }

        var deleted = 0;
        foreach (var obj in candidates)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var path = NormalizeStoredPath(obj.RelativePath);
            if (!path.Contains("/drafts/", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (referenced.Contains(path))
            {
                continue;
            }

            if (await IsReferencedInDatabaseAsync(db, path, cancellationToken))
            {
                logger.LogWarning(
                    "DraftMediaCleanupWorker: skipped {Path} — matched DB after normalize recheck.",
                    path);
                continue;
            }

            await storage.DeleteAsync(path, cancellationToken);
            deleted++;
            logger.LogInformation("DraftMediaCleanupWorker: deleted orphan draft {Path}", path);
        }

        logger.LogInformation(
            "DraftMediaCleanupWorker: deleted {Deleted} orphan draft object(s) older than {Days} day(s).",
            deleted,
            MaxDraftAge.TotalDays);
    }

    internal static async Task<HashSet<string>> LoadAllReferencedMediaPathsAsync(
        IRasAlSouqDbContext db,
        CancellationToken cancellationToken)
    {
        var referenced = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        void Add(string? path)
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                return;
            }

            referenced.Add(NormalizeStoredPath(path));
        }

        var imagePaths = await db.ProductImages
            .AsNoTracking()
            .Where(i => i.ImagePath != null)
            .Select(i => i.ImagePath!)
            .ToListAsync(cancellationToken);
        foreach (var path in imagePaths)
        {
            Add(path);
        }

        var videoPaths = await db.ProductVideos
            .AsNoTracking()
            .Where(v => v.VideoPath != null)
            .Select(v => v.VideoPath!)
            .ToListAsync(cancellationToken);
        foreach (var path in videoPaths)
        {
            Add(path);
        }

        var documentPaths = await db.ProductDocuments
            .AsNoTracking()
            .Where(d => d.DocumentPath != null)
            .Select(d => d.DocumentPath!)
            .ToListAsync(cancellationToken);
        foreach (var path in documentPaths)
        {
            Add(path);
        }

        var productVideoPaths = await db.Products
            .AsNoTracking()
            .Where(p => p.VideoPath != null)
            .Select(p => p.VideoPath!)
            .ToListAsync(cancellationToken);
        foreach (var path in productVideoPaths)
        {
            Add(path);
        }

        var pendingSnapshots = await db.Products
            .AsNoTracking()
            .Where(p => p.PendingProductChanges != null)
            .Select(p => p.PendingProductChanges!)
            .ToListAsync(cancellationToken);
        foreach (var raw in pendingSnapshots)
        {
            var snapshot = PendingProductChangeHelper.TryParse(raw);
            if (snapshot is null)
            {
                continue;
            }

            Add(snapshot.VideoPath);
            foreach (var path in snapshot.ImagePaths)
            {
                Add(path);
            }

            foreach (var path in snapshot.DocumentPaths)
            {
                Add(path);
            }

            foreach (var path in snapshot.ExtraVideoPaths)
            {
                Add(path);
            }
        }

        var orderImagePaths = await db.OrderImages
            .AsNoTracking()
            .Select(i => i.ImagePath)
            .ToListAsync(cancellationToken);
        foreach (var path in orderImagePaths)
        {
            Add(path);
        }

        var orderVideoPaths = await db.OrderVideos
            .AsNoTracking()
            .Select(v => v.VideoPath)
            .ToListAsync(cancellationToken);
        foreach (var path in orderVideoPaths)
        {
            Add(path);
        }

        var offerImagePaths = await db.OfferOnRequestImages
            .AsNoTracking()
            .Select(i => i.ImagePath)
            .ToListAsync(cancellationToken);
        foreach (var path in offerImagePaths)
        {
            Add(path);
        }

        var offerDocumentPaths = await db.OfferOnRequestDocuments
            .AsNoTracking()
            .Select(d => d.DocumentPath)
            .ToListAsync(cancellationToken);
        foreach (var path in offerDocumentPaths)
        {
            Add(path);
        }

        var companyImagePaths = await db.CompanyImages
            .AsNoTracking()
            .Select(i => i.ImagePath)
            .ToListAsync(cancellationToken);
        foreach (var path in companyImagePaths)
        {
            Add(path);
        }

        var bannerPaths = await db.HomeBanners
            .AsNoTracking()
            .Select(b => b.ImagePath)
            .ToListAsync(cancellationToken);
        foreach (var path in bannerPaths)
        {
            Add(path);
        }

        var categoryPaths = await db.Categories
            .AsNoTracking()
            .Select(c => c.ImgPath)
            .ToListAsync(cancellationToken);
        foreach (var path in categoryPaths)
        {
            Add(path);
        }

        var userPaths = await db.Users
            .AsNoTracking()
            .Select(u => new { u.ImgPath, u.LicencePath })
            .ToListAsync(cancellationToken);
        foreach (var user in userPaths)
        {
            Add(user.ImgPath);
            Add(user.LicencePath);
        }

        return referenced;
    }

    private static async Task<bool> IsReferencedInDatabaseAsync(
        IRasAlSouqDbContext db,
        string normalizedPath,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            return false;
        }

        var fileName = normalizedPath.Split('/').LastOrDefault() ?? string.Empty;
        if (fileName.Length == 0)
        {
            return false;
        }

        var productImagePaths = await db.ProductImages
            .AsNoTracking()
            .Where(i => i.ImagePath != null && i.ImagePath.Contains(fileName))
            .Select(i => i.ImagePath!)
            .ToListAsync(cancellationToken);
        if (productImagePaths.Any(p => NormalizeMediaReferencePath(p) == normalizedPath))
        {
            return true;
        }

        var productVideoPaths = await db.ProductVideos
            .AsNoTracking()
            .Where(v => v.VideoPath != null && v.VideoPath.Contains(fileName))
            .Select(v => v.VideoPath!)
            .ToListAsync(cancellationToken);
        if (productVideoPaths.Any(p => NormalizeMediaReferencePath(p) == normalizedPath))
        {
            return true;
        }

        var primaryVideoPaths = await db.Products
            .AsNoTracking()
            .Where(p => p.VideoPath != null && p.VideoPath.Contains(fileName))
            .Select(p => p.VideoPath!)
            .ToListAsync(cancellationToken);
        return primaryVideoPaths.Any(p => NormalizeMediaReferencePath(p) == normalizedPath);
    }

    private static string NormalizeMediaReferencePath(string? path) =>
        WebRootFileHelper.NormalizeMediaReferencePath(path);

    private static string NormalizeStoredPath(string? path) =>
        WebRootFileHelper.NormalizeMediaReferencePath(path);
}
