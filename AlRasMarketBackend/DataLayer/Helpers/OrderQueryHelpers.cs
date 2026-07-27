using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Helpers;

/// <summary>
/// Order status / type byte values used by order filters (kept in DataLayer so EF stays here).
/// Mirrors BusinessLayer ProductTypeCodes / OrderStatusCodes constants.
/// </summary>
public static class OrderCatalogCodes
{
    public const byte TypeRetail = 1;
    public const byte TypeBooking = 2;
    public const byte TypeOffers = 3;
    public const byte TypeRequests = 4;

    public const byte StatusOrdered = 1;
    public const byte StatusShipping = 4;
    public const byte StatusDelivered = 5;
    public const byte StatusCancelled = 6;
    public const byte StatusAwaitingSellerApproval = 11;
}

public static class OrderQueryHelpers
{
    /// <summary>
    /// Mirrors BusinessLayer AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard
    /// (currently identity — all orders visible).
    /// </summary>
    public static IQueryable<Order> WhereVisibleInAdminDashboard(IQueryable<Order> query) => query;

    public static IQueryable<Order> WithListDetails(IQueryable<Order> query) =>
        query
            .Include(x => x.FromUser)
            .Include(x => x.ToUser)
            .Include(x => x.Status)
            .Include(x => x.Unit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Category)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductType)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.RequestType)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Unit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.RetailUnit)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductImages)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductDocuments)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ProductVideos)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.OriginCountry)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.DestinationCountry)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.LoadingPort)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.ArrivalPort)
            .Include(x => x.Product!)
                .ThenInclude(x => x!.Address!)
                    .ThenInclude(a => a.City)
            .Include(x => x.Images)
            .Include(x => x.Videos)
            .Include(x => x.Port)
                .ThenInclude(x => x!.Country)
            .Include(x => x.PendingOrder!)
                .ThenInclude(p => p!.Address!)
                    .ThenInclude(a => a!.City);

    /// <summary>Same as list includes, plus full status timeline for order detail.</summary>
    public static IQueryable<Order> WithDetailDetails(IQueryable<Order> query) =>
        WithListDetails(query).Include(x => x.StatusHistories);

    /// <summary>
    /// Splits catalog orders into sidebar pages: retail / booking / offers / categories.
    /// Mirrors AdminOrdersAppService.ApplyOrderChannelFilter.
    /// </summary>
    public static IQueryable<Order> ApplyOrderChannelFilter(IQueryable<Order> query, string? orderChannel)
    {
        var channel = (orderChannel ?? string.Empty).Trim().ToLowerInvariant();
        return channel switch
        {
            "retail" => query.Where(x =>
                x.Product != null
                && (x.IsRetailPurchase
                    || (x.Product.ProductTypeId == OrderCatalogCodes.TypeRetail
                        && (x.Product.CategoryId == null || x.Product.CategoryId == 0)))),
            "categories" or "category" or "wholesale" => query.Where(x =>
                x.Product != null
                && x.Product.CategoryId != null
                && x.Product.CategoryId > 0
                && !x.IsRetailPurchase
                && (x.Product.ProductTypeId == null
                    || x.Product.ProductTypeId == OrderCatalogCodes.TypeRetail)),
            "booking" => query.Where(x =>
                x.Product != null && x.Product.ProductTypeId == OrderCatalogCodes.TypeBooking),
            "offers" or "offer" => query.Where(x =>
                x.Product != null && x.Product.ProductTypeId == OrderCatalogCodes.TypeOffers),
            _ => query
        };
    }
}
