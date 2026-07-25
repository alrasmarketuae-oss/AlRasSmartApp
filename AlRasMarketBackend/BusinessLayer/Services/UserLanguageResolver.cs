using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using DataLayer.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace BusinessLayer.Services;

public sealed class UserLanguageResolver(
    IRasAlSouqDbContext dbContext,
    IHttpContextAccessor httpContextAccessor) : IUserLanguageResolver
{
    public async Task<string> ResolveAsync(
        string? userId = null,
        string? acceptLanguageHeader = null,
        CancellationToken cancellationToken = default)
    {
        var httpContext = httpContextAccessor.HttpContext;
        if (httpContext?.Items.TryGetValue(UserLanguageContext.ItemKey, out var cached) == true
            && cached is string cachedLanguage)
        {
            return cachedLanguage;
        }

        var language = await ResolveUserLanguageAsync(userId, cancellationToken);

        if (string.IsNullOrWhiteSpace(language) && httpContext is not null)
        {
            language = ResolveFromHttpHeaders(
                httpContext.Request.Headers["X-Preferred-Language"].FirstOrDefault(),
                acceptLanguageHeader ?? httpContext.Request.Headers["Accept-Language"].FirstOrDefault());
        }
        else if (string.IsNullOrWhiteSpace(language))
        {
            language = ResolveFromHttpHeaders(null, acceptLanguageHeader);
        }

        var normalized = NotificationMessages.NormalizeLanguage(language);
        if (httpContext is not null)
        {
            httpContext.Items[UserLanguageContext.ItemKey] = normalized;
        }

        return normalized;
    }

    public string ResolveFromHttpHeaders(string? preferredLanguageHeader, string? acceptLanguageHeader)
    {
        if (!string.IsNullOrWhiteSpace(preferredLanguageHeader))
        {
            return NotificationMessages.NormalizeLanguage(preferredLanguageHeader);
        }

        if (!string.IsNullOrWhiteSpace(acceptLanguageHeader)
            && acceptLanguageHeader.Trim().StartsWith("ar", StringComparison.OrdinalIgnoreCase))
        {
            return "ar";
        }

        return "en";
    }

    private async Task<string?> ResolveUserLanguageAsync(string? userId, CancellationToken cancellationToken)
    {
        var resolvedUserId = userId;
        if (string.IsNullOrWhiteSpace(resolvedUserId))
        {
            var httpContext = httpContextAccessor.HttpContext;
            resolvedUserId = httpContext?.User?.FindFirst("EntityId")?.Value
                ?? httpContext?.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        }

        if (!Guid.TryParse(resolvedUserId, out var parsedUserId))
        {
            return null;
        }

        return await dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == parsedUserId)
            .Select(x => x.PreferredLanguage)
            .FirstOrDefaultAsync(cancellationToken);
    }
}
