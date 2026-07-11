/**
 * Recursive-descent parser with precedence-climbing expressions. Produces the
 * typed AST in ../ast/nodes.ts. Covers the executable Luau grammar: statements,
 * control flow, functions/closures, varargs, tables, operators, labels/goto,
 * plus Luau `continue` and compound assignment.
 *
 * Type annotations and string interpolation are not yet parsed; such files are
 * rejected with a precise diagnostic rather than mis-parsed (see docs).
 */
import { parseError, type SourceLocation } from '../diagnostics.js';
import { tokenize } from '../lexer/lexer.js';
import type { Token } from '../lexer/token.js';
import type {
  Block, Chunk, Expr, Stmt, TableField, DeclName, Param, FunctionExpr, Call, MethodCall,
} from '../ast/nodes.js';

const BLOCK_END = new Set(['end', 'else', 'elseif', 'until']);
const COMPOUND = new Set(['+=', '-=', '*=', '/=', '%=', '^=', '..=']);

// binary operator [left, right] binding powers; right < left => right-assoc.
const BINPRI: Record<string, [number, number]> = {
  or: [1, 1], and: [2, 2],
  '<': [3, 3], '>': [3, 3], '<=': [3, 3], '>=': [3, 3], '~=': [3, 3], '==': [3, 3],
  '|': [4, 4], '~': [5, 5], '&': [6, 6], '<<': [7, 7], '>>': [7, 7],
  '..': [9, 8], '+': [10, 10], '-': [10, 10],
  '*': [11, 11], '/': [11, 11], '//': [11, 11], '%': [11, 11],
  '^': [14, 13],
};
const UNARY_PRI = 12;

export class Parser {
  private i = 0;
  constructor(private readonly toks: Token[], private readonly chunk = 'input') {}

  private peek(o = 0): Token {
    return this.toks[this.i + o] ?? this.toks[this.toks.length - 1]!;
  }
  private next(): Token { const t = this.peek(); this.i++; return t; }
  private loc(): SourceLocation { return { chunk: this.chunk, line: this.peek().line }; }
  private err(msg: string): never {
    const t = this.peek();
    parseError(`${msg} near '${t.type === 'eof' ? '<eof>' : t.value}'`, this.loc());
  }
  private is(type: Token['type'], value?: string): boolean {
    const t = this.peek();
    return t.type === type && (value === undefined || t.value === value);
  }
  private isSym(v: string): boolean { return this.is('symbol', v); }
  private isKw(v: string): boolean { return this.is('keyword', v); }
  private accept(type: Token['type'], value?: string): Token | null {
    return this.is(type, value) ? this.next() : null;
  }
  private expect(type: Token['type'], value?: string): Token {
    if (!this.is(type, value)) this.err(`'${value ?? type}' expected`);
    return this.next();
  }
  private expectName(): string {
    if (!this.is('name')) this.err('name expected');
    return this.next().value;
  }

  parseChunk(): Chunk {
    const body = this.block();
    if (!this.is('eof')) this.err("'<eof>' expected");
    return { type: 'Chunk', body };
  }

  private block(): Block {
    const stmts: Block = [];
    for (;;) {
      const t = this.peek();
      if (t.type === 'eof') break;
      if (t.type === 'keyword' && BLOCK_END.has(t.value)) break;
      if (t.type === 'keyword' && t.value === 'return') { stmts.push(this.retStat()); break; }
      const s = this.statement();
      if (s) stmts.push(s);
    }
    return stmts;
  }

  private retStat(): Stmt {
    const line = this.next().line;
    let exprs: Expr[] = [];
    const t = this.peek();
    const endsBlock = t.type === 'eof' || (t.type === 'keyword' && BLOCK_END.has(t.value));
    if (!endsBlock && !this.isSym(';')) exprs = this.exprList();
    this.accept('symbol', ';');
    return { type: 'Return', exprs, line };
  }

  private statement(): Stmt | null {
    const t = this.peek();
    if (t.type === 'symbol' && t.value === ';') { this.next(); return null; }
    if (t.type === 'symbol' && t.value === '::') return this.labelStat();
    // Luau `continue`: a bare `continue` not used as a prefix expression.
    if (t.type === 'name' && t.value === 'continue' && this.continueLooksLikeStatement()) {
      this.next();
      return { type: 'Continue', line: t.line };
    }
    if (t.type === 'keyword') {
      switch (t.value) {
        case 'break': this.next(); return { type: 'Break', line: t.line };
        case 'goto': this.next(); return { type: 'Goto', label: this.expectName(), line: t.line };
        case 'do': { this.next(); const b = this.block(); this.expect('keyword', 'end'); return { type: 'Do', body: b, line: t.line }; }
        case 'while': return this.whileStat();
        case 'repeat': return this.repeatStat();
        case 'if': return this.ifStat();
        case 'for': return this.forStat();
        case 'function': return this.funcStat();
        case 'local': return this.localStat();
        default: break;
      }
    }
    return this.exprStat();
  }

