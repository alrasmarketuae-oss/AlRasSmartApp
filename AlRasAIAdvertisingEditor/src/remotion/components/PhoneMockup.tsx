import React from "react";
import { AbsoluteFill, Img, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import type { Highlight } from "../../schemas/editing-plan";

export const PhoneMockup: React.FC<{
  src: string;
  highlight?: Highlight;
}> = ({ src, highlight }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = interpolate(frame, [0, Math.min(14, durationInFrames)], [40, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const scale = interpolate(frame, [0, Math.min(14, durationInFrames)], [0.92, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const opacity = interpolate(frame, [0, 8], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Subtle 3D-like tilt settle
  const rotateY = interpolate(frame, [0, Math.min(18, durationInFrames)], [12, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      {/* Atmospheric background */}
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(ellipse at center, #143D2C 0%, #0A1628 55%, #050B14 100%)",
        }}
      />
      <div
        style={{
          opacity,
          transform: `translateY(${enter}px) scale(${scale}) perspective(1200px) rotateY(${rotateY}deg)`,
          width: "72%",
          maxWidth: 520,
          aspectRatio: "9 / 19",
          borderRadius: 48,
          padding: 14,
          background: "linear-gradient(160deg, #2A2A2A, #111)",
          boxShadow: "0 30px 80px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.08)",
          position: "relative",
          overflow: "hidden",
        }}
      >
        {/* Notch */}
        <div
          style={{
            position: "absolute",
            top: 18,
            left: "50%",
            transform: "translateX(-50%)",
            width: 120,
            height: 28,
            borderRadius: 20,
            background: "#0A0A0A",
            zIndex: 3,
          }}
        />
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: 36,
            overflow: "hidden",
            background: "#000",
            position: "relative",
          }}
        >
          <Img
            src={src}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
              objectPosition: "top center",
            }}
          />
          {highlight ? <HighlightOverlay highlight={highlight} /> : null}
        </div>
      </div>
    </AbsoluteFill>
  );
};

export const FloatingScreenshot: React.FC<{
  src: string;
  highlight?: Highlight;
}> = ({ src, highlight }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const y = interpolate(frame, [0, durationInFrames], [18, -12], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  return (
    <AbsoluteFill style={{ justifyContent: "center", alignItems: "center" }}>
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(circle at 30% 20%, #1B4332 0%, #0A1628 50%, #050B14 100%)",
        }}
      />
      <div
        style={{
          width: "78%",
          borderRadius: 24,
          overflow: "hidden",
          transform: `translateY(${y}px)`,
          boxShadow: "0 28px 70px rgba(0,0,0,0.5)",
          position: "relative",
        }}
      >
        <Img src={src} style={{ width: "100%", display: "block" }} />
        {highlight ? <HighlightOverlay highlight={highlight} /> : null}
      </div>
    </AbsoluteFill>
  );
};

const HighlightOverlay: React.FC<{ highlight: Highlight }> = ({ highlight }) => {
  const frame = useCurrentFrame();
  const pulse =
    highlight.style === "pulse"
      ? 0.55 + Math.sin(frame / 8) * 0.25
      : highlight.intensity ?? 0.6;

  if (highlight.style === "blur_surround") {
    return (
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `radial-gradient(ellipse at ${highlight.x * 100}% ${highlight.y * 100}%, transparent 0%, transparent ${Math.max(highlight.width, highlight.height) * 45}%, rgba(0,0,0,${0.45 * pulse}) 100%)`,
          pointerEvents: "none",
        }}
      />
    );
  }

  return (
    <div
      style={{
        position: "absolute",
        left: `${highlight.x * 100}%`,
        top: `${highlight.y * 100}%`,
        width: `${highlight.width * 100}%`,
        height: `${highlight.height * 100}%`,
        borderRadius: highlight.style === "glow" ? 16 : 8,
        boxShadow:
          highlight.style === "glow"
            ? `0 0 0 2px rgba(233,196,106,${pulse}), 0 0 28px rgba(233,196,106,${pulse * 0.7})`
            : `0 0 0 2px rgba(255,255,255,${pulse})`,
        pointerEvents: "none",
      }}
    />
  );
};
