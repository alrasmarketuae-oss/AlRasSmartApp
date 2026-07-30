using BusinessLayer.Caching;
using BusinessLayer.Dtos;
using BusinessLayer.Interfaces;
using BusinessLayer.Services;
using DataLayer.Interfaces;
using DataLayer.Models;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class AdminSettingsAppService(
    IRasAlSouqDbContext dbContext,
    ICommissionSettingsProvider commissionSettingsProvider,
    ICategoryCommissionProvider categoryCommissionProvider,
    IAdminAuditLogAppService auditLogAppService,
    IStaticReferenceCache staticReferenceCache) : IAdminSettingsAppService
{
    public async Task<object> GetSettingsAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateRowAsync(cancellationToken);
        var categoryCommissions = await GetCategoryCommissionsAsync(cancellationToken);

        return new
        {
            retailCommissionPercent = settings.RetailCommissionPercent,
            bookingCommissionPercent = settings.BookingCommissionPercent,
            requestsCommissionPercent = settings.RequestsCommissionPercent,
            offersCommissionPercent = settings.OffersCommissionPercent,
            shippingCommissionPercent = settings.ShippingCommissionPercent,
            appName = settings.AppName,
            supportEmail = settings.SupportEmail,
            phoneNumber = settings.PhoneNumber,
            landlineNumber = settings.LandlineNumber,
            timezone = settings.Timezone,
            address = settings.Address,
            featuredAdPriceAed = settings.FeaturedAdPriceAed,
            adDisplayDurationDays = settings.AdDisplayDurationDays,
            updatedAt = settings.UpdatedAt,
            categoryCommissions
        };
    }

    public async Task<object> GetPublicCommissionsAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateRowAsync(cancellationToken);
        var categoryCommissions = await GetCategoryCommissionsAsync(cancellationToken);

        return new
        {
            retailCommissionPercent = settings.RetailCommissionPercent,
            bookingCommissionPercent = settings.BookingCommissionPercent,
            requestsCommissionPercent = settings.RequestsCommissionPercent,
            offersCommissionPercent = settings.OffersCommissionPercent,
            shippingCommissionPercent = settings.ShippingCommissionPercent,
            categoryCommissions
        };
    }

    public async Task<object> UpdateSettingsAsync(
        UpdateSystemSettingsInput input,
        CancellationToken cancellationToken = default)
    {
        ValidateCommissionPercent(input.RetailCommissionPercent, nameof(input.RetailCommissionPercent));
        ValidateCommissionPercent(input.BookingCommissionPercent, nameof(input.BookingCommissionPercent));
        ValidateCommissionPercent(input.RequestsCommissionPercent, nameof(input.RequestsCommissionPercent));
        ValidateCommissionPercent(input.OffersCommissionPercent, nameof(input.OffersCommissionPercent));
        ValidateCommissionPercent(input.ShippingCommissionPercent, nameof(input.ShippingCommissionPercent));

        if (string.IsNullOrWhiteSpace(input.AppName))
        {
            throw new ArgumentException("AppName is required.");
        }

        if (input.AdDisplayDurationDays < 0)
        {
            throw new ArgumentException("AdDisplayDurationDays cannot be negative.");
        }

        if (input.FeaturedAdPriceAed < 0)
        {
            throw new ArgumentException("FeaturedAdPriceAed cannot be negative.");
        }

        var settings = await GetOrCreateRowAsync(cancellationToken);
        settings.RetailCommissionPercent = input.RetailCommissionPercent;
        settings.BookingCommissionPercent = input.BookingCommissionPercent;
        settings.RequestsCommissionPercent = input.RequestsCommissionPercent;
        settings.OffersCommissionPercent = input.OffersCommissionPercent;
        settings.ShippingCommissionPercent = input.ShippingCommissionPercent;
        settings.AppName = input.AppName.Trim();
        settings.SupportEmail = NormalizeOptional(input.SupportEmail);
        settings.PhoneNumber = NormalizeOptional(input.PhoneNumber);
        settings.LandlineNumber = NormalizeOptional(input.LandlineNumber);
        settings.Timezone = NormalizeOptional(input.Timezone);
        settings.Address = NormalizeOptional(input.Address);
        settings.FeaturedAdPriceAed = decimal.Round(input.FeaturedAdPriceAed, 2, MidpointRounding.AwayFromZero);
        settings.AdDisplayDurationDays = input.AdDisplayDurationDays;
        settings.UpdatedAt = DateTime.UtcNow;

        if (input.CategoryCommissions is { Count: > 0 })
        {
            var categories = await dbContext.Categories.ToListAsync(cancellationToken);
            var byId = categories.ToDictionary(x => x.CategoryId);
            foreach (var item in input.CategoryCommissions)
            {
                ValidateCommissionPercent(item.CommissionPercent, $"CategoryCommissions[{item.CategoryId}]");
                if (byId.TryGetValue(item.CategoryId, out var category))
                {
                    category.CommissionPercent = item.CommissionPercent;
                }
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        commissionSettingsProvider.Invalidate();
        categoryCommissionProvider.Invalidate();
        CategoriesListCache.Bump();
        staticReferenceCache.InvalidateCategories();
        ProductsAppService.InvalidateProductListCaches();

        await auditLogAppService.WriteAsync(
            AdminAuditActions.SettingsUpdate,
            AdminAuditEntityTypes.Settings,
            "1",
            "Updated system settings / commissions",
            new
            {
                input.RetailCommissionPercent,
                input.BookingCommissionPercent,
                input.RequestsCommissionPercent,
                input.OffersCommissionPercent,
                input.ShippingCommissionPercent,
                input.AppName,
                input.AdDisplayDurationDays,
                input.FeaturedAdPriceAed
            },
            cancellationToken);

        return await GetSettingsAsync(cancellationToken);
    }

    private async Task<SystemSettings> GetOrCreateRowAsync(CancellationToken cancellationToken)
    {
        var settings = await dbContext.SystemSettings.FirstOrDefaultAsync(x => x.Id == 1, cancellationToken);
        if (settings is not null)
        {
            return settings;
        }

        settings = new SystemSettings { Id = 1 };
        await dbContext.SystemSettings.AddAsync(settings, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return settings;
    }

    private static void ValidateCommissionPercent(decimal value, string fieldName)
    {
        if (value is < 0 or > 100)
        {
            throw new ArgumentException($"{fieldName} must be between 0 and 100.");
        }
    }

    private async Task<List<CategoryCommissionDto>> GetCategoryCommissionsAsync(
        CancellationToken cancellationToken)
    {
        return await dbContext.Categories
            .AsNoTracking()
            .Where(x => !x.IsHide)
            .OrderBy(x => x.CategoryId)
            .Select(x => new CategoryCommissionDto(
                x.CategoryId,
                x.NameEn,
                x.NameAr,
                x.CommissionPercent))
            .ToListAsync(cancellationToken);
    }

    private static string? NormalizeOptional(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        return trimmed.Length == 0 ? null : trimmed;
    }
}
