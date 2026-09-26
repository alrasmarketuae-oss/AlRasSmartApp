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
    private const string DefaultAndroidStoreUrl =
        "https://play.google.com/store/apps/details?id=com.mergespice.alrasmarket";
    private const string DefaultIosStoreUrl =
        "https://apps.apple.com/gb/app/al-ras-smart/id6795899781";

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
            androidLatestVersion = settings.AndroidLatestVersion,
            iosLatestVersion = settings.IosLatestVersion,
            androidMinVersion = settings.AndroidMinVersion,
            iosMinVersion = settings.IosMinVersion,
            androidStoreUrl = settings.AndroidStoreUrl,
            iosStoreUrl = settings.IosStoreUrl,
            appUpdateMessageAr = settings.AppUpdateMessageAr,
            appUpdateMessageEn = settings.AppUpdateMessageEn,
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

    public async Task<object> GetPublicAppVersionAsync(CancellationToken cancellationToken = default)
    {
        var settings = await GetOrCreateRowAsync(cancellationToken);
        return new
        {
            androidLatestVersion = NormalizeVersion(settings.AndroidLatestVersion),
            iosLatestVersion = NormalizeVersion(settings.IosLatestVersion),
            androidMinVersion = NormalizeVersion(settings.AndroidMinVersion),
            iosMinVersion = NormalizeVersion(settings.IosMinVersion),
            androidStoreUrl = string.IsNullOrWhiteSpace(settings.AndroidStoreUrl)
                ? DefaultAndroidStoreUrl
                : settings.AndroidStoreUrl.Trim(),
            iosStoreUrl = string.IsNullOrWhiteSpace(settings.IosStoreUrl)
                ? DefaultIosStoreUrl
                : settings.IosStoreUrl.Trim(),
            messageAr = settings.AppUpdateMessageAr,
            messageEn = settings.AppUpdateMessageEn
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

        ValidateOptionalVersion(input.AndroidLatestVersion, nameof(input.AndroidLatestVersion));
        ValidateOptionalVersion(input.IosLatestVersion, nameof(input.IosLatestVersion));
        ValidateOptionalVersion(input.AndroidMinVersion, nameof(input.AndroidMinVersion));
        ValidateOptionalVersion(input.IosMinVersion, nameof(input.IosMinVersion));

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
        settings.AndroidLatestVersion = NormalizeVersion(input.AndroidLatestVersion);
        settings.IosLatestVersion = NormalizeVersion(input.IosLatestVersion);
        settings.AndroidMinVersion = NormalizeVersion(input.AndroidMinVersion);
        settings.IosMinVersion = NormalizeVersion(input.IosMinVersion);
        settings.AndroidStoreUrl = NormalizeOptional(input.AndroidStoreUrl);
        settings.IosStoreUrl = NormalizeOptional(input.IosStoreUrl);
        settings.AppUpdateMessageAr = NormalizeOptional(input.AppUpdateMessageAr);
        settings.AppUpdateMessageEn = NormalizeOptional(input.AppUpdateMessageEn);
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
                input.FeaturedAdPriceAed,
                input.AndroidLatestVersion,
                input.IosLatestVersion,
                input.AndroidMinVersion,
                input.IosMinVersion
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

    private static void ValidateOptionalVersion(string? value, string fieldName)
    {
        var normalized = NormalizeVersion(value);
        if (normalized is null) return;
        if (!System.Text.RegularExpressions.Regex.IsMatch(normalized, @"^\d+(\.\d+){0,3}$"))
        {
            throw new ArgumentException($"{fieldName} must look like 1.0.46");
        }
    }

    private static string? NormalizeVersion(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim().TrimStart('v', 'V');
        return trimmed.Length == 0 ? null : trimmed;
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
