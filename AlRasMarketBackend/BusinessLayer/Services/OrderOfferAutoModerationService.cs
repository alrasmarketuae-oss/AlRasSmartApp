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
/// Auto-moderates orders pending admin review (Requests offers, Offers, Booking, Category)
/// with the same text/image/video rules as product ads.
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

        // Same gated types as ads moderation path: Requests, Offers, Booking, Category.
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

        var textFields = await LoadOrderTextFieldsForPolicyScanAsync(order, cancellationToken)
            .ConfigureAwait(false);

        var textHits = AdContactPolicyScanner.Scan(textFields.AllParts);
        if (textHits.Count > 0)
        {
            logger.LogInformation(
                "Order {OrderId} text policy violations: {Hits}",
                workItem.OrderId,
                string.Join(", ", textHits.Select(h => $"{h.Kind}:{h.Sample}")));
            await RejectAsync(adminUserId, workItem.OrderId, cancellationToken).ConfigureAwait(false);
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
                logger.LogWarning(ex, "Order {OrderId} text scan threw — leaving for admin.", workItem.OrderId);
                return;
            }

            if (string.Equals(textLlm.Summary, "scan_failed", StringComparison.OrdinalIgnoreCase))
            {
                logger.LogWarning("Order {OrderId} text scan failed — leaving for admin.", workItem.OrderId);
                return;
            }

            if (textLlm.HasViolation)
            {
                logger.LogInformation(
                    "Order {OrderId} LLM text violations: {Kinds} ({Summary})",
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
                        && !p.Contains("product-documents", StringComparison.OrdinalIgnoreCase)
                        && !p.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var imageScan = await ScanImagesAsync(workItem.OrderId, imagePaths, cancellationToken).ConfigureAwait(false);
        if (imageScan.Hits.Count > 0)
        {
            logger.LogInformation(
                "Order {OrderId} image policy violations: {Hits}",
                workItem.OrderId,
                string.Join(", ", imageScan.Hits));
            await RejectAsync(adminUserId, workItem.OrderId, cancellationToken).ConfigureAwait(false);
            return;
        }

        if (imageScan.Attempted > 0 && imageScan.Succeeded == 0)
        {
            logger.LogWarning("Order {OrderId} image scans all failed — leaving for admin.", workItem.OrderId);
            return;
        }

        // Video is not Vision-scanned: never auto-approve; leave for admin dashboard.
        var hasVideo = order.Videos.Any(v => !string.IsNullOrWhiteSpace(v.VideoPath));
        if (hasVideo)
        {
            logger.LogInformation(
                "Order {OrderId} (type={ProductTypeId}, category={CategoryId}) has video — " +
                "left for admin dashboard (notes/images were clean).",
                workItem.OrderId,
                order.Product?.ProductTypeId,
                order.Product?.CategoryId);
            return;
        }

        try
        {
            await ordersAppService.ApproveRequestOfferForAdminAsync(adminUserId, workItem.OrderId, cancellationToken)
                .ConfigureAwait(false);
            logger.LogInformation(
                "Order {OrderId} (type={ProductTypeId}, category={CategoryId}) auto-approved after policy scan.",
                workItem.OrderId,
                order.Product?.ProductTypeId,
                order.Product?.CategoryId);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-approve failed for order {OrderId} — leaving for admin.", workItem.OrderId);
        }
    }

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

        var notesPrimary = FirstNonEmpty(order.Notes, translation?.TextEn);
        var notesSecondary = DistinctFrom(translation?.TextAr, notesPrimary);

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

            // Order notes are the buyer-submitted text (title/specs equivalent for offers/orders).
            Add("Order notes / specifications", NotesPrimary);
            Add("Order notes (alt language)", NotesSecondary);
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

    private sealed record ImageScanResult(List<string> Hits, int Attempted, int Succeeded);

    private async Task<ImageScanResult> ScanImagesAsync(
        long orderId,
        IReadOnlyList<string> imagePaths,
        CancellationToken cancellationToken)
    {
        var hits = new List<string>();
        var attempted = 0;
        var succeeded = 0;
        var max = options.Value.MaxImagesToScan;
        var toScan = max > 0 ? imagePaths.Take(max) : imagePaths;

        foreach (var path in toScan)
        {
            await using var stream = await fileStorage.OpenReadAsync(path, cancellationToken).ConfigureAwait(false);
            if (stream is null)
            {
                continue;
            }

            attempted++;
            try
            {
                var result = await openAiVision.ScanAdImageForPolicyViolationsAsync(
                        stream,
                        Path.GetFileName(path),
                        cancellationToken)
                    .ConfigureAwait(false);
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

        return new ImageScanResult(hits, attempted, succeeded);
    }
}
