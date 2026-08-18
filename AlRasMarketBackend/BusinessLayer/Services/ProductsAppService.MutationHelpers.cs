using System.Data;
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
    private const string DefaultProductTypeName = "Retail";

    private static string? FirstNonEmpty(params string?[] values) =>
        values.FirstOrDefault(v => !string.IsNullOrWhiteSpace(v))?.Trim();

    private static bool IsCategoryPlaceholder(string? value) =>
        !string.IsNullOrWhiteSpace(value) &&
        (value.Equals("Categories", StringComparison.OrdinalIgnoreCase) ||
         value.Equals("Category", StringComparison.OrdinalIgnoreCase));

    private async Task NormalizeProductCreateFieldsAsync(CreateProductInput input, CancellationToken cancellationToken)
    {
        input.CategoryId = FirstNonEmpty(input.CategoryId, input.Category, input.Categories);
        input.CategoryName = FirstNonEmpty(input.CategoryName);

        var rawProductType = FirstNonEmpty(input.ProductType, input.ProductTypeName);
        var wasCategoryPlaceholder = IsCategoryPlaceholder(rawProductType);

        var productTypeCandidate = rawProductType;
        if (wasCategoryPlaceholder)
        {
            productTypeCandidate = null;
        }

        if (!string.IsNullOrWhiteSpace(productTypeCandidate))
        {
            var normalizedType = productTypeCandidate.ToLowerInvariant();
            var isProductType = staticReferenceCache.ProductTypeExistsByName(productTypeCandidate);

            if (!isProductType)
            {
                var isCategoryName = staticReferenceCache.CategoryExistsByName(productTypeCandidate);

                if (isCategoryName)
                {
                    input.CategoryId ??= productTypeCandidate;
                    productTypeCandidate = null;
                }
                else if (byte.TryParse(productTypeCandidate, out var maybeCategoryId) && maybeCategoryId > 0)
                {
                    var categoryExists = staticReferenceCache.CategoryExistsById(maybeCategoryId);

                    if (categoryExists)
                    {
                        input.CategoryId ??= productTypeCandidate;
                        productTypeCandidate = null;
                    }
                }
            }
        }

        if (wasCategoryPlaceholder)
        {
            input.ProductTypeName = null;
            input.ProductType = null;
        }
        else
        {
            var hasCategory =
                !string.IsNullOrWhiteSpace(input.CategoryId) ||
                !string.IsNullOrWhiteSpace(input.CategoryName) ||
                !string.IsNullOrWhiteSpace(input.Category) ||
                !string.IsNullOrWhiteSpace(input.Categories);

            var hasRealProductType = !string.IsNullOrWhiteSpace(productTypeCandidate);

            if (hasCategory && !hasRealProductType)
            {
                // Main category listing — no service product type.
                input.ProductTypeName = null;
                input.ProductType = null;
            }
            else if (hasCategory && hasRealProductType &&
                     productTypeCandidate!.Equals("Retail", StringComparison.OrdinalIgnoreCase))
            {
                // Hybrid dual-list (CategoryId + Retail ProductTypeId).
                // Keep CategoryId; drop ProductTypeName so update keeps existing
                // ProductTypeId/retail fields instead of converting to pure Retail.
                input.ProductTypeName = null;
                input.ProductType = null;
            }
            else if (hasRealProductType)
            {
                // Service section listing — no main category.
                input.CategoryId = null;
                input.CategoryName = null;
                input.Category = null;
                input.Categories = null;
                input.ProductTypeName = productTypeCandidate;
            }
            else
            {
                input.ProductTypeName = DefaultProductTypeName;
            }
        }
    }

    private async Task<byte?> ResolveCategoryIdAsync(
        string? categoryId,
        string? categoryName,
        CancellationToken cancellationToken)
    {
        var idText = string.IsNullOrWhiteSpace(categoryId) ? null : categoryId.Trim();
        var nameText = string.IsNullOrWhiteSpace(categoryName) ? null : categoryName.Trim();

        if (idText != null && byte.TryParse(idText, out var parsedId) && parsedId > 0)
        {
            var byId = staticReferenceCache.FindCategoryById(parsedId);

            if (byId != null)
            {
                return byId.CategoryId;
            }

            var canonical = CanonicalCategories.Seed.FirstOrDefault(x => x.CategoryId == parsedId);
            if (canonical != null)
            {
                var byCanonicalName = staticReferenceCache.FindCategoryByName(canonical.NameEn);

                if (byCanonicalName != null)
                {
                    return byCanonicalName.CategoryId;
                }
            }

            throw new KeyNotFoundException($"Category '{parsedId}' was not found.");
        }

        var lookupName = nameText ?? (idText != null && !byte.TryParse(idText, out _) ? idText : null);
        if (!string.IsNullOrWhiteSpace(lookupName))
        {
            var byName = staticReferenceCache.FindCategoryByName(lookupName);

            if (byName != null)
            {
                return byName.CategoryId;
            }

            throw new KeyNotFoundException($"Category '{lookupName}' was not found.");
        }

        return null;
    }

    private static void ValidateProductForm(CreateProductInput input)
    {
        var isRequest = !string.IsNullOrWhiteSpace(input.ProductTypeName)
            && input.ProductTypeName.Trim().Equals("Requests", StringComparison.OrdinalIgnoreCase);

        if (!isRequest)
        {
            if (input.USDPrice <= 0)
            {
                throw new ArgumentException("USDPrice must be greater than zero.");
            }

            if (input.Quantity <= 0)
            {
                throw new ArgumentException("Quantity must be greater than zero.");
            }

            if (string.IsNullOrWhiteSpace(input.UnitName))
            {
                throw new ArgumentException("UnitName is required.");
            }
        }
        else
        {
            if (input.USDPrice < 0)
            {
                throw new ArgumentException("USDPrice cannot be negative.");
            }

            if (input.Quantity < 0)
            {
                throw new ArgumentException("Quantity cannot be negative.");
            }

            if (input.USDPrice > 0 && string.IsNullOrWhiteSpace(input.Currency))
            {
                throw new ArgumentException("Currency is required when a target price is provided.");
            }
        }

        var isBooking = !string.IsNullOrWhiteSpace(input.ProductTypeName)
            && input.ProductTypeName.Trim().Equals("Booking", StringComparison.OrdinalIgnoreCase);

        if (isBooking)
        {
            // Booking listings must be priced in USD (UI locks this; API enforces it).
            input.Currency = "USD";
        }
        else if (!string.IsNullOrWhiteSpace(input.Currency)
            && input.Currency.Trim().ToUpperInvariant() is not ("USD" or "AED"))
        {
            throw new ArgumentException("Currency must be USD or AED.");
        }

        if (input.DiscountPercentage.HasValue)
        {
            if (!input.DiscountDays.HasValue)
            {
                throw new ArgumentException("DiscountDays is required when DiscountPercentage is set.");
            }

            if (input.DiscountDays.Value <= 0)
            {
                throw new ArgumentException("DiscountDays must be greater than zero.");
            }
        }

        ValidateShippingDuration(input.ShippingDuration);
        ValidateShippingDuration(input.OfferDuration);
    }

    private static void ValidateCatalogClassification(byte? categoryId, byte? productTypeId)
    {
        if (!categoryId.HasValue && !productTypeId.HasValue)
        {
            throw new ArgumentException("Either CategoryId or ProductTypeName is required.");
        }

        // Hybrids: CategoryId + Retail ProductTypeId (dual wholesale/retail listing).
        if (categoryId.HasValue &&
            productTypeId.HasValue &&
            productTypeId.Value != ProductTypeCodes.Retail)
        {
            throw new ArgumentException("Product cannot have both CategoryId and ProductType.");
        }
    }

    private static void ValidateShippingDuration(string? shippingDuration)
    {
        if (shippingDuration is null)
        {
            return;
        }

        var normalized = shippingDuration.Trim();
        if (normalized.Length == 0)
        {
            return;
        }

        if (normalized.Length > 20)
        {
            throw new ArgumentException("ShippingDuration must be at most 20 characters.");
        }
    }

    private static string? NormalizeShippingDuration(string? shippingDuration)
    {
        if (string.IsNullOrWhiteSpace(shippingDuration))
        {
            return null;
        }

        var normalized = shippingDuration.Trim();
        return normalized.Length == 0 ? null : normalized;
    }

    /// <summary>Packing type id: null or 1–255.</summary>
    private static byte? NormalizePackaging(byte? packaging)
    {
        if (packaging is null or 0)
        {
            return null;
        }

        if (packaging > 255)
        {
            throw new ArgumentException("Packaging must be between 1 and 255.");
        }

        return packaging;
    }

    /// <summary>
    /// Owner may change list/retail prices, discount, and stock quantities (wholesale + retail)
    /// without losing approval. Any other field change keeps the existing resubmit-for-review behavior.
    /// </summary>
    private static bool IsPriceOnlyProductUpdate(
        Product existing,
        CreateProductInput input,
        byte? categoryId,
        ProductReferenceBundle refs,
        string? newVideoPath,
        Guid? newAddressId,
        string newCurrency,
        OwnerEditTranslationHints? translationHints = null)
    {
        if (input.ProductVideoFile is not null)
        {
            return false;
        }

        byte? nextCategoryId;
        byte? nextProductTypeId;
        var isCategoryHybridUpdate =
            existing.CategoryId.HasValue
            && existing.CategoryId.Value > 0
            && refs.ProductType?.Id == ProductTypeCodes.Retail
            && ProductTypeCodes.HasRetailPricing(existing)
            && !categoryId.HasValue;

        if (categoryId.HasValue)
        {
            nextCategoryId = categoryId;
            // Dual retail on category sets ProductTypeId = Retail after ApplyRetailPricing.
            var enablingRetail = input.EnableRetailPricing != false
                && (input.EnableRetailPricing == true
                    || input.RetailPrice.HasValue
                    || !string.IsNullOrWhiteSpace(input.RetailUnitName)
                    || input.RetailQuantity.HasValue
                    || refs.RetailUnit is not null);
            nextProductTypeId = enablingRetail
                ? ProductTypeCodes.Retail
                : (input.EnableRetailPricing == false ? null : existing.ProductTypeId);
            if (input.EnableRetailPricing == false)
            {
                nextProductTypeId = null;
            }
        }
        else if (isCategoryHybridUpdate)
        {
            // Match UpdateAsync: keep category dual-retail classification.
            nextCategoryId = existing.CategoryId;
            nextProductTypeId = existing.ProductTypeId;
        }
        else if (refs.ProductType?.Id != null)
        {
            nextProductTypeId = refs.ProductType.Id;
            nextCategoryId = null;
        }
        else
        {
            nextCategoryId = categoryId;
            nextProductTypeId = refs.ProductType?.Id;
        }

        // Omitted / blank optional fields mean "leave unchanged" on owner edit.
        var nextNameEn = string.IsNullOrWhiteSpace(input.NameEn)
            ? existing.NameEn
            : input.NameEn;
        var nextDescriptionEn = string.IsNullOrWhiteSpace(input.DescriptionEn)
            ? existing.DescriptionEn
            : input.DescriptionEn;
        var nextShippingDuration = string.IsNullOrWhiteSpace(input.ShippingDuration)
            ? existing.ShippingDuration
            : NormalizeShippingDuration(input.ShippingDuration);
        var nextOfferDuration = string.IsNullOrWhiteSpace(input.OfferDuration)
            ? existing.OfferDuration
            : NormalizeShippingDuration(input.OfferDuration);
        var nextPackaging = input.Packaging.HasValue
            ? NormalizePackaging(input.Packaging)
            : existing.Packaging;
        var nextPackagingDetails = string.IsNullOrWhiteSpace(input.PackagingDetails)
            ? existing.PackagingDetails
            : input.PackagingDetails.Trim();
        var nextShippingDescription = string.IsNullOrWhiteSpace(input.ShippingDescriptionEn)
            ? existing.ShippingDescriptionEn
            : input.ShippingDescriptionEn.Trim();
        byte? nextBookingPriceTypeId;
        if (refs.BookingPriceType != null)
        {
            nextBookingPriceTypeId = refs.BookingPriceType.Id;
        }
        else
        {
            nextBookingPriceTypeId = existing.BookingPriceTypeId;
        }

        var nextRequestTypeId = refs.RequestType?.Id ?? existing.RequestTypeId;

        // Omitted geo / min-max on owner edit means "leave unchanged"
        // (Requests/Offers FormData skips ports → must not force re-review).
        var geoProvided = HasAnyGeoInput(input, refs);
        var nextOriginCountryId = geoProvided
            ? refs.OriginCountry?.Id
            : existing.OriginCountryId;
        var nextDestinationCountryId = geoProvided
            ? refs.DestinationCountry?.Id
            : existing.DestinationCountryId;
        var nextLoadingPortId = geoProvided
            ? refs.LoadingPort?.Id
            : existing.LoadingPortId;
        var nextArrivalPortId = geoProvided
            ? refs.ArrivalPort?.Id
            : existing.ArrivalPortId;
        var nextMinimumOrderQuantity = input.MinimumOrderQuantity
            ?? existing.MinimumOrderQuantity;
        var nextMaximumOrderQuantity = input.MaximumOrderQuantity
            ?? existing.MaximumOrderQuantity;

        return LocalizedFieldUnchanged(
                existing.NameEn,
                nextNameEn,
                translationHints?.NameAr,
                translationHints?.NameEn)
            && LocalizedFieldUnchanged(
                existing.DescriptionEn,
                nextDescriptionEn,
                translationHints?.DescriptionAr,
                translationHints?.DescriptionEn)
            && TextEquals(existing.Currency, newCurrency)
            && existing.CategoryId == nextCategoryId
            && existing.ProductTypeId == nextProductTypeId
            && existing.UnitId == refs.Unit?.Id
            && existing.OriginCountryId == nextOriginCountryId
            && existing.DestinationCountryId == nextDestinationCountryId
            && existing.LoadingPortId == nextLoadingPortId
            && existing.ArrivalPortId == nextArrivalPortId
            && existing.MinimumOrderQuantity == nextMinimumOrderQuantity
            && existing.MaximumOrderQuantity == nextMaximumOrderQuantity
            && TextEquals(existing.ShippingDescriptionEn, nextShippingDescription)
            && BoolEquals(existing.Negotiable, input.Negotiable)
            && TextEquals(existing.VideoPath, newVideoPath)
            && DurationFieldEquals(existing.ShippingDuration, nextShippingDuration)
            && (DurationFieldEquals(existing.OfferDuration, nextOfferDuration)
                || (string.IsNullOrWhiteSpace(existing.OfferDuration)
                    && existing.DiscountDays is > 0
                    && DurationFieldEquals(
                        existing.DiscountDays.Value.ToString(),
                        nextOfferDuration)))
            && existing.AddressId == newAddressId
            && existing.Packaging == nextPackaging
            && TextEquals(existing.PackagingDetails, nextPackagingDetails)
            && existing.BookingPriceTypeId == nextBookingPriceTypeId
            && existing.RequestTypeId == nextRequestTypeId
            // USDPrice / RetailPrice / Discount* / Quantity / RetailQuantity may differ without reapproval.
            && RetailChannelUnchangedExceptPriceAndQuantity(existing, input, refs, nextCategoryId, nextProductTypeId)
            && LocalizedFieldUnchanged(
                existing.RetailDescriptionEn,
                string.IsNullOrWhiteSpace(input.RetailDescriptionEn)
                    ? existing.RetailDescriptionEn
                    : input.RetailDescriptionEn,
                translationHints?.RetailDescriptionAr,
                translationHints?.RetailDescriptionEn);
    }

    private sealed class OwnerEditTranslationHints
    {
        public string? NameAr { get; init; }
        public string? NameEn { get; init; }
        public string? DescriptionAr { get; init; }
        public string? DescriptionEn { get; init; }
        public string? RetailDescriptionAr { get; init; }
        public string? RetailDescriptionEn { get; init; }
    }

    private async Task<OwnerEditTranslationHints> LoadOwnerEditTranslationHintsAsync(
        Guid productId,
        CancellationToken cancellationToken)
    {
        var rows = await productData.GetProductEditTranslationHintsAsync(productId, cancellationToken);

        string? arFor(string field) =>
            rows.FirstOrDefault(r => r.Field == field)?.TextAr;
        string? enFor(string field) =>
            rows.FirstOrDefault(r => r.Field == field)?.TextEn;

        return new OwnerEditTranslationHints
        {
            NameAr = arFor(ContentTranslationFields.Name),
            NameEn = enFor(ContentTranslationFields.Name),
            DescriptionAr = arFor(ContentTranslationFields.Description),
            DescriptionEn = enFor(ContentTranslationFields.Description),
            RetailDescriptionAr = arFor(ContentTranslationFields.RetailDescription),
            RetailDescriptionEn = enFor(ContentTranslationFields.RetailDescription),
        };
    }

    /// <summary>
    /// True when next equals stored, or next/stored are the EN/AR translation pair of the same field
    /// (common when NameEn column still holds source Arabic while the client resubmits English).
    /// </summary>
    private static bool LocalizedFieldUnchanged(
        string? stored,
        string? next,
        string? translationAr,
        string? translationEn)
    {
        if (TextEquals(stored, next))
        {
            return true;
        }

        var canonicalEn = FirstNonEmpty(
            translationEn,
            DetectLanguageHintIsArabic(stored) ? null : stored);
        var canonicalAr = FirstNonEmpty(
            translationAr,
            DetectLanguageHintIsArabic(stored) ? stored : null);

        if (!string.IsNullOrWhiteSpace(canonicalEn)
            && TextEquals(next, canonicalEn)
            && (TextEquals(stored, canonicalEn) || TextEquals(stored, canonicalAr)))
        {
            return true;
        }

        if (!string.IsNullOrWhiteSpace(canonicalAr)
            && TextEquals(next, canonicalAr)
            && (TextEquals(stored, canonicalAr) || TextEquals(stored, canonicalEn)))
        {
            return true;
        }

        return false;
    }

    private static bool BoolEquals(bool? left, bool? right) =>
        (left ?? false) == (right ?? false);

    /// <summary>
    /// Treat "7" / "7 days" and date-only vs ISO date as the same duration value.
    /// </summary>
    private static bool DurationFieldEquals(string? left, string? right)
    {
        if (TextEquals(left, right))
        {
            return true;
        }

        var leftDate = TryParseDurationDate(left);
        var rightDate = TryParseDurationDate(right);
        if (leftDate.HasValue && rightDate.HasValue)
        {
            return leftDate.Value == rightDate.Value;
        }

        var leftDays = TryParseDurationDayCount(left);
        var rightDays = TryParseDurationDayCount(right);
        return leftDays.HasValue && rightDays.HasValue && leftDays.Value == rightDays.Value;
    }

    private static DateOnly? TryParseDurationDate(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var text = value.Trim();
        if (DateOnly.TryParse(text, out var dateOnly))
        {
            return dateOnly;
        }

        if (DateTime.TryParse(
                text,
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.RoundtripKind,
                out var dateTime))
        {
            return DateOnly.FromDateTime(dateTime);
        }

        return null;
    }

    private static int? TryParseDurationDayCount(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var text = value.Trim();
        if (int.TryParse(text, out var days) && days > 0)
        {
            return days;
        }

        // "7 days", "7 day", etc. — not a calendar date.
        if (TryParseDurationDate(text).HasValue)
        {
            return null;
        }

        var match = System.Text.RegularExpressions.Regex.Match(text, @"^\s*(\d+)\s");
        if (match.Success
            && int.TryParse(match.Groups[1].Value, out var leading)
            && leading > 0)
        {
            return leading;
        }

        return null;
    }

    private static bool HasAnyGeoInput(CreateProductInput input, ProductReferenceBundle refs) =>
        refs.OriginCountry is not null
        || refs.DestinationCountry is not null
        || refs.LoadingPort is not null
        || refs.ArrivalPort is not null
        || !string.IsNullOrWhiteSpace(input.OriginCountryName)
        || !string.IsNullOrWhiteSpace(input.DestinationCountryName)
        || !string.IsNullOrWhiteSpace(input.LoadingPortName)
        || !string.IsNullOrWhiteSpace(input.ArrivalPortName);

    /// <summary>
    /// Retail unit/packaging/description must stay the same;
    /// <see cref="Product.RetailPrice"/> and <see cref="Product.RetailQuantity"/> may change
    /// without admin reapproval (same rule as wholesale price/qty).
    /// </summary>
    private static bool RetailChannelUnchangedExceptPriceAndQuantity(
        Product existing,
        CreateProductInput input,
        ProductReferenceBundle refs,
        byte? nextCategoryId,
        byte? nextProductTypeId)
    {
        var isCategory = ProductTypeCodes.IsCategoryProduct(nextCategoryId, nextProductTypeId);

        if (!isCategory)
        {
            return existing.RetailPrice is null
                && existing.RetailUnitId is null
                && existing.RetailQuantity is null
                && existing.RetailPackaging is null
                && string.IsNullOrWhiteSpace(existing.RetailPackagingDetails)
                && string.IsNullOrWhiteSpace(existing.RetailDescriptionEn);
        }

        if (input.EnableRetailPricing == false)
        {
            return existing.RetailPrice is null
                && existing.RetailUnitId is null
                && existing.RetailQuantity is null
                && existing.RetailPackaging is null
                && string.IsNullOrWhiteSpace(existing.RetailPackagingDetails)
                && string.IsNullOrWhiteSpace(existing.RetailDescriptionEn);
        }

        var touchingRetail = input.EnableRetailPricing == true
            || input.RetailPrice.HasValue
            || !string.IsNullOrWhiteSpace(input.RetailUnitName)
            || input.RetailQuantity.HasValue
            || refs.RetailUnit is not null
            || input.RetailPackaging.HasValue
            || !string.IsNullOrWhiteSpace(input.RetailPackagingDetails)
            || !string.IsNullOrWhiteSpace(input.RetailDescriptionEn);

        if (!touchingRetail)
        {
            return true;
        }

        // Allow RetailPrice + RetailQuantity to differ; other retail channel fields must match.
        // Omitted retail fields mean "unchanged" (do not treat null as clearing).
        var nextRetailUnitId = refs.RetailUnit?.Id ?? existing.RetailUnitId;
        var nextRetailPackaging = input.RetailPackaging.HasValue
            ? NormalizePackaging(input.RetailPackaging)
            : existing.RetailPackaging;
        var nextRetailPackagingDetails = string.IsNullOrWhiteSpace(input.RetailPackagingDetails)
            ? existing.RetailPackagingDetails
            : input.RetailPackagingDetails.Trim();
        var nextRetailDescription = string.IsNullOrWhiteSpace(input.RetailDescriptionEn)
            ? existing.RetailDescriptionEn
            : input.RetailDescriptionEn.Trim();

        return existing.RetailUnitId == nextRetailUnitId
            && existing.RetailPackaging == nextRetailPackaging
            && TextEquals(existing.RetailPackagingDetails, nextRetailPackagingDetails)
            && TextEquals(existing.RetailDescriptionEn, nextRetailDescription);
    }

    private static void ValidateRetailPricing(
        CreateProductInput input,
        byte? categoryId,
        byte? productTypeId,
        ProductReferenceBundle refs)
    {
        // Form classification: category products send CategoryId with no ProductTypeName.
        var isCategoryListing = categoryId.HasValue
            && (!productTypeId.HasValue || productTypeId == ProductTypeCodes.Retail);
        var anyRetailFieldSet = input.RetailPrice.HasValue
            || !string.IsNullOrWhiteSpace(input.RetailUnitName)
            || input.RetailQuantity.HasValue
            || refs.RetailUnit is not null
            || input.EnableRetailPricing == true
            || input.RetailPackaging.HasValue
            || !string.IsNullOrWhiteSpace(input.RetailPackagingDetails)
            || !string.IsNullOrWhiteSpace(input.RetailDescriptionEn);

        if (!isCategoryListing)
        {
            if (anyRetailFieldSet)
            {
                throw new ArgumentException("Retail pricing is only allowed for category products.");
            }

            return;
        }

        if (input.EnableRetailPricing == false)
        {
            return;
        }

        if (!anyRetailFieldSet)
        {
            return;
        }

        if (input.RetailPrice is not > 0)
        {
            throw new ArgumentException("RetailPrice must be greater than zero when retail pricing is enabled.");
        }

        if (refs.RetailUnit is null || string.IsNullOrWhiteSpace(input.RetailUnitName))
        {
            throw new ArgumentException("RetailUnitName is required when retail pricing is enabled.");
        }

        if (input.RetailQuantity is not > 0)
        {
            throw new ArgumentException("RetailQuantity must be greater than zero when retail pricing is enabled.");
        }

        if (string.IsNullOrWhiteSpace(input.RetailDescriptionEn))
        {
            throw new ArgumentException("RetailDescriptionEn (retail specifications) is required when retail pricing is enabled.");
        }

        _ = NormalizePackaging(input.RetailPackaging);
    }

    private async Task ApplyRetailPricingToProductAsync(
        Product product,
        CreateProductInput input,
        ProductReferenceBundle refs,
        byte? categoryId,
        byte? productTypeId,
        CancellationToken cancellationToken = default)
    {
        // Pure service-type listings (no category) never carry dual retail columns.
        if (!categoryId.HasValue)
        {
            product.RetailPrice = null;
            product.RetailUnitId = null;
            product.RetailQuantity = null;
            product.RetailPackaging = null;
            product.RetailPackagingDetails = null;
            product.RetailDescriptionEn = null;
            product.RetailCode = null;
            return;
        }

        if (input.EnableRetailPricing == false)
        {
            product.RetailPrice = null;
            product.RetailUnitId = null;
            product.RetailQuantity = null;
            product.RetailPackaging = null;
            product.RetailPackagingDetails = null;
            product.RetailDescriptionEn = null;
            product.RetailCode = null;
            // Category-only listing again (not dual Retail).
            if (product.ProductTypeId == ProductTypeCodes.Retail)
            {
                product.ProductTypeId = null;
            }

            return;
        }

        var applying = input.EnableRetailPricing == true
            || input.RetailPrice.HasValue
            || refs.RetailUnit is not null
            || input.RetailQuantity.HasValue
            || input.RetailPackaging.HasValue
            || !string.IsNullOrWhiteSpace(input.RetailDescriptionEn);

        if (!applying)
        {
            return;
        }

        if (input.RetailPrice.HasValue)
        {
            product.RetailPrice = input.RetailPrice;
        }

        if (refs.RetailUnit is not null)
        {
            product.RetailUnitId = refs.RetailUnit.Id;
        }

        if (input.RetailQuantity.HasValue)
        {
            product.RetailQuantity = input.RetailQuantity;
        }

        if (input.RetailPackaging.HasValue)
        {
            product.RetailPackaging = NormalizePackaging(input.RetailPackaging);
        }

        if (!string.IsNullOrWhiteSpace(input.RetailPackagingDetails))
        {
            product.RetailPackagingDetails = input.RetailPackagingDetails.Trim();
        }

        if (!string.IsNullOrWhiteSpace(input.RetailDescriptionEn))
        {
            product.RetailDescriptionEn = input.RetailDescriptionEn.Trim();
        }

        // Dual-list in Retail feed: CategoryId stays set + ProductTypeId = Retail (1).
        product.ProductTypeId = ProductTypeCodes.Retail;

        if (string.IsNullOrWhiteSpace(product.RetailCode)
            && ProductTypeCodes.HasRetailStockConfigured(product))
        {
            product.RetailCode = await AllocateProductCodeAsync(cancellationToken).ConfigureAwait(false);
        }
    }

    /// <summary>
    /// Arabic edit forms may POST localized display text into NameEn/DescriptionEn.
    /// When the payload matches the existing Arabic translation (or the stored English),
    /// keep the stored English so price/qty-only edits do not look like name changes.
    /// Real Arabic or English edits must be persisted as submitted.
    /// </summary>
    private async Task SanitizeOwnerEditLocalizedFieldsAsync(
        Product product,
        CreateProductInput input,
        CancellationToken cancellationToken)
    {
        var rows = await productData.GetProductEditTranslationHintsAsync(product.ProductId, cancellationToken);

        string? arFor(string field) =>
            rows.FirstOrDefault(r => r.Field == field)?.TextAr;
        string? enFor(string field) =>
            rows.FirstOrDefault(r => r.Field == field)?.TextEn;

        input.NameEn = SanitizeLocalizedField(
            input.NameEn,
            product.NameEn,
            arFor(ContentTranslationFields.Name),
            enFor(ContentTranslationFields.Name));
        input.DescriptionEn = SanitizeLocalizedField(
            input.DescriptionEn,
            product.DescriptionEn,
            arFor(ContentTranslationFields.Description),
            enFor(ContentTranslationFields.Description));
        input.RetailDescriptionEn = SanitizeLocalizedField(
            input.RetailDescriptionEn,
            product.RetailDescriptionEn,
            arFor(ContentTranslationFields.RetailDescription),
            enFor(ContentTranslationFields.RetailDescription));
    }

    private static string? SanitizeLocalizedField(
        string? submitted,
        string? storedEn,
        string? translationAr,
        string? translationEn)
    {
        if (string.IsNullOrWhiteSpace(submitted))
        {
            return submitted;
        }

        var canonicalEn = FirstNonEmpty(translationEn, storedEn);
        if (string.IsNullOrWhiteSpace(canonicalEn))
        {
            return submitted;
        }

        // Unchanged localized display (or already English) → keep stored English.
        if (TextEquals(submitted, translationAr)
            || TextEquals(submitted, canonicalEn))
        {
            return canonicalEn;
        }

        // Real edit in Arabic or English — persist as submitted.
        return submitted;
    }

    private static bool TextEquals(string? left, string? right) =>
        string.Equals(
            string.IsNullOrWhiteSpace(left) ? null : left.Trim(),
            string.IsNullOrWhiteSpace(right) ? null : right.Trim(),
            StringComparison.Ordinal);
}
