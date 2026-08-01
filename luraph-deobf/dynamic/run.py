#!/usr/bin/env python3
# ============================================================
#  run.py  --  Luraph dynamic-analysis harness (real Luau)
#
#  Runs a Luraph-protected sample under a REAL Luau runtime inside a
#  fully stubbed, network-blocked environment, and logs everything the
#  program does: HttpGet/request URLs, config assignments, method calls,
#  and (optionally) the string constants the VM materialises.
#
#  Why this works: the sample's bootstrap self-unpacks (base-85 -> LZMA)
#  and runs its VM in-process. We don't need to understand the VM -- we
#  own the environment it runs in (weakness W2), so every external effect
#  is observable. We keep `loadstring` REAL (so the VM compiles) but run
#  every compiled chunk under our env so the program's globals resolve to
#  our stubs.
#
#  IMPORTANT -- satisfying the anti-tamper (weakness W5):
#  the bootstrap probes the environment with loadstring("\x1bLuaP") and
#  compares the SECOND return value (the error message). A stub that drops
#  it flips the internal offset D=5->20 and the LZMA decode dies with
#  "table overflow" in function C. Our loadstring stub preserves
#  (nil, errmsg) exactly, so the probe passes and the sample unpacks.
#
#  Requires a `luau` binary (see build_luau.sh).
#
#  Usage:
#     python3 run.py <sample.lua> [--luau ./luau] [--timeout 60] [--strings]
# ============================================================

import argparse
import subprocess
import sys

STUBS = r'''
local realLoadstring = loadstring
local env = {}
local function serialize(v, d)
    d = d or 0
    local t = type(v)
    if t == "string" then return string.format("%q", v) end
    if t ~= "table" or d > 3 then return tostring(v) end
    local p = {}
    for k, val in pairs(v) do p[#p+1] = tostring(k).."="..serialize(val, d+1) end
    return "{"..table.concat(p, ", ").."}"
end
local function log(tag, ...)
    local o = {}
    for i = 1, select("#", ...) do o[i] = serialize((select(i, ...))) end
    print("[[LOG]] "..tag.."\t"..table.concat(o, "\t"))
end

-- recorder: absorbs any field read/write/call and logs it (captures config)
local recorder
recorder = setmetatable({}, {
    __index=function() return recorder end,
    __newindex=function(_, k, v) log("SET", k, v) end,
    __call=function(_, ...) log("CALL", ...); return recorder end,
    __concat=function() return "" end, __tostring=function() return "" end,
})
env.__rec = recorder

-- loadstring: REAL (so the VM compiles), run under env, and CRUCIALLY
-- preserve the 2nd return value so the W5 integrity probe passes.
env.loadstring = function(s, cn)
    local f, e = realLoadstring(s, cn)
    if f then pcall(setfenv, f, env) end
    return f, e
end
env.load = env.loadstring

-- universal stub: survives index/call/arith so execution proceeds
local instMT
local function inst() return setmetatable({}, instMT) end
instMT = {
    __index=function() return function() return inst() end end,
    __newindex=function() end, __call=function() return inst() end,
    __concat=function() return "" end, __tostring=function() return "" end,
    __add=function() return inst() end, __sub=function() return inst() end,
    __mul=function() return inst() end, __div=function() return inst() end,
    __mod=function() return inst() end, __pow=function() return inst() end,
    __unm=function() return inst() end, __len=function() return 0 end,
    __eq=function() return false end, __lt=function() return false end,
    __le=function() return false end,
}

local svc = {}
env.game = setmetatable({
    HttpGet=function(_, u) log("HttpGet", u); return "return __rec" end,
    HttpGetAsync=function(_, u) log("HttpGetAsync", u); return "return __rec" end,
    GetService=function(_, n) log("GetService", n); svc[n]=svc[n] or inst(); return svc[n] end,
    GetObjects=function() return {} end,
}, {__index=function() return function() return inst() end end, __newindex=function() end})
env.workspace = inst()
env.getgenv = function() return env end
env.getrawmetatable = function(o) return getmetatable(o) end
env.setrawmetatable = function() end
env.setreadonly = function() end
env.isreadonly = function() return false end
env.hookfunction = function(a) return a end
env.hookmetamethod = function() return function() end end
env.newcclosure = function(f) return f end
env.checkcaller = function() return true end
env.getnamecallmethod = function() return "" end
env.setclipboard = function() end
env.identifyexecutor = function() return "harness", "1.0" end
env.getexecutorname = env.identifyexecutor
env.request = function(o) log("request", o); return {StatusCode=200, Body="", Headers={}} end
env.http_request = env.request
env.syn = {request=env.request, protect_gui=function() end}
env.http = {request=env.request}
env.readfile = function() return "" end
env.writefile = function(p) log("writefile", p) end
env.appendfile = function() end
env.makefolder = function() end
env.isfile = function() return false end
env.isfolder = function() return false end
env.listfiles = function() return {} end
local waitCount = 0
local function budgetWait()
    waitCount = waitCount + 1
    if waitCount == 1 then log("first-wait-reached") end
    if waitCount > __WAITBUDGET__ then error("__waitbudget__: exited loop after "..waitCount.." waits") end
    return 0
end
env.task = {wait=budgetWait, spawn=function(f) if type(f)=="function" then pcall(f) end end,
            defer=function(f) if type(f)=="function" then pcall(f) end end,
            delay=function() end, cancel=function() end}
env.wait = budgetWait
local clk = 0
local function nowfn() clk = clk + 0.5; return clk end  -- advancing clock
env.tick = nowfn ; env.time = nowfn
env.os = {time=nowfn, clock=nowfn, date=function() return "" end,
          difftime=function(a,b) return (a or 0)-(b or 0) end}
env.warn = function(...) log("warn", ...) end
env.unpack = table.unpack
env.shared = {}
env._G = env
for _, n in ipairs({"Instance","Vector3","Vector2","Color3","UDim","UDim2",
    "CFrame","Rect","Region3","Ray","TweenInfo","NumberSequence","ColorSequence",
    "NumberRange","BrickColor","PhysicalProperties","Random","Font","Drawing",
    "DateTime","Enum","OverlapParams","RaycastParams"}) do env[n] = inst() end
local realG = getfenv(1)
setmetatable(env, {__index = function(_, k)
    local r = realG[k]; if r ~= nil then return r end; return inst()
end})
env.print = print
__STRINGS__
log("harness-ready")

local SRC = [====[
'''

