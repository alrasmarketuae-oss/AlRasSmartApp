using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.Storage;

public sealed class MediaUrlResolver(
    IOptions<CloudflareR2Options> r2Options,
    IHttpContextAccessor httpContextAccessor) : IMediaUrlResolver
{
    public string ToStorageKey(string? pathOrUrl)
    {
        if (string.IsNullOrWhiteSpace(pathOrUrl))
        {
            return string.Empty;
        }

        var trimmed = pathOrUrl.Trim().Replace('\\', '/');
        if (trimmed.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || trimmed.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            if (Uri.TryCreate(trimmed, UriKind.Absolute, out var uri))
            {
                trimmed = uri.AbsolutePath;
            }
        }

        var normalized = WebRootFileHelper.NormalizeStoredPath(trimmed);
        var bucket = r2Options.Value.BucketName?.Trim().Trim('/');
        if (!string.IsNullOrWhiteSpace(bucket)
            && normalized.StartsWith($"/{bucket}/", StringComparison.OrdinalIgnoreCase))
        {
            normalized = normalized[$"/{bucket}".Length..];
            if (!normalized.StartsWith('/'))
            {
                normalized = "/" + normalized;
            }
        }

        return normalized;
    }

    public string ToPublicUrl(string? storedPath)
    {
        var key = ToStorageKey(storedPath);
        if (string.IsNullOrWhiteSpace(key))
        {
            return string.Empty;
        }

        var publicBase = ResolvePublicBaseUrl();
        if (!string.IsNullOrWhiteSpace(publicBase))
        {
            return $"{publicBase.TrimEnd('/')}{key}";
        }

        var request = httpContextAccessor.HttpContext?.Request;
        if (request is not null)
        {
            var origin = $"{request.Scheme}://{request.Host.Value}".TrimEnd('/');
            return $"{origin}{key}";
        }

        return key;
    }

    private string? ResolvePublicBaseUrl()
    {
        var options = r2Options.Value;
        if (!options.IsConfigured)
        {
            return null;
        }

        var configured = options.PublicBaseUrl?.Trim().TrimEnd('/');
        if (!string.IsNullOrWhiteSpace(configured))
        {
            return configured;
        }

        // Fallback until PublicBaseUrl (cdn.alrasmarketapp.com) is configured.
        var serviceUrl = options.ServiceUrl?.Trim().TrimEnd('/');
        var bucket = options.BucketName?.Trim().Trim('/');
        if (string.IsNullOrWhiteSpace(serviceUrl) || string.IsNullOrWhiteSpace(bucket))
        {
            return null;
        }

        return $"{serviceUrl}/{bucket}";
    }
}
