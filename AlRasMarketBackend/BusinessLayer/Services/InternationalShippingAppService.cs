using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class InternationalShippingAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache,
    IGeoReferenceCache geoReferenceCache,
    ICommissionSettingsProvider commissionSettingsProvider) : IInternationalShippingAppService
{
    private static readonly TimeSpan SearchCacheDuration = TimeSpan.FromMinutes(2);

    public async Task<object> CreatePostAsync(CreateInternationalShippingPostInput input, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.PublisherUserId, out var publisherUserId))
        {
            throw new ArgumentException("Invalid publisher user id.");
        }

        if (string.IsNullOrWhiteSpace(input.FromCountryName) ||
            string.IsNullOrWhiteSpace(input.FromPortName) ||
            string.IsNullOrWhiteSpace(input.ToCountryName) ||
            string.IsNullOrWhiteSpace(input.ToPortName) ||
            string.IsNullOrWhiteSpace(input.PhoneNumber))
        {
            throw new ArgumentException("From/To country, from/to port and phone number are required.");
        }

        input.Container20ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container20ftPriceUsd);
        input.Container40ftPriceUsd =
            CustomerPriceCalculator.NormalizeOptionalContainerPrice(input.Container40ftPriceUsd);

        if (input.ShippingCostUsd < 0)
        {
            throw new ArgumentException("Shipping cost cannot be negative.");
        }

        if (input.PriceUsd <= 0)
        {
            input.PriceUsd = CustomerPriceCalculator.ResolveShippingListPrice(
                input.Container20ftPriceUsd,
                input.Container40ftPriceUsd);
        }

        var publisher = await dbContext.Users.FindAsync([publisherUserId], cancellationToken)
            ?? throw new KeyNotFoundException("Publisher user not found.");

        if (publisher.RoleId != RoleIds.Seller && publisher.RoleId != RoleIds.ShippingCompany)
        {
            throw new UnauthorizedAccessException("Only suppliers or shipping companies can publish international shipping posts.");
        }

        await geoReferenceCache.EnsureLoadedAsync(cancellationToken);

        var fromCountry = geoReferenceCache.FindCountryByName(input.FromCountryName)
            ?? throw new KeyNotFoundException($"From country '{input.FromCountryName}' was not found.");

        var toCountry = geoReferenceCache.FindCountryByName(input.ToCountryName)
            ?? throw new KeyNotFoundException($"To country '{input.ToCountryName}' was not found.");

        var fromPort = geoReferenceCache.FindPortByName(input.FromPortName, fromCountry.Id)
            ?? throw new KeyNotFoundException($"From port '{input.FromPortName}' was not found for country '{input.FromCountryName}'.");

        var toPort = geoReferenceCache.FindPortByName(input.ToPortName, toCountry.Id)
            ?? throw new KeyNotFoundException($"To port '{input.ToPortName}' was not found for country '{input.ToCountryName}'.");

        var entity = new InternationalShippingPost
        {
            PublisherUserId = publisherUserId,
            FromCountryId = fromCountry.Id,
            FromPortId = fromPort.Id,
            ToCountryId = toCountry.Id,
            ToPortId = toPort.Id,
            PriceUsd = input.PriceUsd,
            ShippingCostUsd = input.ShippingCostUsd,
            PhoneNumber = input.PhoneNumber.Trim(),
            Container20ftPriceUsd = input.Container20ftPriceUsd,
            Container40ftPriceUsd = input.Container40ftPriceUsd,
            MinDurationDays = input.MinDurationDays,
            MaxDurationDays = input.MaxDurationDays,
            Details = string.IsNullOrWhiteSpace(input.Details) ? null : input.Details.Trim(),
            Status = publisher.RoleId == RoleIds.ShippingCompany
                ? ProductStatusCodes.UnderReview
                : ProductStatusCodes.Active,
            IsApproved = true
        };

        await dbContext.InternationalShippingPosts.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return new
        {
            entity.Id,
            fromCountry = fromCountry.CountryNameEn,
            fromCountryNameEn = fromCountry.CountryNameEn,
            fromCountryNameAr = fromCountry.CountryNameAr,
            fromPort = fromPort.PortNameEn,
            fromPortNameEn = fromPort.PortNameEn,
            fromPortNameAr = fromPort.PortNameAr,
            toCountry = toCountry.CountryNameEn,
            toCountryNameEn = toCountry.CountryNameEn,
            toCountryNameAr = toCountry.CountryNameAr,
            toPort = toPort.PortNameEn,
            toPortNameEn = toPort.PortNameEn,
            toPortNameAr = toPort.PortNameAr,
            entity.PriceUsd,
            entity.ShippingCostUsd,
            entity.PhoneNumber,
            entity.Container20ftPriceUsd,
            entity.Container40ftPriceUsd,
            entity.PublisherUserId
        };
    }

    public async Task<object> SearchAsync(SearchInternationalShippingInput input, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"shipping:search:{(input.FromCountryName ?? "").Trim().ToLowerInvariant()}|{(input.FromPortName ?? "").Trim().ToLowerInvariant()}|{(input.ToCountryName ?? "").Trim().ToLowerInvariant()}|{(input.ToPortName ?? "").Trim().ToLowerInvariant()}";
        if (cache.TryGetValue(cacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var query = dbContext.InternationalShippingPosts
            .Include(x => x.FromCountry)
            .Include(x => x.FromPort)
            .Include(x => x.ToCountry)
            .Include(x => x.ToPort)
            .Include(x => x.PublisherUser)
            .Where(x => x.IsApproved && x.Status == ProductStatusCodes.Active)
            .Where(x => x.PublisherUser != null && x.PublisherUser.IsActive)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(input.FromCountryName))
        {
            await geoReferenceCache.EnsureLoadedAsync(cancellationToken);
            var fromCountry = geoReferenceCache.FindCountryByName(input.FromCountryName);
            if (fromCountry is not null)
            {
                query = query.Where(x => x.FromCountryId == fromCountry.Id);
            }
            else
            {
                var value = input.FromCountryName.Trim().ToLower();
                query = query.Where(x => x.FromCountry != null
                    && (x.FromCountry.CountryNameEn.ToLower() == value
                        || (x.FromCountry.CountryNameAr != null && x.FromCountry.CountryNameAr.ToLower() == value)));
            }
        }
        if (!string.IsNullOrWhiteSpace(input.FromPortName))
        {
            var value = input.FromPortName.Trim().ToLower();
            query = query.Where(x => x.FromPort != null
                && (x.FromPort.PortNameEn.ToLower() == value
                    || (x.FromPort.PortNameAr != null && x.FromPort.PortNameAr.ToLower() == value)));
        }
        if (!string.IsNullOrWhiteSpace(input.ToCountryName))
        {
            await geoReferenceCache.EnsureLoadedAsync(cancellationToken);
            var toCountry = geoReferenceCache.FindCountryByName(input.ToCountryName);
            if (toCountry is not null)
            {
                query = query.Where(x => x.ToCountryId == toCountry.Id);
            }
            else
            {
                var value = input.ToCountryName.Trim().ToLower();
                query = query.Where(x => x.ToCountry != null
                    && (x.ToCountry.CountryNameEn.ToLower() == value
                        || (x.ToCountry.CountryNameAr != null && x.ToCountry.CountryNameAr.ToLower() == value)));
            }
        }
        if (!string.IsNullOrWhiteSpace(input.ToPortName))
        {
            var value = input.ToPortName.Trim().ToLower();
            query = query.Where(x => x.ToPort != null
                && (x.ToPort.PortNameEn.ToLower() == value
                    || (x.ToPort.PortNameAr != null && x.ToPort.PortNameAr.ToLower() == value)));
        }

        var commissionSettings = await commissionSettingsProvider.GetAsync(cancellationToken);

        var data = await query
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                fromCountry = x.FromCountry!.CountryNameEn,
                fromCountryNameEn = x.FromCountry.CountryNameEn,
                fromCountryNameAr = x.FromCountry.CountryNameAr,
                fromPort = x.FromPort!.PortNameEn,
                fromPortNameEn = x.FromPort.PortNameEn,
                fromPortNameAr = x.FromPort.PortNameAr,
                toCountry = x.ToCountry!.CountryNameEn,
                toCountryNameEn = x.ToCountry.CountryNameEn,
                toCountryNameAr = x.ToCountry.CountryNameAr,
                toPort = x.ToPort!.PortNameEn,
                toPortNameEn = x.ToPort.PortNameEn,
                toPortNameAr = x.ToPort.PortNameAr,
                x.PriceUsd,
                x.ShippingCostUsd,
                x.PhoneNumber,
                x.Container20ftPriceUsd,
                x.Container40ftPriceUsd,
                x.MinDurationDays,
                x.MaxDurationDays,
                x.Details,
                publisherUserId = x.PublisherUserId,
                publisherName = x.PublisherUser!.FullName,
                companyName = x.PublisherUser.CompanyName,
                publisherImgPath = x.PublisherUser.ImgPath,
                x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var response = data.Select(x => new
        {
            x.Id,
            x.fromCountry,
            x.fromCountryNameEn,
            x.fromCountryNameAr,
            x.fromPort,
            x.fromPortNameEn,
            x.fromPortNameAr,
            x.toCountry,
            x.toCountryNameEn,
            x.toCountryNameAr,
            x.toPort,
            x.toPortNameEn,
            x.toPortNameAr,
            priceUsd = CustomerPriceCalculator.ApplyShippingMarkup(x.PriceUsd, commissionSettings),
            shippingCostUsd = CustomerPriceCalculator.ApplyShippingMarkup(x.ShippingCostUsd, commissionSettings),
            x.PhoneNumber,
            container20ftPriceUsd = CustomerPriceCalculator.ApplyShippingMarkup(x.Container20ftPriceUsd, commissionSettings),
            container40ftPriceUsd = CustomerPriceCalculator.ApplyShippingMarkup(x.Container40ftPriceUsd, commissionSettings),
            minDurationDays = x.MinDurationDays,
            maxDurationDays = x.MaxDurationDays,
            details = x.Details ?? string.Empty,
            x.publisherUserId,
            publisherName = x.companyName ?? x.publisherName,
            publisherImgPath = x.publisherImgPath,
            x.CreatedAt
        }).ToList();

        cache.Set(cacheKey, response, SearchCacheDuration);
        return response;
    }

    public Task<object> GetPortsByCountryNameAsync(string countryName, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(countryName))
        {
            throw new ArgumentException("Country name is required.");
        }

        return GetPortsByCountryNameCoreAsync(countryName, cancellationToken);
    }

    private async Task<object> GetPortsByCountryNameCoreAsync(string countryName, CancellationToken cancellationToken)
    {
        await geoReferenceCache.EnsureLoadedAsync(cancellationToken);
        return geoReferenceCache.GetPortsByCountryNameResponse(countryName);
    }
}
