#!/usr/bin/env python3
# Headless runner: loads the mock Roblox env, then executes a target Lua script,
# firing UI callbacks once, and reports the exact error + line on failure.
import sys, os
from lupa import LuaRuntime

HERE = os.path.dirname(os.path.abspath(__file__))

def run(target):
    lua = LuaRuntime(unpack_returned_tuples=True)
    mock_src = open(os.path.join(HERE, "roblox_mock.lua")).read()
    ok, err = lua.eval("function(src) local f,e=load(src,'@mock'); if not f then return false,e end local o,e2=pcall(f); return o,e2 end")(mock_src)
    if not ok:
        return f"MOCK ERROR: {err}"

    script_src = open(target).read()
    runner = lua.eval("""
        function(src, name)
            local f, e = load(src, '@' .. name)
            if not f then return 'COMPILE: ' .. tostring(e) end
            local ok, err = xpcall(f, function(m) return tostring(m) .. '\\n' .. debug.traceback('', 2) end)
            if not ok then return 'RUNTIME: ' .. tostring(err) end
            return 'OK'
        end
    """)
    res = runner(script_src, os.path.basename(target))
    if res != "OK":
        return res
    # exercise callbacks
    cb = lua.eval("function() return __fireAllSignals() end")()
    if cb and cb.strip():
        return "CALLBACK ERRORS:\n" + cb
    return "OK"

if __name__ == "__main__":
    targets = sys.argv[1:] or []
    fail = 0
    for t in targets:
        res = run(t)
        status = "PASS" if res == "OK" else "FAIL"
        if res != "OK":
            fail += 1
        print(f"[{status}] {t}")
        if res != "OK":
            print("   " + res.replace("\n", "\n   "))
    sys.exit(1 if fail else 0)
