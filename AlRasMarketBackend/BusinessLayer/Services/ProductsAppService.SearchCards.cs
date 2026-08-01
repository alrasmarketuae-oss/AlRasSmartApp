using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using DataLayer.Models;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class ProductsAppService
{
    /// <summary>
    /// Lightweight search cards: Redis first, then batch SQL hydrate for misses.
    /// Omits documents / address / long notes — details load on product open.
    /// </summary>
    private async Task<List<object>> BuildSearchProductCardItemsAsync(
        IReadOnlyList<ProductPublicRow> products,
        CancellationToken cancellationToken)
    {
        if (products.Count == 0)
        {
            return [];
        }

        var projections = new List<(ProductPublicRow Row, bool ProjectRetail, string Channel)>();
        foreach (var product in products)
        {
            if (ProductTypeCodes.IsHybridDualListing(product.CategoryId, product.ProductTypeId))
            {
                projections.Add((product, ProjectRetail: true, Channel: "retail"));
                projections.Add((product, ProjectRetail: false, Channel: "category"));
            }
            else
            {
                projections.Add((product, ProjectRetail: false, Channel: "default"));
            }
        }

        var items = new object?[projections.Count];
        var missIndexes = new List<int>(projections.Count);

        var cacheLookups = await Task.WhenAll(projections.Select(async (p, i) =>
        {
            var cached = await TryGetProductCacheAsync(
                SearchCardCacheKey(p.Row.ProductId, p.Channel),
                cancellationToken);
            return (Index: i, Value: cached);
        }));

        foreach (var (index, value) in cacheLookups)
        {
            if (value is not null)
            {
                items[index] = value;
            }
            else
            {
                missIndexes.Add(index);
            }
        }

        if (missIndexes.Count == 0)
        {
            return items.Cast<object>().ToList();
        }

        var missRows = missIndexes
            .Select(i => projections[i].Row)
            .GroupBy(r => r.ProductId)
            .Select(g => g.First())
            .ToList();

        var builtByKey = await BuildSearchCardsFromSqlAsync(missRows, cancellationToken);

        foreach (var index in missIndexes)
        {
            var (row, _, channel) = projections[index];
            var cacheKey = SearchCardCacheKey(row.ProductId, channel);
            if (!builtByKey.TryGetValue((row.ProductId, channel), out var card))
            {
                logger.LogWarning(
                    "Search card missing after SQL hydrate for {ProductId}/{Channel}",
                    row.ProductId,
                    channel);
                continue;
            }

            items[index] = card;
            await SetProductCacheAsync(cacheKey, card, SearchCardCacheTtl, cancellationToken);
        }

        return items.Where(x => x is not null).Cast<object>().ToList();
    }

    private string SearchCardCacheKey(Guid productId, string channel) =>
        $"products:search-card:v13:v{SearchProductsCacheVersion}:{productId:D}:{channel}";

    private async Task<Dictionary<(Guid ProductId, string Channel), object>> BuildSearchCardsFromSqlAsync(
        IReadOnlyList<ProductPublicRow> products,
        CancellationToken cancellationToken)
    {
        var result = new Dictionary<(Guid, string), object>();
        if (products.Count == 0)
        {
            return result;
        }

        var productIds = products.Select(p => p.ProductId).Distinct().ToList();

        // Batch media + name translations only (no documents / address / extra video tables).
        var imagesLookup = await productData.GetProductImagePathsByProductIdsAsync(productIds, cancellationToken);
        var imagesDict = imagesLookup
            .GroupBy(x => x.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.Select(x => x.Path).Take(3).ToList());

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);

        var (commissionSettings, categoryCommissions, usdToAedRate) =
            await GetPricingContextAsync(cancellationToken);

        foreach (var x in products)
        {
            translations.TryGetValue(x.ProductId, out var tr);
            var nameEn = FirstNonEmpty(tr?.NameEn, x.NameEn);
            var nameAr = FirstNonEmpty(tr?.NameAr, DetectLanguageHintIsArabic(x.NameEn) ? x.NameEn : null);
            var descriptionEn = TruncateForSearchCard(FirstNonEmpty(tr?.DescriptionEn, x.DescriptionEn));
            var descriptionAr = TruncateForSearchCard(FirstNonEmpty(
                tr?.DescriptionAr,
                DetectLanguageHintIsArabic(x.DescriptionEn) ? x.DescriptionEn : null));

            imagesDict.TryGetValue(x.ProductId, out var images);
            images ??= [];

            void AddCard(bool projectRetail, string channel)
            {
                result[(x.ProductId, channel)] = MapSearchCard(
                    x,
                    projectRetail,
                    channel,
                    images,
                    nameEn,
                    nameAr,
                    descriptionEn,
                    descriptionAr,
                    commissionSettings,
                    categoryCommissions,
                    usdToAedRate);
            }

            if (ProductTypeCodes.IsHybridDualListing(x.CategoryId, x.ProductTypeId))
            {
                AddCard(projectRetail: true, channel: "retail");
                AddCard(projectRetail: false, channel: "category");
            }
            else
            {
                AddCard(projectRetail: false, channel: "default");
            }
        }

        return result;
    }

    private static object MapSearchCard(
        ProductPublicRow x,
        bool projectRetail,
        string channel,
        IReadOnlyList<string> images,
        string? nameEn,
        string? nameAr,
        string? descriptionEn,
        string? descriptionAr,
        CommissionSettingsSnapshot commissionSettings,
        IReadOnlyDictionary<byte, decimal> categoryCommissions,
        decimal usdToAedRate)
    {
        var (unitPrice, discountPercentage, discountDays) = ResolveOfferPricing(x);
        var hasRetailPricing = ProductTypeCodes.HasRetailPricing(
            x.CategoryId,
            x.ProductTypeId,
            x.RetailPrice,
            x.RetailUnitId,
            x.RetailQuantity);

        var wholesalePriced = BuildCustomerFacingPrice(
            unitPrice,
            ProductTypeCodes.WholesaleCommissionProductTypeId(x.CategoryId, x.ProductTypeId),
            x.CategoryId,
            x.Currency,
            commissionSettings,
            categoryCommissions,
            usdToAedRate);

        CustomerFacingPrice? retailPriced = null;
        if (hasRetailPricing && x.RetailPrice is > 0)
        {
            retailPriced = BuildCustomerFacingPrice(
                x.RetailPrice.Value,
                ProductTypeCodes.Retail,
                categoryId: null,
                "AED",
                commissionSettings,
                categoryCommissions,
                usdToAedRate);
        }

        var useRetailPrimary = projectRetail && hasRetailPricing && retailPriced is not null;
        var priced = useRetailPrimary ? retailPriced!.Value : wholesalePriced;
        var displayQuantity = useRetailPrimary ? (x.RetailQuantity ?? 0) : x.Quantity;

        var wholesaleUnitNameEn = x.UnitName;
        var wholesaleUnitNameAr = CatalogLocalizationHelper.UnitNameAr(x.UnitName);
        var retailUnitNameEn = x.RetailUnitName;
        var retailUnitNameAr = CatalogLocalizationHelper.UnitNameAr(x.RetailUnitName);
        var displayUnitNameEn = useRetailPrimary ? retailUnitNameEn : wholesaleUnitNameEn;
        var displayUnitNameAr = useRetailPrimary ? retailUnitNameAr : wholesaleUnitNameAr;

        var isHomeCatalogShape = channel == "category"
            && ProductTypeCodes.IsCategoryProduct(x.CategoryId, x.ProductTypeId);
        var responseProductTypeId = useRetailPrimary
            ? ProductTypeCodes.Retail
            : (isHomeCatalogShape ? null : x.ProductTypeId);
        var responseProductTypeNameEn = useRetailPrimary
            ? (x.ProductTypeName ?? "Retail")
            : (isHomeCatalogShape ? null : x.ProductTypeName);
        var responseProductTypeNameAr = responseProductTypeNameEn is null
            ? null
            : CatalogLocalizationHelper.ProductTypeNameAr(responseProductTypeId, responseProductTypeNameEn);

        var statusNameEn = CatalogLocalizationHelper.StatusNameEn(x.Status, x.IsApproved);
        var statusNameAr = CatalogLocalizationHelper.StatusNameAr(x.Status, x.IsApproved);
        var approvalStatusEn = CatalogLocalizationHelper.ApprovalStatusEn(x.Status, x.IsApproved);
        var approvalStatusAr = CatalogLocalizationHelper.ApprovalStatusAr(x.Status, x.IsApproved);

        var primaryDescriptionEn = useRetailPrimary
            ? TruncateForSearchCard(FirstNonEmpty(x.RetailDescriptionEn, descriptionEn))
            : descriptionEn;
        var primaryDescriptionAr = useRetailPrimary
            ? TruncateForSearchCard(descriptionAr)
            : descriptionAr;

        var videoPath = string.IsNullOrWhiteSpace(x.VideoPath) ? null : x.VideoPath.Trim();

        return new
        {
            x.ProductId,
            productCode = x.ProductCode,
            nameEn,
            nameAr,
            price = priced.Price,
            currency = priced.Currency,
            priceAed = priced.PriceAed,
            usdPrice = priced.PriceUsd,
            Quantity = displayQuantity,
            description = primaryDescriptionEn,
            descriptionEn = primaryDescriptionEn,
            descriptionAr = primaryDescriptionAr,
            statusName = statusNameEn,
            statusNameEn,
            statusNameAr,
            approvalStatus = approvalStatusEn,
            approvalStatusEn,
            approvalStatusAr,
            isApproved = x.IsApproved,
            DiscountPercentage = discountPercentage,
            DiscountDays = discountDays,
            offerDuration = x.OfferDuration ?? string.Empty,
            x.Negotiable,
            x.IsFeatured,
            videoPath,
            videoPaths = videoPath is null ? Array.Empty<string>() : new[] { videoPath },
            videos = videoPath is null
                ? Array.Empty<object>()
                : new object[]
                {
                    new
                    {
                        path = videoPath,
                        videoPath,
                        durationSeconds = x.VideoDurationSeconds,
                        isMuted = true
                    }
                },
            videoDurationSeconds = x.VideoDurationSeconds,
            CreatedAt = UtcDateTimeHelper.FormatApiDateTime(x.CreatedAt),
            categoryId = x.CategoryId,
            categoryName = x.CategoryName,
            categoryNameEn = x.CategoryName,
            categoryNameAr = x.CategoryNameAr,
            productTypeId = responseProductTypeId,
            productTypeName = responseProductTypeNameEn,
            productTypeNameEn = responseProductTypeNameEn,
            productTypeNameAr = responseProductTypeNameAr,
            unitName = displayUnitNameEn,
            unitNameEn = displayUnitNameEn,
            unitNameAr = displayUnitNameAr,
            hasRetailPricing = channel != "category" && hasRetailPricing,
            retailPrice = channel != "category" ? retailPriced?.Price : null,
            retailPriceAed = channel != "category" ? retailPriced?.PriceAed : null,
            retailUnitName = channel != "category" ? retailUnitNameEn : null,
            retailUnitNameEn = channel != "category" ? retailUnitNameEn : null,
            retailUnitNameAr = channel != "category" ? retailUnitNameAr : null,
            retailQuantity = channel != "category" ? x.RetailQuantity : null,
            requestTypeId = x.RequestTypeId,
            requestTypeName = ResolveRequestTypeName(x.RequestTypeId, x.RequestTypeName),
            bookingPriceTypeId = x.BookingPriceTypeId,
            bookingPriceTypeName = ResolveBookingPriceTypeName(x.BookingPriceTypeId, x.BookingPriceTypeName),
            searchListingChannel = channel == "default" ? null : channel,
            images,
            documents = Array.Empty<string>()
        };
    }

    private static string? TruncateForSearchCard(string? text, int maxLen = 160)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            return text;
        }

        var trimmed = text.Trim();
        return trimmed.Length <= maxLen ? trimmed : trimmed[..maxLen].TrimEnd() + "…";
    }
}
