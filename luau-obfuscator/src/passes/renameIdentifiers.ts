/**
 * Pass: scope-aware identifier renaming.
 *
 * Runs the scope analyzer, then assigns a fresh opaque name to every non-fixed
 * local binding. Only locals/params/loop vars/local functions are renamed;
 * globals, table fields, method names, and implicit `self` are left untouched
 * because they either escape the chunk or are not variables. Renamed names use
 * the digit-prefixed namespace, disjoint from runtime helper locals.
 */
import type { AstPass, PassContext } from './pass.js';
import type { Chunk } from '../ast/nodes.js';
import { analyzeScopes } from '../analysis/scope.js';

export const renameIdentifiers: AstPass = {
  kind: 'ast',
  name: 'rename',
  description: 'Rename local variables to opaque names, respecting lexical scope.',
  run(chunk: Chunk, ctx: PassContext): void {
    const info = analyzeScopes(chunk);
    const used = new Set<string>();
    let renamed = 0;
    for (const b of info.bindings) {
      if (b.fixed) continue;
      let name: string;
      do { name = ctx.prng.identifier(true); } while (used.has(name));
      used.add(name);
      b.newName = name;
      renamed++;
    }
    ctx.log.debug(`rename: ${renamed} local binding(s) renamed`);
  },
};
