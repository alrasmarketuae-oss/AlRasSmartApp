using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using Microsoft.AspNetCore.Http;

namespace BusinessLayer.Services.Storage;

public sealed class MediaStorageService(IFileStorage fileStorage) : IMediaStorageService
{
    public async Task<string> SaveCompressedJpegAsync(
        IFormFile file,
        string folder,
        string? fileName = null,
        ImageCompressionOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(file);
        var name = string.IsNullOrWhiteSpace(fileName)
            ? $"{Guid.NewGuid():N}.jpg"
            : fileName.Trim();
        if (!name.EndsWith(".jpg", StringComparison.OrdinalIgnoreCase)
            && !name.EndsWith(".jpeg", StringComparison.OrdinalIgnoreCase))
        {
            name = Path.ChangeExtension(name, ".jpg");
        }

        var bytes = await ImageFileHelper.CompressToJpegBytesAsync(
            file,
            options ?? ImageCompressionOptions.WebStandard,
            cancellationToken);
        return await SaveBytesAsync(bytes, folder, name, "image/jpeg", cancellationToken);
    }

    public async Task<string> SaveFormFileAsync(
        IFormFile file,
        string folder,
        string? fileName = null,
        string? contentType = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(file);
        var extension = Path.GetExtension(file.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".bin";
        }

        var name = string.IsNullOrWhiteSpace(fileName)
            ? $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}"
            : fileName.Trim();

        await using var input = file.OpenReadStream();
        await using var buffer = new MemoryStream();
        await input.CopyToAsync(buffer, cancellationToken);
        buffer.Position = 0;

        var relative = WebRootFileHelper.BuildRelativePath(folder, name);
        await fileStorage.SaveAsync(
            buffer,
            relative,
            contentType ?? file.ContentType ?? "application/octet-stream",
            cancellationToken);
        return relative;
    }

    public async Task<string> SaveBytesAsync(
        byte[] bytes,
        string folder,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var relative = WebRootFileHelper.BuildRelativePath(folder, fileName);
        await using var stream = new MemoryStream(bytes);
        await fileStorage.SaveAsync(stream, relative, contentType, cancellationToken);
        return relative;
    }

    public Task DeleteAsync(string? relativePath, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(relativePath))
        {
            return Task.CompletedTask;
        }

        return fileStorage.DeleteAsync(relativePath, cancellationToken);
    }

    public Task<Stream?> OpenReadAsync(string relativePath, CancellationToken cancellationToken = default) =>
        fileStorage.OpenReadAsync(relativePath, cancellationToken);

    public Task<bool> ExistsAsync(string relativePath, CancellationToken cancellationToken = default) =>
        fileStorage.ExistsAsync(relativePath, cancellationToken);

    public Task<string?> TryCreatePresignedPutUrlAsync(
        string relativePath,
        string contentType,
        TimeSpan expiry,
        CancellationToken cancellationToken = default) =>
        fileStorage.TryCreatePresignedPutUrlAsync(relativePath, contentType, expiry, cancellationToken);
}
