namespace BusinessLayer.Interfaces;

/// <summary>
/// Provider-agnostic blob storage. Keys are relative web paths like /product-images/abc.jpg
/// (leading slash optional). Implementations map to R2/S3/Azure/local without changing DB.
/// </summary>
public interface IFileStorage
{
    Task SaveAsync(
        Stream content,
        string relativePath,
        string contentType,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default);

    Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default);

    /// <summary>
    /// Lists objects under [prefix] (relative path). Empty list when unsupported.
    /// </summary>
    Task<IReadOnlyList<StoredObjectInfo>> ListAsync(
        string prefix,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Client direct PUT URL when the provider supports it (R2/S3). Returns null for local storage.
    /// </summary>
    Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default);
}

public sealed record StoredObjectInfo(string RelativePath, DateTimeOffset LastModified);
