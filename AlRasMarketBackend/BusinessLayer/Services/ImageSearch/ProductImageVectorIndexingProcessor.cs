using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.ImageSearch;

public sealed class ProductImageVectorIndexingProcessor(
    IRasAlSouqDbContext dbContext,
    IMediaStorageService mediaStorage,
    IImageEmbeddingService imageEmbeddingService,
    IProductImageVectorIndex productImageVectorIndex,
    IOptions<ImageEmbeddingOptions> embeddingOptions,
    ILogger<ProductImageVectorIndexingProcessor> logger) : IProductImageVectorIndexingProcessor
{
    private readonly ImageEmbeddingOptions _options = embeddingOptions.Value;

    public async Task IndexProductImageAsync(long productImageId, CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            return;
        }

        var row = await dbContext.ProductImages
            .AsNoTracking()
            .Where(x => x.Id == productImageId)
            .Select(x => new
            {
                x.Id,
                x.ImagePath,
                x.ProductId,
                ProductCode = x.Product!.ProductCode ?? string.Empty,
                ProductName = x.Product!.NameEn ?? string.Empty,
                Description = x.Product!.DescriptionEn ?? string.Empty,
                RetailDescription = x.Product!.RetailDescriptionEn ?? string.Empty,
                Packaging = x.Product!.Packaging,
                PackagingDetails = x.Product!.PackagingDetails ?? x.Product!.RetailPackagingDetails ?? string.Empty,
                SupplierNotes = x.Product!.SupplierNotesEn ?? string.Empty,
                CategoryName = x.Product!.Category != null ? x.Product.Category.NameEn : string.Empty,
                ProductTypeName = x.Product!.ProductType != null ? x.Product.ProductType.TypeNameEn : string.Empty,
            })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
        {
            logger.LogDebug("Skip indexing — product image {ImageId} no longer exists.", productImageId);
            return;
        }

        var nameAr = await dbContext.ContentTranslations
            .AsNoTracking()
            .Where(t =>
                t.ProductId == row.ProductId
                && t.Scope == ContentTranslationScopes.Product
                && t.Field == ContentTranslationFields.Name
                && t.TextAr != null
                && t.TextAr != string.Empty)
            .Select(t => t.TextAr)
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        try
        {
            await using var stream = await mediaStorage
                .OpenReadAsync(row.ImagePath, cancellationToken)
                .ConfigureAwait(false);
            if (stream is null)
            {
                logger.LogWarning("Skip indexing — image file missing for {ImageId} at {Path}.", row.Id, row.ImagePath);
                return;
            }

            var packagingLabel = row.Packaging.HasValue
                ? row.Packaging.Value.ToString()
                : null;

            var catalogContext = new ProductImageEmbedContext
            {
                ProductName = row.ProductName,
                ProductNameAr = nameAr,
                ProductCode = row.ProductCode,
                Description = row.Description,
                RetailDescription = row.RetailDescription,
                Packaging = packagingLabel,
                PackagingDetails = row.PackagingDetails,
                CategoryName = row.CategoryName,
                ProductTypeName = row.ProductTypeName,
                SupplierNotes = row.SupplierNotes,
            };

            var vector = await imageEmbeddingService
                .EmbedImageAsync(
                    stream,
                    Path.GetFileName(row.ImagePath),
                    catalogContext,
                    cancellationToken)
                .ConfigureAwait(false);
            if (vector is null || vector.Length == 0)
            {
                return;
            }

            await productImageVectorIndex.UpsertAsync(
                new ProductImageVectorPoint
                {
                    ProductImageId = row.Id,
                    ProductId = row.ProductId,
                    ProductCode = row.ProductCode,
                    ProductName = row.ProductName,
                    ImagePath = row.ImagePath,
                    Vector = vector
                },
                cancellationToken).ConfigureAwait(false);

            logger.LogInformation(
                "CLIP-indexed product image {ImageId} for product {ProductId} (dim={Dim}).",
                row.Id,
                row.ProductId,
                vector.Length);
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed indexing product image {ImageId} for vector search.",
                productImageId);
        }
    }
}
