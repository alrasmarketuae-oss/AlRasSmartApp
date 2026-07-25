using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Caching;

public sealed class CategoryCommissionProvider(IServiceScopeFactory scopeFactory) : ICategoryCommissionProvider
{
    private readonly SemaphoreSlim _lock = new(1, 1);
    private IReadOnlyDictionary<byte, decimal>? _cached;

    public async Task<IReadOnlyDictionary<byte, decimal>> GetAsync(CancellationToken cancellationToken = default)
    {
        if (_cached is not null)
        {
            return _cached;
        }

        await _lock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_cached is not null)
            {
                return _cached;
            }

            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();
            var rows = await db.Categories
                .AsNoTracking()
                .Select(x => new { x.CategoryId, x.CommissionPercent })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            _cached = rows.ToDictionary(x => x.CategoryId, x => x.CommissionPercent);
            return _cached;
        }
        finally
        {
            _lock.Release();
        }
    }

    public void Invalidate()
    {
        _cached = null;
    }
}
