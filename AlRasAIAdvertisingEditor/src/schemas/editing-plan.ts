import { z } from "zod";

/** Safe relative path — no traversal, no absolute paths */
export const SafeRelativePathSchema = z
  .string()
  .min(1)
  .refine((p) => !p.includes("..") && !p.startsWith("/") && !/^[A-Za-z]:/.test(p), {
    message: "Path must be relative and must not contain '..'",
  });

export const FormatSchema = z.enum(["9:16", "16:9", "1:1"]);
export const LanguageSchema = z.enum(["ar", "en", "mixed", "unknown"]);

export const CameraTypeSchema = z.enum([
  "none",
  "slow_zoom",
  "slow_pull",
  "ken_burns",
  "cinematic_pan",
  "subtle_shake",
  "parallax",
  "push_in",
  "pull_out",
]);

export const TransitionSchema = z.enum([
  "none",
  "fade",
  "cross_dissolve",
  "smooth_push",
  "slide_left",
  "slide_right",
  "slide_up",
  "whip",
  "zoom",
  "cinematic_reveal",
  "slide_reveal",
  "masked_reveal",
  "light_fade",
]);

export const CaptionAnimationSchema = z.enum([
  "none",
  "fade_up",
  "fade",
  "slide",
  "scale_emphasis",
  "word_emphasis",
  "highlight",
  "kinetic",
]);

export const VisualTypeSchema = z.enum([
  "talking_head",
  "video_full",
  "image",
  "screenshot",
  "screenshot_phone",
  "screenshot_float",
  "logo",
  "b_roll",
  "text_card",
  "end_card",
  "branded_bg",
]);

export const SourceTypeSchema = z.enum(["video", "image", "color", "none"]);

export const HighlightSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  width: z.number().min(0.01).max(1),
  height: z.number().min(0.01).max(1),
  style: z.enum(["glow", "rect", "blur_surround", "pulse"]).default("glow"),
  intensity: z.number().min(0).max(1).default(0.6),
});

export const CameraSchema = z.object({
  type: CameraTypeSchema.default("none"),
  from: z.number().min(0.5).max(2).default(1),
  to: z.number().min(0.5).max(2).default(1.06),
  panX: z.number().min(-0.3).max(0.3).optional(),
  panY: z.number().min(-0.3).max(0.3).optional(),
  focusX: z.number().min(0).max(1).optional(),
  focusY: z.number().min(0).max(1).optional(),
});

export const CaptionSchema = z.object({
  text: z.string().min(1).max(120),
  start: z.number().min(0),
  end: z.number().positive(),
  animation: CaptionAnimationSchema.default("fade_up"),
  emphasizeWords: z.array(z.string()).optional(),
  rtl: z.boolean().optional(),
});

export const OverlaySchema = z.object({
  type: z.enum(["logo", "image", "text", "dim", "vignette", "blur"]),
  path: SafeRelativePathSchema.optional(),
  text: z.string().optional(),
  opacity: z.number().min(0).max(1).default(0.85),
  x: z.number().min(0).max(1).optional(),
  y: z.number().min(0).max(1).optional(),
  scale: z.number().min(0.05).max(2).optional(),
  blur: z.number().min(0).max(40).optional(),
});

export const AudioCueSchema = z.object({
  type: z.enum(["sfx", "music"]),
  path: SafeRelativePathSchema,
  start: z.number().min(0).default(0),
  volume: z.number().min(0).max(1).default(0.5),
  duckSpeech: z.boolean().default(true),
});

export const SceneSourceSchema = z.object({
  type: SourceTypeSchema,
  path: SafeRelativePathSchema.optional(),
  color: z.string().optional(),
  startOffset: z.number().min(0).optional(),
});

export const VisualSchema = z.object({
  type: VisualTypeSchema,
  path: SafeRelativePathSchema.optional(),
  presentation: z
    .enum(["fullscreen", "phone_mockup", "floating", "split"])
    .optional(),
  crop: z
    .object({
      x: z.number().min(0).max(1),
      y: z.number().min(0).max(1),
      width: z.number().min(0.1).max(1),
      height: z.number().min(0.1).max(1),
    })
    .optional(),
  blurBackground: z.boolean().optional(),
  opacity: z.number().min(0).max(1).optional(),
  scale: z.number().min(0.5).max(2).optional(),
  rotation: z.number().min(-15).max(15).optional(),
  highlight: HighlightSchema.optional(),
  parallaxDepth: z.number().min(0).max(1).optional(),
});

export const SceneRoleSchema = z.enum([
  "hook",
  "problem",
  "solution",
  "demo",
  "benefit",
  "cta",
  "logo_intro",
  "end_card",
  "body",
]);

export const SceneSchema = z
  .object({
    id: z.string().min(1),
    start: z.number().min(0),
    end: z.number().positive(),
    role: SceneRoleSchema.default("body"),
    source: SceneSourceSchema,
    visual: VisualSchema,
    camera: CameraSchema.default({}),
    caption: CaptionSchema.optional(),
    overlays: z.array(OverlaySchema).default([]),
    audio: z.array(AudioCueSchema).default([]),
    transitionIn: TransitionSchema.default("fade"),
    transitionOut: TransitionSchema.default("none"),
    emphasis: z.enum(["none", "soft", "strong"]).default("none"),
  })
  .superRefine((scene, ctx) => {
    if (scene.end <= scene.start) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: `Scene ${scene.id}: end must be greater than start`,
        path: ["end"],
      });
    }
    if (scene.caption) {
      if (scene.caption.end <= scene.caption.start) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Scene ${scene.id}: caption end must be > start`,
          path: ["caption", "end"],
        });
      }
    }
  });

export const EditingPlanSchema = z
  .object({
    version: z.literal(1),
    format: FormatSchema.default("9:16"),
    language: LanguageSchema.default("ar"),
    fps: z.number().int().min(24).max(60).default(30),
    duration: z.number().positive(),
    title: z.string().optional(),
    music: z
      .object({
        path: SafeRelativePathSchema,
        volume: z.number().min(0).max(1).default(0.25),
        duckOnSpeech: z.boolean().default(true),
      })
      .optional(),
    scenes: z.array(SceneSchema).min(1),
    metadata: z
      .object({
        sourceVideo: SafeRelativePathSchema.optional(),
        createdAt: z.string().optional(),
        directorMode: z.enum(["ai", "heuristic", "fallback"]).optional(),
        notes: z.string().optional(),
      })
      .optional(),
  })
  .superRefine((plan, ctx) => {
    const sorted = [...plan.scenes].sort((a, b) => a.start - b.start);
    for (let i = 0; i < sorted.length; i++) {
      const s = sorted[i]!;
      if (s.end > plan.duration + 0.05) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Scene ${s.id} ends after plan duration`,
          path: ["scenes", i, "end"],
        });
      }
      if (i > 0) {
        const prev = sorted[i - 1]!;
        // Allow small overlaps for transitions (<= 0.35s)
        if (s.start + 0.001 < prev.end - 0.35) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: `Scene ${s.id} overlaps heavily with ${prev.id}`,
            path: ["scenes", i, "start"],
          });
        }
      }
    }
  });

export type EditingPlan = z.infer<typeof EditingPlanSchema>;
export type Scene = z.infer<typeof SceneSchema>;
export type Caption = z.infer<typeof CaptionSchema>;
export type Format = z.infer<typeof FormatSchema>;
export type Camera = z.infer<typeof CameraSchema>;
export type Visual = z.infer<typeof VisualSchema>;
export type Highlight = z.infer<typeof HighlightSchema>;
export type Transition = z.infer<typeof TransitionSchema>;
