namespace RasAlSouqPresentaionLayer;

/// <summary>
/// Client address for rate limits. Cloudflare overwrites CF-Connecting-IP, so a caller cannot pick their own bucket through the proxy.
/// </summary>
public static class ClientRequestKey
{
    public static string Resolve(HttpContext httpContext)
    {
        var cloudflareIp = httpContext.Request.Headers["CF-Connecting-IP"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(cloudflareIp))
        {
            return cloudflareIp.Trim();
        }

        var forwarded = httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(forwarded))
        {
            var first = forwarded.Split(',')[0].Trim();
            if (first.Length > 0)
            {
                return first;
            }
        }

        return httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }
}
