using System.Text.Json;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BusinessLayer.Caching;

/// <summary>
/// In-memory reference data loaded once at application startup (countries, cities, ports, roles, units).
/// Countries/cities/ports are also mirrored to Redis for shared warm-start across instances.
/// </summary>
public sealed class StaticReferenceCache(
    IServiceScopeFactory scopeFactory,
    ITieredCache tieredCache) : IGeoReferenceCache
{
    private static readonly TimeSpan GeoRedisTtl = TimeSpan.FromHours(24);
    private const string CountriesKey = "geo:countries:v1";
    private const string CitiesKey = "geo:cities:v1";
    private const string PortsKey = "geo:ports:v1";

    private static readonly JsonSerializerOptions GeoJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly SemaphoreSlim _lock = new(1, 1);
    private ReferenceSnapshot? _snapshot;

    public async Task EnsureLoadedAsync(CancellationToken cancellationToken = default)
    {
        if (_snapshot is not null)
        {
            return;
        }

        await _lock.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            if (_snapshot is not null)
            {
                return;
            }

            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<IRasAlSouqDbContext>();

            var countries = await TryReadGeoListAsync<GeoCountrySnapshot>(CountriesKey, cancellationToken)
                .ConfigureAwait(false);
            var ports = await TryReadGeoListAsync<GeoPortSnapshot>(PortsKey, cancellationToken)
                .ConfigureAwait(false);
            var cities = await TryReadGeoListAsync<GeoCitySnapshot>(CitiesKey, cancellationToken)
                .ConfigureAwait(false);

            var loadedGeoFromRedis = countries is { Count: > 0 }
                && ports is not null
                && cities is not null;

            if (!loadedGeoFromRedis)
            {
                countries = await db.Countries
                    .AsNoTracking()
                    .OrderBy(x => x.CountryNameEn)
                    .Select(x => new GeoCountrySnapshot
                    {
                        Id = x.Id,
                        CountryNameEn = x.CountryNameEn,
                        CountryNameAr = x.CountryNameAr,
                        Iso2Code = x.Iso2Code
                    })
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                ports = await db.Ports
                    .AsNoTracking()
                    .OrderBy(x => x.PortNameEn)
                    .Select(x => new GeoPortSnapshot
                    {
                        Id = x.Id,
                        CountryId = x.CountryId,
                        PortNameEn = x.PortNameEn,
                        PortNameAr = x.PortNameAr,
                        UnLocode = x.UnLocode
                    })
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                cities = await db.Cities
                    .AsNoTracking()
                    .OrderBy(x => x.CityName)
                    .Select(x => new GeoCitySnapshot
                    {
                        Id = x.Id,
                        CityName = x.CityName,
                        CountryId = x.CountryId
                    })
                    .ToListAsync(cancellationToken)
                    .ConfigureAwait(false);

                await MirrorGeoToRedisAsync(countries, cities, ports, cancellationToken).ConfigureAwait(false);
            }

            var roles = await db.Roles
                .AsNoTracking()
                .OrderBy(x => x.Id)
                .Select(x => new RoleSnapshot
                {
                    Id = x.Id,
                    RoleName = x.RoleName
                })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            var units = await db.Units
                .AsNoTracking()
                .OrderBy(x => x.Id)
                .Select(x => new UnitSnapshot
                {
                    Id = x.Id,
                    UnitNameEn = x.UnitNameEn
                })
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);

            _snapshot = ReferenceSnapshot.Build(countries!, ports!, cities!, roles, units);
        }
        finally
        {
            _lock.Release();
        }
    }

    private async Task<List<T>?> TryReadGeoListAsync<T>(string key, CancellationToken cancellationToken)
    {
        var cached = await tieredCache.GetAsync(key, cancellationToken).ConfigureAwait(false);
        if (cached is null)
        {
            return null;
        }

        if (cached is List<T> list)
        {
            return list;
        }

        if (cached is IReadOnlyList<T> readOnly)
        {
            return readOnly.ToList();
        }

        if (cached is JsonElement element)
        {
            try
            {
                return element.Deserialize<List<T>>(GeoJsonOptions);
            }
            catch
            {
                return null;
            }
        }

        return null;
    }

    private async Task MirrorGeoToRedisAsync(
        IReadOnlyList<GeoCountrySnapshot> countries,
        IReadOnlyList<GeoCitySnapshot> cities,
        IReadOnlyList<GeoPortSnapshot> ports,
        CancellationToken cancellationToken)
    {
        try
        {
            await tieredCache.SetAsync(CountriesKey, countries, GeoRedisTtl, cancellationToken).ConfigureAwait(false);
            await tieredCache.SetAsync(CitiesKey, cities, GeoRedisTtl, cancellationToken).ConfigureAwait(false);
            await tieredCache.SetAsync(PortsKey, ports, GeoRedisTtl, cancellationToken).ConfigureAwait(false);
        }
        catch
        {
            // Best-effort mirror; memory snapshot remains authoritative for this instance.
        }
    }

    public IReadOnlyList<GeoCountrySnapshot> GetCountries()
    {
        EnsureLoaded();
        return _snapshot!.Countries;
    }

    public GeoCountrySnapshot? FindCountryById(short id)
    {
        EnsureLoaded();
        return _snapshot!.CountriesById.TryGetValue(id, out var country) ? country : null;
    }

    public GeoCountrySnapshot? FindCountryByEnglishName(string countryName)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(countryName))
        {
            return null;
        }

        return _snapshot!.CountriesByName.TryGetValue(countryName.Trim(), out var country)
            ? country
            : null;
    }

    public GeoCountrySnapshot? FindCountryByName(string countryName)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(countryName))
        {
            return null;
        }

        var trimmed = countryName.Trim();
        if (_snapshot!.CountriesByName.TryGetValue(trimmed, out var byEnglishName))
        {
            return byEnglishName;
        }

        return _snapshot.Countries.FirstOrDefault(country =>
            (!string.IsNullOrWhiteSpace(country.CountryNameAr)
             && country.CountryNameAr.Equals(trimmed, StringComparison.OrdinalIgnoreCase))
            || country.Iso2Code.Equals(trimmed, StringComparison.OrdinalIgnoreCase));
    }

    public IReadOnlyList<GeoPortSnapshot> GetPortsByCountryId(short countryId)
    {
        EnsureLoaded();
        return _snapshot!.PortsByCountry.TryGetValue(countryId, out var ports)
            ? ports
            : Array.Empty<GeoPortSnapshot>();
    }

    public GeoPortSnapshot? FindPortById(int id)
    {
        EnsureLoaded();
        return _snapshot!.PortsById.TryGetValue(id, out var port) ? port : null;
    }

    public GeoPortSnapshot? FindPortByEnglishName(string portName, short countryId)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(portName))
        {
            return null;
        }

        var key = BuildPortKey(countryId, portName);
        return _snapshot!.PortsByCountryAndName.TryGetValue(key, out var port) ? port : null;
    }

    public GeoPortSnapshot? FindPortByName(string portName, short countryId)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(portName))
        {
            return null;
        }

        var byEnglish = FindPortByEnglishName(portName, countryId);
        if (byEnglish is not null)
        {
            return byEnglish;
        }

        var trimmed = portName.Trim();
        return GetPortsByCountryId(countryId).FirstOrDefault(port =>
            !string.IsNullOrWhiteSpace(port.PortNameAr)
            && port.PortNameAr.Equals(trimmed, StringComparison.OrdinalIgnoreCase));
    }

    public GeoPortSnapshot? FindPortByEnglishName(string portName, IReadOnlyCollection<int> allowedPortIds)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(portName) || allowedPortIds.Count == 0)
        {
            return null;
        }

        var normalized = portName.Trim();
        return allowedPortIds
            .Select(FindPortById)
            .FirstOrDefault(port =>
                port is not null
                && (port.PortNameEn.Equals(normalized, StringComparison.OrdinalIgnoreCase)
                    || (!string.IsNullOrWhiteSpace(port.PortNameAr)
                        && port.PortNameAr.Equals(normalized, StringComparison.OrdinalIgnoreCase))));
    }

    public GeoPortSnapshot? FindPortByEnglishName(string portName)
    {
        return FindPortByName(portName);
    }

    public GeoPortSnapshot? FindPortByName(string portName)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(portName))
        {
            return null;
        }

        var trimmed = portName.Trim();
        if (_snapshot!.PortsByName.TryGetValue(trimmed, out var byEnglishName))
        {
            return byEnglishName;
        }

        return _snapshot.PortsById.Values.FirstOrDefault(port =>
            !string.IsNullOrWhiteSpace(port.PortNameAr)
            && port.PortNameAr.Equals(trimmed, StringComparison.OrdinalIgnoreCase));
    }

    public object GetPortsByCountryNameResponse(string countryName)
    {
        var country = FindCountryByName(countryName)
            ?? throw new KeyNotFoundException($"Country '{countryName}' was not found.");

        var ports = GetPortsByCountryId(country.Id)
            .Select(x => new
            {
                x.Id,
                portNameEn = x.PortNameEn,
                portNameAr = x.PortNameAr,
                x.UnLocode
            })
            .ToList();

        return new
        {
            countryId = country.Id,
            country = country.CountryNameEn,
            countryNameEn = country.CountryNameEn,
            countryNameAr = country.CountryNameAr,
            ports
        };
    }

    public object GetCitiesByCountryNameResponse(string countryName)
    {
        var country = FindCountryByName(countryName)
            ?? throw new KeyNotFoundException($"Country '{countryName}' was not found.");

        return BuildCitiesByCountryResponse(country);
    }

    public object GetCitiesByCountryIdResponse(short countryId)
    {
        var country = FindCountryById(countryId)
            ?? throw new KeyNotFoundException($"Country id '{countryId}' was not found.");

        return BuildCitiesByCountryResponse(country);
    }

    private object BuildCitiesByCountryResponse(GeoCountrySnapshot country)
    {
        var cities = GetCitiesByCountryId(country.Id)
            .Select(x => new
            {
                id = x.Id,
                cityId = x.Id,
                cityName = x.CityName,
                countryId = x.CountryId
            })
            .ToList();

        return new
        {
            countryId = country.Id,
            countryNameEn = country.CountryNameEn,
            countryNameAr = country.CountryNameAr,
            count = cities.Count,
            items = cities
        };
    }

    public IReadOnlyList<GeoCitySnapshot> GetCities()
    {
        EnsureLoaded();
        return _snapshot!.Cities;
    }

    public IReadOnlyList<GeoCitySnapshot> GetCitiesByCountryId(short countryId)
    {
        EnsureLoaded();
        return _snapshot!.CitiesByCountry.TryGetValue(countryId, out var cities)
            ? cities
            : Array.Empty<GeoCitySnapshot>();
    }

    public GeoCitySnapshot? FindCityById(Guid id)
    {
        EnsureLoaded();
        return _snapshot!.CitiesById.TryGetValue(id, out var city) ? city : null;
    }

    public GeoCitySnapshot? FindCityByName(string cityName)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(cityName))
        {
            return null;
        }

        return _snapshot!.CitiesByName.TryGetValue(cityName.Trim(), out var city) ? city : null;
    }

    public IReadOnlyList<RoleSnapshot> GetRoles()
    {
        EnsureLoaded();
        return _snapshot!.Roles;
    }

    public RoleSnapshot? FindRoleById(byte id)
    {
        EnsureLoaded();
        return _snapshot!.RolesById.TryGetValue(id, out var role) ? role : null;
    }

    public IReadOnlyList<UnitSnapshot> GetUnits()
    {
        EnsureLoaded();
        return _snapshot!.Units;
    }

    public UnitSnapshot? FindUnitById(byte id)
    {
        EnsureLoaded();
        return _snapshot!.UnitsById.TryGetValue(id, out var unit) ? unit : null;
    }

    public UnitSnapshot? FindUnitByName(string unitNameEn)
    {
        EnsureLoaded();
        if (string.IsNullOrWhiteSpace(unitNameEn))
        {
            return null;
        }

        var trimmed = unitNameEn.Trim();
        var normalized = NormalizeUnitName(trimmed);

        if (_snapshot!.UnitsByName.TryGetValue(normalized, out var unit))
        {
            return unit;
        }

        if (_snapshot.UnitsByName.TryGetValue(trimmed, out unit))
        {
            return unit;
        }

        // Last resort: scan (handles odd DB casing / spacing).
        return _snapshot.Units.FirstOrDefault(x =>
            string.Equals(NormalizeUnitName(x.UnitNameEn), normalized, StringComparison.OrdinalIgnoreCase));
    }

    /// <summary>
    /// Maps common UI aliases (Kg/kg) to canonical Units.UnitNameEn values in DB.
    /// </summary>
    internal static string NormalizeUnitName(string unitNameEn)
    {
        var trimmed = unitNameEn.Trim();
        return trimmed.ToLowerInvariant() switch
        {
            "ton" or "tons" or "tonne" or "tonnes" or "طن" or "اطنان" or "أطنان" => "Ton",
            "pcs" or "pc" or "piece" or "pieces" or "قطعة" or "قطع" => "Piece",
            "carton" or "cartons" or "كرتون" => "Carton",
            "bag" or "bags" or "كيس" or "أكياس" or "اكياس" => "Bag",
            "dozen" or "dozens" or "دزينة" => "Dozen",
            "box" or "boxes" or "صندوق" or "صناديق" => "Box",
            "kg" or "kgs" or "kilo" or "kilos" or "كجم" or "كيلو" or "كيلوجرام" or "كيلو جرام" => "Kilogram",
            "kilogram" or "kilograms" => "Kilogram",
            "g" or "gram" or "grams" or "جرام" or "غرام" => "Gram",
            _ => trimmed
        };
    }

    private static IEnumerable<string> UnitAliases(string canonicalUnitNameEn)
    {
        return NormalizeUnitName(canonicalUnitNameEn).ToLowerInvariant() switch
        {
            "kilogram" => ["Kg", "kg", "kgs", "kilo", "kilos", "Kilogram", "kilograms"],
            "gram" => ["g", "G", "gram", "grams", "Gram"],
            "ton" => ["ton", "tons", "tonne", "tonnes", "Ton"],
            "piece" => ["pc", "pcs", "piece", "pieces", "Piece"],
            "carton" => ["carton", "cartons", "Carton"],
            "bag" => ["bag", "bags", "Bag"],
            "dozen" => ["dozen", "dozens", "Dozen"],
            "box" => ["box", "boxes", "Box"],
            _ => []
        };
    }

    private void EnsureLoaded()
    {
        if (_snapshot is null)
        {
            throw new InvalidOperationException("Static reference cache is not loaded yet.");
        }
    }

    private static string BuildPortKey(short countryId, string portName) =>
        $"{countryId}:{portName.Trim().ToLowerInvariant()}";

    /// <summary>First row wins when reference data has duplicate natural keys (e.g. two "Aberdeen" ports).</summary>
    private static Dictionary<TKey, TSource> IndexByKey<TSource, TKey>(
        IEnumerable<TSource> source,
        Func<TSource, TKey> keySelector,
        IEqualityComparer<TKey>? comparer = null)
        where TKey : notnull
    {
        comparer ??= EqualityComparer<TKey>.Default;
        return source
            .GroupBy(keySelector, comparer)
            .ToDictionary(g => g.Key, g => g.First(), comparer);
    }

    private sealed class ReferenceSnapshot
    {
        public required IReadOnlyList<GeoCountrySnapshot> Countries { get; init; }
        public required Dictionary<short, GeoCountrySnapshot> CountriesById { get; init; }
        public required Dictionary<string, GeoCountrySnapshot> CountriesByName { get; init; }
        public required Dictionary<short, IReadOnlyList<GeoPortSnapshot>> PortsByCountry { get; init; }
        public required Dictionary<int, GeoPortSnapshot> PortsById { get; init; }
        public required Dictionary<string, GeoPortSnapshot> PortsByCountryAndName { get; init; }
        public required Dictionary<string, GeoPortSnapshot> PortsByName { get; init; }
        public required IReadOnlyList<GeoCitySnapshot> Cities { get; init; }
        public required Dictionary<Guid, GeoCitySnapshot> CitiesById { get; init; }
        public required Dictionary<string, GeoCitySnapshot> CitiesByName { get; init; }
        public required Dictionary<short, IReadOnlyList<GeoCitySnapshot>> CitiesByCountry { get; init; }
        public required IReadOnlyList<RoleSnapshot> Roles { get; init; }
        public required Dictionary<byte, RoleSnapshot> RolesById { get; init; }
        public required IReadOnlyList<UnitSnapshot> Units { get; init; }
        public required Dictionary<byte, UnitSnapshot> UnitsById { get; init; }
        public required Dictionary<string, UnitSnapshot> UnitsByName { get; init; }

        public static ReferenceSnapshot Build(
            IReadOnlyList<GeoCountrySnapshot> countries,
            IReadOnlyList<GeoPortSnapshot> ports,
            IReadOnlyList<GeoCitySnapshot> cities,
            IReadOnlyList<RoleSnapshot> roles,
            IReadOnlyList<UnitSnapshot> units)
        {
            var countriesById = countries.ToDictionary(x => x.Id);
            var countriesByName = IndexByKey(
                countries,
                x => x.CountryNameEn.Trim(),
                StringComparer.OrdinalIgnoreCase);

            var portsByCountry = ports
                .GroupBy(x => x.CountryId)
                .ToDictionary(g => g.Key, g => (IReadOnlyList<GeoPortSnapshot>)g.ToList());
            var portsById = ports.ToDictionary(x => x.Id);
            var portsByCountryAndName = IndexByKey(
                ports,
                x => BuildPortKey(x.CountryId, x.PortNameEn));
            var portsByName = IndexByKey(
                ports,
                x => x.PortNameEn.Trim(),
                StringComparer.OrdinalIgnoreCase);

            var citiesById = cities.ToDictionary(x => x.Id);
            var citiesByName = IndexByKey(
                cities,
                x => x.CityName.Trim(),
                StringComparer.OrdinalIgnoreCase);
            var citiesByCountry = cities
                .GroupBy(x => x.CountryId)
                .ToDictionary(g => g.Key, g => (IReadOnlyList<GeoCitySnapshot>)g.ToList());

            var rolesById = roles.ToDictionary(x => x.Id);
            var unitsById = units.ToDictionary(x => x.Id);
            var unitsByName = new Dictionary<string, UnitSnapshot>(StringComparer.OrdinalIgnoreCase);
            foreach (var unit in units)
            {
                var canonical = unit.UnitNameEn.Trim();
                unitsByName[canonical] = unit;
                unitsByName[NormalizeUnitName(canonical)] = unit;
                foreach (var alias in UnitAliases(canonical))
                {
                    unitsByName[alias] = unit;
                }
            }

            return new ReferenceSnapshot
            {
                Countries = countries,
                CountriesById = countriesById,
                CountriesByName = countriesByName,
                PortsByCountry = portsByCountry,
                PortsById = portsById,
                PortsByCountryAndName = portsByCountryAndName,
                PortsByName = portsByName,
                Cities = cities,
                CitiesById = citiesById,
                CitiesByName = citiesByName,
                CitiesByCountry = citiesByCountry,
                Roles = roles,
                RolesById = rolesById,
                Units = units,
                UnitsById = unitsById,
                UnitsByName = unitsByName
            };
        }
    }
}
