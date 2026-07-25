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

        await staticReferenceCache.EnsureLoadedAsync(cancellationToken);

        var city = staticReferenceCache.FindCityById(input.CityId)
            ?? throw new KeyNotFoundException("City not found.");

        var address = new Address
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            CityId = city.Id,
            AddressLine1 = input.AddressLine1.Trim(),
            AddressLine2 = string.IsNullOrWhiteSpace(input.AddressLine2) ? null : input.AddressLine2.Trim()
        };

        await dbContext.Addresses.AddAsync(address, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        UserAddressesCache.Bump(userId);

        var mapped = MapAddress(address);
        return new
        {
            addressId = address.Id,
            id = address.Id,
            userId = address.UserId,
            cityId = address.CityId,
            cityName = mapped.CityName,
            countryId = mapped.CountryId,
            countryNameEn = mapped.CountryNameEn,
            countryNameAr = mapped.CountryNameAr,
            addressLine1 = address.AddressLine1,
            addressLine2 = address.AddressLine2
        };
    }

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
