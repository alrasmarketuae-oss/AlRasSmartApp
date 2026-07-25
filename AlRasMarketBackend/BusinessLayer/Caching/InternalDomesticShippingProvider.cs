using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Caching;

/// <summary>
/// Permanent in-memory cache for UAE internal domestic shipping rates + excess kg rate.
/// Loaded once at startup; reads never hit the database; updates refresh cache in-place after DB write.
/// </summary>
public sealed class InternalDomesticShippingProvider(IServiceScopeFactory scopeFactory) : IInternalDomesticShippingProvider
{
    private readonly SemaphoreSlim _loadLock = new(1, 1);
    private readonly object _dataLock = new();
    private List<RateEntry>? _rates;
    private Dictionary<string, RateEntry>? _byNormalizedName;
    private byte _excessKgRateAed;

    public async Task EnsureLoadedAsync(CancellationToken cancellationToken = default)
    {
        if (_rates is not null)
        {
            return;
        }

        await _loadLock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_rates is not null)
            {
                return;
            }

            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();

            var rows = await db.InternalDomesticShippingRates
                .AsNoTracking()
                .OrderBy(x => x.Id)
                .Select(x => new RateEntry
                {
                    Id = x.Id,
                    EmirateNameEn = x.EmirateNameEn,
                    EmirateNameAr = x.EmirateNameAr,
                    PriceAed = x.PriceAed
                })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var excessRate = await db.InternalDomesticShippingConfigs
                .AsNoTracking()
                .Where(x => x.Id == 1)
                .Select(x => (byte?)x.ExcessKgRateAed)
                .FirstOrDefaultAsync(cancellationToken)
                .ConfigureAwait(false) ?? (byte)0;

            lock (_dataLock)
            {
                _rates = rows;
                _byNormalizedName = BuildLookup(rows);
                _excessKgRateAed = excessRate;
            }
        }
        finally
        {
            _loadLock.Release();
        }
    }

    public object GetAllRatesResponse()
    {
        lock (_dataLock)
        {
            EnsureLoadedOrThrow();

            var items = _rates!.Select(x => new InternalDomesticShippingRateDto
            {
                Id = x.Id,
                EmirateNameEn = x.EmirateNameEn,
                EmirateNameAr = x.EmirateNameAr,
                PriceAed = x.PriceAed
            }).ToList();

            return new
            {
                items,
                excessKgRateAed = _excessKgRateAed,
                freeWeightKg = (int)RetailDomesticShippingCalculator.FreeWeightKg
            };
        }
    }

    public object GetPriceByEmirateResponse(string emirateName)
    {
        if (string.IsNullOrWhiteSpace(emirateName))
        {
            throw new ArgumentException("Emirate name is required.");
        }

        var normalized = NormalizeName(emirateName);

        lock (_dataLock)
        {
            EnsureLoadedOrThrow();

            if (_byNormalizedName is null || !_byNormalizedName.TryGetValue(normalized, out var match))
            {
                var canonical = UaeEmirateResolver.ResolveCanonicalEnglishName(emirateName);
                if (canonical is null ||
                    !_byNormalizedName.TryGetValue(NormalizeName(canonical), out match))
                {
                    throw new KeyNotFoundException($"Emirate '{emirateName.Trim()}' was not found.");
                }
            }

            return new
            {
                id = match.Id,
                emirateNameEn = match.EmirateNameEn,
                emirateNameAr = match.EmirateNameAr,
                priceAed = match.PriceAed,
                excessKgRateAed = _excessKgRateAed,
                freeWeightKg = (int)RetailDomesticShippingCalculator.FreeWeightKg
            };
        }
    }

    public byte GetExcessKgRateAed()
    {
        lock (_dataLock)
        {
            EnsureLoadedOrThrow();
            return _excessKgRateAed;
        }
    }

    public void ApplyInMemoryUpdates(IReadOnlyList<(byte Id, decimal PriceAed)> updates)
    {
        if (updates.Count == 0)
        {
            return;
        }

        lock (_dataLock)
        {
            EnsureLoadedOrThrow();

            var byId = _rates!.ToDictionary(x => x.Id);
            foreach (var (id, priceAed) in updates)
            {
                if (!byId.TryGetValue(id, out var entry))
                {
                    throw new KeyNotFoundException($"Emirate id {id} was not found in cache.");
                }

                entry.PriceAed = priceAed;
            }
        }
    }

    public void ApplyExcessKgRateUpdate(byte excessKgRateAed)
    {
        lock (_dataLock)
        {
            EnsureLoadedOrThrow();
            _excessKgRateAed = excessKgRateAed;
        }
    }

    private void EnsureLoadedOrThrow()
    {
        if (_rates is null)
        {
            throw new InvalidOperationException("Internal domestic shipping rates are not loaded.");
        }
    }

    private static Dictionary<string, RateEntry> BuildLookup(IReadOnlyList<RateEntry> rates)
    {
        var lookup = new Dictionary<string, RateEntry>(StringComparer.OrdinalIgnoreCase);
        foreach (var rate in rates)
        {
            lookup[NormalizeName(rate.EmirateNameEn)] = rate;
            lookup[NormalizeName(rate.EmirateNameAr)] = rate;
        }

        return lookup;
    }

    private static string NormalizeName(string value) =>
        value.Trim().ToLowerInvariant();

    private sealed class RateEntry
    {
        public byte Id { get; set; }
        public string EmirateNameEn { get; set; } = string.Empty;
        public string EmirateNameAr { get; set; } = string.Empty;
        public decimal PriceAed { get; set; }
    }
}
