using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class AdminDashboardAppService(IRasAlSouqDbContext dbContext) : IAdminDashboardAppService
{
    public async Task<object> GetDashboardAsync(
        DateTime? createdFrom = null,
        DateTime? createdTo = null,
        CancellationToken cancellationToken = default)
    {
        var response = await BuildDashboardAsync(createdFrom, createdTo, cancellationToken);
        return response;
    }

    public async Task<AdminDashboardResponse> BuildDashboardAsync(
        DateTime? createdFrom = null,
        DateTime? createdTo = null,
        CancellationToken cancellationToken = default)
    {
        var utcNow = DateTime.UtcNow;
        ResolvePeriod(
            createdFrom,
            createdTo,
            utcNow,
            out var periodStart,
            out var periodEndExclusive,
            out var prevPeriodStart,
            out var prevPeriodEndExclusive);

        var yearStart = new DateTime(periodStart.Year, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        var totalUsers = await dbContext.Users.CountAsync(cancellationToken);
        var newUsersThisMonth = await dbContext.Users.CountAsync(
            x => x.CreatedAt >= periodStart && x.CreatedAt < periodEndExclusive, cancellationToken);
        var newUsersLastMonth = await dbContext.Users.CountAsync(
            x => x.CreatedAt >= prevPeriodStart && x.CreatedAt < prevPeriodEndExclusive, cancellationToken);

        var activeSuppliers = await dbContext.Users.CountAsync(x => x.RoleId == 2 && x.IsActive, cancellationToken);
        var newSuppliersThisMonth = await dbContext.Users.CountAsync(
            x => x.RoleId == 2 && x.CreatedAt >= periodStart && x.CreatedAt < periodEndExclusive, cancellationToken);
        var newSuppliersLastMonth = await dbContext.Users.CountAsync(
            x => x.RoleId == 2 && x.CreatedAt >= prevPeriodStart && x.CreatedAt < prevPeriodEndExclusive, cancellationToken);

        var visibleOrders = AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(dbContext.Orders);

        // Sales / order volume on the home dashboard = delivered (and post-delivery paid) only.
        var deliveredOrders = visibleOrders.Where(x =>
            x.StatusId == OrderStatusCodes.Delivered
            || x.StatusId == OrderStatusCodes.Received
            || x.StatusId == OrderStatusCodes.PaidToSupplier);

        var monthlyOrders = await deliveredOrders.CountAsync(
            x => x.CreatedAt >= periodStart && x.CreatedAt < periodEndExclusive, cancellationToken);
        var monthlyOrdersPrev = await deliveredOrders.CountAsync(
            x => x.CreatedAt >= prevPeriodStart && x.CreatedAt < prevPeriodEndExclusive, cancellationToken);

        var monthlySales = await deliveredOrders
            .Where(x => x.CreatedAt >= periodStart && x.CreatedAt < periodEndExclusive)
            .SumAsync(x => (decimal?)x.TotalPrice, cancellationToken) ?? 0m;
        var monthlySalesPrev = await deliveredOrders
            .Where(x => x.CreatedAt >= prevPeriodStart && x.CreatedAt < prevPeriodEndExclusive)
            .SumAsync(x => (decimal?)x.TotalPrice, cancellationToken) ?? 0m;

        var monthlyProfitsRaw = await deliveredOrders
            .Where(x => x.CreatedAt >= yearStart)
            .GroupBy(x => new { x.CreatedAt.Year, x.CreatedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Total = g.Sum(x => x.TotalPrice) })
            .ToListAsync(cancellationToken);

        var recentOrders = await deliveredOrders
            .Include(x => x.FromUser)
            .Include(x => x.ToUser)
            .Include(x => x.Status)
            .Include(x => x.PendingOrder)
            .OrderByDescending(x => x.CreatedAt)
            .Take(10)
            .ToListAsync(cancellationToken);

        var recentUsers = await dbContext.Users
            .Include(x => x.Role)
            .OrderByDescending(x => x.CreatedAt)
            .Take(6)
            .ToListAsync(cancellationToken);

        var activity = await BuildActivityFeedAsync(utcNow, cancellationToken);

        var profitSeries = Enumerable.Range(0, 12)
            .Select(i =>
            {
                var date = yearStart.AddMonths(i);
                var total = monthlyProfitsRaw
                    .Where(p => p.Year == date.Year && p.Month == date.Month)
                    .Select(p => p.Total)
                    .FirstOrDefault();
                return new MonthlyProfitPointDto
                {
                    Month = date.ToString("MMM", System.Globalization.CultureInfo.InvariantCulture),
                    MonthAr = AdminMappings.GetArabicMonth(date.Month),
                    Value = total
                };
            })
            .ToList();

        var pendingCompanies = await dbContext.Users.CountAsync(x => x.RoleId == 2 && !x.IsActive, cancellationToken);
        var totalProducts = await dbContext.Products.CountAsync(cancellationToken);
        var totalOffers = await dbContext.OffersOnNegotiable.CountAsync(cancellationToken);
        var notificationCount = await dbContext.Notifications.CountAsync(cancellationToken);

        var pendingOrders = await visibleOrders.CountAsync(
            x => x.StatusId == OrderStatusCodes.Ordered
                || x.StatusId == OrderStatusCodes.AwaitingSellerApproval
                || x.StatusId == OrderStatusCodes.ReturnRequested,
            cancellationToken);

        var yearSales = monthlyProfitsRaw.Sum(x => x.Total);
        var avgOrderValue = monthlyOrders > 0
            ? decimal.Round(monthlySales / monthlyOrders, 2, MidpointRounding.AwayFromZero)
            : 0m;
        var salesGrowth = AdminMappings.PercentChange(monthlySales, monthlySalesPrev);
        var conversionRate = totalUsers > 0
            ? decimal.Round(monthlyOrders * 100m / totalUsers, 2, MidpointRounding.AwayFromZero)
            : 0m;

        var monthlyOrderSeries = await deliveredOrders
            .Where(x => x.CreatedAt >= yearStart)
            .GroupBy(x => new { x.CreatedAt.Year, x.CreatedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var monthlyUserSeries = await dbContext.Users
            .Where(x => x.CreatedAt >= yearStart)
            .GroupBy(x => new { x.CreatedAt.Year, x.CreatedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var monthlySupplierSeries = await dbContext.Users
            .Where(x => x.RoleId == 2 && x.CreatedAt >= yearStart)
            .GroupBy(x => new { x.CreatedAt.Year, x.CreatedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
            .ToListAsync(cancellationToken);

        static List<decimal> BuildYearSparkline(
            DateTime yearStartDate,
            IEnumerable<(int Year, int Month, decimal Value)> points)
        {
            return Enumerable.Range(0, 12)
                .Select(i =>
                {
                    var date = yearStartDate.AddMonths(i);
                    return points
                        .Where(p => p.Year == date.Year && p.Month == date.Month)
                        .Select(p => p.Value)
                        .FirstOrDefault();
                })
                .ToList();
        }

        var salesSparkline = BuildYearSparkline(
            yearStart,
            monthlyProfitsRaw.Select(p => (p.Year, p.Month, p.Total)));
        var ordersSparkline = BuildYearSparkline(
            yearStart,
            monthlyOrderSeries.Select(p => (p.Year, p.Month, (decimal)p.Count)));
        var usersSparkline = BuildYearSparkline(
            yearStart,
            monthlyUserSeries.Select(p => (p.Year, p.Month, (decimal)p.Count)));
        var suppliersSparkline = BuildYearSparkline(
            yearStart,
            monthlySupplierSeries.Select(p => (p.Year, p.Month, (decimal)p.Count)));

        return new AdminDashboardResponse
        {
            Stats = new AdminStatsDto
            {
                TotalUsers = new AdminStatMetricDto
                {
                    Value = totalUsers,
                    ChangePercent = AdminMappings.PercentChange(newUsersThisMonth, newUsersLastMonth),
                    Sparkline = usersSparkline
                },
                ActiveSuppliers = new AdminStatMetricDto
                {
                    Value = activeSuppliers,
                    ChangePercent = AdminMappings.PercentChange(newSuppliersThisMonth, newSuppliersLastMonth),
                    Sparkline = suppliersSparkline
                },
                MonthlyOrders = new AdminStatMetricDto
                {
                    Value = monthlyOrders,
                    ChangePercent = AdminMappings.PercentChange(monthlyOrders, monthlyOrdersPrev),
                    Sparkline = ordersSparkline
                },
                TotalSales = new AdminSalesMetricDto
                {
                    Value = monthlySales,
                    Formatted = AdminMappings.FormatAmount(monthlySales),
                    ChangePercent = salesGrowth,
                    Sparkline = salesSparkline
                }
            },
            MonthlyProfits = profitSeries,
            RecentOrders = recentOrders.Select(x =>
            {
                var lineTotal = decimal.Round(x.TotalPrice + x.VatAed, 2, MidpointRounding.AwayFromZero);
                var shippingAed = x.IsSelfPickup || x.PendingOrder?.IsSelfPickup == true
                    ? 0m
                    : x.ShippingCostAed > 0
                        ? x.ShippingCostAed
                        : x.PendingOrder?.ShippingCostAed ?? 0m;
                var grandTotal = decimal.Round(lineTotal + shippingAed, 2, MidpointRounding.AwayFromZero);
                return new AdminRecentOrderDto
                {
                    Id = x.Id,
                    CustomerName = x.FromUser?.FullName ?? "—",
                    SupplierName = x.ToUser?.CompanyName ?? x.ToUser?.FullName ?? "—",
                    StatusId = x.StatusId,
                    StatusName = OrderStatusCodes.GetNameEn(x.StatusId),
                    StatusLabelAr = AdminMappings.GetOrderStatusLabelAr(x.StatusId),
                    TotalPrice = grandTotal,
                    AmountFormatted = AdminMappings.FormatAmount(grandTotal),
                    CreatedAt = x.CreatedAt
                };
            }).ToList(),
            RecentUsers = recentUsers.Select(x => new AdminRecentUserDto
            {
                Id = x.Id,
                FullName = x.FullName,
                Email = x.Email,
                PhoneNumber = x.PhoneNumber,
                RoleName = AdminMappings.GetRoleName(x.RoleId, x.IsCustomer),
                RoleLabelAr = AdminMappings.GetRoleLabelAr(x.RoleId, x.IsCustomer),
                CreatedAt = x.CreatedAt,
                ImgPath = x.ImgPath
            }).ToList(),
            RecentActivity = activity,
            Summary = new AdminSummaryCountsDto
            {
                PendingCompanies = pendingCompanies,
                TotalProducts = totalProducts,
                TotalOffers = totalOffers,
                UnreadNotifications = notificationCount
            },
            Insights = new AdminDashboardInsightsDto
            {
                AvgOrderValue = avgOrderValue,
                AvgOrderValueFormatted = AdminMappings.FormatAmount(avgOrderValue),
                ConversionRate = conversionRate,
                PendingOrders = pendingOrders,
                GrowthRate = salesGrowth
            },
            SalesSummary = new AdminSalesSummaryDto
            {
                TotalSales = yearSales,
                TotalSalesFormatted = AdminMappings.FormatAmount(yearSales),
                ThisMonth = monthlySales,
                ThisMonthFormatted = AdminMappings.FormatAmount(monthlySales),
                GrowthPercent = salesGrowth
            }
        };
    }

    private static void ResolvePeriod(
        DateTime? createdFrom,
        DateTime? createdTo,
        DateTime utcNow,
        out DateTime periodStart,
        out DateTime periodEndExclusive,
        out DateTime prevPeriodStart,
        out DateTime prevPeriodEndExclusive)
    {
        var defaultMonthStart = new DateTime(utcNow.Year, utcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        if (!createdFrom.HasValue && !createdTo.HasValue)
        {
            periodStart = defaultMonthStart;
            periodEndExclusive = defaultMonthStart.AddMonths(1);
        }
        else
        {
            periodStart = createdFrom.HasValue
                ? DateTime.SpecifyKind(createdFrom.Value.Date, DateTimeKind.Utc)
                : defaultMonthStart;
            periodEndExclusive = createdTo.HasValue
                ? DateTime.SpecifyKind(createdTo.Value.Date.AddDays(1), DateTimeKind.Utc)
                : utcNow.Date.AddDays(1);

            if (periodEndExclusive <= periodStart)
            {
                periodEndExclusive = periodStart.AddDays(1);
            }
        }

        var length = periodEndExclusive - periodStart;
        prevPeriodEndExclusive = periodStart;
        prevPeriodStart = periodStart - length;
    }

    private async Task<List<AdminActivityItemDto>> BuildActivityFeedAsync(
        DateTime utcNow,
        CancellationToken cancellationToken)
    {
        var orderActivity = await AdminOrderVisibilityHelper.WhereVisibleInAdminDashboard(dbContext.Orders)
            .OrderByDescending(x => x.CreatedAt)
            .Take(6)
            .Select(x => new { x.Id, x.CreatedAt })
            .ToListAsync(cancellationToken);

        var userActivity = await dbContext.Users
            .OrderByDescending(x => x.CreatedAt)
            .Take(6)
            .Select(x => new { x.RoleId, x.CreatedAt })
            .ToListAsync(cancellationToken);

        var shippingActivity = await dbContext.InternationalShippingPosts
            .OrderByDescending(x => x.CreatedAt)
            .Take(4)
            .Select(x => new { x.Id, x.CreatedAt })
            .ToListAsync(cancellationToken);

        var approvalActivity = await dbContext.Users
            .Where(x => x.RoleId == 2 && x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .Take(4)
            .Select(x => new { x.Id, x.CreatedAt })
            .ToListAsync(cancellationToken);

        var offerActivity = await dbContext.OffersOnNegotiable
            .OrderByDescending(x => x.CreatedAt)
            .Take(4)
            .Select(x => new { x.Id, x.CreatedAt })
            .ToListAsync(cancellationToken);

        var profileEditActivity = await dbContext.Users
            .Where(x => x.PendingProfileChanges != null && x.PendingProfileChanges != string.Empty)
            .OrderByDescending(x => x.CreatedAt)
            .Take(4)
            .Select(x => new
            {
                x.Id,
                Title = x.CompanyName ?? x.FullName,
                x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var combined = orderActivity.Select(x => new AdminActivityItemDto
            {
                Type = "order",
                Title = $"طلب جديد #{x.Id}",
                CreatedAt = x.CreatedAt
            })
            .Concat(userActivity.Select(x => new AdminActivityItemDto
            {
                Type = "user",
                Title = x.RoleId == 2 ? "مستخدم جديد - مورد" : "مستخدم جديد",
                CreatedAt = x.CreatedAt
            }))
            .Concat(shippingActivity.Select(_ => new AdminActivityItemDto
            {
                Type = "shipping",
                Title = "طلب شحن",
                CreatedAt = _.CreatedAt
            }))
            .Concat(approvalActivity.Select(_ => new AdminActivityItemDto
            {
                Type = "approval",
                Title = "تمت الموافقة",
                CreatedAt = _.CreatedAt
            }))
            .Concat(offerActivity.Select(_ => new AdminActivityItemDto
            {
                Type = "update",
                Title = "تحديث طلب",
                CreatedAt = _.CreatedAt
            }))
            .Concat(profileEditActivity.Select(x => new AdminActivityItemDto
            {
                Type = "profileEdit",
                Title = $"طلب تعديل بيانات — {x.Title}",
                CreatedAt = x.CreatedAt
            }))
            .OrderByDescending(x => x.CreatedAt)
            .Take(12)
            .ToList();

        foreach (var item in combined)
        {
            item.TimeAgo = AdminMappings.GetTimeAgo(item.CreatedAt, utcNow);
        }

        return combined;
    }
}
