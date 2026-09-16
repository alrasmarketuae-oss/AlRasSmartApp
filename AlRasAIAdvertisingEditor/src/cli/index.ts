#!/usr/bin/env node
import "dotenv/config";
import { Command } from "commander";
import path from "node:path";
import { runPipeline, runRender } from "../pipeline/run.js";
import { PROJECT_ROOT } from "../utils/paths.js";
import { ensureFfmpegOnPath } from "../utils/ffmpeg.js";

ensureFfmpegOnPath();

const program = new Command();

program
  .name("alras-ai-editor")
  .description("Al Ras Market AI Advertising Video Editor")
  .version("1.0.0");

program
  .command("edit")
  .description("Full pipeline: transcribe → analyze → plan → render → final MP4")
  .argument("<video>", "Path to input video (e.g. input/video.mp4)")
  .option("--dry-run", "Transcribe, analyze, and plan without rendering", false)
  .option("--force", "Ignore caches and regenerate", false)
  .option("--format <format>", "Output format: 9:16 | 16:9 | 1:1", "9:16")
  .action(async (video: string, opts: { dryRun?: boolean; force?: boolean; format?: string }) => {
    const result = await runPipeline({
      videoPath: normalizeVideoArg(video),
      dryRun: opts.dryRun,
      force: opts.force,
      format: opts.format as "9:16" | "16:9" | "1:1",
    });
    printResult(result);
  });

program
  .command("preview")
  .description("Low-resolution preview render")
  .argument("<video>", "Path to input video")
  .option("--force", "Ignore caches", false)
  .action(async (video: string, opts: { force?: boolean }) => {
    const result = await runPipeline({
      videoPath: normalizeVideoArg(video),
      preview: true,
      force: opts.force,
    });
    printResult(result);
  });

program
  .command("analyze")
  .description("Transcribe + analyze video and assets only")
  .argument("<video>", "Path to input video")
  .option("--force", "Ignore caches", false)
  .action(async (video: string, opts: { force?: boolean }) => {
    const result = await runPipeline({
      videoPath: normalizeVideoArg(video),
      analyzeOnly: true,
      force: opts.force,
    });
    console.log(JSON.stringify({ jobId: result.jobId, transcriptPath: result.transcriptPath }, null, 2));
  });

program
  .command("plan")
  .description("Generate EditingPlan JSON without rendering")
  .argument("<video>", "Path to input video")
  .option("--force", "Ignore caches", false)
  .option("--format <format>", "9:16 | 16:9 | 1:1", "9:16")
  .action(async (video: string, opts: { force?: boolean; format?: string }) => {
    const result = await runPipeline({
      videoPath: normalizeVideoArg(video),
      planOnly: true,
      force: opts.force,
      format: opts.format as "9:16" | "16:9" | "1:1",
    });
    printResult(result);
  });

program
  .command("render")
  .description("Render an existing EditingPlan JSON")
  .argument("<plan>", "Path to editing-plans/*.json")
  .option("--preview", "Low-res preview", false)
  .action(async (plan: string, opts: { preview?: boolean }) => {
    const planPath = path.isAbsolute(plan) ? plan : path.resolve(PROJECT_ROOT, plan);
    const output = await runRender(planPath, opts.preview);
    console.log(JSON.stringify({ output }, null, 2));
  });

function normalizeVideoArg(video: string): string {
  if (path.isAbsolute(video)) return video;
  return video.replace(/\\/g, "/");
}

function printResult(result: {
  jobId: string;
  transcriptPath: string;
  planPath: string;
  outputPath?: string;
  plan: { scenes: unknown[]; duration: number };
}) {
  console.log(
    JSON.stringify(
      {
        jobId: result.jobId,
        transcriptPath: result.transcriptPath,
        planPath: result.planPath,
        outputPath: result.outputPath,
        scenes: result.plan.scenes.length,
        duration: result.plan.duration,
      },
      null,
      2,
    ),
  );
}

program.parseAsync(process.argv).catch((err) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
