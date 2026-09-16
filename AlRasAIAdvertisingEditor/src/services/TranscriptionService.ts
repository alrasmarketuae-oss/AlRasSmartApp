import fs from "node:fs";
import path from "node:path";
import OpenAI from "openai";
import { FFmpegService } from "./FFmpegService.js";
import type { Transcript, Phrase, WordTiming } from "../schemas/analysis.js";
import { TranscriptSchema } from "../schemas/analysis.js";
import { cachePath, hasValidCache, readJsonIfExists, writeJson, detectLanguageFromText } from "../utils/fs.js";
import { DIRS, jobIdFromVideo, toProjectRelative } from "../utils/paths.js";
import type { Logger } from "../utils/logger.js";

/**
 * Whisper transcription with word/phrase timestamps.
 * Falls back to a deterministic synthetic transcript when no API key is set
 * (enables offline pipeline testing).
 */
export class TranscriptionService {
  private ffmpeg = new FFmpegService();

  async transcribe(videoPath: string, logger: Logger, force = false): Promise<Transcript> {
    const jobId = jobIdFromVideo(videoPath);
    const cacheFile = path.join(DIRS.transcripts, `${jobId}.json`);
    if (!force && hasValidCache(cacheFile)) {
      const cached = readJsonIfExists<Transcript>(cacheFile);
      if (cached) {
        const parsed = TranscriptSchema.safeParse({ ...cached, cached: true });
        if (parsed.success) {
          logger.info("Using cached transcript", { cacheFile });
          return parsed.data;
        }
      }
    }

    const audioPath = cachePath(jobId, "audio.wav");
    const info = await this.ffmpeg.probe(videoPath);
    if (info.hasAudio) {
      logger.info("Extracting audio for transcription");
      await this.ffmpeg.extractAudio(videoPath, audioPath);
    } else {
      logger.warn("Video has no audio track — using silent fallback transcript");
    }

    const apiKey = process.env.OPENAI_API_KEY?.trim();
    let transcript: Transcript;

    if (apiKey && info.hasAudio && fs.existsSync(audioPath)) {
      logger.info("Transcribing with OpenAI Whisper");
      transcript = await this.whisperTranscribe(audioPath, videoPath, info.duration, apiKey);
    } else {
      logger.warn(
        apiKey
          ? "Audio missing — heuristic transcript"
          : "OPENAI_API_KEY not set — using heuristic Arabic demo transcript",
      );
      transcript = this.heuristicTranscript(videoPath, info.duration);
    }

    const validated = TranscriptSchema.parse(transcript);
    writeJson(cacheFile, validated);
    logger.info("Transcript saved", { cacheFile, phrases: validated.phrases.length });
    return validated;
  }

  private async whisperTranscribe(
    audioPath: string,
    videoPath: string,
    duration: number,
    apiKey: string,
  ): Promise<Transcript> {
    const client = new OpenAI({ apiKey });
    const model = process.env.OPENAI_WHISPER_MODEL || "whisper-1";
    const file = fs.createReadStream(audioPath);
    const result = await client.audio.transcriptions.create({
      file,
      model,
      response_format: "verbose_json",
      timestamp_granularities: ["word", "segment"],
      // Auto language detection
    });

    const anyResult = result as unknown as {
      text?: string;
      language?: string;
      words?: Array<{ word: string; start: number; end: number }>;
      segments?: Array<{ text: string; start: number; end: number }>;
    };

    const words: WordTiming[] = (anyResult.words ?? []).map((w) => ({
      word: w.word.trim(),
      start: w.start,
      end: w.end,
    }));

    const phrases: Phrase[] =
      anyResult.segments?.map((s) => ({
        text: s.text.trim(),
        start: s.start,
        end: s.end,
        words: words.filter((w) => w.start >= s.start - 0.05 && w.end <= s.end + 0.05),
      })) ?? this.phrasesFromWords(words);

    const text = anyResult.text?.trim() || phrases.map((p) => p.text).join(" ");
    const langRaw = anyResult.language ?? detectLanguageFromText(text);
    const language =
      langRaw === "arabic" || langRaw === "ar"
        ? "ar"
        : langRaw === "english" || langRaw === "en"
          ? "en"
          : detectLanguageFromText(text);

    return {
      language,
      text,
      duration: duration || Math.max(...phrases.map((p) => p.end), 0),
      phrases: phrases.filter((p) => p.text.length > 0),
      words,
      sourceVideo: toProjectRelative(videoPath),
    };
  }

  private phrasesFromWords(words: WordTiming[]): Phrase[] {
    if (!words.length) return [];
    const phrases: Phrase[] = [];
    let buf: WordTiming[] = [];
    const flush = () => {
      if (!buf.length) return;
      phrases.push({
        text: buf.map((w) => w.word).join(" "),
        start: buf[0]!.start,
        end: buf[buf.length - 1]!.end,
        words: [...buf],
      });
      buf = [];
    };
    for (const w of words) {
      buf.push(w);
      const last = buf[buf.length - 1]!;
      const first = buf[0]!;
      if (last.end - first.start >= 2.8 || /[.!?\u061F]$/.test(w.word)) {
        flush();
      }
    }
    flush();
    return phrases;
  }

  /** Offline-capable sample phrases for Al Ras Market ads */
  private heuristicTranscript(videoPath: string, duration: number): Transcript {
    const base: Array<{ text: string; weight: number }> = [
      { text: "بتدور على منتجات بالجملة؟", weight: 1 },
      { text: "مع Al Ras Market تقدر تلاقي منتجاتك بسهولة.", weight: 1.2 },
      { text: "وتقدر تشوف المنتجات والأسعار بسهولة.", weight: 1.1 },
      { text: "ابحث عن المنتجات وقارن بين الموردين.", weight: 1 },
      { text: "اطلب بسهولة ووفّر وقتك.", weight: 0.9 },
      { text: "حمّل Al Ras Market الآن.", weight: 0.8 },
    ];

    const totalWeight = base.reduce((s, b) => s + b.weight, 0);
    const usable = Math.max(duration - 0.3, 3);
    let t = 0.15;
    const phrases: Phrase[] = [];
    for (const item of base) {
      const span = (item.weight / totalWeight) * usable;
      const end = Math.min(duration - 0.05, t + span);
      if (end <= t) break;
      const words = item.text.split(/\s+/).map((word, i, arr) => {
        const wSpan = (end - t) / arr.length;
        return {
          word,
          start: Number((t + i * wSpan).toFixed(3)),
          end: Number((t + (i + 1) * wSpan).toFixed(3)),
        };
      });
      phrases.push({
        text: item.text,
        start: Number(t.toFixed(3)),
        end: Number(end.toFixed(3)),
        words,
      });
      t = end + 0.08;
      if (t >= duration - 0.2) break;
    }

    return {
      language: "ar",
      text: phrases.map((p) => p.text).join(" "),
      duration,
      phrases,
      words: phrases.flatMap((p) => p.words ?? []),
      sourceVideo: toProjectRelative(videoPath),
    };
  }
}
