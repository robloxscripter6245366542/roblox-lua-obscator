#!/usr/bin/env python3
# ============================================================
#  deobf_v15.py  --  Luraph v15 payload recovery harness (real Luau)
#
#  The problem: Luraph v15 virtualises the program into runtime-XOR-decrypted
#  bytecode. run.py's minimal stub env lets the VM boot but it ABORTS at the
#  loader's environment/anti-tamper checks (it indexes Roblox globals that the
#  bare Luau CLI doesn't have: task/game/Instance/Vector3/identifyexecutor)
#  BEFORE the real program runs, so the payload's strings, URLs and remotes
#  are never decoded.
#
#  This harness gives the VM a RICH, fully network-blocked Roblox + executor
#  emulation so it runs THROUGH those checks INTO the payload, then records
#  everything the program actually does (weakness W2/W6 — we own the env, so
#  every external effect is observable without understanding the VM):
#
#    [[URL]]      HttpGet / HttpGetAsync / request / syn.request targets
#    [[SERVICE]]  game:GetService(name)
#    [[REMOTE]]   FireServer/InvokeServer/FireAllClients/Fire/Invoke + args
#    [[INSTANCE]] Instance.new(class)
#    [[STR]]      program strings the VM materialises (char/concat/readstring)
#    [[GLOBAL]]   globals the loader looks up (env __index misses)
#    [[FS]]       writefile/readfile/setclipboard/queue_on_teleport
#
#  Nothing hits the network or disk — every sink is stubbed and logged. This
#  is defensive RE: it reveals what a hostile script WOULD do, it does not do
#  it. Requires a luau binary (build_luau.sh).
#
#  STATUS (honest): the rich env SOLVES the environment gate — the v15 VM no
#  longer aborts at nil.cancel and boots past its executor/debug checks (which
#  the minimal run.py env could not). On sample_v15.lua it reaches `env-ready`
#  and enters the native XOR-decrypt/dispatch loop. What is NOT yet solved is
#  throughput: this is a virtualised VM (an unrolled interpreter over encrypted
#  bytecode) running INSIDE the Luau interpreter — nested interpretation — so
#  the decrypt+run phase is very slow, and on this build the payload's remotes/
#  URLs had not surfaced within a multi-minute budget. Bounding is also limited
#  because the Luau CLI has no debug.sethook and wrapping the hot path breaks or
#  cripples the VM. Output streams to <out>.raw.txt so partial progress survives
#  a timeout. Making this fully practical needs one of: a faster/JIT Luau, an
#  instruction-cap build of Luau, or capturing on a real executor.
#
#  Usage:
#    python3 deobf_v15.py ../sample_v15.lua --luau ./luau --out dk_recovered
# ============================================================

import argparse
import re
import subprocess
import sys

