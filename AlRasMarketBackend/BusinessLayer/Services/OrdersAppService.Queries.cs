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
    public async Task<object> GetMyOrdersAsync(
        string userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var (orders, totalCount) = await orderData.GetMyOrdersPageAsync(
            parsedUserId,
            page,
            pageSize,
            statusId,
            search,
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

        await ApplyOrderProductTranslationsAsync(items, cancellationToken);

        return new AdminPagedResult<AdminOrderListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    /// <summary>
    /// Offers this user submitted on Request ads (moved out of My Orders into Account → My Offers).
    /// </summary>
    public async Task<object> GetMyOffersAsync(
        string userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var (orders, totalCount) = await orderData.GetMyOffersPageAsync(
            parsedUserId,
            page,
            pageSize,
            statusId,
            search,
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
            // Submitter sees their offered price only — no app commission markup.
            AdminOrderPricingHelper.ApplySupplierFacingOfferDisplay(dto, order, order.Product);
            return dto;
        }).ToList();

        await ApplyOrderProductTranslationsAsync(items, cancellationToken);

        return new AdminPagedResult<AdminOrderListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<object> GetOrderByIdAsync(string userId, long orderId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var order = await orderData.GetOrderWithDetailDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        await EnsureUserCanAccessOrderAsync(parsedUserId, order, cancellationToken);

        var dto = AdminOrderMapper.Map(order);
        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);
        AdminOrderPricingHelper.ApplyPricingFields(
            dto,
            order,
            order.Product,
            commissionSettings,
            categoryCommissions,
            usdToAedRate);
        // Offer submitter viewing their own Request offer: raw submitted price.
        if (order.Product?.ProductTypeId == ProductTypeCodes.Requests
            && order.FromUserId == parsedUserId)
        {
            AdminOrderPricingHelper.ApplySupplierFacingOfferDisplay(dto, order, order.Product);
        }
        else
        {
            AdminOrderPricingHelper.ApplyChargedCheckoutAmounts(dto, order);
        }

        await ApplyOrderProductTranslationsAsync([dto], cancellationToken);
        return dto;
    }

    public async Task<object> GetOffersForRequestAsync(
        string userId,
        string productId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(productId) || !Guid.TryParse(productId, out var parsedProductId))
        {
            throw new ArgumentException("Invalid product id.");
        }

        var product = await orderData.GetProductAsNoTrackingAsync(parsedProductId, cancellationToken)
            ?? throw new KeyNotFoundException("Product not found.");

        if (product.ProductTypeId != ProductTypeCodes.Requests)
        {
            throw new InvalidOperationException("Offers can only be listed for request products.");
        }

        await EnsureUserCanViewRequestOffersAsync(parsedUserId, product, cancellationToken);

        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        var viewer = await orderData.GetUserByIdAsNoTrackingAsync(parsedUserId, cancellationToken);
        var isAdminViewer = viewer?.RoleId == 1;

        var (orders, totalCount) = await orderData.GetOffersForRequestPageAsync(
            parsedProductId,
            isAdminViewer,
            page,
            pageSize,
            statusId,
            search,
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
            // Request owner / admin listing: customer-facing price with app commission.
            AdminOrderPricingHelper.ApplyChargedCheckoutAmounts(dto, order);
            return dto;
        }).ToList();

        return new AdminPagedResult<AdminOrderListItemDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

    public async Task<object> GetMyOffersOnMyRequestsAsync(
        string userId,
        int page,
        int pageSize,
        string? productId,
        byte? statusId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 100 ? 20 : pageSize;

        Guid? parsedProductId = null;
        if (!string.IsNullOrWhiteSpace(productId))
        {
            if (!Guid.TryParse(productId, out var productFilterId))
            {
                throw new ArgumentException("Invalid product id.");
            }

            parsedProductId = productFilterId;
        }

        var (orders, totalCount) = await orderData.GetMyOffersOnMyRequestsPageAsync(
            parsedUserId,
            page,
            pageSize,
            parsedProductId,
            statusId,
            cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);

        var items = orders
            .Select(order => RequestOfferMapper.Map(
                order,
                order.Product ?? throw new InvalidOperationException("Order product is missing."),
                commissionSettings,
                categoryCommissions,
                parsedUserId))
            .ToList();

        return new AdminPagedResult<MyRequestOfferDto>
        {
            Page = page,
            PageSize = pageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize),
            Items = items
        };
    }

}
