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
    public async Task<object> RequestOrderReturnAsync(
        RequestOrderReturnInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var reason = input.Reason?.Trim() ?? string.Empty;
        if (reason.Length < 3)
        {
            throw new ArgumentException("Return reason is required.");
        }

        var order = await orderData.GetOrderWithProductForReturnAsync(input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (order.FromUserId != userId)
        {
            throw new UnauthorizedAccessException("Only the buyer can request a return.");
        }

        if (!ProductTypeCodes.IsRetailOrder(order))
        {
            throw new InvalidOperationException("Returns are only available for retail orders.");
        }

        if (order.StatusId is not (OrderStatusCodes.Delivered or OrderStatusCodes.Received))
        {
            throw new InvalidOperationException("Returns are only allowed after delivery.");
        }

        if (order.StatusId == OrderStatusCodes.ReturnRequested)
        {
            throw new InvalidOperationException("A return request already exists for this order.");
        }

        var mediaPaths = await SaveReturnMediaAsync(
            order.Id,
            input.MediaFiles,
            input.WebRootPath,
            cancellationToken);

        order.StatusId = OrderStatusCodes.ReturnRequested;
        order.ReturnReason = reason.Length > 2000 ? reason[..2000] : reason;
        order.ReturnMediaPathsJson = mediaPaths.Count == 0
            ? null
            : System.Text.Json.JsonSerializer.Serialize(mediaPaths);
        order.ReturnRequestedAtUtc = DateTime.UtcNow;
        order.ReturnAdminResponse = null;
        order.ReturnRespondedAtUtc = null;
        // Overwrite "Received"/custom labels so admin UI shows Return requested.
        RequestOfferStatusLabels.ApplyReturnRequested(order, order.FromUserId);

        await orderData.SaveChangesAsync(cancellationToken);

        await NotifyReturnRequestedPartiesAsync(order, cancellationToken);
        try
        {
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        }
        catch
        {
            // Counts are best-effort.
        }

        var detail = await GetOrderByIdAsync(input.UserId, order.Id, cancellationToken);
        return detail;
    }

    public async Task<object> RespondToOrderReturnAsync(
        RespondToOrderReturnInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.AdminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        var response = input.Response?.Trim() ?? string.Empty;
        if (!input.Approved && response.Length < 2)
        {
            throw new ArgumentException("Response is required when rejecting a return.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var order = await orderData.GetOrderWithProductForReturnResponseAsync(input.OrderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (order.StatusId != OrderStatusCodes.ReturnRequested)
        {
            throw new InvalidOperationException("This order has no pending return request.");
        }

        var defaultApproveNote = order.PaymentMethod == (byte)PaymentMethod.Online
            ? "Return approved. Online refund can be processed from the admin dashboard when ready."
            : "Return approved. This order was cash on delivery — payment was collected on delivery.";

        var finalResponse = response.Length >= 2
            ? response
            : defaultApproveNote;

        order.ReturnAdminResponse = finalResponse.Length > 2000 ? finalResponse[..2000] : finalResponse;
        order.ReturnRespondedAtUtc = DateTime.UtcNow;

        if (input.Approved)
        {
            order.StatusId = OrderStatusCodes.ReturnApproved;
            RequestOfferStatusLabels.ApplyReturnApproved(order, adminId);
            RestoreStockOnReturnApproved(order);
        }
        else
        {
            // Reject: restore delivered/received workflow label.
            order.StatusId = OrderStatusCodes.Delivered;
            RequestOfferStatusLabels.ApplyDelivered(order, adminId);
        }

        await orderData.SaveChangesAsync(cancellationToken);

        var orderForNotify = await orderData.GetOrderWithProductAsNoTrackingAsync(order.Id, cancellationToken)
            ?? order;

        if (input.Approved)
        {
            await NotifyReturnApprovedAsync(orderForNotify, adminId, cancellationToken);
        }
        else
        {
            await NotifyBuyerReturnRejectedAsync(orderForNotify, adminId, cancellationToken);
        }

        try
        {
            await adminRealtimeNotificationService.BroadcastCountsAsync(cancellationToken);
        }
        catch
        {
            // Counts are best-effort.
        }

        return await GetOrderByIdAsync(input.AdminUserId, order.Id, cancellationToken);
    }

    public async Task<object> ApproveRequestOfferForAdminAsync(
        string adminUserId,
        long orderId,
        decimal? adminUnitPrice = null,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(adminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var order = await orderData.GetOrderWithListDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        // Cart / pure retail is seller-first. Category hybrids (ProductTypeId=Retail + CategoryId)
        // can still require admin moderation when notes/media are present.
        if (ProductTypeCodes.IsRetailOrder(order)
            && !ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(order.Product))
        {
            throw new InvalidOperationException(
                "Retail orders are accepted by the seller first. Admin updates Shipping/Delivered after seller approval.");
        }

        EnsurePendingAdminModerationReview(order);

        if (adminUnitPrice is > 0 && ProductTypeCodes.IsRequests(order.Product?.ProductTypeId))
        {
            UpsertAdminAdvertiserPrice(order, adminId, adminUnitPrice.Value, adminTotalPrice);
        }

        order.IsAdminApproved = true;
        order.StatusId = OrderStatusCodes.AwaitingSellerApproval;
        if (ProductTypeCodes.IsRequests(order.Product?.ProductTypeId))
        {
            RequestOfferStatusLabels.ApplyAwaitingAdvertiser(order);
        }
        else
        {
            // Offers, Booking, Category (e.g. coffee), and other moderated types.
            RequestOfferStatusLabels.ApplyAwaitingSeller(order);
        }

        await orderData.SaveChangesAsync(cancellationToken);
        ProductsAppService.InvalidateListingCaches();

        await NotifyAdvertiserOfAdminApprovedOrderAsync(order, cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

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
    }

    public async Task<object> SetRequestOfferAdvertiserPriceAsync(
        string adminUserId,
        long orderId,
        decimal adminUnitPrice,
        decimal? adminTotalPrice = null,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(adminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var order = await orderData.GetOrderWithListDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (!ProductTypeCodes.IsRequests(order.Product?.ProductTypeId))
        {
            throw new InvalidOperationException("Advertiser price can only be set on request offers.");
        }

        UpsertAdminAdvertiserPrice(order, adminId, adminUnitPrice, adminTotalPrice);
        await orderData.SaveChangesAsync(cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

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
    }

    private static void UpsertAdminAdvertiserPrice(
        Order order,
        Guid adminId,
        decimal adminUnitPrice,
        decimal? adminTotalPrice)
    {
        var qty = order.Quantity <= 0 ? 1m : order.Quantity;
        var unit = decimal.Round(adminUnitPrice, 2, MidpointRounding.AwayFromZero);
        if (unit <= 0)
        {
            throw new ArgumentException("Admin unit price must be greater than zero.");
        }

        var total = adminTotalPrice is > 0
            ? decimal.Round(adminTotalPrice.Value, 2, MidpointRounding.AwayFromZero)
            : decimal.Round(unit * qty, 2, MidpointRounding.AwayFromZero);

        if (order.AdminOfferPrice is null)
        {
            order.AdminOfferPrice = new OrderAdminOfferPrice
            {
                OrderId = order.Id,
                AdminUnitPrice = unit,
                AdminTotalPrice = total,
                UpdatedAtUtc = DateTime.UtcNow,
                UpdatedByAdminUserId = adminId,
            };
        }
        else
        {
            order.AdminOfferPrice.AdminUnitPrice = unit;
            order.AdminOfferPrice.AdminTotalPrice = total;
            order.AdminOfferPrice.UpdatedAtUtc = DateTime.UtcNow;
            order.AdminOfferPrice.UpdatedByAdminUserId = adminId;
        }
    }

    public async Task<object> RejectRequestOfferForAdminAsync(
        string adminUserId,
        long orderId,
        string? reasonEn = null,
        string? reasonAr = null,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(adminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var order = await orderData.GetOrderWithListDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (ProductTypeCodes.IsRetailOrder(order)
            && !ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(order.Product))
        {
            throw new InvalidOperationException(
                "Retail orders are rejected by the seller. Use status update to cancel if needed.");
        }

        EnsurePendingAdminModerationReview(order);

        order.StatusId = OrderStatusCodes.Cancelled;
        RequestOfferStatusLabels.ApplyRejectedByAdmin(order);

        var trimmedEn = reasonEn?.Trim();
        var trimmedAr = reasonAr?.Trim();
        if (!string.IsNullOrWhiteSpace(trimmedEn) || !string.IsNullOrWhiteSpace(trimmedAr))
        {
            var reasonBlock = string.Join(
                "\n",
                new[] { trimmedEn, trimmedAr }.Where(x => !string.IsNullOrWhiteSpace(x)));
            order.Notes = string.IsNullOrWhiteSpace(order.Notes)
                ? reasonBlock
                : $"{order.Notes}\n---\n{reasonBlock}";
        }

        await orderData.SaveChangesAsync(cancellationToken);

        // Notify buyer for all moderated order types (Requests offers + Booking/Category/Offers).
        await NotifyOfferRejectedByAdminAsync(
            order,
            adminId,
            trimmedEn,
            trimmedAr,
            cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

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
    }

    /// <summary>
    /// Admin free-text bilingual status for Requests and Offers (after seller/advertiser acceptance).
    /// Notifies buyer and seller using each user's PreferredLanguage.
    /// </summary>
    public async Task<object> SetCustomOrderStatusAsync(
        string adminUserId,
        long orderId,
        string statusNameEn,
        string statusNameAr,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(adminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var nameEn = statusNameEn?.Trim() ?? string.Empty;
        var nameAr = statusNameAr?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(nameEn) && string.IsNullOrWhiteSpace(nameAr))
        {
            throw new ArgumentException("At least one of statusNameEn or statusNameAr is required.");
        }

        var source = !string.IsNullOrWhiteSpace(nameEn) ? nameEn : nameAr;
        var openAi = serviceProvider.GetService<IOpenAiVisionService>();
        if (openAi is not null)
        {
            var bilingual = await openAi.EnsureBilingualStatusNameAsync(source, cancellationToken);
            nameEn = bilingual.NameEn;
            nameAr = bilingual.NameAr;
        }
        else
        {
            nameEn = source;
            nameAr = source;
        }

        if (nameEn.Length > 200 || nameAr.Length > 200)
        {
            throw new ArgumentException("Status names must be at most 200 characters.");
        }

        var order = await orderData.GetOrderWithDetailDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (!ProductTypeCodes.UsesAdminCustomStatus(order.Product))
        {
            throw new InvalidOperationException(
                "Custom status updates are only allowed for catalog order types (Retail, Booking, Offers, Requests, Categories).");
        }

        if (!order.IsApproved || order.StatusId == OrderStatusCodes.Cancelled)
        {
            throw new InvalidOperationException(
                "Custom status can only be set after the seller/advertiser accepts the order.");
        }

        if (RequestOfferStatusLabels.IsFulfillmentComplete(order.StatusId)
            || order.StatusId == OrderStatusCodes.ReturnRequested)
        {
            throw new InvalidOperationException(
                "Custom status cannot be set after the order is completed or a return was requested.");
        }

        RequestOfferStatusLabels.Apply(order, nameEn, nameAr, adminId);
        await orderData.SaveChangesAsync(cancellationToken);

        await NotifyBuyerOrderStatusAsync(order, adminId, cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

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
    }

    /// <summary>
    /// Final fulfillment step: sets StatusId to Delivered and bilingual label Received / تم الاستلام.
    /// Enables retail return requests afterward.
    /// </summary>
    public async Task<object> MarkOrderReceivedAsync(
        string adminUserId,
        long orderId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(adminUserId, out var adminId))
        {
            throw new ArgumentException("Invalid admin user id.");
        }

        _ = await orderData.GetUserByIdAsNoTrackingAsync(adminId, cancellationToken)
            ?? throw new KeyNotFoundException("Admin user not found.");

        var order = await orderData.GetOrderWithDetailDetailsAsync(orderId, cancellationToken)
            ?? throw new KeyNotFoundException("Order not found.");

        if (!ProductTypeCodes.UsesAdminCustomStatus(order.Product))
        {
            throw new InvalidOperationException(
                "Mark received is only allowed for catalog order types.");
        }

        if (!order.IsApproved)
        {
            throw new InvalidOperationException(
                "Order must be accepted by the seller before it can be marked received.");
        }

        if (RequestOfferStatusLabels.IsFulfillmentComplete(order.StatusId)
            || order.StatusId == OrderStatusCodes.ReturnRequested)
        {
            throw new InvalidOperationException("Order is already completed or in return flow.");
        }

        // Delivered (5) is the canonical terminal status (legacy Received/7 is collapsed to 5).
        order.StatusId = OrderStatusCodes.Delivered;
        RequestOfferStatusLabels.ApplyReceived(order, adminId);
        await orderData.SaveChangesAsync(cancellationToken);

        await NotifyBuyerOrderStatusAsync(order, adminId, cancellationToken);

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var categoryCommissions = await categoryCommissionProvider.GetAsync(cancellationToken);
        var usdToAedRate = AdminOrderPricingHelper.GetUsdToAedRate(configuration);

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
    }


    private static void EnsurePendingAdminModerationReview(Order order)
    {
        if (!ProductTypeCodes.RequiresAdminModerationBeforeSellerApproval(order.Product))
        {
            throw new InvalidOperationException("This order does not require admin moderation.");
        }

        if (order.IsAdminApproved)
        {
            throw new InvalidOperationException("This order was already approved by admin.");
        }

        if (order.StatusId != OrderStatusCodes.Ordered)
        {
            throw new InvalidOperationException("Only pending orders can be reviewed by admin.");
        }
    }

    private static void EnsurePendingRetailAdminReview(Order order)
    {
        if (!ProductTypeCodes.IsRetailOrder(order))
        {
            throw new InvalidOperationException("This order is not a retail order.");
        }

        if (order.IsAdminApproved)
        {
            throw new InvalidOperationException("This order was already approved by admin.");
        }

        if (order.StatusId is not (OrderStatusCodes.Ordered or OrderStatusCodes.Paid))
        {
            throw new InvalidOperationException("Only pending retail orders can be reviewed by admin.");
        }

        if (order.StockQuantityDeducted)
        {
            throw new InvalidOperationException("Stock was already deducted for this order.");
        }
    }

    private void ApplyAdminFinalApprovalForRetailOrder(Order order, byte previousStatus)
    {
        order.IsApproved = true;
        TryDeductStockOnOrderApproval(order);
        order.StatusId = previousStatus == OrderStatusCodes.Paid
            ? OrderStatusCodes.Paid
            : OrderStatusCodes.Approved;
    }

    private static void EnsurePendingRequestOfferForAdminReview(Order order) =>
        EnsurePendingAdminModerationReview(order);


    private async Task<int> CountPendingSellerActionsForProductAsync(
        Guid productId,
        byte? productTypeId,
        CancellationToken cancellationToken)
    {
        return await orderData.CountPendingSellerActionsAsync(productId, cancellationToken);
    }

    private async Task<List<string>> SaveReturnMediaAsync(
        long orderId,
        List<Microsoft.AspNetCore.Http.IFormFile> files,
        string webRootPath,
        CancellationToken cancellationToken)
    {
        _ = webRootPath;
        var paths = new List<string>();
        if (files is null || files.Count == 0)
        {
            return paths;
        }

        var folder = $"order-returns/{orderId}";
        var allowedImages = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var allowedVideos = new[] { ".mp4", ".mov", ".webm" };

        foreach (var file in files.Where(f => f is { Length: > 0 }).Take(5))
        {
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedImages.Contains(extension) && !allowedVideos.Contains(extension))
            {
                continue;
            }

            var fileName = $"{Guid.NewGuid():N}{extension}";
            paths.Add(await mediaStorage.SaveFormFileAsync(
                file,
                folder,
                fileName,
                cancellationToken: cancellationToken));
        }

        return paths;
    }

}
