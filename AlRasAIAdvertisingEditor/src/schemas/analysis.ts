import { z } from "zod";

export const WordTimingSchema = z.object({
  word: z.string(),
  start: z.number().min(0),
  end: z.number().min(0),
});

export const PhraseSchema = z.object({
  text: z.string(),
  start: z.number().min(0),
  end: z.number().min(0),
  words: z.array(WordTimingSchema).optional(),
});

export const TranscriptSchema = z.object({
  language: z.string(),
  text: z.string(),
  duration: z.number().min(0),
  phrases: z.array(PhraseSchema),
  words: z.array(WordTimingSchema).default([]),
  sourceVideo: z.string(),
  cached: z.boolean().optional(),
});

export type Transcript = z.infer<typeof TranscriptSchema>;
export type Phrase = z.infer<typeof PhraseSchema>;
export type WordTiming = z.infer<typeof WordTimingSchema>;

export const FrameLabelSchema = z.enum([
  "person_speaking",
  "phone",
  "app_screen",
  "product",
  "empty_background",
  "important_moment",
  "scene_change",
  "camera_movement",
  "broll_opportunity",
  "unknown",
]);

export const FrameAnalysisSchema = z.object({
  path: z.string(),
  timestamp: z.number().min(0),
  labels: z.array(FrameLabelSchema).default(["unknown"]),
  brightness: z.number().min(0).max(255).optional(),
  notes: z.string().optional(),
});

export const VideoAnalysisSchema = z.object({
  duration: z.number(),
  width: z.number(),
  height: z.number(),
  fps: z.number().optional(),
  hasAudio: z.boolean(),
  frames: z.array(FrameAnalysisSchema),
  sceneChangeTimestamps: z.array(z.number()).default([]),
});

export type FrameAnalysis = z.infer<typeof FrameAnalysisSchema>;
export type VideoAnalysis = z.infer<typeof VideoAnalysisSchema>;

export const AssetCategorySchema = z.enum([
  "logo",
  "app_screenshot",
  "product_image",
  "marketing_image",
  "music",
  "sfx",
  "other",
]);

export const AssetAnalysisSchema = z.object({
  asset: z.string(),
  filename: z.string(),
  width: z.number().optional(),
  height: z.number().optional(),
  aspectRatio: z.number().optional(),
  type: AssetCategorySchema,
  purpose: z.string(),
  topics: z.array(z.string()).default([]),
  isAppScreenshot: z.boolean().default(false),
  isProductImage: z.boolean().default(false),
  containsTextLikely: z.boolean().default(false),
  exists: z.boolean(),
});

export type AssetAnalysis = z.infer<typeof AssetAnalysisSchema>;

export const BrandConfigSchema = z.object({
  name: z.string(),
  logo: z.string().optional(),
  primaryLanguage: z.enum(["ar", "en"]).default("ar"),
  defaultFormat: z.enum(["9:16", "16:9", "1:1"]).default("9:16"),
  cta: z
    .object({
      ar: z.string().optional(),
      en: z.string().optional(),
    })
    .optional(),
  tagline: z
    .object({
      ar: z.string().optional(),
      en: z.string().optional(),
    })
    .optional(),
  colors: z
    .object({
      primary: z.string().optional(),
      secondary: z.string().optional(),
      background: z.string().optional(),
      text: z.string().optional(),
      accent: z.string().optional(),
    })
    .optional(),
  typography: z
    .object({
      arabicFont: z.string().optional(),
      latinFont: z.string().optional(),
    })
    .optional(),
  watermark: z
    .object({
      enabled: z.boolean().default(true),
      opacity: z.number().default(0.35),
      position: z.enum(["top-right", "top-left", "bottom-right", "bottom-left"]).default("top-right"),
    })
    .optional(),
  logoIntro: z
    .object({
      enabled: z.boolean().default(true),
      durationSeconds: z.number().default(1.2),
    })
    .optional(),
  endCard: z
    .object({
      enabled: z.boolean().default(true),
      durationSeconds: z.number().default(2.5),
    })
    .optional(),
});

export type BrandConfig = z.infer<typeof BrandConfigSchema>;
