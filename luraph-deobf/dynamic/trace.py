#!/usr/bin/env python3
# ============================================================
#  trace.py  --  Luraph bytecode deserialisation tracer
#
#  Step 1 of devirtualisation: recover the bytecode SERIALISATION
#  GRAMMAR. The v14.7 VM deserialises its bytecode from a Luau `buffer`
#  via buffer.readu8/readu16/readu32/readstring. Because the program
#  reads `buffer` from ITS environment, we hand it wrappers that log
#  every read (offset, width, value). The resulting trace is the raw
#  grammar: the constant table, the proto/instruction stream, and how
#  numbers/strings are encoded -- everything a disassembler needs.
#
#  What the trace shows on the v14.7 sample:
#    * a small fixed header (first ~3 bytes)
#    * a tagged constant table: strings via readstring; f64 constants
#      stored as 8-byte readstring reads; small ints inline; recurring
#      tag bytes (0x12/0x11/0x14); string.pack format specifiers
#      (">i8", "<i8") used to decode wider numbers
#    * then the per-proto instruction stream
#
#  Deserialisation completes before the program's UI loop, so we stop at
#  the first task.wait() (raised as __stop__) and keep the whole trace.
#
#  Usage:
#     python3 trace.py <sample.lua> --luau ./luau [--cap 4000] [--timeout 40]
#     # -> writes trace.txt ; analyse with your own tooling
# ============================================================

import argparse
import subprocess
import sys

STUBS = r'''
local realLoadstring = loadstring
local realG = getfenv(1)
local env = {}
local instMT
local function inst() return setmetatable({}, instMT) end
instMT = {__index=function() return inst() end, __newindex=function() end,
  __call=function() return inst() end, __concat=function() return "" end,
  __tostring=function() return "" end, __add=function() return inst() end,
  __sub=function() return inst() end, __mul=function() return inst() end,
  __div=function() return inst() end, __unm=function() return inst() end,
  __len=function() return 0 end, __eq=function() return false end,
  __lt=function() return false end, __le=function() return false end}
local recorder; recorder = setmetatable({}, {__index=function() return recorder end,
  __newindex=function() end, __call=function() return recorder end,
  __concat=function() return "" end, __tostring=function() return "" end})
env.__rec = recorder
env.loadstring = function(s, cn) local f,e = realLoadstring(s, cn); if f then pcall(setfenv, f, env) end; return f, e end
env.load = env.loadstring
env.game = setmetatable({HttpGet=function() return "return __rec" end,
  HttpGetAsync=function() return "return __rec" end, GetService=function() return inst() end,
  GetObjects=function() return {} end}, {__index=function() return function() return inst() end end,
  __newindex=function() end})
env.workspace = inst() ; env.getgenv = function() return env end
env.identifyexecutor = function() return "h","1" end ; env.getexecutorname = env.identifyexecutor
env.tick = function() return 0 end ; env.time = env.tick
env.task = {wait=function() error("__stop__") end, spawn=function() end, defer=function() end, delay=function() end}
env.wait = function() error("__stop__") end
env.unpack = table.unpack ; env.shared = {} ; env._G = env
for _, n in ipairs({"Instance","Vector3","Vector2","Color3","UDim","UDim2","CFrame","Rect",
  "Region3","Ray","TweenInfo","NumberSequence","ColorSequence","NumberRange","BrickColor",
  "Random","Font","Drawing","DateTime","Enum","OverlapParams","RaycastParams","Path2D",
  "Path2DControlPoint"}) do env[n] = inst() end
local N, CAP = 0, __CAP__
do local rb = realG.buffer ; local p = {} ; for k,v in pairs(rb) do p[k]=v end
  local function wrap(name, f) return function(...)
    local r = f(...) ; if N < CAP then N = N + 1 ; local a = {...}
      print("[[T]] "..name.." off="..tostring(a[2]).." -> "..tostring(r)) end
    return r end end
  p.readu8 = wrap("u8", rb.readu8) ; p.readu16 = wrap("u16", rb.readu16)
  p.readu32 = wrap("u32", rb.readu32)
  if rb.readi32 then p.readi32 = wrap("i32", rb.readi32) end
  if rb.readf64 then p.readf64 = wrap("f64", rb.readf64) end
  if rb.readf32 then p.readf32 = wrap("f32", rb.readf32) end
  p.readstring = function(b, off, len) local r = rb.readstring(b, off, len)
    if N < CAP then N = N + 1
      print("[[T]] str off="..tostring(off).." len="..tostring(len).." -> "..string.format("%q", r):sub(1,80)) end
    return r end
  env.buffer = p end
setmetatable(env, {__index = function(_, k) return realG[k] end})
env.print = print
local SRC = [====[
'''

RUN = r'''
]====]
local f = env.loadstring(SRC, "@s") ; if f then pcall(f) end
print("[[T]] END")
'''


def main():
    ap = argparse.ArgumentParser(description="Luraph bytecode deserialisation tracer")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="./luau")
    ap.add_argument("--cap", type=int, default=4000, help="max buffer reads to log")
    ap.add_argument("--timeout", type=int, default=40)
    ap.add_argument("--out", default="trace.txt")
    args = ap.parse_args()

    with open(args.sample, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    assert ']====]' not in src, "sample uses a level-4 long bracket; bump the level"
    harness = STUBS.replace("__CAP__", str(args.cap)) + src + RUN
    with open("trace_harness.luau", "w", encoding="utf-8") as f:
        f.write(harness)

    with open(args.out, "w", encoding="utf-8") as outf:
        try:
            subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL",
                            args.luau, "trace_harness.luau"], stdout=outf,
                           stderr=subprocess.STDOUT, check=False)
        except FileNotFoundError:
            print("!! luau not found; build it: bash build_luau.sh")
            return 1
    n = sum(1 for l in open(args.out, errors="replace") if l.startswith("[[T]]"))
    print(f"[trace] wrote {args.out}: {n} buffer reads logged")
    return 0


if __name__ == "__main__":
    sys.exit(main())
