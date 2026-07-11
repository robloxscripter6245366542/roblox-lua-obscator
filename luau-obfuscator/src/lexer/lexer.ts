/**
 * Lexer: converts Luau source into a flat token stream. Byte-oriented (operates
 * on char codes) so it round-trips arbitrary string contents. Records the exact
 * `raw` text of every token so the generator can reproduce literals faithfully.
 */
import { lexError, type SourceLocation } from '../diagnostics.js';
import { KEYWORDS, SYMBOLS, type Token } from './token.js';

function isDigit(c: string): boolean { return c >= '0' && c <= '9'; }
function isHex(c: string): boolean {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}
function isAlpha(c: string): boolean {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c === '_';
}
function isAlphaNum(c: string): boolean { return isAlpha(c) || isDigit(c); }

export function tokenize(src: string, chunk = 'input'): Token[] {
  const tokens: Token[] = [];
  const n = src.length;
  let pos = 0;
  let line = 1;

  const loc = (): SourceLocation => ({ chunk, line });
  const peek = (o = 0): string => src.charAt(pos + o);

  function newline(): void {
    const c = peek();
    pos++;
    const c2 = peek();
    if ((c2 === '\n' || c2 === '\r') && c2 !== c) pos++;
    line++;
  }

  function readLongBracket(): string | null {
    if (peek() !== '[') return null;
    let level = 0;
    let p = pos + 1;
    while (src.charAt(p) === '=') { level++; p++; }
    if (src.charAt(p) !== '[') return null;
    pos = p + 1;
    if (peek() === '\r' || peek() === '\n') newline();
    const buf: string[] = [];
    const close = ']' + '='.repeat(level) + ']';
    for (;;) {
      if (pos >= n) lexError('unfinished long bracket', loc());
      const c = peek();
      if (c === ']' && src.substr(pos, close.length) === close) {
        pos += close.length;
        return buf.join('');
      } else if (c === '\n' || c === '\r') {
        buf.push('\n'); newline();
      } else { buf.push(c); pos++; }
    }
  }

  function readString(quote: string): string {
    pos++;
    const buf: string[] = [];
    for (;;) {
      if (pos >= n) lexError('unfinished string', loc());
      const c = peek();
      if (c === quote) { pos++; break; }
      if (c === '\n' || c === '\r') lexError('unfinished string', loc());
      if (c === '\\') {
        pos++;
        const e = peek();
        switch (e) {
          case 'n': buf.push('\n'); pos++; break;
          case 't': buf.push('\t'); pos++; break;
          case 'r': buf.push('\r'); pos++; break;
          case 'a': buf.push('\x07'); pos++; break;
          case 'b': buf.push('\b'); pos++; break;
          case 'f': buf.push('\f'); pos++; break;
          case 'v': buf.push('\x0b'); pos++; break;
          case '\\': buf.push('\\'); pos++; break;
          case '"': buf.push('"'); pos++; break;
          case "'": buf.push("'"); pos++; break;
          case '\n': case '\r': buf.push('\n'); newline(); break;
          case 'x': {
            pos++;
            let h = '';
            for (let k = 0; k < 2; k++) { if (isHex(peek())) { h += peek(); pos++; } }
            if (h.length === 0) lexError('hexadecimal digit expected', loc());
            buf.push(String.fromCharCode(parseInt(h, 16)));
            break;
          }
          case 'z': {
            pos++;
            while (pos < n) {
              const w = peek();
              if (w === '\n' || w === '\r') newline();
              else if (w === ' ' || w === '\t' || w === '\f' || w === '\x0b') pos++;
              else break;
            }
            break;
          }
          default: {
            if (isDigit(e)) {
              let d = '';
              for (let j = 0; j < 3; j++) { if (isDigit(peek())) { d += peek(); pos++; } else break; }
              const num = parseInt(d, 10);
              if (num > 255) lexError('decimal escape too large', loc());
              buf.push(String.fromCharCode(num));
            } else {
              lexError(`invalid escape sequence '\\${e}'`, loc());
            }
          }
        }
      } else { buf.push(c); pos++; }
    }
    return buf.join('');
  }

  function readNumber(): string {
    const start = pos;
    if (peek() === '0' && (peek(1) === 'x' || peek(1) === 'X')) {
      pos += 2;
      while (isHex(peek()) || peek() === '.' || peek() === '_') pos++;
      if (peek() === 'p' || peek() === 'P') {
        pos++;
        if (peek() === '+' || peek() === '-') pos++;
        while (isDigit(peek())) pos++;
      }
    } else {
      // decimal / binary (Luau 0b) with digit separators
      if (peek() === '0' && (peek(1) === 'b' || peek(1) === 'B')) {
        pos += 2;
        while (peek() === '0' || peek() === '1' || peek() === '_') pos++;
      } else {
        while (isDigit(peek()) || peek() === '.' || peek() === '_') pos++;
        if (peek() === 'e' || peek() === 'E') {
          pos++;
          if (peek() === '+' || peek() === '-') pos++;
          while (isDigit(peek())) pos++;
        }
      }
    }
    return src.substring(start, pos);
  }

  while (pos < n) {
    const c = peek();
    const tokStart = pos;
    if (c === '\n' || c === '\r') {
      newline();
    } else if (c === ' ' || c === '\t' || c === '\f' || c === '\x0b') {
      pos++;
    } else if (c === '-' && peek(1) === '-') {
      pos += 2;
      if (peek() === '[') {
        const saved = pos;
        const content = readLongBracket();
        if (content === null) {
          pos = saved;
          while (pos < n && peek() !== '\n' && peek() !== '\r') pos++;
        }
      } else {
        while (pos < n && peek() !== '\n' && peek() !== '\r') pos++;
      }
    } else if (isAlpha(c)) {
      while (isAlphaNum(peek())) pos++;
      const word = src.substring(tokStart, pos);
      tokens.push({ type: KEYWORDS.has(word) ? 'keyword' : 'name', value: word, line, raw: word });
    } else if (isDigit(c) || (c === '.' && isDigit(peek(1)))) {
      const ln = line;
      const numText = readNumber();
      tokens.push({ type: 'number', value: numText, line: ln, raw: numText });
    } else if (c === '"' || c === "'") {
      const ln = line;
      const sval = readString(c);
      tokens.push({ type: 'string', value: sval, line: ln, raw: src.substring(tokStart, pos), long: false });
    } else if (c === '[' && (peek(1) === '[' || peek(1) === '=')) {
      const ln = line;
      const lc = readLongBracket();
      if (lc !== null) {
        tokens.push({ type: 'string', value: lc, line: ln, raw: src.substring(tokStart, pos), long: true });
      } else {
        tokens.push({ type: 'symbol', value: '[', line: ln, raw: '[' });
        pos++;
      }
    } else {
      let matched: string | null = null;
      for (const sym of SYMBOLS) {
        if (src.substr(pos, sym.length) === sym) { matched = sym; break; }
      }
      if (matched === null) lexError(`unexpected symbol near '${c}'`, loc());
      tokens.push({ type: 'symbol', value: matched, line, raw: matched });
      pos += matched.length;
    }
  }

  tokens.push({ type: 'eof', value: '<eof>', line, raw: '' });
  return tokens;
}
