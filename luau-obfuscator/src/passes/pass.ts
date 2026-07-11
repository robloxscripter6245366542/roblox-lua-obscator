/**
 * Transformation pass framework.
 *
 * Two pass kinds compose the pipeline:
 *  - {@link AstPass} mutates the typed AST (rename, encode literals, insert
 *    opaque predicates, …).
 *  - {@link SourcePass} rewrites the already-generated source (whole-chunk
 *    encryption + loader).
 *
 * Passes are self-contained modules; adding one means writing a file and listing
 * it in ./registry.ts — no existing pass is touched (open/closed).
 */
import type { Chunk } from '../ast/nodes.js';
import type { Prng } from '../util/prng.js';
import type { Logger } from '../logger.js';
import type { ResolvedConfig } from '../config/config.js';

export interface PassContext {
  readonly prng: Prng;
  readonly config: ResolvedConfig;
  readonly log: Logger;
  readonly chunkName: string;
  /** Prepend a runtime helper snippet (raw Luau) before the generated body. */
  addPrelude(src: string): void;
  /** Allocate an opaque helper-local name (letter-prefixed; disjoint from renamed locals). */
  freshName(): string;
}

export interface AstPass {
  readonly kind: 'ast';
  readonly name: string;
  readonly description: string;
  run(chunk: Chunk, ctx: PassContext): void;
}

export interface SourcePass {
  readonly kind: 'source';
  readonly name: string;
  readonly description: string;
  run(source: string, ctx: PassContext): string;
}

export type Pass = AstPass | SourcePass;

export function isAstPass(p: Pass): p is AstPass { return p.kind === 'ast'; }
