import path from "node:path";
import fs from "node:fs";
import { EditingPlanSchema, type EditingPlan } from "../schemas/editing-plan.js";
import { DIRS, resolveProjectPath } from "../utils/paths.js";
import { writeJson, readJsonIfExists } from "../utils/fs.js";
import type { Logger } from "../utils/logger.js";

/**
 * Validates, repairs safe issues, and persists EditingPlan JSON.
 * Never executes AI code — JSON only.
 */
export class EditingPlanService {
  validate(plan: unknown): EditingPlan {
    return EditingPlanSchema.parse(plan);
  }

  safeParse(plan: unknown) {
    return EditingPlanSchema.safeParse(plan);
  }

  /**
   * Clamp timestamps, drop missing optional overlays, ensure paths are safe.
   */
  sanitize(plan: EditingPlan, logger: Logger): EditingPlan {
    const scenes = plan.scenes.map((scene) => {
      const overlays = (scene.overlays ?? []).filter((o) => {
        if (!o.path) return true;
        try {
          const abs = resolveProjectPath(o.path);
          if (!fs.existsSync(abs)) {
            logger.warn(`Dropping missing overlay: ${o.path}`);
            return false;
          }
          return true;
        } catch {
          logger.warn(`Dropping unsafe overlay path: ${o.path}`);
          return false;
        }
      });

      const audio = (scene.audio ?? []).filter((a) => {
        try {
          const abs = resolveProjectPath(a.path);
          if (!fs.existsSync(abs)) {
            logger.warn(`Dropping missing audio: ${a.path}`);
            return false;
          }
          return true;
        } catch {
          return false;
        }
      });

      let visual = scene.visual;
      if (visual.path) {
        try {
          resolveProjectPath(visual.path);
        } catch {
          logger.warn(`Clearing unsafe visual path: ${visual.path}`);
          visual = { ...visual, path: undefined };
        }
      }

      return { ...scene, overlays, audio, visual };
    });

    let music = plan.music;
    if (music) {
      try {
        const abs = resolveProjectPath(music.path);
        if (!fs.existsSync(abs)) {
          logger.warn(`Removing missing music: ${music.path}`);
          music = undefined;
        }
      } catch {
        music = undefined;
      }
    }

    return EditingPlanSchema.parse({ ...plan, scenes, music });
  }

  save(jobId: string, plan: EditingPlan): string {
    const out = path.join(DIRS.editingPlans, `${jobId}.json`);
    writeJson(out, plan);
    return out;
  }

  load(planPath: string): EditingPlan {
    const abs = path.isAbsolute(planPath) ? planPath : resolveProjectPath(planPath);
    const data = readJsonIfExists<unknown>(abs);
    if (!data) throw new Error(`Editing plan not found: ${planPath}`);
    return this.validate(data);
  }

  /** Minimal captions-over-video fallback if creative director fails entirely */
  buildFallback(opts: {
    videoPath: string;
    duration: number;
    phrases: Array<{ text: string; start: number; end: number }>;
    language: "ar" | "en" | "mixed" | "unknown";
    format: "9:16" | "16:9" | "1:1";
  }): EditingPlan {
    const scenes = opts.phrases.length
      ? opts.phrases.map((p, i) => ({
          id: `fallback-${i + 1}`,
          start: p.start,
          end: Math.max(p.end, p.start + 0.3),
          role: "body" as const,
          source: { type: "video" as const, path: opts.videoPath, startOffset: p.start },
          visual: { type: "talking_head" as const },
          camera: { type: "slow_zoom" as const, from: 1, to: 1.04 },
          caption: {
            text: p.text.slice(0, 48),
            start: p.start,
            end: p.end,
            animation: "fade_up" as const,
            rtl: /[\u0600-\u06FF]/.test(p.text),
          },
          overlays: [],
          audio: [],
          transitionIn: i === 0 ? ("fade" as const) : ("cross_dissolve" as const),
          transitionOut: "none" as const,
          emphasis: "none" as const,
        }))
      : [
          {
            id: "fallback-1",
            start: 0,
            end: opts.duration,
            role: "body" as const,
            source: { type: "video" as const, path: opts.videoPath },
            visual: { type: "talking_head" as const },
            camera: { type: "none" as const, from: 1, to: 1 },
            overlays: [],
            audio: [],
            transitionIn: "fade" as const,
            transitionOut: "none" as const,
            emphasis: "none" as const,
          },
        ];

    return this.validate({
      version: 1,
      format: opts.format,
      language: opts.language,
      fps: 30,
      duration: opts.duration,
      scenes,
      metadata: {
        sourceVideo: opts.videoPath,
        createdAt: new Date().toISOString(),
        directorMode: "fallback",
      },
    });
  }
}
