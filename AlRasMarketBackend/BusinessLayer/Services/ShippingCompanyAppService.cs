using BusinessLayer.Constants;
using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class ShippingCompanyAppService(
    IRasAlSouqDbContext dbContext,
    IGeoReferenceCache geoReferenceCache,
    IMemoryCache cache,
    IAdminRealtimeNotificationService adminRealtimeNotificationService) : IShippingCompanyAppService
{
    public async Task<object> GetDashboardAsync(string userId, CancellationToken cancellationToken = default)
    {
        var user = await RequireShippingCompanyAsync(userId, cancellationToken);
        var posts = await LoadOwnedPostsAsync(user.Id, cancellationToken);
        var stats = BuildStats(posts);

        return new
        {
            companyName = user.CompanyName ?? user.FullName,
            imgPath = user.ImgPath,
            email = user.Email,
            phoneNumber = user.PhoneNumber,
            commercialRegister = user.CommercialRegister,
            taxNumber = user.TaxNumber,
            website = user.Website,
            stats,
            posts = posts.Select(MapPost).ToList()
        };
    }

    public async Task<object> GetMyPostsAsync(string userId, CancellationToken cancellationToken = default)
    {
        var user = await RequireShippingCompanyAsync(userId, cancellationToken);
        var posts = await LoadOwnedPostsAsync(user.Id, cancellationToken);
        return posts.Select(MapPost).ToList();
    }

    public async Task<object> CreatePostAsync(
        string userId,
        CreateInternationalShippingPostInput input,
        CancellationToken cancellationToken = default)
    {
        var user = await RequireShippingCompanyAsync(userId, cancellationToken);
        EnsureApproved(user);

        input.PublisherUserId = user.Id.ToString();
        ValidatePostInput(input);

        await geoReferenceCache.EnsureLoadedAsync(cancellationToken);
        var route = ResolveRoute(input);

        var entity = new InternationalShippingPost
        {
            PublisherUserId = user.Id,
            FromCountryId = route.FromCountryId,
            FromPortId = route.FromPortId,
            ToCountryId = route.ToCountryId,
            ToPortId = route.ToPortId,
            PriceUsd = input.Container20ftPriceUsd,
            ShippingCostUsd = 0,
            PhoneNumber = input.PhoneNumber.Trim(),
            Container20ftPriceUsd = input.Container20ftPriceUsd,
            Container40ftPriceUsd = input.Container40ftPriceUsd,
            MinDurationDays = input.MinDurationDays,
            MaxDurationDays = input.MaxDurationDays,
            Details = string.IsNullOrWhiteSpace(input.Details) ? null : input.Details.Trim(),
            Status = ProductStatusCodes.UnderReview,
            IsApproved = false
        };

        await dbContext.InternationalShippingPosts.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateSearchCache();

        await adminRealtimeNotificationService.NotifyNewShippingPostAsync(
            entity,
            user.CompanyName ?? user.FullName,
            user.Id.ToString(),
            cancellationToken);

        return MapPost(entity, route);
    }

    public async Task<object> UpdatePostAsync(
        UpdateInternationalShippingPostInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(input.UserId, out var userId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await RequireShippingCompanyAsync(input.UserId, cancellationToken);
        EnsureApproved(user);

        var post = await dbContext.InternationalShippingPosts
            .FirstOrDefaultAsync(x => x.Id == input.PostId && x.PublisherUserId == userId, cancellationToken)
            ?? throw new KeyNotFoundException("Shipping post not found.");

        ValidateUpdateInput(input);
        await geoReferenceCache.EnsureLoadedAsync(cancellationToken);
        var route = ResolveRoute(new CreateInternationalShippingPostInput
        {
            FromCountryName = input.FromCountryName,
            FromPortName = input.FromPortName,
            ToCountryName = input.ToCountryName,
            ToPortName = input.ToPortName,
            PhoneNumber = input.PhoneNumber,
            Container20ftPriceUsd = input.Container20ftPriceUsd,
            Container40ftPriceUsd = input.Container40ftPriceUsd,
            MinDurationDays = input.MinDurationDays,
            MaxDurationDays = input.MaxDurationDays,
            Details = input.Details
        });

        post.FromCountryId = route.FromCountryId;
        post.FromPortId = route.FromPortId;
        post.ToCountryId = route.ToCountryId;
        post.ToPortId = route.ToPortId;
        post.PhoneNumber = input.PhoneNumber.Trim();
        post.Container20ftPriceUsd = input.Container20ftPriceUsd;
        post.Container40ftPriceUsd = input.Container40ftPriceUsd;
        post.PriceUsd = input.Container20ftPriceUsd;
        post.MinDurationDays = input.MinDurationDays;
        post.MaxDurationDays = input.MaxDurationDays;
        post.Details = string.IsNullOrWhiteSpace(input.Details) ? null : input.Details.Trim();
        post.Status = ProductStatusCodes.UnderReview;
        post.IsApproved = false;

        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateSearchCache();

        await adminRealtimeNotificationService.NotifyNewShippingPostAsync(
            post,
            user.CompanyName ?? user.FullName,
            user.Id.ToString(),
            cancellationToken);

        return MapPost(post, route);
    }

    public async Task<object> DeletePostAsync(string userId, long postId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        await RequireShippingCompanyAsync(userId, cancellationToken);

        var post = await dbContext.InternationalShippingPosts
            .FirstOrDefaultAsync(x => x.Id == postId && x.PublisherUserId == parsedUserId, cancellationToken)
            ?? throw new KeyNotFoundException("Shipping post not found.");

        dbContext.InternationalShippingPosts.Remove(post);
        await dbContext.SaveChangesAsync(cancellationToken);
        InvalidateSearchCache();

        return new { message = "Shipping post deleted." };
    }

    private async Task<User> RequireShippingCompanyAsync(string userId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users.FindAsync([parsedUserId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId != RoleIds.ShippingCompany)
        {
            throw new UnauthorizedAccessException("Only shipping company accounts can access this resource.");
        }

        return user;
    }

    private static void EnsureApproved(User user)
    {
        if (!user.IsApproved)
        {
            throw new UnauthorizedAccessException("Your shipping company account is pending admin approval.");
        }
    }

    private async Task<List<InternationalShippingPost>> LoadOwnedPostsAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return await dbContext.InternationalShippingPosts
            .AsNoTracking()
            .Include(x => x.FromCountry)
            .Include(x => x.FromPort)
            .Include(x => x.ToCountry)
            .Include(x => x.ToPort)
            .Include(x => x.PublisherUser)
            .Where(x => x.PublisherUserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    private static object BuildStats(IReadOnlyList<InternationalShippingPost> posts) =>
        new
        {
            activeCount = posts.Count(x =>
                ProductStatusCodes.IsPubliclyVisible(x.Status, x.IsApproved)),
            underReviewCount = posts.Count(x =>
                ProductStatusCodes.IsPendingReview(x.Status, x.IsApproved)),
            rejectedCount = posts.Count(x =>
                ProductStatusCodes.Normalize(x.Status, x.IsApproved) == ProductStatusCodes.Rejected)
        };

    private static void ValidatePostInput(CreateInternationalShippingPostInput input)
    {
        if (string.IsNullOrWhiteSpace(input.FromCountryName) ||
            string.IsNullOrWhiteSpace(input.FromPortName) ||
            string.IsNullOrWhiteSpace(input.ToCountryName) ||
            string.IsNullOrWhiteSpace(input.ToPortName) ||
            string.IsNullOrWhiteSpace(input.PhoneNumber))
        {
            throw new ArgumentException("From/To country, from/to port and phone number are required.");
        }

        if (input.Container20ftPriceUsd <= 0 || input.Container40ftPriceUsd <= 0)
        {
            throw new ArgumentException("Container prices must be greater than zero.");
        }

        if (input.MinDurationDays is <= 0)
        {
            throw new ArgumentException("Minimum shipping duration days must be greater than zero when provided.");
        }

        if (input.MaxDurationDays is <= 0)
        {
            throw new ArgumentException("Maximum shipping duration days must be greater than zero when provided.");
        }

        if (input.MinDurationDays.HasValue
            && input.MaxDurationDays.HasValue
            && input.MinDurationDays > input.MaxDurationDays)
        {
            throw new ArgumentException("Minimum duration cannot exceed maximum duration.");
        }
    }

    private static void ValidateUpdateInput(UpdateInternationalShippingPostInput input)
    {
        ValidatePostInput(new CreateInternationalShippingPostInput
        {
            FromCountryName = input.FromCountryName,
            FromPortName = input.FromPortName,
            ToCountryName = input.ToCountryName,
            ToPortName = input.ToPortName,
            PhoneNumber = input.PhoneNumber,
            Container20ftPriceUsd = input.Container20ftPriceUsd,
            Container40ftPriceUsd = input.Container40ftPriceUsd,
            MinDurationDays = input.MinDurationDays,
            MaxDurationDays = input.MaxDurationDays,
            Details = input.Details
        });
    }

    private RouteResolution ResolveRoute(CreateInternationalShippingPostInput input)
    {
        var fromCountry = geoReferenceCache.FindCountryByEnglishName(input.FromCountryName.Trim())
            ?? throw new KeyNotFoundException($"From country '{input.FromCountryName}' was not found.");

        var toCountry = geoReferenceCache.FindCountryByEnglishName(input.ToCountryName.Trim())
            ?? throw new KeyNotFoundException($"To country '{input.ToCountryName}' was not found.");

        var fromPort = geoReferenceCache.FindPortByEnglishName(input.FromPortName.Trim(), fromCountry.Id)
            ?? throw new KeyNotFoundException($"From port '{input.FromPortName}' was not found for country '{input.FromCountryName}'.");

        var toPort = geoReferenceCache.FindPortByEnglishName(input.ToPortName.Trim(), toCountry.Id)
            ?? throw new KeyNotFoundException($"To port '{input.ToPortName}' was not found for country '{input.ToCountryName}'.");

        return new RouteResolution(
            fromCountry.Id,
            fromPort.Id,
            toCountry.Id,
            toPort.Id,
            fromCountry.CountryNameEn,
            fromPort.PortNameEn,
            toCountry.CountryNameEn,
            toPort.PortNameEn);
    }

    private static object MapPost(InternationalShippingPost post) =>
        MapPost(
            post,
            new RouteResolution(
                post.FromCountryId,
                post.FromPortId,
                post.ToCountryId,
                post.ToPortId,
                post.FromCountry?.CountryNameEn ?? string.Empty,
                post.FromPort?.PortNameEn ?? string.Empty,
                post.ToCountry?.CountryNameEn ?? string.Empty,
                post.ToPort?.PortNameEn ?? string.Empty,
                post.PublisherUser?.CompanyName ?? post.PublisherUser?.FullName));

    private static object MapPost(InternationalShippingPost post, RouteResolution route) =>
        new
        {
            id = post.Id,
            fromCountry = route.FromCountryName,
            fromPort = route.FromPortName,
            toCountry = route.ToCountryName,
            toPort = route.ToPortName,
            container20ftPriceUsd = post.Container20ftPriceUsd,
            container40ftPriceUsd = post.Container40ftPriceUsd,
            minDurationDays = post.MinDurationDays,
            maxDurationDays = post.MaxDurationDays,
            details = post.Details ?? string.Empty,
            phoneNumber = post.PhoneNumber,
            status = ProductStatusCodes.ToDisplayName(post.Status, post.IsApproved),
            isApproved = post.IsApproved,
            publisherName = route.PublisherName ?? string.Empty,
            publisherImgPath = post.PublisherUser?.ImgPath,
            createdAt = post.CreatedAt
        };

    private void InvalidateSearchCache()
    {
        if (cache is MemoryCache memoryCache)
        {
            memoryCache.Compact(1.0);
        }
    }

    private sealed record RouteResolution(
        short FromCountryId,
        int FromPortId,
        short ToCountryId,
        int ToPortId,
        string FromCountryName,
        string FromPortName,
        string ToCountryName,
        string ToPortName,
        string? PublisherName = null);
}
