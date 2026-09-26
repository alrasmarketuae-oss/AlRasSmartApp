using System.Net;
using BusinessLayer.Interfaces;

namespace RasAlSouqPresentaionLayer.Services;

public static class NasserVisitorInfo
{
    /// <summary>
    /// Real client IP. Proxy headers are only trusted when the request arrived from a private/loopback
    /// address (our Nginx container), otherwise a visitor could spoof them.
    /// </summary>
    public static string ClientIp(HttpContext http)
    {
        var remote = http.Connection.RemoteIpAddress;
        if (remote is not null && IsInternal(remote))
        {
            foreach (var header in new[] { "CF-Connecting-IP", "X-Real-IP", "X-Forwarded-For" })
            {
                var value = http.Request.Headers[header].ToString().Split(',')[0].Trim();
                if (IPAddress.TryParse(value, out var parsed) && !IsInternal(parsed))
                {
                    return parsed.ToString();
                }
            }
        }

        return remote?.ToString() ?? "unknown";
    }

    public static NasserVisitor Visitor(HttpContext http)
    {
        var country = http.Request.Headers["CF-IPCountry"].ToString();
        return new NasserVisitor(
            ClientIp(http),
            string.IsNullOrWhiteSpace(country) || country == "XX" ? null : country.ToUpperInvariant(),
            http.Request.Headers.UserAgent.ToString());
    }

    private static bool IsInternal(IPAddress ip)
    {
        if (IPAddress.IsLoopback(ip))
        {
            return true;
        }

        if (ip.IsIPv4MappedToIPv6)
        {
            ip = ip.MapToIPv4();
        }

        if (ip.IsIPv6LinkLocal || ip.IsIPv6SiteLocal || ip.IsIPv6UniqueLocal)
        {
            return true;
        }

        var b = ip.GetAddressBytes();
        return b.Length == 4 && (b[0] == 10
                                 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31)
                                 || (b[0] == 192 && b[1] == 168));
    }
}
