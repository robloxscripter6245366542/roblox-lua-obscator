/**
 * Semantic analysis: lexical scope resolution.
 *
 * Attaches a {@link Binding} to every declaration name and every `Name`
 * reference. References that resolve to no local binding are globals/builtins
 * and are left with `binding = null`. Upvalues need no special handling: a
 * closure referencing an outer local resolves to that same binding object, so a
 * later rename applied to the binding covers every use, at every depth.
 *
 * Correctly models Lua/Luau scoping rules:
 *  - a `local` is visible only after its declaration (RHS resolves first),
 *  - `local function f` is visible inside its own body (recursion),
 *  - loop variables are scoped to the loop body,
 *  - `repeat … until` can see locals declared in the body,
 *  - method bodies get an implicit, non-renamable `self`.
 */
import type {
  Binding, Block, Chunk, DeclName, Expr, FunctionExpr, Param, Stmt,
} from '../ast/nodes.js';

interface Scope {
  readonly vars: Map<string, Binding>;
  readonly parent: Scope | null;
}

export interface ScopeInfo {
  /** Every binding created, in declaration order. */
  readonly bindings: Binding[];
}

function newScope(parent: Scope | null): Scope {
  return { vars: new Map(), parent };
}

function declare(info: ScopeInfo, scope: Scope, decl: DeclName | Param, kind: Binding['kind']): Binding {
  const fixed = (decl as Param).implicit === true;
  const binding: Binding = { originalName: decl.name, newName: null, fixed, kind };
  decl.binding = binding;
  scope.vars.set(decl.name, binding);
  info.bindings.push(binding);
  return binding;
}

function lookup(scope: Scope, name: string): Binding | null {
  let s: Scope | null = scope;
  while (s) {
    const b = s.vars.get(name);
    if (b) return b;
    s = s.parent;
  }
  return null; // global / builtin
}
function resolve(scope: Scope, ref: { name: string; binding: Binding | null }): void {
  ref.binding = lookup(scope, ref.name);
}

function rExpr(info: ScopeInfo, e: Expr, scope: Scope): void {
  switch (e.type) {
    case 'Name': resolve(scope, e); break;
    case 'Paren': rExpr(info, e.expr, scope); break;
    case 'Field': rExpr(info, e.obj, scope); break;
    case 'Index': rExpr(info, e.obj, scope); rExpr(info, e.index, scope); break;
    case 'Call': rExpr(info, e.func, scope); e.args.forEach((a) => rExpr(info, a, scope)); break;
    case 'MethodCall': rExpr(info, e.obj, scope); e.args.forEach((a) => rExpr(info, a, scope)); break;
    case 'Binop': rExpr(info, e.left, scope); rExpr(info, e.right, scope); break;
    case 'Unop': rExpr(info, e.operand, scope); break;
    case 'Function': rFunction(info, e, scope); break;
    case 'Table':
      for (const f of e.fields) {
        if (f.kind === 'keyed') rExpr(info, f.key, scope);
        rExpr(info, f.value, scope);
      }
      break;
    default: break; // literals, Vararg
  }
}

function rFunction(info: ScopeInfo, fn: FunctionExpr, parent: Scope): void {
  const scope = newScope(parent);
  for (const p of fn.params) declare(info, scope, p, 'param');
  for (const st of fn.body) rStmt(info, st, scope);
}

function rBlock(info: ScopeInfo, stmts: Block, parent: Scope): void {
  const scope = newScope(parent);
  for (const st of stmts) rStmt(info, st, scope);
}

function rStmt(info: ScopeInfo, s: Stmt, scope: Scope): void {
  switch (s.type) {
    case 'LocalAssign':
      s.exprs.forEach((e) => rExpr(info, e, scope));
      s.names.forEach((n) => declare(info, scope, n, 'local'));
      break;
    case 'Assign':
      s.targets.forEach((e) => rExpr(info, e, scope));
      s.exprs.forEach((e) => rExpr(info, e, scope));
      break;
    case 'CompoundAssign':
      rExpr(info, s.target, scope);
      rExpr(info, s.value, scope);
      break;
    case 'CallStat': rExpr(info, s.call, scope); break;
    case 'Do': rBlock(info, s.body, scope); break;
    case 'While': rExpr(info, s.cond, scope); rBlock(info, s.body, scope); break;
    case 'Repeat': {
      // `until` sees body locals -> shared scope, cond resolved after body.
      const bs = newScope(scope);
      for (const st of s.body) rStmt(info, st, bs);
      rExpr(info, s.cond, bs);
      break;
    }
    case 'If':
      for (const c of s.clauses) { rExpr(info, c.cond, scope); rBlock(info, c.body, scope); }
      if (s.elseBody) rBlock(info, s.elseBody, scope);
      break;
    case 'NumericFor': {
      rExpr(info, s.start, scope); rExpr(info, s.stop, scope);
      if (s.step) rExpr(info, s.step, scope);
      const fs = newScope(scope);
      declare(info, fs, s.variable, 'loop');
      for (const st of s.body) rStmt(info, st, fs);
      break;
    }
    case 'GenericFor': {
      s.exprs.forEach((e) => rExpr(info, e, scope));
      const gs = newScope(scope);
      s.names.forEach((n) => declare(info, gs, n, 'loop'));
      for (const st of s.body) rStmt(info, st, gs);
      break;
    }
    case 'FunctionDecl':
      if (s.isLocal) {
        declare(info, scope, s.base, 'function'); // visible in its own body
        rFunction(info, s.func, scope);
      } else {
        resolve(scope, { name: s.base.name, get binding() { return null; }, set binding(b) { s.base.binding = b ?? undefined; } } as unknown as { name: string; binding: Binding | null });
        rFunction(info, s.func, scope);
      }
      break;
    case 'Return': s.exprs.forEach((e) => rExpr(info, e, scope)); break;
    default: break; // Break, Continue, Goto, Label
  }
}

/** Resolve scopes across a chunk; returns every binding for the rename pass. */
export function analyzeScopes(chunk: Chunk): ScopeInfo {
  const info: ScopeInfo = { bindings: [] };
  const top = newScope(null);
  for (const st of chunk.body) rStmt(info, st, top);
  return info;
}
