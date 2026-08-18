using System.Diagnostics;
using System.Globalization;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace BusinessLayer.Helpers;

/// <summary>
/// Converts browser-trimmed WebM (VP8/VP9) to H.264 MP4 so Android/iOS players can play it.
/// Admin trim uses ffmpeg stream copy (-c copy) when the cut starts on a keyframe.
/// Otherwise it re-encodes with the source color tags so a few seconds off the start actually cut.
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
        var tempDir = Path.Combine(Path.GetTempPath(), "alras-video-trim", Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(tempDir);
        var inputPath = Path.Combine(tempDir, "input" + (string.IsNullOrEmpty(extension) ? ".bin" : extension));
        var copyOutputPath = Path.Combine(
            tempDir,
            "copy" + (extension is ".mp4" or ".m4v" or ".mov" or ".webm"
                ? (extension is ".m4v" or ".mov" ? ".mp4" : extension)
                : ".mp4"));
        var encodeOutputPath = Path.Combine(tempDir, "accurate.mp4");

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

            var keyframes = await TryGetKeyframeTimesAsync(inputPath, cancellationToken);
            var canCopy = CanStreamCopyTrim(startSeconds, keyframes);
            var usedCopy = false;
            string outputPath;

            if (canCopy)
            {
                usedCopy = await TryCopyTrimAsync(
                    inputPath,
                    copyOutputPath,
                    startSeconds,
                    clipDuration,
                    cancellationToken);
            }

            if (usedCopy)
            {
                outputPath = copyOutputPath;
            }
            else
            {
                if (File.Exists(copyOutputPath))
                {
                    File.Delete(copyOutputPath);
                }

                var color = await TryGetVideoColorInfoAsync(inputPath, cancellationToken);
                var encoded = await TryRunFfmpegAsync(
                    BuildAccurateTrimArgs(inputPath, encodeOutputPath, startSeconds, clipDuration, color),
                    cancellationToken);
                if (!encoded || !HasOutput(encodeOutputPath))
                {
                    if (File.Exists(encodeOutputPath))
                    {
                        File.Delete(encodeOutputPath);
                    }

                    encoded = await TryRunFfmpegAsync(
                        BuildAccurateTrimArgs(
                            inputPath,
                            encodeOutputPath,
                            startSeconds,
                            clipDuration,
                            color,
                            forceYuv420p: true),
                        cancellationToken);
                }

                if (!encoded || !HasOutput(encodeOutputPath))
                {
                    throw new InvalidOperationException("Video trim failed.");
                }

                outputPath = encodeOutputPath;
            }

            var outputExtension = Path.GetExtension(outputPath).ToLowerInvariant();
            if (outputExtension is ".mp4" or ".m4v")
            {
                await Mp4FastStartHelper.TryOptimizeInPlaceAsync(outputPath, cancellationToken);
            }

            var bytes = await File.ReadAllBytesAsync(outputPath, cancellationToken);
            logger?.LogInformation(
                "Trimmed video {Start}-{End}s ({Duration}s stored) from {SourceExt} ({SourceBytes} bytes) to {OutExt} ({OutBytes} bytes) via {Mode}.",
                startSeconds,
                endSeconds,
                durationSeconds,
                extension,
                new FileInfo(inputPath).Length,
                outputExtension,
                bytes.Length,
                usedCopy ? "ffmpeg -c copy" : "ffmpeg accurate");

            return new PreparedVideo(
                new MemoryStream(bytes),
                "trim" + outputExtension,
                outputExtension,
                GuessContentType(outputExtension),
                Converted: !usedCopy);
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

    private static List<string> BuildAccurateTrimArgs(
        string inputPath,
        string outputPath,
        double startSeconds,
        double durationSeconds,
        VideoColorInfo? color,
        bool forceYuv420p = false)
    {
        // -ss before -i is frame-accurate when re-encoding: decode from the previous
        // keyframe, drop frames until START, then encode. That is what actually cuts
        // a few seconds off the beginning.
        var args = new List<string>
        {
            "-y",
            "-ss", FormatFfmpegTime(startSeconds),
            "-i", inputPath,
            "-t", FormatFfmpegTime(durationSeconds),
            "-map", "0:v:0",
            "-map", "0:a?",
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-crf", "17",
            "-profile:v", "main",
            "-level", "4.0",
        };

        var pixFmt = forceYuv420p ? "yuv420p" : color?.PixFmt;
        if (string.IsNullOrWhiteSpace(pixFmt) || pixFmt is "yuvj420p")
        {
            pixFmt = "yuv420p";
        }

        args.Add("-pix_fmt");
        args.Add(pixFmt);

        AddColorTag(args, "-colorspace", color?.ColorSpace);
        AddColorTag(args, "-color_primaries", color?.ColorPrimaries);
        AddColorTag(args, "-color_trc", color?.ColorTransfer);
        var range = NormalizeColorRange(color?.ColorRange);
        if (range is null && color?.PixFmt == "yuvj420p")
        {
            range = "pc";
        }

        AddColorTag(args, "-color_range", range);

        args.Add("-c:a");
        args.Add("aac");
        args.Add("-b:a");
        args.Add("160k");
        args.Add("-ac");
        args.Add("2");
        args.Add("-movflags");
        args.Add("+faststart");
        args.Add(outputPath);
        return args;
    }

    private static void AddColorTag(List<string> args, string flag, string? value)
    {
        if (!IsUsableColorValue(value))
        {
            return;
        }

        args.Add(flag);
        args.Add(value!);
    }

    private static bool IsUsableColorValue(string? value) =>
        !string.IsNullOrWhiteSpace(value)
        && !value.Equals("unknown", StringComparison.OrdinalIgnoreCase)
        && !value.Equals("unspecified", StringComparison.OrdinalIgnoreCase)
        && !value.Equals("N/A", StringComparison.OrdinalIgnoreCase);

    private static string? NormalizeColorRange(string? value)
    {
        if (!IsUsableColorValue(value))
        {
            return null;
        }

        return value!.ToLowerInvariant() switch
        {
            "tv" or "mpeg" or "limited" or "1" => "tv",
            "pc" or "jpeg" or "full" or "2" => "pc",
            _ => value
        };
    }

    private static async Task<bool> TryCopyTrimAsync(
        string inputPath,
        string outputPath,
        double startSeconds,
        double durationSeconds,
        CancellationToken cancellationToken)
    {
        var copied = await TryRunFfmpegAsync(
            BuildCopyTrimArgs(inputPath, outputPath, startSeconds, durationSeconds, inputSeek: true),
            cancellationToken);
        if (copied && HasOutput(outputPath))
        {
            return true;
        }

        if (File.Exists(outputPath))
        {
            File.Delete(outputPath);
        }

        copied = await TryRunFfmpegAsync(
            BuildCopyTrimArgs(inputPath, outputPath, startSeconds, durationSeconds, inputSeek: false),
            cancellationToken);
        return copied && HasOutput(outputPath);
    }

    /// <summary>
    /// Stream copy can only start on a keyframe. Cutting a few seconds off the start
    /// usually lands between keyframes, so ffmpeg keeps the previous GOP (often from 0).
    /// </summary>
    private static bool CanStreamCopyTrim(double startSeconds, IReadOnlyList<double> keyframes)
    {
        const double startToleranceSeconds = 0.04;
        if (startSeconds <= startToleranceSeconds)
        {
            return true;
        }

        if (keyframes.Count == 0)
        {
            return false;
        }

        double? previous = null;
        foreach (var keyframe in keyframes)
        {
            if (keyframe <= startSeconds + 0.001)
            {
                previous = keyframe;
            }
            else
            {
                break;
            }
        }

        return previous is not null && startSeconds - previous.Value <= startToleranceSeconds;
    }

    private static bool HasOutput(string path) =>
        File.Exists(path) && new FileInfo(path).Length > 0;

    private sealed record VideoColorInfo(
        string? PixFmt,
        string? ColorSpace,
        string? ColorPrimaries,
        string? ColorTransfer,
        string? ColorRange);

    private static async Task<IReadOnlyList<double>> TryGetKeyframeTimesAsync(
        string inputPath,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await RunCaptureAsync(
                "ffprobe",
                [
                    "-v", "error",
                    "-select_streams", "v:0",
                    "-show_entries", "packet=pts_time,flags",
                    "-of", "csv=p=0",
                    inputPath
                ],
                cancellationToken);

            if (result.ExitCode != 0 || string.IsNullOrWhiteSpace(result.Stdout))
            {
                return [];
            }

            var times = new List<double>();
            using var reader = new StringReader(result.Stdout);
            while (await reader.ReadLineAsync(cancellationToken) is { } line)
            {
                var parts = line.Split(',', StringSplitOptions.TrimEntries);
                if (parts.Length < 2 || parts[1].IndexOf('K', StringComparison.OrdinalIgnoreCase) < 0)
                {
                    continue;
                }

                if (double.TryParse(parts[0], NumberStyles.Float, CultureInfo.InvariantCulture, out var seconds)
                    && !double.IsNaN(seconds)
                    && seconds >= 0)
                {
                    times.Add(seconds);
                }
            }

            times.Sort();
            return times;
        }
        catch
        {
            return [];
        }
    }

    private static async Task<VideoColorInfo?> TryGetVideoColorInfoAsync(
        string inputPath,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await RunCaptureAsync(
                "ffprobe",
                [
                    "-v", "error",
                    "-select_streams", "v:0",
                    "-show_entries", "stream=pix_fmt,color_space,color_primaries,color_transfer,color_range",
                    "-of", "default=noprint_wrappers=1:nokey=0",
                    inputPath
                ],
                cancellationToken);

            if (result.ExitCode != 0 || string.IsNullOrWhiteSpace(result.Stdout))
            {
                return null;
            }

            string? pixFmt = null;
            string? colorSpace = null;
            string? colorPrimaries = null;
            string? colorTransfer = null;
            string? colorRange = null;
            using var reader = new StringReader(result.Stdout);
            while (await reader.ReadLineAsync(cancellationToken) is { } line)
            {
                var separator = line.IndexOf('=');
                if (separator <= 0)
                {
                    continue;
                }

                var key = line[..separator].Trim();
                var value = line[(separator + 1)..].Trim();
                if (!IsUsableColorValue(value) && key != "pix_fmt")
                {
                    continue;
                }

                switch (key)
                {
                    case "pix_fmt":
                        pixFmt = IsUsableColorValue(value) ? value : pixFmt;
                        break;
                    case "color_space":
                        colorSpace = value;
                        break;
                    case "color_primaries":
                        colorPrimaries = value;
                        break;
                    case "color_transfer":
                        colorTransfer = value;
                        break;
                    case "color_range":
                        colorRange = value;
                        break;
                }
            }

            return new VideoColorInfo(pixFmt, colorSpace, colorPrimaries, colorTransfer, colorRange);
        }
        catch
        {
            return null;
        }
    }

    private static async Task<(int ExitCode, string Stdout, string Stderr)> RunCaptureAsync(
        string fileName,
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken)
    {
        using var process = new Process
        {
            StartInfo = new ProcessStartInfo
            {
                FileName = fileName,
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
            return (-1, "", "Failed to start process.");
        }

        var stdoutTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
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

        return (process.ExitCode, await stdoutTask, await stderrTask);
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
