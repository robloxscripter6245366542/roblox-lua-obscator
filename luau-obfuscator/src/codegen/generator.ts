/**
 * Code generator: AST -> valid Luau source.
 *
 * Binary/unary operators are fully parenthesized so precedence and
 * associativity are preserved without tracking them. Statements are emitted one
 * per line; a statement whose text begins with '(' is prefixed with ';' to
 * defuse the prefix-expression ambiguity (`a = b` / `(f)()`). Identifiers are
 * emitted through {@link nameOf}, which returns a binding's `newName` when the
 * rename pass has assigned one.
 */
import type {
  Block, Chunk, Expr, Stmt, DeclName, Param, FunctionExpr, Binding,
} from '../ast/nodes.js';

export interface GeneratorOptions {
  /** Indentation unit; '' produces compact output. */
  readonly indentUnit?: string;
}

function nameOfBinding(name: string, binding: Binding | null | undefined): string {
  return binding && binding.newName ? binding.newName : name;
}
function nameOfDecl(d: DeclName | Param): string { return nameOfBinding(d.name, d.binding); }

/** Encode any string value as a portable double-quoted literal (pure ASCII). */
export function stringLiteral(s: string): string {
  const out: string[] = ['"'];
  for (let i = 0; i < s.length; i++) {
    const b = s.charCodeAt(i);
    if (b === 34) out.push('\\"');
    else if (b === 92) out.push('\\\\');
    else if (b >= 32 && b <= 126) out.push(String.fromCharCode(b));
    else out.push('\\' + ('00' + b).slice(-3));
  }
  out.push('"');
  return out.join('');
}

export class Generator {
  private readonly unit: string;
  constructor(opts: GeneratorOptions = {}) { this.unit = opts.indentUnit ?? ''; }

  generate(chunk: Chunk): string {
    return this.block(chunk.body, '');
  }

  private block(stmts: Block, indent: string): string {
    const out: string[] = [];
    for (const s of stmts) {
      const text = this.stmt(s, indent);
      out.push(indent + (text.charAt(0) === '(' ? ';' : '') + text + '\n');
    }
    return out.join('');
  }

  private sub(stmts: Block, indent: string): string {
    return this.block(stmts, indent + this.unit);
  }

  private stmt(s: Stmt, indent: string): string {
    switch (s.type) {
      case 'LocalAssign': {
        const ns = s.names.map((n) => nameOfDecl(n) + (n.attrib ? `<${n.attrib}>` : '')).join(',');
        return s.exprs.length ? `local ${ns}=${this.exprList(s.exprs)}` : `local ${ns}`;
      }
      case 'Assign':
        return `${this.exprList(s.targets)}=${this.exprList(s.exprs)}`;
      case 'CompoundAssign':
        return `${this.expr(s.target)}${s.op}=${this.expr(s.value)}`;
      case 'CallStat':
        return this.expr(s.call);
      case 'Do':
        return `do\n${this.sub(s.body, indent)}${indent}end`;
      case 'While':
        return `while ${this.expr(s.cond)} do\n${this.sub(s.body, indent)}${indent}end`;
      case 'Repeat':
        return `repeat\n${this.sub(s.body, indent)}${indent}until ${this.expr(s.cond)}`;
      case 'If': {
        let out = '';
        s.clauses.forEach((c, i) => {
          out += (i === 0 ? 'if ' : indent + 'elseif ') + this.expr(c.cond) + ' then\n' + this.sub(c.body, indent);
        });
        if (s.elseBody) out += indent + 'else\n' + this.sub(s.elseBody, indent);
        return out + indent + 'end';
      }
      case 'NumericFor': {
        let o = `for ${nameOfDecl(s.variable)}=${this.expr(s.start)},${this.expr(s.stop)}`;
        if (s.step) o += ',' + this.expr(s.step);
        return o + ` do\n${this.sub(s.body, indent)}${indent}end`;
      }
      case 'GenericFor':
        return `for ${s.names.map(nameOfDecl).join(',')} in ${this.exprList(s.exprs)} do\n`
          + `${this.sub(s.body, indent)}${indent}end`;
      case 'FunctionDecl': {
        if (s.isLocal) return `local function ${nameOfDecl(s.base)}${this.funcTail(s.func, indent)}`;
        let head = nameOfDecl(s.base);
        for (const p of s.path) head += '.' + p;
        if (s.method) head += ':' + s.method;
        return `function ${head}${this.funcTail(s.func, indent)}`;
      }
      case 'Return':
        return s.exprs.length ? `return ${this.exprList(s.exprs)}` : 'return';
      case 'Break': return 'break';
      case 'Continue': return 'continue';
      case 'Goto': return `goto ${s.label}`;
      case 'Label': return `::${s.name}::`;
      default: {
        const _exhaustive: never = s;
        throw new Error(`gen: unknown stmt ${(_exhaustive as { type: string }).type}`);
      }
    }
  }

  private funcTail(fn: FunctionExpr, indent: string): string {
    const params = fn.params.filter((p) => !p.implicit).map(nameOfDecl);
    if (fn.isVararg) params.push('...');
    return `(${params.join(',')})\n${this.sub(fn.body, indent)}${indent}end`;
  }

  private exprList(list: Expr[]): string {
    return list.map((e) => this.expr(e)).join(',');
  }

  expr(e: Expr): string {
    switch (e.type) {
      case 'Nil': return 'nil';
      case 'True': return 'true';
      case 'False': return 'false';
      case 'Vararg': return '...';
      case 'Number': return e.raw;
      case 'String': return stringLiteral(e.value);
      case 'Name': return nameOfBinding(e.name, e.binding);
      case 'Paren': return `(${this.expr(e.expr)})`;
      case 'Field': return `${this.expr(e.obj)}.${e.name}`;
      case 'Index': return `${this.expr(e.obj)}[${this.expr(e.index)}]`;
      case 'Call': return `${this.callTarget(e.func)}(${this.exprList(e.args)})`;
      case 'MethodCall': return `${this.callTarget(e.obj)}:${e.method}(${this.exprList(e.args)})`;
      case 'Binop': return `(${this.expr(e.left)} ${e.op} ${this.expr(e.right)})`;
      case 'Unop': return `(${e.op} ${this.expr(e.operand)})`;
      case 'Function': return `function${this.funcTail(e, '')}`;
      case 'Table': {
        if (e.fields.length === 0) return '{}';
        const parts = e.fields.map((f) => {
          if (f.kind === 'item') return this.expr(f.value);
          if (f.kind === 'named') return `${f.key}=${this.expr(f.value)}`;
          return `[${this.expr(f.key)}]=${this.expr(f.value)}`;
        });
        return `{${parts.join(',')}}`;
      }
      default: {
        const _exhaustive: never = e;
        throw new Error(`gen: unknown expr ${(_exhaustive as { type: string }).type}`);
      }
    }
  }

  private callTarget(e: Expr): string {
    switch (e.type) {
      case 'Name': case 'Field': case 'Index': case 'Call': case 'MethodCall': case 'Paren':
        return this.expr(e);
      default:
        return `(${this.expr(e)})`;
    }
  }
}

export function generate(chunk: Chunk, opts?: GeneratorOptions): string {
  return new Generator(opts).generate(chunk);
}
