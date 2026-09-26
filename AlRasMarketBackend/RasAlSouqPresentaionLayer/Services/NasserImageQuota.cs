using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Caching.Memory;

namespace RasAlSouqPresentaionLayer.Services;

/// <summary>
/// Limits Nasser portfolio AI images to <see cref="Limit"/> per visitor per <see cref="Window"/>,
/// tracked by a signed cookie and by client IP (so clearing cookies alone does not reset it).
/// </summary>
public sealed class NasserImageQuota(IMemoryCache cache, IConfiguration configuration)
{
    public const int Limit = 2;
    public static readonly TimeSpan Window = TimeSpan.FromDays(2);
    private const string CookieName = "nasser_ai_img";

    private sealed record State(int Count, DateTimeOffset WindowStart);

    public int Remaining(HttpContext http)
    {
        var used = Math.Max(ReadCookie(http)?.Count ?? 0, ReadIp(http)?.Count ?? 0);
        return Math.Max(0, Limit - used);
    }

    public int Consume(HttpContext http)
    {
        var now = DateTimeOffset.UtcNow;
        var cookie = ReadCookie(http);
        var ip = ReadIp(http);
        var start = new[] { cookie?.WindowStart, ip?.WindowStart }
            .Where(x => x.HasValue)
            .Select(x => x!.Value)
            .DefaultIfEmpty(now)
            .Min();
        var count = Math.Max(cookie?.Count ?? 0, ip?.Count ?? 0) + 1;
        var next = new State(count, start);

        cache.Set(IpKey(http), next, start + Window);
        WriteCookie(http, next);
        return Math.Max(0, Limit - count);
    }

    private State? ReadIp(HttpContext http) =>
        cache.TryGetValue(IpKey(http), out State? state) && state is not null && !Expired(state) ? state : null;

    private State? ReadCookie(HttpContext http)
    {
        if (!http.Request.Cookies.TryGetValue(CookieName, out var raw) || string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        var parts = raw.Split('.');
        if (parts.Length != 3
            || !int.TryParse(parts[0], out var count)
            || !long.TryParse(parts[1], out var startUnix)
            || !CryptographicOperations.FixedTimeEquals(
                Encoding.ASCII.GetBytes(Sign($"{parts[0]}.{parts[1]}")),
                Encoding.ASCII.GetBytes(parts[2])))
        {
            return null;
        }

        var state = new State(count, DateTimeOffset.FromUnixTimeSeconds(startUnix));
        return Expired(state) ? null : state;
    }

    private void WriteCookie(HttpContext http, State state)
    {
        var payload = $"{state.Count}.{state.WindowStart.ToUnixTimeSeconds()}";
        http.Response.Cookies.Append(CookieName, $"{payload}.{Sign(payload)}", new CookieOptions
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.None,
            Expires = state.WindowStart + Window,
            Path = "/api/nasser-portfolio"
        });
    }

    private static bool Expired(State state) => DateTimeOffset.UtcNow - state.WindowStart >= Window;

    private static string IpKey(HttpContext http) =>
        $"nasser-ai-img:{NasserVisitorInfo.ClientIp(http)}";

    private string Sign(string payload)
    {
        var secret = configuration["JwtSettings:Key"] ?? "nasser-portfolio-image-quota";
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        return Convert.ToHexString(hmac.ComputeHash(Encoding.UTF8.GetBytes(payload)))[..32];
    }
}
