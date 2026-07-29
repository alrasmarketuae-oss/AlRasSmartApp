using Amazon.S3;
using Amazon.S3.Model;
using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services.Storage;

public sealed class CloudflareR2FileStorage : IFileStorage, IDisposable
{
    private readonly CloudflareR2Options _options;
    private readonly IAmazonS3 _client;
    private readonly ILogger<CloudflareR2FileStorage> _logger;

    public CloudflareR2FileStorage(
        IOptions<CloudflareR2Options> options,
        ILogger<CloudflareR2FileStorage> logger)
    {
        _options = options.Value;
        _logger = logger;
        var config = new AmazonS3Config
        {
            ServiceURL = _options.ServiceUrl.TrimEnd('/'),
            ForcePathStyle = true,
            AuthenticationRegion = "auto"
        };



        _client = new AmazonS3Client(_options.AccessKey, _options.SecretKey, config);
    }

    public async Task SaveAsync(
        Stream content,
        string relativePath,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var key = ToObjectKey(relativePath);
        if (content.CanSeek)
        {
            content.Position = 0;
        }

        var request = new PutObjectRequest
        {
            BucketName = _options.BucketName,
            Key = key,
            InputStream = content,
            ContentType = string.IsNullOrWhiteSpace(contentType)
                ? "application/octet-stream"
                : contentType,
            AutoCloseStream = false,
            DisablePayloadSigning = true
        };

        await _client.PutObjectAsync(request, cancellationToken);
        _logger.LogDebug("Uploaded media object to R2 key {Key}", key);
    }

    public async Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var key = ToObjectKey(relativePath);
        if (string.IsNullOrWhiteSpace(key))
        {
            return;
        }

        try
        {
            await _client.DeleteObjectAsync(_options.BucketName, key, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete R2 object {Key}", key);
        }
    }

    public async Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var key = ToObjectKey(relativePath);
        try
        {
            await _client.GetObjectMetadataAsync(_options.BucketName, key, cancellationToken);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
    }

    public async Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var key = ToObjectKey(relativePath);
        try
        {
            var response = await _client.GetObjectAsync(_options.BucketName, key, cancellationToken);
            var memory = new MemoryStream();
            await response.ResponseStream.CopyToAsync(memory, cancellationToken);
            memory.Position = 0;
            return memory;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
    }

    public Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var key = ToObjectKey(relativePath);
        if (string.IsNullOrWhiteSpace(key))
        {
            return Task.FromResult<string?>(null);
        }

        var seconds = Math.Clamp((int)expiry.TotalSeconds, 60, 3600);
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _options.BucketName,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = DateTime.UtcNow.AddSeconds(seconds),
            ContentType = string.IsNullOrWhiteSpace(contentType)
                ? "application/octet-stream"
                : contentType
        };

        var url = _client.GetPreSignedURL(request);
        return Task.FromResult<string?>(url);
    }

    public void Dispose() => _client.Dispose();

    private static string ToObjectKey(string relativePath)
    {
        var normalized = WebRootFileHelper.NormalizeStoredPath(relativePath);
        return normalized.TrimStart('/');
    }
}
