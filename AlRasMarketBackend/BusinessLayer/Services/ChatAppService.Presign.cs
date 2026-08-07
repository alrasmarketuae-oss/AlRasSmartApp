using BusinessLayer.Helpers;
using BusinessLayer.Interfaces;
using BusinessLayer.Options;
using Microsoft.Extensions.Options;

namespace BusinessLayer.Services;

public sealed partial class ChatAppService
{
    private readonly CloudflareR2Options _r2Options = r2Options.Value;

    public Task<object> PresignImageUploadAsync(string userId, CancellationToken ct = default) =>
        PresignAsync(userId, ChatImagesFolder, $"{Guid.NewGuid():N}.jpg", "image/jpeg", ct);

    public Task<object> PresignVideoUploadAsync(
        string userId,
        string? extension,
        CancellationToken ct = default)
    {
        var ext = NormalizeVideoExtension(extension);
        var mime = ext switch
        {
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "video/mp4"
        };
        return PresignAsync(userId, ChatVideosFolder, $"{Guid.NewGuid():N}{ext}", mime, ct);
    }

    public Task<object> PresignVoiceUploadAsync(
        string userId,
        string? extension,
        CancellationToken ct = default)
    {
        var ext = NormalizeVoiceExtension(extension);
        var fileName = $"{Guid.NewGuid():N}{ext}";
        return PresignAsync(
            userId,
            ChatVoiceFolder,
            fileName,
            VoiceFileHelper.GetContentType(fileName),
            ct);
    }

    public Task<object> PresignFileUploadAsync(
        string userId,
        string? fileName,
        CancellationToken ct = default)
    {
        var originalName = Path.GetFileName(fileName ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(originalName))
        {
            originalName = "document";
        }

        var extension = Path.GetExtension(originalName).ToLowerInvariant();
        if (!ChatFileContentHelper.IsAllowedExtension(extension))
        {
            throw new ArgumentException(
                $"Unsupported file type. Allowed: {ChatFileContentHelper.AllowedExtensionsLabel}.");
        }

        var contentType = ChatFileContentHelper.GetContentType(extension);
        var storedName = $"{Guid.NewGuid():N}{extension}";
        return PresignAsync(userId, ChatFilesFolder, storedName, contentType, ct);
    }

    public async Task<ChatUploadResultDto> ConfirmDirectUploadAsync(
        string userId,
        string rawPath,
        ChatApiMessageType messageType,
        string? originalFileName = null,
        long? sizeBytes = null,
        CancellationToken ct = default)
    {
        var ownerId = ParseUserId(userId);
        var path = WebRootFileHelper.NormalizeStoredPath(rawPath);
        var folder = messageType switch
        {
            ChatApiMessageType.Image => ChatImagesFolder,
            ChatApiMessageType.Voice => ChatVoiceFolder,
            ChatApiMessageType.Video => ChatVideosFolder,
            ChatApiMessageType.File => ChatFilesFolder,
            _ => throw new ArgumentException("Direct upload confirm supports image, voice, video, and file only.")
        };

        EnsureChatPathOwnedByUser(path, ownerId, folder);

        if (!await mediaStorage.ExistsAsync(path, ct))
        {
            throw new ArgumentException("Uploaded file not found in storage. Complete the client upload first.");
        }

        if (messageType == ChatApiMessageType.File)
        {
            var extension = Path.GetExtension(path).ToLowerInvariant();
            var mime = ChatFileContentHelper.GetContentType(extension);
            var displayName = Path.GetFileName(originalFileName ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(displayName))
            {
                displayName = Path.GetFileName(path);
            }

            var content = ChatFileContentHelper.Serialize(
                path,
                displayName,
                sizeBytes is > 0 ? sizeBytes.Value : 0,
                mime);
            return new ChatUploadResultDto(content, messageType, mime);
        }

        var mediaMime = messageType switch
        {
            ChatApiMessageType.Image => "image/jpeg",
            ChatApiMessageType.Voice => VoiceFileHelper.GetContentType(path),
            ChatApiMessageType.Video => VideoMimeFromPath(path),
            _ => null
        };

        return new ChatUploadResultDto(path, messageType, mediaMime);
    }

    private async Task<object> PresignAsync(
        string userId,
        string folder,
        string fileName,
        string contentType,
        CancellationToken ct)
    {
        if (!_r2Options.IsConfigured)
        {
            throw new InvalidOperationException("Direct client upload is not available.");
        }

        var ownerId = ParseUserId(userId);
        var path = WebRootFileHelper.BuildRelativePath($"{folder}/{ownerId:N}", fileName);
        var expirySeconds = Math.Clamp(_r2Options.PresignedPutExpirySeconds, 60, 3600);
        var uploadUrl = await mediaStorage.TryCreatePresignedPutUrlAsync(
            path,
            contentType,
            TimeSpan.FromSeconds(expirySeconds),
            ct);

        if (string.IsNullOrWhiteSpace(uploadUrl))
        {
            throw new InvalidOperationException("Direct client upload is not available.");
        }

        return new
        {
            uploadUrl,
            path,
            contentType,
            requiredHeaders = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["Content-Type"] = contentType
            }
        };
    }

    private static void EnsureChatPathOwnedByUser(string path, Guid userId, string folder)
    {
        var expectedPrefix = $"/{folder.Trim('/')}/{userId:N}/";
        if (!path.StartsWith(expectedPrefix, StringComparison.OrdinalIgnoreCase)
            || path.Contains("..", StringComparison.Ordinal))
        {
            throw new ArgumentException("Invalid media path.");
        }
    }

    private static string NormalizeVideoExtension(string? extension)
    {
        var ext = string.IsNullOrWhiteSpace(extension)
            ? ".mp4"
            : Path.GetExtension(extension).ToLowerInvariant();
        if (ext is not (".mp4" or ".mov" or ".webm" or ".m4v"))
        {
            throw new ArgumentException("Unsupported video format. Allowed: .mp4, .mov, .webm, .m4v");
        }

        return ext;
    }

    private static string NormalizeVoiceExtension(string? extension)
    {
        var ext = string.IsNullOrWhiteSpace(extension)
            ? ".m4a"
            : Path.GetExtension(extension).ToLowerInvariant();
        if (ext is not (".webm" or ".ogg" or ".mp3" or ".m4a" or ".wav" or ".aac" or ".caf" or ".3gp" or ".3gpp" or ".amr"))
        {
            throw new ArgumentException(
                "Unsupported audio format. Allowed: .webm, .ogg, .mp3, .m4a, .wav, .aac, .caf, .3gp, .amr");
        }

        return ext == ".3gpp" ? ".3gp" : ext;
    }

    private static string VideoMimeFromPath(string path) =>
        Path.GetExtension(path).ToLowerInvariant() switch
        {
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "video/mp4"
        };
}
