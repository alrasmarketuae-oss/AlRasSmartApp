using BusinessLayer.Caching;
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
    private async Task NotifyOrderPartiesAsync(IReadOnlyList<Order> orders, CancellationToken cancellationToken)
    {
        if (orders.Count == 0)
        {
            return;
        }

        var productIds = orders.Select(x => x.ProductId).Distinct().ToList();
        var productMeta = await orderData.GetProductNotifyMetaByIdsAsync(productIds, cancellationToken);

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
        var sellers = await orderData.GetUsersNotifyByIdsAsync(sellerIds, cancellationToken);

        var admins = await orderData.GetAdminFcmRecipientsAsync(cancellationToken);

        var orderGroupId = orders.First().OrderGroupId?.ToString() ?? orders.First().Id.ToString();
        var buyerId = orders.First().FromUserId;
        var buyer = await orderData.GetUserNotifyByIdAsync(buyerId, cancellationToken);

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
                    routeName: "orders",
                    referenceId: order.Id.ToString(),
                    notificationTypeName: isRequestOffer ? "request_offer" : "order",
                    fcmData: new Dictionary<string, string>
                    {
                        ["offerCount"] = pendingCount.ToString(),
                        ["productId"] = order.ProductId.ToString(),
                        ["orderId"] = order.Id.ToString(),
                        ["highlightProductId"] = order.ProductId.ToString(),
                    },
                    cancellationToken: cancellationToken,
                    emailHtml: BuildSellerNewOrderEmailHtml(seller.PreferredLanguage, order, productName));
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

            await PublishOrderRealtimeAsync(order, cancellationToken, isNew: true);
        }
    }

    private async Task PublishOrderRealtimeAsync(
        Order order,
        CancellationToken cancellationToken,
        bool isNew = false)
    {
        try
        {
            await orderRealtimeNotificationService.NotifyOrderUpdatedAsync(
                order.Id,
                order.StatusId,
                RequestOfferStatusLabels.ResolveNameEn(order),
                RequestOfferStatusLabels.ResolveNameAr(order),
                ResolveOrderParticipantUserIds(order),
                cancellationToken,
                isNew ? "new_order" : "order_updated");
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Order realtime publish failed for order {OrderId}", order.Id);
        }
    }

    /// <summary>
    /// Status-update notifications:
    /// - Retail orders → buyer only
    /// - All other order types → buyer + seller
    /// </summary>
    private async Task NotifyBuyerOrderStatusAsync(
        Order order,
        Guid fromUserId,
        CancellationToken cancellationToken)
    {
        var orderDetails = await orderData.GetOrderWithDetailDetailsAsync(order.Id, cancellationToken)
            ?? order;

        var buyer = await orderData.GetUserNotifyByIdAsync(orderDetails.FromUserId, cancellationToken);

        var isSellerAction = fromUserId == orderDetails.ToUserId
            || fromUserId == (orderDetails.Product?.OwnerId ?? Guid.Empty);
        var statusEn = RequestOfferStatusLabels.ResolveNameEn(orderDetails);
        var statusAr = RequestOfferStatusLabels.ResolveNameAr(orderDetails);
        var isRequestOffer = orderDetails.Product?.ProductTypeId == ProductTypeCodes.Requests;
        var isRetail = ProductTypeCodes.IsRetailOrder(orderDetails);
        var cancellationReasonEn = orderDetails.CancellationReason?.NameEn;
        var cancellationReasonAr = orderDetails.CancellationReason?.NameAr;
        var cancellationNote = orderDetails.CancellationNote;

        var productName = orderDetails.Product?.NameEn?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(productName))
        {
            productName = await orderData.GetProductNameEnAsync(orderDetails.ProductId, cancellationToken)
                ?? string.Empty;
        }

        if (buyer is not null)
        {
            try
            {
                await SendUserAlertAsync(
                    toUserId: buyer.Id,
                    fromUserId: fromUserId,
                    email: buyer.Email,
                    fcmToken: buyer.FcmToken,
                    messageFactory: lang => isSellerAction switch
                    {
                        true when orderDetails.StatusId == OrderStatusCodes.Approved =>
                            NotificationMessages.OrderAcceptedBySellerBuyer(lang, orderDetails.Id),
                        true when orderDetails.StatusId == OrderStatusCodes.Cancelled =>
                            NotificationMessages.OrderCancelledBuyer(
                                lang,
                                orderDetails.Id,
                                cancellationReasonEn,
                                cancellationReasonAr,
                                cancellationNote),
                        _ when orderDetails.StatusId == OrderStatusCodes.Cancelled =>
                            NotificationMessages.OrderCancelledBuyer(
                                lang,
                                orderDetails.Id,
                                cancellationReasonEn,
                                cancellationReasonAr,
                                cancellationNote),
                        _ => NotificationMessages.OrderStatusUpdatedBuyer(
                            lang,
                            orderDetails.Id,
                            statusEn,
                            statusAr)
                    },
                    preferredLanguage: buyer.PreferredLanguage,
                    type: "order_status_updated",
                    routeName: isRequestOffer ? "my_offers" : "track_order",
                    referenceId: orderDetails.Id.ToString(),
                    cancellationToken: cancellationToken,
                    emailHtml: BuildOrderStatusUpdateEmailHtml(
                        buyer.PreferredLanguage,
                        orderDetails,
                        productName,
                        statusEn,
                        statusAr));
            }
            catch
            {
                // Notification failure must not roll back order updates.
            }
        }

        // Retail: buyer only. Wholesale / booking / offers / requests: also notify seller.
        if (!isRetail)
        {
            var sellerId = orderDetails.Product?.OwnerId ?? orderDetails.ToUserId;
            if (sellerId != Guid.Empty && sellerId != orderDetails.FromUserId)
            {
                var seller = await orderData.GetUserNotifyByIdAsync(sellerId, cancellationToken);
                if (seller is not null)
                {
                    try
                    {
                        await SendUserAlertAsync(
                            toUserId: seller.Id,
                            fromUserId: fromUserId,
                            email: seller.Email,
                            fcmToken: seller.FcmToken,
                            messageFactory: lang => orderDetails.StatusId == OrderStatusCodes.Cancelled
                                ? NotificationMessages.OrderCancelledSeller(
                                    lang,
                                    orderDetails.Id,
                                    cancellationReasonEn,
                                    cancellationReasonAr,
                                    cancellationNote)
                                : NotificationMessages.OrderStatusUpdatedSeller(
                                    lang,
                                    orderDetails.Id,
                                    statusEn,
                                    statusAr),
                            preferredLanguage: seller.PreferredLanguage,
                            type: "order_status_updated",
                            routeName: isRequestOffer ? "my_ads" : "orders",
                            referenceId: orderDetails.Id.ToString(),
                            cancellationToken: cancellationToken,
                            emailHtml: BuildOrderStatusUpdateEmailHtml(
                                seller.PreferredLanguage,
                                orderDetails,
                                productName,
                                statusEn,
                                statusAr));
                    }
                    catch
                    {
                        // Notification failure must not roll back order updates.
                    }
                }
            }
        }

        await PublishOrderRealtimeAsync(orderDetails, cancellationToken);
    }

    private async Task NotifyOfferRejectedByAdminAsync(
        Order order,
        Guid fromUserId,
        string? reasonEn,
        string? reasonAr,
        CancellationToken cancellationToken)
    {
        var buyer = await orderData.GetUserNotifyByIdAsync(order.FromUserId, cancellationToken);
        if (buyer is null)
        {
            await PublishOrderRealtimeAsync(order, cancellationToken);
            return;
        }

        try
        {
            var isRequestOffer = ProductTypeCodes.IsRequests(order.Product?.ProductTypeId);
            await SendUserAlertAsync(
                toUserId: buyer.Id,
                fromUserId: fromUserId,
                email: buyer.Email,
                fcmToken: buyer.FcmToken,
                messageFactory: lang => isRequestOffer
                    ? NotificationMessages.OfferRejectedByAdmin(lang, order.Id, reasonEn, reasonAr)
                    : NotificationMessages.OrderRejectedByAdmin(lang, order.Id, reasonEn, reasonAr),
                preferredLanguage: buyer.PreferredLanguage,
                type: isRequestOffer ? "offer_rejected" : "order_rejected",
                routeName: isRequestOffer ? "my_offers" : "orders",
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
        var buyer = await orderData.GetUserNotifyByIdAsync(order.FromUserId, cancellationToken);

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
        var admins = await orderData.GetAdminFcmRecipientsAsync(cancellationToken);

        var productName = order.Product?.NameEn?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(productName))
        {
            productName = await orderData.GetProductNameEnAsync(order.ProductId, cancellationToken) ?? string.Empty;
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


    private async Task NotifyRequestOwnerOfApprovedOfferAsync(Order order, CancellationToken cancellationToken)
    {
        await NotifyAdvertiserOfAdminApprovedOrderAsync(order, cancellationToken);
    }

    private async Task NotifyAdvertiserOfAdminApprovedOrderAsync(Order order, CancellationToken cancellationToken)
    {
        var advertiserId = order.Product?.OwnerId ?? order.ToUserId;
        var advertiser = await orderData.GetUserNotifyByIdAsync(advertiserId, cancellationToken);

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
                routeName: "orders",
                referenceId: order.Id.ToString(),
                notificationTypeName: isRequestOffer ? "request_offer" : "order",
                fcmData: new Dictionary<string, string>
                {
                    ["offerCount"] = pendingCount.ToString(),
                    ["productId"] = order.ProductId.ToString(),
                    ["orderId"] = order.Id.ToString(),
                    ["highlightProductId"] = order.ProductId.ToString(),
                },
                cancellationToken: cancellationToken,
                emailHtml: BuildSellerNewOrderEmailHtml(advertiser.PreferredLanguage, order, productName));
        }
        catch
        {
            // Notification failure must not roll back admin approval.
        }

        await PublishOrderRealtimeAsync(order, cancellationToken, isNew: true);
    }

    private async Task NotifyAdminSellerApprovedOrderAsync(Order order, CancellationToken cancellationToken)
    {
        var admins = await orderData.GetAdminFcmRecipientsAsync(cancellationToken);

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

        var admins = await orderData.GetAdminNotifyRecipientsAsync(cancellationToken);

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

        var supplierId = order.Product?.OwnerId ?? order.ToUserId;
        var supplier = await orderData.GetUserNotifyByIdAsync(supplierId, cancellationToken);
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

        var buyer = await orderData.GetUserNotifyByIdAsync(order.FromUserId, cancellationToken);
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

        var supplierId = order.Product?.OwnerId ?? order.ToUserId;
        var supplier = await orderData.GetUserNotifyByIdAsync(supplierId, cancellationToken);
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
        var buyer = await orderData.GetUserNotifyByIdAsync(order.FromUserId, cancellationToken);
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
        Dictionary<string, string>? fcmData = null,
        string? emailHtml = null)
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

        await orderData.AddInboxNotificationAsync(new Notification
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
        await orderData.SaveChangesAsync(cancellationToken);

        NotificationCacheVersions.Bump(toUserId);

        if (!string.IsNullOrWhiteSpace(email))
        {
            try
            {
                var emailService = serviceProvider.GetRequiredService<IEmailService>();
                await emailService.SendAsync(
                    email,
                    title,
                    string.IsNullOrWhiteSpace(emailHtml)
                        ? BrandEmailLayout.Headline(title) + BrandEmailLayout.Paragraph(body)
                        : emailHtml);
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
        return await orderData.GetOrCreateNotificationRouteIdAsync(name, cancellationToken);
    }

    private async Task<byte> GetOrCreateNotificationTypeIdAsync(
        string name,
        CancellationToken cancellationToken)
    {
        return await orderData.GetOrCreateNotificationTypeIdAsync(name, cancellationToken);
    }

    private static string BuildSellerNewOrderEmailHtml(string? language, Order order, string productName)
    {
        var arabic = NotificationMessages.IsArabic(language);
        var title = arabic ? "طلب جديد على إعلانك" : "New order on your listing";
        var intro = arabic
            ? "وصلك طلب جديد. راجع التفاصيل بالأسفل ثم افتح طلباتي في التطبيق للقبول أو الرفض."
            : "You received a new order. Review the details below, then open My Orders in the app to accept or reject it.";
        var qty = order.Quantity == decimal.Truncate(order.Quantity)
            ? ((long)order.Quantity).ToString()
            : order.Quantity.ToString("0.##");
        var total = order.TotalPrice.ToString("0.00");
        var delivery = string.IsNullOrWhiteSpace(order.DeliveryAddressLine)
            ? (arabic ? "غير محدد" : "Not provided")
            : order.DeliveryAddressLine.Trim();
        var coords = AddressTextFormatter.FormatCoordinates(order.DeliveryLatitude, order.DeliveryLongitude);

        return BrandEmailLayout.Headline(title)
            + BrandEmailLayout.Paragraph(intro)
            + BrandEmailLayout.InfoCard(arabic ? "رقم الطلب" : "Order no.", $"#{order.Id}")
            + BrandEmailLayout.InfoCard(arabic ? "المنتج" : "Product", string.IsNullOrWhiteSpace(productName) ? "—" : productName)
            + BrandEmailLayout.InfoCard(arabic ? "الكمية" : "Quantity", qty)
            + BrandEmailLayout.InfoCard(arabic ? "الإجمالي (د.إ)" : "Total (AED)", total)
            + BrandEmailLayout.InfoCard(arabic ? "عنوان التوصيل" : "Delivery address", delivery)
            + (string.IsNullOrWhiteSpace(coords)
                ? string.Empty
                : BrandEmailLayout.InfoCard(arabic ? "الإحداثيات" : "Coordinates", coords));
    }

    private static string BuildOrderStatusUpdateEmailHtml(
        string? language,
        Order order,
        string productName,
        string statusEn,
        string statusAr)
    {
        var arabic = NotificationMessages.IsArabic(language);
        var title = arabic ? "تحديث حالة الطلب" : "Order status update";
        var intro = arabic
            ? $"تم تحديث حالة طلبك رقم #{order.Id}. في الأسفل قائمة التتبع الكاملة."
            : $"Your order #{order.Id} status has been updated. The full tracking timeline is below.";
        var statusPill = arabic
            ? $"{statusAr} · {statusEn}"
            : $"{statusEn} · {statusAr}";
        var qty = order.Quantity == decimal.Truncate(order.Quantity)
            ? ((long)order.Quantity).ToString()
            : order.Quantity.ToString("0.##");
        var total = order.TotalPrice.ToString("0.00");

        var inner =
            BrandEmailLayout.Headline(title)
            + BrandEmailLayout.Paragraph(intro)
            + BrandEmailLayout.StatusPill(statusPill, StatusAccentForOrder(order.StatusId))
            + BrandEmailLayout.InfoCard(arabic ? "رقم الطلب" : "Order no.", $"#{order.Id}")
            + BrandEmailLayout.InfoCard(
                arabic ? "المنتج" : "Product",
                string.IsNullOrWhiteSpace(productName) ? "—" : productName)
            + BrandEmailLayout.InfoCard(arabic ? "الكمية" : "Quantity", qty)
            + BrandEmailLayout.InfoCard(arabic ? "الإجمالي (د.إ)" : "Total (AED)", total)
            + BuildOrderTrackingTimelineHtml(order, arabic);

        var subject = arabic
            ? $"تطبيق الراس الذكي — تحديث طلب #{order.Id}"
            : $"Al Ras Smart — Order #{order.Id} update";

        return BrandEmailLayout.Wrap(subject, inner);
    }

    private static string BuildOrderTrackingTimelineHtml(Order order, bool arabic)
    {
        var steps = new List<(string Label, string? Date, bool IsLatest)>
        {
            (
                arabic ? "تم الطلب" : "Ordered",
                FormatOrderEmailDate(order.CreatedAt, arabic),
                false),
        };

        var history = order.StatusHistories?
            .OrderBy(h => h.CreatedAtUtc)
            .ThenBy(h => h.Id)
            .ToList() ?? [];

        if (history.Count > 0)
        {
            for (var i = 0; i < history.Count; i++)
            {
                var entry = history[i];
                var labelEn = RequestOfferStatusLabels.NormalizeDisplayEn(entry.StatusNameEn);
                var labelAr = RequestOfferStatusLabels.NormalizeDisplayAr(entry.StatusNameAr);
                var label = arabic
                    ? (string.IsNullOrWhiteSpace(labelAr) ? labelEn : labelAr)
                    : (string.IsNullOrWhiteSpace(labelEn) ? labelAr : labelEn);
                if (string.IsNullOrWhiteSpace(label))
                {
                    label = arabic ? "تحديث الحالة" : "Status update";
                }

                steps.Add((
                    label,
                    FormatOrderEmailDate(entry.CreatedAtUtc, arabic),
                    i == history.Count - 1));
            }
        }
        else
        {
            var current = arabic
                ? RequestOfferStatusLabels.ResolveNameAr(order)
                : RequestOfferStatusLabels.ResolveNameEn(order);
            if (!string.IsNullOrWhiteSpace(current))
            {
                steps.Add((current, null, true));
            }
        }

        return BrandEmailLayout.Timeline(steps, arabic);
    }

    private static string FormatOrderEmailDate(DateTime value, bool arabic)
    {
        var utc = UtcDateTimeHelper.AsUtc(value);
        var culture = arabic
            ? new System.Globalization.CultureInfo("ar-AE")
            : System.Globalization.CultureInfo.InvariantCulture;
        return utc.ToString("dd MMM yyyy, HH:mm", culture) + " UTC";
    }

    private static string StatusAccentForOrder(byte statusId) => statusId switch
    {
        OrderStatusCodes.Approved => BrandEmailLayout.Green,
        OrderStatusCodes.Delivered => BrandEmailLayout.Green,
        OrderStatusCodes.Received => BrandEmailLayout.Green,
        OrderStatusCodes.Cancelled => BrandEmailLayout.Red,
        _ => BrandEmailLayout.Blue,
    };
}