  private continueLooksLikeStatement(): boolean {
    const nxt = this.peek(1);
    if (nxt.type === 'string') return false;
    if (nxt.type === 'symbol') return !['(', '{', '[', '.', ':', '=', ',', ...COMPOUND].includes(nxt.value);
    return true;
  }

  private labelStat(): Stmt {
    const line = this.next().line;
    const name = this.expectName();
    this.expect('symbol', '::');
    return { type: 'Label', name, line };
  }

  private whileStat(): Stmt {
    const line = this.next().line;
    const cond = this.expr();
    this.expect('keyword', 'do');
    const body = this.block();
    this.expect('keyword', 'end');
    return { type: 'While', cond, body, line };
  }

  private repeatStat(): Stmt {
    const line = this.next().line;
    const body = this.block();
    this.expect('keyword', 'until');
    const cond = this.expr();
    return { type: 'Repeat', body, cond, line };
  }

  private ifStat(): Stmt {
    const line = this.next().line;
    const clauses = [{ cond: this.expr(), body: (this.expect('keyword', 'then'), this.block()) }];
    while (this.isKw('elseif')) {
      this.next();
      const cond = this.expr();
      this.expect('keyword', 'then');
      clauses.push({ cond, body: this.block() });
    }
    let elseBody: Block | null = null;
    if (this.accept('keyword', 'else')) elseBody = this.block();
    this.expect('keyword', 'end');
    return { type: 'If', clauses, elseBody, line };
  }

  private forStat(): Stmt {
    const line = this.next().line;
    const first = this.expectName();
    if (this.isSym('=')) {
      this.next();
      const start = this.expr();
      this.expect('symbol', ',');
      const stop = this.expr();
      let step: Expr | null = null;
      if (this.accept('symbol', ',')) step = this.expr();
      this.expect('keyword', 'do');
      const body = this.block();
      this.expect('keyword', 'end');
      return { type: 'NumericFor', variable: { name: first }, start, stop, step, body, line };
    }
    const names: DeclName[] = [{ name: first }];
    while (this.accept('symbol', ',')) names.push({ name: this.expectName() });
    this.expect('keyword', 'in');
    const exprs = this.exprList();
    this.expect('keyword', 'do');
    const body = this.block();
    this.expect('keyword', 'end');
    return { type: 'GenericFor', names, exprs, body, line };
  }

  private funcStat(): Stmt {
    const line = this.next().line;
    const base: DeclName = { name: this.expectName() };
    const path: string[] = [];
    let method: string | null = null;
    while (this.isSym('.')) { this.next(); path.push(this.expectName()); }
    if (this.accept('symbol', ':')) method = this.expectName();
    const func = this.funcBody(line, method !== null);
    return { type: 'FunctionDecl', base, path, method, func, isLocal: false, line };
  }

  private localStat(): Stmt {
    const line = this.next().line;
    if (this.accept('keyword', 'function')) {
      const base: DeclName = { name: this.expectName() };
      const func = this.funcBody(line, false);
      return { type: 'FunctionDecl', base, path: [], method: null, func, isLocal: true, line };
    }
    const names = [this.localName()];
    while (this.accept('symbol', ',')) names.push(this.localName());
    let exprs: Expr[] = [];
    if (this.accept('symbol', '=')) exprs = this.exprList();
    return { type: 'LocalAssign', names, exprs, line };
  }

  private localName(): DeclName {
    const name = this.expectName();
    let attrib: string | null = null;
    if (this.accept('symbol', '<')) { attrib = this.expectName(); this.expect('symbol', '>'); }
    return { name, attrib };
  }

  private funcBody(line: number, isMethod: boolean): FunctionExpr {
    this.expect('symbol', '(');
    const params: Param[] = [];
    let isVararg = false;
    if (isMethod) params.push({ name: 'self', implicit: true });
    if (!this.isSym(')')) {
      do {
        if (this.isSym('...')) { this.next(); isVararg = true; break; }
        params.push({ name: this.expectName() });
      } while (this.accept('symbol', ','));
    }
    this.expect('symbol', ')');
    const body = this.block();
    this.expect('keyword', 'end');
    return { type: 'Function', params, isVararg, body, line };
  }

  private exprStat(): Stmt {
    const line = this.peek().line;
    const first = this.suffixedExpr();
    if (this.peek().type === 'symbol' && COMPOUND.has(this.peek().value)) {
      const op = this.next().value.slice(0, -1); // '+=' -> '+'
      const value = this.expr();
      this.assertLValue(first);
      return { type: 'CompoundAssign', target: first, op, value, line };
    }
    if (this.isSym('=') || this.isSym(',')) {
      const targets = [first];
      while (this.accept('symbol', ',')) targets.push(this.suffixedExpr());
      this.expect('symbol', '=');
      const exprs = this.exprList();
      for (const tg of targets) this.assertLValue(tg);
      return { type: 'Assign', targets, exprs, line };
    }
    if (first.type !== 'Call' && first.type !== 'MethodCall') this.err('syntax error (statement expected)');
    return { type: 'CallStat', call: first as Call | MethodCall, line };
  }

  private assertLValue(e: Expr): void {
    if (e.type !== 'Name' && e.type !== 'Index' && e.type !== 'Field') this.err('cannot assign to this expression');
  }

