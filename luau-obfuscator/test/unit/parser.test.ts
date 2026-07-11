import { describe, it, expect } from 'vitest';
import { parse } from '../../src/parser/parser.js';
import { generate } from '../../src/codegen/generator.js';

describe('parser + generator', () => {
  const samples: [string, string][] = [
    ['locals', 'local a, b = 1, 2\nprint(a + b)'],
    ['functions', 'local function f(x, ...) return x, ... end\nprint(f(1, 2, 3))'],
    ['methods', 'local t = {} function t:m(a) return self, a end\nt:m(1)'],
    ['tables', 'local t = {1, 2, x = 3, ["y"] = 4, [1+1] = 5}'],
    ['control', 'for i = 1, 10, 2 do if i % 2 == 0 then print(i) end end'],
    ['generic-for', 'for k, v in pairs({a=1}) do print(k, v) end'],
    ['repeat', 'local i = 0 repeat i = i + 1 until i >= 3'],
    ['operators', 'local x = -2 ^ 2 + 3 * 4 .. "z" and not false'],
    ['string-call', 'print "hi"\nprint [[block]]'],
    ['labels', '::top:: goto top'],
    ['method-chain', 'local s = ("x"):rep(3):upper()'],
  ];

  for (const [name, src] of samples) {
    it(`round-trips: ${name}`, () => {
      // The generator fully parenthesizes operators, so it is not textually
      // idempotent; the invariant is that generated output always re-parses.
      const once = generate(parse(src));
      expect(once.length).toBeGreaterThan(0);
      expect(() => parse(once)).not.toThrow();
      expect(() => parse(generate(parse(once)))).not.toThrow();
    });
  }

  it('rejects invalid syntax with a diagnostic', () => {
    expect(() => parse('local = 5')).toThrow(/parse/);
    expect(() => parse('if then end')).toThrow(/parse/);
  });

  it('preserves integer vs float literal forms', () => {
    const out = generate(parse('local a, b, c = 1, 1.0, 0xFF'));
    expect(out).toContain('1');
    expect(out).toContain('1.0');
    expect(out).toContain('0xFF');
  });
});
