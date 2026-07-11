/**
 * Configuration schema, defaults, and loader.
 *
 * Every pass is independently enableable via `passes.<name>`. A config file is
 * plain JSON (`ferret.config.json`); the CLI can also override individual keys.
 * `deterministic` fixes the seed so builds are reproducible; otherwise a random
 * seed is used each run.
 */
import { ObfuscatorError } from '../diagnostics.js';

export interface PassToggles {
  readonly rename: boolean;
  readonly encodeNumbers: boolean;
  readonly encodeStrings: boolean;
  readonly opaquePredicates: boolean;
  readonly pack: boolean;
}

export interface ResolvedConfig {
  readonly seed: number;
  readonly deterministic: boolean;
  readonly passes: PassToggles;
  /** '' = compact output; otherwise the indentation unit (e.g. '  '). */
  readonly indentUnit: string;
  /** Probability [0,1] that an eligible statement gets an opaque-predicate guard. */
  readonly opaquePredicateRate: number;
}

export type UserConfig = {
  seed?: number;
  deterministic?: boolean;
  passes?: Partial<PassToggles>;
  indentUnit?: string;
  opaquePredicateRate?: number;
};

export const DEFAULT_CONFIG: ResolvedConfig = {
  seed: 1,
  deterministic: true,
  passes: {
    rename: true,
    encodeNumbers: true,
    encodeStrings: true,
    opaquePredicates: false,
    pack: true,
  },
  indentUnit: '',
  opaquePredicateRate: 0.25,
};

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new ObfuscatorError('config', msg);
}

/** Merge a partial user config onto the defaults with validation. */
export function resolveConfig(user: UserConfig = {}): ResolvedConfig {
  if (user.opaquePredicateRate !== undefined) {
    assert(user.opaquePredicateRate >= 0 && user.opaquePredicateRate <= 1,
      'opaquePredicateRate must be within [0, 1]');
  }
  if (user.seed !== undefined) assert(Number.isFinite(user.seed), 'seed must be a finite number');

  const seed = user.deterministic === false
    ? (user.seed ?? Math.floor(Math.random() * 2147483646) + 1)
    : (user.seed ?? DEFAULT_CONFIG.seed);

  return {
    seed,
    deterministic: user.deterministic ?? DEFAULT_CONFIG.deterministic,
    passes: { ...DEFAULT_CONFIG.passes, ...(user.passes ?? {}) },
    indentUnit: user.indentUnit ?? DEFAULT_CONFIG.indentUnit,
    opaquePredicateRate: user.opaquePredicateRate ?? DEFAULT_CONFIG.opaquePredicateRate,
  };
}

/** Parse a JSON config string into a validated ResolvedConfig. */
export function parseConfig(json: string): ResolvedConfig {
  let parsed: unknown;
  try { parsed = JSON.parse(json); } catch (e) {
    throw new ObfuscatorError('config', `invalid JSON: ${(e as Error).message}`);
  }
  assert(parsed && typeof parsed === 'object', 'config must be a JSON object');
  return resolveConfig(parsed as UserConfig);
}
