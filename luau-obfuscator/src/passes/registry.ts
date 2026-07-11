/**
 * Pass registry — the single place that lists passes and their order. Adding a
 * transformation means importing it here; nothing else changes (open/closed).
 *
 * AST passes run first (in this order), then the source is generated, then
 * source passes run. The order is deliberate: rename before literal encoding so
 * encoders don't touch generated helper names; pack last so it wraps everything.
 */
import type { AstPass, Pass, SourcePass } from './pass.js';
import { renameIdentifiers } from './renameIdentifiers.js';
import { encodeNumbers } from './encodeNumbers.js';
import { encodeStrings } from './encodeStrings.js';
import { opaquePredicates } from './opaquePredicates.js';
import { packChunk } from './packChunk.js';

export const AST_PASSES: readonly AstPass[] = [
  renameIdentifiers,
  encodeNumbers,
  encodeStrings,
  opaquePredicates,
];

export const SOURCE_PASSES: readonly SourcePass[] = [
  packChunk,
];

export const ALL_PASSES: readonly Pass[] = [...AST_PASSES, ...SOURCE_PASSES];

/** Human-readable catalogue for `--list-passes`. */
export function passCatalogue(): { name: string; kind: string; description: string }[] {
  return ALL_PASSES.map((p) => ({ name: p.name, kind: p.kind, description: p.description }));
}
