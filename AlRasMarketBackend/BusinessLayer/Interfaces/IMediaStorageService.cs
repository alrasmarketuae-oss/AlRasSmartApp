using BusinessLayer.Helpers;
using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Interfaces;

/// <summary>
/// High-level media helper used by upload endpoints.
/// Always returns a relative path suitable for DB storage.
/// </summary>
public interface IMediaStorageService
{
    Task<string> SaveCompressedJpegAsync(
        IFormFile file,
        string folder,
        string? fileName = null,
        ImageCompressionOptions? options = null,
        CancellationToken cancellationToken = default);

    Task<string> SaveFormFileAsync(
        IFormFile file,
        string folder,
        string? fileName = null,
        string? contentType = null,
        CancellationToken cancellationToken = default);

    Task<string> SaveBytesAsync(
        byte[] bytes,
        string folder,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(string? relativePath, CancellationToken cancellationToken = default);

    Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default);

    /// <summary>Null when direct client upload (presigned PUT) is unavailable.</summary>
    Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default);
}
