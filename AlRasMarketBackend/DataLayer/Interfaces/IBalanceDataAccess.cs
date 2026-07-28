using DataLayer.Models;

namespace DataLayer.Interfaces;

public interface IBalanceDataAccess
{
    Task<bool> ExistsForOrderEntryAsync(
        long orderId,
        byte entryType,
        CancellationToken cancellationToken = default);

    Task<Balance?> GetForOrderEntryAsync(
        long orderId,
        byte entryType,
        CancellationToken cancellationToken = default);

    Task AddAsync(Balance entry, CancellationToken cancellationToken = default);

    Task<decimal> SumBalanceAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<List<Balance>> GetStatementAsync(
        Guid userId,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<int> CountStatementAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
