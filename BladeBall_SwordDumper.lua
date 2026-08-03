--[[
    BladeBall_SwordDumper.lua
    -------------------------------------------------------------------------
    Purpose: rip the game's own combat brain — SwordsController, the PRY
    parry module, SwordAPI, the ball logic and the deflection abilities —
    together with their UPVALUES and CONSTANTS (that is where the real parry
    distance / timing numbers live), so the autoparry can be tuned to the
    game's exact hit window instead of guessed radii.

    Run this in your executor while in a Blade Ball round, then send back the
    files it writes (workspace/BladeBallDump/) or the clipboard contents.

    Safe & read-only: it never FireServers anything. It only reads scripts,
    protos, constants and upvalues. Everything is wrapped in pcall so a
    missing executor capability just prints "unsupported" and moves on.
    -------------------------------------------------------------------------
]]

local RS      = game:GetService("ReplicatedStorage")
local HttpSvc = game:GetService("HttpService")

-- ── executor capability probing ─────────────────────────────────────────
local F = {
    decompile        = rawget(getfenv(), "decompile") or decompile,
    getscriptbytecode= rawget(getfenv(), "getscriptbytecode") or getscriptbytecode or dumpstring,
    disassemble      = rawget(getfenv(), "disassemble") or disassemble,
    getgc            = rawget(getfenv(), "getgc") or getgc,
    getupvalues      = (debug and debug.getupvalues) or getupvalues,
    getupvalue       = (debug and debug.getupvalue) or getupvalue,
    getconstants     = (debug and debug.getconstants) or getconstants,
    getprotos        = (debug and debug.getprotos) or getprotos,
    getproto         = (debug and debug.getproto) or getproto,
    getinfo          = (debug and debug.getinfo) or getinfo,
    writefile        = rawget(getfenv(), "writefile") or writefile,
    makefolder       = rawget(getfenv(), "makefolder") or makefolder,
    setclipboard     = rawget(getfenv(), "setclipboard") or setclipboard or toclipboard,
}

local OUT_DIR = "BladeBallDump"
local lines   = {}         -- combined report
local function log(s)
    s = tostring(s)
    table.insert(lines, s)
    print("[SwordDumper] " .. s)
end

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil, res
end

local function fullname(inst)
    local ok, n = pcall(function() return inst:GetFullName() end)
    return ok and n or tostring(inst)
end

