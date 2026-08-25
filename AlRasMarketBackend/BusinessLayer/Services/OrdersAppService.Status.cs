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

public partial class OrdersAppService
{
    public async Task<object> UpdateOrderStatusAsync(UpdateOrderStatusInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (!OrderStatusCodes.IsValid(input.StatusId))
        {
            throw new ArgumentException("Invalid order status.");
        }

        var order = await orderData.GetOrderWithProductForStatusAsync(input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        var user = await orderData.GetUserByIdAsync(userId, cancellationToken: cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (!OrderStatusCodes.CanTransition(
                order.StatusId,
                input.StatusId,
                order.Product?.ProductTypeId))
        {
            throw new InvalidOperationException(
                $"Cannot change order status from '{OrderStatusCodes.GetNameEn(order.StatusId)}' to '{OrderStatusCodes.GetNameEn(input.StatusId)}'.");
        }

        if (ProductTypeCodes.UsesAdminCustomStatus(order.Product)
            && !ProductTypeCodes.IsRetailOrder(order)
            && input.StatusId is OrderStatusCodes.Paid
                or OrderStatusCodes.Shipping
                or OrderStatusCodes.Delivered
                or OrderStatusCodes.PaidToSupplier
                or OrderStatusCodes.Received)
        {
            throw new InvalidOperationException(
                "After seller approval, update this order with a custom bilingual status instead of Paid/Shipping/Delivered.");
        }

        if (ProductTypeCodes.IsRetailOrder(order)
            && order.PaymentMethod == (byte)PaymentMethod.CashOnDelivery
            && input.StatusId == OrderStatusCodes.Paid)
        {
            throw new InvalidOperationException(
                "Cash on delivery retail orders are paid on delivery. Mark the order as Shipping instead of Paid.");
        }

        EnsureUserCanUpdateStatus(user, order, input.StatusId);

        if (input.StatusId == OrderStatusCodes.Cancelled)
        {
            await ApplyCancellationMetadataAsync(order, user, input, cancellationToken);
        }

        var previousStatus = order.StatusId;
        var isAdmin = user.RoleId == 1;
        var product = order.Product;
        var productTypeId = product?.ProductTypeId;
        var sellerFirst = ProductTypeCodes.StartsWithSellerApproval(product)
            || ProductTypeCodes.IsRetailOrder(order);
        var needsModeration = ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(product);
        var stockChanged = false;

        if (needsModeration
            && !order.IsAdminApproved
            && !isAdmin
            && input.StatusId is OrderStatusCodes.Approved or OrderStatusCodes.Cancelled
                or OrderStatusCodes.Shipping or OrderStatusCodes.Delivered)
        {
            throw new InvalidOperationException("This order is pending admin review.");
        }

        if (input.StatusId == OrderStatusCodes.Approved
            && !isAdmin
            && (sellerFirst || needsModeration)
            && order.StatusId != OrderStatusCodes.AwaitingSellerApproval)
        {
            throw new InvalidOperationException("This order is not awaiting seller approval.");
        }

        // Admin pre-approval → seller inbox (Booking / Requests with media).
        if (input.StatusId == OrderStatusCodes.Approved
            && isAdmin
            && !order.IsAdminApproved
            && needsModeration)
        {
            order.IsAdminApproved = true;
            order.StatusId = OrderStatusCodes.AwaitingSellerApproval;
            if (ProductTypeCodes.IsRequests(productTypeId))
            {
                RequestOfferStatusLabels.ApplyAwaitingAdvertiser(order);
            }
            else if (ProductTypeCodes.IsOffers(productTypeId))
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else if (ProductTypeCodes.IsBooking(productTypeId))
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }
            else if (ProductTypeCodes.IsCategoryProduct(product?.CategoryId, productTypeId))
            {
                RequestOfferStatusLabels.ApplyAwaitingSeller(order);
            }

            await orderData.SaveChangesAsync(cancellationToken);
            ProductsAppService.InvalidateListingCaches();

            try
            {
                await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
            }
            catch
            {
                // Realtime notification failure must not roll back order updates.
            }

            var orderForModerationNotify = await orderData.GetOrderWithListDetailsAsync(input.OrderId, cancellationToken)
                ?? order;
            await NotifyAdvertiserOfAdminApprovedOrderAsync(orderForModerationNotify, cancellationToken);
            await PublishOrderRealtimeAsync(orderForModerationNotify, cancellationToken);

            var moderationCommissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
            var moderationCategoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
            var moderationUsdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

            var moderationDto = AdminOrderMapper.Map(order);
            AdminOrderPricingHelper.ApplyPricingFields(
                moderationDto,
                order,
                order.Product,
                moderationCommissionSettings,
                moderationCategoryCommissions,
                moderationUsdToAedRate);
            AdminOrderPricingHelper.ApplyChargedCheckoutAmounts(moderationDto, order);
            return moderationDto;
        }

        order.StatusId = input.StatusId;

        if (input.StatusId is OrderStatusCodes.Shipping
            or OrderStatusCodes.Delivered
            or OrderStatusCodes.Paid
            or OrderStatusCodes.PaidToSupplier)
        {
            order.CustomStatusNameEn = null;
            order.CustomStatusNameAr = null;
        }

        if (input.StatusId == OrderStatusCodes.Approved)
        {
            order.IsApproved = true;
            if (sellerFirst || ProductTypeCodes.IsOffers(productTypeId))
            {
                order.IsAdminApproved = true;
            }

            TryDeductStockOnOrderApproval(order);
            if (ProductTypeCodes.IsRequests(productTypeId))
            {
                RequestOfferStatusLabels.ApplyAcceptedByRequester(order);
            }
            else if (sellerFirst || ProductTypeCodes.IsOffers(productTypeId))
            {
                RequestOfferStatusLabels.ApplyAcceptedBySeller(order);
            }
        }

        if (input.StatusId == OrderStatusCodes.Cancelled)
        {
            if (ProductTypeCodes.IsRequests(productTypeId) && !isAdmin)
            {
                RequestOfferStatusLabels.ApplyRejectedByAdvertiser(order, userId);
            }
            else if ((sellerFirst || ProductTypeCodes.IsOffers(productTypeId)) && !isAdmin)
            {
                RequestOfferStatusLabels.ApplyRejectedOrder(order, userId);
            }
            else
            {
                RequestOfferStatusLabels.ApplyCancelled(order, userId);
            }

            if (order.StockQuantityDeducted
                && order.Product is not null
                && previousStatus != OrderStatusCodes.Delivered)
            {
                var restoreQuantity = ResolveQuantityInProductUnits(order, order.Product);
                ApplyStockRestore(order, order.Product, restoreQuantity);
                stockChanged = true;
            }
        }

        await orderData.SaveChangesAsync(cancellationToken);

        // Push updated live counts to the admin dashboard so an admin standing on
        // this order's detail page (or a list) sees the status change in real time,
        // even when the change is initiated from the mobile app (seller/buyer).
        try
        {
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        }
        catch
        {
            // Realtime notification failure must not roll back order updates.
        }

        if (input.StatusId == OrderStatusCodes.Approved
            && (ProductTypeCodes.IsRequests(order.Product?.ProductTypeId)
                || ProductTypeCodes.IsOffers(order.Product?.ProductTypeId)
                || ProductTypeCodes.IsBooking(order.Product?.ProductTypeId)
                || ProductTypeCodes.IsRetailOrder(order)
                || ProductTypeCodes.IsCategoryProduct(order.Product)))
        {
            stockChanged = true;
        }

        if (stockChanged)
        {
            ProductsAppService.InvalidateListingCaches();
        }

        string? refundMessage = null;
        if (input.StatusId == OrderStatusCodes.Cancelled
            && order.PaymentMethod == (byte)PaymentMethod.Online)
        {
            refundMessage = await TryRefundCancelledOnlineOrderAsync(order.Id, cancellationToken);
        }

        var orderForNotification = await orderData.GetOrderWithDetailDetailsAsync(input.OrderId, cancellationToken)
            ?? order;

        await NotifyBuyerOrderStatusAsync(orderForNotification, userId, cancellationToken);
        if (input.StatusId == OrderStatusCodes.Cancelled
            && orderForNotification.PaymentMethod == (byte)PaymentMethod.Online
            && (orderForNotification.RefundedAtUtc.HasValue
                || !string.IsNullOrWhiteSpace(orderForNotification.StripeRefundId)))
        {
            await NotifyBuyerRefundProcessedAsync(orderForNotification, cancellationToken);
        }

        // Seller/advertiser accepted → notify admins so they can continue the workflow.
        if (input.StatusId == OrderStatusCodes.Approved
            && !isAdmin
            && previousStatus == OrderStatusCodes.AwaitingSellerApproval)
        {
            await NotifyAdminSellerApprovedOrderAsync(order, cancellationToken);
        }

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);

        var mappedOrder = orderForNotification.Product is not null ? orderForNotification : order;
        var detail = AdminOrderPricingHelper.ToCustomerFacingDetail(
            mappedOrder,
            mappedOrder.Product ?? throw new InvalidOperationException("Order product is missing."),
            commissionSettings,
            categoryCommissions);

        if (refundMessage is not null)
        {
            return new
            {
                order = detail,
                refundMessage,
                refundMessageAr = "سيتم إعادة المبلغ إلى نفس طريقة الدفع خلال يوم عمل واحد."
            };
        }

        return detail;
    }

