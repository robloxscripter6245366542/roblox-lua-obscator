import { describe, it, expect } from 'vitest';
import { obfuscate } from '../../src/pipeline.js';
import { resolveConfig, type UserConfig } from '../../src/config/config.js';
import { validateEquivalence, hasInterpreter } from '../../src/validate/validator.js';

const LUA = process.env.LUA_BIN ?? 'lua5.4';
const HAS_LUA = hasInterpreter(LUA);

/** Representative programs exercising the language features passes touch. */
const PROGRAMS: [string, string][] = [
  ['arithmetic', 'print(1 + 2 * 3, 2 ^ 10, 7 // 2, 7 % 3, -5)'],
  ['strings', 'local s = "a\\tb" print(#s, s .. "!", ("x"):rep(3))'],
  ['closures', 'local function counter() local n = 0 return function() n = n + 1 return n end end\nlocal c = counter() print(c(), c(), c())'],
  ['varargs', 'local function sum(...) local t = 0 for _, v in ipairs({...}) do t = t + v end return t end print(sum(1,2,3,4))'],
  ['tables', 'local t = {1,2,3, k = "v"} t[#t+1] = 4 print(#t, t.k, t[4])'],
  ['recursion', 'local function fib(n) if n < 2 then return n end return fib(n-1) + fib(n-2) end print(fib(10))'],
  ['control', 'local o = "" for i=1,5 do if i % 2 == 0 then o = o .. i end end print(o)'],
  ['multiret', 'local function mr() return 1, 2, 3 end local a, b, c = mr() print(a, b, c)'],
  ['shadowing', 'local x = 1 do local x = x + 10 print(x) end print(x)'],
  ['string-call-sugar', 'print "hello" print(("%d/%d"):format(3, 4))'],
];

const CONFIGS: [string, UserConfig][] = [
  ['rename-only', { passes: { rename: true, encodeNumbers: false, encodeStrings: false, opaquePredicates: false, pack: false } }],
  ['encode', { passes: { rename: true, encodeNumbers: true, encodeStrings: true, opaquePredicates: false, pack: false } }],
  ['opaque', { passes: { rename: true, encodeNumbers: true, encodeStrings: true, opaquePredicates: true, pack: false } }],
  ['full', { passes: { rename: true, encodeNumbers: true, encodeStrings: true, opaquePredicates: true, pack: true } }],
];

describe.skipIf(!HAS_LUA)(`behavior equivalence (${LUA})`, () => {
  for (const [cfgName, userCfg] of CONFIGS) {
    for (const [progName, src] of PROGRAMS) {
      it(`${cfgName}: ${progName}`, () => {
        const config = resolveConfig({ seed: 7, ...userCfg });
        const { code } = obfuscate(src, { config });
        const result = validateEquivalence(src, code, { luaBin: LUA });
        expect(result.status, result.status === 'mismatch'
          ? `expected:\n${result.expected}\nactual:\n${result.actual}` : '').not.toBe('mismatch');
      });
    }
  }
});

describe('determinism', () => {
  it('same seed yields identical output', () => {
    const config = resolveConfig({ seed: 123 });
    const src = 'local x = 1 print(x + 2)';
    expect(obfuscate(src, { config }).code).toBe(obfuscate(src, { config }).code);
  });
});
