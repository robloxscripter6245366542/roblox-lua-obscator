/**
 * Pass: opaque predicates.
 *
 * Wraps a random subset of call statements in `if <always-true> then <call> end`.
 * The guard is the algebraic identity `a*a - b*b == (a-b)*(a+b)`, which is true
 * for all numbers, so behavior is unchanged — but the value is computed at
 * runtime and is not a constant literal, resisting trivial folding.
 *
 * Only `CallStat` is wrapped: it introduces no bindings, so moving it inside an
 * `if` block never changes scope or control flow.
 */
import type { AstPass, PassContext } from './pass.js';
import type { Chunk, Expr, If, Stmt } from '../ast/nodes.js';
import { mapStatements } from '../ast/visitor.js';

function opaqueTrue(ctx: PassContext, line: number): Expr {
  const a = ctx.prng.range(2, 60_000);
  const b = ctx.prng.range(2, 60_000);
  const num = (v: number): Expr => ({ type: 'Number', raw: String(v), line });
  // a*a - b*b
  const lhs: Expr = {
    type: 'Binop', op: '-', line,
    left: { type: 'Binop', op: '*', left: num(a), right: num(a), line },
    right: { type: 'Binop', op: '*', left: num(b), right: num(b), line },
  };
  // (a-b)*(a+b)
  const rhs: Expr = {
    type: 'Binop', op: '*', line,
    left: { type: 'Paren', line, expr: { type: 'Binop', op: '-', left: num(a), right: num(b), line } },
    right: { type: 'Paren', line, expr: { type: 'Binop', op: '+', left: num(a), right: num(b), line } },
  };
  return { type: 'Binop', op: '==', left: lhs, right: rhs, line };
}

export const opaquePredicates: AstPass = {
  kind: 'ast',
  name: 'opaquePredicates',
  description: 'Guard random call statements with runtime-true opaque predicates.',
  run(chunk: Chunk, ctx: PassContext): void {
    const rate = ctx.config.opaquePredicateRate;
    let count = 0;
    mapStatements(chunk, (s: Stmt): Stmt[] => {
      if (s.type !== 'CallStat') return [s];
      if (ctx.prng.next() / 2_147_483_646 >= rate) return [s];
      count++;
      const guard: If = {
        type: 'If',
        clauses: [{ cond: opaqueTrue(ctx, s.line), body: [s] }],
        elseBody: null,
        line: s.line,
      };
      return [guard];
    });
    ctx.log.debug(`opaquePredicates: ${count} statement(s) guarded`);
  },
};
