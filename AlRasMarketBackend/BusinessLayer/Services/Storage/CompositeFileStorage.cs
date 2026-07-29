using BusinessLayer.Interfaces;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Services.Storage;

/// <summary>
/// Writes to primary (R2 when configured). Reads try primary then local fallback
/// so existing wwwroot files keep working during migration.
/// </summary>
public sealed class CompositeFileStorage(
    IFileStorage primary,
    IFileStorage fallback,
    ILogger<CompositeFileStorage> logger) : IFileStorage
{
    public async Task SaveAsync(
        Stream content,
        string relativePath,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        // Buffer once so retries / dual paths don't consume a non-seekable stream.
        await using var buffer = new MemoryStream();
        if (content.CanSeek)
        {
            content.Position = 0;
        }

        await content.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;
        await primary.SaveAsync(buffer, relativePath, contentType, cancellationToken);
    }

    public async Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        await primary.DeleteAsync(relativePath, cancellationToken);
        try
        {
            await fallback.DeleteAsync(relativePath, cancellationToken);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "Fallback delete ignored for {Path}", relativePath);
        }
    }

    public async Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        if (await primary.ExistsAsync(relativePath, cancellationToken))
        {
            return true;
        }

        return await fallback.ExistsAsync(relativePath, cancellationToken);
    }

    public async Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var stream = await primary.OpenReadAsync(relativePath, cancellationToken);
        if (stream is not null)
        {
            return stream;
        }

        return await fallback.OpenReadAsync(relativePath, cancellationToken);
    }

    public Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default) =>
        primary.TryCreatePresignedPutUrlAsync(relativePath, contentType, expiry, cancellationToken);
}
