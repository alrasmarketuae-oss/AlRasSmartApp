import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";

const root = process.cwd();
fs.mkdirSync(path.join(root, "assets"), { recursive: true });
fs.mkdirSync(path.join(root, "input"), { recursive: true });

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: "inherit", shell: false });
    p.on("close", (code) => (code === 0 ? resolve() : reject(new Error(`${cmd} exited ${code}`))));
  });
}

/** Create a solid-color PNG via ffmpeg (no sharp needed) */
async function makePng(out, w, h, color, label) {
  // Draw label with drawtext when font available; otherwise solid brand color plate
  const vf = label
    ? `drawbox=x=60:y=120:w=${w - 120}:h=120:color=white@0.95:t=fill,drawbox=x=60:y=300:w=${w - 120}:h=280:color=white@0.95:t=fill`
    : "null";
  await run("ffmpeg", [
    "-y",
    "-f",
    "lavfi",
    "-i",
    `color=c=${color}:s=${w}x${h}:d=1`,
    "-frames:v",
    "1",
    "-vf",
    vf,
    out,
  ]);
}

await makePng("assets/logo.png", 512, 512, "0x0B6E4F", "logo");
await makePng("assets/app-home.png", 1080, 1920, "0xF3F6F4", "home");
await makePng("assets/search-screen.png", 1080, 1920, "0xEEF5F1", "search");
await makePng("assets/products.png", 1080, 1920, "0xF7F3EA", "products");
await makePng("assets/product-details.png", 1080, 1920, "0xF5F5F5", "details");
console.log("Assets created");

await run("ffmpeg", [
  "-y",
  "-f",
  "lavfi",
  "-i",
  "color=c=0x1B4332:s=1080x1920:d=8",
  "-f",
  "lavfi",
  "-i",
  "sine=frequency=440:duration=8",
  "-c:v",
  "libx264",
  "-pix_fmt",
  "yuv420p",
  "-c:a",
  "aac",
  "-shortest",
  "input/sample.mp4",
]);
console.log("Sample video created: input/sample.mp4");
