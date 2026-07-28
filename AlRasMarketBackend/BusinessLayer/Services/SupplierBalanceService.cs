using System.Text.Json;
using BusinessLayer.Caching;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services;

public interface ISupplierBalanceService
{
    /// <summary>Credit supplier after online retail payment (idempotent).</summary>
    Task TryCreditRetailOrderAsync(Order order, CancellationToken cancellationToken = default);

    /// <summary>Credit supplier when COD retail order is marked Received (idempotent).</summary>
    Task TryCreditRetailOrderOnReceivedAsync(Order order, CancellationToken cancellationToken = default);

    /// <summary>Debit supplier when a retail return is approved (idempotent).</summary>
    Task TryDebitRetailReturnAsync(Order order, CancellationToken cancellationToken = default);

    Task<decimal> GetBalanceAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<object> GetStatementAsync(
        Guid userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default);

    Task RecordManualWithdrawalAsync(
        Guid userId,
        decimal amount,
        string reasonEn,
        string reasonAr,
        string? referenceId = null,
        CancellationToken cancellationToken = default);
}

public sealed class SupplierBalanceService(
    IBalanceDataAccess balanceData,
    IRasAlSouqDbContext dbContext,
    ICommissionSettingsProvider commissionSettingsProvider,
    ITieredCache tieredCache,
    IFcmNotificationService fcmNotificationService,
    IServiceProvider serviceProvider,
    ILogger<SupplierBalanceService> logger) : ISupplierBalanceService
{
    private static readonly TimeSpan BalanceTtl = TimeSpan.FromMinutes(30);
    private static readonly TimeSpan StatementTtl = TimeSpan.FromMinutes(10);

    public Task TryCreditRetailOrderAsync(Order order, CancellationToken cancellationToken = default) =>
        CreditIfEligibleAsync(order, requireOnlinePayment: true, cancellationToken);

    public Task TryCreditRetailOrderOnReceivedAsync(Order order, CancellationToken cancellationToken = default) =>
        CreditIfEligibleAsync(order, requireOnlinePayment: false, cancellationToken);

    public async Task TryDebitRetailReturnAsync(Order order, CancellationToken cancellationToken = default)
    {
        if (!ProductTypeCodes.IsRetailOrder(order) || order.Id <= 0)
        {
            return;
        }

        if (await balanceData.ExistsForOrderEntryAsync(order.Id, BalanceEntryTypes.Withdrawal, cancellationToken))
        {
            return;
        }

        var deposit = await balanceData.GetForOrderEntryAsync(
            order.Id,
            BalanceEntryTypes.Deposit,
            cancellationToken);
        if (deposit is null || deposit.BalanceAmount <= 0)
        {
            return;
        }

        var debitAmount = decimal.Round(deposit.BalanceAmount, 2, MidpointRounding.AwayFromZero);
        var entry = new Balance
        {
            Id = NewBalanceId(),
            UserId = order.ToUserId,
            OrderId = order.Id,
            BalanceAmount = -debitAmount,
            EntryType = BalanceEntryTypes.Withdrawal,
            ReasonEn = $"Return approved — balance withdrawn for order #{order.Id}",
            ReasonAr = $"تم اعتماد الاسترجاع — سحب من الرصيد للطلب رقم {order.Id}",
            CreatedAtUtc = DateTime.UtcNow,
        };

        await balanceData.AddAsync(entry, cancellationToken);
        await balanceData.SaveChangesAsync(cancellationToken);
        SupplierBalanceCacheVersions.Bump(order.ToUserId);

        var newBalance = await GetBalanceAsync(order.ToUserId, cancellationToken);
        await NotifySupplierAsync(
            order.ToUserId,
            order.Id,
            isCredit: false,
            debitAmount,
            newBalance,
            cancellationToken);
    }

    public async Task<decimal> GetBalanceAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var cacheKey = BalanceCacheKey(userId);
        var cached = await tieredCache.GetAsync(cacheKey, cancellationToken);
        if (TryReadDecimal(cached, out var cachedBalance))
        {
            return cachedBalance;
        }

        var balance = await balanceData.SumBalanceAsync(userId, cancellationToken);
        await tieredCache.SetAsync(
            cacheKey,
            new SupplierBalanceCacheDto { Balance = balance },
            BalanceTtl,
            cancellationToken);
        return balance;
    }

    public async Task<object> GetStatementAsync(
        Guid userId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var cacheKey = StatementCacheKey(userId, page, pageSize);
        var cached = await tieredCache.GetAsync(cacheKey, cancellationToken);
        if (TryReadStatement(cached, out var cachedPayload))
        {
            return cachedPayload;
        }

        var skip = (page - 1) * pageSize;
        var totalCount = await balanceData.CountStatementAsync(userId, cancellationToken);
        var rows = await balanceData.GetStatementAsync(userId, skip, pageSize, cancellationToken);
        var balance = await GetBalanceAsync(userId, cancellationToken);

        var payload = new
        {
            balance,
            page,
            pageSize,
            totalCount,
            totalPages = totalCount == 0 ? 0 : (int)Math.Ceiling(totalCount / (double)pageSize),
            items = rows.Select(x => new
            {
                id = x.Id,
                orderId = x.OrderId,
                amount = x.BalanceAmount,
                entryType = x.EntryType,
                entryTypeNameEn = BalanceEntryTypes.ToNameEn(x.EntryType),
                entryTypeNameAr = BalanceEntryTypes.ToNameAr(x.EntryType),
                reasonEn = x.ReasonEn,
                reasonAr = x.ReasonAr,
                createdAtUtc = DateTime.SpecifyKind(x.CreatedAtUtc, DateTimeKind.Utc),
                source = "Al Ras Market"
            }).ToList()
        };

        await tieredCache.SetAsync(cacheKey, payload, StatementTtl, cancellationToken);
        return payload;
    }

    public async Task RecordManualWithdrawalAsync(
        Guid userId,
        decimal amount,
        string reasonEn,
        string reasonAr,
        string? referenceId = null,
        CancellationToken cancellationToken = default)
    {
        var normalizedAmount = decimal.Round(Math.Abs(amount), 2, MidpointRounding.AwayFromZero);
        if (normalizedAmount <= 0)
        {
            throw new ArgumentException("Withdrawal amount must be greater than zero.");
        }

        var entry = new Balance
        {
            Id = NewBalanceId(),
            UserId = userId,
            OrderId = null,
            BalanceAmount = -normalizedAmount,
            EntryType = BalanceEntryTypes.Withdrawal,
            ReasonEn = reasonEn,
            ReasonAr = reasonAr,
            CreatedAtUtc = DateTime.UtcNow,
        };

        await balanceData.AddAsync(entry, cancellationToken);
        await balanceData.SaveChangesAsync(cancellationToken);
        SupplierBalanceCacheVersions.Bump(userId);

        var newBalance = await GetBalanceAsync(userId, cancellationToken);
        await NotifySupplierAsync(
            userId,
            orderId: 0,
            isCredit: false,
            normalizedAmount,
            newBalance,
            cancellationToken,
            referenceId);
    }

    private async Task CreditIfEligibleAsync(
        Order order,
        bool requireOnlinePayment,
        CancellationToken cancellationToken)
    {
        if (!ProductTypeCodes.IsRetailOrder(order) || order.Id <= 0 || order.ToUserId == Guid.Empty)
        {
            return;
        }

        var isOnline = order.PaymentMethod == (byte)PaymentMethod.Online;
        if (requireOnlinePayment && !isOnline)
        {
            return;
        }

        if (!requireOnlinePayment && isOnline)
        {
            // Online orders are credited at payment time; Received must not double-credit.
            return;
        }

        if (await balanceData.ExistsForOrderEntryAsync(order.Id, BalanceEntryTypes.Deposit, cancellationToken))
        {
            return;
        }

        var settings = await commissionSettingsProvider.GetAsync(cancellationToken);
        var netAmount = CalculateSupplierNet(order.TotalPrice, settings.RetailCommissionPercent);
        if (netAmount <= 0)
        {
            return;
        }

        var entry = new Balance
        {
            Id = NewBalanceId(),
            UserId = order.ToUserId,
            OrderId = order.Id,
            BalanceAmount = netAmount,
            EntryType = BalanceEntryTypes.Deposit,
            ReasonEn = requireOnlinePayment
                ? $"Retail order paid online — deposit for order #{order.Id}"
                : $"Retail order received (COD) — deposit for order #{order.Id}",
            ReasonAr = requireOnlinePayment
                ? $"طلب تجزئة مدفوع إلكترونياً — إيداع للطلب رقم {order.Id}"
                : $"تم استلام طلب التجزئة (الدفع عند الاستلام) — إيداع للطلب رقم {order.Id}",
            CreatedAtUtc = DateTime.UtcNow,
        };

        try
        {
            await balanceData.AddAsync(entry, cancellationToken);
            await balanceData.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex)
        {
            // Unique (OrderId, EntryType) race — treat as already credited.
            logger.LogWarning(ex, "Balance deposit race for order {OrderId}; treating as already applied", order.Id);
            return;
        }

        SupplierBalanceCacheVersions.Bump(order.ToUserId);
        var newBalance = await GetBalanceAsync(order.ToUserId, cancellationToken);
        await NotifySupplierAsync(
            order.ToUserId,
            order.Id,
            isCredit: true,
            netAmount,
            newBalance,
            cancellationToken);
    }

    /// <summary>
    /// Customer prices store markup as base*(1+p/100). Reverse to supplier net.
    /// </summary>
    internal static decimal CalculateSupplierNet(decimal customerGoodsTotal, decimal retailCommissionPercent)
    {
        var goods = decimal.Round(customerGoodsTotal, 2, MidpointRounding.AwayFromZero);
        if (goods <= 0)
        {
            return 0m;
        }

        if (retailCommissionPercent <= 0)
        {
            return goods;
        }

        var divisor = 1m + (retailCommissionPercent / 100m);
        return decimal.Round(goods / divisor, 2, MidpointRounding.AwayFromZero);
    }

    private async Task NotifySupplierAsync(
        Guid supplierUserId,
        long orderId,
        bool isCredit,
        decimal amount,
        decimal newBalance,
        CancellationToken cancellationToken,
        string? referenceId = null)
    {
        try
        {
            var user = await dbContext.Users.AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == supplierUserId, cancellationToken);
            if (user is null)
            {
                return;
            }

            var amountText = amount.ToString("0.00");
            var balanceText = newBalance.ToString("0.00");
            var (titleEn, bodyEn) = isCredit
                ? (
                    "Balance increased",
                    $"AED {amountText} was added to your balance for order #{orderId}. Current balance: AED {balanceText}.")
                : (
                    "Balance decreased",
                    orderId > 0
                        ? $"AED {amountText} was deducted from your balance for returned order #{orderId}. Current balance: AED {balanceText}."
                        : $"AED {amountText} was deducted from your balance for your withdrawal request. Current balance: AED {balanceText}.");
            var (titleAr, bodyAr) = isCredit
                ? (
                    "زيادة في الرصيد",
                    $"تمت إضافة {amountText} درهم إلى رصيدك للطلب رقم {orderId}. الرصيد الحالي: {balanceText} درهم.")
                : (
                    "نقص في الرصيد",
                    orderId > 0
                        ? $"تم خصم {amountText} درهم من رصيدك بسبب استرجاع الطلب رقم {orderId}. الرصيد الحالي: {balanceText} درهم."
                        : $"تم خصم {amountText} درهم من رصيدك بعد تنفيذ طلب السحب. الرصيد الحالي: {balanceText} درهم.");

            var (title, body) = NotificationMessages.PickOptional(
                user.PreferredLanguage,
                titleEn,
                bodyEn,
                titleAr,
                bodyAr);

            var routeId = await GetOrCreateNotificationRouteIdAsync("supplier_balance", cancellationToken);
            var typeId = await GetOrCreateNotificationTypeIdAsync("balance", cancellationToken);

            await dbContext.Notifications.AddAsync(new Notification
            {
                Id = Guid.NewGuid(),
                Title = Truncate(titleEn, 255),
                TitleAr = Truncate(titleAr, 255),
                Body = Truncate(bodyEn, 1000),
                BodyAr = Truncate(bodyAr, 1000),
                FromUserId = supplierUserId,
                ToUserId = supplierUserId,
                TypeId = typeId,
                RouteId = routeId,
                ReferenceId = !string.IsNullOrWhiteSpace(referenceId) ? referenceId : orderId.ToString(),
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
            }, cancellationToken);
            await dbContext.SaveChangesAsync(cancellationToken);
            NotificationCacheVersions.Bump(supplierUserId);

            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                try
                {
                    var emailService = serviceProvider.GetRequiredService<IEmailService>();
                    await emailService.SendAsync(
                        user.Email,
                        title,
                        BrandEmailLayout.Headline(title) + BrandEmailLayout.Paragraph(body));
                }
                catch
                {
                    // best-effort
                }
            }

            if (!string.IsNullOrWhiteSpace(user.FcmToken))
            {
                try
                {
                    await fcmNotificationService.SendNotificationAsync(
                        user.FcmToken,
                        new FcmNotificationPayload
                        {
                            Title = title,
                            Body = body,
                            Data = new Dictionary<string, string>
                            {
                                ["type"] = isCredit ? "balance_credit" : "balance_debit",
                                ["route"] = "supplier_balance",
                                ["referenceId"] = !string.IsNullOrWhiteSpace(referenceId) ? referenceId : orderId.ToString(),
                                ["orderId"] = orderId.ToString(),
                            }
                        },
                        cancellationToken);
                }
                catch
                {
                    // best-effort
                }
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Failed to notify supplier {UserId} about balance change", supplierUserId);
        }
    }

    private async Task<Guid> GetOrCreateNotificationRouteIdAsync(string name, CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationRoutes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        var created = new NotificationRoute { Id = Guid.NewGuid(), Name = name };
        await dbContext.NotificationRoutes.AddAsync(created, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return created.Id;
    }

    private async Task<byte> GetOrCreateNotificationTypeIdAsync(string name, CancellationToken cancellationToken)
    {
        var existing = await dbContext.NotificationTypes.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Name == name, cancellationToken);
        if (existing is not null)
        {
            return existing.Id;
        }

        // Id is IDENTITY — do not set it explicitly (SQL error 544).
        var created = new NotificationType { Name = name };
        await dbContext.NotificationTypes.AddAsync(created, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return created.Id;
    }

    private static string NewBalanceId() => Guid.NewGuid().ToString("N");

    private static string BalanceCacheKey(Guid userId) =>
        $"supplier-balance:{userId:N}:v{SupplierBalanceCacheVersions.Current(userId)}";

    private static string StatementCacheKey(Guid userId, int page, int pageSize) =>
        $"supplier-balance-statement:{userId:N}:p{page}:s{pageSize}:v{SupplierBalanceCacheVersions.Current(userId)}";

    private static string Truncate(string value, int max) =>
        value.Length <= max ? value : value[..max];

    private static bool TryReadDecimal(object? cached, out decimal value)
    {
        value = 0m;
        if (cached is null)
        {
            return false;
        }

        if (cached is SupplierBalanceCacheDto dto)
        {
            value = dto.Balance;
            return true;
        }

        if (cached is JsonElement element)
        {
            if (element.ValueKind == JsonValueKind.Object
                && element.TryGetProperty("balance", out var balanceProp)
                && balanceProp.TryGetDecimal(out value))
            {
                return true;
            }
        }

        return false;
    }

    private static bool TryReadStatement(object? cached, out object payload)
    {
        payload = cached!;
        if (cached is null)
        {
            return false;
        }

        if (cached is JsonElement)
        {
            payload = cached;
            return true;
        }

        // In-memory object from previous SetAsync in this process.
        payload = cached;
        return true;
    }

    private sealed class SupplierBalanceCacheDto
    {
        public decimal Balance { get; set; }
    }
}
