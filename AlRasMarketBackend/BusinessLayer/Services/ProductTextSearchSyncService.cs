using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

/// <summary>
/// Builds Meilisearch documents from SQL and keeps the text index in sync.
/// Does not change the public search response shape — SQL remains the source of truth for payloads.
/// </summary>
public sealed class ProductTextSearchSyncService(
    IProductDataAccess productData,
    IRasAlSouqDbContext dbContext,
    IProductTextSearchIndex textSearchIndex,
    ILogger<ProductTextSearchSyncService> logger)
{
    public async Task UpsertProductAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        if (!textSearchIndex.IsEnabled)
        {
            return;
        }

        try
        {
            var document = await BuildDocumentAsync(productId, cancellationToken).ConfigureAwait(false);
            if (document is null || !document.IsPublic)
            {
                await textSearchIndex.DeleteAsync(productId, cancellationToken).ConfigureAwait(false);
                return;
            }

            await textSearchIndex.UpsertAsync(document, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed syncing product {ProductId} to Meilisearch", productId);
        }
    }

    public async Task DeleteProductAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        if (!textSearchIndex.IsEnabled)
        {
            return;
        }

        try
        {
            await textSearchIndex.DeleteAsync(productId, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed deleting product {ProductId} from Meilisearch", productId);
        }
    }

    public async Task ReindexAllPublicAsync(CancellationToken cancellationToken = default)
    {
        if (!textSearchIndex.IsEnabled)
        {
            return;
        }

        await textSearchIndex.EnsureIndexAsync(cancellationToken).ConfigureAwait(false);

        const int batchSize = 200;
        var skip = 0;
        var total = 0;

        while (true)
        {
            var ids = await ProductQueryHelpers.ApplyPublicProductFilter(dbContext.Products.AsNoTracking())
                .OrderByDescending(x => x.CreatedAt)
                .Skip(skip)
                .Take(batchSize)
                .Select(x => x.ProductId)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            if (ids.Count == 0)
            {
                break;
            }

            var docs = new List<ProductTextSearchDocument>(ids.Count);
            foreach (var id in ids)
            {
                var doc = await BuildDocumentAsync(id, cancellationToken).ConfigureAwait(false);
                if (doc is { IsPublic: true })
                {
                    docs.Add(doc);
                }
            }

            if (docs.Count > 0)
            {
                await textSearchIndex.UpsertManyAsync(docs, cancellationToken).ConfigureAwait(false);
                total += docs.Count;
            }

            skip += batchSize;
            if (ids.Count < batchSize)
            {
                break;
            }
        }

        logger.LogInformation("Meilisearch full reindex finished ({Count} public products)", total);
        _ = productData;
    }

    private async Task<ProductTextSearchDocument?> BuildDocumentAsync(
        Guid productId,
        CancellationToken cancellationToken)
    {
        var row = await dbContext.Products.AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => new
            {
                x.ProductId,
                x.ProductCode,
                x.NameEn,
                x.DescriptionEn,
                x.RetailDescriptionEn,
                x.SupplierNotesEn,
                x.ShippingDescriptionEn,
                x.CreatedAt,
                x.Status,
                x.IsApproved,
                x.DisplayExpiresAtUtc,
                x.ProductTypeId,
                x.Quantity,
                CategoryNameEn = x.Category != null ? x.Category.NameEn : null,
                CategoryNameAr = x.Category != null ? x.Category.NameAr : null,
                ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : null
            })
            .FirstOrDefaultAsync(cancellationToken)
            .ConfigureAwait(false);

        if (row is null)
        {
            return null;
        }

        var utcNow = DateTime.UtcNow;
        var isPublic =
            (row.Status == ProductCatalogCodes.StatusActive
                || (row.Status == ProductCatalogCodes.StatusUnderReview && row.IsApproved == true))
            && (row.DisplayExpiresAtUtc == null || row.DisplayExpiresAtUtc > utcNow)
            && (row.ProductTypeId != ProductCatalogCodes.TypeRequests || row.Quantity > 0);

        var translations = await dbContext.ContentTranslations.AsNoTracking()
            .Where(t =>
                t.Scope == ContentTranslationScopes.Product
                && t.ProductId == productId
                && (t.Field == ContentTranslationFields.Name
                    || t.Field == ContentTranslationFields.Description
                    || t.Field == ContentTranslationFields.RetailDescription
                    || t.Field == ContentTranslationFields.SupplierNotes
                    || t.Field == ContentTranslationFields.ShippingDescription))
            .Select(t => new { t.Field, t.TextAr, t.TextEn })
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        string? FieldAr(string field) =>
            translations.FirstOrDefault(t => t.Field == field)?.TextAr;
        string? FieldEn(string field) =>
            translations.FirstOrDefault(t => t.Field == field)?.TextEn;

        var nameAr = FieldAr(ContentTranslationFields.Name);
        var nameEn = FirstNonEmpty(row.NameEn, FieldEn(ContentTranslationFields.Name));

        var suggest = new List<string>();
        void AddSuggest(string? value)
        {
            var v = value?.Trim();
            if (!string.IsNullOrWhiteSpace(v)
                && !suggest.Contains(v, StringComparer.OrdinalIgnoreCase))
            {
                suggest.Add(v);
            }
        }

        AddSuggest(nameEn);
        AddSuggest(nameAr);
        AddSuggest(row.ProductCode);

        return new ProductTextSearchDocument
        {
            ProductId = row.ProductId,
            ProductCode = row.ProductCode?.Trim(),
            NameEn = nameEn,
            NameAr = nameAr?.Trim(),
            CategoryNameEn = row.CategoryNameEn?.Trim(),
            CategoryNameAr = row.CategoryNameAr?.Trim(),
            ProductTypeName = row.ProductTypeName?.Trim(),
            DescriptionEn = FirstNonEmpty(row.DescriptionEn, FieldEn(ContentTranslationFields.Description)),
            DescriptionAr = FieldAr(ContentTranslationFields.Description)?.Trim(),
            RetailDescriptionEn = FirstNonEmpty(
                row.RetailDescriptionEn,
                FieldEn(ContentTranslationFields.RetailDescription)),
            RetailDescriptionAr = FieldAr(ContentTranslationFields.RetailDescription)?.Trim(),
            SupplierNotesEn = FirstNonEmpty(row.SupplierNotesEn, FieldEn(ContentTranslationFields.SupplierNotes)),
            SupplierNotesAr = FieldAr(ContentTranslationFields.SupplierNotes)?.Trim(),
            ShippingDescriptionEn = FirstNonEmpty(
                row.ShippingDescriptionEn,
                FieldEn(ContentTranslationFields.ShippingDescription)),
            ShippingDescriptionAr = FieldAr(ContentTranslationFields.ShippingDescription)?.Trim(),
            SuggestLabels = suggest,
            CreatedAtUnix = new DateTimeOffset(
                DateTime.SpecifyKind(row.CreatedAt, DateTimeKind.Utc)).ToUnixTimeSeconds(),
            IsPublic = isPublic
        };
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return null;
    }
}

