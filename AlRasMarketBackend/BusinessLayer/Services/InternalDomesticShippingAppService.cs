using BusinessLayer.Dtos;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public class InternalDomesticShippingAppService(
    IRasAlSouqDbContext dbContext,
    IInternalDomesticShippingProvider ratesProvider,
    IAdminAuditLogAppService auditLogAppService) : IInternalDomesticShippingAppService
{
    public async Task<object> GetAllRatesAsync(CancellationToken cancellationToken = default)
    {
        await ratesProvider.EnsureLoadedAsync(cancellationToken);
        return ratesProvider.GetAllRatesResponse();
    }

    public async Task<object> GetPriceByEmirateAsync(string emirateName, CancellationToken cancellationToken = default)
    {
        await ratesProvider.EnsureLoadedAsync(cancellationToken);
        return ratesProvider.GetPriceByEmirateResponse(emirateName);
    }

    public async Task<object> UpdateRatesAsync(
        UpdateInternalDomesticShippingInput input,
        CancellationToken cancellationToken = default)
    {
        if (input.Rates is null || input.Rates.Count == 0)
        {
            throw new ArgumentException("At least one emirate rate is required.");
        }

        var ids = input.Rates.Select(x => x.Id).Distinct().ToList();
        var entities = await dbContext.InternalDomesticShippingRates
            .Where(x => ids.Contains(x.Id))
            .ToListAsync(cancellationToken);

        if (entities.Count != ids.Count)
        {
            throw new KeyNotFoundException("One or more emirates were not found.");
        }

        var now = DateTime.UtcNow;
        foreach (var item in input.Rates)
        {
            if (item.PriceAed < 0)
            {
                throw new ArgumentException("Shipping price cannot be negative.");
            }

            var entity = entities.First(x => x.Id == item.Id);
            entity.PriceAed = item.PriceAed;
            entity.UpdatedAt = now;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        ratesProvider.ApplyInMemoryUpdates(
            input.Rates.Select(x => (x.Id, x.PriceAed)).ToList());

        if (input.ExcessKgRateAed.HasValue)
        {
            var config = await dbContext.InternalDomesticShippingConfigs
                .FirstOrDefaultAsync(x => x.Id == 1, cancellationToken);

            if (config is null)
            {
                config = new DataLayer.Models.InternalDomesticShippingConfig { Id = 1 };
                await dbContext.InternalDomesticShippingConfigs.AddAsync(config, cancellationToken);
            }

            config.ExcessKgRateAed = input.ExcessKgRateAed.Value;
            config.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
            ratesProvider.ApplyExcessKgRateUpdate(input.ExcessKgRateAed.Value);
        }

        await auditLogAppService.WriteAsync(
            AdminAuditActions.DomesticShippingUpdate,
            AdminAuditEntityTypes.Shipping,
            null,
            "Updated internal domestic shipping rates",
            new
            {
                rateCount = input.Rates.Count,
                rates = input.Rates,
                excessKgRateAed = input.ExcessKgRateAed
            },
            cancellationToken);

        return ratesProvider.GetAllRatesResponse();
    }
}

public class UserPreferencesAppService(IRasAlSouqDbContext dbContext) : IUserPreferencesAppService
{
    public async Task<object> GetPreferredLanguageAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var user = await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == parsedUserId)
            .Select(x => new { x.PreferredLanguage })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        var language = NotificationMessages.NormalizeLanguage(user.PreferredLanguage);
        return new { language };
    }

    public async Task<object> UpdatePreferredLanguageAsync(
        string userId,
        UpdatePreferredLanguageInput input,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(userId, out var parsedUserId))
        {
            throw new ArgumentException("Invalid user id.");
        }

        var language = NotificationMessages.NormalizeLanguageOrThrow(input.Language);

        var user = await dbContext.Users.FindAsync([parsedUserId], cancellationToken)
            ?? throw new KeyNotFoundException("User not found.");

        user.PreferredLanguage = language;
        await dbContext.SaveChangesAsync(cancellationToken);

        return new { language, message = language == "ar" ? "تم تحديث اللغة المفضلة." : "Preferred language updated." };
    }
}