  // ---- expressions ---------------------------------------------------------
  private exprList(): Expr[] {
    const list = [this.expr()];
    while (this.accept('symbol', ',')) list.push(this.expr());
    return list;
  }

  private expr(): Expr { return this.subExpr(0); }

  private binop(): string | null {
    const t = this.peek();
    if (t.type === 'symbol' && BINPRI[t.value]) return t.value;
    if (t.type === 'keyword' && (t.value === 'and' || t.value === 'or')) return t.value;
    return null;
  }
  private unop(): string | null {
    const t = this.peek();
    if (t.type === 'symbol' && (t.value === '-' || t.value === '#' || t.value === '~')) return t.value;
    if (t.type === 'keyword' && t.value === 'not') return t.value;
    return null;
  }

  private subExpr(limit: number): Expr {
    let e: Expr;
    const u = this.unop();
    if (u) {
      const line = this.next().line;
      e = { type: 'Unop', op: u, operand: this.subExpr(UNARY_PRI), line };
    } else {
      e = this.simpleExpr();
    }
    let op: string | null;
    while ((op = this.binop()) !== null && BINPRI[op]![0] > limit) {
      const line = this.next().line;
      const right = this.subExpr(BINPRI[op]![1]);
      e = { type: 'Binop', op, left: e, right, line };
    }
    return e;
  }

  private simpleExpr(): Expr {
    const t = this.peek();
    if (t.type === 'number') { this.next(); return { type: 'Number', raw: t.raw, line: t.line }; }
    if (t.type === 'string') { this.next(); return { type: 'String', value: t.value, long: t.long, line: t.line }; }
    if (t.type === 'keyword') {
      if (t.value === 'nil') { this.next(); return { type: 'Nil', line: t.line }; }
      if (t.value === 'true') { this.next(); return { type: 'True', line: t.line }; }
      if (t.value === 'false') { this.next(); return { type: 'False', line: t.line }; }
      if (t.value === 'function') { const l = this.next().line; return this.funcBody(l, false); }
    }
    if (t.type === 'symbol') {
      if (t.value === '...') { this.next(); return { type: 'Vararg', line: t.line }; }
      if (t.value === '{') return this.tableConstructor();
    }
    return this.suffixedExpr();
  }

  private primaryExpr(): Expr {
    const t = this.peek();
    if (t.type === 'symbol' && t.value === '(') {
      this.next();
      const e = this.expr();
      this.expect('symbol', ')');
      return { type: 'Paren', expr: e, line: t.line };
    }
    if (t.type === 'name') { this.next(); return { type: 'Name', name: t.value, binding: null, line: t.line }; }
    this.err('unexpected symbol');
  }

  private suffixedExpr(): Expr {
    let e = this.primaryExpr();
    for (;;) {
      const t = this.peek();
      if (t.type === 'symbol' && t.value === '.') {
        this.next();
        e = { type: 'Field', obj: e, name: this.expectName(), line: t.line };
      } else if (t.type === 'symbol' && t.value === '[') {
        this.next();
        const index = this.expr();
        this.expect('symbol', ']');
        e = { type: 'Index', obj: e, index, line: t.line };
      } else if (t.type === 'symbol' && t.value === ':') {
        this.next();
        const method = this.expectName();
        const args = this.callArgs();
        e = { type: 'MethodCall', obj: e, method, args, line: t.line } satisfies MethodCall;
      } else if ((t.type === 'symbol' && (t.value === '(' || t.value === '{')) || t.type === 'string') {
        e = { type: 'Call', func: e, args: this.callArgs(), line: t.line } satisfies Call;
      } else break;
    }
    return e;
  }

  private callArgs(): Expr[] {
    const t = this.peek();
    if (t.type === 'string') { this.next(); return [{ type: 'String', value: t.value, long: t.long, line: t.line }]; }
    if (t.type === 'symbol' && t.value === '{') return [this.tableConstructor()];
    this.expect('symbol', '(');
    let args: Expr[] = [];
    if (!this.isSym(')')) args = this.exprList();
    this.expect('symbol', ')');
    return args;
  }

  private tableConstructor(): Expr {
    const line = this.expect('symbol', '{').line;
    const fields: TableField[] = [];
    while (!this.isSym('}')) {
      if (this.isSym('[')) {
        this.next();
        const key = this.expr();
        this.expect('symbol', ']');
        this.expect('symbol', '=');
        fields.push({ kind: 'keyed', key, value: this.expr() });
      } else if (this.is('name') && this.peek(1).type === 'symbol' && this.peek(1).value === '=') {
        const key = this.next().value;
        this.next(); // '='
        fields.push({ kind: 'named', key, value: this.expr() });
      } else {
        fields.push({ kind: 'item', value: this.expr() });
      }
      if (!this.accept('symbol', ',') && !this.accept('symbol', ';')) break;
    }
    this.expect('symbol', '}');
    return { type: 'Table', fields, line };
  }
}

export function parse(src: string, chunk = 'input'): Chunk {
  return new Parser(tokenize(src, chunk), chunk).parseChunk();
}