/// <summary>Ensures Meilisearch index exists and bootstraps documents when empty.</summary>
public sealed class ProductTextSearchBootstrapHostedService(
    IServiceScopeFactory scopeFactory,
    IProductTextSearchIndex textSearchIndex,
    IOptions<MeilisearchOptions> options,
    ILogger<ProductTextSearchBootstrapHostedService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!textSearchIndex.IsEnabled || !options.Value.BootstrapOnStartup)
        {
            return;
        }

        // Meili may start after the API (compose --no-deps / first boot). Retry a few times.
        const int maxAttempts = 8;
        for (var attempt = 1; attempt <= maxAttempts && !stoppingToken.IsCancellationRequested; attempt++)
        {
            try
            {
                await Task.Delay(TimeSpan.FromSeconds(attempt == 1 ? 5 : 10), stoppingToken)
                    .ConfigureAwait(false);

                await textSearchIndex.EnsureIndexAsync(stoppingToken).ConfigureAwait(false);
                var count = await textSearchIndex.GetDocumentCountAsync(stoppingToken).ConfigureAwait(false);
                if (count > 0)
                {
                    logger.LogInformation(
                        "Meilisearch already has {Count} documents — skip bootstrap reindex",
                        count);
                    return;
                }

                await using var scope = scopeFactory.CreateAsyncScope();
                var sync = scope.ServiceProvider.GetRequiredService<ProductTextSearchSyncService>();
                await sync.ReindexAllPublicAsync(stoppingToken).ConfigureAwait(false);
                return;
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Meilisearch bootstrap attempt {Attempt}/{Max} failed",
                    attempt,
                    maxAttempts);
            }
        }

        logger.LogWarning("Meilisearch bootstrap reindex gave up — SQL search remains available");
    }
}
