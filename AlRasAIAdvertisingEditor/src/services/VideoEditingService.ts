import path from "node:path";
import fs from "node:fs";
import { FFmpegService } from "./FFmpegService.js";
import { TranscriptionService } from "./TranscriptionService.js";
import { MediaAnalysisService } from "./MediaAnalysisService.js";
import { AssetAnalysisService } from "./AssetAnalysisService.js";
import { CreativeDirectorService, loadBrand } from "./CreativeDirectorService.js";
import { EditingPlanService } from "./EditingPlanService.js";
import { RemotionRenderService } from "./RemotionRenderService.js";
import { Logger } from "../utils/logger.js";
import {
  PROJECT_ROOT,
  DIRS,
  jobIdFromVideo,
  toProjectRelative,
  resolveProjectPath,
} from "../utils/paths.js";
import {
  SUPPORTED_VIDEO,
  ensureDir,
  hasValidCache,
  readJsonIfExists,
  writeJson,
} from "../utils/fs.js";
import type { EditingPlan } from "../schemas/editing-plan.js";
import type { BrandConfig } from "../schemas/analysis.js";

export interface EditOptions {
  videoPath: string;
  dryRun?: boolean;
  preview?: boolean;
  force?: boolean;
  format?: "9:16" | "16:9" | "1:1";
  skipRender?: boolean;
  planOnly?: boolean;
  analyzeOnly?: boolean;
}

export interface EditResult {
  jobId: string;
  transcriptPath: string;
  planPath: string;
  outputPath?: string;
  plan: EditingPlan;
}

export class VideoEditingService {
  private ffmpeg = new FFmpegService();
  private transcription = new TranscriptionService();
  private media = new MediaAnalysisService();
  private assets = new AssetAnalysisService();
  private director = new CreativeDirectorService();
  private plans = new EditingPlanService();
  private renderer = new RemotionRenderService();

