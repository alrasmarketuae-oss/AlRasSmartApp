import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/** Project root = AlRasAIAdvertisingEditor/ */
export const PROJECT_ROOT = path.resolve(__dirname, "../..");

export const DIRS = {
  input: path.join(PROJECT_ROOT, "input"),
  assets: path.join(PROJECT_ROOT, "assets"),
  output: path.join(PROJECT_ROOT, "output"),
  transcripts: path.join(PROJECT_ROOT, "transcripts"),
  editingPlans: path.join(PROJECT_ROOT, "editing-plans"),
  renders: path.join(PROJECT_ROOT, "renders"),
  temp: path.join(PROJECT_ROOT, "temp"),
  logs: path.join(PROJECT_ROOT, "logs"),
  public: path.join(PROJECT_ROOT, "public"),
} as const;

export function jobIdFromVideo(videoPath: string): string {
  return path.basename(videoPath, path.extname(videoPath)).replace(/[^\w\-ء-ي]+/g, "-");
}

export function resolveProjectPath(relativePath: string): string {
  const cleaned = relativePath.replace(/\\/g, "/");
  if (cleaned.includes("..") || path.isAbsolute(cleaned)) {
    throw new Error(`Unsafe path rejected: ${relativePath}`);
  }
  const resolved = path.resolve(PROJECT_ROOT, cleaned);
  if (!resolved.startsWith(PROJECT_ROOT)) {
    throw new Error(`Path escapes project root: ${relativePath}`);
  }
  return resolved;
}

export function toProjectRelative(absolutePath: string): string {
  return path.relative(PROJECT_ROOT, absolutePath).replace(/\\/g, "/");
}
