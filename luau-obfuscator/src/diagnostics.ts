/**
 * Diagnostics: source locations and a typed error used across every compiler
 * stage so failures carry precise, actionable context instead of bare strings.
 */

export interface SourceLocation {
  readonly chunk: string;
  readonly line: number;
  readonly column?: number;
}

export type Stage = 'lex' | 'parse' | 'analyze' | 'transform' | 'generate' | 'validate' | 'config';

/** Error raised by any stage; formats as `chunk:line: [stage] message`. */
export class ObfuscatorError extends Error {
  readonly stage: Stage;
  readonly location: SourceLocation | undefined;

  constructor(stage: Stage, message: string, location?: SourceLocation) {
    const where = location ? `${location.chunk}:${location.line}: ` : '';
    super(`${where}[${stage}] ${message}`);
    this.name = 'ObfuscatorError';
    this.stage = stage;
    this.location = location;
  }
}

export function lexError(message: string, loc: SourceLocation): never {
  throw new ObfuscatorError('lex', message, loc);
}
export function parseError(message: string, loc: SourceLocation): never {
  throw new ObfuscatorError('parse', message, loc);
}
