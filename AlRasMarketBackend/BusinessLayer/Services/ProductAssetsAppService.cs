using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public class ProductAssetsAppService(
    IRasAlSouqDbContext dbContext,
    IMediaStorageService mediaStorage,
    IProductImageIndexingQueue productImageIndexingQueue,
    IProductImageVectorIndex productImageVectorIndex,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    IServiceScopeFactory scopeFactory,
    ILogger<ProductAssetsAppService> logger) : IProductAssetsAppService
{
    private readonly ImageEmbeddingOptions _embeddingOptions = embeddingOptions.Value;

    private const string ProductImagesFolder = "product-images";
    private const string ProductDocumentsFolder = "product-documents";

    public async Task<object> UploadImageAsync(UploadProductImageInput input, CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await dbContext.Products.FindAsync([productId], cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        // DEV: التحقق من الملكية معطّل — أي مستخدم مسجّل يرفع على أي منتج.
        // PRODUCTION: أزل التعليق عن الكود التالي:
        /*
        if (!Guid.TryParse(input.OwnerId, out var ownerId))
        {
            throw new ArgumentException("Invalid owner id.");
        }

        await EnsureProductAssetAccessAsync(product, ownerId, input.AllowAdminAccess, cancellationToken);
        */

        const int maxProductImages = 15;
        var existingImageCount = await dbContext.ProductImages
            .CountAsync(x => x.ProductId == productId, cancellationToken);
        if (existingImageCount >= maxProductImages)
        {
            throw new InvalidOperationException("A product can have at most 15 images.");
        }

        var fileName = $"{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            ProductImagesFolder,
            fileName,
            ImageCompressionOptions.ProductUploadFast,
            cancellationToken: cancellationToken);
        var entity = new ProductImage
        {
            ProductId = productId,
            ImagePath = imagePath
        };

        await dbContext.ProductImages.AddAsync(entity, cancellationToken);
        // Admin edits apply live — do not send the listing back to pending review.
        var markedAsEdit = false;
        if (!input.AllowAdminAccess)
        {
            markedAsEdit = await MarkOwnerMediaChangedForReviewAsync(product, cancellationToken);
        }
        else
        {
            product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product.OwnerId);

        // Do not run CLIP during the upload request — that blocks the publisher on CPU-heavy
        // embedding. New ads are indexed after SubmitForAdminReview; already-live ads enqueue
        // here without awaiting the workers.
        if (_embeddingOptions.Enabled
            && (product.IsReadyForAdminReview || product.IsApproved == true || input.AllowAdminAccess))
        {
            QueueImageIndexing(entity.Id);
        }

        if (markedAsEdit)
        {
            QueueAdminProductEditAlert(product);
        }

        return new { entity.Id, entity.ProductId, Path = entity.ImagePath };
    }

    public async Task<string> DeleteImageAsync(
        long imageId,
        string ownerId,
        string? webRootPath,
        bool allowAdminAccess,
        CancellationToken cancellationToken = default)
    {
        // DEV: حذف الصور بدون تحقق ملكية.
        // PRODUCTION: استبدل FirstOrDefaultAsync أدناه بالنسخة المعطّلة بالتعليق في نهاية الملف.
        var image = await dbContext.ProductImages
            .FirstOrDefaultAsync(x => x.Id == imageId, cancellationToken)
            ?? throw new KeyNotFoundException("Product image not found.");

        /*
        if (!Guid.TryParse(ownerId, out var parsedOwnerId))
        {
            throw new ArgumentException("Invalid owner id.");
        }

        var image = await dbContext.ProductImages
            .Include(x => x.Product)
            .FirstOrDefaultAsync(x => x.Id == imageId, cancellationToken)
            ?? throw new KeyNotFoundException("Product image not found.");

        if (!allowAdminAccess && image.Product?.OwnerId != parsedOwnerId)
        {
            throw new UnauthorizedAccessException("You can delete files only from your own product.");
        }
        */

        var path = image.ImagePath;
        var product = image.Product
            ?? await dbContext.Products.FirstOrDefaultAsync(
                x => x.ProductId == image.ProductId,
                cancellationToken);

        var markedAsEdit = false;
        if (product is not null && !allowAdminAccess && ShouldTreatMediaChangeAsOwnerEdit(product))
        {
            await EnsurePendingEditSnapshotAsync(product, cancellationToken);
        }

        var pending = PendingProductChangeHelper.TryParse(product?.PendingProductChanges);
        // Keep previous images on disk until admin accepts/rejects the edit.
        var keepFileForPendingEdit = !allowAdminAccess
            && PendingProductChangeHelper.PathExistsInSnapshot(pending, path);

        dbContext.ProductImages.Remove(image);

        if (product is not null)
        {
            if (!allowAdminAccess)
            {
                markedAsEdit = await MarkOwnerMediaChangedForReviewAsync(product, cancellationToken);
            }
            else
            {
                product.UpdatedAt = UtcDateTimeHelper.UtcNow;
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product?.OwnerId);

        try
        {
            await productImageVectorIndex.DeleteByProductImageIdAsync(imageId, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed removing Qdrant vector for image {ImageId}", imageId);
        }

        if (markedAsEdit)
        {
            QueueAdminProductEditAlert(image.ProductId);
        }

        if (!keepFileForPendingEdit)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }

        return "Image deleted successfully.";
    }

    public async Task<string> DeleteImageByPathAsync(
        string productId,
        string imagePath,
        string ownerId,
        string? webRootPath,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var normalizedPath = NormalizeAssetPath(imagePath);
        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            throw new ArgumentException("Image path is required.");
        }

        var images = await dbContext.ProductImages
            .Where(x => x.ProductId == parsedProductId)
            .ToListAsync(cancellationToken);

        var image = images.FirstOrDefault(x =>
            string.Equals(
                NormalizeAssetPath(x.ImagePath),
                normalizedPath,
                StringComparison.OrdinalIgnoreCase));

        if (image is null)
        {
            throw new KeyNotFoundException("Product image not found.");
        }

        return await DeleteImageAsync(
            image.Id,
            ownerId,
            webRootPath,
            allowAdminAccess: false,
            cancellationToken);
    }

    public async Task<string> DeleteVideoByPathAsync(
        string productId,
        string videoPath,
        string ownerId,
        string? webRootPath,
        bool allowAdminAccess,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var normalizedPath = NormalizeAssetPath(videoPath);
        if (string.IsNullOrWhiteSpace(normalizedPath))
        {
            throw new ArgumentException("Video path is required.");
        }

        var product = await dbContext.Products
            .Include(x => x.ProductVideos)
            .FirstOrDefaultAsync(x => x.ProductId == parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (!allowAdminAccess)
        {
            if (!Guid.TryParse(ownerId, out var parsedOwnerId)
                || product.OwnerId != parsedOwnerId)
            {
                throw new UnauthorizedAccessException("You can delete files only from your own product.");
            }
        }

        var primaryMatches = string.Equals(
            NormalizeAssetPath(product.VideoPath),
            normalizedPath,
            StringComparison.OrdinalIgnoreCase);

        var extraMatch = product.ProductVideos
            .FirstOrDefault(v =>
                string.Equals(
                    NormalizeAssetPath(v.VideoPath),
                    normalizedPath,
                    StringComparison.OrdinalIgnoreCase));

        if (!primaryMatches && extraMatch is null)
        {
            throw new KeyNotFoundException("Product video not found.");
        }

        if (!allowAdminAccess && ShouldTreatMediaChangeAsOwnerEdit(product))
        {
            await EnsurePendingEditSnapshotAsync(product, cancellationToken);
        }

        var pending = PendingProductChangeHelper.TryParse(product.PendingProductChanges);
        var keepFileForPendingEdit = PendingProductChangeHelper.PathExistsInSnapshot(pending, normalizedPath);

        if (primaryMatches)
        {
            var nextExtra = product.ProductVideos
                .OrderBy(v => v.Id)
                .FirstOrDefault();
            if (nextExtra is not null)
            {
                product.VideoPath = nextExtra.VideoPath;
                product.VideoDurationSeconds = nextExtra.VideoDurationSeconds;
                dbContext.ProductVideos.Remove(nextExtra);
            }
            else
            {
                product.VideoPath = null;
                product.VideoDurationSeconds = null;
            }
        }
        else if (extraMatch is not null)
        {
            dbContext.ProductVideos.Remove(extraMatch);
        }

        var markedAsEdit = false;
        if (!allowAdminAccess)
        {
            markedAsEdit = await MarkOwnerMediaChangedForReviewAsync(product, cancellationToken);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product.OwnerId);

        if (markedAsEdit)
        {
            QueueAdminProductEditAlert(parsedProductId);
        }

        if (!keepFileForPendingEdit)
        {
            await mediaStorage.DeleteAsync(normalizedPath, cancellationToken);
        }

        return "Video deleted successfully.";
    }

    private static string NormalizeAssetPath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return string.Empty;
        var value = path.Trim().Replace('\\', '/');
        // Strip absolute URL / host so we compare storage-relative paths.
        if (value.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || value.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                value = new Uri(value).AbsolutePath;
            }
            catch
            {
                // keep as-is
            }
        }

        var marker = "/product-images/";
        var idx = value.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
        if (idx >= 0)
        {
            value = value[idx..];
        }

        if (!value.StartsWith('/'))
        {
            value = "/" + value.TrimStart('/');
        }

        return value;
    }

    /// <summary>
    /// Media uploads during first-create (never approved, not yet submitted) are not owner edits.
    /// </summary>
    private static bool ShouldTreatMediaChangeAsOwnerEdit(Product product)
    {
        if (product.IsApproved == true)
        {
            return true;
        }

        // Already submitted once, or already carrying a real previous-approved snapshot.
        if (product.IsReadyForAdminReview
            || PendingProductChangeHelper.IndicatesPreviouslyApprovedEdit(product.PendingProductChanges))
        {
            return true;
        }

        return false;
    }

    private async Task EnsurePendingEditSnapshotAsync(
        Product product,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(product.PendingProductChanges))
        {
            return;
        }

        var existingImages = await dbContext.ProductImages
            .AsNoTracking()
            .Where(x => x.ProductId == product.ProductId)
            .OrderBy(x => x.Id)
            .Select(x => x.ImagePath)
            .ToListAsync(cancellationToken);
        var existingDocuments = await dbContext.ProductDocuments
            .AsNoTracking()
            .Where(x => x.ProductId == product.ProductId)
            .OrderBy(x => x.Id)
            .Select(x => x.DocumentPath)
            .ToListAsync(cancellationToken);
        var existingExtraVideos = await dbContext.ProductVideos
            .AsNoTracking()
            .Where(x => x.ProductId == product.ProductId)
            .OrderBy(x => x.Id)
            .Select(x => x.VideoPath)
            .ToListAsync(cancellationToken);

        var snapshot = PendingProductChangeHelper.Capture(
            product,
            existingImages,
            existingDocuments,
            existingExtraVideos);
        product.PendingProductChanges = PendingProductChangeHelper.Serialize(snapshot);
    }

    private async Task<bool> MarkOwnerMediaChangedForReviewAsync(
        Product product,
        CancellationToken cancellationToken)
    {
        if (!ShouldTreatMediaChangeAsOwnerEdit(product))
        {
            return false;
        }

        await EnsurePendingEditSnapshotAsync(product, cancellationToken);

        product.Status = ProductStatusCodes.UnderReview;
        product.IsApproved = false;
        product.DisplayExpiresAtUtc = null;
        product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        return true;
    }

    public async Task<object> UploadDocumentAsync(UploadProductDocumentInput input, CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await dbContext.Products.FindAsync([productId], cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        // DEV: التحقق من الملكية معطّل — أي مستخدم مسجّل يرفع على أي منتج.
        // PRODUCTION: أزل التعليق عن الكود التالي:
        /*
        if (!Guid.TryParse(input.OwnerId, out var ownerId))
        {
            throw new ArgumentException("Invalid owner id.");
        }

        await EnsureProductAssetAccessAsync(product, ownerId, input.AllowAdminAccess, cancellationToken);
        */

        var extension = Path.GetExtension(input.File.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".pdf";
        }

        var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var documentPath = await mediaStorage.SaveFormFileAsync(
            input.File,
            ProductDocumentsFolder,
            fileName,
            cancellationToken: cancellationToken);
        var entity = new ProductDocument
        {
            ProductId = productId,
            DocumentPath = documentPath
        };

        await dbContext.ProductDocuments.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product.OwnerId);

        return new { entity.Id, entity.ProductId, Path = entity.DocumentPath };
    }

    public async Task<object> UploadVideoAsync(
        UploadProductVideoInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (!input.VideoDurationSeconds.HasValue
            || input.VideoDurationSeconds.Value <= 0
            || input.VideoDurationSeconds.Value > 180)
        {
            throw new ArgumentException("VideoDurationSeconds must be between 1 and 180.");
        }

        var product = await dbContext.Products
            .Include(x => x.ProductVideos)
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        var existingCount = ProductVideoPathsHelper.ResolveAll(product).Count;
        if (existingCount >= ProductVideoPathsHelper.MaxProductVideos)
        {
            throw new InvalidOperationException(
                $"A product can have at most {ProductVideoPathsHelper.MaxProductVideos} videos.");
        }

        var extension = Path.GetExtension(input.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        var fileName = $"video-{Guid.NewGuid():N}{extension}";
        var videoPath = await mediaStorage.SaveFormFileAsync(
            input.File,
            "product-videos",
            fileName,
            cancellationToken: cancellationToken);
        if (string.IsNullOrWhiteSpace(product.VideoPath))
        {
            product.VideoPath = videoPath;
            product.VideoDurationSeconds = input.VideoDurationSeconds;
        }
        else
        {
            var entity = new ProductVideo
            {
                ProductId = productId,
                VideoPath = videoPath,
                VideoDurationSeconds = input.VideoDurationSeconds,
            };
            await dbContext.ProductVideos.AddAsync(entity, cancellationToken);
        }

        if (!input.AllowAdminAccess)
        {
            await MarkOwnerMediaChangedForReviewAsync(product, cancellationToken);
        }
        else
        {
            product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product.OwnerId);

        return new { path = videoPath };
    }

    public async Task<object> UploadOfferStagingImageAsync(
        UploadStagingAssetInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var fileName = $"{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            ProductImagesFolder,
            fileName,
            ImageCompressionOptions.ProductUploadFast,
            cancellationToken: cancellationToken);

        return new { path = imagePath };
    }

    public async Task<object> UploadOfferStagingDocumentAsync(
        UploadStagingAssetInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var extension = Path.GetExtension(input.File.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".pdf";
        }

        var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var documentPath = await mediaStorage.SaveFormFileAsync(
            input.File,
            ProductDocumentsFolder,
            fileName,
            cancellationToken: cancellationToken);
        return new { path = documentPath };
    }

    public async Task<object> UploadOfferStagingVideoAsync(
        UploadStagingAssetInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("File is required.");
        }

        var extension = Path.GetExtension(input.File.FileName).ToLowerInvariant();
        var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        var fileName = $"order-video-{Guid.NewGuid():N}{extension}";
        var videoPath = await mediaStorage.SaveFormFileAsync(
            input.File,
            "order-videos",
            fileName,
            cancellationToken: cancellationToken);
        return new { path = videoPath };
    }

    // PRODUCTION: أزل التعليق عن الدالة كاملة عند تفعيل التحقق من الملكية.
    /*
    private async Task EnsureProductAssetAccessAsync(
        Product product,
        Guid actorId,
        bool allowAdminAccess,
        CancellationToken cancellationToken)
    {
        if (allowAdminAccess)
        {
            var actor = await dbContext.Users.FindAsync([actorId], cancellationToken);
            if (actor?.RoleId == 1)
            {
                return;
            }
        }

        if (product.OwnerId is null)
        {
            throw new UnauthorizedAccessException(
                "This product has no owner assigned. Only the supplier who created it can upload files.");
        }

        if (product.OwnerId != actorId)
        {
            throw new UnauthorizedAccessException(
                "You can upload files only to your own product. Use the same supplier account that created this product.");
        }
    }
    */

    /// <summary>
    /// Best-effort admin edit alert (Notify* already pushes live counts).
    /// Off the upload/delete HTTP critical path.
    /// </summary>
    private void QueueAdminProductEditAlert(Product product)
    {
        QueueAdminProductEditAlert(product.ProductId, product.NameEn, product.ProductTypeId, product.CategoryId);
    }

    private void QueueAdminProductEditAlert(Guid productId)
    {
        QueueAdminProductEditAlert(productId, nameEn: null, productTypeId: null, categoryId: null);
    }

    private void QueueAdminProductEditAlert(
        Guid productId,
        string? nameEn,
        byte? productTypeId,
        byte? categoryId)
    {
        _ = Task.Run(async () =>
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            try
            {
                var notify = scope.ServiceProvider.GetRequiredService<IAdminRealtimeNotificationService>();
                Product snapshot;
                if (nameEn is null && productTypeId is null && categoryId is null)
                {
                    var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
                    snapshot = await db.Products.AsNoTracking()
                        .FirstOrDefaultAsync(x => x.ProductId == productId)
                        ?? new Product { ProductId = productId };
                }
                else
                {
                    snapshot = new Product
                    {
                        ProductId = productId,
                        NameEn = nameEn,
                        ProductTypeId = productTypeId,
                        CategoryId = categoryId
                    };
                }

                await notify.NotifyProductEditAsync(snapshot);
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Background admin realtime notification failed for product {ProductId}",
                    productId);
            }
        });
    }

    /// <summary>Fire-and-forget enqueue - never await CLIP/Qdrant on the request thread.</summary>
    private void QueueImageIndexing(long productImageId)
    {
        _ = productImageIndexingQueue.EnqueueAsync(productImageId, CancellationToken.None);
    }
}
