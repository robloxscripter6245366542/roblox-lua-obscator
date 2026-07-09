#!/usr/bin/env lua
-- ferret/cli.lua
-- Command-line front end for the ferret-style Lua obfuscator.
--
--   lua ferret/cli.lua obfuscate <input.lua> -o <output.lua> [options]
--
-- Options:
--   -o, --output <file>   output path (default: <input>.obf.lua)
--   --seed <n>            deterministic build seed (default: random)
--   --layers <a,b,c>      pick passes: numbers,strings,pack (default: all)
--   -q, --quiet           suppress the summary line
--
-- Mirrors LuaCrypt/ferret's `obfuscate input.lua -o output.lua --seed N`.

local here = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = here .. "/?.lua;" .. package.path

local Ferret = require("ferret")

local function die(msg)
    io.stderr:write("ferret: " .. msg .. "\n")
    os.exit(1)
end

local function usage()
    io.write([[
ferret - Lua VM-style obfuscator (pure Lua, Luau-compatible output)

Usage:
  lua ferret/cli.lua obfuscate <input.lua> [-o <output.lua>] [--seed N] [--layers L]

Options:
  -o, --output <file>   output path (default: <input>.obf.lua)
  --seed <n>            deterministic build seed (default: time-based)
  --layers <a,b,c>      passes to apply: numbers,strings,pack (default: all)
  -q, --quiet           suppress summary
  -h, --help            this help

Examples:
  lua ferret/cli.lua obfuscate script.lua -o out.lua --seed 7
  lua ferret/cli.lua obfuscate script.lua --layers numbers,strings
]])
end

local cmd = arg[1]
if cmd == "-h" or cmd == "--help" or cmd == nil then usage(); os.exit(0) end
if cmd ~= "obfuscate" then die("unknown command '" .. tostring(cmd) .. "' (try --help)") end

local input, output, seed, layers, quiet
local i = 2
while arg[i] do
    local a = arg[i]
    if a == "-o" or a == "--output" then i = i + 1; output = arg[i]
    elseif a == "--seed" then i = i + 1; seed = tonumber(arg[i]) or die("--seed needs a number")
    elseif a == "--layers" then
        i = i + 1
        layers = {}
        for l in (arg[i] or ""):gmatch("[^,]+") do layers[#layers + 1] = l end
    elseif a == "-q" or a == "--quiet" then quiet = true
    elseif a == "-h" or a == "--help" then usage(); os.exit(0)
    elseif a:sub(1, 1) == "-" then die("unknown option '" .. a .. "'")
    else
        if input then die("unexpected extra argument '" .. a .. "'") end
        input = a
    end
    i = i + 1
end

if not input then die("no input file (try --help)") end
output = output or (input:gsub("%.lua$", "") .. ".obf.lua")
seed = seed or (os.time() % 2147483648)

local f = io.open(input, "rb") or die("cannot open input '" .. input .. "'")
local src = f:read("*a"); f:close()

local ok, result = pcall(Ferret.obfuscate, src, { seed = seed, layers = layers, chunkname = input })
if not ok then die("obfuscation failed: " .. tostring(result)) end

local of = io.open(output, "wb") or die("cannot write output '" .. output .. "'")
of:write(result); of:close()

if not quiet then
    io.write(string.format(
        "ferret: %s -> %s\n  input : %d bytes\n  output: %d bytes\n  seed  : %d\n  layers: %s\n",
        input, output, #src, #result, seed,
        layers and table.concat(layers, ",") or table.concat(Ferret.DEFAULT_LAYERS, ",")))
end
