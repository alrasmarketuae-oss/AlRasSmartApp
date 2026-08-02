using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace DataLayer.Repositories;

public sealed class BalanceDataAccess(IRasAlSouqDbContext dbContext) : IBalanceDataAccess
{
    public Task<bool> ExistsForOrderEntryAsync(
        long orderId,
        byte entryType,
        CancellationToken cancellationToken = default) =>
        dbContext.Balances.AsNoTracking()
            .AnyAsync(x => x.OrderId == orderId && x.EntryType == entryType, cancellationToken);

    public Task<Balance?> GetForOrderEntryAsync(
        long orderId,
        byte entryType,
        CancellationToken cancellationToken = default) =>
        dbContext.Balances.AsNoTracking()
            .FirstOrDefaultAsync(x => x.OrderId == orderId && x.EntryType == entryType, cancellationToken);

    public async Task AddAsync(Balance entry, CancellationToken cancellationToken = default) =>
        await dbContext.Balances.AddAsync(entry, cancellationToken);

    public async Task<decimal> SumBalanceAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var sum = await dbContext.Balances.AsNoTracking()
            .Where(x => x.UserId == userId)
            .SumAsync(x => (decimal?)x.BalanceAmount, cancellationToken);
        return sum ?? 0m;
    }

    public Task<List<Balance>> GetStatementAsync(
        Guid userId,
        int skip,
        int take,
        byte? entryType = null,
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.Balances.AsNoTracking()
            .Where(x => x.UserId == userId);
        if (entryType.HasValue)
        {
            query = query.Where(x => x.EntryType == entryType.Value);
        }

        return query
            .OrderByDescending(x => x.CreatedAtUtc)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);
    }

    public Task<int> CountStatementAsync(
        Guid userId,
        byte? entryType = null,
        CancellationToken cancellationToken = default)
    {
        var query = dbContext.Balances.AsNoTracking()
            .Where(x => x.UserId == userId);
        if (entryType.HasValue)
        {
            query = query.Where(x => x.EntryType == entryType.Value);
        }

        return query.CountAsync(cancellationToken);
    }

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        dbContext.SaveChangesAsync(cancellationToken);
}
