using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RasAlSouqPresentaionLayer.Hubs;

namespace RasAlSouqPresentaionLayer.Services;

public class AdminRealtimeNotificationService(
    IRasAlSouqDbContext dbContext,
    IContentTranslationService contentTranslationService,
    IHubContext<AdminNotificationHub> hubContext,
    ILogger<AdminRealtimeNotificationService> logger) : IAdminRealtimeNotificationService
{
    private const byte PendingOrderStatusId = OrderStatusCodes.Ordered;
    private const byte AwaitingSellerStatusId = OrderStatusCodes.AwaitingSellerApproval;
    private const byte ReturnRequestedStatusId = OrderStatusCodes.ReturnRequested;

    public async Task<AdminLiveCountsDto> GetLiveCountsAsync(CancellationToken cancellationToken = default)
    {
        var pendingProfileEdits = await dbContext.Users
            .AsNoTracking()
            .CountAsync(x =>
                !x.IsRejected
                && x.PendingProfileChanges != null
                && x.PendingProfileChanges != string.Empty,
                cancellationToken);

        var pendingNewRegistrations = await dbContext.Users
            .AsNoTracking()
            .CountAsync(x =>
                !x.IsRejected
                && (x.RoleId == RoleIds.Seller || x.RoleId == RoleIds.ShippingCompany)
                && !x.IsApproved,
                cancellationToken);

        var pendingUsers = pendingNewRegistrations;

        // New ads awaiting first approval (not edit resubmits).
        // Offers / Retail / Booking / category ads → PendingAds (Ads sidebar).
        // Request ads → PendingRequestOfferAds (طلب / Reqs & Offers).
        var pendingAds = await dbContext.Products
            .AsNoTracking()
            .CountAsync(x =>
                x.IsReadyForAdminReview
                && x.IsApproved != true
                && x.Status != ProductStatusCodes.Rejected
                && x.ProductTypeId != ProductTypeCodes.Requests
                && (x.PendingProductChanges == null
                    || x.PendingProductChanges == string.Empty
                    || !(x.PendingProductChanges.Contains("\"IsApproved\":true")
                        || x.PendingProductChanges.Contains("\"isApproved\":true"))),
                cancellationToken);

        // Seller edited an existing approved ad and re-submitted for approval.
        var pendingAdEdits = await dbContext.Products
            .AsNoTracking()
            .CountAsync(x =>
                x.IsReadyForAdminReview
                && x.IsApproved != true
                && x.Status != ProductStatusCodes.Rejected
                && x.PendingProductChanges != null
                && x.PendingProductChanges != string.Empty
                && (x.PendingProductChanges.Contains("\"IsApproved\":true")
                    || x.PendingProductChanges.Contains("\"isApproved\":true")),
                cancellationToken);

        var pendingRequestOfferAds = await dbContext.Products
            .AsNoTracking()
            .CountAsync(x =>
                x.IsReadyForAdminReview
                && x.IsApproved != true
                && x.Status != ProductStatusCodes.Rejected
                && x.ProductTypeId == ProductTypeCodes.Requests
                && (x.PendingProductChanges == null
                    || x.PendingProductChanges == string.Empty
                    || !(x.PendingProductChanges.Contains("\"IsApproved\":true")
                        || x.PendingProductChanges.Contains("\"isApproved\":true"))),
                cancellationToken);

        var pendingShippingAds = await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .CountAsync(x =>
                !x.IsApproved && x.Status != ProductStatusCodes.Rejected, cancellationToken);

        // New catalog orders start as AwaitingSellerApproval; also surface returns for admin.
        var pendingOrderBase = AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(
                dbContext.Orders.AsNoTracking())
            .Where(x =>
                x.StatusId == PendingOrderStatusId
                || x.StatusId == AwaitingSellerStatusId
                || x.StatusId == ReturnRequestedStatusId);

        var pendingOrders = await pendingOrderBase
            .Where(x => x.Product == null || x.Product.ProductTypeId != ProductTypeCodes.Requests)
            .CountAsync(cancellationToken);

        var pendingRetailOrders = await pendingOrderBase
            .Where(x =>
                x.Product != null
                && (x.IsRetailPurchase
                    || (x.Product.ProductTypeId == ProductTypeCodes.Retail
                        && (x.Product.CategoryId == null || x.Product.CategoryId == 0))))
            .CountAsync(cancellationToken);

        var pendingBookingOrders = await pendingOrderBase
            .Where(x => x.Product != null && x.Product.ProductTypeId == ProductTypeCodes.Booking)
            .CountAsync(cancellationToken);

        var pendingOffersOrders = await pendingOrderBase
            .Where(x => x.Product != null && x.Product.ProductTypeId == ProductTypeCodes.Offers)
            .CountAsync(cancellationToken);

        var pendingCategoriesOrders = await pendingOrderBase
            .Where(x =>
                x.Product != null
                && x.Product.CategoryId != null
                && x.Product.CategoryId > 0
                && !x.IsRetailPurchase
                && (x.Product.ProductTypeId == null
                    || x.Product.ProductTypeId == ProductTypeCodes.Retail))
            .CountAsync(cancellationToken);

        // Supplier offers on Request ads awaiting admin approval.
        var pendingOffers = await AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(
                dbContext.Orders.AsNoTracking())
            .CountAsync(
                x =>
                    x.Product != null
                    && x.Product.ProductTypeId == ProductTypeCodes.Requests
                    && !x.IsAdminApproved
                    && x.StatusId != OrderStatusCodes.Cancelled,
                cancellationToken);

        return new AdminLiveCountsDto
        {
            PendingUsers = pendingUsers,
            PendingProfileEdits = pendingProfileEdits,
            PendingAds = pendingAds,
            PendingAdEdits = pendingAdEdits,
            PendingOrders = pendingOrders,
            PendingOffers = pendingOffers,
            PendingRequestOfferAds = pendingRequestOfferAds,
            PendingShippingAds = pendingShippingAds,
            PendingRetailOrders = pendingRetailOrders,
            PendingBookingOrders = pendingBookingOrders,
            PendingOffersOrders = pendingOffersOrders,
            PendingCategoriesOrders = pendingCategoriesOrders
        };
    }

    public async Task NotifyNewUserAsync(User user, CancellationToken cancellationToken = default)
    {
        var isCompany = user.RoleId == 2;
        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = "newUser",
            ReferenceId = user.Id.ToString(),
            DisplayName = isCompany
                ? user.CompanyName ?? user.FullName
                : user.FullName,
            SecondaryName = user.Email
        }, cancellationToken);
    }

    public async Task NotifyProfileEditAsync(User user, CancellationToken cancellationToken = default)
    {
        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = "profileEdit",
            ReferenceId = user.Id.ToString(),
            DisplayName = user.CompanyName ?? user.FullName,
            SecondaryName = user.Email
        }, cancellationToken);
    }

    public async Task NotifyNewProductAsync(Product product, CancellationToken cancellationToken = default)
    {
        var productTypeLabel = product.ProductTypeId switch
        {
            ProductTypeCodes.Offers => "Offers",
            ProductTypeCodes.Requests => "Requests",
            ProductTypeCodes.Retail => "Retail",
            ProductTypeCodes.Booking => "Booking",
            _ => product.CategoryId.HasValue ? "Category" : "Ad"
        };

        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = "newAd",
            ReferenceId = product.ProductId.ToString(),
            DisplayName = await ResolveProductDisplayNameAsync(product.ProductId, product.NameEn, cancellationToken),
            SecondaryName = productTypeLabel
        }, cancellationToken);
    }

    public async Task NotifyProductEditAsync(Product product, CancellationToken cancellationToken = default)
    {
        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = "adEdit",
            ReferenceId = product.ProductId.ToString(),
            DisplayName = await ResolveProductDisplayNameAsync(product.ProductId, product.NameEn, cancellationToken),
            SecondaryName = "edit"
        }, cancellationToken);
    }

    public async Task NotifyNewShippingPostAsync(
        InternationalShippingPost post,
        string? displayName,
        string? providerUserId,
        CancellationToken cancellationToken = default)
    {
        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = "newShippingAd",
            ReferenceId = post.Id.ToString(),
            DisplayName = displayName,
            SecondaryName = providerUserId
        }, cancellationToken);
    }

    public async Task NotifyNewOrderAsync(Order order, CancellationToken cancellationToken = default)
    {
        var product = await dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == order.ProductId)
            .Select(x => new
            {
                x.ProductId,
                x.NameEn,
                x.DescriptionEn,
                x.ProductTypeId,
                x.UnitId,
                UnitName = x.Unit != null ? x.Unit.UnitNameEn : null,
                RetailUnitName = x.RetailUnit != null ? x.RetailUnit.UnitNameEn : null
            })
            .FirstOrDefaultAsync(cancellationToken);

        var productName = product is null
            ? null
            : await ResolveProductDisplayNameAsync(product.ProductId, product.NameEn, cancellationToken);
        var isRequestOffer = product?.ProductTypeId == ProductTypeCodes.Requests;

        string? actorName;
        if (isRequestOffer)
        {
            // Supplier who submitted the offer (FromUser).
            actorName = await dbContext.Users
                .AsNoTracking()
                .Where(x => x.Id == order.FromUserId)
                .Select(x => x.CompanyName ?? x.FullName)
                .FirstOrDefaultAsync(cancellationToken);
        }
        else
        {
            actorName = await dbContext.Users
                .AsNoTracking()
                .Where(x => x.Id == order.FromUserId)
                .Select(x => x.FullName)
                .FirstOrDefaultAsync(cancellationToken);
        }

        var unitName = await ResolveOrderUnitNameAsync(order, product?.UnitId, product?.UnitName, product?.RetailUnitName, cancellationToken);
        var quantityText = FormatQuantity(order.Quantity);
        string? productDescription = product?.DescriptionEn;
        if (product is not null)
        {
            var translations = await contentTranslationService.GetProductTranslationsAsync(
                [product.ProductId],
                cancellationToken);
            translations.TryGetValue(product.ProductId, out var tr);
            productDescription = AdminProductTextHelper.ResolveDescription(tr, product.DescriptionEn);
        }

        var details = BuildOrderAlertDetails(order.Notes, productDescription);

        await PushAlertAsync(new AdminRealtimeAlertDto
        {
            Type = isRequestOffer ? "newOffer" : "newOrder",
            ReferenceId = order.Id.ToString(),
            DisplayName = actorName,
            SecondaryName = productName,
            // Product id so the dashboard can open the request ad itself.
            TertiaryName = isRequestOffer ? order.ProductId.ToString("D") : null,
            Quantity = quantityText,
            UnitName = unitName,
            Details = details
        }, cancellationToken);
    }

    private async Task<string?> ResolveProductDisplayNameAsync(
        Guid productId,
        string? legacyNameEn,
        CancellationToken cancellationToken)
    {
        var translations = await contentTranslationService.GetProductTranslationsAsync(
            [productId],
            cancellationToken);
        translations.TryGetValue(productId, out var tr);
        var name = AdminProductTextHelper.ResolveName(tr, legacyNameEn);
        return string.IsNullOrEmpty(name) ? null : name;
    }

    private async Task<string?> ResolveOrderUnitNameAsync(
        Order order,
        byte? productUnitId,
        string? productUnitName,
        string? retailUnitName,
        CancellationToken cancellationToken)
    {
        if (order.UnitId is byte orderUnitId)
        {
            var fromOrder = await dbContext.Units
                .AsNoTracking()
                .Where(x => x.Id == orderUnitId)
                .Select(x => x.UnitNameEn)
                .FirstOrDefaultAsync(cancellationToken);
            if (!string.IsNullOrWhiteSpace(fromOrder))
            {
                return fromOrder.Trim();
            }
        }

        if (order.IsRetailPurchase && !string.IsNullOrWhiteSpace(retailUnitName))
        {
            return retailUnitName.Trim();
        }

        if (!string.IsNullOrWhiteSpace(productUnitName))
        {
            return productUnitName.Trim();
        }

        if (productUnitId is byte fallbackUnitId)
        {
            return await dbContext.Units
                .AsNoTracking()
                .Where(x => x.Id == fallbackUnitId)
                .Select(x => x.UnitNameEn)
                .FirstOrDefaultAsync(cancellationToken);
        }

        return null;
    }

    private static string FormatQuantity(decimal quantity)
    {
        return quantity == decimal.Truncate(quantity)
            ? ((long)quantity).ToString()
            : quantity.ToString("0.##");
    }

    private static string? BuildOrderAlertDetails(string? notes, string? productDescription)
    {
        var notesTrimmed = notes?.Trim();
        if (!string.IsNullOrWhiteSpace(notesTrimmed))
        {
            return TruncateAlertText(notesTrimmed, 160);
        }

        var description = productDescription?.Trim();
        if (string.IsNullOrWhiteSpace(description))
        {
            return null;
        }

        // Specs may be multi-line; keep a short preview for the toast.
        var firstLine = description
            .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
            .Select(x => x.Trim())
            .FirstOrDefault(x => x.Length > 0);

        return string.IsNullOrWhiteSpace(firstLine)
            ? null
            : TruncateAlertText(firstLine, 160);
    }

    private static string TruncateAlertText(string value, int maxLength)
    {
        if (value.Length <= maxLength)
        {
            return value;
        }

        return value[..(maxLength - 1)].TrimEnd() + "…";
    }

    public async Task NotifyAdminChatMessageAsync(
        string recipientUserId,
        string senderUserId,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(recipientUserId, out var parsedRecipientId)
            || !Guid.TryParse(senderUserId, out var parsedSenderId))
        {
            return;
        }

        var isAdminRecipient = await dbContext.Users
            .AsNoTracking()
            .AnyAsync(x => x.Id == parsedRecipientId && x.RoleId == 1, cancellationToken);

        if (!isAdminRecipient)
        {
            return;
        }

        var senderDisplayName = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == parsedSenderId)
            .Select(x => x.CompanyName ?? x.FullName)
            .FirstOrDefaultAsync(cancellationToken);

        var activeAssignment = await dbContext.ChatSupportAssignments
            .AsNoTracking()
            .FirstOrDefaultAsync(
                x => x.CustomerUserId == parsedSenderId && x.ReleasedAtUtc == null,
                cancellationToken);

        var alert = new AdminRealtimeAlertDto
        {
            Type = "chat",
            ReferenceId = senderUserId,
            DisplayName = senderDisplayName
        };

        if (activeAssignment is not null)
        {
            await PushChatAlertToAgentAsync(alert, activeAssignment.AgentUserId.ToString("D"), cancellationToken);
            return;
        }

        await PushAlertAsync(alert, cancellationToken);
    }

    private async Task PushChatAlertToAgentAsync(
        AdminRealtimeAlertDto alert,
        string agentUserId,
        CancellationToken cancellationToken)
    {
        try
        {
            await hubContext.Clients
                .Group(AdminNotificationHub.GetAgentGroupName(agentUserId))
                .SendAsync("adminAlert", alert, cancellationToken);

            await PushCountsAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to push targeted admin chat alert to agent {AgentUserId}", agentUserId);
        }
    }

    public Task BroadcastCountsAsync(CancellationToken cancellationToken = default) =>
        PushCountsAsync(cancellationToken);

    private async Task PushAlertAsync(AdminRealtimeAlertDto alert, CancellationToken cancellationToken)
    {
        try
        {
            await hubContext.Clients
                .Group(AdminNotificationHub.GroupName)
                .SendAsync("adminAlert", alert, cancellationToken);

            await PushCountsAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to push admin realtime alert {AlertType}", alert.Type);
        }
    }

    private async Task PushCountsAsync(CancellationToken cancellationToken)
    {
        try
        {
            var counts = await GetLiveCountsAsync(cancellationToken);
            await hubContext.Clients
                .Group(AdminNotificationHub.GroupName)
                .SendAsync("liveCountsUpdated", counts, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to push admin live counts");
        }
    }
}
