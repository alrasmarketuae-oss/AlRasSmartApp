using System.Data;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;
public partial class ProductsAppService
{
    private async Task<Guid?> ResolveProductAddressIdAsync(
        Guid ownerId,
        string? addressId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(addressId))
        {
            return null;
        }

        if (!Guid.TryParse(addressId.Trim(), out var parsedAddressId))
        {
            throw new ArgumentException("Invalid address id.");
        }

        var belongsToOwner = await productData.AddressBelongsToUserAsync(
            parsedAddressId,
            ownerId,
            cancellationToken);

        if (!belongsToOwner)
        {
            throw new KeyNotFoundException("Address not found for this user.");
        }

        return parsedAddressId;
    }

    private async Task<ProductReferenceBundle> ResolveProductReferencesAsync(
        CreateProductInput input,
        CancellationToken cancellationToken)
    {
        ProductType? productType = null;
        if (!string.IsNullOrWhiteSpace(input.ProductTypeName))
        {
            var typeSnap = staticReferenceCache.FindProductTypeByName(input.ProductTypeName)
                ?? throw new KeyNotFoundException($"Product type '{input.ProductTypeName}' was not found.");
            productType = new ProductType { Id = typeSnap.Id, TypeNameEn = typeSnap.TypeNameEn };
        }

        UnitSnapshot? unit = null;
        if (!string.IsNullOrWhiteSpace(input.UnitName))
        {
            unit = staticReferenceCache.FindUnitByName(input.UnitName)
                ?? throw new KeyNotFoundException($"Unit '{input.UnitName}' was not found.");
        }

        UnitSnapshot? retailUnit = null;
        if (!string.IsNullOrWhiteSpace(input.RetailUnitName))
        {
            retailUnit = staticReferenceCache.FindUnitByName(input.RetailUnitName)
                ?? throw new KeyNotFoundException($"Retail unit '{input.RetailUnitName}' was not found.");
        }

        GeoCountrySnapshot? originCountry = null;
        GeoPortSnapshot? loadingPort = null;
        if (!string.IsNullOrWhiteSpace(input.OriginCountryName))
        {
            originCountry = staticReferenceCache.FindCountryByName(input.OriginCountryName)
                ?? throw BuildCountryNotFoundException("Origin country", input.OriginCountryName);

            if (!string.IsNullOrWhiteSpace(input.LoadingPortName))
            {
                loadingPort = staticReferenceCache.FindPortByName(input.LoadingPortName, originCountry.Id)
                    ?? throw BuildPortNotFoundException(
                        "Loading port",
                        input.LoadingPortName,
                        originCountry);
            }
        }

        GeoCountrySnapshot? destinationCountry = null;
        GeoPortSnapshot? arrivalPort = null;
        if (!string.IsNullOrWhiteSpace(input.DestinationCountryName))
        {
            destinationCountry = staticReferenceCache.FindCountryByName(input.DestinationCountryName)
                ?? throw BuildCountryNotFoundException("Destination country", input.DestinationCountryName);

            if (!string.IsNullOrWhiteSpace(input.ArrivalPortName))
            {
                arrivalPort = staticReferenceCache.FindPortByName(input.ArrivalPortName, destinationCountry.Id)
                    ?? throw BuildPortNotFoundException(
                        "Arrival port",
                        input.ArrivalPortName,
                        destinationCountry);
            }
        }

        RequestType? requestType = null;
        byte? parsedCategoryId = null;
        if (!string.IsNullOrWhiteSpace(input.CategoryId) &&
            byte.TryParse(input.CategoryId.Trim(), out var categoryIdValue))
        {
            parsedCategoryId = categoryIdValue;
        }

        var requiresPriceType =
            productType?.Id == ProductTypeCodes.Requests
            || productType?.Id == ProductTypeCodes.Offers
            || parsedCategoryId.HasValue;

        if (requiresPriceType
            || input.RequestTypeId.HasValue
            || !string.IsNullOrWhiteSpace(input.RequestTypeName))
        {
            if (input.RequestTypeId.HasValue)
            {
                var snap = staticReferenceCache.FindRequestTypeById(input.RequestTypeId.Value)
                    ?? throw new KeyNotFoundException($"Request type id '{input.RequestTypeId}' was not found.");
                requestType = new RequestType { Id = snap.Id, NameEn = snap.NameEn };
            }
            else if (!string.IsNullOrWhiteSpace(input.RequestTypeName))
            {
                var requestTypeName = NormalizeRequestTypeName(input.RequestTypeName);
                var snap = staticReferenceCache.FindRequestTypeByName(requestTypeName)
                    ?? throw new KeyNotFoundException($"Request type '{input.RequestTypeName}' was not found.");
                requestType = new RequestType { Id = snap.Id, NameEn = snap.NameEn };
            }
            else if (requiresPriceType)
            {
                // Admin UI does not edit Price Type; UpdateProductAsync passes the existing id.
                // If missing on a legacy row, skip hard-fail — UpdateAsync keeps the current value.
                var isAdminPartialUpdate = input is UpdateProductInput { AllowAdminUpdate: true };
                if (!isAdminPartialUpdate)
                {
                    throw new ArgumentException("Price Type (Local / Rexport) is required for Requests, Offers, and Categories products.");
                }
            }
        }

        BookingPriceType? bookingPriceType = null;
        if (input.BookingPriceTypeId.HasValue
            || !string.IsNullOrWhiteSpace(input.BookingPriceTypeName))
        {
            if (input.BookingPriceTypeId.HasValue)
            {
                var snap = staticReferenceCache.FindBookingPriceTypeById(input.BookingPriceTypeId.Value)
                    ?? throw new KeyNotFoundException($"Booking price type id '{input.BookingPriceTypeId}' was not found.");
                bookingPriceType = new BookingPriceType { Id = snap.Id, NameEn = snap.NameEn };
            }
            else
            {
                var bookingPriceTypeName = NormalizeBookingPriceTypeName(input.BookingPriceTypeName!);
                var snap = staticReferenceCache.FindBookingPriceTypeByName(bookingPriceTypeName)
                    ?? throw new KeyNotFoundException($"Booking price type '{input.BookingPriceTypeName}' was not found.");
                bookingPriceType = new BookingPriceType { Id = snap.Id, NameEn = snap.NameEn };
            }
        }

        return new ProductReferenceBundle
        {
            ProductType = productType,
            RequestType = requestType,
            BookingPriceType = bookingPriceType,
            Unit = unit,
            RetailUnit = retailUnit,
            OriginCountry = originCountry,
            DestinationCountry = destinationCountry,
            LoadingPort = loadingPort,
            ArrivalPort = arrivalPort
        };
    }

    private static string NormalizeRequestTypeName(string name)
    {
        var normalized = name.Trim().ToLowerInvariant();
        return normalized switch
        {
            "booking" or "re-export" or "re_export" or "rexport" => "reexport",
            _ => normalized
        };
    }

    private static string NormalizeBookingPriceTypeName(string name)
    {
        var normalized = name.Trim().ToUpperInvariant();
        return normalized switch
        {
            "C&F" or "C AND F" or "CANDF" => "CNF",
            _ => normalized
        };
    }

    private async Task<string?> ResolveVideoPathAsync(
        CreateProductInput input,
        string? existingVideoPath,
        CancellationToken cancellationToken)
    {
        if (input.ProductVideoFile is null)
        {
            return existingVideoPath;
        }

        if (input.ProductVideoFile.Length == 0)
        {
            throw new ArgumentException("Product video file is empty.");
        }

        if (!input.VideoDurationSeconds.HasValue)
        {
            throw new ArgumentException("VideoDurationSeconds is required when ProductVideoFile is provided.");
        }

        if (input.VideoDurationSeconds.Value <= 0 || input.VideoDurationSeconds.Value > 180)
        {
            throw new ArgumentException("Product video duration must be between 1 and 180 seconds.");
        }

        var extension = Path.GetExtension(input.ProductVideoFile.FileName).ToLowerInvariant();
        var allowed = new[] { ".mp4", ".mov", ".webm", ".m4v" };
        if (!allowed.Contains(extension))
        {
            throw new ArgumentException("Unsupported product video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        var videoFileName = $"video-{Guid.NewGuid():N}{extension}";
        var videoPath = await mediaStorage.SaveFormFileAsync(
            input.ProductVideoFile,
            "product-videos",
            videoFileName,
            cancellationToken: cancellationToken);

        if (!string.IsNullOrWhiteSpace(existingVideoPath))
        {
            // Owner edits keep the previous video on disk until admin approve/reject.
            var isOwnerEdit = input is UpdateProductInput update && !update.AllowAdminUpdate;
            if (!isOwnerEdit)
            {
                await mediaStorage.DeleteAsync(existingVideoPath, cancellationToken);
            }
        }

        logger.LogInformation(
            "Product video saved. Size={SizeBytes} Duration={DurationSeconds}s Path={Path}",
            input.ProductVideoFile.Length,
            input.VideoDurationSeconds.Value,
            videoFileName);

        return videoPath;
    }

    private Task<string> AllocateProductCodeAsync(CancellationToken cancellationToken) =>
        productData.AllocateProductCodeAsync(cancellationToken);

    private static object BuildProductMutationResponse(
        Product product,
        ProductReferenceBundle refs,
        string? addressText = null,
        bool requiresAdminReview = true)
    {
        var videos = ProductVideoPathsHelper.ResolveVideoItems(
            product.VideoPath,
            product.VideoDurationSeconds,
            product.ProductVideos);

        return new
        {
            saved = true,
            productId = product.ProductId,
            productCode = product.ProductCode,
            ownerId = product.OwnerId,
            product.NameEn,
            product.USDPrice,
            currency = product.Currency,
            product.Quantity,
            status = ProductStatusCodes.ToDisplayName(product.Status, product.IsApproved),
            approvalStatus = GetApprovalStatusText(product.Status, product.IsApproved),
            isApproved = product.IsApproved == true,
            requiresAdminReview,
            message = requiresAdminReview
                ? "Product saved successfully and is pending admin approval."
                : "Product saved successfully.",
            productType = refs.ProductType?.TypeNameEn,
            unit = refs.Unit?.UnitNameEn,
            categoryId = product.CategoryId,
            originCountry = refs.OriginCountry?.CountryNameEn,
            destinationCountry = refs.DestinationCountry?.CountryNameEn,
            loadingPort = refs.LoadingPort?.PortNameEn,
            arrivalPort = refs.ArrivalPort?.PortNameEn,
            videoPath = videos.FirstOrDefault()?.Path,
            videoPaths = videos.Select(x => x.Path),
            videos = videos.Select(x => new
            {
                x.Id,
                path = x.Path,
                videoPath = x.Path,
                durationSeconds = x.DurationSeconds,
                isMuted = x.IsMuted
            }),
            videoDurationSeconds = videos.FirstOrDefault()?.DurationSeconds,
            shippingDuration = product.ShippingDuration,
            offerDuration = product.OfferDuration,
            addressId = product.AddressId,
            address = product.AddressId.HasValue ? addressText : null,
            hasRetailPricing = ProductTypeCodes.HasRetailPricing(product),
            retailPrice = product.RetailPrice,
            retailUnitId = product.RetailUnitId,
            retailUnitName = refs.RetailUnit?.UnitNameEn,
            retailQuantity = product.RetailQuantity,
            retailPackaging = product.RetailPackaging,
            retailPackagingDetails = product.RetailPackagingDetails,
            retailDescription = product.RetailDescriptionEn,
            requestType = refs.RequestType?.NameEn,
            requestTypeId = refs.RequestType?.Id,
            bookingPriceType = refs.BookingPriceType?.NameEn,
            bookingPriceTypeId = refs.BookingPriceType?.Id
        };
    }

    private static decimal ApplyCustomerPrice(
        decimal usdPrice,
        byte? productTypeId,
        byte? categoryId,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions) =>
        CustomerPriceCalculator.ApplyProductMarkup(
            usdPrice,
            productTypeId,
            categoryId,
            settings,
            categoryCommissions);

    private decimal GetUsdToAedRate() =>
        CurrencyConversionHelper.GetUsdToAedRate(configuration);

    private static CustomerFacingPrice BuildCustomerFacingPrice(
        decimal baseUsdPrice,
        byte? productTypeId,
        byte? categoryId,
        string? productCurrency,
        CommissionSettingsSnapshot settings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate)
    {
        var markedUpUsd = ApplyCustomerPrice(
            baseUsdPrice,
            productTypeId,
            categoryId,
            settings,
            categoryCommissions);
        return CustomerPriceCalculator.RoundUpToQuarter(
            ProductPricePresenter.Present(markedUpUsd, productTypeId, productCurrency, usdToAedRate));
    }

    /// <summary>
    /// Offer products store the sale (after-discount) unit price.
    /// When DiscountDays have elapsed, restore the pre-discount price and clear offer flags.
    /// </summary>
    private static (decimal UnitPrice, byte? DiscountPercentage, short? DiscountDays) ResolveOfferPricing(
        ProductPublicRow product)
    {
        return ResolveOfferPricing(
            product.USDPrice,
            product.DiscountPercentage,
            product.DiscountDays,
            product.CreatedAt);
    }

    private static (decimal UnitPrice, byte? DiscountPercentage, short? DiscountDays) ResolveOfferPricing(
        decimal usdPrice,
        byte? discountPercentage,
        short? discountDays,
        DateTime createdAt)
    {
        var unitPrice = usdPrice;
        var resolvedDiscountPercentage = discountPercentage;
        var resolvedDiscountDays = discountDays;

        if (resolvedDiscountPercentage is not > 0 || resolvedDiscountDays is not > 0)
        {
            return (unitPrice, resolvedDiscountPercentage, resolvedDiscountDays);
        }

        var createdAtUtc = UtcDateTimeHelper.AsUtc(createdAt);
        var endsAt = createdAtUtc.AddDays(resolvedDiscountDays.Value);
        if (UtcDateTimeHelper.UtcNow < endsAt)
        {
            return (unitPrice, resolvedDiscountPercentage, resolvedDiscountDays);
        }

        var factor = 1m - (resolvedDiscountPercentage.Value / 100m);
        if (factor > 0)
        {
            unitPrice = decimal.Round(unitPrice / factor, 2, MidpointRounding.AwayFromZero);
        }

        return (unitPrice, null, null);
    }

    private static bool IsOfferProduct(byte? productTypeId) =>
        ProductTypeCodes.IsOffers(productTypeId);

    private static CustomerFacingPrice BuildSupplierFacingPrice(
        decimal baseUsdPrice,
        byte? productTypeId,
        string? productCurrency,
        decimal usdToAedRate) =>
        ProductPricePresenter.Present(baseUsdPrice, productTypeId, productCurrency, usdToAedRate);

    private static string ResolveProductCurrency(string? currency, byte? productTypeId) =>
        ProductCurrencyHelper.Normalize(currency, productTypeId);

    private async Task<(CommissionSettingsSnapshot Settings, IReadOnlyDictionary<byte, decimal> CategoryCommissions, decimal UsdToAedRate)> GetPricingContextAsync(
        CancellationToken cancellationToken)
    {
        var settings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        return (settings, categoryCommissions, GetUsdToAedRate());
    }

    private async Task<IReadOnlyDictionary<Guid, string>> LoadAddressTextLookupAsync(
        IEnumerable<Guid?> addressIds,
        CancellationToken cancellationToken)
    {
        var ids = addressIds
            .Where(x => x.HasValue)
            .Select(x => x!.Value)
            .Distinct()
            .ToList();

        if (ids.Count == 0)
        {
            return new Dictionary<Guid, string>();
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var rows = await productData.GetAddressDisplayRowsByIdsAsync(ids, cancellationToken);

        return rows.ToDictionary(
            x => x.Id,
            x => FormatAddressDisplayText(
                x.AddressLine1,
                x.AddressLine2,
                staticReferenceCache.FindCityById(x.CityId)?.CityName));
    }

    private static string? ResolveAddressText(
        Guid? addressId,
        IReadOnlyDictionary<Guid, string> lookup)
    {
        if (!addressId.HasValue)
        {
            return null;
        }

        return lookup.TryGetValue(addressId.Value, out var text) ? text : null;
    }

    private static string FormatAddressDisplayText(string line1, string? line2, string? cityName)
    {
        var parts = new List<string>(3);
        if (!string.IsNullOrWhiteSpace(line1))
        {
            parts.Add(line1.Trim());
        }

        if (!string.IsNullOrWhiteSpace(line2))
        {
            parts.Add(line2.Trim());
        }

        if (!string.IsNullOrWhiteSpace(cityName))
        {
            parts.Add(cityName.Trim());
        }

        return parts.Count == 0 ? string.Empty : string.Join(", ", parts);
    }

    private KeyNotFoundException BuildCountryNotFoundException(string label, string input)
    {
        var suggestions = staticReferenceCache.SuggestCountries(input)
            .Select(x => x.CountryNameEn)
            .Take(5)
            .ToList();
        var hint = suggestions.Count > 0
            ? $" Did you mean: {string.Join(", ", suggestions)}?"
            : " Call lookup_create_ad_reference with lookup=countries.";
        return new KeyNotFoundException($"{label} '{input}' was not found.{hint}");
    }

    private KeyNotFoundException BuildPortNotFoundException(
        string label,
        string input,
        GeoCountrySnapshot country)
    {
        var suggestions = staticReferenceCache.SuggestPorts(input, country.Id)
            .Select(x => x.PortNameEn)
            .Take(8)
            .ToList();
        var hint = suggestions.Count > 0
            ? $" Did you mean: {string.Join(", ", suggestions)}?"
            : $" Call lookup_create_ad_reference with lookup=ports and country_name={country.CountryNameEn}.";
        return new KeyNotFoundException(
            $"{label} '{input}' was not found for country '{country.CountryNameEn}'.{hint}");
    }
}
