import fs from "node:fs";
import OpenAI from "openai";
import type { Transcript, VideoAnalysis, AssetAnalysis, BrandConfig } from "../schemas/analysis.js";
import type { EditingPlan, Scene } from "../schemas/editing-plan.js";
import { EditingPlanSchema } from "../schemas/editing-plan.js";
import { splitCaptionPhrases, detectLanguageFromText, isArabicText } from "../utils/fs.js";
import { toProjectRelative } from "../utils/paths.js";
import type { Logger } from "../utils/logger.js";

export interface CreativeDirectorInput {
  videoPath: string;
  transcript: Transcript;
  videoAnalysis: VideoAnalysis;
  assets: AssetAnalysis[];
  brand: BrandConfig;
  format: "9:16" | "16:9" | "1:1";
}

const SYSTEM_PROMPT = `You are a senior advertising Creative Director + Video Editor for Al Ras Market (wholesale marketplace app).
You produce ONLY valid JSON matching the EditingPlan schema. No markdown, no commentary, no code.

Rules:
- Show what the speaker is talking about (search → search UI, prices → products UI).
- Prefer short Arabic/English caption phrases, not paragraphs.
- Use cinematic but subtle camera moves (slow_zoom, ken_burns, cinematic_pan).
- Do not invent spoken words. Captions must come from the transcript (shortened OK).
- Only reference asset paths that exist in the provided assets list.
- Source video path must be the given sourceVideo.
- Structure when appropriate: hook → problem → solution → demo → benefit → cta.
- Default format 9:16 mobile ad.
- Never output shell, JS, TS, or FFmpeg commands — JSON only.`;

export class CreativeDirectorService {
  async createPlan(input: CreativeDirectorInput, logger: Logger): Promise<EditingPlan> {
    const forceHeuristic = process.env.FORCE_HEURISTIC_DIRECTOR === "1";
    const apiKey = process.env.OPENAI_API_KEY?.trim();

    if (!forceHeuristic && apiKey) {
      try {
        logger.info("Creative Director: requesting AI editing plan");
        const plan = await this.aiPlan(input, apiKey, logger);
        return plan;
      } catch (err) {
        logger.warn("AI Creative Director failed — falling back to heuristic", {
          error: err instanceof Error ? err.message : String(err),
        });
      }
    } else {
      logger.info("Creative Director: heuristic mode");
    }

    return this.heuristicPlan(input);
  }

  private async aiPlan(
    input: CreativeDirectorInput,
    apiKey: string,
    logger: Logger,
  ): Promise<EditingPlan> {
    const client = new OpenAI({ apiKey });
    const model = process.env.OPENAI_CREATIVE_MODEL || "gpt-4o";

    const payload = {
      sourceVideo: toProjectRelative(input.videoPath),
      format: input.format,
      brand: {
        name: input.brand.name,
        logo: input.brand.logo,
        cta: input.brand.cta,
        colors: input.brand.colors,
      },
      transcript: {
        language: input.transcript.language,
        duration: input.transcript.duration,
        phrases: input.transcript.phrases.map((p) => ({
          text: p.text,
          start: p.start,
          end: p.end,
        })),
      },
      video: {
        duration: input.videoAnalysis.duration,
        sceneChanges: input.videoAnalysis.sceneChangeTimestamps.slice(0, 12),
        frameNotes: input.videoAnalysis.frames.slice(0, 12).map((f) => ({
          t: f.timestamp,
          labels: f.labels,
        })),
      },
      assets: input.assets
        .filter((a) => a.exists)
        .map((a) => ({
          asset: a.asset,
          type: a.type,
          purpose: a.purpose,
          topics: a.topics,
        })),
      schemaHint: {
        version: 1,
        scenes: [
          {
            id: "scene-1",
            start: 0,
            end: 3,
            role: "hook",
            source: { type: "video", path: "input/video.mp4" },
            visual: { type: "talking_head" },
            camera: { type: "slow_zoom", from: 1, to: 1.08 },
            caption: { text: "...", start: 0.2, end: 2.8, animation: "fade_up" },
            transitionIn: "fade",
            transitionOut: "smooth_push",
          },
        ],
      },
    };

    const repair = async (errors: string, previous: string): Promise<EditingPlan> => {
      const repairResp = await client.chat.completions.create({
        model,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          {
            role: "user",
            content: `Fix this EditingPlan JSON. Validation errors:\n${errors}\n\nPrevious JSON:\n${previous}\n\nReturn corrected JSON only.`,
          },
        ],
        temperature: 0.2,
      });
      const fixed = repairResp.choices[0]?.message?.content ?? "{}";
      return EditingPlanSchema.parse(JSON.parse(fixed));
    };

