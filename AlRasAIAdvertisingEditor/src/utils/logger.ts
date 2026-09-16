import fs from "node:fs";
import path from "node:path";
import { DIRS } from "./paths.js";

export type LogLevel = "debug" | "info" | "warn" | "error";

export class Logger {
  private stream: fs.WriteStream | null = null;
  private jobId: string;

  constructor(jobId: string) {
    this.jobId = jobId;
    fs.mkdirSync(DIRS.logs, { recursive: true });
    this.stream = fs.createWriteStream(path.join(DIRS.logs, `${jobId}.log`), {
      flags: "a",
    });
  }

  private write(level: LogLevel, message: string, meta?: unknown) {
    const line = `[${new Date().toISOString()}] [${level.toUpperCase()}] ${message}${
      meta !== undefined ? ` ${JSON.stringify(meta)}` : ""
    }`;
    const fn = level === "error" ? console.error : level === "warn" ? console.warn : console.log;
    fn(line);
    this.stream?.write(line + "\n");
  }

  debug(msg: string, meta?: unknown) {
    this.write("debug", msg, meta);
  }
  info(msg: string, meta?: unknown) {
    this.write("info", msg, meta);
  }
  warn(msg: string, meta?: unknown) {
    this.write("warn", msg, meta);
  }
  error(msg: string, meta?: unknown) {
    this.write("error", msg, meta);
  }

  close() {
    this.stream?.end();
    this.stream = null;
  }
}
