using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class UserIbanAppService(IRasAlSouqDbContext dbContext) : IUserIbanAppService
{
    public async Task<object> GetMyIbansAsync(string userId, CancellationToken cancellationToken = default)
    {
        var parsedUserId = ParseUserId(userId);
        var items = await dbContext.UserIbans
            .AsNoTracking()
            .Where(x => x.UserId == parsedUserId)
            .OrderByDescending(x => x.IsDefault)
            .ThenByDescending(x => x.CreatedAtUtc)
            .Select(x => new
            {
                x.Id,
                x.Iban,
                x.AccountHolderName,
                x.BankName,
                x.IsDefault,
                createdAtUtc = DateTime.SpecifyKind(x.CreatedAtUtc, DateTimeKind.Utc)
            })
            .ToListAsync(cancellationToken);

        return new { items };
    }

    public async Task<object> AddMyIbanAsync(string userId, CreateUserIbanRequest input, CancellationToken cancellationToken = default)
    {
        var parsedUserId = ParseUserId(userId);
        var normalizedIban = NormalizeIban(input.Iban);
        if (string.IsNullOrWhiteSpace(normalizedIban) || normalizedIban.Length < 15 || normalizedIban.Length > 34)
        {
            throw new ArgumentException("Invalid IBAN.");
        }

        var exists = await dbContext.UserIbans.AnyAsync(
            x => x.UserId == parsedUserId && x.Iban == normalizedIban,
            cancellationToken);
        if (exists)
        {
            throw new InvalidOperationException("IBAN already exists.");
        }

        var shouldDefault = input.IsDefault || !await dbContext.UserIbans.AnyAsync(x => x.UserId == parsedUserId, cancellationToken);
        if (shouldDefault)
        {
            var currentDefaults = await dbContext.UserIbans
                .Where(x => x.UserId == parsedUserId && x.IsDefault)
                .ToListAsync(cancellationToken);
            foreach (var row in currentDefaults)
            {
                row.IsDefault = false;
            }
        }

        var entity = new UserIban
        {
            Id = Guid.NewGuid(),
            UserId = parsedUserId,
            Iban = normalizedIban,
            AccountHolderName = NormalizeOptional(input.AccountHolderName),
            BankName = NormalizeOptional(input.BankName),
            IsDefault = shouldDefault,
            CreatedAtUtc = DateTime.UtcNow
        };

        dbContext.UserIbans.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetMyIbansAsync(userId, cancellationToken);
    }

    internal static Guid ParseUserId(string userId) =>
        Guid.TryParse(userId, out var parsedUserId) ? parsedUserId : throw new ArgumentException("Invalid user id.");

    internal static string NormalizeIban(string? value) =>
        new string(
            (value ?? string.Empty)
                .Trim()
                .ToUpperInvariant()
                .Where(char.IsLetterOrDigit)
                .ToArray());

    internal static string? NormalizeOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}

public sealed class WithdrawalRequestsAppService(
    IRasAlSouqDbContext dbContext,
    ISupplierBalanceService supplierBalanceService) : IWithdrawalRequestsAppService
{
    public async Task<object> GetMyWithdrawalRequestsAsync(string userId, CancellationToken cancellationToken = default)
    {
        var parsedUserId = UserIbanAppService.ParseUserId(userId);
        var items = await dbContext.WithdrawalRequests
            .AsNoTracking()
            .Where(x => x.UserId == parsedUserId)
            .OrderByDescending(x => x.RequestedAtUtc)
            .Select(x => new
            {
                x.Id,
                x.Amount,
                x.StatusId,
                statusNameEn = WithdrawalRequestStatusCodes.ToNameEn(x.StatusId),
                statusNameAr = WithdrawalRequestStatusCodes.ToNameAr(x.StatusId),
                x.Notes,
                x.IbanSnapshot,
                x.AccountHolderNameSnapshot,
                x.BankNameSnapshot,
                requestedAtUtc = DateTime.SpecifyKind(x.RequestedAtUtc, DateTimeKind.Utc),
                completedAtUtc = x.CompletedAtUtc.HasValue ? (DateTime?)DateTime.SpecifyKind(x.CompletedAtUtc.Value, DateTimeKind.Utc) : null
            })
            .ToListAsync(cancellationToken);

        return new { items };
    }

    public async Task<object> CreateMyWithdrawalRequestAsync(string userId, CreateWithdrawalRequestInput input, CancellationToken cancellationToken = default)
    {
        var parsedUserId = UserIbanAppService.ParseUserId(userId);
        var amount = decimal.Round(input.Amount, 2, MidpointRounding.AwayFromZero);
        if (amount <= 0)
        {
            throw new ArgumentException("Withdrawal amount must be greater than zero.");
        }

        var iban = await dbContext.UserIbans
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == input.UserIbanId && x.UserId == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("IBAN not found.");

        var balance = await supplierBalanceService.GetBalanceAsync(parsedUserId, cancellationToken);
        var pendingTotal = await dbContext.WithdrawalRequests
            .AsNoTracking()
            .Where(x => x.UserId == parsedUserId && x.StatusId == WithdrawalRequestStatusCodes.Pending)
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

        var available = balance - pendingTotal;
        if (amount > available)
        {
            throw new InvalidOperationException("Withdrawal amount exceeds available balance.");
        }

        var entity = new WithdrawalRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = parsedUserId,
            UserIbanId = iban.Id,
            Amount = amount,
            StatusId = WithdrawalRequestStatusCodes.Pending,
            Notes = UserIbanAppService.NormalizeOptional(input.Notes),
            IbanSnapshot = iban.Iban,
            AccountHolderNameSnapshot = iban.AccountHolderName,
            BankNameSnapshot = iban.BankName,
            RequestedAtUtc = DateTime.UtcNow
        };

        dbContext.WithdrawalRequests.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetMyWithdrawalRequestsAsync(userId, cancellationToken);
    }
}

