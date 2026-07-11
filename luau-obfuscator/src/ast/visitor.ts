/**
 * AST traversal helpers. Passes use {@link mapExpressions} to rewrite every
 * expression slot (post-order: children are rewritten before their parent) and
 * {@link mapStatements} to rewrite statement lists. Rewriting through these
 * keeps every expression/statement site in one place, so a new node kind only
 * needs updating here.
 */
import type { Block, Chunk, Expr, Stmt } from './nodes.js';

export type ExprRewriter = (e: Expr) => Expr;
export type StmtRewriter = (s: Stmt) => Stmt[];

function mapExpr(e: Expr, f: ExprRewriter): Expr {
  switch (e.type) {
    case 'Paren': e.expr = mapExpr(e.expr, f); break;
    case 'Field': e.obj = mapExpr(e.obj, f); break;
    case 'Index': e.obj = mapExpr(e.obj, f); e.index = mapExpr(e.index, f); break;
    case 'Call': e.func = mapExpr(e.func, f); e.args = e.args.map((a) => mapExpr(a, f)); break;
    case 'MethodCall': e.obj = mapExpr(e.obj, f); e.args = e.args.map((a) => mapExpr(a, f)); break;
    case 'Binop': e.left = mapExpr(e.left, f); e.right = mapExpr(e.right, f); break;
    case 'Unop': e.operand = mapExpr(e.operand, f); break;
    case 'Function': mapBlockExprs(e.body, f); break;
    case 'Table':
      for (const field of e.fields) {
        if (field.kind === 'keyed') field.key = mapExpr(field.key, f);
        field.value = mapExpr(field.value, f);
      }
      break;
    default: break; // Nil/True/False/Vararg/Number/String/Name have no child expressions
  }
  return f(e);
}

function mapStmtExprs(s: Stmt, f: ExprRewriter): void {
  switch (s.type) {
    case 'LocalAssign': s.exprs = s.exprs.map((e) => mapExpr(e, f)); break;
    case 'Assign': s.targets = s.targets.map((e) => mapExpr(e, f)); s.exprs = s.exprs.map((e) => mapExpr(e, f)); break;
    case 'CompoundAssign': s.target = mapExpr(s.target, f); s.value = mapExpr(s.value, f); break;
    case 'CallStat': { const c = mapExpr(s.call, f); s.call = c as typeof s.call; break; }
    case 'Do': mapBlockExprs(s.body, f); break;
    case 'While': s.cond = mapExpr(s.cond, f); mapBlockExprs(s.body, f); break;
    case 'Repeat': mapBlockExprs(s.body, f); s.cond = mapExpr(s.cond, f); break;
    case 'If':
      for (const c of s.clauses) { c.cond = mapExpr(c.cond, f); mapBlockExprs(c.body, f); }
      if (s.elseBody) mapBlockExprs(s.elseBody, f);
      break;
    case 'NumericFor':
      s.start = mapExpr(s.start, f); s.stop = mapExpr(s.stop, f);
      if (s.step) s.step = mapExpr(s.step, f);
      mapBlockExprs(s.body, f);
      break;
    case 'GenericFor': s.exprs = s.exprs.map((e) => mapExpr(e, f)); mapBlockExprs(s.body, f); break;
    case 'FunctionDecl': mapBlockExprs(s.func.body, f); break;
    case 'Return': s.exprs = s.exprs.map((e) => mapExpr(e, f)); break;
    default: break; // Break/Continue/Goto/Label
  }
}

function mapBlockExprs(block: Block, f: ExprRewriter): void {
  for (const s of block) mapStmtExprs(s, f);
}

/** Rewrite every expression in the chunk (post-order). */
export function mapExpressions(chunk: Chunk, f: ExprRewriter): void {
  mapBlockExprs(chunk.body, f);
}

function mapBlockStmts(block: Block, f: StmtRewriter): Block {
  const out: Block = [];
  for (const s of block) {
    // recurse into nested blocks first
    switch (s.type) {
      case 'Do': s.body = mapBlockStmts(s.body, f); break;
      case 'While': s.body = mapBlockStmts(s.body, f); break;
      case 'Repeat': s.body = mapBlockStmts(s.body, f); break;
      case 'NumericFor': s.body = mapBlockStmts(s.body, f); break;
      case 'GenericFor': s.body = mapBlockStmts(s.body, f); break;
      case 'FunctionDecl': s.func.body = mapBlockStmts(s.func.body, f); break;
      case 'If':
        for (const c of s.clauses) c.body = mapBlockStmts(c.body, f);
        if (s.elseBody) s.elseBody = mapBlockStmts(s.elseBody, f);
        break;
      default: break;
    }
    out.push(...f(s));
  }
  return out;
}

/** Rewrite every statement (a rewriter may expand one statement into several). */
export function mapStatements(chunk: Chunk, f: StmtRewriter): void {
  chunk.body = mapBlockStmts(chunk.body, f);
}
