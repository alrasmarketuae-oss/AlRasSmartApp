using DataLayer.Helpers;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Repositories;

public sealed class OrderDataAccess(IRasAlSouqDbContext dbContext) : IOrderDataAccess
{
    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        dbContext.SaveChangesAsync(cancellationToken);

    public async Task AddOrderAsync(Order order, CancellationToken cancellationToken = default)
    {
        await dbContext.Orders.AddAsync(order, cancellationToken);
    }

    public async Task AddPendingOrderAsync(PendingOrder pendingOrder, CancellationToken cancellationToken = default)
    {
        await dbContext.PendingOrders.AddAsync(pendingOrder, cancellationToken);
    }

    public async Task AddOrderVideoAsync(OrderVideo orderVideo, CancellationToken cancellationToken = default)
    {
        await dbContext.OrderVideos.AddAsync(orderVideo, cancellationToken);
    }

    public async Task AddOrderImageAsync(OrderImage orderImage, CancellationToken cancellationToken = default)
    {
        await dbContext.OrderImages.AddAsync(orderImage, cancellationToken);
    }

    public void RemoveOrderVideo(OrderVideo orderVideo) =>
        dbContext.OrderVideos.Remove(orderVideo);

    public void RemoveOrderImage(OrderImage orderImage) =>
        dbContext.OrderImages.Remove(orderImage);

    public void RemoveCartItems(IEnumerable<CartItem> cartItems) =>
        dbContext.CartItems.RemoveRange(cartItems);

    public async Task<User?> GetUserByIdAsync(
        Guid userId,
        bool tracked = true,
        CancellationToken cancellationToken = default)
    {
        if (tracked)
        {
            return await dbContext.Users.FindAsync([userId], cancellationToken);
        }

        return await GetUserByIdAsNoTrackingAsync(userId, cancellationToken);
    }

