import React from "react";
import {
  AbsoluteFill,
  Audio,
  Img,
  OffthreadVideo,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import type { EditingPlan, Scene } from "../../schemas/editing-plan";
import { CameraMotion } from "../effects/CameraMotion";
import { TransitionOverlay } from "../transitions/TransitionOverlay";
import { CaptionLayer } from "./CaptionLayer";
import { FloatingScreenshot, PhoneMockup } from "./PhoneMockup";

export type AdCompositionProps = {
  plan: EditingPlan;
};

/** Resolve project-relative media via Remotion publicDir (project root). */
function resolveMedia(mediaPath: string | undefined): string | undefined {
  if (!mediaPath) return undefined;
  if (mediaPath.startsWith("http") || mediaPath.startsWith("data:")) return mediaPath;
  const cleaned = mediaPath.replace(/\\/g, "/");
  const markers = ["assets/", "input/", "temp/", "public/"];
  for (const m of markers) {
    const idx = cleaned.toLowerCase().lastIndexOf(m);
    if (idx >= 0) {
      return staticFile(cleaned.slice(idx));
    }
  }
  if (!cleaned.includes(":") && !cleaned.startsWith("/")) {
    return staticFile(cleaned);
  }
  return mediaPath;
}

const SceneView: React.FC<{
  scene: Scene;
  plan: EditingPlan;
}> = ({ scene }) => {
  const { fps, durationInFrames } = useVideoConfig();
  const frame = useCurrentFrame();
  const colors = {
    bg: "#0A1628",
    text: "#FFFFFF",
    accent: "#E9C46A",
  };

  const mediaPath = resolveMedia(scene.visual.path ?? scene.source.path);
  const videoSrc = resolveMedia(
    scene.source.type === "video" ? scene.source.path : undefined,
  );

  const sceneStartSeconds = scene.start;

  let body: React.ReactNode = null;

  if (scene.visual.type === "logo" || scene.visual.type === "end_card") {
    const logoSrc = resolveMedia(scene.visual.path);
    body = (
      <AbsoluteFill
        style={{
          background: scene.source.color ?? colors.bg,
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        {logoSrc ? (
          <Img
            src={logoSrc}
            style={{
              width: scene.visual.type === "end_card" ? "42%" : "48%",
              objectFit: "contain",
            }}
          />
        ) : (
          <div
            style={{
              color: colors.text,
              fontSize: 64,
              fontWeight: 800,
              fontFamily: '"Cairo", "Segoe UI", sans-serif',
            }}
          >
            Al Ras Market
          </div>
        )}
      </AbsoluteFill>
    );
  } else if (
    scene.visual.type === "screenshot_phone" ||
    scene.visual.presentation === "phone_mockup"
  ) {
    body = mediaPath ? (
      <PhoneMockup src={mediaPath} highlight={scene.visual.highlight} />
    ) : (
      <AbsoluteFill style={{ background: colors.bg }} />
    );
  } else if (
    scene.visual.type === "screenshot_float" ||
    scene.visual.presentation === "floating" ||
    scene.visual.type === "screenshot" ||
    scene.visual.type === "image"
  ) {
    body = mediaPath ? (
      scene.visual.presentation === "fullscreen" ? (
        <AbsoluteFill>
          <Img src={mediaPath} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </AbsoluteFill>
      ) : (
        <FloatingScreenshot src={mediaPath} highlight={scene.visual.highlight} />
      )
    ) : (
      <AbsoluteFill style={{ background: colors.bg }} />
    );
  } else if (scene.source.type === "color") {
    body = <AbsoluteFill style={{ background: scene.source.color ?? colors.bg }} />;
  } else if (videoSrc) {
    const startFrom = Math.round((scene.source.startOffset ?? scene.start) * fps);
    body = (
      <AbsoluteFill style={{ background: "#000" }}>
        <OffthreadVideo
          src={videoSrc}
          startFrom={startFrom}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
          volume={1}
        />
        {scene.visual.blurBackground ? (
          <AbsoluteFill style={{ backdropFilter: "blur(2px)", background: "rgba(0,0,0,0.08)" }} />
        ) : null}
      </AbsoluteFill>
    );
  } else {
    body = <AbsoluteFill style={{ background: colors.bg }} />;
  }

  const vignetteOpacity = interpolate(frame, [0, 10], [0.15, 0.35], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill>
      <CameraMotion camera={scene.camera} durationInFrames={durationInFrames}>
        {body}
      </CameraMotion>

      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,${vignetteOpacity}) 100%)`,
          pointerEvents: "none",
        }}
      />

      {scene.overlays?.map((o, i) => {
        if (o.type === "logo" && o.path) {
          const src = resolveMedia(o.path);
          if (!src) return null;
          return (
            <Img
              key={i}
              src={src}
              style={{
                position: "absolute",
                left: `${(o.x ?? 0.85) * 100}%`,
                top: `${(o.y ?? 0.05) * 100}%`,
                width: `${(o.scale ?? 0.12) * 100}%`,
                opacity: o.opacity ?? 0.35,
                transform: "translate(-50%, -50%)",
              }}
            />
          );
        }
        if (o.type === "dim") {
          return (
            <AbsoluteFill
              key={i}
              style={{ background: `rgba(0,0,0,${o.opacity ?? 0.3})`, pointerEvents: "none" }}
            />
          );
        }
        return null;
      })}

      {scene.caption ? (
        <CaptionLayer
          caption={scene.caption}
          sceneStartFrame={Math.round(sceneStartSeconds * fps)}
          primaryColor={colors.text}
          accentColor={colors.accent}
        />
      ) : null}

      <TransitionOverlay type={scene.transitionIn} mode="in" durationInFrames={durationInFrames} />
      <TransitionOverlay type={scene.transitionOut} mode="out" durationInFrames={durationInFrames} />
    </AbsoluteFill>
  );
};

export const AlRasAdComposition: React.FC<AdCompositionProps> = ({ plan }) => {
  const { fps } = useVideoConfig();
  const musicVolume = plan.music?.duckOnSpeech ? 0.14 : plan.music?.volume ?? 0.22;

  return (
    <AbsoluteFill style={{ backgroundColor: "#050B14" }}>
      {plan.music?.path ? <Audio src={resolveMedia(plan.music.path)!} volume={musicVolume} /> : null}

      {plan.scenes.map((scene) => {
        const from = Math.round(scene.start * fps);
        const durationInFrames = Math.max(1, Math.round((scene.end - scene.start) * fps));
        return (
          <Sequence key={scene.id} from={from} durationInFrames={durationInFrames} name={scene.id}>
            <SceneView scene={scene} plan={plan} />
            {scene.audio?.map((a, i) => {
              const src = resolveMedia(a.path);
              if (!src) return null;
              return (
                <Audio
                  key={`${scene.id}-a-${i}`}
                  src={src}
                  volume={a.volume}
                  startFrom={Math.round(a.start * fps)}
                />
              );
            })}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
