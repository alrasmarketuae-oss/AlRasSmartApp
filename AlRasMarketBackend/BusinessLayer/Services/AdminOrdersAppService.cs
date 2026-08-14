using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Services;

public class AdminOrdersAppService(
    IOrderDataAccess orderData,
    IOrdersAppService ordersAppService,
    IContentTranslationService contentTranslationService,
    IAdminRealtimeNotificationService adminRealtimeNotificationService,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider,
    IAdminAuditLogAppService auditLogAppService,
    IConfiguration configuration) : IAdminOrdersAppService
{
    private readonly IOrdersAppService _ordersAppService = ordersAppService;

    public async Task<AdminOrderStatsDto> GetOrderStatsAsync(CancellationToken cancellationToken = default)
    {
        var stats = await orderData.GetAdminOrderStatsAsync(cancellationToken);

        return new AdminOrderStatsDto
        {
            TotalOrders = stats.TotalOrders,
            TotalOrdersChangePercent = AdminMappings.PercentChange(stats.OrdersThisMonth, stats.OrdersLastMonth),
            OrderedCount = stats.OrderedCount,
            ShippingCount = stats.ShippingCount,
            DeliveredCount = stats.DeliveredCount,
        };
    }

    public async Task<AdminOrderListItemDto> GetOrderByIdAsync(long orderId, CancellationToken cancellationToken = default)
    {
        var order = await orderData.GetAdminVisibleOrderWithDetailDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

        var dto = AdminOrderMapper.Map(order);
        await ApplyProductTranslationsAsync(dto, order.Product, cancellationToken);
        await ApplyUserTranslationsAsync([dto], cancellationToken);
        AdminOrderPricingHelper.ApplyPricingFields(
            dto,
            order,
            order.Product,
            commissionSettings,
            categoryCommissions,
            usdToAedRate);
        AdminOrderPricingHelper.ApplyChargedCheckoutAmounts(dto, order);
        await EnrichLegacyPendingPaymentIdsAsync(dto, order.Id, cancellationToken);
        return dto;
    }

    /// <summary>
    /// Older cart checkouts stored Stripe IDs on PendingPayments (per order) instead of PendingOrders.
    /// </summary>
    private async Task EnrichLegacyPendingPaymentIdsAsync(
        AdminOrderListItemDto dto,
        long orderId,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(dto.PaymentIntentId)
            && !string.IsNullOrWhiteSpace(dto.StripeSessionId)
            && !string.IsNullOrWhiteSpace(dto.StripeRefundId))
        {
            return;
        }

        var pendingPayment = await orderData.GetPendingPaymentByOrderIdAsync(orderId, cancellationToken);
        if (pendingPayment is null)
        {
            return;
        }

        dto.StripeSessionId ??= string.IsNullOrWhiteSpace(pendingPayment.StripeSessionId)
            ? null
            : pendingPayment.StripeSessionId.Trim();
        dto.PaymentIntentId ??= string.IsNullOrWhiteSpace(pendingPayment.PaymentIntentId)
            ? null
            : pendingPayment.PaymentIntentId.Trim();
        dto.StripeRefundId ??= string.IsNullOrWhiteSpace(pendingPayment.StripeRefundId)
            ? null
            : pendingPayment.StripeRefundId.Trim();
        dto.RefundedAtUtc ??= pendingPayment.RefundedAtUtc.HasValue
            ? UtcDateTimeHelper.AsUtc(pendingPayment.RefundedAtUtc.Value)
            : null;
        dto.IsRefunded = dto.IsRefunded
            || dto.RefundedAtUtc.HasValue
            || !string.IsNullOrWhiteSpace(dto.StripeRefundId);
    }

    public async Task<object> GetOrdersAsync(
        int page,
        int pageSize,
        byte? statusId,
        byte? productTypeId,
        byte? excludeProductTypeId,
        string? productId,
        string? search,
        DateTime? createdFrom,
        DateTime? createdTo,
        string? offerReview = null,
        string? orderChannel = null,
        CancellationToken cancellationToken = default)
    {
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        Guid? parsedProductId = null;
        if (!string.IsNullOrWhiteSpace(productId) && Guid.TryParse(productId.Trim(), out var guid))
        {
            parsedProductId = guid;
        }

        var (orders, totalCount) = await orderData.GetAdminOrdersPageAsync(
            new AdminOrdersPageFilter
            {
                Page = page,
                PageSize = pageSize,
                StatusId = statusId,
                ProductTypeId = productTypeId,
                ExcludeProductTypeId = excludeProductTypeId,
                ProductId = parsedProductId,
                Search = search,
                CreatedFrom = createdFrom,
                CreatedTo = createdTo,
                OfferReview = offerReview,
                OrderChannel = orderChannel,
            },
            cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

        var items = orders.Select(order =>
        {
            var dto = AdminOrderMapper.Map(order);
            AdminOrderPricingHelper.ApplyPricingFields(
                dto,
                order,
                order.Product,
                commissionSettings,
                categoryCommissions,
                usdToAedRate);
            AdminOrderPricingHelper.ApplyChargedCheckoutAmounts(dto, order);
            return dto;
        }).ToList();

        await ApplyProductTranslationsAsync(items, orders, cancellationToken);
        await ApplyUserTranslationsAsync(items, cancellationToken);

        return new AdminPagedResult<AdminOrderListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<object> UpdateOrderStatusAsync(
        string adminUserId,
        long orderId,
        byte statusId,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.UpdateOrderStatusAsync(new UpdateOrderStatusInput
        {
            UserId = adminUserId,
            OrderId = orderId,
            StatusId = statusId
        }, cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderStatusUpdate,
            orderId,
            $"Updated order #{orderId} status to {OrderStatusCodes.GetNameEn(statusId)}",
            new { statusId, statusName = OrderStatusCodes.GetNameEn(statusId) },
            cancellationToken);
        return result;
    }

    public async Task<object> ApproveRequestOfferAsync(
        string adminUserId,
        long orderId,
        decimal? adminUnitPrice = null,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.ApproveRequestOfferForAdminAsync(
            adminUserId,
            orderId,
            adminUnitPrice,
            adminTotalPrice,
            cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderApproveOffer,
            orderId,
            adminUnitPrice is > 0
                ? $"Approved order #{orderId} for seller review with advertiser unit price {adminUnitPrice.Value:0.00}"
                : $"Approved order #{orderId} for seller review",
            adminUnitPrice is > 0 ? new { adminUnitPrice, adminTotalPrice } : null,
            cancellationToken);
        return result;
    }

    public async Task<object> SetRequestOfferAdvertiserPriceAsync(
        string adminUserId,
        long orderId,
        decimal adminUnitPrice,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.SetRequestOfferAdvertiserPriceAsync(
            adminUserId,
            orderId,
            adminUnitPrice,
            adminTotalPrice,
            cancellationToken);

        await WriteOrderAuditAsync(
            AdminAuditActions.OrderApproveOffer,
            orderId,
            $"Set advertiser price on order #{orderId} to unit {adminUnitPrice:0.00}",
            new { adminUnitPrice, adminTotalPrice },
            cancellationToken);
        return result;
    }

    public async Task<object> RejectRequestOfferAsync(
        string adminUserId,
        long orderId,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.RejectRequestOfferForAdminAsync(
            adminUserId,
            orderId,
            cancellationToken: cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderRejectOffer,
            orderId,
            $"Rejected order #{orderId}",
            null,
            cancellationToken);
        return result;
    }

    public async Task<object> SetCustomOrderStatusAsync(
        string adminUserId,
        long orderId,
        string statusNameEn,
        string statusNameAr,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.SetCustomOrderStatusAsync(
            adminUserId,
            orderId,
            statusNameEn,
            statusNameAr,
            cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderCustomStatus,
            orderId,
            $"Set custom status on order #{orderId}: {statusNameEn.Trim()}",
            new { statusNameEn, statusNameAr },
            cancellationToken);
        return result;
    }

    public async Task<object> MarkOrderReceivedAsync(
        string adminUserId,
        long orderId,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.MarkOrderReceivedAsync(
            adminUserId,
            orderId,
            cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderMarkReceived,
            orderId,
            $"Marked order #{orderId} as received",
            null,
            cancellationToken);
        return result;
    }

    public async Task<object> RespondToReturnAsync(
        string adminUserId,
        long orderId,
        string response,
        bool approved,
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.RespondToOrderReturnAsync(
            new RespondToOrderReturnInput
            {
                AdminUserId = adminUserId,
                OrderId = orderId,
                Response = response,
                Approved = approved
            },
            cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            approved ? AdminAuditActions.OrderReturnApprove : AdminAuditActions.OrderReturnReject,
            orderId,
            approved
                ? $"Approved return for order #{orderId}"
                : $"Rejected return for order #{orderId}",
            new { approved, response },
            cancellationToken);
        return result;
    }

    private async Task ApplyProductTranslationsAsync(
        AdminOrderListItemDto dto,
        Product? product,
        CancellationToken cancellationToken)
    {
        if (product is null)
        {
            return;
        }

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            [product.ProductId],
            cancellationToken);
        translations.TryGetValue(product.ProductId, out var tr);
        AdminProductTextHelper.ApplyToOrderDto(
            dto,
            tr,
            product.NameEn,
            product.DescriptionEn,
            product.ShippingDescriptionEn);
    }

    private async Task ApplyProductTranslationsAsync(
        IReadOnlyList<AdminOrderListItemDto> items,
        IReadOnlyList<Order> orders,
        CancellationToken cancellationToken)
    {
        var productIds = orders
            .Where(o => o.Product != null)
            .Select(o => o.Product!.ProductId)
            .Distinct()
            .ToList();
        if (productIds.Count == 0)
        {
            return;
        }

        var translations = await contentTranslationService.GetProductTranslationsAsync(
            productIds,
            cancellationToken);
        var productByOrderId = orders.ToDictionary(o => o.Id, o => o.Product);

        foreach (var dto in items)
        {
            if (!productByOrderId.TryGetValue(dto.Id, out var product) || product is null)
            {
                continue;
            }

            translations.TryGetValue(product.ProductId, out var tr);
            AdminProductTextHelper.ApplyToOrderDto(
                dto,
                tr,
                product.NameEn,
                product.DescriptionEn,
                product.ShippingDescriptionEn);
        }
    }

    private async Task ApplyUserTranslationsAsync(
        IReadOnlyList<AdminOrderListItemDto> items,
        CancellationToken cancellationToken)
    {
        var userIds = items
            .SelectMany(i => new[] { i.CustomerUserId, i.SupplierUserId })
            .Where(id => id.HasValue)
            .Select(id => id!.Value)
            .Distinct()
            .ToList();
        if (userIds.Count == 0)
        {
            return;
        }

        var translations = await contentTranslationService.GetUserTranslationsAsync(
            userIds,
            cancellationToken);

        foreach (var dto in items)
        {
            if (dto.CustomerUserId is Guid customerId
                && translations.TryGetValue(customerId, out var customerTr))
            {
                AdminUserTextHelper.ApplyCustomerNames(dto, customerTr);
            }

            if (dto.SupplierUserId is Guid supplierId
                && translations.TryGetValue(supplierId, out var supplierTr))
            {
                AdminUserTextHelper.ApplySupplierNames(dto, supplierTr);
            }
        }
    }

    private async Task WriteOrderAuditAsync(
        string action,
        long orderId,
        string summary,
        object? details,
        CancellationToken cancellationToken)
    {
        await auditLogAppService.WriteAsync(
            action,
            AdminAuditEntityTypes.Order,
            orderId.ToString(),
            summary,
            details,
            cancellationToken);
    }
}
