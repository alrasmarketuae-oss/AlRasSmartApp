using System.Data;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using DataLayer.Seeding;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    private static string GetApprovalStatusText(byte? status, bool? isApproved)
    {
        if (ProductStatusCodes.Normalize(status, isApproved) == ProductStatusCodes.Rejected)
        {
            return "Rejected";
        }

        return isApproved == true ? "Approved" : "Pending";
    }

    private static bool DetectLanguageHintIsArabic(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return false;
        }

        var arabic = 0;
        var latin = 0;
        foreach (var ch in text)
        {
            if (ch is >= '\u0600' and <= '\u06FF')
            {
                arabic++;
            }
            else if (char.IsLetter(ch))
            {
                latin++;
            }
        }

        return arabic > 0 && arabic >= latin;
    }

    /// <summary>Normalize create-time UI language; fall back to script detection on the title.</summary>
    private static string NormalizeCreatedLanguage(string? language, string? nameHint) =>
        !string.IsNullOrWhiteSpace(language)
            ? NotificationMessages.NormalizeLanguage(language)
            : (DetectLanguageHintIsArabic(nameHint) ? "ar" : "en");

    /// <summary>
    /// Prefer stored CreatedLanguage; for legacy rows infer from Arabic title / translation.
    /// </summary>
    private static string ResolveCreatedLanguage(
        string? stored,
        string? nameEn,
        string? nameAr)
    {
        if (!string.IsNullOrWhiteSpace(stored))
        {
            return NotificationMessages.NormalizeLanguage(stored);
        }

        if (DetectLanguageHintIsArabic(nameEn))
        {
            return "ar";
        }

        if (!string.IsNullOrWhiteSpace(nameAr)
            && DetectLanguageHintIsArabic(nameAr)
            && !DetectLanguageHintIsArabic(nameEn))
        {
            return "ar";
        }

        return "en";
    }

    private static string ToYesNoText(bool? value) =>
        value switch
        {
            true => "Yes",
            false => "No",
            _ => string.Empty
        };

    private static string ToYesNoText(bool value) => value ? "Yes" : "No";

    private static string FormatDateTimeText(DateTime value) =>
        UtcDateTimeHelper.FormatApiDateTime(value);

    private static string FormatDateTimeText(DateTime? value) =>
        UtcDateTimeHelper.FormatApiDateTime(value);

    private static byte ResolveProductStatusOnUpdate(byte? currentStatus, byte? requestedStatus)
    {
        var current = ProductStatusCodes.Normalize(currentStatus);

        if (!requestedStatus.HasValue)
        {
            return current;
        }

        if (ProductStatusCodes.IsValidForSupplierUpdate(requestedStatus))
        {
            return requestedStatus.Value;
        }

        if (requestedStatus == ProductStatusCodes.UnderReview && current == ProductStatusCodes.UnderReview)
        {
            return ProductStatusCodes.UnderReview;
        }

        return current;
    }

    private sealed class ProductReferenceBundle
    {
        public ProductType? ProductType { get; init; }
        public RequestType? RequestType { get; init; }
        public BookingPriceType? BookingPriceType { get; init; }
        public required UnitSnapshot Unit { get; init; }
        public UnitSnapshot? RetailUnit { get; init; }
        public GeoCountrySnapshot? OriginCountry { get; init; }
        public GeoCountrySnapshot? DestinationCountry { get; init; }
        public GeoPortSnapshot? LoadingPort { get; init; }
        public GeoPortSnapshot? ArrivalPort { get; init; }
    }

    private async Task<Guid> EnsureCompanyOwnerAsync(string ownerIdText, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(ownerIdText, out var ownerId))
        {
            throw new ArgumentException("Invalid owner id.");
        }

        var owner = await dbContext.Users.FindAsync([ownerId], cancellationToken)
            ?? throw new KeyNotFoundException("Owner user not found.");

        if (owner.RoleId != 2)
        {
            throw new UnauthorizedAccessException("Only company accounts can manage products.");
        }

        // Profile edits awaiting admin approval must NOT block ads — live data stays as-is.
        var hasPendingProfileEdit = !string.IsNullOrWhiteSpace(owner.PendingProfileChanges);
        if (owner.IsRejected || !owner.IsActive || (!owner.IsApproved && !hasPendingProfileEdit))
        {
            throw new UnauthorizedAccessException(
                "Your company account is pending admin approval. You cannot create or edit ads now.");
        }

        return ownerId;
    }

    /// <summary>Companies registered with a non-UAE phone may only create Booking ads.</summary>
    private async Task EnsureNonUaeCompanyBookingOnlyAsync(
        Guid ownerId,
        byte? productTypeId,
        byte? categoryId,
        CancellationToken cancellationToken)
    {
        var phone = await dbContext.Users.AsNoTracking()
            .Where(x => x.Id == ownerId)
            .Select(x => x.PhoneNumber)
            .FirstOrDefaultAsync(cancellationToken);

        if (IsUaePhoneNumber(phone))
        {
            return;
        }

        var isBookingOnly = productTypeId == ProductTypeCodes.Booking && !categoryId.HasValue;
        if (!isBookingOnly)
        {
            throw new ArgumentException(
                "Companies registered with a non-UAE phone number can only publish Booking ads.");
        }
    }

    private static bool IsUaePhoneNumber(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
        {
            return false;
        }

        var digits = new string(phone.Where(char.IsDigit).ToArray());
        return digits.StartsWith("971", StringComparison.Ordinal);
    }

    private async Task EnsureCanDeleteProductAsync(
        Guid userId,
        Product product,
        CancellationToken cancellationToken)
    {
        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId == 1)
        {
            return;
        }

        if (user.RoleId == 2 && product.OwnerId == userId)
        {
            return;
        }

        throw new UnauthorizedAccessException("You are not allowed to delete this product.");
    }

    private async Task DeleteProductOrdersAndDependentsAsync(
        Guid productId,
        string? webRootPath,
        CancellationToken cancellationToken)
    {
        _ = webRootPath;
        var orderIds = await dbContext.Orders
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        if (orderIds.Count > 0)
        {
            var orderImagePaths = await dbContext.OrderImages
                .AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.ImagePath)
                .ToListAsync(cancellationToken);

            var orderVideoPaths = await dbContext.OrderVideos
                .AsNoTracking()
                .Where(x => orderIds.Contains(x.OrderId))
                .Select(x => x.VideoPath)
                .ToListAsync(cancellationToken);

            await RemoveDeletionRangeAsync(
                dbContext.InternationalShipments.Where(x => orderIds.Contains(x.OrderId)),
                cancellationToken);
            await RemoveDeletionRangeAsync(
                dbContext.PendingPayments.Where(x => orderIds.Contains(x.OrderId)),
                cancellationToken);
            await RemoveDeletionRangeAsync(
                dbContext.OrderVideos.Where(x => orderIds.Contains(x.OrderId)),
                cancellationToken);
            await RemoveDeletionRangeAsync(
                dbContext.OrderImages.Where(x => orderIds.Contains(x.OrderId)),
                cancellationToken);
            // Order FK on ContentTranslations is NO ACTION (SQL Server cascade-path limit).
            await RemoveDeletionRangeAsync(
                dbContext.ContentTranslations.Where(x => x.OrderId != null && orderIds.Contains(x.OrderId.Value)),
                cancellationToken);
            await RemoveDeletionRangeAsync(
                dbContext.Orders.Where(x => orderIds.Contains(x.Id)),
                cancellationToken);

            await DeleteOrderPhysicalAssetsAsync(orderImagePaths, orderVideoPaths, cancellationToken);
        }

        await RemoveDeletionRangeAsync(
            dbContext.PendingOrderItems.Where(x => x.ProductId == productId),
            cancellationToken);
    }

    private async Task DeleteOrderPhysicalAssetsAsync(
        IReadOnlyList<string> imagePaths,
        IReadOnlyList<string> videoPaths,
        CancellationToken cancellationToken)
    {
        foreach (var path in imagePaths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }

        foreach (var path in videoPaths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }
    }

    private async Task RemoveDeletionRangeAsync<TEntity>(
        IQueryable<TEntity> query,
        CancellationToken cancellationToken)
        where TEntity : class
    {
        var items = await query.ToListAsync(cancellationToken);
        if (items.Count == 0)
        {
            return;
        }

        if (dbContext is not DbContext efContext)
        {
            throw new InvalidOperationException("Database context must support entity removal.");
        }

        efContext.Set<TEntity>().RemoveRange(items);
    }

    private async Task DeleteProductPhysicalAssetsAsync(
        Guid productId,
        IReadOnlyList<string> videoPaths,
        IReadOnlyList<string> imagePaths,
        IReadOnlyList<string> documentPaths,
        CancellationToken cancellationToken)
    {
        _ = productId;

        foreach (var path in videoPaths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }

        foreach (var path in imagePaths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }

        foreach (var path in documentPaths)
        {
            await mediaStorage.DeleteAsync(path, cancellationToken);
        }
    }

}
