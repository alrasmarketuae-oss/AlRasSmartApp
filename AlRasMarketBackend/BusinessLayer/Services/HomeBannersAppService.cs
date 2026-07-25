using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace BusinessLayer.Services;

public class HomeBannersAppService(
    IRasAlSouqDbContext dbContext,
    IMemoryCache cache,
    IAdminAuditLogAppService auditLogAppService,
    IMediaStorageService mediaStorage) : IHomeBannersAppService
{
    private const string HomeBannersCacheKey = "home-banners:all";

    public async Task<object> CreateAsync(CreateHomeBannerInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        if (input.File is null || input.File.Length == 0)
        {
            throw new ArgumentException("Banner image file is required.");
        }

        var exists = await dbContext.HomeBanners.AnyAsync(x => x.DisplayOrder == input.DisplayOrder, cancellationToken);
        if (exists)
        {
            throw new InvalidOperationException($"DisplayOrder '{input.DisplayOrder}' already exists.");
        }

        var fileName = $"banner-{Guid.NewGuid():N}.jpg";
        var imagePath = await mediaStorage.SaveCompressedJpegAsync(
            input.File,
            "home-banners",
            fileName,
            cancellationToken: cancellationToken);

        var entity = new HomeBanner
        {
            ImagePath = imagePath,
            LinkUrl = string.IsNullOrWhiteSpace(input.LinkUrl) ? string.Empty : input.LinkUrl.Trim(),
            DisplayOrder = input.DisplayOrder
        };

        await dbContext.HomeBanners.AddAsync(entity, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(HomeBannersCacheKey);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.BannerCreate,
            AdminAuditEntityTypes.Banner,
            entity.Id.ToString(),
            $"Created home banner #{entity.Id}",
            new { entity.DisplayOrder, entity.LinkUrl, entity.ImagePath },
            cancellationToken);

        return new { entity.Id, entity.ImagePath, entity.LinkUrl, entity.DisplayOrder };
    }

    public async Task<object> GetAllAsync(CancellationToken cancellationToken = default)
    {
        if (cache.TryGetValue(HomeBannersCacheKey, out object? cached) && cached is not null)
        {
            return cached;
        }

        var banners = await dbContext.HomeBanners
            .AsNoTracking()
            .OrderBy(x => x.DisplayOrder)
            .Select(x => new
            {
                x.Id,
                x.ImagePath,
                x.LinkUrl,
                x.DisplayOrder
            })
            .ToListAsync(cancellationToken);

        var result = new { count = banners.Count, items = banners };
        cache.Set(HomeBannersCacheKey, result, TimeSpan.FromMinutes(5));
        return result;
    }

    public async Task<object> UpdateAsync(UpdateHomeBannerInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        var banner = await dbContext.HomeBanners.FirstOrDefaultAsync(x => x.Id == input.BannerId, cancellationToken)
            ?? throw new KeyNotFoundException("Banner not found.");

        if (input.LinkUrl is not null)
        {
            banner.LinkUrl = string.IsNullOrWhiteSpace(input.LinkUrl) ? string.Empty : input.LinkUrl.Trim();
        }

        if (input.DisplayOrder.HasValue)
        {
            var newOrder = input.DisplayOrder.Value;
            var orderTaken = await dbContext.HomeBanners.AnyAsync(
                x => x.Id != banner.Id && x.DisplayOrder == newOrder,
                cancellationToken);
            if (orderTaken)
            {
                throw new InvalidOperationException($"DisplayOrder '{newOrder}' already exists.");
            }

            banner.DisplayOrder = newOrder;
        }

        var oldImagePath = banner.ImagePath;
        if (input.File is not null && input.File.Length > 0)
        {
            var fileName = $"banner-{Guid.NewGuid():N}.jpg";
            banner.ImagePath = await mediaStorage.SaveCompressedJpegAsync(
                input.File,
                "home-banners",
                fileName,
                cancellationToken: cancellationToken);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(HomeBannersCacheKey);

        if (input.File is not null && input.File.Length > 0)
        {
            await mediaStorage.DeleteAsync(oldImagePath, cancellationToken);
        }

        await auditLogAppService.WriteAsync(
            AdminAuditActions.BannerUpdate,
            AdminAuditEntityTypes.Banner,
            banner.Id.ToString(),
            $"Updated home banner #{banner.Id}",
            new { banner.DisplayOrder, banner.LinkUrl, banner.ImagePath },
            cancellationToken);

        return new { banner.Id, banner.ImagePath, banner.LinkUrl, banner.DisplayOrder };
    }

    public async Task<object> DeleteAsync(DeleteHomeBannerInput input, CancellationToken cancellationToken = default)
    {
        await ValidateAdminAsync(input.UserId, cancellationToken);

        var banner = await dbContext.HomeBanners.FirstOrDefaultAsync(x => x.Id == input.BannerId, cancellationToken)
            ?? throw new KeyNotFoundException("Banner not found.");

        var oldImagePath = banner.ImagePath;
        var bannerId = banner.Id;
        dbContext.HomeBanners.Remove(banner);
        await dbContext.SaveChangesAsync(cancellationToken);
        cache.Remove(HomeBannersCacheKey);

        await mediaStorage.DeleteAsync(oldImagePath, cancellationToken);

        await auditLogAppService.WriteAsync(
            AdminAuditActions.BannerDelete,
            AdminAuditEntityTypes.Banner,
            bannerId.ToString(),
            $"Deleted home banner #{bannerId}",
            null,
            cancellationToken);

        return new { message = "Banner deleted successfully." };
    }

    private async Task ValidateAdminAsync(string userId, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(userId, out var userGuid))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users.FindAsync([userGuid], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        if (user.RoleId != 1)
        {
            throw new UnauthorizedAccessException("Only admin can manage home banners.");
        }
    }
}