    public async Task<IReadOnlyList<OrderCancellationReasonDto>> GetCancellationReasonsAsync(
        CancellationToken cancellationToken = default)
    {
        var reasons = await orderData.GetActiveCancellationReasonsAsync(cancellationToken);
        return reasons
            .Select(x => new OrderCancellationReasonDto
            {
                Id = x.Id,
                NameEn = x.NameEn,
                NameAr = x.NameAr,
                RequiresNote = OrderCancellationReasonCodes.RequiresNote(x.Id)
            })
            .ToList();
    }

    private async Task ApplyCancellationMetadataAsync(
        Order order,
        User user,
        UpdateOrderStatusInput input,
        CancellationToken cancellationToken)
    {
        var reasonId = await ResolveCancellationReasonIdAsync(order, user, input.CancellationReasonId, cancellationToken);
        var note = string.IsNullOrWhiteSpace(input.CancellationNote)
            ? null
            : input.CancellationNote.Trim();

        if (note is { Length: > 2000 })
        {
            throw new ArgumentException("Cancellation note cannot exceed 2000 characters.");
        }

        if (OrderCancellationReasonCodes.RequiresNote(reasonId) && string.IsNullOrWhiteSpace(note))
        {
            throw new ArgumentException("Cancellation note is required when the reason is Other.");
        }

        order.CancellationReasonId = reasonId;
        order.CancellationNote = note;
        order.CancelledAt = DateTime.UtcNow;
        order.CancelledByUserId = user.Id;
    }

