using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed class ClipReferenceImageAppService(
    IRasAlSouqDbContext dbContext,
    IMediaStorageService mediaStorage,
    IImageEmbeddingService imageEmbeddingService,
    IProductImageVectorIndex productImageVectorIndex,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    ILogger<ClipReferenceImageAppService> logger) : IClipReferenceImageAppService
{
    private const string StorageFolder = "product-images/clip-reference";
    private const int MaxBatchFiles = 30;
    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

    private readonly ImageEmbeddingOptions _embeddingOptions = embeddingOptions.Value;

    public async Task<AdminClipReferenceImagesPageDto> GetReferenceImagesAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var query = dbContext.ClipReferenceImages.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(x =>
                x.ProductName.Contains(term)
                || (x.ProductNameAr != null && x.ProductNameAr.Contains(term))
                || (x.ProductCode != null && x.ProductCode.Contains(term)));
        }

        var total = await query.CountAsync(cancellationToken).ConfigureAwait(false);
        var items = await query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new ClipReferenceImageListItemDto
            {
                Id = x.Id,
                ProductName = x.ProductName,
                ProductNameAr = x.ProductNameAr,
                ProductCode = x.ProductCode,
                ImagePath = x.ImagePath,
                CreatedAtUtc = x.CreatedAtUtc,
            })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        return new AdminClipReferenceImagesPageDto
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = total,
            TotalPages = Math.Max(1, (int)Math.Ceiling(total / (double)pageSize)),
            Items = items,
        };
    }

    public async Task<object> UploadReferenceImagesAsync(
        string productName,
        string? productNameAr,
        string? productCode,
        IReadOnlyList<IFormFile> files,
        Guid? adminUserId,
        CancellationToken cancellationToken = default)
    {
        productName = productName?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(productName))
        {
            throw new ArgumentException("Product name is required.");
        }

        if (files is null || files.Count == 0)
        {
            throw new ArgumentException("At least one image file is required.");
        }

        if (files.Count > MaxBatchFiles)
        {
            throw new ArgumentException($"You can upload at most {MaxBatchFiles} images at once.");
        }

        var created = new List<object>();
        foreach (var file in files)
        {
            if (file is null || file.Length == 0)
            {
                continue;
            }

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!AllowedExtensions.Contains(extension))
            {
                throw new ArgumentException(
                    $"Unsupported image format: {file.FileName}. Allowed: .jpg, .jpeg, .png, .webp");
            }

            var imagePath = await mediaStorage
                .SaveCompressedJpegAsync(file, StorageFolder, cancellationToken: cancellationToken)
                .ConfigureAwait(false);

            var entity = new ClipReferenceImage
            {
                ProductName = productName,
                ProductNameAr = string.IsNullOrWhiteSpace(productNameAr) ? null : productNameAr.Trim(),
                ProductCode = string.IsNullOrWhiteSpace(productCode) ? null : productCode.Trim(),
                ImagePath = imagePath,
                CreatedByAdminUserId = adminUserId,
            };

            await dbContext.ClipReferenceImages.AddAsync(entity, cancellationToken).ConfigureAwait(false);
            await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

            await IndexReferenceImageAsync(entity.Id, cancellationToken).ConfigureAwait(false);

            created.Add(new
            {
                entity.Id,
                entity.ProductName,
                path = entity.ImagePath,
            });
        }

        if (created.Count == 0)
        {
            throw new ArgumentException("No valid image files were uploaded.");
        }

        logger.LogInformation(
            "Admin uploaded {Count} CLIP reference images for {ProductName}.",
            created.Count,
            productName);

        return new
        {
            productName,
            uploaded = created.Count,
            items = created,
        };
    }

    public async Task<object> DeleteReferenceImageAsync(long id, CancellationToken cancellationToken = default)
    {
        var row = await dbContext.ClipReferenceImages
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken)
            .ConfigureAwait(false)
            ?? throw new KeyNotFoundException("Reference image not found.");

        var path = row.ImagePath;
        dbContext.ClipReferenceImages.Remove(row);
        await dbContext.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        if (_embeddingOptions.Enabled)
        {
            await productImageVectorIndex
                .DeleteByProductImageIdAsync(ClipVectorIds.ToReferencePointId(id), cancellationToken)
                .ConfigureAwait(false);
        }

        await mediaStorage.DeleteAsync(path, cancellationToken).ConfigureAwait(false);

        return new { message = "Reference image deleted.", id };
    }

    public async Task<object> ReindexReferenceImagesAsync(CancellationToken cancellationToken = default)
    {
        var ids = await dbContext.ClipReferenceImages
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        foreach (var id in ids)
        {
            await IndexReferenceImageAsync(id, cancellationToken).ConfigureAwait(false);
        }

        logger.LogInformation("Reindexed {Count} CLIP reference images.", ids.Count);
        return new
        {
            enqueued = ids.Count,
            message = "Reference images reindexed in Qdrant.",
        };
    }

    public async Task IndexReferenceImageAsync(long referenceImageId, CancellationToken cancellationToken = default)
    {
        if (!_embeddingOptions.Enabled)
        {
            return;
        }

        var row = await dbContext.ClipReferenceImages
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == referenceImageId, cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
        {
            return;
        }

        try
        {
            await using var stream = await mediaStorage
                .OpenReadAsync(row.ImagePath, cancellationToken)
                .ConfigureAwait(false);
            if (stream is null)
            {
                logger.LogWarning("Skip CLIP reference index — file missing for {Id} at {Path}.", row.Id, row.ImagePath);
                return;
            }

            var vector = await imageEmbeddingService
                .EmbedImageAsync(stream, Path.GetFileName(row.ImagePath), cancellationToken: cancellationToken)
                .ConfigureAwait(false);
            if (vector is null || vector.Length == 0)
            {
                return;
            }

            var pointId = ClipVectorIds.ToReferencePointId(row.Id);
            await productImageVectorIndex.UpsertAsync(
                new ProductImageVectorPoint
                {
                    ProductImageId = pointId,
                    ProductId = ClipVectorIds.ReferenceProductId,
                    ProductCode = row.ProductCode ?? string.Empty,
                    ProductName = row.ProductName,
                    ImagePath = row.ImagePath,
                    Vector = vector,
                    IsReference = true,
                    ReferenceImageId = row.Id,
                },
                cancellationToken).ConfigureAwait(false);

            logger.LogInformation("CLIP-indexed reference image {Id} ({Name}).", row.Id, row.ProductName);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed indexing CLIP reference image {Id}.", referenceImageId);
        }
    }
}
