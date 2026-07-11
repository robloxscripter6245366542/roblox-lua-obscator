/**
 * Deterministic pseudo-random number generators.
 *
 * Two concerns share this module:
 *  - {@link Prng} drives build-time decisions (name choices, salts) so a given
 *    seed always yields the same obfuscated output.
 *  - {@link keystream} produces the XOR keystream used by string/chunk encoding.
 *    It MUST stay bit-identical to the Lua/Luau runtime decoder that ferret
 *    emits, so it uses a Park-Miller generator whose intermediate products stay
 *    below 2^53 and are therefore exact in JS numbers, Lua 5.3/5.4 integers, and
 *    Luau/Lua 5.1 doubles alike.
 */

const PM_MOD = 2147483647; // 2^31 - 1
const PM_MULT = 16807;

/** Deterministic PRNG (Park-Miller minimal standard). */
export class Prng {
  private state: number;

  constructor(seed: number) {
    // keep the state in [1, PM_MOD - 1]; 0 is a fixed point.
    this.state = (Math.abs(Math.trunc(seed)) % (PM_MOD - 1)) + 1;
  }

  /** Next integer in [0, 2^31 - 2]. */
  next(): number {
    this.state = (this.state * PM_MULT) % PM_MOD;
    return this.state;
  }

  /** Integer in [lo, hi] inclusive. */
  range(lo: number, hi: number): number {
    return lo + (this.next() % (hi - lo + 1));
  }

  /**
   * Opaque, valid Lua identifier. The character after `_` is a digit so the
   * namespace stays disjoint from other generated names that use a letter there
   * (see {@link generatedName}) — renamed locals can never collide with runtime
   * helper locals.
   */
  identifier(prefixDigit = true): string {
    const hex = '0123456789abcdef';
    let out = '_';
    out += prefixDigit ? String(this.next() % 10) : 'abcdefghijklmnopqrstuvwxyz'[this.next() % 26];
    for (let i = 0; i < 6; i++) out += hex[this.next() % 16];
    return out;
  }
}

/**
 * Park-Miller keystream. `salt` seeds it; the returned bytes XOR the plaintext.
 * The emitted runtime regenerates the identical sequence, so encode/decode match
 * on every supported runtime.
 */
export function keystream(salt: number, length: number): number[] {
  let state = (Math.abs(Math.trunc(salt)) % (PM_MOD - 1)) + 1;
  const out = new Array<number>(length);
  for (let i = 0; i < length; i++) {
    state = (state * PM_MULT) % PM_MOD;
    out[i] = state % 256;
  }
  return out;
}
