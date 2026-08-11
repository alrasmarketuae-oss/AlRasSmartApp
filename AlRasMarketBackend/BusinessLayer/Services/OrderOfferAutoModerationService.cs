using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public interface IOrderOfferAutoModerationService
{
    Task ProcessAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default);
}

/// <summary>
/// Auto-moderates orders pending admin review for Requests offers, Offers, Booking, and Category.
/// Buyer notes (and images) are scanned with the same policy as ads:
/// - order video → admin dashboard only (no auto-reject / auto-approve / notify)
/// - no video + notes/text violations → auto-reject + notify buyer
/// - no video + image violations (phone, company name, brand on photos) →
///   admin dashboard only (no auto-reject, no auto-approve)
/// - no video + clean notes/images → auto-approve for seller
/// </summary>
public sealed class OrderOfferAutoModerationService(
    IRasAlSouqDbContext dbContext,
    IFileStorage fileStorage,
    IOpenAiVisionService openAiVision,
    IOrdersAppService ordersAppService,
    IConfiguration configuration,
    IOptions<AdAutoModerationOptions> options,
    ILogger<OrderOfferAutoModerationService> logger) : IOrderOfferAutoModerationService
{
    private static readonly string RejectReasonEn =
        "Your submission was rejected because it appears to contain insults/profanity, a phone number, " +
        "contact details, WhatsApp, website, seller logo, or a commercial brand logo. " +
        "Origin country and product specs (e.g. Sudanese peanuts) are allowed — " +
        "please remove abusive language, contact info, and commercial logos, then resubmit.";

    private static readonly string RejectReasonAr =
        "تم الرفض لأنه يحتوي على ألفاظ نابية/إساءة أو رقم هاتف أو بيانات تواصل أو واتساب أو موقع " +
        "أو شعار البائع أو شعار ماركة تجارية. " +
        "مسموح بذكر بلد المنشأ والمواصفات (مثل: حبوب سودانية) — " +
        "يرجى إزالة الشتائم وأرقام التواصل والشعارات التجارية ثم إعادة الإرسال.";

    public async Task ProcessAsync(OrderOfferAutoModerationWorkItem workItem, CancellationToken cancellationToken = default)
    {
        if (!options.Value.Enabled)
        {
            logger.LogInformation("Order auto-moderation disabled — order {OrderId} left for admin.", workItem.OrderId);
            return;
        }

        var order = await dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Product)
            .Include(o => o.Images)
            .Include(o => o.Videos)
            .FirstOrDefaultAsync(o => o.Id == workItem.OrderId, cancellationToken)
            .ConfigureAwait(false);

        if (order is null)
        {
            logger.LogWarning("Order auto-moderation skipped — order {OrderId} not found.", workItem.OrderId);
            return;
        }

        // Requests / Offers / Booking / Category (incl. hybrid category catalog).
        if (!ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(order.Product))
        {
            return;
        }

        if (order.IsAdminApproved)
        {
            logger.LogInformation("Order {OrderId} already admin-approved — skip auto-moderation.", workItem.OrderId);
            return;
        }

        if (order.StatusId == OrderStatusCodes.Cancelled)
        {
            return;
        }

        var adminUserId = configuration["SupportChat:AdminUserId"]?.Trim();
        if (string.IsNullOrWhiteSpace(adminUserId) || !Guid.TryParse(adminUserId, out _))
        {
            logger.LogWarning(
                "SupportChat:AdminUserId missing — cannot auto-moderate order {OrderId}; leaving for admin.",
                workItem.OrderId);
            return;
        }

        // Video cannot be Vision-scanned: never auto-reject / auto-approve / notify.
        var hasVideo = order.Videos.Any(v => !string.IsNullOrWhiteSpace(v.VideoPath));
        if (hasVideo)
        {
            logger.LogInformation(
                "Order {OrderId} (type={ProductTypeId}, category={CategoryId}) has video — " +
                "left for admin dashboard only (no auto-reject/approve/notify).",
                workItem.OrderId,
                order.Product?.ProductTypeId,
                order.Product?.CategoryId);
            return;
        }

        var textFields = await LoadOrderTextFieldsForPolicyScanAsync(order, cancellationToken)
            .ConfigureAwait(false);
        var hasNotes = textFields.HasAnyNotes;

        logger.LogInformation(
            "Order {OrderId} (type={ProductTypeId}, category={CategoryId}) scanning buyer notes/images " +
            "(hasNotes={HasNotes}, noteChars={NoteChars}).",
            workItem.OrderId,
            order.Product?.ProductTypeId,
            order.Product?.CategoryId,
            hasNotes,
            textFields.CombinedLength);

        // Buyer notes (Booking / Category / Offers / Requests) — same contact/abuse policy as ads.
        var textHits = AdContactPolicyScanner.Scan(textFields.AllParts);
        if (textHits.Count > 0)
        {
            logger.LogInformation(
                "Order {OrderId} notes policy violations: {Hits}",
                workItem.OrderId,
                string.Join(", ", textHits.Select(h => $"{h.Kind}:{h.Sample}")));
            await RejectAsync(adminUserId, workItem.OrderId, cancellationToken).ConfigureAwait(false);
            return;
        }

        var combinedText = textFields.ToLabeledCombinedText();
        if (hasNotes)
        {
            if (string.IsNullOrWhiteSpace(combinedText))
            {
                logger.LogWarning(
                    "Order {OrderId} notes expected but combined text empty — leaving for admin.",
                    workItem.OrderId);
                return;
            }

            AdTextPolicyScanResult textLlm;
            try
            {
                textLlm = await openAiVision.ScanAdTextForPolicyViolationsAsync(combinedText, cancellationToken)
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Order {OrderId} notes scan threw — leaving for admin.", workItem.OrderId);
                return;
            }

            if (string.Equals(textLlm.Summary, "scan_failed", StringComparison.OrdinalIgnoreCase))
            {
                logger.LogWarning("Order {OrderId} notes scan failed — leaving for admin.", workItem.OrderId);
                return;
            }

            if (textLlm.HasViolation)
            {
                logger.LogInformation(
                    "Order {OrderId} LLM notes violations: {Kinds} ({Summary})",
                    workItem.OrderId,
                    string.Join("|", textLlm.ViolationKinds),
                    textLlm.Summary);
                await RejectAsync(adminUserId, workItem.OrderId, cancellationToken).ConfigureAwait(false);
                return;
            }
        }

        var imagePaths = order.Images
            .Select(i => i.ImagePath)
            .Where(p => !string.IsNullOrWhiteSpace(p)
                        && !IsDocumentPath(p))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var hasDocuments = order.Images.Any(i =>
            !string.IsNullOrWhiteSpace(i.ImagePath) && IsDocumentPath(i.ImagePath));

        var imageScan = await ScanImagesAsync(workItem.OrderId, imagePaths, cancellationToken).ConfigureAwait(false);
        if (imageScan.Hits.Count > 0)
        {
            logger.LogInformation(
                "Order {OrderId} image policy violations: {Hits} — left for admin dashboard review.",
                workItem.OrderId,
                string.Join(", ", imageScan.Hits));
            return;
        }

        if (imageScan.Listed > 0 && imageScan.Succeeded < imageScan.Listed)
        {
            logger.LogWarning(
                "Order {OrderId} image scan incomplete ({Succeeded}/{Listed}) — leaving for admin.",
                workItem.OrderId,
                imageScan.Succeeded,
                imageScan.Listed);
            return;
        }

        // Documents are not Vision-scanned — admin must review.
        if (hasDocuments)
        {
            logger.LogInformation(
                "Order {OrderId} has documents — left for admin dashboard (notes/images were clean).",
                workItem.OrderId);
            return;
        }

        // Nothing scannable (should be rare for admin-gated orders) — don't vacuous-approve.
        if (!hasNotes && imagePaths.Count == 0)
        {
            logger.LogInformation(
                "Order {OrderId} has no notes/images to scan — left for admin dashboard.",
                workItem.OrderId);
            return;
        }

        if (AdminOrderPricingHelper.IsRequestOfferBelowListingPrice(order, order.Product))
        {
            logger.LogInformation(
                "Order {OrderId} offer is below the request listing price — left for admin.",
                workItem.OrderId);
            return;
        }

        try
        {
            await ordersAppService.ApproveRequestOfferForAdminAsync(
                    adminUserId,
                    workItem.OrderId,
                    cancellationToken: cancellationToken)
                .ConfigureAwait(false);
            logger.LogInformation(
                "Order {OrderId} (type={ProductTypeId}, category={CategoryId}) auto-approved after notes/image scan.",
                workItem.OrderId,
                order.Product?.ProductTypeId,
                order.Product?.CategoryId);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-approve failed for order {OrderId} — leaving for admin.", workItem.OrderId);
        }
    }

    private static bool IsDocumentPath(string path) =>
        path.Contains("product-documents", StringComparison.OrdinalIgnoreCase)
        || path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase);

    private async Task<OrderTextFieldsForScan> LoadOrderTextFieldsForPolicyScanAsync(
        Order order,
        CancellationToken cancellationToken)
    {
        var translation = await dbContext.ContentTranslations
            .AsNoTracking()
            .FirstOrDefaultAsync(
                x => x.Scope == ContentTranslationScopes.Order
                    && x.OrderId == order.Id
                    && x.Field == ContentTranslationFields.OfferNotes,
                cancellationToken)
            .ConfigureAwait(false);

        var notesPrimary = FirstNonEmpty(order.Notes, translation?.TextEn, translation?.TextAr);
        var notesSecondary = DistinctFrom(
            FirstNonEmpty(translation?.TextAr, translation?.TextEn),
            notesPrimary);

        return new OrderTextFieldsForScan(notesPrimary, notesSecondary);
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

    private sealed record OrderTextFieldsForScan(
        string? NotesPrimary,
        string? NotesSecondary)
    {
        public string?[] AllParts => [NotesPrimary, NotesSecondary];

        public bool HasAnyNotes =>
            !string.IsNullOrWhiteSpace(NotesPrimary) || !string.IsNullOrWhiteSpace(NotesSecondary);

        public int CombinedLength =>
            (NotesPrimary?.Length ?? 0) + (NotesSecondary?.Length ?? 0);

        public string ToLabeledCombinedText()
        {
            var lines = new List<string>(2);
            void Add(string label, string? value)
            {
                if (!string.IsNullOrWhiteSpace(value))
                {
                    lines.Add($"{label}: {value.Trim()}");
                }
            }

            // Buyer notes on Booking / Category / Offers / Requests purchase orders.
            Add("Buyer order notes / additional instructions", NotesPrimary);
            Add("Buyer order notes (alt language)", NotesSecondary);
            return string.Join("\n", lines);
        }
    }

    private async Task RejectAsync(string adminUserId, long orderId, CancellationToken cancellationToken) =>
        await RejectAsync(adminUserId, orderId, RejectReasonEn, RejectReasonAr, cancellationToken)
            .ConfigureAwait(false);

    private async Task RejectAsync(
        string adminUserId,
        long orderId,
        string reasonEn,
        string reasonAr,
        CancellationToken cancellationToken)
    {
        try
        {
            await ordersAppService.RejectRequestOfferForAdminAsync(
                    adminUserId,
                    orderId,
                    reasonEn,
                    reasonAr,
                    cancellationToken)
                .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-reject failed for order {OrderId} — leaving for admin.", orderId);
        }
    }

    private sealed record ImageScanResult(List<string> Hits, int Listed, int Succeeded);

    private async Task<ImageScanResult> ScanImagesAsync(
        long orderId,
        IReadOnlyList<string> imagePaths,
        CancellationToken cancellationToken)
    {
        var hits = new List<string>();
        var succeeded = 0;
        var max = options.Value.MaxImagesToScan;
        var toScan = (max > 0 ? imagePaths.Take(max) : imagePaths).ToList();
        var listed = toScan.Count;

        foreach (var path in toScan)
        {
            await using var stream = await fileStorage.OpenReadAsync(path, cancellationToken).ConfigureAwait(false);
            if (stream is null)
            {
                logger.LogWarning(
                    "Order {OrderId} image {Path} could not be opened — treating as scan failure.",
                    orderId,
                    path);
                continue;
            }

            try
            {
                var result = await openAiVision.ScanAdImageForPolicyViolationsAsync(
                        stream,
                        Path.GetFileName(path),
                        cancellationToken)
                    .ConfigureAwait(false);
                if (result.ScanFailed)
                {
                    logger.LogWarning(
                        "Order {OrderId} image {Path} policy scan failed ({Summary}).",
                        orderId,
                        path,
                        result.Summary);
                    continue;
                }

                succeeded++;
                if (!result.HasViolation)
                {
                    continue;
                }

                var kinds = result.ViolationKinds.Count > 0
                    ? string.Join("|", result.ViolationKinds)
                    : "policy";
                hits.Add($"{path}:{kinds}");
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Vision scan failed for order {OrderId} image {Path}", orderId, path);
            }
        }

        return new ImageScanResult(hits, listed, succeeded);
    }
}
