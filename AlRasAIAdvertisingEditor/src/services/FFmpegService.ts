import fs from "node:fs";
import path from "node:path";
import { runFfmpeg, runFfprobe } from "../utils/ffmpeg.js";
import { ensureDir } from "../utils/fs.js";

export interface MediaInfo {
  duration: number;
  width: number;
  height: number;
  fps: number;
  hasAudio: boolean;
  codec?: string;
}

export class FFmpegService {
  async probe(filePath: string): Promise<MediaInfo> {
    const { stdout } = await runFfprobe([
      "-v",
      "quiet",
      "-print_format",
      "json",
      "-show_format",
      "-show_streams",
      filePath,
    ]);
    const data = JSON.parse(stdout) as {
      format?: { duration?: string };
      streams?: Array<{
        codec_type?: string;
        width?: number;
        height?: number;
        r_frame_rate?: string;
        codec_name?: string;
      }>;
    };
    const video = data.streams?.find((s) => s.codec_type === "video");
    const audio = data.streams?.find((s) => s.codec_type === "audio");
    const duration = Number(data.format?.duration ?? 0);
    let fps = 30;
    if (video?.r_frame_rate?.includes("/")) {
      const [a, b] = video.r_frame_rate.split("/").map(Number);
      if (a && b) fps = a / b;
    }
    return {
      duration,
      width: video?.width ?? 1080,
      height: video?.height ?? 1920,
      fps,
      hasAudio: Boolean(audio),
      codec: video?.codec_name,
    };
  }

  async extractAudio(videoPath: string, outputWav: string): Promise<string> {
    ensureDir(path.dirname(outputWav));
    await runFfmpeg([
      "-i",
      videoPath,
      "-vn",
      "-acodec",
      "pcm_s16le",
      "-ar",
      "16000",
      "-ac",
      "1",
      outputWav,
    ]);
    return outputWav;
  }

  async extractFrame(videoPath: string, timestamp: number, outputPath: string): Promise<string> {
    ensureDir(path.dirname(outputPath));
    await runFfmpeg([
      "-ss",
      String(Math.max(0, timestamp)),
      "-i",
      videoPath,
      "-frames:v",
      "1",
      "-q:v",
      "2",
      outputPath,
    ]);
    return outputPath;
  }

  /**
   * Scene-change + periodic frame extraction (bounded).
   */
  async extractRepresentativeFrames(
    videoPath: string,
    outputDir: string,
    duration: number,
    options?: { maxFrames?: number; intervalSeconds?: number },
  ): Promise<{ path: string; timestamp: number }[]> {
    ensureDir(outputDir);
    const maxFrames = options?.maxFrames ?? 24;
    const interval = options?.intervalSeconds ?? Math.max(1.5, duration / Math.max(8, maxFrames / 2));
    const timestamps = new Set<number>();

    // Periodic samples
    for (let t = 0.2; t < duration - 0.1; t += interval) {
      timestamps.add(Number(t.toFixed(2)));
    }
    timestamps.add(0.1);
    timestamps.add(Number(Math.max(0, duration - 0.15).toFixed(2)));

    // Scene-change detection via select filter (bounded)
    const sceneListPath = path.join(outputDir, "scenes.txt");
    try {
      await runFfmpeg(
        [
          "-i",
          videoPath,
          "-vf",
          "select='gt(scene,0.35)',showinfo",
          "-vsync",
          "vfr",
          "-f",
          "null",
          "-",
        ],
        { timeoutMs: 120_000 },
      ).then((r) => {
        const matches = [...r.stderr.matchAll(/pts_time:([0-9.]+)/g)];
        for (const m of matches.slice(0, 12)) {
          timestamps.add(Number(Number(m[1]).toFixed(2)));
        }
        fs.writeFileSync(
          sceneListPath,
          matches.map((m) => m[1]).join("\n"),
          "utf8",
        );
      });
    } catch {
      // scene detect optional
    }

    const sorted = [...timestamps].sort((a, b) => a - b).slice(0, maxFrames);
    const frames: { path: string; timestamp: number }[] = [];
    for (let i = 0; i < sorted.length; i++) {
      const t = sorted[i]!;
      const out = path.join(outputDir, `frame_${String(i).padStart(3, "0")}_${t.toFixed(2)}.jpg`);
      if (!fs.existsSync(out)) {
        await this.extractFrame(videoPath, t, out);
      }
      frames.push({ path: out, timestamp: t });
    }
    return frames;
  }

  async postProcess(
    inputPath: string,
    outputPath: string,
    options?: { crf?: number; audioBitrate?: string },
  ): Promise<string> {
    ensureDir(path.dirname(outputPath));
    await runFfmpeg([
      "-i",
      inputPath,
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-crf",
      String(options?.crf ?? 18),
      "-c:a",
      "aac",
      "-b:a",
      options?.audioBitrate ?? "192k",
      "-movflags",
      "+faststart",
      outputPath,
    ]);
    return outputPath;
  }

  async generateSilentVideo(
    outputPath: string,
    duration: number,
    width: number,
    height: number,
  ): Promise<string> {
    ensureDir(path.dirname(outputPath));
    await runFfmpeg([
      "-f",
      "lavfi",
      "-i",
      `color=c=0x0A1628:s=${width}x${height}:d=${duration}`,
      "-f",
      "lavfi",
      "-i",
      `anullsrc=r=44100:cl=stereo`,
      "-t",
      String(duration),
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-c:a",
      "aac",
      "-shortest",
      outputPath,
    ]);
    return outputPath;
  }
}
