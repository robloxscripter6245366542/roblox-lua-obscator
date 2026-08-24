#!/usr/bin/env python3
# ============================================================
#  run_v15.py  --  Luraph v15 VM trace harness (real Luau)
#
#  The v15 analogue of devirt/run_vm.py. Where v14.7 shipped a separate VM
#  interpreter source + bytecode (so you booted the recovered source over the
#  bytecode), v15 is ONE `return setmetatable({...}, {}):XA()(...)` expression:
#    * the table's fields are ~140 threaded "continuation" handlers, each
#      returning (next_handler_id, regs...),
#    * library calls are cached in numeric table slots (buffer/bit32/string),
#    * the VM buffer is base-85(+substitution)-decoded then XOR-decrypted
#      byte-by-byte at runtime (bit32.bxor in the readu8 path).
#
#  So there is nothing to "boot separately" — you run the sample and instrument
#  the handler table in place. This harness (weakness W2: we own the env):
#    1. reuses run.py's stubbed, network-blocked Roblox/executor env,
#    2. wraps `setmetatable`: when the big handler table (>=40 function fields)
#       is set up, every VM handler field is wrapped with a tracer BEFORE the
#       driver fetches it into locals — cached std-lib primitives are left real
#       (identity-checked) so the hot path stays fast and uncounted,
#    3. captures the decrypted VM buffer by registering buffer.create/fromstring
#       objects and dumping the largest at the end,
#    4. bounds the run with a step budget so a non-terminating VM still yields
#       a trace.
#
#  Output (stdout markers, also parsed to files with --out):
#    [[VMH]] name=<handler> calls=<n>   -- per-handler histogram (.hist.txt)
#    [[VMSEQ]] <h>-><next_id> ...       -- handler-transition trace (.seq.txt);
#                                          the executed opcode stream — this is
#                                          the v15 analogue of devirt disasm.
#    [[VMBUF]] <base64>                 -- most-written buffer (.writebuf.bin);
#                                          VM SCRATCH/register space, NOT the
#                                          bytecode. v15 decrypts lazily per
#                                          read (bit32.bxor), so the plaintext
#                                          bytecode is never one buffer — the
#                                          trace confirms this empirically.
#
#  Usage:
#     python3 run_v15.py ../sample_v15.lua --luau ./luau \
#         --max-steps 500000 --seq 6000 --out v15_trace
# ============================================================

import argparse
import base64
import os
import subprocess
import sys

# Reuse the stubbed env from the v14.7 harness (same directory).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run import STUBS  # noqa: E402

