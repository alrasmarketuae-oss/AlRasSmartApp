using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public interface IProductAutoModerationService
{
    Task ProcessAsync(ProductAutoModerationWorkItem workItem, CancellationToken cancellationToken = default);
}

/// <summary>
/// Background ad review (all product types: Offers, Requests, Booking, Category/Retail):
/// - any violation (text, image, video) → leave for admin dashboard only (under review)
/// - scan failure / incomplete image scan → admin dashboard only
/// - no video + clean text and images → auto-approve + notify (then CLIP)
/// - seller edits/resubmits → same scan again
/// Never auto-rejects — admin decides on flagged ads.
/// </summary>
public sealed class ProductAutoModerationService(
    IRasAlSouqDbContext dbContext,
    IProductDataAccess productData,
    IFileStorage fileStorage,
    IOpenAiVisionService openAiVision,
    IAdminProductsAppService adminProducts,
    IProductImageIndexingQueue imageIndexingQueue,
    IOptions<AdAutoModerationOptions> options,
    IOptions<ImageEmbeddingOptions> imageEmbeddingOptions,
    ILogger<ProductAutoModerationService> logger) : IProductAutoModerationService
{
    public async Task ProcessAsync(ProductAutoModerationWorkItem workItem, CancellationToken cancellationToken = default)
    {
        var product = await dbContext.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ProductId == workItem.ProductId, cancellationToken)
            .ConfigureAwait(false);

        if (product is null)
        {
            logger.LogWarning("Auto-moderation skipped — product {ProductId} not found.", workItem.ProductId);
            return;
        }

        if (product.IsApproved == true && product.Status == ProductStatusCodes.Active)
        {
            await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        if (!product.IsReadyForAdminReview)
        {
            logger.LogInformation(
                "Auto-moderation skipped — product {ProductId} not ready for review yet.",
                workItem.ProductId);
            return;
        }

        if (!options.Value.Enabled || workItem.RequireManualReview)
        {
            logger.LogInformation(
                "Product {ProductId} left for manual admin review (enabled={Enabled}, requireManual={Manual}).",
                workItem.ProductId,
                options.Value.Enabled,
                workItem.RequireManualReview);
            await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        // Video cannot be Vision-scanned: never auto-reject / auto-approve / notify.
        // Leave the ad (with video) for admin dashboard review only.
        if (await HasVideoAsync(workItem.ProductId, product, cancellationToken).ConfigureAwait(false))
        {
            logger.LogInformation(
                "Product {ProductId} (type={ProductTypeId}, category={CategoryId}) has video — " +
                "left for admin dashboard only (no auto-reject/approve/notify).",
                workItem.ProductId,
                product.ProductTypeId,
                product.CategoryId);
            await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        var textFields = await LoadAdTextFieldsForPolicyScanAsync(product, cancellationToken)
            .ConfigureAwait(false);

        if (string.IsNullOrWhiteSpace(textFields.TitlePrimary)
            && string.IsNullOrWhiteSpace(textFields.TitleSecondary))
        {
            logger.LogWarning(
                "Product {ProductId} has empty ad title — leaving for manual admin review.",
                workItem.ProductId);
            await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        var textHits = AdContactPolicyScanner.Scan(textFields.AllParts);
        if (textHits.Count > 0)
        {
            logger.LogInformation(
                "Product {ProductId} text policy violations: {Hits} — left for admin dashboard review.",
                workItem.ProductId,
                string.Join(", ", textHits.Select(h => $"{h.Kind}:{h.Sample}")));
            await LeaveForAdminReviewAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        var combinedText = textFields.ToLabeledCombinedText();
        if (!string.IsNullOrWhiteSpace(combinedText))
        {
            AdTextPolicyScanResult textLlm;
            try
            {
                textLlm = await openAiVision.ScanAdTextForPolicyViolationsAsync(combinedText, cancellationToken)
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Text policy scan threw for {ProductId} — leaving for admin.", workItem.ProductId);
                await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
                return;
            }

            if (string.Equals(textLlm.Summary, "scan_failed", StringComparison.OrdinalIgnoreCase))
            {
                logger.LogWarning(
                    "Text policy scan failed for {ProductId} — leaving for manual admin review.",
                    workItem.ProductId);
                await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
                return;
            }

            if (textLlm.HasViolation)
            {
                logger.LogInformation(
                    "Product {ProductId} LLM text policy violations: {Kinds} ({Summary}) — left for admin dashboard review.",
                    workItem.ProductId,
                    string.Join("|", textLlm.ViolationKinds),
                    textLlm.Summary);
                await LeaveForAdminReviewAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
                return;
            }
        }

        var imageScan = await ScanImagesAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
        if (imageScan.Hits.Count > 0)
        {
            logger.LogInformation(
                "Product {ProductId} image policy violations: {Hits} — left for admin dashboard review.",
                workItem.ProductId,
                string.Join(", ", imageScan.Hits));
            await LeaveForAdminReviewAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        if (imageScan.Listed > 0 && imageScan.Succeeded < imageScan.Listed)
        {
            logger.LogWarning(
                "Product {ProductId} image scan incomplete ({Succeeded}/{Listed}) — leaving for admin.",
                workItem.ProductId,
                imageScan.Succeeded,
                imageScan.Listed);
            await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        try
        {
            await adminProducts.ApproveProductAsync(
                    workItem.ProductId.ToString("D"),
                    new AdminRejectProductRequest(),
                    cancellationToken)
                .ConfigureAwait(false);

            logger.LogInformation(
                "Product {ProductId} (type={ProductTypeId}, category={CategoryId}) auto-approved after policy scan.",
                workItem.ProductId,
                product.ProductTypeId,
                product.CategoryId);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-approve failed for {ProductId} — leaving for admin.", workItem.ProductId);
        }

        await QueueClipAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
    }

    /// <summary>
    /// Keeps the ad under admin review (no auto-reject, no auto-approve, no seller notify).
    /// </summary>
    private Task LeaveForAdminReviewAsync(Guid productId, CancellationToken cancellationToken) =>
        QueueClipAsync(productId, cancellationToken);

    /// <summary>
    /// Loads live product title + specs (including bilingual ContentTranslations)
    /// so create and edit resubmits both scan the actual ad name the seller submitted.
    /// </summary>
    private async Task<AdTextFieldsForScan> LoadAdTextFieldsForPolicyScanAsync(
        Product product,
        CancellationToken cancellationToken)
    {
        var translations = await dbContext.ContentTranslations
            .AsNoTracking()
            .Where(x =>
                x.Scope == ContentTranslationScopes.Product
                && x.ProductId == product.ProductId
                && (x.Field == ContentTranslationFields.Name
                    || x.Field == ContentTranslationFields.Description
                    || x.Field == ContentTranslationFields.RetailDescription
                    || x.Field == ContentTranslationFields.ShippingDescription))
            .ToListAsync(cancellationToken)
            .ConfigureAwait(false);

        string? FieldEn(string field) =>
            translations.FirstOrDefault(x => x.Field == field)?.TextEn;
        string? FieldAr(string field) =>
            translations.FirstOrDefault(x => x.Field == field)?.TextAr;

        // Prefer the live Products.NameEn (create + latest edit), then bilingual store.
        var titlePrimary = FirstNonEmpty(product.NameEn, FieldEn(ContentTranslationFields.Name));
        var titleSecondary = DistinctFrom(
            FieldAr(ContentTranslationFields.Name),
            titlePrimary);

        var descriptionPrimary = FirstNonEmpty(
            product.DescriptionEn,
            FieldEn(ContentTranslationFields.Description));
        var descriptionSecondary = DistinctFrom(
            FieldAr(ContentTranslationFields.Description),
            descriptionPrimary);

        var retailPrimary = FirstNonEmpty(
            product.RetailDescriptionEn,
            FieldEn(ContentTranslationFields.RetailDescription));
        var retailSecondary = DistinctFrom(
            FieldAr(ContentTranslationFields.RetailDescription),
            retailPrimary);

        var shippingPrimary = FirstNonEmpty(
            product.ShippingDescriptionEn,
            FieldEn(ContentTranslationFields.ShippingDescription));
        var shippingSecondary = DistinctFrom(
            FieldAr(ContentTranslationFields.ShippingDescription),
            shippingPrimary);

        return new AdTextFieldsForScan(
            titlePrimary,
            titleSecondary,
            descriptionPrimary,
            descriptionSecondary,
            retailPrimary,
            retailSecondary,
            shippingPrimary,
            shippingSecondary,
            product.PackagingDetails,
            product.RetailPackagingDetails);
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

    private static string? DistinctFrom(string? candidate, string? alreadyIncluded)
    {
        if (string.IsNullOrWhiteSpace(candidate))
        {
            return null;
        }

        var trimmed = candidate.Trim();
        if (!string.IsNullOrWhiteSpace(alreadyIncluded)
            && string.Equals(trimmed, alreadyIncluded.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return trimmed;
    }

    private sealed record AdTextFieldsForScan(
        string? TitlePrimary,
        string? TitleSecondary,
        string? DescriptionPrimary,
        string? DescriptionSecondary,
        string? RetailPrimary,
        string? RetailSecondary,
        string? ShippingPrimary,
        string? ShippingSecondary,
        string? PackagingDetails,
        string? RetailPackagingDetails)
    {
        public string?[] AllParts =>
        [
            TitlePrimary,
            TitleSecondary,
            DescriptionPrimary,
            DescriptionSecondary,
            RetailPrimary,
            RetailSecondary,
            ShippingPrimary,
            ShippingSecondary,
            PackagingDetails,
            RetailPackagingDetails
        ];

        public string ToLabeledCombinedText()
        {
            var lines = new List<string>(12);
            void Add(string label, string? value)
            {
                if (!string.IsNullOrWhiteSpace(value))
                {
                    lines.Add($"{label}: {value.Trim()}");
                }
            }

            // Title first — create and edit must always verify the ad name.
            Add("Ad title", TitlePrimary);
            Add("Ad title (alt language)", TitleSecondary);
            Add("Specifications", DescriptionPrimary);
            Add("Specifications (alt language)", DescriptionSecondary);
            Add("Retail specifications", RetailPrimary);
            Add("Retail specifications (alt language)", RetailSecondary);
            Add("Shipping notes", ShippingPrimary);
            Add("Shipping notes (alt language)", ShippingSecondary);
            Add("Packaging details", PackagingDetails);
            Add("Retail packaging details", RetailPackagingDetails);
            return string.Join("\n", lines);
        }
    }

    private async Task<bool> HasVideoAsync(Guid productId, Product product, CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(product.VideoPath))
        {
            return true;
        }

        var videos = await productData.GetProductVideoPathsByProductIdsAsync([productId], cancellationToken)
            .ConfigureAwait(false);
        return videos.Exists(v => !string.IsNullOrWhiteSpace(v.Path));
    }

    private sealed record ImageScanResult(List<string> Hits, List<string> Kinds, int Listed, int Succeeded);

    private async Task<ImageScanResult> ScanImagesAsync(Guid productId, CancellationToken cancellationToken)
    {
        var hits = new List<string>();
        var kindSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var succeeded = 0;
        var images = await productData.GetProductImagePathsByProductIdsAsync([productId], cancellationToken)
            .ConfigureAwait(false);

        var max = options.Value.MaxImagesToScan;
        var toScan = (max > 0 ? images.Take(max) : images)
            .Where(image => !string.IsNullOrWhiteSpace(image.Path))
            .ToList();
        var listed = toScan.Count;

        foreach (var image in toScan)
        {
            await using var stream = await fileStorage.OpenReadAsync(image.Path, cancellationToken)
                .ConfigureAwait(false);
            if (stream is null)
            {
                logger.LogWarning(
                    "Product {ProductId} image {Path} could not be opened — treating as scan failure.",
                    productId,
                    image.Path);
                continue;
            }

            AdImagePolicyScanResult result;
            try
            {
                result = await openAiVision.ScanAdImageForPolicyViolationsAsync(
                        stream,
                        Path.GetFileName(image.Path),
                        cancellationToken)
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Vision scan failed for image {Path} on {ProductId}", image.Path, productId);
                continue;
            }

            if (result.ScanFailed)
            {
                logger.LogWarning(
                    "Product {ProductId} image {Path} policy scan failed ({Summary}).",
                    productId,
                    image.Path,
                    result.Summary);
                continue;
            }

            succeeded++;
            if (!result.HasViolation)
            {
                continue;
            }

            foreach (var kind in result.ViolationKinds)
            {
                if (!string.IsNullOrWhiteSpace(kind))
                {
                    kindSet.Add(kind.Trim());
                }
            }

            var kinds = result.ViolationKinds.Count > 0
                ? string.Join("|", result.ViolationKinds)
                : "policy";
            hits.Add($"{image.Path}:{kinds}");
        }

        return new ImageScanResult(hits, kindSet.ToList(), listed, succeeded);
    }

    private async Task QueueClipAsync(Guid productId, CancellationToken cancellationToken)
    {
        if (!ImageEmbeddingIndexingGate.ShouldAutoIndexOnCatalogChange(imageEmbeddingOptions.Value))
        {
            return;
        }

        try
        {
            var imageIds = await productData.GetProductImageIdsByProductIdAsync(productId).ConfigureAwait(false);
            foreach (var imageId in imageIds)
            {
                await imageIndexingQueue.EnqueueAsync(imageId, cancellationToken).ConfigureAwait(false);
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "CLIP enqueue after moderation failed for {ProductId}", productId);
        }
    }
}
