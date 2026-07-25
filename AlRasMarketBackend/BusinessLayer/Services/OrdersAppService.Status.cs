using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
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

        var order = await dbContext.Orders
            .Include(x => x.Product!)
            .ThenInclude(x => x!.ProductType)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .FirstOrDefaultAsync(x => x.Id == input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
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

        var previousStatus = order.StatusId;
        var isAdmin = user.RoleId == 1;
        var product = order.Product;
        var productTypeId = product?.ProductTypeId;
        var sellerFirst = ProductTypeCodes.StartsWithSellerApproval(product)
            || ProductTypeCodes.IsRetailOrder(order);
        var needsModeration = ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(product)
            && !ProductTypeCodes.IsRetailOrder(order);
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

            await dbContext.SaveChangesAsync(cancellationToken);
            ProductsAppService.InvalidateListingCaches();

            var orderForModerationNotify = await AdminOrderMapper.WithAdminListDetails(dbContext.Orders)
                .FirstOrDefaultAsync(x => x.Id == input.OrderId, cancellationToken)
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
                RequestOfferStatusLabels.ApplyRejectedByAdvertiser(order);
            }
            else if ((sellerFirst || ProductTypeCodes.IsOffers(productTypeId)) && !isAdmin)
            {
                RequestOfferStatusLabels.ApplyRejectedOrder(order);
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

        await dbContext.SaveChangesAsync(cancellationToken);

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

        var orderForNotification = await AdminOrderMapper.WithAdminListDetails(dbContext.Orders)
            .FirstOrDefaultAsync(x => x.Id == input.OrderId, cancellationToken)
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

        var detail = AdminOrderPricingHelper.ToCustomerFacingDetail(
            order,
            order.Product ?? throw new InvalidOperationException("Order product is missing."),
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