# Instrumentation injected into `env` just before harness-ready. Wraps
# setmetatable + buffer; defines the trace accumulators as upvalues.
V15_INSTR = r'''
-- ---- v15 VM instrumentation ------------------------------------------------
local __steps, __seqn = 0, 0
local __counts, __seq = {}, {}
local __MAXSTEPS, __SEQMAX = __MAXSTEPS__, __SEQMAX__
local __SENTINEL = "__v15_stepbudget__"
local __rbuf = getfenv(1).buffer     -- real buffer lib, captured as an upvalue

-- tiny base64 encoder (Luau has none built in), as a local upvalue so the
-- dumper below can close over it regardless of its runtime environment.
local __b64enc
do
    local B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    __b64enc = function(data)
        local out, n = {}, #data
        local byte = string.byte
        for i = 1, n, 3 do
            local a, b, c = byte(data, i), byte(data, i+1), byte(data, i+2)
            b = b or 0; c = c or 0
            local t = a * 65536 + b * 256 + c
            local e1 = math.floor(t / 262144) % 64
            local e2 = math.floor(t / 4096) % 64
            local e3 = math.floor(t / 64) % 64
            local e4 = t % 64
            out[#out+1] = B:sub(e1+1, e1+1) .. B:sub(e2+1, e2+1) ..
                          ((i+1 <= n) and B:sub(e3+1, e3+1) or "=") ..
                          ((i+2 <= n) and B:sub(e4+1, e4+1) or "=")
        end
        return table.concat(out)
    end
end

-- Identity set of cached std-lib primitives, so we DON'T wrap (or count) the
-- hot buffer/bit32/string/table/math functions the VM stores in numeric slots.
local __prim = {}
do
    local realG = getfenv(1)
    for _, libname in ipairs({"buffer","bit32","string","table","math","os",
                              "coroutine","utf8"}) do
        local lib = realG[libname]
        if type(lib) == "table" then
            for _, fn in pairs(lib) do if type(fn)=="function" then __prim[fn]=true end end
        end
    end
    for _, fn in ipairs({rawget, rawset, rawequal, rawlen, getmetatable,
                         setmetatable, select, type, tonumber, tostring,
                         pcall, xpcall, next, pairs, ipairs, unpack,
                         table and table.unpack or nil}) do
        if type(fn)=="function" then __prim[fn]=true end
    end
end

local __realsetmeta = setmetatable
local __instrumented = false
env.setmetatable = function(t, mt)
    if not __instrumented and type(t)=="table" then
        local fcount = 0
        for k, v in pairs(t) do
            if type(v)=="function" and not __prim[v] then fcount = fcount + 1 end
        end
        if fcount >= 40 then          -- this is the VM handler table
            __instrumented = true
            for k, v in pairs(t) do
                if type(v)=="function" and not __prim[v] then
                    local name, fn = tostring(k), v
                    t[k] = function(...)
                        __steps = __steps + 1
                        __counts[name] = (__counts[name] or 0) + 1
                        if __steps > __MAXSTEPS then error(__SENTINEL) end
                        if __steps <= __SEQMAX then
                            local r = { fn(...) }
                            __seqn = __seqn + 1
                            __seq[__seqn] = name .. "->" .. tostring(r[1])
                            return table.unpack(r)
                        end
                        return fn(...)
                    end
                end
            end
            log("vm-instrumented", fcount)
        end
    end
    return __realsetmeta(t, mt)
end

-- Buffer capture. v15 decrypts the bytecode LAZILY (bit32.bxor in the readu8
-- path), so no single fully-decrypted buffer exists to dump. Instead we record
-- writeu8(dst, off, byte) — the point where each decrypted byte lands — and
-- reconstruct the most-written buffer at the end. That is the materialised
-- plaintext the VM produced while running.
local __writes = {}          -- buffer -> { [off]=byte }
local __wmax = {}            -- buffer -> highest offset seen
do
    local realG = getfenv(1)
    local rb = realG.buffer
    if rb then
        local bp = {}
        for k, v in pairs(rb) do bp[k] = v end
        local realwrite = rb.writeu8
        if realwrite then
            bp.writeu8 = function(b, off, val)
                local w = __writes[b]
                if not w then w = {}; __writes[b] = w end
                w[off] = val
                if (__wmax[b] or -1) < off then __wmax[b] = off end
                return realwrite(b, off, val)
            end
        end
        env.buffer = bp
    end
end

function env.__v15_dump()
    -- histogram
    local names = {}
    for n in pairs(__counts) do names[#names+1] = n end
    table.sort(names, function(a, b) return __counts[a] > __counts[b] end)
    for _, n in ipairs(names) do print("[[VMH]] name=" .. n .. " calls=" .. __counts[n]) end
    print("[[VMSTEPS]] total=" .. __steps .. " handlers=" .. #names)
    -- sequence (chunked to keep lines short)
    local line, per = {}, 24
    for i = 1, #__seq do
        line[#line+1] = __seq[i]
        if #line == per then print("[[VMSEQ]] " .. table.concat(line, " ")); line = {} end
    end
    if #line > 0 then print("[[VMSEQ]] " .. table.concat(line, " ")) end
    -- Reconstruct the most-written buffer from the writeu8 log = the
    -- materialised decrypted bytes.
    local best, bmax = nil, -1
    for b, mx in pairs(__wmax) do
        if mx > bmax then best, bmax = b, mx end
    end
    if best then
        local w = __writes[best]
        local out = {}
        for off = 0, bmax do out[#out+1] = string.char(w[off] or 0) end
        local s = table.concat(out)
        print("[[VMBUFLEN]] " .. #s)
        print("[[VMBUF]] " .. __b64enc(s))
    end
end
'''

