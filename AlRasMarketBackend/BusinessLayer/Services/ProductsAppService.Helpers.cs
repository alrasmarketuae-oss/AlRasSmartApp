using System.Data;
using System.Security.Claims;
using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using DataLayer.Seeding;
using Microsoft.Extensions.Caching.Memory;
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
        public UnitSnapshot? Unit { get; init; }
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

        var principal = httpContextAccessor.HttpContext?.User;
        if (principal?.Identity?.IsAuthenticated == true && IsAdminPrincipal(principal))
        {
            var target = await productData.GetUserByIdAsync(ownerId, tracked: true, cancellationToken)
                ?? throw new KeyNotFoundException("Owner user not found.");
            if (target.RoleId is not (RoleIds.Seller or RoleIds.ShippingCompany))
            {
                throw new UnauthorizedAccessException("Target account cannot own products.");
            }

            if (target.IsRejected)
            {
                throw new UnauthorizedAccessException("This company account is rejected.");
            }

            return ownerId;
        }

        if (principal?.Identity?.IsAuthenticated == true
            && TryAuthorizeCompanyOwnerFromToken(principal, ownerId))
        {
            return ownerId;
        }

        var owner = await productData.GetUserByIdAsync(ownerId, tracked: true, cancellationToken)
            ?? throw new KeyNotFoundException("Owner user not found.");

        if (owner.RoleId != RoleIds.Seller && owner.RoleId != RoleIds.ShippingCompany)
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

    private static bool IsAdminPrincipal(ClaimsPrincipal principal) =>
        principal.IsInRole("Admin")
        || string.Equals(principal.FindFirst("roleId")?.Value, "1", StringComparison.Ordinal);

    /// <summary>
    /// Fast path: trust JWT claims issued at login (roleId / approval / phone).
    /// Falls through when claims are missing (old tokens) so DB check still runs.
    /// </summary>
    private static bool TryAuthorizeCompanyOwnerFromToken(ClaimsPrincipal principal, Guid expectedOwnerId)
    {
        var claimId = principal.FindFirst("EntityId")?.Value
            ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(claimId, out var tokenUserId) || tokenUserId != expectedOwnerId)
        {
            return false;
        }

        var roleIdRaw = principal.FindFirst("roleId")?.Value;
        var roleName = principal.FindFirst(ClaimTypes.Role)?.Value;
        var isSeller = roleIdRaw == "2"
            || string.Equals(roleName, "Seller", StringComparison.OrdinalIgnoreCase);
        if (!isSeller)
        {
            return false;
        }

        // New tokens always include isApproved. Old tokens without it → force DB path.
        var approvedClaim = principal.FindFirst("isApproved")?.Value;
        if (approvedClaim is null)
        {
            return false;
        }

        var isApproved = IsTruthClaim(approvedClaim);
        var isActive = IsTruthClaim(principal.FindFirst("isActive")?.Value ?? "true");
        var isRejected = IsTruthClaim(principal.FindFirst("isRejected")?.Value);
        var hasPending = IsTruthClaim(principal.FindFirst("hasPendingProfile")?.Value);

        if (isRejected || !isActive || (!isApproved && !hasPending))
        {
            throw new UnauthorizedAccessException(
                "Your company account is pending admin approval. You cannot create or edit ads now.");
        }

        return true;
    }

    private static bool IsTruthClaim(string? value) =>
        string.Equals(value, "true", StringComparison.OrdinalIgnoreCase)
        || value == "1";

    /// <summary>Companies registered with a non-UAE phone may only create Booking ads.</summary>
    private async Task EnsureNonUaeCompanyBookingOnlyAsync(
        Guid ownerId,
        byte? productTypeId,
        byte? categoryId,
        CancellationToken cancellationToken)
    {
        var phone = httpContextAccessor.HttpContext?.User?.FindFirst("phone")?.Value;
        if (string.IsNullOrWhiteSpace(phone))
        {
            phone = await productData.GetUserPhoneByIdAsync(ownerId, cancellationToken);
        }

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
        var user = await productData.GetUserByIdAsync(userId, tracked: true, cancellationToken)
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
        var media = await productData.DeleteProductOrdersAndDependentsAsync(productId, cancellationToken);
        await DeleteOrderPhysicalAssetsAsync(media.OrderImagePaths, media.OrderVideoPaths, cancellationToken);
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

    private async Task<CatalogSearchAudience> ResolveCatalogSearchAudienceAsync(
        string? searcherUserId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(searcherUserId)
            || !Guid.TryParse(searcherUserId, out var userId)
            || userId == Guid.Empty)
        {
            return CatalogSearchAudience.All;
        }

        var user = await productData.GetUserByIdAsync(userId, tracked: false, cancellationToken);
        if (user is null)
        {
            return CatalogSearchAudience.All;
        }

        // Company customer (Seller role + IsCustomer): Offers / Booking / wholesale.
        if (user.RoleId == RoleIds.Seller && user.IsCustomer == true)
        {
            return CatalogSearchAudience.CompanyCustomer;
        }

        // Personal customer (Buyer): Retail only.
        if (user.RoleId == RoleIds.Buyer)
        {
            return CatalogSearchAudience.PersonalCustomer;
        }

        // Supplier (Seller + !IsCustomer), admin, shipping, etc.
        return CatalogSearchAudience.All;
    }

    private static string CatalogAudienceCacheKey(CatalogSearchAudience audience) =>
        audience switch
        {
            CatalogSearchAudience.CompanyCustomer => "cc",
            CatalogSearchAudience.PersonalCustomer => "pc",
            _ => "all",
        };

    private static List<ProductPublicRow> FilterCatalogRowsForAudience(
        IReadOnlyList<ProductPublicRow> products,
        CatalogSearchAudience audience)
    {
        if (audience == CatalogSearchAudience.All)
        {
            return products as List<ProductPublicRow> ?? products.ToList();
        }

        if (audience == CatalogSearchAudience.CompanyCustomer)
        {
            return products
                .Where(p => !ProductTypeCodes.IsHiddenFromCompanyCustomerCatalog(
                    p.CategoryId,
                    p.ProductTypeId))
                .ToList();
        }

        return products
            .Where(p => !ProductTypeCodes.IsHiddenFromPersonalCustomerCatalog(
                p.CategoryId,
                p.ProductTypeId,
                p.RetailPrice,
                p.RetailUnitId))
            .ToList();
    }

    private static bool IncludeRetailHybridCard(CatalogSearchAudience audience) =>
        audience != CatalogSearchAudience.CompanyCustomer;

    private static bool IncludeCategoryHybridCard(CatalogSearchAudience audience) =>
        audience != CatalogSearchAudience.PersonalCustomer;

}
