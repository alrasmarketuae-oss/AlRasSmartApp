using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;

namespace BusinessLayer.Auth;

public static class AppleIdentityTokenValidator
{
    private const string AppleIssuer = "https://appleid.apple.com";
    private const string AppleJwksUrl = "https://appleid.apple.com/auth/keys";
    private static readonly TimeSpan KeysCacheDuration = TimeSpan.FromHours(24);

    private static readonly ConcurrentDictionary<string, (IReadOnlyCollection<SecurityKey> Keys, DateTimeOffset FetchedAt)> KeyCache = new();
    private static readonly SemaphoreSlim FetchLock = new(1, 1);

    public static async Task<ClaimsPrincipal> ValidateAsync(
        string token,
        string[] allowedClientIds,
        HttpClient httpClient)
    {
        if (allowedClientIds.Length == 0)
        {
            throw new InvalidOperationException("Apple ClientIds are not configured.");
        }

        var handler = new JwtSecurityTokenHandler();
        if (!handler.CanReadToken(token))
        {
            throw new UnauthorizedAccessException("Invalid Apple token format.");
        }

        var keys = await GetAppleSigningKeysAsync(httpClient);
        var parameters = new TokenValidationParameters
        {
            ValidIssuer = AppleIssuer,
            ValidAudiences = allowedClientIds,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = keys,
            ClockSkew = TimeSpan.FromMinutes(2)
        };

        try
        {
            return handler.ValidateToken(token, parameters, out _);
        }
        catch (SecurityTokenException ex)
        {
            throw new UnauthorizedAccessException("Apple token is invalid.", ex);
        }
    }

    private static async Task<IReadOnlyCollection<SecurityKey>> GetAppleSigningKeysAsync(HttpClient httpClient)
    {
        if (KeyCache.TryGetValue(AppleJwksUrl, out var cached) &&
            DateTimeOffset.UtcNow - cached.FetchedAt < KeysCacheDuration &&
            cached.Keys.Count > 0)
        {
            return cached.Keys;
        }

        await FetchLock.WaitAsync();
        try
        {
            if (KeyCache.TryGetValue(AppleJwksUrl, out cached) &&
                DateTimeOffset.UtcNow - cached.FetchedAt < KeysCacheDuration &&
                cached.Keys.Count > 0)
            {
                return cached.Keys;
            }

            var jwksJson = await httpClient.GetStringAsync(AppleJwksUrl);
            var keySet = new JsonWebKeySet(jwksJson);
            var keys = (IReadOnlyCollection<SecurityKey>)keySet.GetSigningKeys();
            if (keys.Count == 0)
            {
                throw new UnauthorizedAccessException("Unable to load Apple signing keys.");
            }

            KeyCache[AppleJwksUrl] = (keys, DateTimeOffset.UtcNow);
            return keys;
        }
        catch (UnauthorizedAccessException)
        {
            throw;
        }
        catch (Exception ex)
        {
            if (KeyCache.TryGetValue(AppleJwksUrl, out var stale) && stale.Keys.Count > 0)
            {
                return stale.Keys;
            }

            throw new UnauthorizedAccessException("Unable to validate Apple token keys.", ex);
        }
        finally
        {
            FetchLock.Release();
        }
    }
}