-- ── serialise a lua value shallowly (constants / upvalues) ──────────────
local function serialise(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "string" then
        return string.format("%q", v)
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "Instance" then
        return "Instance<" .. fullname(v) .. ">"
    elseif t == "function" then
        local info = F.getinfo and safe(F.getinfo, v) or nil
        if info then
            return string.format("function<nups=%s,nparams=%s,src=%s>",
                tostring(info.nups), tostring(info.numparams), tostring(info.short_src or info.source))
        end
        return "function"
    elseif t == "table" then
        if depth > 2 then return "{...}" end
        local parts = {}
        local n = 0
        for k, val in pairs(v) do
            n = n + 1
            if n > 40 then table.insert(parts, "...") break end
            table.insert(parts, "[" .. serialise(k, depth + 1) .. "]=" .. serialise(val, depth + 1))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        -- Vector3 / CFrame / Enum / etc.
        return t .. "(" .. tostring(v) .. ")"
    end
end

-- ── dump a single script instance: source + bytecode ───────────────────
local function dumpScript(inst, tag)
    log("")
    log("################################################################")
    log("## " .. (tag or "SCRIPT") .. ": " .. fullname(inst) .. "  (" .. inst.ClassName .. ")")
    log("################################################################")

    -- 1) try full decompile
    if F.decompile then
        local src, err = safe(F.decompile, inst)
        if type(src) == "string" and #src > 0 then
            log("----- DECOMPILED SOURCE -----")
            log(src)
            if F.writefile then
                safe(F.writefile, OUT_DIR .. "/" .. inst.Name .. "_decompiled.lua", src)
            end
            return
        else
            log("decompile unavailable/failed: " .. tostring(err))
        end
    end

    -- 2) fall back to raw bytecode (hex) + optional disassembly
    if F.getscriptbytecode then
        local bc, err = safe(F.getscriptbytecode, inst)
        if type(bc) == "string" and #bc > 0 then
            log("----- BYTECODE (" .. #bc .. " bytes) -----")
            if F.disassemble then
                local dis = safe(F.disassemble, inst) or safe(F.disassemble, bc)
                if type(dis) == "string" then
                    log(dis)
                    if F.writefile then safe(F.writefile, OUT_DIR .. "/" .. inst.Name .. "_disasm.txt", dis) end
                end
            end
            -- hex for offline analysis
            local hex = {}
            for i = 1, #bc do hex[i] = string.format("%02x", string.byte(bc, i)) end
            local hexstr = table.concat(hex)
            if F.writefile then safe(F.writefile, OUT_DIR .. "/" .. inst.Name .. "_bytecode.hex", hexstr) end
            -- readable constant strings embedded in the bytecode
            local strs = {}
            for s in string.gmatch(bc, "[\032-\126][\032-\126][\032-\126][\032-\126]+") do
                strs[s] = true
            end
            local keys = {}
            for s in pairs(strs) do table.insert(keys, s) end
            table.sort(keys)
            log("----- EMBEDDED STRINGS (" .. #keys .. ") -----")
            log(table.concat(keys, " | "))
        else
            log("bytecode unavailable/failed: " .. tostring(err))
        end
    else
        log("no bytecode/decompile capability in this executor")
    end
end

-- ── dump a required MODULE's return value: upvalues + constants ─────────
-- This is the money shot for parry math: PRY's Network/Constants/Convert/Hash
-- and the ball module's speed/curve tables live in upvalues & constants.
local function dumpModuleInternals(moduleInst, tag)
    log("")
    log("================================================================")
    log("== MODULE INTERNALS " .. (tag or "") .. ": " .. fullname(moduleInst))
    log("================================================================")

    local mod = safe(require, moduleInst)
    if mod == nil then
        log("require() failed or returned nil")
    else
        log("require() returned: " .. type(mod))
        if type(mod) == "table" then
            for k, v in pairs(mod) do
                log("  ." .. tostring(k) .. " = " .. serialise(v, 1))
            end
        elseif type(mod) == "function" and F.getupvalues then
            local ups = safe(F.getupvalues, mod)
            if type(ups) == "table" then
                log("  function upvalues:")
                for i, v in pairs(ups) do
                    log("    [" .. tostring(i) .. "] = " .. serialise(v, 1))
                end
            end
            if F.getconstants then
                local consts = safe(F.getconstants, mod)
                if type(consts) == "table" then
                    log("  function constants:")
                    for i, v in pairs(consts) do
                        log("    [" .. tostring(i) .. "] = " .. serialise(v, 1))
                    end
                end
            end
        end
    end
end

-- ── numeric-constant harvester: scan a script's protos for numbers ──────
-- Parry windows are numbers (reach radius, time thresholds). Pull every
-- numeric constant out of a script's function tree so we can spot them.
local function harvestNumbers(fn, seen, out, depth)
    if depth > 6 or not fn then return end
    seen = seen or {}
    if seen[fn] then return end
    seen[fn] = true
    if F.getconstants then
        local consts = safe(F.getconstants, fn)
        if type(consts) == "table" then
            for _, c in pairs(consts) do
                if type(c) == "number" then out[c] = (out[c] or 0) + 1 end
            end
        end
    end
    if F.getprotos then
        local protos = safe(F.getprotos, fn)
        if type(protos) == "table" then
            for _, p in pairs(protos) do harvestNumbers(p, seen, out, depth + 1) end
        end
    end
end

-- =========================================================================
-- TARGET RESOLUTION
-- =========================================================================
log("BladeBall SwordDumper starting @ " .. os.date("%X"))
if F.makefolder then safe(F.makefolder, OUT_DIR) end

local targets = {}
local function addTarget(inst, tag)
    if inst then table.insert(targets, {inst = inst, tag = tag}) end
end

-- SwordsController (Script) + its module children
local controllers = RS:FindFirstChild("Controllers")
if controllers then
    for _, child in ipairs(controllers:GetDescendants()) do
        local n = child.Name
        if n:match("Sword") or n:match("Parry") or n:match("Combat") or n:match("Ball") then
            addTarget(child, "Controllers/" .. child.ClassName)
        end
    end
end

-- PRY parry module (may be nested / renamed) + SwordAPI + Shared combat
addTarget(RS:FindFirstChild("PRY", true), "PRY module")
local shared = RS:FindFirstChild("Shared")
if shared then
    addTarget(shared:FindFirstChild("SwordAPI", true), "SwordAPI")
    addTarget(shared:FindFirstChild("ReplicatedInstances", true), "ReplicatedInstances")
    for _, child in ipairs(shared:GetDescendants()) do
        if child:IsA("ModuleScript") and (child.Name:match("Ball") or child.Name:match("Parry") or child.Name:match("Sword")) then
            addTarget(child, "Shared/" .. child.Name)
        end
    end
end

-- Deflection abilities (their success/timing constants matter for Auto Ability)
local abilityRoots = { RS:FindFirstChild("Abilities", true) }
local charModel = game:GetService("Players").LocalPlayer.Character
for _, root in ipairs(abilityRoots) do
    if root then
        for _, child in ipairs(root:GetDescendants()) do
            if child:IsA("LuaSourceContainer") and (child.Name:match("Deflect") or child.Name:match("Parry") or child.Name:match("Slash")) then
                addTarget(child, "Ability/" .. child.Name)
            end
        end
    end
end

log("Resolved " .. #targets .. " target(s).")

-- =========================================================================
-- DUMP EACH TARGET
-- =========================================================================
local allNumbers = {}
for _, t in ipairs(targets) do
    if t.inst:IsA("LuaSourceContainer") then
        dumpScript(t.inst, t.tag)
        -- harvest numeric constants from the live function if we can reach it
        if F.getgc then
            -- (best-effort; many executors can't map a Script->function directly)
        end
    end
    if t.inst:IsA("ModuleScript") then
        dumpModuleInternals(t.inst, t.tag)
        local mod = safe(require, t.inst)
        if type(mod) == "function" then harvestNumbers(mod, {}, allNumbers, 0) end
    end
end

-- =========================================================================
-- BALL SNAPSHOT (live physical values — reach radius sanity check)
-- =========================================================================
log("")
log("================= LIVE BALL SNAPSHOT =================")
local balls = workspace:FindFirstChild("Balls")
if balls then
    for _, ball in ipairs(balls:GetChildren()) do
        if ball:GetAttribute("realBall") then
            local z = ball:FindFirstChild("zoomies")
            log(("Ball %s | target=%s DoNotParry=%s size=%s speed=%.2f")
                :format(ball.Name,
                    tostring(ball:GetAttribute("target")),
                    tostring(ball:GetAttribute("DoNotParry")),
                    tostring(ball.Size),
                    z and z.VectorVelocity.Magnitude or -1))
            local attrs = safe(function() return ball:GetAttributes() end)
            if type(attrs) == "table" then
                for k, v in pairs(attrs) do log("    attr " .. tostring(k) .. " = " .. serialise(v, 1)) end
            end
        end
    end
else
    log("no workspace.Balls (start a round first)")
end

-- =========================================================================
-- NUMERIC CONSTANT SUMMARY (likely parry windows / reach radii)
-- =========================================================================
log("")
log("========= NUMERIC CONSTANTS HARVESTED (value : count) =========")
local numlist = {}
for n, c in pairs(allNumbers) do table.insert(numlist, {n = n, c = c}) end
table.sort(numlist, function(a, b) return a.n < b.n end)
for _, e in ipairs(numlist) do
    -- flag values in plausible parry-reach / timing ranges
    local flag = ""
    if e.n > 0 and e.n < 60 then flag = "  <-- plausible reach/threshold" end
    if e.n > 0 and e.n < 1 then flag = "  <-- plausible time(s)/factor" end
    log(string.format("  %-14s : %d%s", tostring(e.n), e.c, flag))
end

-- =========================================================================
-- WRITE / COPY REPORT
-- =========================================================================
local report = table.concat(lines, "\n")
if F.writefile then
    safe(F.writefile, OUT_DIR .. "/FULL_REPORT.txt", report)
    log("")
    log("Wrote " .. OUT_DIR .. "/FULL_REPORT.txt (" .. #report .. " bytes)")
end
if F.setclipboard then
    safe(F.setclipboard, report)
    log("Report copied to clipboard.")
end
log("DONE. Send back the FULL_REPORT.txt (and the *_bytecode.hex files) to tune the parry.")
