/** Build-time encoding used by the string/pack passes. Byte strings are JS
 *  strings whose char codes are 0..255. */
import { keystream } from './prng.js';

/** XOR `data` with the Park-Miller keystream seeded by `salt`. */
export function xorEncrypt(data: string, salt: number): string {
  const ks = keystream(salt, data.length);
  const out = new Array<string>(data.length);
  for (let i = 0; i < data.length; i++) out[i] = String.fromCharCode(data.charCodeAt(i) ^ ks[i]!);
  return out.join('');
}

const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** Standard base64 over raw bytes (matches the emitted Lua decoder). */
export function base64Encode(data: string): string {
  const out: string[] = [];
  const len = data.length;
  for (let i = 0; i < len; i += 3) {
    const b1 = data.charCodeAt(i);
    const b2 = i + 1 < len ? data.charCodeAt(i + 1) : 0;
    const b3 = i + 2 < len ? data.charCodeAt(i + 2) : 0;
    const n = b1 * 65536 + b2 * 256 + b3;
    out.push(B64.charAt(Math.floor(n / 262144) % 64));
    out.push(B64.charAt(Math.floor(n / 4096) % 64));
    out.push(i + 1 < len ? B64.charAt(Math.floor(n / 64) % 64) : '=');
    out.push(i + 2 < len ? B64.charAt(n % 64) : '=');
  }
  return out.join('');
}

export function chunkString(s: string, size: number): string[] {
  const out: string[] = [];
  for (let i = 0; i < s.length; i += size) out.push(s.slice(i, i + size));
  return out;
}
