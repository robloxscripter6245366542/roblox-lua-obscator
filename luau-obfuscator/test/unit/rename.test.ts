import { describe, it, expect } from 'vitest';
import { parse } from '../../src/parser/parser.js';
import { generate } from '../../src/codegen/generator.js';
import { obfuscate } from '../../src/pipeline.js';
import { resolveConfig } from '../../src/config/config.js';

function renameOnly(src: string): string {
  const config = resolveConfig({
    seed: 1,
    passes: { rename: true, encodeNumbers: false, encodeStrings: false, opaquePredicates: false, pack: false },
  });
  return obfuscate(src, { config }).code;
}

describe('scope-aware renaming', () => {
  it('renames locals but never globals, fields, or method names', () => {
    const out = renameOnly('local x = 1\nprint(x)\nlocal t = {}\nt.field = x\nt:method(x)');
    expect(out).toContain('print(');       // global preserved
    expect(out).toContain('.field');       // field name preserved
    expect(out).toContain(':method(');     // method name preserved
    expect(out).not.toMatch(/\blocal x\b/); // the local was renamed away
  });

  it('keeps shadowed variables distinct', () => {
    const out = renameOnly('local a = 1\ndo local a = 2 print(a) end\nprint(a)');
    // two different bindings -> two different generated names
    const names = [...out.matchAll(/local (\w+)=/g)].map((m) => m[1]);
    expect(new Set(names).size).toBe(2);
  });

  it('does not rename implicit method self', () => {
    const out = renameOnly('local t = {} function t:m() return self end');
    expect(out).toContain('return self');
  });

  it('renames a recursive local function consistently', () => {
    const out = renameOnly('local function fac(n) if n <= 1 then return 1 end return n * fac(n - 1) end\nprint(fac(5))');
    const decl = out.match(/local function (\w+)\(/)?.[1];
    expect(decl).toBeDefined();
    // the recursive call uses the same renamed identifier
    expect(out).toContain(`${decl}(`);
    expect(out).not.toContain('fac');
  });

  it('is deterministic for a fixed seed', () => {
    const a = renameOnly('local q = 1 print(q)');
    const b = renameOnly('local q = 1 print(q)');
    expect(a).toBe(b);
  });

  it('produces parseable output', () => {
    const out = renameOnly('local function f(a,b) return a+b end for i=1,3 do print(f(i,i)) end');
    expect(() => parse(out)).not.toThrow();
    expect(generate(parse(out)).length).toBeGreaterThan(0);
  });
});
