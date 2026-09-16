# Al Ras AI Advertising Editor

Standalone AI advertising video editor for **Al Ras Market**.

Turns a raw talking-head / product video + app screenshots into a polished cinematic mobile ad:

```
RAW VIDEO → Whisper → Frame/Asset Analysis → AI Creative Director → EditingPlan JSON → Remotion → FFmpeg → Final MP4
```

The AI outputs **validated JSON only**. Remotion/FFmpeg execute the plan. No arbitrary code or shell from the model.

## Quick start

```bash
cd AlRasAIAdvertisingEditor
cp .env.example .env   # add OPENAI_API_KEY for Whisper + GPT director
npm install

# Place your video and assets
# input/your-video.mp4
# assets/logo.png, assets/search-screen.png, ...

npm run edit -- input/your-video.mp4
```

Outputs:

- `output/your-video-final.mp4`
- `editing-plans/your-video.json`
- `transcripts/your-video.json`
- `logs/your-video.log`

## Commands

| Command | Purpose |
|--------|---------|
| `npm run edit -- input/video.mp4` | Full pipeline |
| `npm run edit -- input/video.mp4 --dry-run` | Plan only (no render) |
| `npm run preview -- input/video.mp4` | Low-res preview |
| `npm run analyze -- input/video.mp4` | Transcript + analysis |
| `npm run plan -- input/video.mp4` | Generate EditingPlan |
| `npm run render -- editing-plans/video.json` | Render existing plan |
| `npm test` | Unit tests |

## Configuration

- `brand.json` — brand name, CTA, colors, logo intro / end card
- `video-config.json` — formats, preview/render quality, music ducking
- `.env` — `OPENAI_API_KEY` (optional; heuristic director works offline)

Without an API key the system uses a deterministic Creative Director + demo Arabic phrases for silent/offline videos so the pipeline still renders.

## Requirements

- Node.js 20+
- FFmpeg + ffprobe on PATH
- (Optional) OpenAI API key for Whisper + GPT-4o creative direction

## Architecture

See `src/services/*` for deterministic modules Cursor can invoke:

`VideoEditingService`, `TranscriptionService`, `MediaAnalysisService`, `AssetAnalysisService`, `CreativeDirectorService`, `EditingPlanService`, `RemotionRenderService`, `FFmpegService`