public sealed class AdminFinanceAppService(
    IRasAlSouqDbContext dbContext,
    ISupplierBalanceService supplierBalanceService,
    IAdminAuditLogAppService auditLogAppService) : IAdminFinanceAppService
{
    public async Task<object> GetWithdrawalRequestsAsync(AdminGetWithdrawalRequestsInput input, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, input.Page);
        var pageSize = Math.Clamp(input.PageSize, 1, 100);
        var query = dbContext.WithdrawalRequests
            .AsNoTracking()
            .Include(x => x.User)
            .Include(x => x.UserIban)
            .AsQueryable();

        if (input.StatusId.HasValue)
        {
            query = query.Where(x => x.StatusId == input.StatusId.Value);
        }

        if (!string.IsNullOrWhiteSpace(input.Search))
        {
            var term = input.Search.Trim();
            query = query.Where(x =>
                (x.User != null && (
                    x.User.FullName.Contains(term) ||
                    x.User.Email.Contains(term) ||
                    (x.User.CompanyName != null && x.User.CompanyName.Contains(term)))) ||
                x.IbanSnapshot.Contains(term));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(x => x.StatusId == WithdrawalRequestStatusCodes.Pending ? 0 : 1)
            .ThenByDescending(x => x.RequestedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new
            {
                x.Id,
                x.Amount,
                x.StatusId,
                statusNameEn = WithdrawalRequestStatusCodes.ToNameEn(x.StatusId),
                statusNameAr = WithdrawalRequestStatusCodes.ToNameAr(x.StatusId),
                supplierId = x.UserId,
                supplierName = x.User != null ? x.User.FullName : string.Empty,
                supplierCompanyName = x.User != null ? x.User.CompanyName : null,
                supplierEmail = x.User != null ? x.User.Email : null,
                supplierPhone = x.User != null ? x.User.PhoneNumber : null,
                x.IbanSnapshot,
                x.AccountHolderNameSnapshot,
                x.BankNameSnapshot,
                x.Notes,
                requestedAtUtc = DateTime.SpecifyKind(x.RequestedAtUtc, DateTimeKind.Utc),
                completedAtUtc = x.CompletedAtUtc.HasValue ? (DateTime?)DateTime.SpecifyKind(x.CompletedAtUtc.Value, DateTimeKind.Utc) : null
            })
            .ToListAsync(cancellationToken);

        return new
        {
            page,
            pageSize,
            totalCount,
            totalPages = totalCount == 0 ? 0 : (int)Math.Ceiling(totalCount / (double)pageSize),
            items
        };
    }

    public async Task<object> GetCompanyFinanceProfileAsync(string userId, CancellationToken cancellationToken = default)
    {
        var parsedUserId = UserIbanAppService.ParseUserId(userId);
        var user = await dbContext.Users
            .AsNoTracking()
            .Include(x => x.CompanyImages)
            .FirstOrDefaultAsync(x => x.Id == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var adsCount = await dbContext.Products.CountAsync(x => x.OwnerId == parsedUserId, cancellationToken);
        var balance = await supplierBalanceService.GetBalanceAsync(parsedUserId, cancellationToken);
        var ibans = await dbContext.UserIbans
            .AsNoTracking()
            .Where(x => x.UserId == parsedUserId)
            .OrderByDescending(x => x.IsDefault)
            .ThenByDescending(x => x.CreatedAtUtc)
            .Select(x => new
            {
                x.Id,
                x.Iban,
                x.AccountHolderName,
                x.BankName,
                x.IsDefault
            })
            .ToListAsync(cancellationToken);

        return new
        {
            userId = user.Id,
            fullName = user.FullName,
            companyName = user.CompanyName,
            email = user.Email,
            phoneNumber = user.PhoneNumber,
            landNumber = user.LandNumber,
            balance,
            adsCount,
            imgPath = WebRootFileHelper.NormalizeStoredPath(user.ImgPath),
            companyImage = user.CompanyImages
                .OrderByDescending(x => x.IsPrimary)
                .ThenByDescending(x => x.CreatedAt)
                .Select(x => WebRootFileHelper.NormalizeStoredPath(x.ImagePath))
                .FirstOrDefault(),
            ibans
        };
    }

    public async Task<object> GetCompanyBalanceStatementAsync(string userId, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var parsedUserId = UserIbanAppService.ParseUserId(userId);
        return await supplierBalanceService.GetStatementAsync(parsedUserId, page, pageSize, cancellationToken);
    }

    public async Task<object> MarkWithdrawalPaidAsync(
        string adminUserId,
        string withdrawalRequestId,
        AdminMarkWithdrawalPaidInput input,
        CancellationToken cancellationToken = default)
    {
        if (dbContext is not DbContext efContext)
        {
            throw new InvalidOperationException("Database context must support transactions.");
        }

        var parsedAdminId = UserIbanAppService.ParseUserId(adminUserId);
        var request = await dbContext.WithdrawalRequests
            .FirstOrDefaultAsync(x => x.Id == withdrawalRequestId, cancellationToken)
            ?? throw new KeyNotFoundException("Withdrawal request not found.");

        var reasonEn = $"Withdrawal request {request.Id} paid to IBAN {request.IbanSnapshot}";
        var reasonAr = $"تم تحويل طلب السحب {request.Id} إلى الآيبان {request.IbanSnapshot}";
        var hasLedgerWithdrawal = await HasWithdrawalLedgerEntryAsync(request.UserId, request.Id, cancellationToken);

        if (request.StatusId == WithdrawalRequestStatusCodes.Paid && hasLedgerWithdrawal)
        {
            return new
            {
                message = "Withdrawal request already marked as paid.",
                id = request.Id,
                completedAtUtc = request.CompletedAtUtc.HasValue
                    ? DateTime.SpecifyKind(request.CompletedAtUtc.Value, DateTimeKind.Utc)
                    : DateTime.SpecifyKind(DateTime.UtcNow, DateTimeKind.Utc)
            };
        }

        var balance = await supplierBalanceService.GetBalanceAsync(request.UserId, cancellationToken);
        if (request.Amount > balance)
        {
            throw new InvalidOperationException("Supplier balance is lower than the withdrawal amount.");
        }

        await using var transaction = await efContext.Database.BeginTransactionAsync(cancellationToken);
        request.StatusId = WithdrawalRequestStatusCodes.Paid;
        request.CompletedAtUtc ??= DateTime.UtcNow;
        request.CompletedByAdminUserId ??= parsedAdminId;
        if (!string.IsNullOrWhiteSpace(input.Notes) && string.IsNullOrWhiteSpace(request.Notes))
        {
            request.Notes = input.Notes.Trim();
        }

        if (!hasLedgerWithdrawal)
        {
            await supplierBalanceService.RecordManualWithdrawalAsync(
                request.UserId,
                request.Amount,
                reasonEn,
                reasonAr,
                request.Id,
                cancellationToken);
        }

        await auditLogAppService.WriteAsync(
            "finance.withdrawal_paid",
            "WithdrawalRequest",
            request.Id,
            $"Marked withdrawal request {request.Id} as paid.",
            new
            {
                request.UserId,
                request.Amount,
                request.IbanSnapshot,
                request.CompletedAtUtc,
                notes = request.Notes
            },
            cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return new
        {
            message = "Withdrawal request marked as paid.",
            id = request.Id,
            completedAtUtc = DateTime.SpecifyKind(request.CompletedAtUtc!.Value, DateTimeKind.Utc)
        };
    }

    private async Task<bool> HasWithdrawalLedgerEntryAsync(
        Guid userId,
        string withdrawalRequestId,
        CancellationToken cancellationToken)
    {
        return await dbContext.Balances
            .AsNoTracking()
            .AnyAsync(
                x => x.UserId == userId
                    && x.OrderId == null
                    && x.EntryType == BalanceEntryTypes.Withdrawal
                    && (
                        (x.ReasonEn != null && x.ReasonEn.Contains(withdrawalRequestId))
                        || (x.ReasonAr != null && x.ReasonAr.Contains(withdrawalRequestId))),
                cancellationToken);
    }
}