    const resp = await client.chat.completions.create({
      model,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: `Create an EditingPlan for this Al Ras Market ad.\n\n${JSON.stringify(payload)}`,
        },
      ],
      temperature: 0.4,
    });

    const raw = resp.choices[0]?.message?.content ?? "{}";
    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch {
      throw new Error("AI returned non-JSON");
    }

    const first = EditingPlanSchema.safeParse(parsed);
    if (first.success) return first.data;

    logger.warn("EditingPlan validation failed — requesting repair", {
      issues: first.error.issues.slice(0, 8),
    });
    return repair(JSON.stringify(first.error.issues.slice(0, 20)), raw);
  }

  /** Deterministic creative director — visual storytelling from transcript + assets */
  heuristicPlan(input: CreativeDirectorInput): EditingPlan {
    const { transcript, assets, brand, format, videoPath, videoAnalysis } = input;
    const sourceRel = toProjectRelative(videoPath);
    const duration = Math.max(transcript.duration, videoAnalysis.duration, 1);
    const language = (detectLanguageFromText(transcript.text) === "en" ? "en" : "ar") as
      | "ar"
      | "en";

    const logo = assets.find((a) => a.type === "logo" && a.exists);
    const music = assets.find((a) => a.type === "music" && a.exists);
    const screenshots = assets.filter((a) => a.isAppScreenshot && a.exists);
    const findAsset = (...keys: string[]) =>
      screenshots.find((a) => keys.some((k) => a.purpose.includes(k) || a.topics.some((t) => t.includes(k)) || a.filename.toLowerCase().includes(k)));

    const searchUi = findAsset("search", "بحث");
    const homeUi = findAsset("home", "app_home");
    const productsUi = findAsset("product", "catalog", "list", "price");
    const detailsUi = findAsset("detail", "تفاصيل");
    const orderUi = findAsset("order", "cart", "طلب");

    const scenes: Scene[] = [];
    let sceneIdx = 0;
    const nextId = (role: string) => `scene-${++sceneIdx}-${role}`;

    const introDur = brand.logoIntro?.enabled !== false ? brand.logoIntro?.durationSeconds ?? 1.0 : 0;
    if (introDur > 0 && logo) {
      scenes.push({
        id: nextId("logo_intro"),
        start: 0,
        end: Math.min(introDur, duration * 0.15),
        role: "logo_intro",
        source: { type: "color", color: brand.colors?.background ?? "#0A1628" },
        visual: { type: "logo", path: logo.asset, presentation: "fullscreen", scale: 1 },
        camera: { type: "slow_zoom", from: 0.92, to: 1 },
        overlays: [],
        audio: [],
        transitionIn: "cinematic_reveal",
        transitionOut: "fade",
        emphasis: "soft",
      });
    }

    const contentStart = scenes.length ? scenes[scenes.length - 1]!.end : 0;
    const rawPhrases = transcript.phrases.length
      ? transcript.phrases
      : [{ text: brand.tagline?.[language] ?? brand.name, start: contentStart, end: duration }];

    // Remap phrases so they start immediately after logo intro (no black gaps)
    const firstPhraseStart = rawPhrases[0]?.start ?? 0;
    const shift = Math.max(0, contentStart - firstPhraseStart);
    const phrases = rawPhrases.map((p) => ({
      ...p,
      start: p.start + shift,
      end: Math.min(p.end + shift, Math.max(duration, contentStart + 0.5)),
    }));

    for (let i = 0; i < phrases.length; i++) {
      const phrase = phrases[i]!;
      const start = Math.max(phrase.start, contentStart);
      const end = Math.max(start + 0.3, Math.min(phrase.end, Math.max(duration, start + 0.3)));
      if (end - start < 0.25) continue;

      const text = phrase.text;
      const lower = text.toLowerCase();
      const role = classifyRole(text, i, phrases.length);
      const captions = splitCaptionPhrases(text, 28);
      const captionText = captions[0] ?? text.slice(0, 28);

      const match = matchVisual(lower, {
        searchUi,
        homeUi,
        productsUi,
        detailsUi,
        orderUi,
        screenshots,
      });

      const isHook = role === "hook" || i === 0;
      const useScreenshot = Boolean(match.asset) && !isHook;

      const scene: Scene = {
        id: nextId(role),
        start,
        end,
        role,
        source: useScreenshot
          ? { type: "image", path: match.asset!.asset }
          : { type: "video", path: sourceRel, startOffset: start },
        visual: useScreenshot
          ? {
              type: match.presentation === "phone" ? "screenshot_phone" : "screenshot",
              path: match.asset!.asset,
              presentation: match.presentation === "phone" ? "phone_mockup" : "floating",
              blurBackground: true,
              highlight: match.highlight,
            }
          : {
              type: "talking_head",
              blurBackground: false,
            },
        camera: useScreenshot
          ? {
              type: match.camera,
              from: 1,
              to: 1.08,
              focusX: match.focusX,
              focusY: match.focusY,
              panX: match.panX,
              panY: match.panY,
            }
          : {
              type: isHook ? "push_in" : "slow_zoom",
              from: 1,
              to: isHook ? 1.1 : 1.05,
            },
        caption: {
          text: captionText,
          start: start + 0.08,
          end: end - 0.05,
          animation: isHook ? "scale_emphasis" : "fade_up",
          rtl: isArabicText(captionText),
        },
        overlays:
          brand.watermark?.enabled && logo
            ? [
                {
                  type: "logo",
                  path: logo.asset,
                  opacity: brand.watermark.opacity ?? 0.35,
                  x: 0.88,
                  y: 0.06,
                  scale: 0.12,
                },
              ]
            : [],
        audio: [],
        transitionIn: i === 0 ? "fade" : pickTransition(role),
        transitionOut: "none",
        emphasis: isHook || role === "cta" ? "strong" : "soft",
      };

      // Secondary caption line if phrase was split
      if (captions.length > 1 && end - start > 2) {
        const mid = (start + end) / 2;
        scenes.push({
          ...scene,
          id: nextId(role),
          end: mid,
          caption: { ...scene.caption!, end: mid - 0.05 },
        });
        scenes.push({
          ...scene,
          id: nextId(role),
          start: mid,
          caption: {
            text: captions[1]!,
            start: mid + 0.05,
            end: end - 0.05,
            animation: "fade_up",
            rtl: isArabicText(captions[1]!),
          },
          transitionIn: "cross_dissolve",
        });
        continue;
      }

      scenes.push(scene);
    }

    // End card / CTA
    const endDur = brand.endCard?.enabled !== false ? brand.endCard?.durationSeconds ?? 2.2 : 0;
    if (endDur > 0) {
      const ctaText =
        brand.cta?.[language] ??
        (language === "ar" ? "حمّل Al Ras Market الآن" : "Download Al Ras Market now");
      const lastEnd = scenes.length ? Math.max(...scenes.map((s) => s.end)) : duration;
      const ctaStart = Math.min(lastEnd, duration);
      const ctaEnd = ctaStart + endDur;
      scenes.push({
        id: nextId("cta"),
        start: ctaStart,
        end: ctaEnd,
        role: "cta",
        source: { type: "color", color: brand.colors?.background ?? "#0A1628" },
        visual: {
          type: "end_card",
          path: logo?.asset,
          presentation: "fullscreen",
        },
        camera: { type: "slow_zoom", from: 1, to: 1.04 },
        caption: {
          text: ctaText,
          start: ctaStart + 0.2,
          end: ctaEnd - 0.2,
          animation: "scale_emphasis",
          rtl: language === "ar",
        },
        overlays: [],
        audio: [],
        transitionIn: "cinematic_reveal",
        transitionOut: "fade",
        emphasis: "strong",
      });
    }

    const planDuration = Math.max(duration, ...scenes.map((s) => s.end));

    const plan: EditingPlan = {
      version: 1,
      format,
      language,
      fps: 30,
      duration: planDuration,
      title: `${brand.name} Ad`,
      music: music
        ? { path: music.asset, volume: 0.22, duckOnSpeech: true }
        : undefined,
      scenes,
      metadata: {
        sourceVideo: sourceRel,
        createdAt: new Date().toISOString(),
        directorMode: "heuristic",
        notes: "Heuristic Creative Director — show-what-is-spoken visual matching",
      },
    };

    return EditingPlanSchema.parse(plan);
  }
}

