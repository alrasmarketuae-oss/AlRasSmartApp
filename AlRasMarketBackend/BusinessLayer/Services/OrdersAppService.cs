using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public partial class OrdersAppService(
    IOrderDataAccess orderData,
    IMemoryCache cache,
    IFcmNotificationService fcmNotificationService,
    IConfiguration configuration,
    IStaticReferenceCache staticReferenceCache,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    IOrderRealtimeNotificationService orderRealtimeNotificationService,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider,
    IContentTranslationService contentTranslationService,
    IServiceProvider serviceProvider,
    ILogger<OrdersAppService> logger,
    IMediaStorageService mediaStorage,
    ISupplierBalanceService supplierBalanceService,
    IOrderOfferAutoModerationQueue orderOfferAutoModerationQueue) : IOrdersAppService
{
    public async Task<object> PlaceBookingOrderAsync(CreateDirectOrderInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.AuthenticatedUserId, out var fromUserId))
        {
            throw new ArgumentException("Invalid authenticated user.");
        }

        if (string.IsNullOrWhiteSpace(input.ToUserId))
        {
            throw new ArgumentException("ToUserId is required.");
        }

        if (!Guid.TryParse(input.ToUserId, out var toUserId))
        {
            throw new ArgumentException("ToUserId must be a valid guid.");
        }

        if (string.IsNullOrWhiteSpace(input.ProductId))
        {
            throw new ArgumentException("ProductId is required.");
        }

        if (!Guid.TryParse(input.ProductId, out var productId))
        {
            throw new ArgumentException("ProductId must be a valid guid.");
        }

        if (input.Quantity <= 0)
        {
            throw new ArgumentException("Quantity must be greater than zero.");
        }

        if (input.UnitPrice <= 0)
        {
            throw new ArgumentException("UnitPrice must be greater than zero.");
        }

        if (input.TotalPrice <= 0)
        {
            throw new ArgumentException("TotalPrice must be greater than zero.");
        }

        var product = await ResolveProductByIdAsync(productId, cancellationToken);

        if (string.IsNullOrWhiteSpace(input.UnitName) && product.UnitId is null or 0)
        {
            throw new ArgumentException("UnitName is required.");
        }

        var paymentMethod = ParsePaymentMethod(input.PaymentMethodName);
        EnsureOnlinePaymentAllowed(product, paymentMethod);
        if (paymentMethod == PaymentMethod.Online && !IsStripeConfigured())
        {
            throw new InvalidOperationException("Online payment is not available right now.");
        }

        var fromUser = await orderData.GetUserByIdAsync(fromUserId, cancellationToken: cancellationToken)
            ?? throw new KeyNotFoundException("Authenticated user not found.");

        if (product.OwnerId is null)
        {
            throw new InvalidOperationException("Product has no owner.");
        }

        OrderOwnershipRules.EnsureBuyerIsNotOwner(fromUserId, product.OwnerId);

        // DEV: ToUserId mismatch — نستخدم مالك المنتج تلقائياً بدل الرفض.
        // PRODUCTION: أزل التعليق عن الكود التالي واحذف بلوك الـ DEV:
        /*
        if (product.OwnerId != toUserId)
        {
            throw new ArgumentException("ToUserId does not match the product owner.");
        }
        */
        if (product.OwnerId != toUserId)
        {
            toUserId = product.OwnerId.Value;
        }

      

        var toUser = await orderData.GetUserByIdAsync(toUserId, cancellationToken: cancellationToken)
            ?? throw new KeyNotFoundException("Supplier user not found.");

        // DEV: تعطيل التحقق من SupplierEmail.
        // PRODUCTION: أزل التعليق:
        /*
        if (!string.IsNullOrWhiteSpace(input.SupplierEmail)
            && !string.Equals(toUser.Email.Trim(), input.SupplierEmail.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException("SupplierEmail does not match the product owner.");
        }
        */

        // Request offers: always persist the supplier's chosen unit (not the request ad unit).
        UnitSnapshot? unit;
        if (ProductTypeCodes.IsRequests(product.ProductTypeId))
        {
            if (string.IsNullOrWhiteSpace(input.UnitName))
            {
                throw new ArgumentException("UnitName is required.");
            }

            unit = staticReferenceCache.FindUnitByName(input.UnitName)
                ?? throw new KeyNotFoundException($"Unit '{input.UnitName}' was not found.");
        }
        else
        {
            unit = product.UnitId is byte productUnitId
                ? staticReferenceCache.FindUnitById(productUnitId)
                : null;

            if (unit is null && !string.IsNullOrWhiteSpace(input.UnitName))
            {
                unit = staticReferenceCache.FindUnitByName(input.UnitName);
            }

            if (unit is null)
            {
                throw new KeyNotFoundException(
                    $"Unit for product was not found (submitted: '{input.UnitName}').");
            }
        }

        if (!ProductStatusCodes.IsPubliclyVisible(product.Status, product.IsApproved))
        {
            throw new InvalidOperationException("Product is not available for ordering.");
        }

        ValidateDirectOrderQuantity(product, input.Quantity);
        var orderPort = ResolveOrderPort(product, input.PortName);

        var (orderUnitPrice, orderTotalPrice) = product.ProductTypeId == ProductTypeCodes.Requests
            ? AdminOrderPricingHelper.NormalizeRequestsOrderAmounts(
                input.Quantity,
                input.UnitPrice,
                input.TotalPrice)
            : (
                decimal.Round(input.UnitPrice, 2, MidpointRounding.AwayFromZero),
                decimal.Round(input.TotalPrice, 2, MidpointRounding.AwayFromZero));

        var imagePaths = NormalizeOrderAssetPaths(input.ImagePaths, "product-images", "image");
        var videoPaths = NormalizeOrderAssetPaths(input.VideoPaths, "order-videos", "video");
        var documentPaths = NormalizeOrderAssetPaths(input.DocumentPaths, "product-documents", "document");
        if (imagePaths.Count > 15)
        {
            throw new ArgumentException("An order can have at most 15 images.");
        }
        var notes = NormalizeNotes(input.Notes);

        var (statusId, isAdminApproved) = ResolveInitialOrderStatus(
            product,
            (byte)paymentMethod,
            notes,
            imagePaths.Count,
            documentPaths.Count,
            videoPaths.Count);

        var order = new Order
        {
            FromUserId = fromUser.Id,
            ToUserId = toUser.Id,
            ProductId = product.ProductId,
            Quantity = input.Quantity,
            UnitPrice = orderUnitPrice,
            TotalPrice = orderTotalPrice,
            StatusId = statusId,
            OrderGroupId = Guid.NewGuid(),
            PaymentMethod = (byte)paymentMethod,
            UnitId = unit.Id,
            IsApproved = false,
            IsAdminApproved = isAdminApproved,
            // Direct / category / booking PO — never the retail cart channel.
            IsRetailPurchase = false,
            Notes = notes,
            StockQuantityDeducted = false,
            PortId = orderPort?.Id,
            CreatedAt = DateTime.SpecifyKind(UtcDateTimeHelper.UtcNow, DateTimeKind.Utc),
        };

        if (ProductTypeCodes.IsRequests(product.ProductTypeId))
        {
            if (isAdminApproved)
            {
                RequestOfferStatusLabels.ApplyAwaitingAdvertiser(order);
            }
            else
            {
                RequestOfferStatusLabels.ApplyAwaitingAdmin(order);
            }
        }
        else if (ProductTypeCodes.IsOffers(product.ProductTypeId))
        {
            if (isAdminApproved)
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else
            {
                RequestOfferStatusLabels.ApplyAwaitingAdmin(order);
            }
        }
        else if (ProductTypeCodes.IsBooking(product.ProductTypeId))
        {
            if (isAdminApproved)
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else
            {
                RequestOfferStatusLabels.ApplyAwaitingAdmin(order);
            }
        }
        else if (ProductTypeCodes.IsCategoryProduct(product))
        {
            if (isAdminApproved)
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else
            {
                RequestOfferStatusLabels.ApplyAwaitingAdmin(order);
            }
        }
        else if (ProductTypeCodes.StartsWithSellerApproval(product))
        {
            RequestOfferStatusLabels.ApplyAwaitingSeller(order);
        }

        foreach (var path in imagePaths)
        {
            order.Images.Add(new OrderImage
            {
                ImagePath = path,
                UploadedByUserId = fromUserId
            });
        }

        // Documents are stored alongside images (path-only); UI separates by extension/folder.
        foreach (var path in documentPaths)
        {
            order.Images.Add(new OrderImage
            {
                ImagePath = path,
                UploadedByUserId = fromUserId
            });
        }

        foreach (var path in videoPaths)
        {
            order.Videos.Add(new OrderVideo
            {
                VideoPath = path,
                UploadedByUserId = fromUserId
            });
        }

        await orderData.AddOrderAsync(order, cancellationToken);
        await orderData.SaveChangesAsync(cancellationToken);
        await TryTranslateOrderNotesAsync(order.Id, notes, cancellationToken);
        logger.LogInformation(
            "Order {OrderId} created for product {ProductId} with UnitId={UnitId} UnitName={UnitName} (submitted '{SubmittedUnit}')",
            order.Id,
            product.ProductId,
            order.UnitId,
            unit.UnitNameEn,
            input.UnitName);
        ProductsAppService.InvalidateListingCaches();
        await NotifyOrderPartiesAsync([order], cancellationToken);

        // Requests / Offers / Booking / Category pending admin review → same auto-moderation as ads.
        if (!isAdminApproved
            && ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(product))
        {
            QueueOrderOfferAutoModeration(order.Id);
        }

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);

        return new
        {
            order = AdminOrderPricingHelper.ToCustomerFacingDetail(
                order,
                product,
                commissionSettings,
                categoryCommissions),
            availableQuantity = product.Quantity
        };
    }

    private void QueueOrderOfferAutoModeration(long orderId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await orderOfferAutoModerationQueue.EnqueueAsync(
                        new OrderOfferAutoModerationWorkItem(orderId))
                    .ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Failed to enqueue offer auto-moderation for order {OrderId}", orderId);
            }
        });
    }

    private async Task TryTranslateOrderNotesAsync(long orderId, string? notes, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(notes))
        {
            return;
        }

        try
        {
            await contentTranslationService.UpsertOrderOfferNotesAsync(orderId, notes, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Order notes translation failed for order {OrderId}", orderId);
        }
    }

}
