/** Token kinds produced by the lexer. */
export type TokenType = 'keyword' | 'name' | 'number' | 'string' | 'symbol' | 'eof';

export interface Token {
  readonly type: TokenType;
  /** For keyword/name/symbol: the text. For number: the numeric text. For string: the DECODED value. */
  readonly value: string;
  readonly line: number;
  /** Exact source text of the token (for numbers, the original literal). */
  readonly raw: string;
  /** True when a string came from a `[[ ]]` long bracket. */
  readonly long?: boolean;
}

export const KEYWORDS: ReadonlySet<string> = new Set([
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while',
  // Luau contextual keywords are lexed as names and handled by the parser
  // (`continue`, `type`, `export`) so they remain usable as identifiers.
]);

/** Multi-character symbols, ordered longest-first so greedy matching is correct. */
export const SYMBOLS: readonly string[] = [
  // 3-char
  '...', '..=',
  // 2-char
  '..', '::', '==', '~=', '<=', '>=', '//', '<<', '>>',
  '+=', '-=', '*=', '/=', '%=', '^=',
  // 1-char
  '+', '-', '*', '/', '%', '^', '#', '&', '~', '|', '<', '>', '=',
  '(', ')', '{', '}', '[', ']', ';', ':', ',', '.', '?',
];