function classifyRole(
  text: string,
  index: number,
  total: number,
): Scene["role"] {
  const t = text.toLowerCase();
  if (index === 0) return "hook";
  if (/حمّل|حمل|download|الآن|now|جرّب|جرب/.test(t) || index >= total - 1) return "cta";
  if (/\?|؟|بتدور|looking|need/.test(t)) return "problem";
  if (/مع al ras|مع أل|market|حل|solution/.test(t)) return "solution";
  if (/ابحث|search|شوف|أسعار|منتجات|اطلب|order|قارن/.test(t)) return "demo";
  if (/سهولة|وفّر|توفر|سهل|easily|save/.test(t)) return "benefit";
  return "body";
}

function pickTransition(role: Scene["role"]): Scene["transitionIn"] {
  switch (role) {
    case "demo":
      return "smooth_push";
    case "solution":
      return "cross_dissolve";
    case "cta":
      return "cinematic_reveal";
    case "problem":
      return "fade";
    default:
      return "cross_dissolve";
  }
}

function matchVisual(
  lower: string,
  ctx: {
    searchUi?: AssetAnalysis;
    homeUi?: AssetAnalysis;
    productsUi?: AssetAnalysis;
    detailsUi?: AssetAnalysis;
    orderUi?: AssetAnalysis;
    screenshots: AssetAnalysis[];
  },
): {
  asset?: AssetAnalysis;
  presentation: "phone" | "float";
  camera: Scene["camera"]["type"];
  focusX?: number;
  focusY?: number;
  panX?: number;
  panY?: number;
  highlight?: Scene["visual"]["highlight"];
} {
  if (/ابحث|بحث|search|تلاقي|find/.test(lower) && ctx.searchUi) {
    return {
      asset: ctx.searchUi,
      presentation: "phone",
      camera: "push_in",
      focusX: 0.5,
      focusY: 0.22,
      highlight: { x: 0.1, y: 0.12, width: 0.8, height: 0.12, style: "glow", intensity: 0.65 },
    };
  }
  if (/سعر|أسعار|price|منتجات|products|شوف|catalog/.test(lower) && (ctx.productsUi || ctx.detailsUi)) {
    const asset = ctx.productsUi ?? ctx.detailsUi!;
    return {
      asset,
      presentation: "phone",
      camera: "ken_burns",
      focusY: 0.45,
      panY: 0.04,
      highlight: { x: 0.15, y: 0.35, width: 0.7, height: 0.25, style: "rect", intensity: 0.5 },
    };
  }
  if (/اطلب|order|طلب|سلة|cart/.test(lower) && ctx.orderUi) {
    return {
      asset: ctx.orderUi,
      presentation: "phone",
      camera: "slow_zoom",
      focusY: 0.7,
    };
  }
  if (/سهولة|home|تطبيق|app|al ras/.test(lower) && ctx.homeUi) {
    return {
      asset: ctx.homeUi,
      presentation: "float",
      camera: "parallax",
      panX: 0.02,
    };
  }
  // Generic screenshot if talking about the app and we have any
  if (/تطبيق|market|منصة|app/.test(lower) && ctx.screenshots[0]) {
    return {
      asset: ctx.screenshots[0],
      presentation: "phone",
      camera: "slow_zoom",
    };
  }
  return { presentation: "phone", camera: "slow_zoom" };
}

export function loadBrand(brandPath: string): BrandConfig {
  if (!fs.existsSync(brandPath)) {
    return {
      name: "Al Ras Market",
      primaryLanguage: "ar",
      defaultFormat: "9:16",
    };
  }
  return JSON.parse(fs.readFileSync(brandPath, "utf8")) as BrandConfig;
}