RUNNER_V15 = r'''
]====]
local chunk, err = env.loadstring(SRC, "@sample")
if not chunk then print("[[LOG]] COMPILE-ERR\t"..tostring(err)); return end
local ok, e = xpcall(chunk, function(x) return tostring(x).."\n"..debug.traceback("",2) end)
if not ok then
    local es = tostring(e)
    if es:find("__v15_stepbudget__") then
        print("[[LOG]] step-budget reached (bounded trace)")
    else
        print("[[LOG]] RUNTIME\t"..es)
    end
end
if env.__v15_dump then env.__v15_dump() end
print("[[LOG]] done")
'''


def build(sample_src, wait_budget, max_steps, seq_max):
    stubs = (STUBS
             .replace("__STRINGS__", "")
             .replace("__WAITBUDGET__", str(wait_budget))
             .replace('log("harness-ready")',
                      V15_INSTR
                      .replace("__MAXSTEPS__", str(max_steps))
                      .replace("__SEQMAX__", str(seq_max))
                      + '\nlog("harness-ready")'))
    assert ']====]' not in sample_src, "sample uses a level-4 long bracket; bump the level"
    return stubs + sample_src + RUNNER_V15


def main():
    ap = argparse.ArgumentParser(description="Luraph v15 VM trace harness (Luau)")
    ap.add_argument("sample")
    ap.add_argument("--luau", default="./luau", help="path to luau binary")
    ap.add_argument("--timeout", type=int, default=120)
    ap.add_argument("--max-steps", type=int, default=500000,
                    help="handler-call budget before the trace is cut off")
    ap.add_argument("--seq", type=int, default=6000,
                    help="how many handler transitions to record in sequence")
    ap.add_argument("--wait-budget", type=int, default=3000)
    ap.add_argument("--harness", default="harness_v15.luau")
    ap.add_argument("--out", default=None,
                    help="prefix: writes <out>.hist.txt / .seq.txt / .writebuf.bin")
    args = ap.parse_args()

    with open(args.sample, "r", encoding="utf-8", errors="replace") as f:
        src = f.read()
    harness = build(src, args.wait_budget, args.max_steps, args.seq)
    with open(args.harness, "w", encoding="utf-8") as f:
        f.write(harness)
    print(f"[run_v15] wrote {args.harness} ({len(harness)} bytes); executing under "
          f"{args.luau} (timeout {args.timeout}s)\n")

    try:
        p = subprocess.run(["timeout", str(args.timeout), "stdbuf", "-oL", "-eL",
                            args.luau, args.harness],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except FileNotFoundError:
        print("!! luau binary not found. Build it first: bash build_luau.sh")
        return 1
    out = p.stdout.decode("utf-8", "replace")

    hist, seq, buf, buflen = [], [], None, None
    for line in out.splitlines():
        if line.startswith("[[VMBUF]] "):
            buf = line[len("[[VMBUF]] "):]
        elif line.startswith("[[VMBUFLEN]] "):
            buflen = line.split()[-1]
        elif line.startswith("[[VMH]] ") or line.startswith("[[VMSTEPS]] "):
            hist.append(line)
        elif line.startswith("[[VMSEQ]] "):
            seq.append(line[len("[[VMSEQ]] "):])
        else:
            print(line)

    print("\n".join(hist[:60]))
    if args.out:
        with open(args.out + ".hist.txt", "w") as f:
            f.write("\n".join(hist) + "\n")
        with open(args.out + ".seq.txt", "w") as f:
            f.write("\n".join(seq) + "\n")
        if buf:
            data = base64.b64decode(buf)
            with open(args.out + ".writebuf.bin", "wb") as f:
                f.write(data)
            print(f"\n[run_v15] most-written buffer (VM scratch/registers): "
                  f"{len(data)} bytes -> {args.out}.writebuf.bin")
        print(f"[run_v15] handler trace -> {args.out}.seq.txt "
              "(executed opcode stream), histogram -> " + args.out + ".hist.txt")
    elif buflen:
        print(f"\n[run_v15] most-written buffer captured: {buflen} bytes "
              "(VM scratch; pass --out to save it)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
