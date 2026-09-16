import path from "node:path";
import fs from "node:fs";
import { bundle } from "@remotion/bundler";
import { renderMedia, selectComposition } from "@remotion/renderer";
import type { EditingPlan } from "../schemas/editing-plan.js";
import { PROJECT_ROOT } from "../utils/paths.js";
import { ensureDir } from "../utils/fs.js";
import type { Logger } from "../utils/logger.js";

export interface RenderOptions {
  plan: EditingPlan;
  outputPath: string;
  preview?: boolean;
  scale?: number;
  concurrency?: number | null;
}

let bundleLocationCache: string | null = null;

export class RemotionRenderService {
  async ensureBundle(logger: Logger): Promise<string> {
    if (bundleLocationCache && fs.existsSync(bundleLocationCache)) {
      return bundleLocationCache;
    }
    const entry = path.join(PROJECT_ROOT, "src/remotion/index.tsx");
    logger.info("Bundling Remotion composition");
    const location = await bundle({
      entryPoint: entry,
      // Project root is public so staticFile('assets/…') and staticFile('input/…') work
      publicDir: PROJECT_ROOT,
      webpackOverride: (config) => config,
    });
    bundleLocationCache = location;
    return location;
  }

  async render(options: RenderOptions, logger: Logger): Promise<string> {
    const { plan, outputPath, preview } = options;
    ensureDir(path.dirname(outputPath));

    // Invalidate bundle cache when needed — keep for session
    const serveUrl = await this.ensureBundle(logger);
    const inputProps = {
      plan: this.toRelativePlan(plan),
    };

    const composition = await selectComposition({
      serveUrl,
      id: "AlRasAd",
      inputProps,
    });

    const scale = preview ? (options.scale ?? 0.35) : 1;
    logger.info("Rendering with Remotion", {
      frames: composition.durationInFrames,
      preview: Boolean(preview),
      scale,
      outputPath,
    });

    await renderMedia({
      composition,
      serveUrl,
      codec: "h264",
      outputLocation: outputPath,
      inputProps,
      scale,
      crf: preview ? 28 : 18,
      concurrency: options.concurrency ?? (preview ? 2 : null),
    });

    logger.info("Remotion render complete", { outputPath });
    return outputPath;
  }

  /** Keep project-relative paths for staticFile() resolution */
  private toRelativePlan(plan: EditingPlan): EditingPlan {
    const rel = (p?: string) => {
      if (!p) return p;
      if (p.startsWith("http") || p.startsWith("data:")) return p;
      const normalized = p.replace(/\\/g, "/");
      if (!path.isAbsolute(p) && !/^[A-Za-z]:/.test(p)) return normalized;
      const absolute = path.resolve(p);
      const relative = path.relative(PROJECT_ROOT, absolute).replace(/\\/g, "/");
      if (relative.startsWith("..")) {
        throw new Error(`Media path outside project root: ${p}`);
      }
      return relative;
    };

    return {
      ...plan,
      music: plan.music ? { ...plan.music, path: rel(plan.music.path)! } : undefined,
      scenes: plan.scenes.map((s) => ({
        ...s,
        source: { ...s.source, path: rel(s.source.path) },
        visual: { ...s.visual, path: rel(s.visual.path) },
        overlays: (s.overlays ?? []).map((o) => ({ ...o, path: rel(o.path) })),
        audio: (s.audio ?? []).map((a) => ({ ...a, path: rel(a.path)! })),
      })),
    };
  }
}
