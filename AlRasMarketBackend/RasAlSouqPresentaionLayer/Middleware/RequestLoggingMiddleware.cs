using System.Diagnostics;

namespace RasAlSouqPresentaionLayer.Middleware;

/// <summary>
/// يسجّل كل طلب HTTP وارد والاستجابة في سجلات السيرفر (Console / ملفات الاستضافة).
/// </summary>
public sealed class RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var method = context.Request.Method;
        var path = context.Request.Path.Value ?? "/";
        var query = context.Request.QueryString.HasValue ? context.Request.QueryString.Value : string.Empty;
        var clientIp = context.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        logger.LogInformation(
            "→ HTTP {Method} {Path}{Query} from {ClientIp}",
            method,
            path,
            query,
            clientIp);

        var stopwatch = Stopwatch.StartNew();

        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            logger.LogError(
                ex,
                "✗ HTTP {Method} {Path}{Query} failed after {ElapsedMs}ms",
                method,
                path,
                query,
                stopwatch.ElapsedMilliseconds);
            throw;
        }

        stopwatch.Stop();

        logger.LogInformation(
            "← HTTP {Method} {Path}{Query} => {StatusCode} ({ElapsedMs}ms)",
            method,
            path,
            query,
            context.Response.StatusCode,
            stopwatch.ElapsedMilliseconds);
    }
}
