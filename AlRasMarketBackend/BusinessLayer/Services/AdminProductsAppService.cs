using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public class AdminProductsAppService(
    IRasAlSouqDbContext dbContext,
    IProductsAppService productsAppService,
    IProductAssetsAppService productAssetsAppService,
    IContentTranslationService contentTranslationService,
    IStaticReferenceCache staticReferenceCache,
    IServiceScopeFactory scopeFactory,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IAdminAuditLogAppService auditLogAppService,
    IMediaStorageService mediaStorage,
    IProductImageIndexingQueue productImageIndexingQueue,
    ILogger<AdminProductsAppService> logger) : IAdminProductsAppService
{
    private readonly IProductsAppService _productsAppService = productsAppService;
    private readonly IProductAssetsAppService _productAssetsAppService = productAssetsAppService;

    private void QueueTextSearchSync(Guid productId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var sync = scope.ServiceProvider.GetRequiredService<ProductTextSearchSyncService>();
                await sync.UpsertProductAsync(productId).ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background Meilisearch sync failed for admin product {ProductId}", productId);
            }
        });
    }

    public async Task<object> ReindexImageVectorsAsync(CancellationToken cancellationToken = default)
    {
        var imageIds = await dbContext.ProductImages
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        foreach (var imageId in imageIds)
        {
            await productImageIndexingQueue.EnqueueAsync(imageId, cancellationToken);
        }

        logger.LogInformation("Enqueued {Count} product images for CLIP reindex.", imageIds.Count);
        return new
        {
            enqueued = imageIds.Count,
            message = "CLIP reindex queued. Background workers will rebuild Qdrant vectors."
        };
    }

    public async Task<AdminProductStatsDto> GetProductStatsAsync(CancellationToken cancellationToken = default)
    {
        var utcNow = DateTime.UtcNow;
        var monthStart = new DateTime(utcNow.Year, utcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var prevMonthStart = monthStart.AddMonths(-1);

        var totalAds = await dbContext.Products.CountAsync(cancellationToken);
        var adsThisMonth = await dbContext.Products.CountAsync(x => x.CreatedAt >= monthStart, cancellationToken);
        var adsLastMonth = await dbContext.Products.CountAsync(
            x => x.CreatedAt >= prevMonthStart && x.CreatedAt < monthStart,
            cancellationToken);

        return new AdminProductStatsDto
        {
            TotalAds = totalAds,
            TotalAdsChangePercent = AdminMappings.PercentChange(adsThisMonth, adsLastMonth),
            OffersCount = await dbContext.Products.CountAsync(
                x => x.ProductTypeId == ProductTypeCodes.Offers,
                cancellationToken),
            RetailCount = await dbContext.Products.CountAsync(
                x => x.ProductTypeId == ProductTypeCodes.Retail,
                cancellationToken),
            BookingCount = await dbContext.Products.CountAsync(
                x => x.ProductTypeId == ProductTypeCodes.Booking,
                cancellationToken),
        };
    }

    public async Task<AdminPagedResult<AdminProductListItemDto>> GetProductsAsync(
        int page,
        int pageSize,
        string? search,
        string? approval,
        byte? categoryId,
        byte? status,
        byte? productTypeId,
        byte? excludeProductTypeId,
        DateTime? createdFrom,
        DateTime? createdTo,
        bool? hasPendingOffers = null,
        bool? editResubmitOnly = null,
        string? language = null,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var query = dbContext.Products.AsNoTracking().AsQueryable();

        // Hide ads that are still uploading media on the client.
        query = query.Where(x => x.IsReadyForAdminReview);

        if (editResubmitOnly == true)
        {
            // Seller edited a previously approved ad and sent it back for admin approval.
            query = query.Where(x =>
                x.IsApproved != true
                && x.Status != ProductStatusCodes.Rejected
                && x.PendingProductChanges != null
                && x.PendingProductChanges != string.Empty
                && (x.PendingProductChanges.Contains("\"IsApproved\":true")
                    || x.PendingProductChanges.Contains("\"isApproved\":true")));
        }
        else
        {
            var approvalFilter = (approval ?? "pending").Trim().ToLowerInvariant();
            query = approvalFilter switch
            {
                "approved" or "موافق" => query.Where(x => x.IsApproved == true),
                "rejected" or "مرفوض" => query.Where(x => x.Status == ProductStatusCodes.Rejected),
                "all" or "الكل" => query,
                _ => query.Where(x =>
                    x.IsApproved != true && x.Status != ProductStatusCodes.Rejected)
            };
        }

        if (categoryId.HasValue)
        {
            query = query.Where(x => x.CategoryId == categoryId.Value);
        }

        if (productTypeId.HasValue)
        {
            query = query.Where(x => x.ProductTypeId == productTypeId.Value);
        }

        if (excludeProductTypeId.HasValue)
        {
            query = query.Where(x => x.ProductTypeId != excludeProductTypeId.Value);
        }

        if (status.HasValue)
        {
            query = status.Value switch
            {
                ProductStatusCodes.UnderReview => query.Where(x =>
                    x.IsApproved != true && x.Status != ProductStatusCodes.Rejected),
                ProductStatusCodes.Rejected => query.Where(x => x.Status == ProductStatusCodes.Rejected),
                ProductStatusCodes.Active => query.Where(x =>
                    x.IsApproved == true && x.Status != ProductStatusCodes.Paused),
                ProductStatusCodes.Paused => query.Where(x => x.Status == ProductStatusCodes.Paused),
                _ => query.Where(x => x.Status == status.Value)
            };
        }

        if (createdFrom.HasValue)
        {
            var from = DateTime.SpecifyKind(createdFrom.Value.Date, DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt >= from);
        }

        if (createdTo.HasValue)
        {
            var to = DateTime.SpecifyKind(createdTo.Value.Date.AddDays(1), DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt < to);
        }

        if (hasPendingOffers == true)
        {
            query = query.Where(p =>
                dbContext.Orders.Any(o =>
                    o.ProductId == p.ProductId
                    && o.StatusId == OrderStatusCodes.Ordered
                    && !o.IsAdminApproved
                    && o.Product != null
                    && o.Product.ProductTypeId == ProductTypeCodes.Requests));
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            query = query.Where(x =>
                (x.NameEn != null && x.NameEn.ToLower().Contains(term))
                || (x.DescriptionEn != null && x.DescriptionEn.ToLower().Contains(term))
                || (x.Owner != null && x.Owner.FullName.ToLower().Contains(term))
                || (x.Owner != null && x.Owner.Email.ToLower().Contains(term))
                || (x.Owner != null && x.Owner.CompanyName != null && x.Owner.CompanyName.ToLower().Contains(term))
                || (x.Category != null && x.Category.NameEn.ToLower().Contains(term))
                || dbContext.ContentTranslations.Any(t =>
                    t.ProductId == x.ProductId
                    && t.Scope == ContentTranslationScopes.Product
                    && (t.Field == ContentTranslationFields.Name
                        || t.Field == ContentTranslationFields.Description)
                    && ((t.TextEn != null && t.TextEn.ToLower().Contains(term))
                        || (t.TextAr != null && t.TextAr.ToLower().Contains(term)))));
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var rawItems = await query
            // Newest ads first (by creation date).
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.ProductId,
                Name = x.NameEn ?? string.Empty,
                x.DescriptionEn,
                x.USDPrice,
                x.Currency,
                x.ProductTypeId,
                x.Quantity,
                x.Negotiable,
                CategoryName = x.Category != null ? x.Category.NameEn : "—",
                ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : "—",
                UnitName = x.Unit != null ? x.Unit.UnitNameEn : "—",
                OwnerName = x.Owner != null ? x.Owner.FullName : "—",
                OwnerCompanyName = x.Owner != null ? x.Owner.CompanyName : null,
                OwnerEmail = x.Owner != null ? x.Owner.Email : "—",
                x.Status,
                x.IsApproved,
                x.CreatedAt,
                x.UpdatedAt,
                x.PendingProductChanges,
                PrimaryImagePath = x.ProductImages
                    .OrderBy(pi => pi.Id)
                    .Select(pi => pi.ImagePath)
                    .FirstOrDefault(),
                ImagePaths = x.ProductImages
                    .OrderBy(pi => pi.Id)
                    .Select(pi => pi.ImagePath)
                    .ToList(),
                OriginCountryName = x.OriginCountry != null ? x.OriginCountry.CountryNameEn : null,
                DestinationCountryName = x.DestinationCountry != null ? x.DestinationCountry.CountryNameEn : null,
                LoadingPortName = x.LoadingPort != null ? x.LoadingPort.PortNameEn : null,
                ArrivalPortName = x.ArrivalPort != null ? x.ArrivalPort.PortNameEn : null,
                ShippingDescription = x.ShippingDescriptionEn,
                x.ShippingDuration,
                x.OfferDuration,
                AddressLine1 = x.Address != null ? x.Address.AddressLine1 : null,
                AddressLine2 = x.Address != null ? x.Address.AddressLine2 : null,
                CityName = x.Address != null && x.Address.City != null ? x.Address.City.CityName : null,
                x.CategoryId,
                x.RetailPrice,
                x.RetailUnitId,
                x.RetailQuantity,
                RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null,
                x.RequestTypeId,
                RequestTypeName = x.RequestType != null ? x.RequestType.NameEn : null,
                x.BookingPriceTypeId,
                BookingPriceTypeName = x.BookingPriceType != null ? x.BookingPriceType.NameEn : null,
                x.Packaging,
                x.PackagingDetails,
                RetailDescription = x.RetailDescriptionEn,
                x.RetailPackaging,
                x.RetailPackagingDetails
            })
            .ToListAsync(cancellationToken);

        var productIds = rawItems.Select(x => x.ProductId).ToList();
        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);
        var pendingOffersByProduct = await dbContext.Orders
            .AsNoTracking()
            .Where(o =>
                productIds.Contains(o.ProductId)
                && o.StatusId == OrderStatusCodes.Ordered
                && !o.IsAdminApproved
                && o.Product != null
                && o.Product.ProductTypeId == ProductTypeCodes.Requests)
            .GroupBy(o => o.ProductId)
            .Select(g => new { ProductId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.ProductId, x => x.Count, cancellationToken);

        var items = rawItems.Select(x =>
        {
            translations.TryGetValue(x.ProductId, out var tr);
            var currency = ProductCurrencyHelper.Normalize(x.Currency, x.ProductTypeId);
            return new AdminProductListItemDto
        {
            ProductId = x.ProductId,
            Name = AdminProductTextHelper.ResolveNameForLocale(tr, x.Name, language),
            Description = AdminProductTextHelper.ResolveDescriptionForLocale(tr, x.DescriptionEn, language),
            PriceUsd = x.USDPrice,
            Currency = currency,
            PriceFormatted = ProductCurrencyHelper.FormatPrice(x.USDPrice, currency),
            Quantity = x.Quantity,
            Negotiable = x.Negotiable,
            CategoryName = AdminProductTextHelper.LocalizeCategoryName(
                x.CategoryId,
                x.CategoryName,
                staticReferenceCache,
                language),
            CategoryId = x.CategoryId,
            ProductTypeId = x.ProductTypeId,
            ProductTypeName = x.ProductTypeName,
            UnitName = x.UnitName,
            OwnerName = x.OwnerName,
            OwnerCompanyName = x.OwnerCompanyName,
            OwnerEmail = x.OwnerEmail,
            StatusLabelAr = AdminMappings.GetProductStatusLabelAr(x.Status, x.IsApproved),
            IsApproved = x.IsApproved == true,
            CreatedAt = UtcDateTimeHelper.AsUtc(x.CreatedAt),
            UpdatedAt = UtcDateTimeHelper.AsUtc(x.UpdatedAt),
            IsEditResubmit = AdminMappings.IsProductEditResubmit(
                x.CreatedAt,
                x.UpdatedAt,
                x.Status,
                x.IsApproved,
                x.PendingProductChanges),
            PrimaryImagePath = x.PrimaryImagePath,
            ImagePaths = x.ImagePaths,
            OriginCountryName = x.OriginCountryName ?? string.Empty,
            DestinationCountryName = x.DestinationCountryName ?? string.Empty,
            LoadingPortName = x.LoadingPortName ?? string.Empty,
            ArrivalPortName = x.ArrivalPortName ?? string.Empty,
            ShippingDescription = AdminProductTextHelper.ResolveShippingDescriptionForLocale(
                tr,
                x.ShippingDescription,
                language),
            ShippingRouteSummary = AdminShippingDisplayHelper.BuildRouteSummary(
                x.OriginCountryName,
                x.LoadingPortName,
                x.DestinationCountryName,
                x.ArrivalPortName),
            ShippingDuration = x.ShippingDuration ?? string.Empty,
            OfferDuration = x.OfferDuration ?? string.Empty,
            ProductAddress = AdminShippingDisplayHelper.FormatAddressParts(
                x.AddressLine1,
                x.AddressLine2,
                x.CityName),
            PendingOffersCount = pendingOffersByProduct.GetValueOrDefault(x.ProductId),
            HasRetailPricing = ProductTypeCodes.HasRetailPricing(
                x.CategoryId,
                x.ProductTypeId,
                x.RetailPrice,
                x.RetailUnitId,
                x.RetailQuantity),
            RetailPrice = x.RetailPrice,
            RetailUnitName = x.RetailUnitName,
            RetailQuantity = x.RetailQuantity,
            RequestTypeId = x.RequestTypeId,
            RequestTypeName = x.RequestTypeName,
            BookingPriceTypeId = x.BookingPriceTypeId,
            BookingPriceTypeName = ResolveBookingPriceTypeName(x.BookingPriceTypeId, x.BookingPriceTypeName),
            Packaging = x.Packaging,
            PackagingDetails = x.PackagingDetails,
            RetailDescription = AdminProductTextHelper.ResolveRetailDescription(tr, x.RetailDescription),
            RetailPackaging = x.RetailPackaging,
            RetailPackagingDetails = x.RetailPackagingDetails
        };
        }).ToList();

        return new AdminPagedResult<AdminProductListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<string> ApproveProductAsync(
        string productId,
        AdminRejectProductRequest? request = null,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await dbContext.Products
            .Include(x => x.Owner)
            .FirstOrDefaultAsync(x => x.ProductId == parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.IsApproved == true && product.Status == ProductStatusCodes.Active)
        {
            throw new InvalidOperationException("Product is already approved.");
        }

        if (!product.IsReadyForAdminReview)
        {
            throw new InvalidOperationException(
                "Product media upload is still in progress. Wait until the seller finishes uploading files.");
        }

        var adminNotes = request?.SupplierNotesEn?.Trim();
        if (!string.IsNullOrWhiteSpace(adminNotes))
        {
            product.SupplierNotesEn = adminNotes;
        }

        var productName = await ResolveProductDisplayNameAsync(product.ProductId, product.NameEn, cancellationToken);
        var previousSnapshot = PendingProductChangeHelper.TryParse(product.PendingProductChanges);
        var wasEditResubmit = previousSnapshot is not null
            || (product.IsApproved != true
                && product.Status != ProductStatusCodes.Rejected
                && product.UpdatedAt != null
                && product.UpdatedAt > product.CreatedAt.AddMinutes(1));

        product.IsApproved = true;
        product.Status = ProductStatusCodes.Active;
        product.UpdatedAt = UtcDateTimeHelper.UtcNow;

        if (product.ProductTypeId == ProductTypeCodes.Offers)
        {
            product.DisplayExpiresAtUtc = null;
        }
        else
        {
            var adDisplayDurationDays = await dbContext.SystemSettings
                .AsNoTracking()
                .Where(x => x.Id == 1)
                .Select(x => x.AdDisplayDurationDays)
                .FirstOrDefaultAsync(cancellationToken);
            product.DisplayExpiresAtUtc = UtcDateTimeHelper.ComputeAdExpiresAtUtc(
                UtcDateTimeHelper.UtcNow,
                adDisplayDurationDays);
        }

        // Accept edit: keep new live data/files; delete previous snapshot files no longer used.
        if (previousSnapshot is not null)
        {
            await DeleteObsoletePreviousAssetsAsync(product.ProductId, previousSnapshot, cancellationToken);
            product.PendingProductChanges = null;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches(product.OwnerId);
        QueueTextSearchSync(product.ProductId);
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ProductApprove,
            AdminAuditEntityTypes.Product,
            product.ProductId.ToString("D"),
            wasEditResubmit
                ? $"Approved edited ad '{productName}'"
                : $"Approved ad '{productName}'",
            new
            {
                productName,
                productTypeId = product.ProductTypeId,
                categoryId = product.CategoryId,
                ownerId = product.OwnerId,
                wasEditResubmit,
                adminNotes
            },
            cancellationToken);

        var owner = product.Owner;
        var productIdText = product.ProductId.ToString();
        var notificationEn = NotificationMessages.AdApproved("en", productName, adminNotes);
        var notificationAr = NotificationMessages.AdApproved("ar", productName, adminNotes);
        var preferred = NotificationMessages.IsArabic(owner?.PreferredLanguage)
            ? notificationAr
            : notificationEn;

        QueueOwnerNotification(
            owner,
            preferred.EmailSubject,
            preferred.EmailHtml,
            preferred.FcmTitle,
            preferred.FcmBody,
            "ad_approved",
            productIdText,
            $"ad approval for product {productIdText}",
            titleEn: notificationEn.FcmTitle,
            bodyEn: notificationEn.FcmBody,
            titleAr: notificationAr.FcmTitle,
            bodyAr: notificationAr.FcmBody);

        return "Product approved successfully.";
    }

    public async Task<string> RejectProductAsync(
        string productId,
        AdminRejectProductRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await dbContext.Products
            .Include(x => x.Owner)
            .FirstOrDefaultAsync(x => x.ProductId == parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        var adminNotesEn = request.SupplierNotesEn?.Trim();
        var adminNotesAr = request.SupplierNotesAr?.Trim();
        if (string.IsNullOrWhiteSpace(adminNotesEn) && string.IsNullOrWhiteSpace(adminNotesAr))
        {
            throw new ArgumentException("Rejection reason is required.");
        }

        var previousSnapshot = PendingProductChangeHelper.TryParse(product.PendingProductChanges);
        var isPendingEditReject = previousSnapshot is not null;

        if (isPendingEditReject)
        {
            // Reject edit: restore previous data/files; delete proposed (new) assets.
            await RestorePreviousProductEditAsync(product, previousSnapshot!, cancellationToken);
            product.PendingProductChanges = null;
            product.IsReadyForAdminReview = true;
            product.SupplierNotesEn = !string.IsNullOrWhiteSpace(adminNotesEn)
                ? adminNotesEn
                : adminNotesAr;
            product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        }
        else
        {
            product.IsApproved = false;
            product.Status = ProductStatusCodes.Rejected;
            // Allow a later SubmitForAdminReview after the seller edits (wasReady must be false).
            product.IsReadyForAdminReview = false;
            product.SupplierNotesEn = !string.IsNullOrWhiteSpace(adminNotesEn)
                ? adminNotesEn
                : adminNotesAr;
            product.UpdatedAt = DateTime.UtcNow;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        try
        {
            await contentTranslationService.UpsertProductSupplierNotesBilingualAsync(
                product.ProductId,
                adminNotesEn,
                adminNotesAr,
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed to persist bilingual rejection notes for product {ProductId}",
                product.ProductId);
        }

        ProductsAppService.InvalidateListingCaches(product.OwnerId);
        QueueTextSearchSync(product.ProductId);
        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);

        var owner = product.Owner;
        var productIdText = product.ProductId.ToString();
        var productName = await ResolveProductDisplayNameAsync(product.ProductId, product.NameEn, cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ProductReject,
            AdminAuditEntityTypes.Product,
            product.ProductId.ToString("D"),
            isPendingEditReject
                ? $"Rejected edit for ad '{productName}' and restored previous version"
                : $"Rejected ad '{productName}'",
            new
            {
                productName,
                productTypeId = product.ProductTypeId,
                categoryId = product.CategoryId,
                ownerId = product.OwnerId,
                reasonEn = adminNotesEn,
                reasonAr = adminNotesAr,
                wasPendingEdit = isPendingEditReject
            },
            cancellationToken);

        var notificationEn = NotificationMessages.AdRejected(
            "en",
            productName,
            adminNotesEn,
            adminNotesAr);
        var notificationAr = NotificationMessages.AdRejected(
            "ar",
            productName,
            adminNotesEn,
            adminNotesAr);
        var preferred = NotificationMessages.IsArabic(owner?.PreferredLanguage)
            ? notificationAr
            : notificationEn;

        QueueOwnerNotification(
            owner,
            preferred.EmailSubject,
            preferred.EmailHtml,
            preferred.FcmTitle,
            preferred.FcmBody,
            "ad_rejected",
            productIdText,
            $"ad rejection for product {productIdText}",
            titleEn: notificationEn.FcmTitle,
            bodyEn: notificationEn.FcmBody,
            titleAr: notificationAr.FcmTitle,
            bodyAr: notificationAr.FcmBody);

        return "Product rejected successfully.";
    }

    public async Task<AdminProductDetailDto> GetProductByIdAsync(
        string productId,
        string? language = null,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var raw = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == parsedProductId)
            .Select(x => new
            {
                x.ProductId,
                Name = x.NameEn ?? string.Empty,
                x.DescriptionEn,
                x.USDPrice,
                x.Currency,
                x.Quantity,
                x.Negotiable,
                x.CategoryId,
                CategoryName = x.Category != null ? x.Category.NameEn : "—",
                x.ProductTypeId,
                ProductTypeName = x.ProductType != null ? x.ProductType.TypeNameEn : "—",
                x.UnitId,
                UnitName = x.Unit != null ? x.Unit.UnitNameEn : "—",
                OwnerName = x.Owner != null ? x.Owner.FullName : "—",
                OwnerCompanyName = x.Owner != null ? x.Owner.CompanyName : null,
                OwnerEmail = x.Owner != null ? x.Owner.Email : "—",
                OwnerPhone = x.Owner != null ? x.Owner.PhoneNumber : null,
                OwnerCity = x.Owner != null
                    ? x.Owner.Addresses
                        .OrderBy(a => a.Id)
                        .Select(a => a.City != null ? a.City.CityName : null)
                        .FirstOrDefault()
                    : null,
                x.Status,
                x.IsApproved,
                x.CreatedAt,
                x.UpdatedAt,
                x.ViewsCount,
                x.SupplierNotesEn,
                x.Packaging,
                x.PackagingDetails,
                RetailDescription = x.RetailDescriptionEn,
                x.RetailPackaging,
                x.RetailPackagingDetails,
                x.VideoPath,
                x.VideoDurationSeconds,
                x.PendingProductChanges,
                Videos = x.ProductVideos
                    .OrderBy(v => v.Id)
                    .Select(v => new AdminProductVideoDto
                    {
                        Id = v.Id,
                        Path = v.VideoPath,
                        IsMuted = v.IsMuted,
                        DurationSeconds = v.VideoDurationSeconds
                    })
                    .ToList(),
                OriginCountryName = x.OriginCountry != null ? x.OriginCountry.CountryNameEn : null,
                x.OriginCountryId,
                DestinationCountryName = x.DestinationCountry != null ? x.DestinationCountry.CountryNameEn : null,
                x.DestinationCountryId,
                LoadingPortName = x.LoadingPort != null ? x.LoadingPort.PortNameEn : null,
                x.LoadingPortId,
                ArrivalPortName = x.ArrivalPort != null ? x.ArrivalPort.PortNameEn : null,
                x.ArrivalPortId,
                ShippingDescription = x.ShippingDescriptionEn,
                x.ShippingDuration,
                x.OfferDuration,
                AddressLine1 = x.Address != null ? x.Address.AddressLine1 : null,
                AddressLine2 = x.Address != null ? x.Address.AddressLine2 : null,
                CityName = x.Address != null && x.Address.City != null ? x.Address.City.CityName : null,
                x.RetailPrice,
                x.RetailUnitId,
                x.RetailQuantity,
                RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null,
                x.RequestTypeId,
                RequestTypeName = x.RequestType != null ? x.RequestType.NameEn : null,
                x.BookingPriceTypeId,
                BookingPriceTypeName = x.BookingPriceType != null ? x.BookingPriceType.NameEn : null,
                Images = x.ProductImages
                    .OrderBy(pi => pi.Id)
                    .Select(pi => new AdminProductImageDto { Id = pi.Id, Path = pi.ImagePath })
                    .ToList(),
                Documents = x.ProductDocuments
                    .OrderBy(pd => pd.Id)
                    .Select(pd => new AdminProductDocumentDto { Id = pd.Id, Path = pd.DocumentPath })
                    .ToList()
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        var imagePaths = raw.Images.Select(i => i.Path).ToList();
        var previousSnapshot = PendingProductChangeHelper.TryParse(raw.PendingProductChanges);
        var isEditResubmit = AdminMappings.IsProductEditResubmit(
            raw.CreatedAt,
            raw.UpdatedAt,
            raw.Status,
            raw.IsApproved,
            raw.PendingProductChanges);

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            [raw.ProductId],
            cancellationToken);
        translations.TryGetValue(raw.ProductId, out var tr);
        var displayName = AdminProductTextHelper.ResolveNameForLocale(tr, raw.Name, language);
        var displayDescription = AdminProductTextHelper.ResolveDescriptionForLocale(tr, raw.DescriptionEn, language);
        var displayRetailDescription = AdminProductTextHelper.ResolveRetailDescriptionForLocale(
            tr,
            raw.RetailDescription,
            language);
        var displaySupplierNotes = AdminProductTextHelper.ResolveSupplierNotesForLocale(
            tr,
            raw.SupplierNotesEn,
            language);
        var displayShippingDescription = AdminProductTextHelper.ResolveShippingDescriptionForLocale(
            tr,
            raw.ShippingDescription,
            language);
        var displayCategoryName = AdminProductTextHelper.LocalizeCategoryName(
            raw.CategoryId,
            raw.CategoryName,
            staticReferenceCache,
            language);
        var displayOriginCountry = AdminProductTextHelper.LocalizeCountryName(
            raw.OriginCountryId,
            raw.OriginCountryName,
            staticReferenceCache,
            language);
        var displayDestinationCountry = AdminProductTextHelper.LocalizeCountryName(
            raw.DestinationCountryId,
            raw.DestinationCountryName,
            staticReferenceCache,
            language);
        var displayLoadingPort = AdminProductTextHelper.LocalizePortName(
            raw.LoadingPortId,
            raw.LoadingPortName,
            staticReferenceCache,
            language);
        var displayArrivalPort = AdminProductTextHelper.LocalizePortName(
            raw.ArrivalPortId,
            raw.ArrivalPortName,
            staticReferenceCache,
            language);

        return new AdminProductDetailDto
        {
            ProductId = raw.ProductId,
            Name = displayName,
            Description = displayDescription,
            PriceUsd = raw.USDPrice,
            Currency = ProductCurrencyHelper.Normalize(raw.Currency, raw.ProductTypeId),
            PriceFormatted = ProductCurrencyHelper.FormatPrice(
                raw.USDPrice,
                ProductCurrencyHelper.Normalize(raw.Currency, raw.ProductTypeId)),
            Quantity = raw.Quantity,
            Negotiable = raw.Negotiable,
            CategoryId = raw.CategoryId,
            CategoryName = displayCategoryName,
            ProductTypeId = raw.ProductTypeId,
            ProductTypeName = raw.ProductTypeName,
            UnitId = raw.UnitId,
            UnitName = raw.UnitName,
            OwnerName = raw.OwnerName,
            OwnerCompanyName = raw.OwnerCompanyName,
            OwnerEmail = raw.OwnerEmail,
            OwnerPhone = raw.OwnerPhone,
            OwnerCity = raw.OwnerCity,
            StatusId = raw.Status,
            StatusLabelAr = AdminMappings.GetProductStatusLabelAr(raw.Status, raw.IsApproved),
            IsApproved = raw.IsApproved == true,
            CreatedAt = UtcDateTimeHelper.AsUtc(raw.CreatedAt),
            UpdatedAt = UtcDateTimeHelper.AsUtc(raw.UpdatedAt),
            IsEditResubmit = isEditResubmit,
            ViewsCount = raw.ViewsCount,
            SupplierNotesEn = displaySupplierNotes,
            Packaging = raw.Packaging,
            PackagingDetails = raw.PackagingDetails,
            RetailDescription = displayRetailDescription,
            RetailPackaging = raw.RetailPackaging,
            RetailPackagingDetails = raw.RetailPackagingDetails,
            Videos = ProductVideoPathsHelper.ResolveVideoItems(
                    raw.VideoPath,
                    raw.VideoDurationSeconds,
                    raw.Videos.Select(v => new ProductVideo
                    {
                        Id = v.Id,
                        VideoPath = v.Path,
                        VideoDurationSeconds = v.DurationSeconds,
                        IsMuted = v.IsMuted
                    }))
                .Select(v => new AdminProductVideoDto
                {
                    Id = v.Id,
                    Path = v.Path,
                    IsMuted = v.IsMuted,
                    DurationSeconds = v.DurationSeconds
                })
                .ToList(),
            VideoPath = ProductVideoPathsHelper.ResolveVideoItems(
                    raw.VideoPath,
                    raw.VideoDurationSeconds,
                    raw.Videos.Select(v => new ProductVideo
                    {
                        Id = v.Id,
                        VideoPath = v.Path,
                        VideoDurationSeconds = v.DurationSeconds,
                        IsMuted = v.IsMuted
                    }))
                .FirstOrDefault()?.Path,
            VideoPaths = ProductVideoPathsHelper.ResolveVideoItems(
                    raw.VideoPath,
                    raw.VideoDurationSeconds,
                    raw.Videos.Select(v => new ProductVideo
                    {
                        Id = v.Id,
                        VideoPath = v.Path,
                        VideoDurationSeconds = v.DurationSeconds,
                        IsMuted = v.IsMuted
                    }))
                .Select(v => v.Path)
                .ToList(),
            VideoDurationSeconds = ProductVideoPathsHelper.ResolveVideoItems(
                    raw.VideoPath,
                    raw.VideoDurationSeconds,
                    raw.Videos.Select(v => new ProductVideo
                    {
                        Id = v.Id,
                        VideoPath = v.Path,
                        VideoDurationSeconds = v.DurationSeconds,
                        IsMuted = v.IsMuted
                    }))
                .FirstOrDefault()?.DurationSeconds,
            PrimaryImagePath = imagePaths.FirstOrDefault(),
            ImagePaths = imagePaths,
            Images = raw.Images,
            Documents = raw.Documents,
            OriginCountryName = displayOriginCountry,
            DestinationCountryName = displayDestinationCountry,
            LoadingPortName = displayLoadingPort,
            ArrivalPortName = displayArrivalPort,
            ShippingDescription = displayShippingDescription,
            ShippingRouteSummary = AdminShippingDisplayHelper.BuildRouteSummary(
                raw.OriginCountryName,
                raw.LoadingPortName,
                raw.DestinationCountryName,
                raw.ArrivalPortName),
            ShippingDuration = raw.ShippingDuration ?? string.Empty,
            OfferDuration = raw.OfferDuration ?? string.Empty,
            ProductAddress = AdminShippingDisplayHelper.FormatAddressParts(
                raw.AddressLine1,
                raw.AddressLine2,
                raw.CityName),
            HasRetailPricing = ProductTypeCodes.HasRetailPricing(
                raw.CategoryId,
                raw.ProductTypeId,
                raw.RetailPrice,
                raw.RetailUnitId,
                raw.RetailQuantity),
            RetailPrice = raw.RetailPrice,
            RetailUnitName = raw.RetailUnitName,
            RetailQuantity = raw.RetailQuantity,
            RequestTypeId = raw.RequestTypeId,
            RequestTypeName = !string.IsNullOrWhiteSpace(raw.RequestTypeName)
                ? raw.RequestTypeName
                : raw.RequestTypeId switch
                {
                    1 => "Local",
                    2 => "Reexport",
                    _ => null
                },
            BookingPriceTypeId = raw.BookingPriceTypeId,
            BookingPriceTypeName = ResolveBookingPriceTypeName(raw.BookingPriceTypeId, raw.BookingPriceTypeName),
            PendingEdit = previousSnapshot is null
                ? null
                : BuildPendingEditDto(
                    previousSnapshot,
                    raw.Name,
                    raw.DescriptionEn,
                    raw.USDPrice,
                    raw.Currency,
                    raw.Quantity,
                    raw.VideoPath,
                    imagePaths,
                    raw.Documents.Select(d => d.Path).ToList())
        };
    }

    private static AdminPendingProductEditDto BuildPendingEditDto(
        PendingProductEditSnapshot previous,
        string proposedName,
        string? proposedDescription,
        decimal proposedPrice,
        string? proposedCurrency,
        long proposedQuantity,
        string? proposedVideoPath,
        IReadOnlyList<string> proposedImagePaths,
        IReadOnlyList<string> proposedDocumentPaths)
    {
        return new AdminPendingProductEditDto
        {
            PreviousName = previous.NameEn,
            ProposedName = proposedName,
            PreviousDescription = previous.DescriptionEn,
            ProposedDescription = proposedDescription,
            PreviousPrice = previous.USDPrice,
            ProposedPrice = proposedPrice,
            PreviousCurrency = previous.Currency,
            ProposedCurrency = proposedCurrency,
            PreviousQuantity = previous.Quantity,
            ProposedQuantity = proposedQuantity,
            PreviousVideoPath = previous.VideoPath,
            ProposedVideoPath = proposedVideoPath,
            PreviousImagePaths = previous.ImagePaths,
            ProposedImagePaths = proposedImagePaths.ToList(),
            PreviousDocumentPaths = previous.DocumentPaths,
            ProposedDocumentPaths = proposedDocumentPaths.ToList()
        };
    }

    private async Task DeleteObsoletePreviousAssetsAsync(
        Guid productId,
        PendingProductEditSnapshot previous,
        CancellationToken cancellationToken)
    {
        var currentImages = await dbContext.ProductImages
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.ImagePath)
            .ToListAsync(cancellationToken);
        var currentDocuments = await dbContext.ProductDocuments
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.DocumentPath)
            .ToListAsync(cancellationToken);
        var currentExtraVideos = await dbContext.ProductVideos
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.VideoPath)
            .ToListAsync(cancellationToken);
        var currentVideo = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.VideoPath)
            .FirstOrDefaultAsync(cancellationToken);

        var keep = PendingProductChangeHelper.ToPathSet(
            currentImages
                .Concat(currentDocuments)
                .Concat(currentExtraVideos)
                .Append(currentVideo));

        foreach (var path in previous.ImagePaths
                     .Concat(previous.DocumentPaths)
                     .Concat(previous.ExtraVideoPaths)
                     .Append(previous.VideoPath ?? string.Empty))
        {
            var normalized = PendingProductChangeHelper.NormalizePath(path);
            if (normalized.Length == 0 || keep.Contains(normalized))
            {
                continue;
            }

            await mediaStorage.DeleteAsync(path, cancellationToken);
        }
    }

    private async Task RestorePreviousProductEditAsync(
        Product product,
        PendingProductEditSnapshot previous,
        CancellationToken cancellationToken)
    {
        var currentImages = await dbContext.ProductImages
            .Where(x => x.ProductId == product.ProductId)
            .ToListAsync(cancellationToken);
        var currentDocuments = await dbContext.ProductDocuments
            .Where(x => x.ProductId == product.ProductId)
            .ToListAsync(cancellationToken);
        var currentExtraVideos = await dbContext.ProductVideos
            .Where(x => x.ProductId == product.ProductId)
            .ToListAsync(cancellationToken);

        var previousImageSet = PendingProductChangeHelper.ToPathSet(previous.ImagePaths);
        var previousDocumentSet = PendingProductChangeHelper.ToPathSet(previous.DocumentPaths);
        var previousExtraVideoSet = PendingProductChangeHelper.ToPathSet(previous.ExtraVideoPaths);
        var previousPrimaryVideo = PendingProductChangeHelper.NormalizePath(previous.VideoPath);

        // Delete proposed images that were not in the previous set.
        var removedImagePaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var image in currentImages)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(image.ImagePath);
            if (previousImageSet.Contains(normalized))
            {
                continue;
            }

            removedImagePaths.Add(normalized);
            dbContext.ProductImages.Remove(image);
            await mediaStorage.DeleteAsync(image.ImagePath, cancellationToken);
        }

        var removedDocumentPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var doc in currentDocuments)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(doc.DocumentPath);
            if (previousDocumentSet.Contains(normalized))
            {
                continue;
            }

            removedDocumentPaths.Add(normalized);
            dbContext.ProductDocuments.Remove(doc);
            await mediaStorage.DeleteAsync(doc.DocumentPath, cancellationToken);
        }

        var removedExtraVideoPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var video in currentExtraVideos)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(video.VideoPath);
            if (previousExtraVideoSet.Contains(normalized))
            {
                continue;
            }

            removedExtraVideoPaths.Add(normalized);
            dbContext.ProductVideos.Remove(video);
            await mediaStorage.DeleteAsync(video.VideoPath, cancellationToken);
        }

        var proposedPrimaryVideo = PendingProductChangeHelper.NormalizePath(product.VideoPath);
        if (!string.IsNullOrWhiteSpace(proposedPrimaryVideo)
            && !string.Equals(proposedPrimaryVideo, previousPrimaryVideo, StringComparison.OrdinalIgnoreCase)
            && !previousExtraVideoSet.Contains(proposedPrimaryVideo))
        {
            await mediaStorage.DeleteAsync(product.VideoPath, cancellationToken);
        }

        // Restore missing previous image rows (files were kept on disk).
        var remainingImagePaths = PendingProductChangeHelper.ToPathSet(
            currentImages
                .Where(x => !removedImagePaths.Contains(PendingProductChangeHelper.NormalizePath(x.ImagePath)))
                .Select(x => x.ImagePath));
        foreach (var path in previous.ImagePaths)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(path);
            if (normalized.Length == 0 || remainingImagePaths.Contains(normalized))
            {
                continue;
            }

            await dbContext.ProductImages.AddAsync(
                new ProductImage
                {
                    ProductId = product.ProductId,
                    ImagePath = path
                },
                cancellationToken);
        }

        var remainingDocumentPaths = PendingProductChangeHelper.ToPathSet(
            currentDocuments
                .Where(x => !removedDocumentPaths.Contains(PendingProductChangeHelper.NormalizePath(x.DocumentPath)))
                .Select(x => x.DocumentPath));
        foreach (var path in previous.DocumentPaths)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(path);
            if (normalized.Length == 0 || remainingDocumentPaths.Contains(normalized))
            {
                continue;
            }

            await dbContext.ProductDocuments.AddAsync(
                new ProductDocument
                {
                    ProductId = product.ProductId,
                    DocumentPath = path
                },
                cancellationToken);
        }

        var remainingExtraVideos = PendingProductChangeHelper.ToPathSet(
            currentExtraVideos
                .Where(x => !removedExtraVideoPaths.Contains(PendingProductChangeHelper.NormalizePath(x.VideoPath)))
                .Select(x => x.VideoPath));
        foreach (var path in previous.ExtraVideoPaths)
        {
            var normalized = PendingProductChangeHelper.NormalizePath(path);
            if (normalized.Length == 0 || remainingExtraVideos.Contains(normalized))
            {
                continue;
            }

            await dbContext.ProductVideos.AddAsync(
                new ProductVideo
                {
                    ProductId = product.ProductId,
                    VideoPath = path
                },
                cancellationToken);
        }

        PendingProductChangeHelper.ApplySnapshotToProduct(product, previous);

        // Prefer restored previous approval when the edit was on a live ad.
        if (previous.IsApproved == true || previous.Status == ProductStatusCodes.Active)
        {
            product.IsApproved = true;
            product.Status = ProductStatusCodes.Active;
        }
    }

    public async Task<object> UpdateProductAsync(
        string productId,
        AdminUpdateProductRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == parsedProductId)
            .Select(x => new
            {
                x.ProductId,
                x.OwnerId,
                x.OriginCountryId,
                x.DestinationCountryId,
                x.LoadingPortId,
                x.ArrivalPortId,
                x.RequestTypeId,
                x.Negotiable,
                x.Packaging,
                x.PackagingDetails,
                x.ShippingDuration,
                x.OfferDuration,
                x.MinimumOrderQuantity,
                x.MaximumOrderQuantity,
                x.DiscountPercentage,
                x.DiscountDays,
                x.ShippingDescriptionEn,
                x.AddressId,
                x.BookingPriceTypeId,
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.OwnerId is null)
        {
            throw new InvalidOperationException("Product has no owner.");
        }

        var originCountry = product.OriginCountryId.HasValue
            ? staticReferenceCache.FindCountryById(product.OriginCountryId.Value)?.CountryNameEn ?? string.Empty
            : string.Empty;
        var destinationCountry = product.DestinationCountryId.HasValue
            ? staticReferenceCache.FindCountryById(product.DestinationCountryId.Value)?.CountryNameEn ?? string.Empty
            : string.Empty;
        var loadingPort = product.LoadingPortId.HasValue
            ? staticReferenceCache.FindPortById(product.LoadingPortId.Value)?.PortNameEn ?? string.Empty
            : string.Empty;
        var arrivalPort = product.ArrivalPortId.HasValue
            ? staticReferenceCache.FindPortById(product.ArrivalPortId.Value)?.PortNameEn ?? string.Empty
            : string.Empty;

        var result = await _productsAppService.UpdateAsync(new UpdateProductInput
        {
            ProductId = productId,
            OwnerId = product.OwnerId.Value.ToString(),
            AllowAdminUpdate = true,
            NameEn = request.NameEn.Trim(),
            USDPrice = request.USDPrice,
            Currency = request.Currency,
            Quantity = request.Quantity,
            DescriptionEn = request.DescriptionEn,
            CategoryId = request.CategoryId?.ToString(System.Globalization.CultureInfo.InvariantCulture),
            ProductTypeName = request.ProductTypeName.Trim(),
            UnitName = request.UnitName.Trim(),
            SupplierNotesEn = request.SupplierNotesEn,
            // Preserve catalog fields the admin UI does not edit.
            RequestTypeId = product.RequestTypeId,
            BookingPriceTypeId = product.BookingPriceTypeId,
            Negotiable = product.Negotiable,
            Packaging = product.Packaging,
            PackagingDetails = product.PackagingDetails,
            ShippingDuration = product.ShippingDuration,
            OfferDuration = product.OfferDuration,
            MinimumOrderQuantity = product.MinimumOrderQuantity,
            MaximumOrderQuantity = product.MaximumOrderQuantity,
            DiscountPercentage = product.DiscountPercentage,
            DiscountDays = product.DiscountDays,
            ShippingDescriptionEn = product.ShippingDescriptionEn,
            AddressId = product.AddressId?.ToString(),
            OriginCountryName = originCountry,
            DestinationCountryName = destinationCountry,
            LoadingPortName = loadingPort,
            ArrivalPortName = arrivalPort
        }, cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.ProductUpdate,
            AdminAuditEntityTypes.Product,
            productId,
            $"Updated ad '{request.NameEn.Trim()}'",
            new
            {
                nameEn = request.NameEn.Trim(),
                usdPrice = request.USDPrice,
                currency = request.Currency,
                quantity = request.Quantity,
                categoryId = request.CategoryId,
                productTypeName = request.ProductTypeName.Trim(),
                unitName = request.UnitName.Trim()
            },
            cancellationToken);

        return result;
    }

    public async Task<AdminProductLookupsDto> GetLookupsAsync(CancellationToken cancellationToken = default)
    {
        var productTypes = await dbContext.ProductTypes
            .AsNoTracking()
            .OrderBy(x => x.Id)
            .Select(x => new AdminLookupItemDto { Id = x.Id, Name = x.TypeNameEn })
            .ToListAsync(cancellationToken);

        var units = staticReferenceCache.GetUnits()
            .Select(x => new AdminLookupItemDto { Id = x.Id, Name = x.UnitNameEn })
            .ToList();

        return new AdminProductLookupsDto
        {
            ProductTypes = productTypes,
            Units = units
        };
    }

    public async Task<string> DeleteProductImageAsync(
        string productId,
        long imageId,
        string? webRootPath,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var image = await dbContext.ProductImages
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == imageId && x.ProductId == parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product image not found.");

        return await _productAssetsAppService.DeleteImageAsync(
            imageId,
            Guid.Empty.ToString(),
            webRootPath,
            allowAdminAccess: true,
            cancellationToken);
    }

    public async Task<string> DeleteProductVideoAsync(
        string productId,
        string videoPath,
        string? webRootPath,
        CancellationToken cancellationToken = default)
    {
        return await _productAssetsAppService.DeleteVideoByPathAsync(
            productId,
            videoPath,
            Guid.Empty.ToString(),
            webRootPath,
            allowAdminAccess: true,
            cancellationToken);
    }

    public Task<object> SetProductVideoMutedAsync(
        string productId,
        string videoPath,
        bool isMuted,
        CancellationToken cancellationToken = default) =>
        _productAssetsAppService.SetVideoMutedAsync(productId, videoPath, isMuted, cancellationToken);

    public async Task<string> DeleteProductAsync(
        string productId,
        string adminUserId,
        string? webRootPath,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var productInfo = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == parsedProductId)
            .Select(x => new
            {
                x.ProductId,
                x.NameEn,
                x.ProductTypeId,
                x.CategoryId,
                x.OwnerId
            })
            .FirstOrDefaultAsync(cancellationToken);

        await _productsAppService.DeleteAsync(
            new DeleteProductInput
            {
                ProductId = productId,
                UserId = adminUserId,
                WebRootPath = webRootPath,
                AllowAdminDelete = true
            },
            cancellationToken);

        if (productInfo is not null)
        {
            var displayName = await ResolveProductDisplayNameAsync(
                productInfo.ProductId,
                productInfo.NameEn,
                cancellationToken);
            await auditLogAppService.WriteAsync(
                AdminAuditActions.ProductDelete,
                AdminAuditEntityTypes.Product,
                productInfo.ProductId.ToString("D"),
                $"Deleted ad '{displayName}'",
                new
                {
                    productName = displayName,
                    productTypeId = productInfo.ProductTypeId,
                    categoryId = productInfo.CategoryId,
                    ownerId = productInfo.OwnerId
                },
                cancellationToken);
        }

        return "Product deleted successfully.";
    }

    private async Task<string> ResolveProductDisplayNameAsync(
        Guid productId,
        string? legacyNameEn,
        CancellationToken cancellationToken)
    {
        var translations = await contentTranslationService.GetProductTranslationsAsync(
            [productId],
            cancellationToken);
        translations.TryGetValue(productId, out var tr);
        return AdminProductTextHelper.ResolveName(tr, legacyNameEn);
    }

    private void QueueOwnerNotification(
        User? owner,
        string subject,
        string emailHtml,
        string fcmTitle,
        string fcmBody,
        string fcmType,
        string referenceId,
        string logContext,
        string? titleEn = null,
        string? bodyEn = null,
        string? titleAr = null,
        string? bodyAr = null)
    {
        if (owner is null)
        {
            return;
        }

        var ownerId = owner.Id;
        var ownerEmail = owner.Email;
        var fcmToken = owner.FcmToken;
        var preferredLanguage = owner.PreferredLanguage;
        var storeTitleEn = TruncateNotify(titleEn ?? fcmTitle, 255);
        var storeBodyEn = TruncateNotify(bodyEn ?? fcmBody, 1000);
        var storeTitleAr = string.IsNullOrWhiteSpace(titleAr) ? null : TruncateNotify(titleAr, 255);
        var storeBodyAr = string.IsNullOrWhiteSpace(bodyAr) ? null : TruncateNotify(bodyAr, 1000);

        _ = Task.Run(async () =>
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var emailService = scope.ServiceProvider.GetRequiredService<IEmailService>();
                var fcmService = scope.ServiceProvider.GetRequiredService<IFcmNotificationService>();
                var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();

                try
                {
                    var routeId = await EnsureNotificationRouteAsync(db, "product-detail");
                    var typeId = await EnsureNotificationTypeAsync(db, fcmType);
                    await db.Notifications.AddAsync(new Notification
                    {
                        Id = Guid.NewGuid(),
                        Title = storeTitleEn,
                        TitleAr = storeTitleAr,
                        Body = storeBodyEn,
                        BodyAr = storeBodyAr,
                        FromUserId = ownerId,
                        ToUserId = ownerId,
                        TypeId = typeId,
                        RouteId = routeId,
                        ReferenceId = referenceId,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow,
                    });
                    await db.SaveChangesAsync();
                    NotificationCacheVersions.Bump(ownerId);
                }
                catch (Exception ex)
                {
                    logger.LogWarning(ex, "Failed to persist inbox notification for {LogContext}", logContext);
                }

                if (!string.IsNullOrWhiteSpace(ownerEmail))
                {
                    await emailService.SendAsync(ownerEmail, subject, emailHtml);
                }

                if (!string.IsNullOrWhiteSpace(fcmToken))
                {
                    var (pushTitle, pushBody) = NotificationMessages.PickOptional(
                        preferredLanguage,
                        storeTitleEn,
                        storeBodyEn,
                        storeTitleAr,
                        storeBodyAr);
                    await fcmService.SendNotificationAsync(
                        fcmToken,
                        new FcmNotificationPayload
                        {
                            Title = pushTitle,
                            Body = pushBody,
                            Type = fcmType,
                            RouteId = "product-detail",
                            ReferenceId = referenceId
                        });
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to send {LogContext}", logContext);
            }
        });
    }

    private static string TruncateNotify(string? value, int maxLen)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= maxLen ? trimmed : trimmed[..(maxLen - 1)] + "…";
    }

    private static async Task<Guid> EnsureNotificationRouteAsync(IRasAlSouqDbContext db, string name)
    {
        var existing = await db.NotificationRoutes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name);
        if (existing is not null)
        {
            return existing.Id;
        }

        var route = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await db.NotificationRoutes.AddAsync(route);
        await db.SaveChangesAsync();
        return route.Id;
    }

    private static async Task<byte> EnsureNotificationTypeAsync(IRasAlSouqDbContext db, string name)
    {
        var existing = await db.NotificationTypes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name);
        if (existing is not null)
        {
            return existing.Id;
        }

        var type = new NotificationType { Name = name };
        await db.NotificationTypes.AddAsync(type);
        await db.SaveChangesAsync();
        return type.Id;
    }

    private static string? ResolveBookingPriceTypeName(byte? bookingPriceTypeId, string? bookingPriceTypeName)
    {
        if (!string.IsNullOrWhiteSpace(bookingPriceTypeName))
        {
            return bookingPriceTypeName.Trim();
        }

        return bookingPriceTypeId switch
        {
            1 => "FOB",
            2 => "CNF",
            3 => "CIF",
            _ => null
        };
    }
}
