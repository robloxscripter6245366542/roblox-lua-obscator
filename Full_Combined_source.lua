-- ================================================================
--  NEXUS EXECUTOR  –  Modular Bootstrap
--  Each module loaded via individual pcall + loadstring + HttpGet.
-- ================================================================

local _ok, _err = pcall(function()

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local SG      = game:GetService("StarterGui")

-- Wait for LocalPlayer (works on all executors — no RunService)
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12s."); return end

local PGui = LP:WaitForChild("PlayerGui", 15)
if not PGui then warn("[Nexus] No PlayerGui."); return end

local old = PGui:FindFirstChild("__SS_EXEC__")
if old then old:Destroy() end

local function notify(msg)
    pcall(function() SG:SetCore("SendNotification",{Title="Nexus",Text=msg,Duration=4}) end)
end

notify("Loading modules...")

-- SHA-pinned raw URL — avoids branch-name slash ambiguity in HttpGet
-- Update this SHA after pushing new lib/tabs/data files.
local RAW = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/0fa210a21976631e2224b2be0ca83396782364c1/"

_G._SS = {
    RAW=RAW, LP=LP, PGui=PGui,
    Players=Players, RS=RS, UIS=UIS, TS=TS,
}

local _ld = loadstring or load
local loaded, failed = 0, 0

local function loadMod(path)
    local ok, src = pcall(game.HttpGet, game, RAW..path, true)
    if not ok then
        warn("[Nexus] HTTP fail: "..path.." → "..tostring(src))
        failed += 1; return
    end
    local fn, ce = _ld(src)
    if not fn then
        warn("[Nexus] Compile fail: "..path.." → "..tostring(ce))
        failed += 1; return
    end
    local ok2, re = pcall(fn)
    if not ok2 then
        warn("[Nexus] Runtime fail: "..path.." → "..tostring(re))
        failed += 1; return
    end
    loaded += 1
end

-- ── Core libraries ────────────────────────────────────────────────────────────
loadMod("lib/theme.lua")
loadMod("lib/ui.lua")
loadMod("lib/bridge.lua")
loadMod("lib/window.lua")

-- If window failed, nothing will show — abort with a visible notification
if not _G._SS.newTab then
    notify("ERROR: window failed to load. Check console.")
    warn("[Nexus] window.lua did not register newTab — aborting.")
    return
end

-- ── Tab modules ───────────────────────────────────────────────────────────────
loadMod("tabs/execute.lua")
loadMod("tabs/server.lua")
loadMod("tabs/sandbox.lua")
loadMod("tabs/malware.lua")
loadMod("tabs/deobfusc.lua")
loadMod("tabs/checker.lua")
loadMod("tabs/scripts.lua")
loadMod("tabs/env.lua")

-- ── Finalise ──────────────────────────────────────────────────────────────────
if _G._SS.showPage    then _G._SS.showPage(1)   end
if _G._SS.initChecker then _G._SS.initChecker() end

if failed == 0 then
    notify("Loaded ✓  ("..loaded.." modules)")
else
    notify("Loaded with "..failed.." error(s) — check console")
end

end)

if not _ok then
    warn("[Nexus] STARTUP ERROR: "..tostring(_err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            {Title="Nexus ERROR",Text=tostring(_err):sub(1,80),Duration=8})
    end)
end
