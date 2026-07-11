/** Minimal leveled logger with a silent default; the CLI raises the level. */
export type LogLevel = 'silent' | 'error' | 'warn' | 'info' | 'debug';

const ORDER: Record<LogLevel, number> = { silent: 0, error: 1, warn: 2, info: 3, debug: 4 };

export class Logger {
  constructor(private level: LogLevel = 'warn', private readonly sink: (m: string) => void = (m) => process.stderr.write(m + '\n')) {}

  setLevel(level: LogLevel): void { this.level = level; }

  private at(level: LogLevel): boolean { return ORDER[level] <= ORDER[this.level]; }
  private emit(level: LogLevel, tag: string, msg: string): void {
    if (this.at(level)) this.sink(`[${tag}] ${msg}`);
  }

  error(msg: string): void { this.emit('error', 'error', msg); }
  warn(msg: string): void { this.emit('warn', 'warn', msg); }
  info(msg: string): void { this.emit('info', 'info', msg); }
  debug(msg: string): void { this.emit('debug', 'debug', msg); }
}
