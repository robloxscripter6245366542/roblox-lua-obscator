/**
 * AST node definitions for the Luau subset ferret understands.
 *
 * Every node carries a discriminant `type` and a `line`. Expressions and
 * statements are discriminated unions so passes and the generator get
 * exhaustiveness checking from the compiler.
 *
 * Scope information is attached after parsing by the analyzer: declaration
 * names and references gain a {@link Binding}.
 */

export interface Binding {
  readonly originalName: string;
  /** Assigned by the rename pass; null means "keep original name". */
  newName: string | null;
  /** True for names that must never be renamed (e.g. implicit method `self`). */
  readonly fixed: boolean;
  readonly kind: 'local' | 'param' | 'loop' | 'function';
}

export type Block = Stmt[];

// ---- shared name carriers --------------------------------------------------
export interface DeclName {
  name: string;
  attrib?: string | null;
  binding?: Binding;
}
export interface Param {
  name: string;
  implicit?: boolean;
  binding?: Binding;
}

// ---- statements ------------------------------------------------------------
export interface LocalAssign { type: 'LocalAssign'; names: DeclName[]; exprs: Expr[]; line: number; }
export interface Assign { type: 'Assign'; targets: Expr[]; exprs: Expr[]; line: number; }
/** Luau compound assignment (`a += b`). Preserved verbatim to keep single-evaluation semantics. */
export interface CompoundAssign { type: 'CompoundAssign'; target: Expr; op: string; value: Expr; line: number; }
export interface CallStat { type: 'CallStat'; call: Call | MethodCall; line: number; }
export interface Do { type: 'Do'; body: Block; line: number; }
export interface While { type: 'While'; cond: Expr; body: Block; line: number; }
export interface Repeat { type: 'Repeat'; body: Block; cond: Expr; line: number; }
export interface IfClause { cond: Expr; body: Block; }
export interface If { type: 'If'; clauses: IfClause[]; elseBody: Block | null; line: number; }
export interface NumericFor {
  type: 'NumericFor'; variable: DeclName; start: Expr; stop: Expr; step: Expr | null; body: Block; line: number;
}
export interface GenericFor { type: 'GenericFor'; names: DeclName[]; exprs: Expr[]; body: Block; line: number; }
export interface FunctionDecl {
  type: 'FunctionDecl';
  base: DeclName;         // either a new local (isLocal) or a reference to resolve
  path: string[];         // function a.b.c -> ['b','c']
  method: string | null;  // function a:m -> 'm'
  func: FunctionExpr;
  isLocal: boolean;
  line: number;
}
export interface Return { type: 'Return'; exprs: Expr[]; line: number; }
export interface Break { type: 'Break'; line: number; }
export interface Continue { type: 'Continue'; line: number; }
export interface Goto { type: 'Goto'; label: string; line: number; }
export interface Label { type: 'Label'; name: string; line: number; }

export type Stmt =
  | LocalAssign | Assign | CompoundAssign | CallStat | Do | While | Repeat | If
  | NumericFor | GenericFor | FunctionDecl | Return | Break | Continue | Goto | Label;

// ---- expressions -----------------------------------------------------------
export interface NilLit { type: 'Nil'; line: number; }
export interface TrueLit { type: 'True'; line: number; }
export interface FalseLit { type: 'False'; line: number; }
export interface Vararg { type: 'Vararg'; line: number; }
export interface NumberLit { type: 'Number'; raw: string; line: number; }
export interface StringLit { type: 'String'; value: string; long?: boolean; line: number; }
export interface NameRef { type: 'Name'; name: string; binding: Binding | null; line: number; }
export interface Paren { type: 'Paren'; expr: Expr; line: number; }
export interface Field { type: 'Field'; obj: Expr; name: string; line: number; }
export interface Index { type: 'Index'; obj: Expr; index: Expr; line: number; }
export interface Call { type: 'Call'; func: Expr; args: Expr[]; line: number; }
export interface MethodCall { type: 'MethodCall'; obj: Expr; method: string; args: Expr[]; line: number; }
export interface FunctionExpr { type: 'Function'; params: Param[]; isVararg: boolean; body: Block; line: number; }

export type TableField =
  | { kind: 'item'; value: Expr }
  | { kind: 'named'; key: string; value: Expr }
  | { kind: 'keyed'; key: Expr; value: Expr };
export interface Table { type: 'Table'; fields: TableField[]; line: number; }
export interface Binop { type: 'Binop'; op: string; left: Expr; right: Expr; line: number; }
export interface Unop { type: 'Unop'; op: string; operand: Expr; line: number; }

export type Expr =
  | NilLit | TrueLit | FalseLit | Vararg | NumberLit | StringLit | NameRef
  | Paren | Field | Index | Call | MethodCall | FunctionExpr | Table | Binop | Unop;

export interface Chunk { type: 'Chunk'; body: Block; }

/** Narrowing helper for the two call forms. */
export function isCall(e: Expr): e is Call | MethodCall {
  return e.type === 'Call' || e.type === 'MethodCall';
}
