import { describe, it, expect } from 'vitest';
import { keystream, Prng } from '../../src/util/prng.js';
import { xorEncrypt, base64Encode, chunkString } from '../../src/util/encoding.js';
import { resolveConfig, parseConfig } from '../../src/config/config.js';

describe('prng + keystream', () => {
  it('keystream products stay exact in doubles (< 2^53)', () => {
    // largest intermediate is state*16807; state < 2^31 => product < ~3.6e13 < 2^53
    const ks = keystream(2147483000, 32);
    expect(ks.every((b) => b >= 0 && b < 256 && Number.isInteger(b))).toBe(true);
  });

  it('keystream is deterministic per salt', () => {
    expect(keystream(123, 16)).toEqual(keystream(123, 16));
    expect(keystream(123, 16)).not.toEqual(keystream(124, 16));
  });

  it('prng is reproducible per seed', () => {
    const a = new Prng(7);
    const b = new Prng(7);
    expect([a.next(), a.next(), a.next()]).toEqual([b.next(), b.next(), b.next()]);
  });

  it('renamed identifiers are digit-prefixed, helper names letter-prefixed', () => {
    const r = new Prng(1);
    expect(r.identifier(true)).toMatch(/^_[0-9][0-9a-f]{6}$/);
    expect(r.identifier(false)).toMatch(/^_[a-z][0-9a-f]{6}$/);
  });
});

describe('xor + base64 round-trip', () => {
  it('xor is an involution with the same salt', () => {
    const data = 'the quick brown fox \x00\xff';
    const enc = xorEncrypt(data, 999);
    expect(xorEncrypt(enc, 999)).toBe(data);
  });

  it('base64 matches btoa for ascii', () => {
    expect(base64Encode('hello')).toBe(Buffer.from('hello', 'latin1').toString('base64'));
  });

  it('chunkString splits without loss', () => {
    expect(chunkString('abcdef', 2)).toEqual(['ab', 'cd', 'ef']);
    expect(chunkString('abcde', 2).join('')).toBe('abcde');
  });
});

describe('config', () => {
  it('applies defaults and merges toggles', () => {
    const c = resolveConfig({ passes: { pack: false } });
    expect(c.passes.pack).toBe(false);
    expect(c.passes.rename).toBe(true);
  });

  it('rejects an out-of-range opaquePredicateRate', () => {
    expect(() => resolveConfig({ opaquePredicateRate: 2 })).toThrow(/config/);
  });

  it('parses a JSON config', () => {
    const c = parseConfig('{"seed": 42, "passes": {"encodeStrings": false}}');
    expect(c.seed).toBe(42);
    expect(c.passes.encodeStrings).toBe(false);
  });

  it('rejects invalid JSON with a diagnostic', () => {
    expect(() => parseConfig('{ not json')).toThrow(/config/);
  });
});
