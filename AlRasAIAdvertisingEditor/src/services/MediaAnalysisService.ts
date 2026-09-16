import fs from "node:fs";
import path from "node:path";
import type { FrameAnalysis, VideoAnalysis } from "../schemas/analysis.js";
import { FFmpegService } from "./FFmpegService.js";
import { cachePath, hasValidCache, readJsonIfExists, writeJson } from "../utils/fs.js";
import { jobIdFromVideo, toProjectRelative } from "../utils/paths.js";
import type { Logger } from "../utils/logger.js";
import type { Phrase } from "../schemas/analysis.js";
import { runFfprobe } from "../utils/ffmpeg.js";

export class MediaAnalysisService {
  private ffmpeg = new FFmpegService();

  async analyze(
    videoPath: string,
    phrases: Phrase[],
    logger: Logger,
    force = false,
  ): Promise<VideoAnalysis> {
    const jobId = jobIdFromVideo(videoPath);
    const cacheFile = cachePath(jobId, "video-analysis.json");
    if (!force && hasValidCache(cacheFile)) {
      const cached = readJsonIfExists<VideoAnalysis>(cacheFile);
      if (cached) {
        logger.info("Using cached video analysis");
        return cached;
      }
    }

    const info = await this.ffmpeg.probe(videoPath);
    const framesDir = cachePath(jobId, "frames");
    logger.info("Extracting representative frames");
    const rawFrames = await this.ffmpeg.extractRepresentativeFrames(
      videoPath,
      framesDir,
      info.duration,
      { maxFrames: 20 },
    );

    for (const phrase of phrases.slice(0, 8)) {
      const mid = (phrase.start + phrase.end) / 2;
      const out = path.join(framesDir, `speech_${mid.toFixed(2)}.jpg`);
      if (!fs.existsSync(out)) {
        try {
          await this.ffmpeg.extractFrame(videoPath, mid, out);
          rawFrames.push({ path: out, timestamp: mid });
        } catch {
          /* skip */
        }
      }
    }

    const frames: FrameAnalysis[] = [];
    for (const f of rawFrames) {
      frames.push(await this.classifyFrame(f.path, f.timestamp, info));
    }

    const sceneChangeTimestamps = frames
      .filter((f) => f.labels.includes("scene_change"))
      .map((f) => f.timestamp);

    for (let i = 1; i < frames.length; i++) {
      const prev = frames[i - 1]!;
      const cur = frames[i]!;
      if (
        prev.brightness != null &&
        cur.brightness != null &&
        Math.abs(cur.brightness - prev.brightness) > 35
      ) {
        if (!cur.labels.includes("scene_change")) cur.labels.push("scene_change");
        sceneChangeTimestamps.push(cur.timestamp);
      }
    }

    const analysis: VideoAnalysis = {
      duration: info.duration,
      width: info.width,
      height: info.height,
      fps: info.fps,
      hasAudio: info.hasAudio,
      frames: frames.map((f) => ({
        ...f,
        path: toProjectRelative(f.path),
      })),
      sceneChangeTimestamps: [...new Set(sceneChangeTimestamps)].sort((a, b) => a - b),
    };

    writeJson(cacheFile, analysis);
    logger.info("Video analysis complete", { frames: frames.length });
    return analysis;
  }

  private async classifyFrame(
    filePath: string,
    timestamp: number,
    videoInfo: { width: number; height: number },
  ): Promise<FrameAnalysis> {
    const labels: FrameAnalysis["labels"] = [];
    let brightness = 128;

    try {
      // Sample mean brightness via ffmpeg signalstats
      const { stderr } = await runFfprobe([
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "frame=pkt_size",
        "-of",
        "csv=p=0",
        "-read_intervals",
        "%+#1",
        filePath,
      ]).catch(() => ({ stderr: "", stdout: "" }));
      void stderr;

      const size = fs.statSync(filePath).size;
      // Rough brightness proxy from JPEG size relative to resolution
      const pixels = videoInfo.width * videoInfo.height;
      brightness = Math.min(255, Math.max(20, (size / Math.max(pixels, 1)) * 12));

      const aspect = videoInfo.width / Math.max(videoInfo.height, 1);
      if (brightness < 40) labels.push("empty_background");
      else if (brightness > 180) labels.push("important_moment");
      else labels.push("person_speaking");

      if (aspect < 0.7) {
        labels.push("phone");
        labels.push("broll_opportunity");
      }
      if (aspect > 1.4) labels.push("camera_movement");
      if (brightness > 90 && brightness < 200 && aspect > 0.45 && aspect < 0.7) {
        labels.push("app_screen");
      }
    } catch {
      labels.push("unknown");
    }

    if (!labels.length) labels.push("unknown");

    return {
      path: filePath,
      timestamp,
      labels: [...new Set(labels)],
      brightness,
      notes: "Heuristic frame labels from file metrics/aspect (not semantic OCR)",
    };
  }
}
