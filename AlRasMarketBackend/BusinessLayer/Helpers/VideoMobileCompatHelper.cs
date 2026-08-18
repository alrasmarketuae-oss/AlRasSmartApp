using System.Diagnostics;
using System.Globalization;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Helpers;

/// <summary>
/// Converts browser-trimmed WebM (VP8/VP9) to H.264 MP4 so Android/iOS players can play it.
/// Admin trim uses ffmpeg stream copy (-c copy) on the original file so colors are unchanged.
/// </summary>
public static class VideoMobileCompatHelper
{
    public sealed record PreparedVideo(
        Stream Content,
        string FileName,
        string Extension,
        string ContentType,
        bool Converted);

    public static byte ResolveTrimDurationSeconds(double startSeconds, double endSeconds)
    {
        if (double.IsNaN(startSeconds) || double.IsInfinity(startSeconds) || startSeconds < 0)
        {
            throw new ArgumentException("Start time must be 0 or greater.");
        }

        if (double.IsNaN(endSeconds) || double.IsInfinity(endSeconds))
        {
            throw new ArgumentException("Invalid end time.");
        }

        var duration = endSeconds - startSeconds;
        if (duration < 0.5)
        {
            throw new ArgumentException("Trimmed clip must be at least 0.5 seconds.");
        }

        if (duration > 180)
        {
            throw new ArgumentException("Trimmed clip cannot exceed 180 seconds.");
        }

        return (byte)Math.Clamp((int)Math.Round(duration, MidpointRounding.AwayFromZero), 1, 180);
    }

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

