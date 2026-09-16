import React from "react";
import { Composition, registerRoot } from "remotion";
import { AlRasAdComposition, type AdCompositionProps } from "./components/AlRasAdComposition";
import type { EditingPlan } from "../schemas/editing-plan";

const FORMAT_SIZES = {
  "9:16": { width: 1080, height: 1920 },
  "16:9": { width: 1920, height: 1080 },
  "1:1": { width: 1080, height: 1080 },
} as const;

const defaultPlan: EditingPlan = {
  version: 1,
  format: "9:16",
  language: "ar",
  fps: 30,
  duration: 5,
  scenes: [
    {
      id: "placeholder",
      start: 0,
      end: 5,
      role: "body",
      source: { type: "color", color: "#0A1628" },
      visual: { type: "text_card" },
      camera: { type: "none", from: 1, to: 1 },
      caption: {
        text: "Al Ras Market",
        start: 0.3,
        end: 4.5,
        animation: "fade_up",
        rtl: false,
      },
      overlays: [],
      audio: [],
      transitionIn: "fade",
      transitionOut: "none",
      emphasis: "none",
    },
  ],
};

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="AlRasAd"
      component={AlRasAdComposition}
      durationInFrames={150}
      fps={30}
      width={1080}
      height={1920}
      defaultProps={
        {
          plan: defaultPlan,
        } as AdCompositionProps
      }
      calculateMetadata={({ props }) => {
        const plan = (props as AdCompositionProps).plan ?? defaultPlan;
        const size = FORMAT_SIZES[plan.format] ?? FORMAT_SIZES["9:16"];
        const fps = plan.fps || 30;
        return {
          durationInFrames: Math.max(1, Math.ceil(plan.duration * fps)),
          fps,
          width: size.width,
          height: size.height,
        };
      }}
    />
  );
};

registerRoot(RemotionRoot);
