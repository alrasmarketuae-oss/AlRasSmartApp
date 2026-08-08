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
/// - video present → leave for admin dashboard only (no auto-reject, no auto-approve, no notify)
/// - no video + text/image violations → auto-reject + notify
/// - no video + clean → auto-approve + notify (then CLIP)
/// - seller edits/resubmits → same scan again
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
    private static readonly string RejectReasonEn = AutoModerationMessages.RejectReasonEn;

    private static readonly string RejectReasonAr = AutoModerationMessages.RejectReasonAr;

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
                "Product {ProductId} text policy violations: {Hits}",
                workItem.ProductId,
                string.Join(", ", textHits.Select(h => $"{h.Kind}:{h.Sample}")));
            await RejectAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
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
                    "Product {ProductId} LLM text policy violations: {Kinds} ({Summary})",
                    workItem.ProductId,
                    string.Join("|", textLlm.ViolationKinds),
                    textLlm.Summary);
                await RejectAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
                return;
            }
        }

        var imageScan = await ScanImagesAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
        if (imageScan.Hits.Count > 0)
        {
            logger.LogInformation(
                "Product {ProductId} image policy violations: {Hits}",
                workItem.ProductId,
                string.Join(", ", imageScan.Hits));
            await RejectAsync(workItem.ProductId, cancellationToken).ConfigureAwait(false);
            return;
        }

        if (imageScan.Attempted > 0 && imageScan.Succeeded == 0)
        {
            logger.LogWarning(
                "Product {ProductId} image scans all failed — leaving for manual admin review.",
                workItem.ProductId);
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

    private async Task RejectAsync(
        Guid productId,
        CancellationToken cancellationToken) =>
        await RejectAsync(productId, RejectReasonEn, RejectReasonAr, cancellationToken)
            .ConfigureAwait(false);

    private async Task RejectAsync(
        Guid productId,
        string reasonEn,
        string reasonAr,
        CancellationToken cancellationToken)
    {
        try
        {
            await adminProducts.RejectProductAsync(
                    productId.ToString("D"),
                    new AdminRejectProductRequest
                    {
                        SupplierNotesEn = reasonEn,
                        SupplierNotesAr = reasonAr
                    },
                    cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-reject failed for {ProductId} — leaving for admin.", productId);
            await QueueClipAsync(productId, cancellationToken).ConfigureAwait(false);
        }
    }

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

    private sealed record ImageScanResult(List<string> Hits, int Attempted, int Succeeded);

    private async Task<ImageScanResult> ScanImagesAsync(Guid productId, CancellationToken cancellationToken)
    {
        var hits = new List<string>();
        var attempted = 0;
        var succeeded = 0;
        var images = await productData.GetProductImagePathsByProductIdsAsync([productId], cancellationToken)
            .ConfigureAwait(false);

        var max = options.Value.MaxImagesToScan;
        var toScan = max > 0 ? images.Take(max) : images;
        foreach (var image in toScan)
        {
            if (string.IsNullOrWhiteSpace(image.Path))
            {
                continue;
            }

            await using var stream = await fileStorage.OpenReadAsync(image.Path, cancellationToken)
                .ConfigureAwait(false);
            if (stream is null)
            {
                continue;
            }

            attempted++;
            AdImagePolicyScanResult result;
            try
            {
                result = await openAiVision.ScanAdImageForPolicyViolationsAsync(
                        stream,
                        Path.GetFileName(image.Path),
                        cancellationToken)
                    .ConfigureAwait(false);
                succeeded++;
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Vision scan failed for image {Path} on {ProductId}", image.Path, productId);
                continue;
            }

            if (!result.HasViolation)
            {
                continue;
            }

            var kinds = result.ViolationKinds.Count > 0
                ? string.Join("|", result.ViolationKinds)
                : "policy";
            hits.Add($"{image.Path}:{kinds}");
        }

        return new ImageScanResult(hits, attempted, succeeded);
    }

    private async Task QueueClipAsync(Guid productId, CancellationToken cancellationToken)
    {
        if (!imageEmbeddingOptions.Value.Enabled)
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
