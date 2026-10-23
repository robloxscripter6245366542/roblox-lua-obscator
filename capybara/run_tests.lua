#!/usr/bin/env lua
-- capybara/run_tests.lua
-- Behavioral test suite: for each sample program, run the original and the
-- obfuscated build in sandboxes and assert they produce identical printed
-- output and return values. Exercises each layer independently and combined.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path

local Capybara = require("capybara")

-- Sample programs: each returns a value and/or prints; both are compared.
local SAMPLES = {
    ["arith"] = [[
        local a, b = 6, 7
        return a * b + 100 - 42
    ]],
    ["strings"] = [[
        local s = "hello" .. ", " .. "world"
        local t = { "a", "b", "c" }
        return s .. "/" .. table.concat(t, "-")
    ]],
    ["string-call-sugar"] = [[
        local buf = {}
        local function w(x) buf[#buf+1] = x end
        w "one"
        w("two")
        return table.concat(buf, ",")
    ]],
    ["control-flow"] = [[
        local sum = 0
        for i = 1, 10 do
            if i % 2 == 0 then sum = sum + i else sum = sum - 1 end
        end
        return sum
    ]],
    ["closures"] = [[
        local function counter()
            local n = 0
            return function() n = n + 1; return n end
        end
        local c = counter()
        return c() + c() + c()
    ]],
    ["tables-methods"] = [[
        local M = {}
        M.__index = M
        function M.new(v) return setmetatable({ v = v }, M) end
        function M:double() return self.v * 2 end
        local o = M.new(21)
        return o:double()
    ]],
    ["mixed-numbers"] = [[
        local hex = 0xFF
        local flt = 3.14
        local int = 255
        return (hex == int) and (flt > 3) and int or -1
    ]],
    ["escapes"] = [[
        return "tab\there\nnewline\65\66\67"
    ]],
    ["varargs"] = [[
        local function sum(...)
            local t = { ... }
            local s = 0
            for _, v in ipairs(t) do s = s + v end
            return s
        end
        return sum(1, 2, 3, 4, 5)
    ]],
    ["long-string"] = [[
        local s = [==[line1
line2 "quoted" and 'single']==]
        return #s
    ]],
}

-- Run a chunk in a fresh environment; capture print output and the return.
local function run(src, name)
    local out = {}
    local env = setmetatable({
        print = function(...)
            local parts = {}
            for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
            out[#out + 1] = table.concat(parts, "\t")
        end,
    }, { __index = _G })

    local loader = loadstring or load
    local chunk, err
    if _VERSION == "Lua 5.1" then
        chunk, err = loader(src, name)
        if chunk then setfenv(chunk, env) end
    else
        chunk, err = loader(src, name, "t", env)
    end
    if not chunk then return nil, "compile error: " .. tostring(err) end

    local ok, ret = pcall(chunk)
    if not ok then return nil, "runtime error: " .. tostring(ret) end
    return { output = table.concat(out, "\n"), value = ret }
end

local function eq(a, b)
    return a.output == b.output and tostring(a.value) == tostring(b.value)
end

local LAYER_SETS = {
    { name = "numbers", layers = { "numbers" } },
    { name = "strings", layers = { "strings" } },
    { name = "pack",    layers = { "pack" } },
    { name = "all",     layers = { "numbers", "strings", "pack" } },
}

local passed, failed = 0, 0
local names = {}
for k in pairs(SAMPLES) do names[#names + 1] = k end
table.sort(names)

for _, name in ipairs(names) do
    local src = SAMPLES[name]
    local base, baseErr = run(src, "@" .. name)
    if not base then
        print(string.format("SKIP  %-20s (baseline failed: %s)", name, baseErr))
    else
        for seed = 1, 3 do
            for _, set in ipairs(LAYER_SETS) do
                local ok, obf = pcall(Capybara.obfuscate, src,
                    { seed = seed, layers = set.layers, chunkname = name })
                local label = string.format("%s [%s seed=%d]", name, set.name, seed)
                if not ok then
                    failed = failed + 1
                    print(string.format("FAIL  %-34s obfuscate error: %s", label, tostring(obf)))
                else
                    local got, gotErr = run(obf, "@" .. name)
                    if not got then
                        failed = failed + 1
                        print(string.format("FAIL  %-34s %s", label, gotErr))
                    elseif not eq(base, got) then
                        failed = failed + 1
                        print(string.format("FAIL  %-34s output/return mismatch", label))
                        print("        want: " .. tostring(base.value) .. " | " .. base.output)
                        print("        got : " .. tostring(got.value) .. " | " .. got.output)
                    else
                        passed = passed + 1
                    end
                end
            end
        end
    end
end

print(string.format("\ncapybara tests: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
