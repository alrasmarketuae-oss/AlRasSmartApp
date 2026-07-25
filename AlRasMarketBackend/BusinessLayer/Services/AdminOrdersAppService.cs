using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace BusinessLayer.Services;

public class AdminOrdersAppService(
    IRasAlSouqDbContext dbContext,
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
        var utcNow = DateTime.UtcNow;
        var monthStart = new DateTime(utcNow.Year, utcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var prevMonthStart = monthStart.AddMonths(-1);

        var visibleOrders = AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(dbContext.Orders);

        var totalOrders = await visibleOrders.CountAsync(cancellationToken);
        var ordersThisMonth = await visibleOrders.CountAsync(x => x.CreatedAt >= monthStart, cancellationToken);
        var ordersLastMonth = await visibleOrders.CountAsync(
            x => x.CreatedAt >= prevMonthStart && x.CreatedAt < monthStart,
            cancellationToken);

        return new AdminOrderStatsDto
        {
            TotalOrders = totalOrders,
            TotalOrdersChangePercent = AdminMappings.PercentChange(ordersThisMonth, ordersLastMonth),
            OrderedCount = await visibleOrders.CountAsync(x => x.StatusId == OrderStatusCodes.Ordered, cancellationToken),
            ShippingCount = await visibleOrders.CountAsync(x => x.StatusId == OrderStatusCodes.Shipping, cancellationToken),
            DeliveredCount = await visibleOrders.CountAsync(x => x.StatusId == OrderStatusCodes.Delivered, cancellationToken),
        };
    }

    public async Task<AdminOrderListItemDto> GetOrderByIdAsync(long orderId, CancellationToken cancellationToken = default)
    {
        var order = await AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(
                AdminOrderMapper.WithAdminDetailDetails(dbContext.Orders))
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

        var dto = AdminOrderMapper.Map(order);
        await ApplyProductTranslationsAsync(dto, order.Product, cancellationToken);
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

        var pendingPayment = await dbContext.PendingPayments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);
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

        var query = AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(
            dbContext.Orders.AsNoTracking());

        if (statusId.HasValue)
        {
            query = query.Where(x => x.StatusId == statusId.Value);
        }

        query = ApplyOrderChannelFilter(query, orderChannel);

        if (productTypeId.HasValue)
        {
            query = query.Where(x => x.Product != null && x.Product.ProductTypeId == productTypeId.Value);
        }

        if (excludeProductTypeId.HasValue)
        {
            query = query.Where(x => x.Product == null || x.Product.ProductTypeId != excludeProductTypeId.Value);
        }

        if (!string.IsNullOrWhiteSpace(productId) && Guid.TryParse(productId.Trim(), out var parsedProductId))
        {
            query = query.Where(x => x.ProductId == parsedProductId);
        }

        var review = (offerReview ?? string.Empty).Trim().ToLowerInvariant();
        query = review switch
        {
            "awaitingadmin" or "new" or "pendingadmin" => query.Where(x =>
                !x.IsAdminApproved
                && x.StatusId == OrderStatusCodes.Ordered
                && x.Product != null
                && x.Product.ProductTypeId == ProductTypeCodes.Requests),
            "awaitingseller" or "pendingseller" => query.Where(x =>
                x.IsAdminApproved
                && !x.IsApproved
                && x.StatusId == OrderStatusCodes.AwaitingSellerApproval
                && x.Product != null
                && x.Product.ProductTypeId == ProductTypeCodes.Requests),
            "sellerapproved" or "accepted" => query.Where(x =>
                x.IsApproved
                && x.StatusId != OrderStatusCodes.Cancelled
                && x.Product != null
                && x.Product.ProductTypeId == ProductTypeCodes.Requests),
            _ => query
        };

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

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLowerInvariant();
            if (long.TryParse(term, out var orderId))
            {
                query = query.Where(x => x.Id == orderId);
            }
            else
            {
                query = query.Where(x =>
                    (x.FromUser != null && x.FromUser.FullName.ToLower().Contains(term)) ||
                    (x.FromUser != null && x.FromUser.Email.ToLower().Contains(term)) ||
                    (x.ToUser != null && x.ToUser.FullName.ToLower().Contains(term)) ||
                    (x.ToUser != null && x.ToUser.Email.ToLower().Contains(term)) ||
                    (x.Product != null && x.Product.NameEn != null && x.Product.NameEn.ToLower().Contains(term)) ||
                    (x.Product != null && dbContext.ContentTranslations.Any(t =>
                        t.ProductId == x.ProductId
                        && t.Scope == ContentTranslationScopes.Product
                        && t.Field == ContentTranslationFields.Name
                        && ((t.TextEn != null && t.TextEn.ToLower().Contains(term))
                            || (t.TextAr != null && t.TextAr.ToLower().Contains(term))))) ||
                    (x.Notes != null && x.Notes.ToLower().Contains(term)));
            }
        }

        var totalCount = await query.CountAsync(cancellationToken);

        // Page IDs first (no collection Includes) so newest orders stay on top.
        // Including images/videos before Skip/Take can scramble order via cartesian joins.
        var orderIds = await query
            .OrderByDescending(x => x.CreatedAt)
            .ThenByDescending(x => x.Id)
            .Select(x => x.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        List<Order> orders;
        if (orderIds.Count == 0)
        {
            orders = [];
        }
        else
        {
            var loaded = await AdminOrderMapper.WithAdminListDetails(dbContext.Orders.AsNoTracking())
                .AsSplitQuery()
                .Where(x => orderIds.Contains(x.Id))
                .ToListAsync(cancellationToken);

            var orderIndex = orderIds
                .Select((id, index) => (id, index))
                .ToDictionary(x => x.id, x => x.index);

            orders = loaded
                .OrderBy(x => orderIndex[x.Id])
                .ToList();
        }

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
        CancellationToken cancellationToken = default)
    {
        var result = await _ordersAppService.ApproveRequestOfferForAdminAsync(
            adminUserId,
            orderId,
            cancellationToken);

        await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        await WriteOrderAuditAsync(
            AdminAuditActions.OrderApproveOffer,
            orderId,
            $"Approved order #{orderId} for seller review",
            null,
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
            cancellationToken);

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

    /// <summary>
    /// Splits catalog orders into sidebar pages: retail / booking / offers / categories.
    /// </summary>
    private static IQueryable<Order> ApplyOrderChannelFilter(IQueryable<Order> query, string? orderChannel)
    {
        var channel = (orderChannel ?? string.Empty).Trim().ToLowerInvariant();
        return channel switch
        {
            "retail" => query.Where(x =>
                x.Product != null
                && (x.IsRetailPurchase
                    || (x.Product.ProductTypeId == ProductTypeCodes.Retail
                        && (x.Product.CategoryId == null || x.Product.CategoryId == 0)))),
            "categories" or "category" or "wholesale" => query.Where(x =>
                x.Product != null
                && x.Product.CategoryId != null
                && x.Product.CategoryId > 0
                && !x.IsRetailPurchase
                && (x.Product.ProductTypeId == null
                    || x.Product.ProductTypeId == ProductTypeCodes.Retail)),
            "booking" => query.Where(x =>
                x.Product != null && x.Product.ProductTypeId == ProductTypeCodes.Booking),
            "offers" or "offer" => query.Where(x =>
                x.Product != null && x.Product.ProductTypeId == ProductTypeCodes.Offers),
            _ => query
        };
    }
}