  async edit(options: EditOptions): Promise<EditResult> {
    const absVideo = path.isAbsolute(options.videoPath)
      ? options.videoPath
      : resolveProjectPath(options.videoPath.replace(/^\.\//, ""));

    if (!fs.existsSync(absVideo)) {
      throw new Error(`Input video not found: ${options.videoPath}`);
    }
    const ext = path.extname(absVideo).toLowerCase();
    if (!SUPPORTED_VIDEO.has(ext)) {
      throw new Error(`Unsupported video format: ${ext}`);
    }

    const jobId = jobIdFromVideo(absVideo);
    const logger = new Logger(jobId);
    ensureDir(DIRS.temp);
    ensureDir(DIRS.output);
    ensureDir(DIRS.renders);
    ensureDir(DIRS.editingPlans);
    ensureDir(DIRS.transcripts);

    logger.info("=== Al Ras AI Advertising Editor ===", { jobId, video: absVideo });

    try {
      // 1–3. Transcribe
      const transcript = await this.transcription.transcribe(absVideo, logger, options.force);
      const transcriptPath = path.join(DIRS.transcripts, `${jobId}.json`);

      // 4–5. Media analysis
      const videoAnalysis = await this.media.analyze(
        absVideo,
        transcript.phrases,
        logger,
        options.force,
      );

      // 6. Assets
      const assets = await this.assets.analyze(logger, jobId, options.force);

      if (options.analyzeOnly) {
        const analysisOut = path.join(DIRS.temp, jobId, "full-analysis.json");
        writeJson(analysisOut, { transcript, videoAnalysis, assets });
        logger.info("Analyze-only complete", { analysisOut });
        return {
          jobId,
          transcriptPath,
          planPath: "",
          plan: this.plans.buildFallback({
            videoPath: toProjectRelative(absVideo),
            duration: transcript.duration,
            phrases: transcript.phrases,
            language: (transcript.language as "ar") || "ar",
            format: options.format ?? "9:16",
          }),
        };
      }

      const brand = loadBrand(path.join(PROJECT_ROOT, "brand.json")) as BrandConfig;
      const format = options.format ?? brand.defaultFormat ?? "9:16";

      // 7–9. Editing plan (with fallback)
      let plan: EditingPlan;
      const planCache = path.join(DIRS.editingPlans, `${jobId}.json`);
      if (!options.force && hasValidCache(planCache) && !options.planOnly) {
        const cached = readJsonIfExists<EditingPlan>(planCache);
        const parsed = cached ? this.plans.safeParse(cached) : null;
        if (parsed?.success) {
          logger.info("Using cached editing plan");
          plan = parsed.data;
        } else {
          plan = await this.generatePlan(
            absVideo,
            transcript,
            videoAnalysis,
            assets,
            brand,
            format,
            logger,
          );
        }
      } else {
        plan = await this.generatePlan(
          absVideo,
          transcript,
          videoAnalysis,
          assets,
          brand,
          format,
          logger,
        );
      }

      plan = this.plans.sanitize(plan, logger);
      const planPath = this.plans.save(jobId, plan);
      logger.info("Editing plan saved", { planPath, scenes: plan.scenes.length });

      if (options.dryRun || options.planOnly || options.skipRender) {
        logger.info(options.dryRun ? "Dry run complete (no render)" : "Plan-only complete");
        return { jobId, transcriptPath, planPath, plan };
      }

      // 10–12. Render + post-process
      const renderPath = path.join(
        DIRS.renders,
        `${jobId}${options.preview ? "-preview" : "-raw"}.mp4`,
      );
      await this.renderer.render(
        {
          plan,
          outputPath: renderPath,
          preview: options.preview,
          scale: options.preview ? 0.35 : 1,
        },
        logger,
      );

      const outputName = `${jobId}${options.preview ? "-preview" : "-final"}.mp4`;
      const outputPath = path.join(DIRS.output, outputName);
      await this.ffmpeg.postProcess(renderPath, outputPath, {
        crf: options.preview ? 28 : 18,
      });
      logger.info("Final output ready", { outputPath });

      return { jobId, transcriptPath, planPath, outputPath, plan };
    } catch (err) {
      logger.error("Pipeline failed", {
        error: err instanceof Error ? err.message : String(err),
      });
      throw err;
    } finally {
      logger.close();
    }
  }

  async renderPlan(planPath: string, preview = false): Promise<string> {
    const plan = this.plans.load(planPath);
    const jobId =
      path.basename(planPath, path.extname(planPath)).replace(/[^\w\-]+/g, "-") || "render";
    const logger = new Logger(jobId);
    try {
      const sanitized = this.plans.sanitize(plan, logger);
      const renderPath = path.join(DIRS.renders, `${jobId}${preview ? "-preview" : "-raw"}.mp4`);
      await this.renderer.render({ plan: sanitized, outputPath: renderPath, preview }, logger);
      const outputPath = path.join(
        DIRS.output,
        `${jobId}${preview ? "-preview" : "-final"}.mp4`,
      );
      await this.ffmpeg.postProcess(renderPath, outputPath, { crf: preview ? 28 : 18 });
      logger.info("Render complete", { outputPath });
      return outputPath;
    } finally {
      logger.close();
    }
  }

  private async generatePlan(
    absVideo: string,
    transcript: Awaited<ReturnType<TranscriptionService["transcribe"]>>,
    videoAnalysis: Awaited<ReturnType<MediaAnalysisService["analyze"]>>,
    assets: Awaited<ReturnType<AssetAnalysisService["analyze"]>>,
    brand: BrandConfig,
    format: "9:16" | "16:9" | "1:1",
    logger: Logger,
  ): Promise<EditingPlan> {
    try {
      return await this.director.createPlan(
        {
          videoPath: absVideo,
          transcript,
          videoAnalysis,
          assets,
          brand,
          format,
        },
        logger,
      );
    } catch (err) {
      logger.warn("Creative director failed — using deterministic fallback", {
        error: err instanceof Error ? err.message : String(err),
      });
      return this.plans.buildFallback({
        videoPath: toProjectRelative(absVideo),
        duration: Math.max(transcript.duration, videoAnalysis.duration),
        phrases: transcript.phrases,
        language: (transcript.language as "ar") || "ar",
        format,
      });
    }
  }
}
