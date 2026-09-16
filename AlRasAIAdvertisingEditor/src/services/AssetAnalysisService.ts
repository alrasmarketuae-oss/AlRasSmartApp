import fs from "node:fs";
import path from "node:path";
import type { AssetAnalysis } from "../schemas/analysis.js";
import { DIRS, toProjectRelative } from "../utils/paths.js";
import {
  SUPPORTED_AUDIO,
  SUPPORTED_IMAGE,
  cachePath,
  hasValidCache,
  readJsonIfExists,
  writeJson,
} from "../utils/fs.js";
import type { Logger } from "../utils/logger.js";
import { runFfprobe } from "../utils/ffmpeg.js";

const TOPIC_HINTS: Array<{
  match: RegExp;
  topics: string[];
  purpose: string;
  type: AssetAnalysis["type"];
}> = [
  { match: /logo/i, topics: ["brand", "logo"], purpose: "brand_logo", type: "logo" },
  {
    match: /home|الرئيس|dashboard/i,
    topics: ["home", "app", "browse"],
    purpose: "app_home",
    type: "app_screenshot",
  },
  {
    match: /search|بحث/i,
    topics: ["search", "products", "find products"],
    purpose: "product_search",
    type: "app_screenshot",
  },
  {
    match: /product|منتج|catalog|list/i,
    topics: ["products", "catalog", "prices"],
    purpose: "product_listing",
    type: "app_screenshot",
  },
  {
    match: /detail|تفاصيل|price|سعر/i,
    topics: ["product details", "prices"],
    purpose: "product_details",
    type: "app_screenshot",
  },
  {
    match: /cart|order|طلب|checkout/i,
    topics: ["order", "checkout"],
    purpose: "ordering_flow",
    type: "app_screenshot",
  },
  { match: /music|bgm|underscore/i, topics: ["music"], purpose: "background_music", type: "music" },
  {
    match: /sfx|whoosh|click|pop|reveal/i,
    topics: ["sfx"],
    purpose: "sound_effect",
    type: "sfx",
  },
];

export class AssetAnalysisService {
  async analyze(logger: Logger, jobId = "assets", force = false): Promise<AssetAnalysis[]> {
    const cacheFile = cachePath(jobId, "asset-analysis.json");
    if (!force && hasValidCache(cacheFile)) {
      const cached = readJsonIfExists<AssetAnalysis[]>(cacheFile);
      if (cached) {
        logger.info("Using cached asset analysis", { count: cached.length });
        return cached;
      }
    }

    const results: AssetAnalysis[] = [];
    if (fs.existsSync(DIRS.assets)) {
      for (const file of walkFiles(DIRS.assets)) {
        const ext = path.extname(file).toLowerCase();
        if (!SUPPORTED_IMAGE.has(ext) && !SUPPORTED_AUDIO.has(ext)) continue;
        results.push(await this.analyzeOne(file));
      }
    }

    writeJson(cacheFile, results);
    logger.info("Asset analysis complete", { count: results.length });
    return results;
  }

  private async analyzeOne(filePath: string): Promise<AssetAnalysis> {
    const filename = path.basename(filePath);
    const relative = toProjectRelative(filePath);
    const ext = path.extname(filePath).toLowerCase();
    const exists = fs.existsSync(filePath);

    let width: number | undefined;
    let height: number | undefined;
    let aspectRatio: number | undefined;

    if (SUPPORTED_IMAGE.has(ext) && exists) {
      try {
        const { stdout } = await runFfprobe([
          "-v",
          "quiet",
          "-print_format",
          "json",
          "-show_streams",
          filePath,
        ]);
        const data = JSON.parse(stdout) as {
          streams?: Array<{ width?: number; height?: number }>;
        };
        width = data.streams?.[0]?.width;
        height = data.streams?.[0]?.height;
        if (width && height) aspectRatio = width / height;
      } catch {
        /* ignore */
      }
    }

    const hint = TOPIC_HINTS.find((h) => h.match.test(filename));
    let type: AssetAnalysis["type"] = hint?.type ?? "other";
    if (!hint && SUPPORTED_AUDIO.has(ext)) {
      type = filename.toLowerCase().includes("music") ? "music" : "sfx";
    }
    if (!hint && SUPPORTED_IMAGE.has(ext) && aspectRatio != null) {
      if (aspectRatio < 0.7) type = "app_screenshot";
      else if (aspectRatio > 1.1) type = "marketing_image";
    }

    const isAppScreenshot = type === "app_screenshot";
    const isProductImage = type === "product_image" || /product/i.test(filename);

    return {
      asset: relative,
      filename,
      width,
      height,
      aspectRatio,
      type,
      purpose: hint?.purpose ?? (isAppScreenshot ? "app_ui" : type),
      topics: hint?.topics ?? deriveTopicsFromName(filename),
      isAppScreenshot,
      isProductImage,
      containsTextLikely: isAppScreenshot,
      exists,
    };
  }
}

function deriveTopicsFromName(filename: string): string[] {
  const stem = filename.replace(/\.[^.]+$/, "").toLowerCase();
  return stem.split(/[-_\s]+/).filter((t) => t.length > 2);
}

function walkFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walkFiles(full));
    else out.push(full);
  }
  return out;
}
