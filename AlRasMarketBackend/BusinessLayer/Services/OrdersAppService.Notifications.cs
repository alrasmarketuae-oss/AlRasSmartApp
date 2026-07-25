using BusinessLayer.Caching;
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
    private async Task NotifyOrderPartiesAsync(IReadOnlyList<Order> orders, CancellationToken cancellationToken)
    {
        if (orders.Count == 0)
        {
            return;
        }

        var productIds = orders.Select(x => x.ProductId).Distinct().ToList();
        var productMeta = await dbContext.Products
            .AsNoTracking()
            .Where(x => productIds.Contains(x.ProductId))
            .Select(x => new { x.ProductId, x.NameEn, x.ProductTypeId, x.CategoryId, x.OwnerId })
            .ToListAsync(cancellationToken);

        var productNames = productMeta.ToDictionary(x => x.ProductId, x => x.NameEn);
        var productTypes = productMeta.ToDictionary(x => x.ProductId, x => x.ProductTypeId);
        var productCategories = productMeta.ToDictionary(x => x.ProductId, x => x.CategoryId);
        var productOwners = productMeta.ToDictionary(x => x.ProductId, x => x.OwnerId);

        var sellerIds = orders
            .Select(o => productOwners.TryGetValue(o.ProductId, out var ownerId) && ownerId.HasValue
                ? ownerId.Value
                : o.ToUserId)
            .Distinct()
            .ToList();
        var sellers = await dbContext.Users
            .AsNoTracking()
            .Where(x => sellerIds.Contains(x.Id))
            .Select(x => new { x.Id, x.Email, x.FcmToken, x.PreferredLanguage })
            .ToListAsync(cancellationToken);

        var admins = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1 && x.FcmToken != null && x.FcmToken != "")
            .Select(x => new { x.FcmToken, x.PreferredLanguage })
            .ToListAsync(cancellationToken);

        var orderGroupId = orders.First().OrderGroupId?.ToString() ?? orders.First().Id.ToString();
        var buyerId = orders.First().FromUserId;
        var buyer = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == buyerId, cancellationToken);

        if (buyer is not null)
        {
            foreach (var order in orders)
            {
                try
                {
                    await SendUserAlertAsync(
                        toUserId: buyer.Id,
                        fromUserId: order.ToUserId,
                        email: buyer.Email,
                        fcmToken: buyer.FcmToken,
                        messageFactory: lang => NotificationMessages.OrderPlacedBuyer(lang, order.Id),
                        preferredLanguage: buyer.PreferredLanguage,
                        type: "order_placed",
                        routeName: "track_order",
                        referenceId: order.Id.ToString(),
                        cancellationToken: cancellationToken);
                }
                catch
                {
                    // Notification failure must not roll back paid orders.
                }
            }
        }

        var hasVisibleOrdersForAdmin = orders.Any(order =>
        {
            productTypes.TryGetValue(order.ProductId, out var productTypeId);
            if (productTypeId != ProductTypeCodes.Requests)
            {
                return true;
            }

            return !order.IsAdminApproved;
        });

        if (hasVisibleOrdersForAdmin)
        {
            var sampleOrder = orders.FirstOrDefault(order =>
            {
                productTypes.TryGetValue(order.ProductId, out var productTypeId);
                return productTypeId != ProductTypeCodes.Requests || !order.IsAdminApproved;
            }) ?? orders.First();
            productNames.TryGetValue(sampleOrder.ProductId, out var sampleProductName);
            var sampleQty = FormatAdminOrderQuantityLabel(sampleOrder);
            var sampleDetails = TruncateAdminAlertText(sampleOrder.Notes);
            if (orders.Count > 1)
            {
                var extra = $"+{orders.Count - 1} more";
                sampleDetails = string.IsNullOrWhiteSpace(sampleDetails)
                    ? extra
                    : $"{sampleDetails} · {extra}";
            }

            foreach (var admin in admins.GroupBy(x => x.FcmToken!).Select(g => g.First()))
            {
                var (title, body) = NotificationMessages.NewOrderAdmin(
                    admin.PreferredLanguage,
                    sampleOrder.Id,
                    sampleProductName ?? string.Empty,
                    sampleQty,
                    sampleDetails);
                try
                {
                    await fcmNotificationService.SendNotificationAsync(
                        admin.FcmToken!,
                        new FcmNotificationPayload
                        {
                            Title = title,
                            Body = body,
                            Type = "order_created",
                            RouteId = "orders",
                            ReferenceId = orderGroupId
                        },
                        cancellationToken);
                }
                catch
                {
                    // Notification failure must not roll back paid orders.
                }
            }
        }

        foreach (var order in orders)
        {
            productTypes.TryGetValue(order.ProductId, out var productTypeId);
            productCategories.TryGetValue(order.ProductId, out var categoryId);

            if (ProductTypeCodes.UsesSpecOrMediaAdminGate(productTypeId, categoryId) && !order.IsAdminApproved)
            {
                continue;
            }

            // Seller-first (Retail/Category) or admin-approved gated orders: alert the seller now.
            if (!ProductTypeCodes.StartsWithSellerApproval(productTypeId, categoryId) && !order.IsAdminApproved)
            {
                continue;
            }

            var sellerId = productOwners.TryGetValue(order.ProductId, out var ownerId) && ownerId.HasValue
                ? ownerId.Value
                : order.ToUserId;
            var seller = sellers.FirstOrDefault(x => x.Id == sellerId);
            if (seller is null)
            {
                continue;
            }

            var productName = productNames.TryGetValue(order.ProductId, out var name) && !string.IsNullOrWhiteSpace(name)
                ? name.Trim()
                : string.Empty;

            var isRequestOffer = productTypeId == ProductTypeCodes.Requests;

            var pendingCount = await CountPendingSellerActionsForProductAsync(
                order.ProductId,
                productTypeId,
                cancellationToken);

            try
            {
                await SendUserAlertAsync(
                    toUserId: seller.Id,
                    fromUserId: order.FromUserId,
                    email: seller.Email,
                    fcmToken: seller.FcmToken,
                    messageFactory: lang => isRequestOffer
                        ? NotificationMessages.NewOfferOnRequest(lang, productName, pendingCount)
                        : NotificationMessages.NewProductOrderSeller(lang, productName, pendingCount),
                    preferredLanguage: seller.PreferredLanguage,
                    type: isRequestOffer ? "request_offer" : "new_order",
                    routeName: "my_ads",
                    referenceId: order.ProductId.ToString(),
                    notificationTypeName: isRequestOffer ? "request_offer" : "order",
                    fcmData: new Dictionary<string, string>
                    {
                        ["offerCount"] = pendingCount.ToString(),
                        ["productId"] = order.ProductId.ToString(),
                        ["orderId"] = order.Id.ToString(),
                        ["highlightProductId"] = order.ProductId.ToString(),
                    },
                    cancellationToken: cancellationToken);
            }
            catch
            {
                // Notification failure must not roll back paid orders.
            }
        }

        foreach (var order in orders)
        {
            try
            {
                await adminRealtimeNotificationService.NotifyNewOrderAsync(order, cancellationToken);
            }
            catch
            {
                // Realtime notification failure must not roll back orders.
            }
        }
    }

    private async Task PublishOrderRealtimeAsync(Order order, CancellationToken cancellationToken)
    {
        try
        {
            await orderRealtimeNotificationService.NotifyOrderUpdatedAsync(
                order.Id,
                order.StatusId,
                RequestOfferStatusLabels.ResolveNameEn(order),
                RequestOfferStatusLabels.ResolveNameAr(order),
                cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Order realtime publish failed for order {OrderId}", order.Id);
        }
    }

    private async Task NotifyBuyerOrderStatusAsync(
        Order order,
        Guid fromUserId,
        CancellationToken cancellationToken)
    {
        var buyer = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.FromUserId, cancellationToken);

        if (buyer is null)
        {
            return;
        }

        var isSellerAction = fromUserId == order.ToUserId
            || fromUserId == (order.Product?.OwnerId ?? Guid.Empty);
        var statusEn = RequestOfferStatusLabels.ResolveNameEn(order);
        var statusAr = RequestOfferStatusLabels.ResolveNameAr(order);
        var isRequestOffer = order.Product?.ProductTypeId == ProductTypeCodes.Requests;

        try
        {
            await SendUserAlertAsync(
                toUserId: buyer.Id,
                fromUserId: fromUserId,
                email: buyer.Email,
                fcmToken: buyer.FcmToken,
                messageFactory: lang => isSellerAction switch
                {
                    true when order.StatusId == OrderStatusCodes.Approved =>
                        NotificationMessages.OrderAcceptedBySellerBuyer(lang, order.Id),
                    true when order.StatusId == OrderStatusCodes.Cancelled =>
                        NotificationMessages.OrderRejectedBySellerBuyer(lang, order.Id),
                    _ => NotificationMessages.OrderStatusUpdatedBuyer(lang, order.Id, statusEn, statusAr)
                },
                preferredLanguage: buyer.PreferredLanguage,
                type: "order_status_updated",
                routeName: isRequestOffer ? "my_offers" : "track_order",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }
        catch
        {
            // Notification failure must not roll back order updates.
        }

        await PublishOrderRealtimeAsync(order, cancellationToken);
    }

    private async Task NotifyBuyerRefundProcessedAsync(Order order, CancellationToken cancellationToken)
    {
        var buyer = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.FromUserId, cancellationToken);

        if (buyer is null)
        {
            return;
        }

        try
        {
            await SendUserAlertAsync(
                toUserId: buyer.Id,
                fromUserId: order.ToUserId,
                email: buyer.Email,
                fcmToken: buyer.FcmToken,
                messageFactory: lang => NotificationMessages.OrderRefundProcessedBuyer(lang, order.Id),
                preferredLanguage: buyer.PreferredLanguage,
                type: "order_refund_processed",
                routeName: "track_order",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }
        catch
        {
            // Notification failure must not roll back order updates.
        }
    }

    private async Task NotifyAdminOfVisibleOrderAsync(Order order, CancellationToken cancellationToken)
    {
        var admins = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1 && x.FcmToken != null && x.FcmToken != "")
            .Select(x => new { x.FcmToken, x.PreferredLanguage })
            .ToListAsync(cancellationToken);

        var productName = order.Product?.NameEn?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(productName))
        {
            productName = await dbContext.Products
                .AsNoTracking()
                .Where(x => x.ProductId == order.ProductId)
                .Select(x => x.NameEn)
                .FirstOrDefaultAsync(cancellationToken) ?? string.Empty;
        }

        var quantityLabel = FormatAdminOrderQuantityLabel(order);
        var details = TruncateAdminAlertText(order.Notes);

        foreach (var admin in admins.GroupBy(x => x.FcmToken!).Select(g => g.First()))
        {
            var (title, body) = NotificationMessages.NewOrderAdmin(
                admin.PreferredLanguage,
                order.Id,
                productName,
                quantityLabel,
                details);
            try
            {
                await fcmNotificationService.SendNotificationAsync(
                    admin.FcmToken!,
                    new FcmNotificationPayload
                    {
                        Title = title,
                        Body = body,
                        Type = "order_created",
                        RouteId = "orders",
                        ReferenceId = order.Id.ToString()
                    },
                    cancellationToken);
            }
            catch
            {
                // Notification failure must not roll back orders.
            }
        }

        try
        {
            await adminRealtimeNotificationService.NotifyNewOrderAsync(order, cancellationToken);
        }
        catch
        {
            // Realtime notification failure must not roll back orders.
        }
    }

    private static string FormatAdminOrderQuantityLabel(Order order)
    {
        var qty = order.Quantity == decimal.Truncate(order.Quantity)
            ? ((long)order.Quantity).ToString()
            : order.Quantity.ToString("0.##");
        return qty;
    }

    private static string? TruncateAdminAlertText(string? value, int maxLength = 120)
    {
        var trimmed = value?.Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return null;
        }

        return trimmed.Length <= maxLength
            ? trimmed
            : trimmed[..(maxLength - 1)].TrimEnd() + "…";
    }

    private decimal GetUsdToAedRate()
    {
        var configured = configuration["Stripe:UsdToAedRate"];
        return decimal.TryParse(configured, out var rate) && rate > 0 ? rate : 3.6725m;
    }


    private async Task NotifyOrderPartiesCustomStatusAsync(
        Order order,
        Guid fromUserId,
        CancellationToken cancellationToken)
    {
        var statusEn = RequestOfferStatusLabels.ResolveNameEn(order);
        var statusAr = RequestOfferStatusLabels.ResolveNameAr(order);
        var partyIds = new[]
            {
                order.FromUserId,
                order.Product?.OwnerId ?? order.ToUserId
            }
            .Distinct()
            .ToList();

        var parties = await dbContext.Users
            .AsNoTracking()
            .Where(x => partyIds.Contains(x.Id))
            .Select(x => new { x.Id, x.Email, x.FcmToken, x.PreferredLanguage })
            .ToListAsync(cancellationToken);

        foreach (var party in parties)
        {
            try
            {
                var isBuyer = party.Id == order.FromUserId;
                var isRequestOffer = ProductTypeCodes.IsRequests(order.Product?.ProductTypeId);
                var routeName = isBuyer
                    ? (isRequestOffer ? "my_offers" : "track_order")
                    : "my_ads";

                await SendUserAlertAsync(
                    toUserId: party.Id,
                    fromUserId: fromUserId,
                    email: party.Email,
                    fcmToken: party.FcmToken,
                    messageFactory: lang => NotificationMessages.OrderStatusUpdatedBuyer(
                        lang,
                        order.Id,
                        statusEn,
                        statusAr),
                    preferredLanguage: party.PreferredLanguage,
                    type: "order_status_updated",
                    routeName: routeName,
                    referenceId: order.Id.ToString(),
                    cancellationToken: cancellationToken);
            }
            catch
            {
                // Notification failure must not roll back status updates.
            }
        }

        await PublishOrderRealtimeAsync(order, cancellationToken);
    }


    private async Task NotifyRequestOwnerOfApprovedOfferAsync(Order order, CancellationToken cancellationToken)
    {
        await NotifyAdvertiserOfAdminApprovedOrderAsync(order, cancellationToken);
    }

    private async Task NotifyAdvertiserOfAdminApprovedOrderAsync(Order order, CancellationToken cancellationToken)
    {
        var advertiserId = order.Product?.OwnerId ?? order.ToUserId;
        var advertiser = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == advertiserId, cancellationToken);

        if (advertiser is null)
        {
            return;
        }

        var productName = order.Product?.NameEn?.Trim() ?? string.Empty;
        var productTypeId = order.Product?.ProductTypeId;
        var isRequestOffer = productTypeId == ProductTypeCodes.Requests;
        var pendingCount = await CountPendingSellerActionsForProductAsync(
            order.ProductId,
            productTypeId,
            cancellationToken);
        try
        {
            await SendUserAlertAsync(
                toUserId: advertiser.Id,
                fromUserId: order.FromUserId,
                email: advertiser.Email,
                fcmToken: advertiser.FcmToken,
                messageFactory: lang => isRequestOffer
                    ? NotificationMessages.NewOfferOnRequest(lang, productName, pendingCount)
                    : NotificationMessages.NewProductOrderSeller(lang, productName, pendingCount),
                preferredLanguage: advertiser.PreferredLanguage,
                type: isRequestOffer ? "request_offer" : "new_order",
                routeName: "my_ads",
                referenceId: order.ProductId.ToString(),
                notificationTypeName: isRequestOffer ? "request_offer" : "order",
                fcmData: new Dictionary<string, string>
                {
                    ["offerCount"] = pendingCount.ToString(),
                    ["productId"] = order.ProductId.ToString(),
                    ["orderId"] = order.Id.ToString(),
                    ["highlightProductId"] = order.ProductId.ToString(),
                },
                cancellationToken: cancellationToken);
        }
        catch
        {
            // Notification failure must not roll back admin approval.
        }
    }

    private async Task NotifyAdminSellerApprovedOrderAsync(Order order, CancellationToken cancellationToken)
    {
        var admins = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1 && x.FcmToken != null && x.FcmToken != "")
            .Select(x => new { x.FcmToken, x.PreferredLanguage })
            .ToListAsync(cancellationToken);

        var productName = order.Product?.NameEn?.Trim() ?? string.Empty;
        foreach (var admin in admins.GroupBy(x => x.FcmToken!).Select(g => g.First()))
        {
            var (title, body) = NotificationMessages.SellerApprovedOrderAdmin(
                admin.PreferredLanguage,
                order.Id,
                productName);
            try
            {
                await fcmNotificationService.SendNotificationAsync(
                    admin.FcmToken!,
                    new FcmNotificationPayload
                    {
                        Title = title,
                        Body = body,
                        Type = "order_seller_approved",
                        RouteId = "orders",
                        ReferenceId = order.Id.ToString()
                    },
                    cancellationToken);
            }
            catch
            {
                // Notification failure must not roll back order updates.
            }
        }

        try
        {
            await adminRealtimeNotificationService.NotifyNewOrderAsync(order, cancellationToken);
        }
        catch
        {
            // Realtime notification failure must not roll back orders.
        }
    }


    private async Task NotifyReturnRequestedPartiesAsync(Order order, CancellationToken cancellationToken)
    {
        var productName = order.Product?.NameEn ?? "product";

        var admins = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1)
            .Select(x => new { x.Id, x.FcmToken, x.PreferredLanguage, x.Email })
            .ToListAsync(cancellationToken);

        foreach (var admin in admins)
        {
            await SendUserAlertAsync(
                toUserId: admin.Id,
                fromUserId: order.FromUserId,
                email: admin.Email,
                fcmToken: admin.FcmToken,
                messageFactory: lang => NotificationMessages.OrderReturnRequestedAdmin(lang, order.Id),
                preferredLanguage: admin.PreferredLanguage,
                type: "order_return_requested",
                routeName: "orders",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }

        var supplier = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.ToUserId, cancellationToken);
        if (supplier is not null)
        {
            await SendUserAlertAsync(
                toUserId: supplier.Id,
                fromUserId: order.FromUserId,
                email: supplier.Email,
                fcmToken: supplier.FcmToken,
                messageFactory: lang => NotificationMessages.OrderReturnRequestedSupplier(
                    lang,
                    order.Id,
                    productName),
                preferredLanguage: supplier.PreferredLanguage,
                type: "order_return_requested",
                routeName: "orders",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }

        await PublishOrderRealtimeAsync(order, cancellationToken);
    }

    private async Task NotifyReturnApprovedAsync(
        Order order,
        Guid adminUserId,
        CancellationToken cancellationToken)
    {
        var productName = order.Product?.NameEn ?? "product";
        var isOnline = order.PaymentMethod == (byte)PaymentMethod.Online;

        var buyer = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.FromUserId, cancellationToken);
        if (buyer is not null)
        {
            await SendUserAlertAsync(
                toUserId: buyer.Id,
                fromUserId: adminUserId,
                email: buyer.Email,
                fcmToken: buyer.FcmToken,
                messageFactory: lang => isOnline
                    ? NotificationMessages.OrderReturnApprovedOnlineBuyer(lang, order.Id)
                    : NotificationMessages.OrderReturnApprovedCodBuyer(lang, order.Id),
                preferredLanguage: buyer.PreferredLanguage,
                type: "order_return_approved",
                routeName: "track_order",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }

        var supplier = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.ToUserId, cancellationToken);
        if (supplier is not null)
        {
            await SendUserAlertAsync(
                toUserId: supplier.Id,
                fromUserId: adminUserId,
                email: supplier.Email,
                fcmToken: supplier.FcmToken,
                messageFactory: lang => NotificationMessages.OrderReturnApprovedSupplier(
                    lang,
                    order.Id,
                    productName),
                preferredLanguage: supplier.PreferredLanguage,
                type: "order_return_approved",
                routeName: "orders",
                referenceId: order.Id.ToString(),
                cancellationToken: cancellationToken);
        }

        await PublishOrderRealtimeAsync(order, cancellationToken);
    }

    private async Task NotifyBuyerReturnRejectedAsync(
        Order order,
        Guid adminUserId,
        CancellationToken cancellationToken)
    {
        var buyer = await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == order.FromUserId, cancellationToken);
        if (buyer is null)
        {
            return;
        }

        var responseText = order.ReturnAdminResponse ?? string.Empty;

        await SendUserAlertAsync(
            toUserId: buyer.Id,
            fromUserId: adminUserId,
            email: buyer.Email,
            fcmToken: buyer.FcmToken,
            messageFactory: lang => NotificationMessages.OrderReturnRejectedBuyer(
                lang,
                order.Id,
                responseText),
            preferredLanguage: buyer.PreferredLanguage,
            type: "order_return_rejected",
            routeName: "track_order",
            referenceId: order.Id.ToString(),
            cancellationToken: cancellationToken);

        await PublishOrderRealtimeAsync(order, cancellationToken);
    }

    private async Task SendUserAlertAsync(
        Guid toUserId,
        Guid fromUserId,
        string? email,
        string? fcmToken,
        Func<string?, (string Title, string Body)> messageFactory,
        string? preferredLanguage,
        string type,
        string routeName,
        string referenceId,
        CancellationToken cancellationToken,
        string notificationTypeName = "order",
        Dictionary<string, string>? fcmData = null)
    {
        var (titleEn, bodyEn) = messageFactory("en");
        var (titleAr, bodyAr) = messageFactory("ar");

        var titleEnStore = TruncateNotifyField(titleEn, 255);
        var bodyEnStore = TruncateNotifyField(bodyEn, 1000);
        var titleArStore = TruncateNotifyField(titleAr, 255);
        var bodyArStore = TruncateNotifyField(bodyAr, 1000);

        var (title, body) = NotificationMessages.PickOptional(
            preferredLanguage,
            titleEnStore,
            bodyEnStore,
            titleArStore,
            bodyArStore);

        var routeId = await GetOrCreateNotificationRouteIdAsync(routeName, cancellationToken);
        var typeId = await GetOrCreateNotificationTypeIdAsync(notificationTypeName, cancellationToken);

        await dbContext.Notifications.AddAsync(new Notification
        {
            Id = Guid.NewGuid(),
            Title = titleEnStore,
            TitleAr = string.IsNullOrWhiteSpace(titleArStore) ? null : titleArStore,
            Body = bodyEnStore,
            BodyAr = string.IsNullOrWhiteSpace(bodyArStore) ? null : bodyArStore,
            FromUserId = fromUserId,
            ToUserId = toUserId,
            TypeId = typeId,
            RouteId = routeId,
            ReferenceId = referenceId,
            IsRead = false,
            CreatedAt = DateTime.UtcNow,
        }, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        NotificationCacheVersions.Bump(toUserId);

        if (!string.IsNullOrWhiteSpace(email))
        {
            try
            {
                var emailService = serviceProvider.GetRequiredService<IEmailService>();
                await emailService.SendAsync(
                    email,
                    title,
                    BrandEmailLayout.Headline(title) + BrandEmailLayout.Paragraph(body));
            }
            catch
            {
                // ignore email failures
            }
        }

        if (!string.IsNullOrWhiteSpace(fcmToken))
        {
            try
            {
                await fcmNotificationService.SendNotificationAsync(
                    fcmToken,
                    new FcmNotificationPayload
                    {
                        Title = title,
                        Body = body,
                        Type = type,
                        RouteId = routeName,
                        ReferenceId = referenceId,
                        Data = fcmData
                    },
                    cancellationToken);
            }
            catch
            {
                // ignore push failures
            }
        }
    }

    private static string TruncateNotifyField(string? value, int maxLen)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var trimmed = value.Trim();
        return trimmed.Length <= maxLen ? trimmed : trimmed[..(maxLen - 1)] + "…";
    }

    private async Task<Guid> GetOrCreateNotificationRouteIdAsync(
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationRoutes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var route = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await dbContext.NotificationRoutes.AddAsync(route, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return route.Id;
    }

    private async Task<byte> GetOrCreateNotificationTypeIdAsync(
        string name,
        CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationTypes
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var type = new NotificationType { Name = name };
        await dbContext.NotificationTypes.AddAsync(type, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return type.Id;
    }

}
