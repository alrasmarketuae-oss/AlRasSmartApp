using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Caching;

public sealed class CommissionSettingsProvider(IServiceScopeFactory scopeFactory) : ICommissionSettingsProvider
{
    private readonly SemaphoreSlim _lock = new(1, 1);
    private CommissionSettingsSnapshot? _cached;

    public async Task<CommissionSettingsSnapshot> GetAsync(CancellationToken cancellationToken = default)
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
            var row = await db.SystemSettings.AsNoTracking().FirstOrDefaultAsync(x => x.Id == 1, cancellationToken)
                .ConfigureAwait(false);

            _cached = row is null
                ? CommissionSettingsSnapshot.Empty
                : new CommissionSettingsSnapshot
                {
                    RetailCommissionPercent = row.RetailCommissionPercent,
                    BookingCommissionPercent = row.BookingCommissionPercent,
                    RequestsCommissionPercent = row.RequestsCommissionPercent,
                    OffersCommissionPercent = row.OffersCommissionPercent,
                    ShippingCommissionPercent = row.ShippingCommissionPercent
                };

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
