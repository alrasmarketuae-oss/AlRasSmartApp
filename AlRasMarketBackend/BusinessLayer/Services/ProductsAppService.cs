using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System.Security.Claims;

namespace BusinessLayer.Services;

public partial class ProductsAppService(
    IProductDataAccess productData,
    IRasAlSouqDbContext dbContext,
    ITieredCache tieredCache,
    ProductCacheVersions productCacheVersions,
    IOpenAiVisionService openAiVisionService,
    IContentTranslationService contentTranslationService,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider,
    IStaticReferenceCache staticReferenceCache,
    IProductBackgroundEventQueue productBackgroundEventQueue,
    IProductAutoModerationQueue productAutoModerationQueue,
    IConfiguration configuration,
    IServiceScopeFactory scopeFactory,
    ILogger<ProductsAppService> logger,
    IMediaStorageService mediaStorage,
    IImageEmbeddingService imageEmbeddingService,
    IProductImageVectorIndex productImageVectorIndex,
    Microsoft.Extensions.Options.IOptions<BusinessLayer.Options.ImageEmbeddingOptions> imageEmbeddingOptions,
    IHttpContextAccessor httpContextAccessor,
    IProductAssetsAppService productAssetsAppService,
    IProductTextSearchIndex productTextSearchIndex) : IProductsAppService
{
    private const string AllProductsCacheKey = "products:all:v17";
    private const string ProductsByTypeCachePrefix = "products:by-type:v15:";
    private const string ProductsByCategoryCachePrefix = "products:by-category:v10:";
    private const string FeaturedProductsCacheKey = "products:featured:v7";
    private const string SearchProductsCachePrefix = "products:search:v14:";
    private static readonly TimeSpan SearchCardCacheTtl = TimeSpan.FromMinutes(10);
    private const string ProductByCodeCachePrefix = "products:by-code:v3:";
    private const string ProductByIdCachePrefix = "products:by-id:v8:";

    private int AllProductsCacheVersion => productCacheVersions.Get(ProductCacheVersions.All);
    private int FeaturedProductsCacheVersion => productCacheVersions.Get(ProductCacheVersions.Featured);
    private int ByTypeProductsCacheVersion => productCacheVersions.Get(ProductCacheVersions.ByType);
    private int ByCategoryProductsCacheVersion => productCacheVersions.Get(ProductCacheVersions.ByCategory);
    private int SearchNameIndexCacheVersion => productCacheVersions.Get(ProductCacheVersions.SearchNameIndex);
    private int SearchProductsCacheVersion => productCacheVersions.Get(ProductCacheVersions.Search);
    private int ProductDetailCacheVersion => productCacheVersions.Get(ProductCacheVersions.Detail);

    // Text search uses Meilisearch typo-tolerance (no sync OpenAI). Keep the client wired
    // for image/vision and optional future background spell analytics.
    private IOpenAiVisionService OpenAiVision => openAiVisionService;

    /// <summary>
    /// Busts every public product read cache (lists, search, detail, name index).
    /// When <paramref name="ownerId"/> is set, also busts that owner's my-listings cache.
    /// </summary>
    public static void InvalidateProductListCaches(Guid? ownerId = null)
    {
        if (ProductCacheVersions.Current is { } versions)
        {
            versions.BumpAll();
        }

        if (ownerId.HasValue)
        {
            MyListingsCacheVersions.Bump(ownerId.Value);
        }
    }

    /// <summary>Alias of <see cref="InvalidateProductListCaches"/>.</summary>
    public static void InvalidateListingCaches(Guid? ownerId = null) => InvalidateProductListCaches(ownerId);

    private static void InvalidateProductCaches(Guid? ownerId = null) => InvalidateProductListCaches(ownerId);

    /// <summary>Fire-and-forget Meilisearch upsert/delete; never blocks the API response.</summary>
    private void QueueTextSearchSync(Guid productId, bool deleted = false)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var sync = scope.ServiceProvider.GetRequiredService<ProductTextSearchSyncService>();
                if (deleted)
                {
                    await sync.DeleteProductAsync(productId).ConfigureAwait(false);
                }
                else
                {
                    await sync.UpsertProductAsync(productId).ConfigureAwait(false);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background Meilisearch sync failed for {ProductId}", productId);
            }
        });
    }

    /// <summary>Busts detail/by-code only (e.g. view-count bumps).</summary>
    private void InvalidateProductDetailCaches() => productCacheVersions.BumpDetail();

    private Task<object?> TryGetProductCacheAsync(string key, CancellationToken cancellationToken) =>
        tieredCache.GetAsync(key, cancellationToken);

    private Task SetProductCacheAsync(
        string key,
        object value,
        TimeSpan ttl,
        CancellationToken cancellationToken) =>
        tieredCache.SetAsync(key, value, ttl, cancellationToken);

    public async Task<object> CreateAsync(CreateProductInput input, CancellationToken cancellationToken = default)
    {
       //first call to the database
        var ownerId = await EnsureCompanyOwnerAsync(input.OwnerId, cancellationToken);
        await NormalizeProductCreateFieldsAsync(input, cancellationToken);
        ValidateProductForm(input);
        var categoryId = await ResolveCategoryIdAsync(input.CategoryId, input.CategoryName, cancellationToken);
        var refs = await ResolveProductReferencesAsync(input, cancellationToken);
        ValidateCatalogClassification(categoryId, refs.ProductType?.Id);
        ValidateRetailPricing(input, categoryId, refs.ProductType?.Id, refs);
        await EnsureNonUaeCompanyBookingOnlyAsync(
            ownerId,
            refs.ProductType?.Id,
            categoryId,
            cancellationToken);
        var videoPath = await ResolveVideoPathAsync(input, existingVideoPath: null, cancellationToken);
        var addressId = await ResolveProductAddressIdAsync(ownerId, input.AddressId, cancellationToken);

        var productTypeId = refs.ProductType?.Id;

        var product = new Product
        {
            ProductId = Guid.NewGuid(),
            OwnerId = ownerId,
            NameEn = input.NameEn,
            CreatedLanguage = NormalizeCreatedLanguage(input.CreatedLanguage, input.NameEn),
            USDPrice = input.USDPrice,
            Currency = ResolveProductCurrency(input.Currency, productTypeId),
            Quantity = input.Quantity,
            DescriptionEn = input.DescriptionEn,
            CategoryId = categoryId,
            ProductTypeId = productTypeId,
            UnitId = refs.Unit.Id,
            OriginCountryId = refs.OriginCountry?.Id,
            DestinationCountryId = refs.DestinationCountry?.Id,
            LoadingPortId = refs.LoadingPort?.Id,
            ArrivalPortId = refs.ArrivalPort?.Id,
            MinimumOrderQuantity = input.MinimumOrderQuantity,
            MaximumOrderQuantity = input.MaximumOrderQuantity,
            Status = ProductStatusCodes.UnderReview,
            IsApproved = false,
            // Stay hidden from admin until client finishes uploading images/videos.
            IsReadyForAdminReview = false,
            DiscountPercentage = input.DiscountPercentage,
            DiscountDays = input.DiscountDays,
            ShippingDescriptionEn = input.ShippingDescriptionEn,
            SupplierNotesEn = input.SupplierNotesEn,
            Packaging = NormalizePackaging(input.Packaging),
            PackagingDetails = string.IsNullOrWhiteSpace(input.PackagingDetails)
                ? null
                : input.PackagingDetails.Trim(),
            Negotiable = input.Negotiable,
            VideoPath = videoPath,
            VideoDurationSeconds = input.ProductVideoFile is not null
                ? input.VideoDurationSeconds
                : null,
            ShippingDuration = NormalizeShippingDuration(input.ShippingDuration),
            OfferDuration = NormalizeShippingDuration(input.OfferDuration),
            AddressId = addressId,
            RequestTypeId = refs.RequestType?.Id,
            BookingPriceTypeId = refs.BookingPriceType?.Id,
            CreatedAt = UtcDateTimeHelper.UtcNow
        };

        await ApplyRetailPricingToProductAsync(product, input, refs, categoryId, productTypeId, cancellationToken);

        product.ProductCode = await productData.InsertProductAsync(product, cancellationToken);
        if (!string.IsNullOrWhiteSpace(videoPath))
        {
            await dbContext.ProductVideos.AddAsync(
                new ProductVideo
                {
                    ProductId = product.ProductId,
                    VideoPath = videoPath,
                    VideoDurationSeconds = product.VideoDurationSeconds,
                    IsMuted = true
                },
                cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        // Attach already-uploaded draft media in one SaveChanges (mobile create+drafts path).
        if ((input.DraftImagePaths is { Count: > 0 })
            || !string.IsNullOrWhiteSpace(input.DraftVideoPath))
        {
            await productAssetsAppService.ConfirmProductAssetsBatchAsync(
                new ConfirmProductAssetsBatchInput
                {
                    ProductId = product.ProductId.ToString("D"),
                    OwnerId = input.OwnerId,
                    ImagePaths = input.DraftImagePaths ?? [],
                    VideoPath = input.DraftVideoPath,
                    VideoDurationSeconds = input.DraftVideoDurationSeconds
                        ?? input.VideoDurationSeconds,
                },
                cancellationToken);
        }

        // OpenAI translation must not block create response.
        await QueueTranslateProductFieldsAsync(product, cancellationToken);

        InvalidateProductCaches(ownerId);
        QueueTextSearchSync(product.ProductId);

        // Do not notify admin yet â€” media uploads happen after create.
        // Client calls SubmitForAdminReviewAsync when uploads complete.

        var addressLookup = await LoadAddressTextLookupAsync([product.AddressId], cancellationToken);
        var addressText = ResolveAddressText(product.AddressId, addressLookup);

        return BuildProductMutationResponse(product, refs, addressText);
    }

    /// <summary>
    /// Best-effort admin SignalR alert (includes live counts via Notify*).
    /// Does not block create/update/submit responses.
    /// </summary>
    private void QueueAdminAdAlert(Product product, bool isEdit)
    {
        var productId = product.ProductId;
        var nameEn = product.NameEn;
        var productTypeId = product.ProductTypeId;
        var categoryId = product.CategoryId;

        _ = Task.Run(async () =>
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            try
            {
                var notify = scope.ServiceProvider.GetRequiredService<IAdminRealtimeNotificationService>();
                var snapshot = new Product
                {
                    ProductId = productId,
                    NameEn = nameEn,
                    ProductTypeId = productTypeId,
                    CategoryId = categoryId
                };

                if (isEdit)
                {
                    await notify.NotifyProductEditAsync(snapshot);
                }
                else
                {
                    await notify.NotifyNewProductAsync(snapshot);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(
                    ex,
                    "Background admin realtime notification failed for product {ProductId}",
                    productId);
            }
        });
    }

    /// <summary>
    /// Runs AI bilingual translation in the background, then CLIP-reindexes
    /// product images once (with EN+AR catalog text).
    /// </summary>
    private ValueTask QueueTranslateProductFieldsAsync(Product product, CancellationToken cancellationToken)
    {
        return productBackgroundEventQueue.EnqueueAsync(
            new ProductBackgroundWorkItem(
                product.ProductId,
                product.NameEn,
                product.DescriptionEn,
                product.RetailDescriptionEn,
                product.SupplierNotesEn,
                product.ShippingDescriptionEn,
                product.IsReadyForAdminReview || product.IsApproved == true),
            cancellationToken);
    }

    public async Task<object> UpdateAsync(UpdateProductInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var ownerId = await EnsureCompanyOwnerAsync(input.OwnerId, cancellationToken);
        await NormalizeProductCreateFieldsAsync(input, cancellationToken);
        ValidateProductForm(input);
        var categoryId = await ResolveCategoryIdAsync(input.CategoryId, input.CategoryName, cancellationToken);
        var refs = await ResolveProductReferencesAsync(input, cancellationToken);
        ValidateCatalogClassification(categoryId, refs.ProductType?.Id);
        ValidateRetailPricing(input, categoryId, refs.ProductType?.Id, refs);

        var product = await productData.GetProductByIdTrackedAsync(productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (!input.AllowAdminUpdate && product.OwnerId != ownerId)
        {
            throw new UnauthorizedAccessException("You can only update your own products.");
        }

        if (!input.AllowAdminUpdate)
        {
            await EnsureNonUaeCompanyBookingOnlyAsync(
                ownerId,
                refs.ProductType?.Id,
                categoryId,
                cancellationToken);
        }

        var videoPath = await ResolveVideoPathAsync(input, product.VideoPath, cancellationToken);
        var addressId = string.IsNullOrWhiteSpace(input.AddressId)
            ? product.AddressId
            : await ResolveProductAddressIdAsync(ownerId, input.AddressId, cancellationToken);

        var isOwnerEdit = !input.AllowAdminUpdate;
        // Empty Currency on owner FormData must not default to AED and force re-review.
        var resolvedCurrency = isOwnerEdit && string.IsNullOrWhiteSpace(input.Currency)
            ? ResolveProductCurrency(product.Currency, refs.ProductType?.Id ?? product.ProductTypeId)
            : ResolveProductCurrency(input.Currency, refs.ProductType?.Id ?? product.ProductTypeId);

        if (isOwnerEdit)
        {
            await SanitizeOwnerEditLocalizedFieldsAsync(product, input, cancellationToken);
        }

        var requiresAdminReapproval = isOwnerEdit && !IsPriceOnlyProductUpdate(
            product,
            input,
            categoryId,
            refs,
            videoPath,
            addressId,
            resolvedCurrency,
            await LoadOwnerEditTranslationHintsAsync(product.ProductId, cancellationToken));

        // Snapshot MUST run before overwriting NameEn/Description/etc.
        // Keep an existing snapshot only when it came from a previously approved live ad.
        // Replace create-time / junk snapshots so previous â‰  proposed after a real edit.
        if (requiresAdminReapproval)
        {
            var keepExistingSnapshot = PendingProductChangeHelper.IndicatesPreviouslyApprovedEdit(
                product.PendingProductChanges);
            if (!keepExistingSnapshot)
            {
                var media = await productData.GetProductMediaPathsForSnapshotAsync(productId, cancellationToken);

                // Copy scalar values now â€” before any field assignment below.
                var snapshot = PendingProductChangeHelper.Capture(
                    product,
                    media.ImagePaths,
                    media.DocumentPaths,
                    media.ExtraVideoPaths);
                product.PendingProductChanges = PendingProductChangeHelper.Serialize(snapshot);
            }
        }

        if (!string.IsNullOrWhiteSpace(input.NameEn) || input.AllowAdminUpdate)
        {
            product.NameEn = input.NameEn;
        }

        product.USDPrice = input.USDPrice;
        product.Currency = resolvedCurrency;
        product.Quantity = input.Quantity;
        if (!string.IsNullOrWhiteSpace(input.DescriptionEn) || input.AllowAdminUpdate)
        {
            product.DescriptionEn = input.DescriptionEn;
        }

        var isCategoryHybridUpdate =
            product.CategoryId.HasValue
            && product.CategoryId.Value > 0
            && refs.ProductType?.Id == ProductTypeCodes.Retail
            && ProductTypeCodes.HasRetailPricing(product)
            && !categoryId.HasValue;

        if (categoryId.HasValue)
        {
            product.CategoryId = categoryId;
            // ProductTypeId for category dual-retail is owned by ApplyRetailPricingToProduct
            // (sets Retail=1 when enabled, clears when disabled). Do not force null here.
        }
        else if (isCategoryHybridUpdate)
        {
            // Client sent ProductTypeName=Retail without CategoryId (common on mobile edit).
            // Keep wholesale/home catalog classification; do not demote to pure Retail.
        }
        else if (refs.ProductType?.Id != null)
        {
            product.ProductTypeId = refs.ProductType.Id;
            product.CategoryId = null;
            product.RetailPrice = null;
            product.RetailUnitId = null;
            product.RetailQuantity = null;
            product.RetailPackaging = null;
            product.RetailPackagingDetails = null;
            product.RetailDescriptionEn = null;
        }
        else
        {
            product.CategoryId = categoryId;
            product.ProductTypeId = refs.ProductType?.Id;
        }

        product.UnitId = refs.Unit.Id;

        // Owner FormData often omits geo (Requests/Offers/Categories). Do not wipe existing route.
        var geoProvided = refs.OriginCountry is not null
            || refs.DestinationCountry is not null
            || refs.LoadingPort is not null
            || refs.ArrivalPort is not null
            || !string.IsNullOrWhiteSpace(input.OriginCountryName)
            || !string.IsNullOrWhiteSpace(input.DestinationCountryName)
            || !string.IsNullOrWhiteSpace(input.LoadingPortName)
            || !string.IsNullOrWhiteSpace(input.ArrivalPortName);
        if (geoProvided || input.AllowAdminUpdate)
        {
            product.OriginCountryId = refs.OriginCountry?.Id;
            product.DestinationCountryId = refs.DestinationCountry?.Id;
            product.LoadingPortId = refs.LoadingPort?.Id;
            product.ArrivalPortId = refs.ArrivalPort?.Id;
        }

        if (input.MinimumOrderQuantity.HasValue || input.AllowAdminUpdate)
        {
            product.MinimumOrderQuantity = input.MinimumOrderQuantity;
        }

        if (input.MaximumOrderQuantity.HasValue || input.AllowAdminUpdate)
        {
            product.MaximumOrderQuantity = input.MaximumOrderQuantity;
        }

        await ApplyRetailPricingToProductAsync(
            product, input, refs, product.CategoryId, product.ProductTypeId, cancellationToken);

        if (requiresAdminReapproval)
        {
            product.Status = ProductStatusCodes.UnderReview;
            product.IsApproved = false;
            product.DisplayExpiresAtUtc = null;
            // Visible to admin immediately. Media uploads may still follow; SubmitForAdminReview is idempotent.
            product.IsReadyForAdminReview = true;
        }
        else if (!isOwnerEdit)
        {
            product.Status = ResolveProductStatusOnUpdate(product.Status, input.Status);
        }

        if (input.DiscountPercentage.HasValue || input.AllowAdminUpdate)
        {
            product.DiscountPercentage = input.DiscountPercentage;
        }

        if (input.DiscountDays.HasValue || input.AllowAdminUpdate)
        {
            product.DiscountDays = input.DiscountDays;
        }
        if (refs.RequestType != null)
        {
            product.RequestTypeId = refs.RequestType.Id;
        }
        else if (input.AllowAdminUpdate)
        {
            product.RequestTypeId = null;
        }
        // Owner edit with omitted RequestTypeName: keep existing (do not clear).

        if (refs.BookingPriceType != null)
        {
            product.BookingPriceTypeId = refs.BookingPriceType.Id;
        }
        else if (input.AllowAdminUpdate)
        {
            product.BookingPriceTypeId = null;
        }
        else if (refs.ProductType?.Id != ProductTypeCodes.Booking
                 && !string.IsNullOrWhiteSpace(input.BookingPriceTypeName))
        {
            // Explicit clear only when a non-booking type is being set with empty booking type.
            product.BookingPriceTypeId = null;
        }

        if (input.AllowAdminUpdate)
        {
            product.SupplierNotesEn = input.SupplierNotesEn;
        }
        product.Negotiable = input.Negotiable ?? product.Negotiable ?? false;
        var previousVideoPath = product.VideoPath;
        product.VideoPath = videoPath;
        product.VideoDurationSeconds = input.ProductVideoFile is not null
            ? input.VideoDurationSeconds
            : product.VideoDurationSeconds;
        if (input.ProductVideoFile is not null && !string.IsNullOrWhiteSpace(videoPath))
        {
            var primaryVideo = await dbContext.ProductVideos.FirstOrDefaultAsync(
                x => x.ProductId == product.ProductId
                    && x.VideoPath == previousVideoPath,
                cancellationToken);
            if (primaryVideo is null)
            {
                await dbContext.ProductVideos.AddAsync(
                    new ProductVideo
                    {
                        ProductId = product.ProductId,
                        VideoPath = videoPath,
                        VideoDurationSeconds = input.VideoDurationSeconds,
                        IsMuted = true
                    },
                    cancellationToken);
            }
            else
            {
                primaryVideo.VideoPath = videoPath;
                primaryVideo.VideoDurationSeconds = input.VideoDurationSeconds;
            }
        }
        // Empty/null duration or notes mean "leave unchanged" on owner edits
        // (Flutter update FormData used to send "" and wipe values â†’ false re-review).
        if (!string.IsNullOrWhiteSpace(input.ShippingDuration) || input.AllowAdminUpdate)
        {
            var nextShippingDuration = NormalizeShippingDuration(input.ShippingDuration);
            if (nextShippingDuration is not null || input.AllowAdminUpdate)
            {
                product.ShippingDuration = nextShippingDuration;
            }
        }

        if (!string.IsNullOrWhiteSpace(input.OfferDuration) || input.AllowAdminUpdate)
        {
            var nextOfferDuration = NormalizeShippingDuration(input.OfferDuration);
            if (nextOfferDuration is not null || input.AllowAdminUpdate)
            {
                product.OfferDuration = nextOfferDuration;
            }
        }

        if (!string.IsNullOrWhiteSpace(input.ShippingDescriptionEn) || input.AllowAdminUpdate)
        {
            product.ShippingDescriptionEn = string.IsNullOrWhiteSpace(input.ShippingDescriptionEn)
                ? null
                : input.ShippingDescriptionEn.Trim();
        }

        if (input.Packaging.HasValue || input.AllowAdminUpdate)
        {
            product.Packaging = NormalizePackaging(input.Packaging);
        }

        if (!string.IsNullOrWhiteSpace(input.PackagingDetails) || input.AllowAdminUpdate)
        {
            product.PackagingDetails = string.IsNullOrWhiteSpace(input.PackagingDetails)
                ? null
                : input.PackagingDetails.Trim();
        }

        product.AddressId = addressId;
        product.UpdatedAt = UtcDateTimeHelper.UtcNow;

        await productData.SaveChangesAsync(cancellationToken);
        // OpenAI translation must not block update response.
        // CLIP reindex runs once after translation (inside QueueTranslateProductFields).
        await QueueTranslateProductFieldsAsync(product, cancellationToken);
        InvalidateProductCaches(ownerId);
        QueueTextSearchSync(product.ProductId);

        if (requiresAdminReapproval)
        {
            // Alert + live counts already run inside Notify*; do not await on the publish path.
            QueueAdminAdAlert(product, isEdit: true);

            // Same auto-moderation as first submit (edit / post-reject fix).
            // SubmitForAdminReview may also re-queue after late media uploads.
            QueueAutoModeration(product.ProductId, requireManualReview: false);

            var owner = await productData.GetUserByIdAsync(ownerId, tracked: false, cancellationToken);
            var productName = string.IsNullOrWhiteSpace(product.NameEn) ? string.Empty : product.NameEn.Trim();
            var notificationEn = NotificationMessages.AdResubmittedForReview("en", productName);
            var notificationAr = NotificationMessages.AdResubmittedForReview("ar", productName);
            var preferred = NotificationMessages.IsArabic(owner?.PreferredLanguage)
                ? notificationAr
                : notificationEn;
            QueueOwnerNotification(
                owner,
                preferred.EmailSubject,
                preferred.EmailHtml,
                preferred.FcmTitle,
                preferred.FcmBody,
                "ad_resubmitted",
                product.ProductId.ToString(),
                $"ad resubmit for product {product.ProductId}",
                titleEn: notificationEn.FcmTitle,
                bodyEn: notificationEn.FcmBody,
                titleAr: notificationAr.FcmTitle,
                bodyAr: notificationAr.FcmBody);
        }

        var addressLookup = await LoadAddressTextLookupAsync([product.AddressId], cancellationToken);
        var addressText = ResolveAddressText(product.AddressId, addressLookup);

        return BuildProductMutationResponse(
            product,
            refs,
            addressText,
            requiresAdminReview: requiresAdminReapproval);
    }

    /// <inheritdoc />
    public async Task<object> SubmitForAdminReviewAsync(
        string productId,
        string ownerId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var ownerGuid = await EnsureCompanyOwnerAsync(ownerId, cancellationToken);

        var product = await productData.GetProductByIdTrackedAsync(parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.OwnerId != ownerGuid)
        {
            throw new UnauthorizedAccessException("You can only submit your own products.");
        }

        // Price-only (and similar) updates keep IsApproved=true and never enter UnderReview.
        // Mobile still calls this endpoint after every edit â€” treat as a no-op.
        if (product.IsApproved == true
            && product.Status != ProductStatusCodes.UnderReview
            && !PendingProductChangeHelper.IndicatesPreviouslyApprovedEdit(product.PendingProductChanges))
        {
            QueueProductImagesForClipIndexing(product.ProductId);
            return new
            {
                productId = product.ProductId.ToString("D"),
                isReadyForAdminReview = product.IsReadyForAdminReview == true,
                requiresAdminReview = false,
                message = "No admin review required."
            };
        }

        var wasReady = product.IsReadyForAdminReview;
        if (wasReady)
        {
            // Already marked ready (e.g. after Update). Re-run the same auto-moderation
            // scan so post-reject edits and late media uploads are checked again.
            QueueAutoModeration(product.ProductId, requireManualReview: false);
            return new
            {
                productId = product.ProductId.ToString("D"),
                isReadyForAdminReview = true,
                message = "Product already submitted for admin review."
            };
        }

        // First submit of a never-approved ad is always "new", not "edit".
        // Clear accidental create-time PendingProductChanges / UpdatedAt from media uploads.
        var isEditResubmit = PendingProductChangeHelper.IndicatesPreviouslyApprovedEdit(
            product.PendingProductChanges);
        if (!isEditResubmit && product.IsApproved != true)
        {
            product.PendingProductChanges = null;
            product.UpdatedAt = null;
        }

        product.IsReadyForAdminReview = true;
        if (product.IsApproved != true)
        {
            product.Status = ProductStatusCodes.UnderReview;
        }

        await productData.SaveChangesAsync(cancellationToken);
        InvalidateProductCaches(product.OwnerId);
        QueueTextSearchSync(product.ProductId);

        // Same admin alert/counts as before — off the HTTP critical path.
        // Same path for Offers / Requests / Booking / Category:
        // violations → admin dashboard (under review); clean no-video → auto-approve.
        QueueAdminAdAlert(product, isEdit: isEditResubmit);
        QueueAutoModeration(product.ProductId, requireManualReview: false);

        return new
        {
            productId = product.ProductId.ToString("D"),
            isReadyForAdminReview = true,
            message = "Product submitted for admin review."
        };
    }

    /// <summary>
    /// Enqueues auto-moderation without blocking the seller upload/submit response.
    /// CLIP indexing runs after the moderation worker finishes (not on this path).
    /// </summary>
    private void QueueAutoModeration(Guid productId, bool requireManualReview)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await productAutoModerationQueue.EnqueueAsync(
                        new ProductAutoModerationWorkItem(productId, requireManualReview))
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to enqueue auto-moderation for product {ProductId}", productId);
                // Fallback: still index images so search is not stuck.
                QueueProductImagesForClipIndexing(productId);
            }
        });
    }

    /// <summary>
    /// Enqueues CLIP/Qdrant indexing in the background after the HTTP response path â€”
    /// never awaits embedding so publish stays fast for the user.
    /// </summary>
    private void QueueProductImagesForClipIndexing(Guid productId)
    {
        if (!imageEmbeddingOptions.Value.Enabled)
        {
            return;
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var queue = scope.ServiceProvider.GetRequiredService<IProductImageIndexingQueue>();
                var db = scope.ServiceProvider.GetRequiredService<IProductDataAccess>();
                var imageIds = await db.GetProductImageIdsByProductIdAsync(productId)
                    .ConfigureAwait(false);

                foreach (var imageId in imageIds)
                {
                    await queue.EnqueueAsync(imageId).ConfigureAwait(false);
                }

                logger.LogInformation(
                    "Queued {Count} images for background CLIP indexing after publish {ProductId}.",
                    imageIds.Count,
                    productId);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Background CLIP enqueue failed for product {ProductId}", productId);
            }
        });
    }
    public async Task<object> DeleteAsync(DeleteProductInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var product = await productData.GetProductWithMediaForDeleteAsync(productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (!input.AllowAdminDelete)
        {
            await EnsureCanDeleteProductAsync(userId, product, cancellationToken);
        }

        await DeleteProductOrdersAndDependentsAsync(productId, input.WebRootPath, cancellationToken);

        ProductDeleteCascadeResult cascade;
        try
        {
            cascade = await productData.DeleteProductCascadeAsync(product, cancellationToken);
        }
        catch (DbUpdateException ex)
        {
            throw new InvalidOperationException(
                "Cannot delete this product because it is linked to other records.",
                ex);
        }

        InvalidateProductCaches(cascade.OwnerId);
        QueueTextSearchSync(productId, deleted: true);

        await DeleteProductPhysicalAssetsAsync(
            productId,
            cascade.VideoPaths,
            cascade.ImagePaths,
            cascade.DocumentPaths,
            cancellationToken);

        try
        {
            foreach (var imageId in cascade.ImageIds)
            {
                await productImageVectorIndex.DeleteByProductImageIdAsync(imageId, cancellationToken);
            }

            await productImageVectorIndex.DeleteByProductIdAsync(productId, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed removing Qdrant vectors for deleted product {ProductId}",
                productId);
        }

        return new { message = "Product deleted successfully." };
    }

    public async Task<object> SetListingStatusAsync(
        SetProductListingStatusInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var ownerId = await EnsureCompanyOwnerAsync(input.OwnerId, cancellationToken);

        var product = await productData.GetProductByIdTrackedAsync(productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.OwnerId != ownerId)
        {
            throw new UnauthorizedAccessException("You can only manage your own listings.");
        }

        if (product.IsApproved != true)
        {
            throw new InvalidOperationException(
                "Cannot pause or activate a listing until it is approved by admin.");
        }

        var normalized = ProductStatusCodes.Normalize(product.Status, product.IsApproved);

        if (input.IsActive)
        {
            if (normalized == ProductStatusCodes.Paused)
            {
                product.Status = ProductStatusCodes.Active;
                await ApplyAdDisplayExpiryAsync(product, cancellationToken);
            }
            else if (normalized != ProductStatusCodes.Active)
            {
                throw new InvalidOperationException("Only paused listings can be reactivated.");
            }
        }
        else
        {
            if (normalized == ProductStatusCodes.Active)
            {
                product.Status = ProductStatusCodes.Paused;
            }
            else if (normalized != ProductStatusCodes.Paused)
            {
                throw new InvalidOperationException("Only active listings can be paused.");
            }
        }

        product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        await productData.SaveChangesAsync(cancellationToken);
        InvalidateProductCaches(ownerId);
        QueueTextSearchSync(product.ProductId);

        var statusName = ProductStatusCodes.ToDisplayName(product.Status, product.IsApproved);
        var isPublic = ProductStatusCodes.IsPubliclyVisible(product.Status, product.IsApproved);

        return new
        {
            productId = product.ProductId,
            status = statusName,
            statusLabelAr = AdminMappings.GetProductStatusLabelAr(product.Status, product.IsApproved),
            isPubliclyVisible = isPublic,
            message = input.IsActive
                ? "Listing activated successfully."
                : "Listing paused successfully."
        };
    }

    public async Task<object> UpdatePriceAsync(
        SetProductPriceInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        if (input.UsdPrice is null && input.RetailPrice is null)
        {
            throw new ArgumentException("Provide usdPrice and/or retailPrice.");
        }

        if (input.UsdPrice is <= 0)
        {
            throw new ArgumentException("Price must be greater than zero.");
        }

        if (input.RetailPrice is <= 0)
        {
            throw new ArgumentException("Retail price must be greater than zero.");
        }

        var ownerId = await EnsureCompanyOwnerAsync(input.OwnerId, cancellationToken);

        var product = await productData.GetProductByIdTrackedAsync(productId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.OwnerId != ownerId)
        {
            throw new UnauthorizedAccessException("You can only update your own listings.");
        }

        if (input.UsdPrice is > 0)
        {
            product.USDPrice = input.UsdPrice.Value;
        }

        if (input.RetailPrice is > 0)
        {
            product.RetailPrice = input.RetailPrice.Value;
        }

        product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        await productData.SaveChangesAsync(cancellationToken);
        InvalidateProductCaches(ownerId);
        QueueTextSearchSync(product.ProductId);

        return new
        {
            productId = product.ProductId,
            usdPrice = product.USDPrice,
            retailPrice = product.RetailPrice,
            message = "Price updated successfully."
        };
    }

    public async Task<object> MarkSoldOutAsync(
        string productId,
        string ownerId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(productId, out var parsedId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var owner = await EnsureCompanyOwnerAsync(ownerId, cancellationToken);

        var product = await productData.GetProductByIdTrackedAsync(parsedId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.OwnerId != owner)
        {
            throw new UnauthorizedAccessException("You can only manage your own listings.");
        }

        if (product.Quantity <= 0)
        {
            return new
            {
                productId = product.ProductId,
                quantity = product.Quantity,
                message = "Listing is already sold out."
            };
        }

        product.Quantity = 0;
        product.UpdatedAt = UtcDateTimeHelper.UtcNow;
        await productData.SaveChangesAsync(cancellationToken);
        InvalidateProductCaches(owner);
        QueueTextSearchSync(product.ProductId);

        return new
        {
            productId = product.ProductId,
            quantity = product.Quantity,
            message = "Listing marked as sold out."
        };
    }
}