            await RunFfmpegAsync(
                BuildWebmConvertArgs(inputPath, outputPath),
                "WebM to MP4 conversion",
                cancellationToken);

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
            TryDeleteDirectory(tempDir);
        }
    }

    public static async Task<PreparedVideo> TrimSegmentAsync(
        Stream source,
        string sourceExtension,
        double startSeconds,
        double endSeconds,
        ILogger? logger = null,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(source);
        var durationSeconds = ResolveTrimDurationSeconds(startSeconds, endSeconds);
        var clipDuration = endSeconds - startSeconds;

        if (!IsFfmpegAvailable())
        {
            throw new InvalidOperationException("Trimming videos requires ffmpeg on the server.");
        }

        var extension = NormalizeExtension(sourceExtension);
        var outputExtension = extension is ".mp4" or ".m4v" or ".mov" or ".webm"
            ? (extension is ".m4v" or ".mov" ? ".mp4" : extension)
            : ".mp4";
        var tempDir = Path.Combine(Path.GetTempPath(), "alras-video-trim", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        var inputPath = Path.Combine(tempDir, "input" + (string.IsNullOrEmpty(extension) ? ".bin" : extension));
        var outputPath = Path.Combine(tempDir, "output" + outputExtension);

        try
        {
            await using (var output = File.Create(inputPath))
            {
                if (source.CanSeek)
                {
                    source.Position = 0;
                }

                await source.CopyToAsync(output, cancellationToken);
            }

            // Stream copy only: no decode/encode, so color space/codec/bitrate stay original.
            // ffmpeg -ss START -i input -t DURATION -c copy output
            var copied = await TryRunFfmpegAsync(
                BuildCopyTrimArgs(inputPath, outputPath, startSeconds, clipDuration, inputSeek: true),
                cancellationToken);
            if (copied && (!File.Exists(outputPath) || new FileInfo(outputPath).Length == 0))
            {
                copied = false;
            }

            if (!copied)
            {
                if (File.Exists(outputPath))
                {
                    File.Delete(outputPath);
                }

                copied = await TryRunFfmpegAsync(
                    BuildCopyTrimArgs(inputPath, outputPath, startSeconds, clipDuration, inputSeek: false),
                    cancellationToken);
            }

            if (!copied || !File.Exists(outputPath) || new FileInfo(outputPath).Length == 0)
            {
                throw new InvalidOperationException(
                    "Video trim with stream copy failed. Re-encoding is disabled to preserve original colors.");
            }

            if (outputExtension is ".mp4" or ".m4v")
            {
                await Mp4FastStartHelper.TryOptimizeInPlaceAsync(outputPath, cancellationToken);
            }

            var bytes = await File.ReadAllBytesAsync(outputPath, cancellationToken);
            logger?.LogInformation(
                "Trimmed video {Start}-{End}s ({Duration}s stored) from {SourceExt} ({SourceBytes} bytes) to {OutExt} ({OutBytes} bytes) using ffmpeg -c copy.",
                startSeconds,
                endSeconds,
                durationSeconds,
                extension,
                new FileInfo(inputPath).Length,
                outputExtension,
                bytes.Length);

            return new PreparedVideo(
                new MemoryStream(bytes),
                "trim" + outputExtension,
                outputExtension,
                GuessContentType(outputExtension),
                Converted: false);
        }
        finally
        {
            TryDeleteDirectory(tempDir);
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

    private static List<string> BuildWebmConvertArgs(string inputPath, string outputPath) =>
    [
        "-y",
        "-fflags", "+genpts",
        "-i", inputPath,
        "-map", "0:v:0",
        "-map", "0:a?",
        "-vf", "setpts=PTS-STARTPTS,format=yuv420p",
        "-vsync", "vfr",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-profile:v", "main",
        "-level", "4.0",
        "-preset", "veryfast",
        "-crf", "23",
        "-c:a", "aac",
        "-b:a", "128k",
        "-ac", "2",
        "-movflags", "+faststart",
        outputPath
    ];

    /// <summary>
    /// ffmpeg -ss START -i input -t DURATION -c copy output
    /// When <paramref name="inputSeek"/> is false: -i first then -ss (still copy, no re-encode).
    /// </summary>
    private static List<string> BuildCopyTrimArgs(
        string inputPath,
        string outputPath,
        double startSeconds,
        double durationSeconds,
        bool inputSeek)
    {
        var start = FormatFfmpegTime(startSeconds);
        var duration = FormatFfmpegTime(durationSeconds);
        var args = new List<string> { "-y" };
        if (inputSeek)
        {
            args.Add("-ss");
            args.Add(start);
            args.Add("-i");
            args.Add(inputPath);
        }
        else
        {
            args.Add("-i");
            args.Add(inputPath);
            args.Add("-ss");
            args.Add(start);
        }

        args.Add("-t");
        args.Add(duration);
        args.Add("-c");
        args.Add("copy");
        args.Add("-avoid_negative_ts");
        args.Add("make_zero");
        if (Path.GetExtension(outputPath).Equals(".mp4", StringComparison.OrdinalIgnoreCase)
            || Path.GetExtension(outputPath).Equals(".m4v", StringComparison.OrdinalIgnoreCase))
        {
            args.Add("-movflags");
            args.Add("+faststart");
        }

        args.Add(outputPath);
        return args;
    }

    private static async Task RunFfmpegAsync(
        IReadOnlyList<string> arguments,
        string failureLabel,
        CancellationToken cancellationToken)
    {
        var result = await RunFfmpegCoreAsync(arguments, cancellationToken);
        if (result.Ok)
        {
            return;
        }

        var detail = string.IsNullOrWhiteSpace(result.Stderr)
            ? $"exit code {result.ExitCode}"
            : result.Stderr.Length > 500
                ? result.Stderr[^500..]
                : result.Stderr;
        throw new InvalidOperationException($"{failureLabel} failed: {detail}");
    }

    private static async Task<bool> TryRunFfmpegAsync(
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken)
    {
        var result = await RunFfmpegCoreAsync(arguments, cancellationToken);
        return result.Ok;
    }

    private static async Task<FfmpegRunResult> RunFfmpegCoreAsync(
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken)
    {
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

        foreach (var argument in arguments)
        {
            process.StartInfo.ArgumentList.Add(argument);
        }

        if (!process.Start())
        {
            return new FfmpegRunResult(false, -1, "Failed to start ffmpeg.");
        }

        var stderrTask = process.StandardError.ReadToEndAsync(cancellationToken);
        try
        {
            await process.WaitForExitAsync(cancellationToken);
        }
        catch (OperationCanceledException)
        {
            try
            {
                process.Kill(entireProcessTree: true);
            }
            catch
            {
                // Best-effort stop.
            }

            throw;
        }

        var stderr = await stderrTask;
        return new FfmpegRunResult(process.ExitCode == 0, process.ExitCode, stderr);
    }

    private readonly record struct FfmpegRunResult(bool Ok, int ExitCode, string Stderr);

    private static string FormatFfmpegTime(double seconds) =>
        Math.Max(0, seconds).ToString("0.###", CultureInfo.InvariantCulture);

    private static string NormalizeExtension(string? extension)
    {
        if (string.IsNullOrWhiteSpace(extension))
        {
            return ".mp4";
        }

        var value = extension.Trim().ToLowerInvariant();
        return value.StartsWith('.') ? value : "." + value;
    }

    private static void TryDeleteDirectory(string tempDir)
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

    private static string GuessContentType(string extension) =>
        extension switch
        {
            ".mp4" or ".m4v" => "video/mp4",
            ".mov" => "video/quicktime",
            ".webm" => "video/webm",
            _ => "application/octet-stream"
        };
}
