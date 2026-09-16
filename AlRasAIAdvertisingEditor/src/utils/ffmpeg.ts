import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

let cachedFfmpeg: string | null = null;
let cachedFfprobe: string | null = null;

function appendMissingPathDirs(dirs: string[]) {
  const current = process.env.PATH ?? "";
  const parts = current.split(path.delimiter).filter(Boolean);
  const lower = new Set(parts.map((p) => p.toLowerCase()));
  for (const dir of dirs) {
    if (dir && fs.existsSync(dir) && !lower.has(dir.toLowerCase())) {
      parts.unshift(dir);
    }
  }
  process.env.PATH = parts.join(path.delimiter);
}

/** Ensure WinGet / common FFmpeg locations are visible even if the shell was opened before install. */
export function ensureFfmpegOnPath() {
  const local = process.env.LOCALAPPDATA ?? "";
  const dirs = [
    path.join(local, "Microsoft", "WinGet", "Links"),
    "C:\\ffmpeg\\bin",
    "C:\\ProgramData\\chocolatey\\bin",
  ];
  // Also add discovered package bin folders
  const wingetRoot = path.join(local, "Microsoft", "WinGet", "Packages");
  if (fs.existsSync(wingetRoot)) {
    const bin = findBinary(wingetRoot, "ffprobe.exe");
    if (bin) dirs.unshift(path.dirname(bin));
  }
  appendMissingPathDirs(dirs);
}

function resolveRealBinary(candidate: string): string {
  try {
    return fs.realpathSync(candidate);
  } catch {
    return candidate;
  }
}

function whichSync(cmd: string): string | null {
  const isWin = process.platform === "win32";
  const exe = isWin ? `${cmd}.exe` : cmd;
  const pathEnv = process.env.PATH ?? "";

  for (const dir of pathEnv.split(path.delimiter)) {
    if (!dir) continue;
    const full = path.join(dir, isWin ? exe : cmd);
    if (fs.existsSync(full)) return resolveRealBinary(full);
  }

  const local = process.env.LOCALAPPDATA ?? "";
  const wingetRoot = path.join(local, "Microsoft", "WinGet", "Packages");
  if (fs.existsSync(wingetRoot)) {
    const found = findBinary(wingetRoot, isWin ? exe : cmd);
    if (found) return resolveRealBinary(found);
  }

  const fallbacks = [
    path.join(local, "Microsoft", "WinGet", "Links", exe),
    path.join("C:\\ffmpeg\\bin", exe),
    path.join("C:\\ProgramData\\chocolatey\\bin", exe),
  ];
  for (const c of fallbacks) {
    if (fs.existsSync(c)) return resolveRealBinary(c);
  }
  return null;
}

function findBinary(root: string, name: string, depth = 0): string | null {
  if (depth > 8) return null;
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch {
    return null;
  }
  // Prefer .../bin/<name> quickly
  for (const e of entries) {
    if (e.isFile() && e.name.toLowerCase() === name.toLowerCase()) {
      return path.join(root, e.name);
    }
  }
  for (const e of entries) {
    if (!e.isDirectory() || e.name.startsWith(".")) continue;
    // Dive into FFmpeg package folders first
    if (/ffmpeg/i.test(e.name) || e.name === "bin") {
      const hit = findBinary(path.join(root, e.name), name, depth + 1);
      if (hit) return hit;
    }
  }
  for (const e of entries) {
    if (!e.isDirectory() || e.name.startsWith(".") || /ffmpeg/i.test(e.name) || e.name === "bin") {
      continue;
    }
    const hit = findBinary(path.join(root, e.name), name, depth + 1);
    if (hit) return hit;
  }
  return null;
}

export function getFfmpegPath(): string {
  if (cachedFfmpeg) return cachedFfmpeg;
  ensureFfmpegOnPath();
  const found = whichSync("ffmpeg");
  if (!found) {
    throw new Error(
      "FFmpeg not found. Install it (winget install Gyan.FFmpeg), then open a new terminal.",
    );
  }
  cachedFfmpeg = found;
  return found;
}

export function getFfprobePath(): string {
  if (cachedFfprobe) return cachedFfprobe;
  ensureFfmpegOnPath();
  const found = whichSync("ffprobe");
  if (!found) {
    const ffmpeg = getFfmpegPath();
    const sibling = path.join(
      path.dirname(ffmpeg),
      process.platform === "win32" ? "ffprobe.exe" : "ffprobe",
    );
    if (fs.existsSync(sibling)) {
      cachedFfprobe = resolveRealBinary(sibling);
      return cachedFfprobe;
    }
    throw new Error("ffprobe not found next to ffmpeg. Reinstall FFmpeg full build.");
  }
  cachedFfprobe = found;
  return found;
}

export interface RunResult {
  stdout: string;
  stderr: string;
  code: number;
}

export function runCommand(
  bin: string,
  args: string[],
  opts?: { cwd?: string; timeoutMs?: number },
): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, {
      cwd: opts?.cwd,
      windowsHide: true,
      stdio: ["ignore", "pipe", "pipe"],
      env: process.env,
    });
    let stdout = "";
    let stderr = "";
    const timer =
      opts?.timeoutMs != null
        ? setTimeout(() => {
            child.kill("SIGKILL");
            reject(new Error(`Command timed out: ${bin} ${args.join(" ")}`));
          }, opts.timeoutMs)
        : null;

    child.stdout.on("data", (d) => {
      stdout += d.toString();
    });
    child.stderr.on("data", (d) => {
      stderr += d.toString();
    });
    child.on("error", (err) => {
      if (timer) clearTimeout(timer);
      reject(
        new Error(
          `Failed to start ${bin}: ${err.message}. Is FFmpeg installed and on PATH?`,
        ),
      );
    });
    child.on("close", (code) => {
      if (timer) clearTimeout(timer);
      // Normalize Windows NTSTATUS-style unsigned codes
      const raw = code ?? 1;
      const normalized = raw > 0xffffff ? Number(BigInt(raw) & 0xffffffffn) : raw;
      resolve({ stdout, stderr, code: normalized });
    });
  });
}

export async function runFfmpeg(args: string[], opts?: { timeoutMs?: number }): Promise<RunResult> {
  const bin = getFfmpegPath();
  const result = await runCommand(bin, ["-y", ...args], opts);
  if (result.code !== 0) {
    throw new Error(
      `FFmpeg failed (${result.code}) via ${bin}: ${result.stderr.slice(-800) || result.stdout.slice(-400)}`,
    );
  }
  return result;
}

export async function runFfprobe(args: string[]): Promise<RunResult> {
  const bin = getFfprobePath();
  const result = await runCommand(bin, args);
  if (result.code !== 0) {
    throw new Error(
      `ffprobe failed (${result.code}) via ${bin}: ${result.stderr.slice(-800) || result.stdout.slice(-400) || "no output — check the video file is a valid MP4/MOV"}`,
    );
  }
  return result;
}
