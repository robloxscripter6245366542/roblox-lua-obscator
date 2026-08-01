#!/usr/bin/env python3
# ============================================================
#  unpack_runnable.py  --  emit a RUNNABLE, unpacked Luraph script
#
#  Two very different "deobfuscation" goals:
#    * readable clean source (devirt/lift.py) -> analysis only, NOT runnable
#    * unpacked-but-runnable (this tool)      -> RUNS identically
#
#  This strips the outer shell that Luraph v14.7 wraps around its VM --
#  the base-85 encoding, the LZMA compression, and the anti-tamper decode
#  bootstrap -- and re-emits a self-contained script that:
#
#    * exposes the VM interpreter as PLAIN READABLE Lua source (was a
#      compressed blob) -- you can read/patch it,
#    * embeds the bytecode as base64 (decoded by a tiny inline decoder),
#    * invokes the VM exactly as the original bootstrap did, so behaviour
#      is identical.
#
#  The program logic stays VM bytecode (fully removing the VM = the
#  bytecode->source recompiler problem, which is not runnable). What you
#  gain: no packing, no anti-tamper, the interpreter in the clear, and a
#  script you can still run in an executor.
#
#  Targets the sigil-family bootstrap: base-85 -> LZMA -> loadstring(vm)
#  -> N(buffer) -> (...)  (sigil / mycode / axonic).
#
#  Usage:
#     python3 unpack_runnable.py <sample.lua> -o unpacked_runnable.lua
# ============================================================

import argparse
import base64
import lzma
import re
import sys

A85_DROP = 5


def find_long_brackets(src):
    out = []
    for m in re.finditer(r"\[(=*)\[", src):
        lvl = m.group(1)
        close = "]" + lvl + "]"
        end = src.find(close, m.end())
        if end == -1:
            continue
        out.append((len(lvl), src[m.end():end]))
    return out


def a85_decode(body, drop=A85_DROP):
    s = body[drop - 1:]
    s = s.replace("z", "!!!!!")
    out = bytearray()
    n = len(s) - (len(s) % 5)
    for i in range(0, n, 5):
        val = 0
        for ch in s[i:i + 5]:
            val = val * 85 + (ord(ch) - 33)
        out += (val & 0xFFFFFFFF).to_bytes(4, "little")
    return bytes(out)


def lzma_raw(data):
    for bits in range(16, 28):
        try:
            d = lzma.LZMADecompressor(format=lzma.FORMAT_RAW, filters=[
                {"id": lzma.FILTER_LZMA1, "lc": 3, "lp": 0, "pb": 0,
                 "dict_size": 1 << bits}])
            return d.decompress(data)
        except lzma.LZMAError:
            continue
    return None


def safe_bracket(text):
    """Pick a long-bracket level whose close sequence isn't in text."""
    lvl = 0
    while ("]" + "=" * lvl + "]") in text:
        lvl += 1
    eq = "=" * lvl
    return f"[{eq}[", f"]{eq}]"


RUNNER_B64 = r'''
local function __b64(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local t={} for i=1,#b do t[b:sub(i,i)]=i-1 end
  data=data:gsub('[^%w+/]','')
  local out={}
  for i=1,#data,4 do
    local c1=t[data:sub(i,i)] or 0 local c2=t[data:sub(i+1,i+1)] or 0
    local c3=t[data:sub(i+2,i+2)] local c4=t[data:sub(i+3,i+3)]
    local n=c1*262144+c2*4096+(c3 or 0)*64+(c4 or 0)
    out[#out+1]=string.char(math.floor(n/65536)%256)
    if c3~=nil then out[#out+1]=string.char(math.floor(n/256)%256) end
    if c4~=nil then out[#out+1]=string.char(n%256) end
  end
  return table.concat(out)
end
'''


def main():
    ap = argparse.ArgumentParser(description="emit a runnable unpacked Luraph script")
    ap.add_argument("input")
    ap.add_argument("-o", "--out", default="unpacked_runnable.lua")
    args = ap.parse_args()

    src = open(args.input, "r", encoding="utf-8", errors="replace").read()
    streams = [(lvl, body) for (lvl, body) in find_long_brackets(src)
               if body[:3] == "LPH"]
    if len(streams) < 2:
        sys.exit("!! expected 2 LPH streams (VM source + bytecode); this build "
                 "may differ. Found %d." % len(streams))

    decoded = []
    for lvl, body in streams:
        raw = a85_decode(body)
        dec = lzma_raw(raw)
        if dec is None:
            sys.exit("!! a stream did not decompress as LZMA1 -- not the "
                     "sigil-family v14.7 packing this tool targets.")
        decoded.append(dec)

    # identify which is VM source (printable Lua) vs bytecode
    def printable(b):
        s = b[:2000]
        return sum(1 for c in s if c in (9, 10, 13) or 32 <= c <= 126) / max(len(s), 1)
    vm_src, bytecode = None, None
    for d in decoded:
        if printable(d) > 0.95:
            vm_src = d.decode("latin1")
        else:
            bytecode = d
    if vm_src is None or bytecode is None:
        sys.exit("!! couldn't tell VM source from bytecode among the streams.")

    ob, cb = safe_bracket(vm_src)
    bc_b64 = base64.b64encode(bytecode).decode()

    out = []
    out.append("-- Unpacked by luraph-deobf/unpack_runnable.py")
    out.append("-- Runnable + behaviour-identical. Removed: base-85 encoding,")
    out.append("-- LZMA compression, and the anti-tamper decode bootstrap.")
    out.append("-- The VM interpreter below is now PLAIN SOURCE (was a packed blob);")
    out.append("-- the program logic remains VM bytecode (see luraph-deobf/devirt for lifting).")
    out.append(RUNNER_B64)
    out.append(f"local __VM = {ob}\n{vm_src}\n{cb}")
    out.append(f'local __BC = "{bc_b64}"')
    out.append('-- invoke exactly as the original bootstrap did: '
               'loadstring(vm)(buffer.fromstring(bytecode))(...)')
    out.append('return loadstring(__VM, "Luraph  ")'
               '(buffer.fromstring(__b64(__BC)))(...)')
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    print(f"[unpack_runnable] wrote {args.out}")
    print(f"  VM interpreter source: {len(vm_src):,} bytes (readable)")
    print(f"  bytecode: {len(bytecode):,} bytes (base64-embedded)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
