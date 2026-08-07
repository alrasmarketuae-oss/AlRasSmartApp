using System.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Helpers;

/// <summary>
/// Converts browser-trimmed WebM (VP8/VP9) to H.264 MP4 so Android/iOS players can play it.
/// Dashboard MediaRecorder usually emits WebM; ExoPlayer/AVPlayer often fail on that format.
/// </summary>
public static class VideoMobileCompatHelper
{
    public sealed record PreparedVideo(
        Stream Content,
        string FileName,
        string Extension,
        string ContentType,
        bool Converted);

    public static async Task<PreparedVideo> PrepareForMobilePlaybackAsync(
        IFormFile file,
        ILogger? logger = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(file);

        var originalName = Path.GetFileName(file.FileName);
        if (string.IsNullOrWhiteSpace(originalName))
        {
            originalName = "video.bin";
        }

        var extension = Path.GetExtension(originalName).ToLowerInvariant();
        if (extension is not ".webm")
        {
            var passthrough = new MemoryStream();
            await using (var input = file.OpenReadStream())
            {
                await input.CopyToAsync(passthrough, cancellationToken);
            }

            passthrough.Position = 0;
            return new PreparedVideo(
                passthrough,
                originalName,
                extension,
                file.ContentType ?? GuessContentType(extension),
                Converted: false);
        }

        if (!IsFfmpegAvailable())
        {
            throw new InvalidOperationException(
                "Trimmed WebM videos require ffmpeg on the server to convert to MP4 for mobile playback.");
        }

        var tempDir = Path.Combine(Path.GetTempPath(), "alras-video-compat", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        var inputPath = Path.Combine(tempDir, "input.webm");
        var outputPath = Path.Combine(tempDir, "output.mp4");

        try
        {
            await using (var input = file.OpenReadStream())
            await using (var output = File.Create(inputPath))
            {
                await input.CopyToAsync(output, cancellationToken);
            }

            await RunFfmpegAsync(inputPath, outputPath, cancellationToken);

            if (!File.Exists(outputPath) || new FileInfo(outputPath).Length == 0)
            {
                throw new InvalidOperationException("WebM to MP4 conversion produced an empty file.");
            }

            await Mp4FastStartHelper.TryOptimizeInPlaceAsync(outputPath, cancellationToken);

            var bytes = await File.ReadAllBytesAsync(outputPath, cancellationToken);
            var stream = new MemoryStream(bytes);
            var mp4Name = Path.ChangeExtension(originalName, ".mp4");
            logger?.LogInformation(
                "Converted trimmed WebM ({WebmBytes} bytes) to MP4 ({Mp4Bytes} bytes) for mobile playback.",
                new FileInfo(inputPath).Length,
                bytes.Length);

            return new PreparedVideo(stream, mp4Name, ".mp4", "video/mp4", Converted: true);
        }
        finally
        {
            try
            {
                if (Directory.Exists(tempDir))
                {
                    Directory.Delete(tempDir, recursive: true);
                }
            }
            catch
            {
                // Best-effort temp cleanup.
            }
        }
    }

    private static bool IsFfmpegAvailable()
    {
        try
        {
            using var process = Process.Start(new ProcessStartInfo
            {
                FileName = "ffmpeg",
                Arguments = "-version",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            });
            if (process is null)
            {
                return false;
            }

            process.WaitForExit(5000);
            return process.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    private static async Task RunFfmpegAsync(
        string inputPath,
        string outputPath,
        CancellationToken cancellationToken)
    {
        // Baseline H.264 + AAC is widely supported on Android/iOS video_player.
        using var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = "ffmpeg",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            }
        };

        var args = process.StartInfo.ArgumentList;
        args.Add("-y");
        args.Add("-i");
        args.Add(inputPath);
        args.Add("-c:v");
        args.Add("libx264");
        args.Add("-pix_fmt");
        args.Add("yuv420p");
        args.Add("-profile:v");
        args.Add("baseline");
        args.Add("-level");
        args.Add("3.1");
        args.Add("-preset");
        args.Add("veryfast");
        args.Add("-crf");
        args.Add("23");
        args.Add("-c:a");
        args.Add("aac");
        args.Add("-b:a");
        args.Add("128k");
        args.Add("-ac");
        args.Add("2");
        args.Add("-movflags");
        args.Add("+faststart");
        args.Add(outputPath);

        if (!process.Start())
        {
            throw new InvalidOperationException("Failed to start ffmpeg.");
        }

        var stderrTask = process.StandardError.ReadToEndAsync(cancellationToken);
        await process.WaitForExitAsync(cancellationToken);
        var stderr = await stderrTask;

        if (process.ExitCode != 0)
        {
            var detail = string.IsNullOrWhiteSpace(stderr)
                ? $"exit code {process.ExitCode}"
                : stderr.Length > 500
                    ? stderr[^500..]
                    : stderr;
            throw new InvalidOperationException($"WebM to MP4 conversion failed: {detail}");
        }
    }

    private static string GuessContentType(string extension) =>
        extension switch
        {
            ".mp4" or ".m4v" => "video/mp4",
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "application/octet-stream"
        };
}
