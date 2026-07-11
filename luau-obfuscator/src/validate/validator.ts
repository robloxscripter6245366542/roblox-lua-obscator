/**
 * Behavior-equivalence validator.
 *
 * Runs a Lua/Luau interpreter on the original and the obfuscated program and
 * compares their output. Chunk paths and line numbers in tracebacks are
 * normalized so the comparison measures observable behavior, not filenames.
 * Non-deterministic programs (two original runs disagree) are reported as such
 * rather than counted as failures.
 */
import { spawnSync } from 'node:child_process';
import { writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

export interface ValidationResult {
  readonly ok: boolean;
  readonly status: 'match' | 'mismatch' | 'nondeterministic';
  readonly expected?: string;
  readonly actual?: string;
}

export function normalizeOutput(s: string): string {
  return s
    .replace(/\[string "[^"]*"\]/g, 'CHUNK')
    .replace(/\S*\.lua/g, 'CHUNK')
    .replace(/CHUNK:\d+/g, 'CHUNK:L')
    .replace(/\s*\(\.\.\.tail calls\.\.\.\)\n?/g, '\n');
}

function runFile(luaBin: string, file: string): string {
  const r = spawnSync(luaBin, [file], { encoding: 'latin1', maxBuffer: 1 << 26 });
  return normalizeOutput((r.stdout ?? '') + (r.stderr ?? ''));
}

export interface ValidateOptions {
  /** Interpreter binary, e.g. 'lua5.4' or a Luau CLI path. */
  readonly luaBin?: string;
}

/**
 * Compare `original` against `obfuscated` by executing both. Both are written to
 * temp files so tracebacks and `require`-style behavior match a real run.
 */
export function validateEquivalence(
  original: string,
  obfuscated: string,
  opts: ValidateOptions = {},
): ValidationResult {
  const luaBin = opts.luaBin ?? 'lua5.4';
  const dir = mkdtempSync(join(tmpdir(), 'ferret-validate-'));
  try {
    const origFile = join(dir, 'orig.lua');
    const obfFile = join(dir, 'obf.lua');
    writeFileSync(origFile, original, 'latin1');
    writeFileSync(obfFile, obfuscated, 'latin1');

    const a = runFile(luaBin, origFile);
    const b = runFile(luaBin, origFile);
    if (a !== b) return { ok: true, status: 'nondeterministic' };

    const c = runFile(luaBin, obfFile);
    if (c === a) return { ok: true, status: 'match' };
    return { ok: false, status: 'mismatch', expected: a, actual: c };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

/** True if a usable Lua interpreter is on PATH (for conditionally running validation). */
export function hasInterpreter(luaBin = 'lua5.4'): boolean {
  const r = spawnSync(luaBin, ['-v'], { encoding: 'utf8' });
  return r.status === 0 || (typeof r.stdout === 'string' && /lua/i.test(r.stdout + (r.stderr ?? '')));
}