STRINGS_BLOCK = r'''
do  -- string proxy: dump decoded constants the VM builds via string.*
    local rs = realG.string ; local seen = {}
    local function maybe(s)
        if type(s)=="string" and #s>=4 and #s<=400 and not seen[s] and s:find("%a%a%a%a") then
            seen[s]=true; print("[[STR]] "..string.format("%q", s))
        end
        return s
    end
    local proxy = {} ; for k,v in pairs(rs) do proxy[k]=v end
    proxy.char=function(...) return maybe(rs.char(...)) end
    proxy.sub =function(...) return maybe(rs.sub(...)) end
    proxy.format=function(...) return maybe(rs.format(...)) end
    env.string = proxy
end
'''

RUNNER = r'''
]====]
local chunk, err = env.loadstring(SRC, "@sample")
if not chunk then print("[[LOG]] COMPILE-ERR\t"..tostring(err)); return end
local ok, e = xpcall(chunk, function(x) return tostring(x).."\n"..debug.traceback("",2) end)
if not ok then print("[[LOG]] RUNTIME\t"..tostring(e)) end
print("[[LOG]] done")
'''


def build(sample_src, want_strings, wait_budget):
    stubs = (STUBS
             .replace("__STRINGS__", STRINGS_BLOCK if want_strings else "")
             .replace("__WAITBUDGET__", str(wait_budget)))
    assert ']====]' not in sample_src, "sample uses a level-4 long bracket; bump the level"
    return stubs + sample_src + RUNNER


def main():
    ap = argparse.ArgumentParser(description="Luraph dynamic harness (Luau)")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="./luau", help="path to luau binary")
    ap.add_argument("--timeout", type=int, default=60)
    ap.add_argument("--strings", action="store_true",
                    help="also dump decoded string constants (slower)")
    ap.add_argument("--wait-budget", type=int, default=3000)
    ap.add_argument("--out", default="harness.luau", help="generated harness path")
    args = ap.parse_args()

    with open(args.sample, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    harness = build(src, args.strings, args.wait_budget)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(harness)
    print(f"[run] wrote {args.out} ({len(harness)} bytes); executing under {args.luau} "
          f"(timeout {args.timeout}s)\n")

    try:
        subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL", "-eL",
                        args.luau, args.out], check=False)
    except FileNotFoundError:
        print("!! luau binary not found. Build it first: bash build_luau.sh")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
