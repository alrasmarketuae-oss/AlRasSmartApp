import React from "react";
import { interpolate, useCurrentFrame, useVideoConfig, Easing } from "remotion";
import type { Camera } from "../../schemas/editing-plan";

export function useCameraTransform(camera: Camera, durationInFrames: number) {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const progress = interpolate(frame, [0, Math.max(1, durationInFrames - 1)], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.cubic),
  });

  const from = camera.from ?? 1;
  const to = camera.to ?? 1.06;
  let scale = from;
  let translateX = 0;
  let translateY = 0;
  let rotate = 0;
  const type = camera.type ?? "none";

  if (type === "none") {
    scale = 1;
  } else if (type === "slow_zoom" || type === "push_in") {
    scale = interpolate(progress, [0, 1], [from, to]);
    if (camera.focusX != null) translateX = (0.5 - camera.focusX) * 40 * progress;
    if (camera.focusY != null) translateY = (0.5 - camera.focusY) * 40 * progress;
  } else if (type === "slow_pull" || type === "pull_out") {
    scale = interpolate(progress, [0, 1], [to, from]);
  } else if (type === "ken_burns") {
    scale = interpolate(progress, [0, 1], [from, to]);
    translateX = interpolate(progress, [0, 1], [0, (camera.panX ?? 0.03) * 100]);
    translateY = interpolate(progress, [0, 1], [0, (camera.panY ?? 0.02) * 100]);
  } else if (type === "cinematic_pan") {
    scale = Math.max(from, to);
    translateX = interpolate(progress, [0, 1], [-(camera.panX ?? 0.05) * 120, (camera.panX ?? 0.05) * 120]);
    translateY = interpolate(progress, [0, 1], [0, (camera.panY ?? 0.02) * 80]);
  } else if (type === "parallax") {
    scale = interpolate(progress, [0, 1], [from, to]);
    translateX = Math.sin(progress * Math.PI) * ((camera.panX ?? 0.03) * 60);
    translateY = Math.cos(progress * Math.PI) * ((camera.panY ?? 0.02) * 40);
  } else if (type === "subtle_shake") {
    scale = interpolate(progress, [0, 1], [from, to]);
    const t = frame / fps;
    translateX = Math.sin(t * 14) * 1.2;
    translateY = Math.cos(t * 11) * 0.9;
    rotate = Math.sin(t * 9) * 0.15;
  } else {
    scale = interpolate(progress, [0, 1], [from, to]);
  }

  return {
    transform: `translate(${translateX}px, ${translateY}px) scale(${scale}) rotate(${rotate}deg)`,
    progress,
  };
}

export const CameraMotion: React.FC<{
  camera: Camera;
  durationInFrames: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ camera, durationInFrames, children, style }) => {
  const { transform } = useCameraTransform(camera, durationInFrames);
  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        overflow: "hidden",
        ...style,
      }}
    >
      <div style={{ width: "100%", height: "100%", transform, transformOrigin: "center center" }}>
        {children}
      </div>
    </div>
  );
};