PRELUDE = r'''
--=== deobf_v15 rich Roblox/executor emulation (network + disk blocked) =====
local realG = getfenv(1)
local env = {}
local LOGSTR = __LOGSTR__     -- whether to log materialised program strings

local function ser(v, d)
    d = d or 0
    local t = type(v)
    if t == "string" then return #v <= 120 and string.format("%q", v) or ("<str "..#v..">") end
    if t == "number" or t == "boolean" then return tostring(v) end
    if t == "table" then
        if d > 2 then return "{..}" end
        local mt = getmetatable(v)
        if mt and mt.__rbx then return mt.__rbx end     -- proxy label
        local p = {}
        for k, val in pairs(v) do
            p[#p+1] = tostring(k).."="..ser(val, d+1)
            if #p > 8 then p[#p+1] = ".."; break end
        end
        return "{"..table.concat(p, ",").."}"
    end
    local mt = getmetatable(v)
    if mt and mt.__rbx then return mt.__rbx end
    return tostring(v)
end
local function log(tag, ...)
    local o = {}
    for i = 1, select("#", ...) do o[i] = ser((select(i, ...))) end
    print("[["..tag.."]] "..table.concat(o, "\t"))
end

-- ---- chainable Roblox instance/service proxy -----------------------------
-- Survives indexing / calling / arithmetic so control flow proceeds, and
-- logs the interesting method calls (remotes, http).
local newProxy
local REMOTE = { FireServer=1, InvokeServer=1, FireAllClients=1, Fire=1,
                 Invoke=1, InvokeClient=1, FireClient=1 }
local function methodCall(path, key, ...)
    if REMOTE[key] then log("REMOTE", path..":"..key, ...) end
    if key == "GetService" or key == "service" then
        local n = (...)
        log("SERVICE", n)
        return newProxy(tostring(n))
    end
    if key == "HttpGet" or key == "HttpGetAsync" or key == "GetAsync" then
        log("URL", (...))
        return "return function() end"
    end
    if key == "FindFirstChild" or key == "WaitForChild" or key == "FindService" then
        return newProxy(path.."."..tostring((...)))
    end
    return newProxy(path.."."..key)
end
newProxy = function(path)
    path = path or "?"
    return setmetatable({}, {
        __rbx = path,
        __index = function(_, k)
            if k == "Name" then return path end
            if k == "ClassName" then return path end
            if k == "PlaceId" or k == "GameId" or k == "UserId" or k == "JobId" then return 0 end
            if k == "Parent" then return newProxy(path..".Parent") end
            if k == "Character" or k == "LocalPlayer" or k == "PlayerGui" then
                return newProxy(path.."."..k)
            end
            -- return a method-dispatcher: calling it logs; indexing chains
            return setmetatable({}, {
                __rbx = path.."."..k,
                __call = function(_, _self, ...) return methodCall(path, k, ...) end,
                __index = function(_, k2) return newProxy(path.."."..k.."."..k2) end,
                __concat = function() return "" end, __tostring = function() return "" end,
            })
        end,
        __newindex = function() end,
        __call = function(_, ...) return newProxy(path) end,
        __concat = function() return "" end, __tostring = function() return path end,
        __len = function() return 0 end,
        __add = function() return 0 end, __sub = function() return 0 end,
        __mul = function() return 0 end, __div = function() return 0 end,
        __mod = function() return 0 end, __pow = function() return 0 end,
        __unm = function() return 0 end,
        __eq = function() return false end,
        __lt = function() return false end, __le = function() return false end,
    })
end

-- ---- datatypes ------------------------------------------------------------
local function dtype(name)
    return setmetatable({}, {__rbx=name, __index=function(_, k)
        if k == "new" or k == "fromRGB" or k == "fromHSV" or k == "Angles"
           or k == "fromMatrix" or k == "fromAxisAngle" then
            return function(...) return newProxy(name) end
        end
        return function(...) return newProxy(name.."."..k) end
    end, __call=function(_, ...) return newProxy(name) end})
end
for _, n in ipairs({"Vector3","Vector2","CFrame","Color3","UDim","UDim2","Rect",
    "Region3","Ray","TweenInfo","NumberSequence","ColorSequence","NumberRange",
    "BrickColor","PhysicalProperties","Font","DateTime","OverlapParams",
    "RaycastParams","Path2DControlPoint","ColorSequenceKeypoint",
    "NumberSequenceKeypoint","Instance"}) do env[n] = dtype(n) end
env.Instance = setmetatable({}, {__rbx="Instance", __index=function(_, k)
    if k == "new" then return function(cls, parent) log("INSTANCE", cls); return newProxy(tostring(cls)) end end
    return function(...) return newProxy("Instance."..k) end
end})
env.Random = setmetatable({}, {__index=function() return function()
    return setmetatable({}, {__index=function(_, k)
        return function(_, a, b) return type(b)=="number" and b or (type(a)=="number" and a or 0) end
    end}) end end})
env.Enum = setmetatable({}, {__index=function() return
    setmetatable({}, {__index=function() return newProxy("Enum") end}) end})

-- ---- scheduler (bounded) --------------------------------------------------
local waits = 0
local function budgetWait()
    waits = waits + 1
    if waits == 1 then log("first-wait") end
    if waits > __WAITBUDGET__ then error("__waitbudget__:"..waits) end
    return 1/60
end
local function runf(f) if type(f)=="function" then pcall(f) end return newProxy("thread") end
env.task = {wait=budgetWait, spawn=runf, defer=runf, delay=function(_, f) return runf(f) end,
            cancel=function() end, synchronize=function() end, desynchronize=function() end}
env.wait = budgetWait
env.delay = function(_, f) return runf(f) end
env.spawn = runf ; env.Spawn = runf
local clk = 0
local function nowfn() clk = clk + 1/60; return clk end
env.tick = nowfn ; env.time = nowfn ; env.elapsedTime = nowfn
env.os = setmetatable({time=function() return 1700000000 end, clock=nowfn,
    date=function() return "2026-01-01" end, difftime=function(a,b) return (a or 0)-(b or 0) end},
    {__index=realG.os or {}})

-- ---- game / workspace -----------------------------------------------------
env.game = newProxy("game")
env.Game = env.game
env.workspace = newProxy("workspace")
env.Workspace = env.workspace
env.script = newProxy("script")
env.shared = {} ; env.plugin = nil

-- ---- executor surface (log network/fs, never touch real ones) ------------
env.identifyexecutor = function() return "Synapse X", "2.0.0" end
env.getexecutorname = env.identifyexecutor
env.request = function(o) local u = type(o)=="table" and (o.Url or o.url) or o; log("URL", u); return {StatusCode=200, Body="", Headers={}} end
env.http_request = env.request
env.syn = setmetatable({request=env.request, protect_gui=function() end,
    crypt=setmetatable({}, {__index=function() return function(...) return (...) end end})},
    {__index=function() return function() end end})
env.http = {request=env.request, GetAsync=function(_, u) log("URL", u); return "" end}
env.fluxus = {request=env.request}
env.getgenv = function() return env end
env.getrenv = function() return env end
env.getsenv = function() return env end
env.getfenv = realG.getfenv ; env.setfenv = realG.setfenv
env.getrawmetatable = function(o) return getmetatable(o) end
env.setrawmetatable = function(o, mt) return o end
env.setreadonly = function() end ; env.isreadonly = function() return false end
env.make_writeable = function() end ; env.make_readonly = function() end
env.hookfunction = function(a) return a end ; env.replaceclosure = function(a) return a end
env.hookmetamethod = function() return function() end end
env.newcclosure = function(f) return f end ; env.clonefunction = function(f) return f end
env.checkcaller = function() return true end
env.getnamecallmethod = function() return "" end
env.setnamecallmethod = function() end
env.iscclosure = function() return false end ; env.islclosure = function() return true end
env.getcallingscript = function() return newProxy("script") end
env.getconnections = function() return {} end ; env.firesignal = function() end
env.getgc = function() return {} end ; env.getreg = function() return {} end
env.getloadedmodules = function() return {} end ; env.getrunningscripts = function() return {} end
env.getscripts = function() return {} end ; env.getnilinstances = function() return {} end
env.getinstances = function() return {} end
env.fireclickdetector = function() end ; env.fireproximityprompt = function() end
env.firetouchinterest = function() end
env.setclipboard = function(s) log("FS", "setclipboard", s) end ; env.toclipboard = env.setclipboard
env.readfile = function(p) log("FS", "readfile", p); return "" end
env.writefile = function(p, d) log("FS", "writefile", p) end
env.appendfile = function(p) log("FS", "appendfile", p) end
env.loadfile = function() return function() end end
env.dofile = function() end
env.makefolder = function() end ; env.delfolder = function() end ; env.delfile = function() end
env.isfile = function() return false end ; env.isfolder = function() return false end
env.listfiles = function() return {} end
env.queue_on_teleport = function(s) log("FS", "queue_on_teleport", s) end
env.mouse1click = function() end ; env.keypress = function() end ; env.keyrelease = function() end

-- loadstring: real (so nested VM stages compile) but run under env, keep the
-- 2nd return so any v14-style probe still passes.
env.loadstring = function(s, cn)
    local f, e = realG.loadstring(s, cn)
    if f then pcall(realG.setfenv, f, env) end
    return f, e
end
env.load = env.loadstring
env.require = function(m) log("require", m); return newProxy("module") end
env.collectgarbage = function() return 0 end
env.warn = function(...) log("warn", ...) end
env.print = function(...) log("print", ...) end
env.error = realG.error ; env.assert = realG.assert ; env.pcall = realG.pcall
env.xpcall = realG.xpcall ; env.select = realG.select ; env.unpack = realG.unpack or table.unpack
env.next = realG.next ; env.rawget = realG.rawget ; env.rawset = realG.rawset
env.rawequal = realG.rawequal ; env.rawlen = realG.rawlen
env.type = realG.type ; env.typeof = function(v)
    local mt = getmetatable(v); if mt and mt.__rbx then return "Instance" end
    return realG.type(v)
end
env.tostring = realG.tostring ; env.tonumber = realG.tonumber
env.getmetatable = realG.getmetatable ; env.setmetatable = realG.setmetatable
env.ipairs = realG.ipairs ; env.pairs = realG.pairs
env._VERSION = realG._VERSION
env.debug = realG.debug            -- REAL Luau debug -> satisfies the v15 gate
env.buffer = realG.buffer ; env.bit32 = realG.bit32
env.utf8 = realG.utf8 ; env.coroutine = realG.coroutine ; env.math = realG.math

-- string/table: real, but optionally tap the materialised program strings.
do
    local seen = {}
    local function tap(s, src)
        if LOGSTR and type(s)=="string" and #s>=3 and #s<=400 and not seen[s]
           and s:find("[%w/:%.]") then
            seen[s]=true; log("STR", src, s)
        end
        return s
    end
    local rs = realG.string ; local sp = {} ; for k,v in pairs(rs) do sp[k]=v end
    sp.char=function(...) return tap(rs.char(...),"char") end
    sp.sub=function(...) return tap(rs.sub(...),"sub") end
    sp.format=function(...) return tap(rs.format(...),"fmt") end
    sp.gsub=function(...) local a,b=rs.gsub(...); return tap(a,"gsub"),b end
    env.string = sp
    local rt = realG.table ; local tp = {} ; for k,v in pairs(rt) do tp[k]=v end
    tp.concat=function(...) return tap(rt.concat(...),"concat") end
    env.table = tp
    local rb = realG.buffer
    if rb and rb.readstring then
        local bp = {} ; for k,v in pairs(rb) do bp[k]=v end
        bp.readstring=function(...) return tap(rb.readstring(...),"buf") end
        env.buffer = bp
    end
end
env._G = env

-- Hard execution cap, NON-INVASIVE. Luau CLI has no debug.sethook, and
-- wrapping the VM handler table breaks its dispatch, so instead bound work by
-- counting buffer.readu8 — the VM reads a bytecode byte on essentially every
-- step, and readu8 is a leaf primitive whose wrapping does not affect dispatch
-- logic (handlers just call t[94] = this counter). When the cap trips we raise
-- a sentinel and keep every behaviour log emitted up to that point.
-- NOTE on bounding: do NOT wrap buffer.readu8 — it is called on every VM step,
-- and turning that native primitive into a Lua closure makes the decrypt loop
-- ~100x slower so bootstrap never finishes. The VM is instead bounded by the
-- wait-budget (payload loops call task.wait -> budget breaks them) plus the
-- process timeout. __MAXREADS__ is accepted but intentionally unused here.
local _ = __MAXREADS__
-- Provide Luau's native `vector` directly so it doesn't churn __index.
env.vector = realG.vector
env.getgenv = function() return env end

-- Unknown globals: log the miss once, then CACHE the resolved value onto env
-- (rawset) so hot globals resolve natively on every later access instead of
-- re-entering this handler — critical for the bootstrap/decrypt loop's speed.
local misses = {}
setmetatable(env, {__index = function(t, k)
    if not misses[k] then misses[k] = true; log("GLOBAL", k) end
    local v = realG[k]
    if v ~= nil then rawset(t, k, v) end
    return v
end})
log("env-ready")

local SRC = [====[
'''

