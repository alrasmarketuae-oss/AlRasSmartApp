import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { DIRS } from "./paths.js";

export function ensureDir(dir: string) {
  fs.mkdirSync(dir, { recursive: true });
}

export function fileHash(filePath: string): string {
  const buf = fs.readFileSync(filePath);
  return crypto.createHash("sha256").update(buf).digest("hex").slice(0, 16);
}

export function readJsonIfExists<T>(filePath: string): T | null {
  if (!fs.existsSync(filePath)) return null;
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
  } catch {
    return null;
  }
}

export function writeJson(filePath: string, data: unknown) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), "utf8");
}

export function cachePath(jobId: string, name: string): string {
  const dir = path.join(DIRS.temp, jobId, "cache");
  ensureDir(dir);
  return path.join(dir, name);
}

export function hasValidCache(filePath: string, maxAgeMs = 7 * 24 * 60 * 60 * 1000): boolean {
  if (!fs.existsSync(filePath)) return false;
  const age = Date.now() - fs.statSync(filePath).mtimeMs;
  return age < maxAgeMs;
}

export const SUPPORTED_VIDEO = new Set([".mp4", ".mov", ".webm", ".m4v"]);
export const SUPPORTED_IMAGE = new Set([".png", ".jpg", ".jpeg", ".webp"]);
export const SUPPORTED_AUDIO = new Set([".mp3", ".wav", ".m4a", ".aac"]);

export function isArabicText(text: string): boolean {
  return /[\u0600-\u06FF]/.test(text);
}

export function detectLanguageFromText(text: string): "ar" | "en" | "mixed" {
  const ar = (text.match(/[\u0600-\u06FF]/g) ?? []).length;
  const en = (text.match(/[A-Za-z]/g) ?? []).length;
  if (ar > 0 && en > ar * 0.4) return "mixed";
  if (ar > en) return "ar";
  if (en > 0) return "en";
  return "ar";
}

/** Split long caption into short advertising phrases */
export function splitCaptionPhrases(text: string, maxLen = 28): string[] {
  const cleaned = text.replace(/\s+/g, " ").trim();
  if (!cleaned) return [];
  if (cleaned.length <= maxLen) return [cleaned];

  const parts = cleaned.split(/(?<=[.?!\u061F،,;])\s+|،\s+/).filter(Boolean);
  const result: string[] = [];
  for (const part of parts) {
    if (part.length <= maxLen) {
      result.push(part.trim());
      continue;
    }
    const words = part.split(/\s+/);
    let buf = "";
    for (const w of words) {
      if ((buf + " " + w).trim().length > maxLen && buf) {
        result.push(buf.trim());
        buf = w;
      } else {
        buf = (buf + " " + w).trim();
      }
    }
    if (buf) result.push(buf.trim());
  }
  return result.filter(Boolean);
}
