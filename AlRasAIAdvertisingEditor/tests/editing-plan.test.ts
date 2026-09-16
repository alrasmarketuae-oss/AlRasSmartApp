import { describe, it, expect } from "vitest";
import { EditingPlanSchema } from "../src/schemas/editing-plan.js";
import { TranscriptSchema } from "../src/schemas/analysis.js";
import { splitCaptionPhrases, detectLanguageFromText, isArabicText } from "../src/utils/fs.js";
import { EditingPlanService } from "../src/services/EditingPlanService.js";
import { CreativeDirectorService } from "../src/services/CreativeDirectorService.js";
import { Logger } from "../src/utils/logger.js";
import path from "node:path";
import fs from "node:fs";
import { PROJECT_ROOT } from "../src/utils/paths.js";

describe("caption utilities", () => {
  it("splits long Arabic captions into short phrases", () => {
    const text =
      "مع تطبيق Al Ras Market يمكنك البحث عن جميع المنتجات المتوفرة لدى الموردين ومقارنتها بسهولة";
    const parts = splitCaptionPhrases(text, 28);
    expect(parts.length).toBeGreaterThan(1);
    expect(parts.every((p) => p.length <= 40)).toBe(true);
  });

  it("detects Arabic language", () => {
    expect(detectLanguageFromText("بتدور على منتجات")).toBe("ar");
    expect(isArabicText("حمّل الآن")).toBe(true);
  });
});

describe("transcript schema", () => {
  it("validates timed phrases", () => {
    const t = TranscriptSchema.parse({
      language: "ar",
      text: "مرحبا",
      duration: 2,
      phrases: [{ text: "مرحبا", start: 0, end: 1.5 }],
      words: [{ word: "مرحبا", start: 0, end: 1.5 }],
      sourceVideo: "input/video.mp4",
    });
    expect(t.phrases[0]!.end).toBe(1.5);
  });
});

describe("EditingPlan validation", () => {
  it("accepts a valid plan", () => {
    const plan = EditingPlanSchema.parse({
      version: 1,
      format: "9:16",
      language: "ar",
      fps: 30,
      duration: 5,
      scenes: [
        {
          id: "scene-1",
          start: 0,
          end: 3.5,
          source: { type: "video", path: "input/video.mp4" },
          visual: { type: "talking_head" },
          camera: { type: "slow_zoom", from: 1, to: 1.08 },
          caption: {
            text: "بتدور على منتجات بالجملة؟",
            start: 0.2,
            end: 3.3,
            animation: "fade_up",
          },
          transitionIn: "fade",
          transitionOut: "smooth_push",
        },
      ],
    });
    expect(plan.scenes).toHaveLength(1);
  });

  it("rejects end <= start", () => {
    const result = EditingPlanSchema.safeParse({
      version: 1,
      format: "9:16",
      language: "ar",
      duration: 5,
      scenes: [
        {
          id: "bad",
          start: 2,
          end: 1,
          source: { type: "color", color: "#000" },
          visual: { type: "talking_head" },
        },
      ],
    });
    expect(result.success).toBe(false);
  });

  it("rejects path traversal", () => {
    const result = EditingPlanSchema.safeParse({
      version: 1,
      format: "9:16",
      language: "ar",
      duration: 5,
      scenes: [
        {
          id: "bad",
          start: 0,
          end: 2,
          source: { type: "video", path: "../secrets/x.mp4" },
          visual: { type: "talking_head" },
        },
      ],
    });
    expect(result.success).toBe(false);
  });
});

describe("EditingPlanService fallback", () => {
  it("builds a renderable fallback plan", () => {
    const service = new EditingPlanService();
    const plan = service.buildFallback({
      videoPath: "input/sample.mp4",
      duration: 6,
      phrases: [
        { text: "مرحبا", start: 0, end: 2 },
        { text: "Al Ras Market", start: 2, end: 4 },
      ],
      language: "ar",
      format: "9:16",
    });
    expect(plan.metadata?.directorMode).toBe("fallback");
    expect(plan.scenes.length).toBe(2);
  });
});

describe("CreativeDirector heuristic", () => {
  it("creates a validated storytelling plan", async () => {
    const director = new CreativeDirectorService();
    const logger = new Logger("test-director");
    const plan = await director.createPlan(
      {
        videoPath: path.join(PROJECT_ROOT, "input/sample.mp4"),
        format: "9:16",
        brand: {
          name: "Al Ras Market",
          primaryLanguage: "ar",
          defaultFormat: "9:16",
          logo: "assets/logo.png",
          cta: { ar: "حمّل Al Ras Market الآن" },
          colors: { background: "#0A1628" },
          logoIntro: { enabled: false, durationSeconds: 0 },
          endCard: { enabled: true, durationSeconds: 2 },
        },
        transcript: {
          language: "ar",
          text: "بتدور على منتجات؟ مع Al Ras Market ابحث عن المنتجات",
          duration: 8,
          phrases: [
            { text: "بتدور على منتجات بالجملة؟", start: 0.2, end: 2.5 },
            { text: "مع Al Ras Market تقدر تلاقي منتجاتك بسهولة.", start: 2.6, end: 5.2 },
            { text: "ابحث عن المنتجات وقارن الأسعار.", start: 5.3, end: 7.5 },
          ],
          words: [],
          sourceVideo: "input/sample.mp4",
        },
        videoAnalysis: {
          duration: 8,
          width: 1080,
          height: 1920,
          hasAudio: true,
          frames: [],
          sceneChangeTimestamps: [],
        },
        assets: [
          {
            asset: "assets/search-screen.png",
            filename: "search-screen.png",
            type: "app_screenshot",
            purpose: "product_search",
            topics: ["search", "products"],
            isAppScreenshot: true,
            isProductImage: false,
            containsTextLikely: true,
            exists: fs.existsSync(path.join(PROJECT_ROOT, "assets/search-screen.png")),
          },
          {
            asset: "assets/logo.png",
            filename: "logo.png",
            type: "logo",
            purpose: "brand_logo",
            topics: ["logo"],
            isAppScreenshot: false,
            isProductImage: false,
            containsTextLikely: false,
            exists: fs.existsSync(path.join(PROJECT_ROOT, "assets/logo.png")),
          },
        ],
      },
      logger,
    );
    logger.close();
    expect(plan.version).toBe(1);
    expect(plan.scenes.length).toBeGreaterThan(1);
    expect(plan.scenes.some((s) => s.role === "hook" || s.role === "cta")).toBe(true);
  });
});