    public Task<User?> GetUserByIdAsNoTrackingAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Users.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);

    public Task<Product?> GetProductForOrderAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products
            .Include(x => x.ProductType)
            .Include(x => x.Unit)
            .Include(x => x.RetailUnit)
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken);

    public Task<Dictionary<Guid, Product>> GetProductsByIdsWithUnitsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.Products
            .AsNoTracking()
            .Include(x => x.Unit)
            .Include(x => x.RetailUnit)
            .Where(x => productIds.Contains(x.ProductId))
            .ToDictionaryAsync(x => x.ProductId, cancellationToken);

    public async Task<Order?> GetOrderByIdTrackedAsync(long orderId, CancellationToken cancellationToken = default) =>
        await dbContext.Orders.FindAsync([orderId], cancellationToken);

    public Task<Order?> GetOrderWithProductForStatusAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.Orders
            .Include(x => x.Product!)
            .ThenInclude(x => x!.ProductType)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Order?> GetOrderWithProductForReturnAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.Orders
            .Include(x => x.Product!)
            .ThenInclude(x => x!.ProductType)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Order?> GetOrderWithProductForReturnResponseAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.Orders
            .Include(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Order?> GetOrderWithVideosAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.Orders
            .Include(x => x.Videos)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<OrderVideo?> GetOrderVideoWithOrderAsync(
        long videoId,
        long orderId,
        CancellationToken cancellationToken = default) =>
        dbContext.OrderVideos
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.Id == videoId && x.OrderId == orderId, cancellationToken);

    public Task<OrderImage?> GetOrderImageWithOrderAsync(
        long imageId,
        long orderId,
        CancellationToken cancellationToken = default) =>
        dbContext.OrderImages
            .Include(x => x.Order)
            .FirstOrDefaultAsync(x => x.Id == imageId && x.OrderId == orderId, cancellationToken);

    public Task<int> CountOrderImagesAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.OrderImages.CountAsync(x => x.OrderId == orderId, cancellationToken);

    public Task<Order?> GetOrderWithListDetailsAsync(long orderId, CancellationToken cancellationToken = default) =>
        OrderQueryHelpers.WithListDetails(dbContext.Orders)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Order?> GetOrderWithDetailDetailsAsync(long orderId, CancellationToken cancellationToken = default) =>
        OrderQueryHelpers.WithDetailDetails(dbContext.Orders)
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Order?> GetOrderWithProductAsNoTrackingAsync(long orderId, CancellationToken cancellationToken = default) =>
        dbContext.Orders
            .Include(x => x.Product)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<Cart?> GetCartForCheckoutAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Carts
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.ProductType)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.Unit)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Product!)
            .ThenInclude(x => x!.RetailUnit)
            .Include(x => x.CartItems)
            .ThenInclude(x => x.Unit)
            .FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);

    public Task<Cart?> GetCartWithItemsAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Carts
            .Include(x => x.CartItems)
            .FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);

    public Task<PendingOrder?> GetPendingOrderWithItemsAsync(Guid pendingOrderId, CancellationToken cancellationToken = default) =>
        dbContext.PendingOrders
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.Id == pendingOrderId, cancellationToken);

    public Task<Address?> GetAddressForUserAsync(
        Guid addressId,
        Guid userId,
        CancellationToken cancellationToken = default) =>
        dbContext.Addresses.FirstOrDefaultAsync(
            x => x.Id == addressId && x.UserId == userId,
            cancellationToken);

    public Task<Address?> GetAddressByUserCityLineAsync(
        Guid userId,
        Guid cityId,
        string addressLine1Lower,
        CancellationToken cancellationToken = default) =>
        dbContext.Addresses.FirstOrDefaultAsync(
            x => x.UserId == userId
                && x.CityId == cityId
                && x.AddressLine1.ToLower() == addressLine1Lower,
            cancellationToken);

    public Task<Guid?> GetProductOwnerIdAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.OwnerId)
            .FirstOrDefaultAsync(cancellationToken);

    public Task<Product?> GetProductAsNoTrackingAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.ProductId == productId, cancellationToken);

    public Task<int> CountPendingSellerActionsAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Orders.CountAsync(
            o => o.ProductId == productId
                && !o.IsApproved
                && o.StatusId == OrderCatalogCodes.StatusAwaitingSellerApproval,
            cancellationToken);

    public async Task<(List<Order> Orders, int TotalCount)> GetMyOrdersPageAsync(
        Guid userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        // "My Orders" is orders created by this user, excluding offers on Request ads
        // (those appear under My Offers / Account).
        var query = OrderQueryHelpers.WithListDetails(dbContext.Orders)
            .Where(x => x.FromUserId == userId
                && (x.Product == null || x.Product.ProductTypeId != OrderCatalogCodes.TypeRequests));

        if (statusId.HasValue)
        {
            query = query.Where(x => x.StatusId == statusId.Value);
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
                    (x.Notes != null && x.Notes.ToLower().Contains(term)));
            }
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (orders, totalCount);
    }

    public async Task<(List<Order> Orders, int TotalCount)> GetMyOffersPageAsync(
        Guid userId,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        var query = OrderQueryHelpers.WithListDetails(dbContext.Orders)
            .Where(x => x.FromUserId == userId
                && x.Product != null
                && x.Product.ProductTypeId == OrderCatalogCodes.TypeRequests);

        if (statusId.HasValue)
        {
            query = query.Where(x => x.StatusId == statusId.Value);
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
                    (x.ToUser != null && x.ToUser.FullName.ToLower().Contains(term)) ||
                    (x.ToUser != null && x.ToUser.Email.ToLower().Contains(term)) ||
                    (x.Product != null && x.Product.NameEn != null && x.Product.NameEn.ToLower().Contains(term)) ||
                    (x.Notes != null && x.Notes.ToLower().Contains(term)));
            }
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (orders, totalCount);
    }

    public async Task<(List<Order> Orders, int TotalCount)> GetOffersForRequestPageAsync(
        Guid productId,
        bool isAdminViewer,
        int page,
        int pageSize,
        byte? statusId,
        string? search,
        CancellationToken cancellationToken = default)
    {
        var query = OrderQueryHelpers.WithListDetails(dbContext.Orders)
            .Where(x => x.ProductId == productId);

        if (!isAdminViewer)
        {
            query = query.Where(x => x.IsAdminApproved);
        }

        if (statusId.HasValue)
        {
            query = query.Where(x => x.StatusId == statusId.Value);
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
                    (x.Notes != null && x.Notes.ToLower().Contains(term)));
            }
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (orders, totalCount);
    }

    public async Task<(List<Order> Orders, int TotalCount)> GetMyOffersOnMyRequestsPageAsync(
        Guid userId,
        int page,
        int pageSize,
        Guid? productId,
        byte? statusId,
        CancellationToken cancellationToken = default)
    {
        // Retail: visible immediately (seller-first, no admin gate).
        // Booking/Category/Offers/Requests: visible when IsAdminApproved
        // (created true when no notes/media; false until admin approves).
        var query = OrderQueryHelpers.WithListDetails(dbContext.Orders)
            .Where(x =>
                (x.ToUserId == userId
                 || (x.Product != null && x.Product.OwnerId == userId))
                && (
                    x.Product == null
                    || x.Product.ProductTypeId == OrderCatalogCodes.TypeRetail
                    || x.IsAdminApproved));

        if (productId.HasValue)
        {
            query = query.Where(x => x.ProductId == productId.Value);
        }

        if (statusId.HasValue)
        {
            query = query.Where(x => x.StatusId == statusId.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (orders, totalCount);
    }

    public Task<List<OrderProductNotifyMeta>> GetProductNotifyMetaByIdsAsync(
        IReadOnlyList<Guid> productIds,
        CancellationToken cancellationToken = default) =>
        dbContext.Products
            .AsNoTracking()
            .Where(x => productIds.Contains(x.ProductId))
            .Select(x => new OrderProductNotifyMeta
            {
                ProductId = x.ProductId,
                NameEn = x.NameEn,
                ProductTypeId = x.ProductTypeId,
                CategoryId = x.CategoryId,
                OwnerId = x.OwnerId
            })
            .ToListAsync(cancellationToken);

    public Task<List<OrderNotifyUserRow>> GetUsersNotifyByIdsAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken = default) =>
        dbContext.Users
            .AsNoTracking()
            .Where(x => userIds.Contains(x.Id))
            .Select(x => new OrderNotifyUserRow
            {
                Id = x.Id,
                Email = x.Email,
                FcmToken = x.FcmToken,
                PreferredLanguage = x.PreferredLanguage,
                RoleId = x.RoleId
            })
            .ToListAsync(cancellationToken);

    public Task<List<OrderNotifyUserRow>> GetAdminFcmRecipientsAsync(CancellationToken cancellationToken = default) =>
        dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1 && x.FcmToken != null && x.FcmToken != "")
            .Select(x => new OrderNotifyUserRow
            {
                Id = x.Id,
                Email = x.Email,
                FcmToken = x.FcmToken,
                PreferredLanguage = x.PreferredLanguage,
                RoleId = x.RoleId
            })
            .ToListAsync(cancellationToken);

    public Task<List<OrderNotifyUserRow>> GetAdminNotifyRecipientsAsync(CancellationToken cancellationToken = default) =>
        dbContext.Users
            .AsNoTracking()
            .Where(x => x.RoleId == 1)
            .Select(x => new OrderNotifyUserRow
            {
                Id = x.Id,
                Email = x.Email,
                FcmToken = x.FcmToken,
                PreferredLanguage = x.PreferredLanguage,
                RoleId = x.RoleId
            })
            .ToListAsync(cancellationToken);

    public Task<OrderNotifyUserRow?> GetUserNotifyByIdAsync(Guid userId, CancellationToken cancellationToken = default) =>
        dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => new OrderNotifyUserRow
            {
                Id = x.Id,
                Email = x.Email,
                FcmToken = x.FcmToken,
                PreferredLanguage = x.PreferredLanguage,
                RoleId = x.RoleId
            })
            .FirstOrDefaultAsync(cancellationToken);

    public Task<string?> GetProductNameEnAsync(Guid productId, CancellationToken cancellationToken = default) =>
        dbContext.Products
            .AsNoTracking()
            .Where(x => x.ProductId == productId)
            .Select(x => x.NameEn)
            .FirstOrDefaultAsync(cancellationToken);

    public Task<List<OrderNotifyUserRow>> GetUsersByIdsAsync(
        IReadOnlyList<Guid> userIds,
        CancellationToken cancellationToken = default) =>
        GetUsersNotifyByIdsAsync(userIds, cancellationToken);

    public async Task AddInboxNotificationAsync(Notification notification, CancellationToken cancellationToken = default)
    {
        await dbContext.Notifications.AddAsync(notification, cancellationToken);
    }

    public async Task<Guid> GetOrCreateNotificationRouteIdAsync(
        string name,
        CancellationToken cancellationToken = default)
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

    public async Task<byte> GetOrCreateNotificationTypeIdAsync(
        string name,
        CancellationToken cancellationToken = default)
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

    public async Task<AdminOrderStatsRow> GetAdminOrderStatsAsync(CancellationToken cancellationToken = default)
    {
        var utcNow = DateTime.UtcNow;
        var monthStart = new DateTime(utcNow.Year, utcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var prevMonthStart = monthStart.AddMonths(-1);

        var visibleOrders = OrderQueryHelpers.WhereVisibleInAdminDashboard(dbContext.Orders);

        var totalOrders = await visibleOrders.CountAsync(cancellationToken);
        var ordersThisMonth = await visibleOrders.CountAsync(x => x.CreatedAt >= monthStart, cancellationToken);
        var ordersLastMonth = await visibleOrders.CountAsync(
            x => x.CreatedAt >= prevMonthStart && x.CreatedAt < monthStart,
            cancellationToken);

        return new AdminOrderStatsRow
        {
            TotalOrders = totalOrders,
            OrdersThisMonth = ordersThisMonth,
            OrdersLastMonth = ordersLastMonth,
            OrderedCount = await visibleOrders.CountAsync(
                x => x.StatusId == OrderCatalogCodes.StatusOrdered,
                cancellationToken),
            ShippingCount = await visibleOrders.CountAsync(
                x => x.StatusId == OrderCatalogCodes.StatusShipping,
                cancellationToken),
            DeliveredCount = await visibleOrders.CountAsync(
                x => x.StatusId == OrderCatalogCodes.StatusDelivered,
                cancellationToken),
        };
    }

    public Task<Order?> GetAdminVisibleOrderWithDetailDetailsAsync(
        long orderId,
        CancellationToken cancellationToken = default) =>
        OrderQueryHelpers.WhereVisibleInAdminDashboard(
                OrderQueryHelpers.WithDetailDetails(dbContext.Orders))
            .FirstOrDefaultAsync(x => x.Id == orderId, cancellationToken);

    public Task<PendingPayment?> GetPendingPaymentByOrderIdAsync(
        long orderId,
        CancellationToken cancellationToken = default) =>
        dbContext.PendingPayments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.OrderId == orderId, cancellationToken);

    public async Task<(List<Order> Orders, int TotalCount)> GetAdminOrdersPageAsync(
        AdminOrdersPageFilter filter,
        CancellationToken cancellationToken = default)
    {
        var page = filter.Page < 1 ? 1 : filter.Page;
        var pageSize = filter.PageSize is < 1 or > 100 ? 20 : filter.PageSize;

        var query = OrderQueryHelpers.WhereVisibleInAdminDashboard(
            dbContext.Orders.AsNoTracking());

        if (filter.StatusId.HasValue)
        {
            query = query.Where(x => x.StatusId == filter.StatusId.Value);
        }

        query = OrderQueryHelpers.ApplyOrderChannelFilter(query, filter.OrderChannel);

        if (filter.ProductTypeId.HasValue)
        {
            query = query.Where(x => x.Product != null && x.Product.ProductTypeId == filter.ProductTypeId.Value);
        }

        if (filter.ExcludeProductTypeId.HasValue)
        {
            query = query.Where(x =>
                x.Product == null || x.Product.ProductTypeId != filter.ExcludeProductTypeId.Value);
        }

        if (filter.ProductId.HasValue)
        {
            query = query.Where(x => x.ProductId == filter.ProductId.Value);
        }

        var review = (filter.OfferReview ?? string.Empty).Trim().ToLowerInvariant();
        query = review switch
        {
            "awaitingadmin" or "new" or "pendingadmin" => query.Where(x =>
                !x.IsAdminApproved
                && x.StatusId == OrderCatalogCodes.StatusOrdered
                && x.Product != null
                && x.Product.ProductTypeId == OrderCatalogCodes.TypeRequests),
            "awaitingseller" or "pendingseller" => query.Where(x =>
                x.IsAdminApproved
                && !x.IsApproved
                && x.StatusId == OrderCatalogCodes.StatusAwaitingSellerApproval
                && x.Product != null
                && x.Product.ProductTypeId == OrderCatalogCodes.TypeRequests),
            "sellerapproved" or "accepted" => query.Where(x =>
                x.IsApproved
                && x.StatusId != OrderCatalogCodes.StatusCancelled
                && x.Product != null
                && x.Product.ProductTypeId == OrderCatalogCodes.TypeRequests),
            _ => query
        };

        if (filter.CreatedFrom.HasValue)
        {
            var from = DateTime.SpecifyKind(filter.CreatedFrom.Value.Date, DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt >= from);
        }

        if (filter.CreatedTo.HasValue)
        {
            var to = DateTime.SpecifyKind(filter.CreatedTo.Value.Date.AddDays(1), DateTimeKind.Utc);
            query = query.Where(x => x.CreatedAt < to);
        }

        if (!string.IsNullOrWhiteSpace(filter.Search))
        {
            var term = filter.Search.Trim().ToLowerInvariant();
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
            var loaded = await OrderQueryHelpers.WithListDetails(dbContext.Orders.AsNoTracking())
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

        return (orders, totalCount);
    }

    public async Task<List<OrderGroupSiblingRow>> GetOrderGroupSiblingsAsync(
        IReadOnlyList<Guid> groupIds,
        CancellationToken cancellationToken = default)
    {
        if (groupIds.Count == 0)
        {
            return [];
        }

        return await dbContext.Orders
            .AsNoTracking()
            .Where(x => x.OrderGroupId != null && groupIds.Contains(x.OrderGroupId.Value))
            .Select(x => new OrderGroupSiblingRow
            {
                Id = x.Id,
                OrderGroupId = x.OrderGroupId!.Value,
                ProductId = x.ProductId,
                ProductName = x.Product != null ? (x.Product.NameEn ?? string.Empty) : string.Empty,
                PrimaryImagePath = x.Product != null
                    ? x.Product.ProductImages
                        .OrderBy(i => i.Id)
                        .Select(i => i.ImagePath)
                        .FirstOrDefault()
                    : null,
                Quantity = x.Quantity,
                StatusId = x.StatusId,
                SupplierName = x.ToUser != null
                    ? (x.ToUser.CompanyName ?? x.ToUser.FullName)
                    : null,
            })
            .ToListAsync(cancellationToken);
    }
}
