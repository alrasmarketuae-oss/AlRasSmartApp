import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";

export const TransitionOverlay: React.FC<{
  type: string;
  mode: "in" | "out";
  durationInFrames: number;
}> = ({ type, mode, durationInFrames }) => {
  const frame = useCurrentFrame();
  const window = Math.min(12, Math.max(6, Math.floor(durationInFrames * 0.15)));

  if (type === "none") return null;

  const local = mode === "in" ? frame : durationInFrames - 1 - frame;
  if (local > window) return null;

  const p = interpolate(local, [0, window], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const cover = mode === "in" ? 1 - p : p;

  switch (type) {
    case "fade":
    case "light_fade":
    case "cross_dissolve":
      return (
        <AbsoluteFill
          style={{
            backgroundColor: type === "light_fade" ? "#fff" : "#000",
            opacity: cover,
            pointerEvents: "none",
          }}
        />
      );
    case "whip":
      return (
        <AbsoluteFill
          style={{
            background: `linear-gradient(90deg, transparent, #000 ${cover * 100}%, #000)`,
            opacity: cover,
            transform: `translateX(${(1 - cover) * (mode === "in" ? -40 : 40)}%)`,
            pointerEvents: "none",
          }}
        />
      );
    case "slide_left":
    case "slide_right":
    case "slide_up":
    case "smooth_push":
    case "slide_reveal": {
      const dir =
        type === "slide_up"
          ? `translateY(${cover * 100}%)`
          : type === "slide_right"
            ? `translateX(${-cover * 100}%)`
            : `translateX(${cover * 100}%)`;
      return (
        <AbsoluteFill
          style={{
            backgroundColor: "#0A1628",
            transform: dir,
            pointerEvents: "none",
          }}
        />
      );
    }
    case "zoom":
    case "cinematic_reveal":
    case "masked_reveal":
      return (
        <AbsoluteFill
          style={{
            backgroundColor: "#0A1628",
            opacity: cover,
            transform: `scale(${1 + cover * 0.15})`,
            pointerEvents: "none",
          }}
        />
      );
    default:
      return (
        <AbsoluteFill style={{ backgroundColor: "#000", opacity: cover, pointerEvents: "none" }} />
      );
  }
};
