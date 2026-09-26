using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Caching.Memory;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>
/// Stand-alone login for the private portfolio inbox. Deliberately independent of the marketplace
/// JWT/roles: its tokens are not JWTs and are rejected by every marketplace endpoint, and marketplace
/// tokens are rejected here.
/// </summary>
public sealed class NasserAdminAuth(IConfiguration configuration, IMemoryCache cache)
{
    public static readonly TimeSpan TokenLifetime = TimeSpan.FromHours(12);
    private const int MaxFailedAttempts = 5;
    private static readonly TimeSpan LockoutWindow = TimeSpan.FromMinutes(15);

    private string Username => configuration["NasserPortfolio:AdminUsername"]?.Trim() ?? string.Empty;
    private string Password => configuration["NasserPortfolio:AdminPassword"] ?? string.Empty;

    public bool Enabled => Username.Length > 0 && Password.Length >= 12;

    public bool IsLockedOut(HttpContext http) =>
        cache.TryGetValue(LockKey(http), out int failures) && failures >= MaxFailedAttempts;

    public string? Login(HttpContext http, string? username, string? password)
    {
        if (!Enabled || IsLockedOut(http))
        {
            return null;
        }

        var ok = FixedEquals(username?.Trim() ?? string.Empty, Username)
                 & FixedEquals(password ?? string.Empty, Password);
        if (!ok)
        {
            var failures = cache.TryGetValue(LockKey(http), out int f) ? f + 1 : 1;
            cache.Set(LockKey(http), failures, LockoutWindow);
            return null;
        }

        cache.Remove(LockKey(http));
        var expires = DateTimeOffset.UtcNow.Add(TokenLifetime).ToUnixTimeSeconds();
        var payload = $"np-admin.{expires}.{Convert.ToHexString(RandomNumberGenerator.GetBytes(8))}";
        return $"{payload}.{Sign(payload)}";
    }

    public bool Validate(HttpContext http)
    {
        if (!Enabled)
        {
            return false;
        }

        var header = http.Request.Headers["X-Nasser-Admin"].ToString();
        var parts = header.Split('.');
        if (parts.Length != 4 || parts[0] != "np-admin" || !long.TryParse(parts[1], out var exp))
        {
            return false;
        }

        if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > exp)
        {
            return false;
        }

        return FixedEquals(Sign($"{parts[0]}.{parts[1]}.{parts[2]}"), parts[3]);
    }

    private string Sign(string payload)
    {
        // Password is part of the key so changing it immediately revokes every issued token.
        var secret = $"{configuration["NasserPortfolio:AdminTokenSecret"] ?? configuration["JwtSettings:Key"]}|nasser-admin|{Username}|{Password}";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(payload)));
    }

    private static bool FixedEquals(string a, string b) =>
        CryptographicOperations.FixedTimeEquals(
            SHA256.HashData(Encoding.UTF8.GetBytes(a)),
            SHA256.HashData(Encoding.UTF8.GetBytes(b)));

    private static string LockKey(HttpContext http) => $"nasser-admin-fail:{NasserVisitorInfo.ClientIp(http)}";
}
