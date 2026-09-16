import { describe, it, expect } from "vitest";
import { resolveProjectPath } from "../src/utils/paths.js";

describe("path safety", () => {
  it("resolves safe relative paths", () => {
    const p = resolveProjectPath("input/video.mp4");
    expect(p.replace(/\\/g, "/")).toMatch(/input\/video\.mp4$/);
  });

  it("blocks traversal", () => {
    expect(() => resolveProjectPath("../outside.txt")).toThrow();
  });
});
