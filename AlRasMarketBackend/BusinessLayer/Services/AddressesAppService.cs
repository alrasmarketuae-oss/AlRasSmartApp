using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class AddressesAppService(
    IRasAlSouqDbContext dbContext,
    IStaticReferenceCache staticReferenceCache,
    IMemoryCache cache) : IAddressesAppService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(30);
    private const int CityNameMaxLength = 255;

    public async Task<object> GetByUserAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var cacheKey = BuildListCacheKey(parsedUserId);
        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var addresses = await dbContext.Addresses
            .AsNoTracking()
            .Where(x => x.UserId == parsedUserId)
            .OrderByDescending(x => x.Id)
            .ToListAsync(cancellationToken);

        var items = addresses.Select(MapAddress).ToList();
        var result = new { count = items.Count, items };
        cache.Set(cacheKey, result, CacheDuration);
        return result;
    }

    public async Task<object> AddAsync(AddAddressInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(input.AddressLine1))
        {
            throw new ArgumentException("AddressLine1 is required.");
        }

        var user = await dbContext.Users.FindAsync([userId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var city = await ResolveCityAsync(input.CityId, input.CountryId, input.CityName, cancellationToken);

        var address = new Address
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            CityId = city.CityId,
            AddressLine1 = input.AddressLine1.Trim(),
            AddressLine2 = string.IsNullOrWhiteSpace(input.AddressLine2) ? null : input.AddressLine2.Trim()
        };

        await dbContext.Addresses.AddAsync(address, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        UserAddressesCache.Bump(userId);

        return BuildAddressResponse(address, city);
    }

    public async Task<object> UpdateAsync(UpdateAddressInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        if (string.IsNullOrWhiteSpace(input.AddressLine1))
        {
            throw new ArgumentException("AddressLine1 is required.");
        }

        var address = await dbContext.Addresses
            .FirstOrDefaultAsync(x => x.Id == input.AddressId && x.UserId == userId, cancellationToken)
            ?? throw new KeyNotFoundException("Address not found.");

        var city = await ResolveCityAsync(input.CityId, input.CountryId, input.CityName, cancellationToken);

        address.CityId = city.CityId;
        address.AddressLine1 = input.AddressLine1.Trim();
        address.AddressLine2 = string.IsNullOrWhiteSpace(input.AddressLine2) ? null : input.AddressLine2.Trim();

        await dbContext.SaveChangesAsync(cancellationToken);

        UserAddressesCache.Bump(userId);

        return BuildAddressResponse(address, city);
    }

    public async Task DeleteAsync(string userId, Guid addressId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var address = await dbContext.Addresses
            .FirstOrDefaultAsync(x => x.Id == addressId && x.UserId == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("Address not found.");

        dbContext.Addresses.Remove(address);
        await dbContext.SaveChangesAsync(cancellationToken);

        UserAddressesCache.Bump(parsedUserId);
    }

    /// <summary>
    /// Accepts either a known city id or a country plus a typed city name. Outside the UAE the Cities
    /// table is sparse, so an unknown name is inserted for that country rather than rejected.
    /// </summary>
    private async Task<ResolvedCity> ResolveCityAsync(
        Guid? cityId,
        short? countryId,
        string? cityName,
        CancellationToken cancellationToken)
    {
        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        if (cityId.HasValue && cityId.Value != Guid.Empty)
        {
            var known = staticReferenceCache.FindCityById(cityId.Value);
            if (known is not null)
            {
                return ToResolvedCity(known.Id, known.CityName, known.CountryId);
            }
        }

        var trimmedName = cityName?.Trim();
        if (string.IsNullOrEmpty(trimmedName) || !countryId.HasValue)
        {
            throw new KeyNotFoundException("City not found.");
        }

        if (trimmedName.Length > CityNameMaxLength)
        {
            trimmedName = trimmedName[..CityNameMaxLength];
        }

        var country = staticReferenceCache.FindCountryById(countryId.Value)
            ?? throw new KeyNotFoundException("Country not found.");

        var cached = staticReferenceCache.FindCityByName(trimmedName, country.Id);
        if (cached is not null)
        {
            return ToResolvedCity(cached.Id, cached.CityName, cached.CountryId);
        }

        // The snapshot can lag behind another instance's insert, so confirm against SQL before adding.
        var existing = await dbContext.Cities
            .FirstOrDefaultAsync(
                x => x.CountryId == country.Id && x.CityName == trimmedName,
                cancellationToken);

        if (existing is not null)
        {
            return ToResolvedCity(existing.Id, existing.CityName, existing.CountryId);
        }

        var city = new City
        {
            Id = Guid.NewGuid(),
            CityName = trimmedName,
            CountryId = country.Id
        };

        await dbContext.Cities.AddAsync(city, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        // Built before invalidating so the response does not trigger a blocking reload.
        var resolved = new ResolvedCity(
            city.Id,
            city.CityName,
            country.Id,
            country.CountryNameEn,
            country.CountryNameAr);

        await staticReferenceCache.InvalidateGeoAsync(cancellationToken);
        return resolved;
    }

    private ResolvedCity ToResolvedCity(Guid cityId, string cityName, short countryId)
    {
        var country = staticReferenceCache.FindCountryById(countryId);
        return new ResolvedCity(cityId, cityName, countryId, country?.CountryNameEn, country?.CountryNameAr);
    }

    private static object BuildAddressResponse(Address address, ResolvedCity city) => new
    {
        addressId = address.Id,
        id = address.Id,
        userId = address.UserId,
        cityId = address.CityId,
        cityName = city.CityName,
        countryId = city.CountryId,
        countryNameEn = city.CountryNameEn,
        countryNameAr = city.CountryNameAr,
        addressLine1 = address.AddressLine1,
        addressLine2 = address.AddressLine2
    };

    private sealed record ResolvedCity(
        Guid CityId,
        string CityName,
        short CountryId,
        string? CountryNameEn,
        string? CountryNameAr);

    private AddressListItemDto MapAddress(Address address)
    {
        var city = staticReferenceCache.FindCityById(address.CityId);
        var country = city is null ? null : staticReferenceCache.FindCountryById(city.CountryId);

        return new AddressListItemDto
        {
            AddressId = address.Id,
            Id = address.Id,
            UserId = address.UserId,
            CityId = address.CityId,
            CityName = city?.CityName ?? string.Empty,
            CountryId = city?.CountryId,
            CountryNameEn = country?.CountryNameEn,
            CountryNameAr = country?.CountryNameAr,
            AddressLine1 = address.AddressLine1,
            AddressLine2 = address.AddressLine2
        };
    }

    private static string BuildListCacheKey(Guid userId) =>
        $"addresses:user:{userId:D}:v{UserAddressesCache.GetVersion(userId)}";
}
