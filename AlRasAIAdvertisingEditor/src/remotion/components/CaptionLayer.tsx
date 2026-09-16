import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from "remotion";
import type { Caption } from "../../schemas/editing-plan";

export const CaptionLayer: React.FC<{
  caption: Caption;
  sceneStartFrame: number;
  primaryColor?: string;
  accentColor?: string;
}> = ({ caption, sceneStartFrame, primaryColor = "#FFFFFF", accentColor = "#E9C46A" }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const absoluteFrame = sceneStartFrame + frame;

  const startF = Math.round(caption.start * fps);
  const endF = Math.round(caption.end * fps);
  if (absoluteFrame < startF || absoluteFrame > endF) return null;

  const local = absoluteFrame - startF;
  const duration = Math.max(1, endF - startF);
  const appear = Math.min(10, Math.floor(duration * 0.2));
  const opacity = interpolate(local, [0, appear], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  let translateY = 0;
  let scale = 1;
  switch (caption.animation) {
    case "fade_up":
    case "slide":
      translateY = interpolate(local, [0, appear], [24, 0], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      break;
    case "scale_emphasis":
    case "kinetic":
      scale = interpolate(local, [0, appear, appear + 8], [0.86, 1.06, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      break;
    case "word_emphasis":
    case "highlight":
      scale = interpolate(local, [0, appear], [0.95, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      });
      break;
    default:
      break;
  }

  const rtl = caption.rtl ?? /[\u0600-\u06FF]/.test(caption.text);

  return (
    <AbsoluteFill
      style={{
        justifyContent: "flex-end",
        alignItems: "center",
        paddingBottom: "14%",
        paddingLeft: "6%",
        paddingRight: "6%",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          opacity,
          transform: `translateY(${translateY}px) scale(${scale})`,
          maxWidth: "90%",
          textAlign: "center",
          direction: rtl ? "rtl" : "ltr",
          fontFamily: rtl
            ? '"Cairo", "Segoe UI", "Tahoma", sans-serif'
            : '"Inter", "Segoe UI", sans-serif',
          fontSize: 52,
          fontWeight: 700,
          lineHeight: 1.35,
          color: primaryColor,
          textShadow: "0 2px 18px rgba(0,0,0,0.65), 0 0 2px rgba(0,0,0,0.8)",
          letterSpacing: rtl ? 0 : "-0.02em",
        }}
      >
        {caption.animation === "highlight" ? (
          <span
            style={{
              background: `linear-gradient(transparent 60%, ${accentColor}88 60%)`,
              padding: "0 8px",
            }}
          >
            {caption.text}
          </span>
        ) : (
          caption.text
        )}
      </div>
    </AbsoluteFill>
  );
};
