using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Hosting;

namespace BusinessLayer.Services.Storage;

public sealed class LocalWebRootFileStorage(IWebHostEnvironment environment) : IFileStorage
{
    private string WebRootPath =>
        environment.WebRootPath
        ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

    public async Task SaveAsync(
        Stream content,
        string relativePath,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var key = WebRootFileHelper.NormalizeStoredPath(relativePath).TrimStart('/');
        var fullPath = Path.Combine(WebRootPath, key.Replace('/', Path.DirectorySeparatorChar));
        var directory = Path.GetDirectoryName(fullPath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using var output = File.Create(fullPath);
        if (content.CanSeek)
        {
            content.Position = 0;
        }

        await content.CopyToAsync(output, cancellationToken);
    }

    public Task DeleteAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        WebRootFileHelper.TryDeleteRelativeFile(WebRootPath, relativePath);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var fullPath = WebRootFileHelper.ToFullPath(WebRootPath, relativePath);
        return Task.FromResult(File.Exists(fullPath));
    }

    public Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var fullPath = WebRootFileHelper.ToFullPath(WebRootPath, relativePath);
        if (!File.Exists(fullPath))
        {
            return Task.FromResult<Stream?>(null);
        }

        Stream stream = File.OpenRead(fullPath);
        return Task.FromResult<Stream?>(stream);
    }

    public Task<IReadOnlyList<StoredObjectInfo>> ListAsync(
        string prefix,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var key = WebRootFileHelper.NormalizeStoredPath(prefix).TrimStart('/');
        var root = Path.Combine(WebRootPath, key.Replace('/', Path.DirectorySeparatorChar));
        if (!Directory.Exists(root))
        {
            return Task.FromResult<IReadOnlyList<StoredObjectInfo>>(Array.Empty<StoredObjectInfo>());
        }

        var results = new List<StoredObjectInfo>();
        foreach (var file in Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories))
        {
            cancellationToken.ThrowIfCancellationRequested();
            var relative = Path.GetRelativePath(WebRootPath, file)
                .Replace('\\', '/');
            var info = new FileInfo(file);
            results.Add(new StoredObjectInfo("/" + relative.TrimStart('/'), info.LastWriteTimeUtc));
        }

        return Task.FromResult<IReadOnlyList<StoredObjectInfo>>(results);
    }

    public Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default) =>
        Task.FromResult<string?>(null);
}