    private async Task<byte> ResolveCancellationReasonIdAsync(
        Order order,
        User user,
        byte? requestedReasonId,
        CancellationToken cancellationToken)
    {
        if (requestedReasonId.HasValue)
        {
            var reason = await orderData.GetCancellationReasonByIdAsync(requestedReasonId.Value, cancellationToken)
                ?? throw new ArgumentException("Invalid cancellation reason.");
            if (!reason.IsActive)
            {
                throw new ArgumentException("The selected cancellation reason is not available.");
            }

            return reason.Id;
        }

        var isBuyer = order.FromUserId == user.Id;
        var isSeller = order.ToUserId == user.Id || order.Product?.OwnerId == user.Id;

        if (isBuyer)
        {
            return OrderCancellationReasonCodes.BuyerRequested;
        }

        if (isSeller)
        {
            return OrderCancellationReasonCodes.SupplierUnavailable;
        }

        throw new ArgumentException("CancellationReasonId is required to cancel an order.");
    }

    private async Task<string> TryRefundCancelledOnlineOrderAsync(long orderId, CancellationToken cancellationToken)
    {
        const string successEn = "The amount will be refunded to your original payment method within one business day.";
        try
        {
            var payments = serviceProvider.GetRequiredService<IPaymentsAppService>();
            await payments.RefundCancelledOrderAsync(orderId, cancellationToken);
            return successEn;
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Auto-refund failed for cancelled order {OrderId}. Manual refund may be required.", orderId);
            return successEn;
        }
    }

}
