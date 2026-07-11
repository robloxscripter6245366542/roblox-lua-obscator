/**
 * Pass: numeric literal encoding.
 *
 * Rewrites plain non-negative decimal integer literals `n` as `(a - b)` with
 * `a - b === n`, preserving integer/float typing (only +/- of integers). Hex,
 * float, exponent, binary, and separator forms are left untouched so no value
 * or type is ever changed.
 */
import type { AstPass, PassContext } from './pass.js';
import type { Chunk, Expr } from '../ast/nodes.js';
import { mapExpressions } from '../ast/visitor.js';

export const encodeNumbers: AstPass = {
  kind: 'ast',
  name: 'encodeNumbers',
  description: 'Rewrite integer literals as equivalent arithmetic expressions.',
  run(chunk: Chunk, ctx: PassContext): void {
    let count = 0;
    mapExpressions(chunk, (e: Expr): Expr => {
      if (e.type !== 'Number') return e;
      if (!/^[0-9]+$/.test(e.raw) || e.raw.length > 9) return e;
      const n = parseInt(e.raw, 10);
      const b = ctx.prng.range(1, 1_000_000);
      const a = n + b;
      count++;
      return {
        type: 'Binop',
        op: '-',
        left: { type: 'Number', raw: String(a), line: e.line },
        right: { type: 'Number', raw: String(b), line: e.line },
        line: e.line,
      };
    });
    ctx.log.debug(`encodeNumbers: ${count} literal(s) rewritten`);
  },
};
