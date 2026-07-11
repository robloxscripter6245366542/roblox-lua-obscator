/**
 * Emitted-runtime Luau templates. These are the only place we generate Luau as
 * text rather than from the AST; they are small, fixed, and generated with
 * mangled local names so the output carries no plain helper identifiers.
 *
 * All arithmetic here is exact in Luau/Lua 5.1 doubles and Lua 5.3/5.4 integers:
 * the keystream is Park-Miller (`st = st*16807 % 2147483647`), matching
 * util/prng.ts so encode/decode agree on every runtime.
 */

export interface StringDecoderNames {
  readonly decode: string; // the decoder function
  readonly sc: string;     // string.char
  readonly sb: string;     // string.byte
  readonly tc: string;     // table.concat
  readonly cache: string;  // memo table
}

/** Prelude that defines the string decoder `names.decode(cipher, salt)`. */
export function stringDecoderPrelude(n: StringDecoderNames): string {
  return [
    `local ${n.sc}=string.char`,
    `local ${n.sb}=string.byte`,
    `local ${n.tc}=table.concat`,
    `local ${n.cache}={}`,
    `local function ${n.decode}(e,s)`,
    `local ck=s..'|'..e`,
    `local cv=${n.cache}[ck]`,
    `if cv~=nil then return cv end`,
    `local t={}`,
    `local st=s%2147483646+1`,
    `for i=1,#e do`,
    `st=(st*16807)%2147483647`,
    `local k=st%256`,
    `local a,b=${n.sb}(e,i),k`,
    `local r,p=0,1`,
    `while a>0 or b>0 do`,
    `local aa,bb=a%2,b%2`,
    `if aa~=bb then r=r+p end`,
    `a=(a-aa)/2 b=(b-bb)/2 p=p*2`,
    `end`,
    `t[i]=${n.sc}(r)`,
    `end`,
    `local out=${n.tc}(t)`,
    `${n.cache}[ck]=out`,
    `return out`,
    `end`,
  ].join('\n');
}

export interface PackNames {
  readonly alphabet: string;
  readonly payload: string;
  readonly joined: string;
  readonly b64dec: string;
  readonly xordec: string;
  readonly src: string;
  readonly loader: string;
  readonly fn: string;
}

const B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/**
 * Standalone loader that decodes (base64), decrypts (XOR keystream), compiles,
 * and runs the encrypted chunk. Requires `loadstring` (Roblox executors, or a
 * server with LoadStringEnabled).
 */
export function packLoader(parts: string[], key: number, n: PackNames): string {
  const alphaBytes = Array.from(B64, (c) => String(c.charCodeAt(0))).join(',');
  const L: string[] = [];
  L.push(`local ${n.alphabet}=string.char(${alphaBytes})`);
  L.push(`local ${n.payload}={`);
  parts.forEach((c, i) => L.push(`'${c}'${i < parts.length - 1 ? ',' : ''}`));
  L.push('}');
  L.push(`local ${n.joined}=table.concat(${n.payload})`);
  L.push(`local function ${n.b64dec}(s)`);
  L.push('  local r,v,b={},0,0');
  L.push(`  s=s:gsub('[^'..${n.alphabet}..'=]','')`);
  L.push('  for i=1,#s do');
  L.push('    local c=s:sub(i,i)');
  L.push("    if c=='=' then break end");
  L.push(`    local p=${n.alphabet}:find(c,1,true)`);
  L.push('    if not p then break end');
  L.push('    v=v*64+(p-1) b=b+6');
  L.push('    if b>=8 then b=b-8 r[#r+1]=string.char(math.floor(v/2^b)%256) v=v%(2^b) end');
  L.push('  end');
  L.push('  return table.concat(r)');
  L.push('end');
  L.push(`local function ${n.xordec}(d,k)`);
  L.push('  local r,st={},k%2147483646+1');
  L.push('  for i=1,#d do');
  L.push('    st=(st*16807)%2147483647');
  L.push('    local a,b=d:byte(i),st%256');
  L.push('    local x,p=0,1');
  L.push('    while a>0 or b>0 do');
  L.push('      local aa,bb=a%2,b%2');
  L.push('      if aa~=bb then x=x+p end');
  L.push('      a=(a-aa)/2 b=(b-bb)/2 p=p*2');
  L.push('    end');
  L.push('    r[i]=string.char(x)');
  L.push('  end');
  L.push('  return table.concat(r)');
  L.push('end');
  L.push(`local ${n.src}=${n.xordec}(${n.b64dec}(${n.joined}),${key})`);
  L.push(`local ${n.loader}=loadstring or load`);
  L.push(`local ${n.fn}=${n.loader}(${n.src},'@obf.lua')`);
  L.push(`return ${n.fn}()`);
  return L.join('\n') + '\n';
}