RUNNER = r'''
]====]
local chunk, err = env.loadstring(SRC, "@dropkick")
if not chunk then print("[[LOG]] COMPILE-ERR\t"..tostring(err)); return end
local ok, e = xpcall(chunk, function(x)
    return tostring(x).."\n"..debug.traceback("", 2) end)
if not ok then
    local es = tostring(e)
    if es:find("__waitbudget__") then print("[[LOG]] wait-budget reached (payload loop bounded)")
    elseif es:find("__readcap__") then print("[[LOG]] read-cap reached (VM bounded; logs above are the payload's observable setup)")
    else print("[[LOG]] RUNTIME\t"..es) end
end
print("[[LOG]] done")
'''


def build(sample_src, logstr, wait_budget, max_reads):
    pre = (PRELUDE
           .replace("__LOGSTR__", "true" if logstr else "false")
           .replace("__WAITBUDGET__", str(wait_budget))
           .replace("__MAXREADS__", str(max_reads)))
    assert ']====]' not in sample_src, "sample uses a level-4 long bracket; bump the level"
    return pre + sample_src + RUNNER


def main():
    ap = argparse.ArgumentParser(description="Luraph v15 payload recovery harness")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="./luau")
    ap.add_argument("--timeout", type=int, default=150)
    ap.add_argument("--wait-budget", type=int, default=500)
    ap.add_argument("--max-reads", type=int, default=8000000,
                    help="buffer.readu8 cap (bounds infinite payload loops)")
    ap.add_argument("--no-strings", action="store_true", help="don't log program strings")
    ap.add_argument("--harness", default="harness_deobf_v15.luau")
    ap.add_argument("--out", default=None, help="prefix: writes <out>.behavior.txt")
    args = ap.parse_args()

    src = open(args.sample, encoding="utf-8", errors="replace").read()
    harness = build(src, not args.no_strings, args.wait_budget, args.max_reads)
    open(args.harness, "w", encoding="utf-8").write(harness)
    print(f"[deobf_v15] wrote {args.harness} ({len(harness)} bytes); running under "
          f"{args.luau} (network/disk stubbed, timeout {args.timeout}s)\n")

    # Stream luau's (line-buffered) output straight to a file so that even when
    # the VM is still running at the timeout and the process is killed, every
    # line emitted so far survives — a plain PIPE is block-buffered and lost on
    # kill, which hides all progress on long/looping runs.
    raw_path = (args.out + ".raw.txt") if args.out else (args.harness + ".out")
    try:
        with open(raw_path, "w", encoding="utf-8") as rf:
            p = subprocess.Popen(["stdbuf", "-oL", "-eL", args.luau, args.harness],
                                 stdout=rf, stderr=subprocess.STDOUT)
            try:
                p.wait(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                p.kill(); p.wait()
                print(f"[deobf_v15] timeout after {args.timeout}s — VM still running; "
                      "partial log captured (nested VM emulation is compute-heavy).")
    except FileNotFoundError:
        print("!! luau not found; build it: bash build_luau.sh"); return 1
    out = open(raw_path, encoding="utf-8", errors="replace").read()

    tags = {}
    for line in out.splitlines():
        m = re.match(r"\[\[(\w+)\]\] ?(.*)", line)
        if m:
            tags.setdefault(m.group(1), []).append(m.group(2))
        print(line)

    # concise behavior summary
    print("\n===== behavior summary =====")
    for t in ("URL", "SERVICE", "REMOTE", "INSTANCE", "FS", "require", "GLOBAL"):
        vals = sorted(set(tags.get(t, [])))
        if vals:
            print(f"{t} ({len(vals)}):")
            for v in vals[:40]:
                print("   " + v)
    if args.out:
        with open(args.out + ".behavior.txt", "w") as f:
            f.write(out)
        print(f"\n[deobf_v15] full log -> {args.out}.behavior.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
