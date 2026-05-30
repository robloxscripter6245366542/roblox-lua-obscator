-- ================================================================
--  NEXUS EXECUTOR  –  Modular Bootstrap
--  Fetches all modules via game:HttpGet + loadstring.
--  Obfuscate with:  lua5.4 obfuscate.lua
-- ================================================================

local _ok, _err = pcall(function()

-- ── Services ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")

-- ── Wait for LocalPlayer (works in all executors, no RunService) ──────────────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12 s."); return end

-- ── PlayerGui ─────────────────────────────────────────────────────────────────
local PGui = LP:WaitForChild("PlayerGui", 15)
if not PGui then warn("[Nexus] No PlayerGui."); return end

-- Remove stale GUI from previous injection
local old = PGui:FindFirstChild("__SS_EXEC__")
if old then old:Destroy() end

-- ── Loading notification ───────────────────────────────────────────────────────
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="Nexus Executor", Text="Loading...", Duration=3})
end)

-- ── Shared namespace ──────────────────────────────────────────────────────────
local RAW = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/claude/session-UDpk7/"

_G._SS = {
    RAW     = RAW,
    LP      = LP,
    PGui    = PGui,
    Players = Players,
    RS      = RS,
    UIS     = UIS,
    TS      = TS,
}

-- ── Module loader ─────────────────────────────────────────────────────────────
-- Uses loadstring or load — works on Delta, Synapse, Krnl, Fluxus, etc.
local _ld = loadstring or load

local function loadMod(path)
    local ok2, src = pcall(game.HttpGet, game, RAW..path, true)
    if not ok2 then
        warn("[Nexus] HTTP fail: "..path.." — "..tostring(src)); return
    end
    local fn, ce = _ld(src)
    if not fn then
        warn("[Nexus] Compile fail: "..path.." — "..tostring(ce)); return
    end
    local ok3, re = pcall(fn)
    if not ok3 then
        warn("[Nexus] Runtime fail: "..path.." — "..tostring(re))
    end
end

-- ── Core libraries (order matters) ────────────────────────────────────────────
loadMod("lib/theme.lua")   -- SS.C, SS.TF, SS.TS2, SS.FB, SS.FN, SS.FC
loadMod("lib/ui.lua")      -- SS.Frm/Lbl/Btn/Inp/Con/Scr/hov/corner/stroke/pad/listH/listV/rowBar/tw
loadMod("lib/bridge.lua")  -- SS.Bridge, SS.pingBridge, SS.callBridge
loadMod("lib/window.lua")  -- SS.WIN/TBAR/SIDE/BODY, SS.newTab, SS.showPage

-- ── Tab modules ───────────────────────────────────────────────────────────────
loadMod("tabs/execute.lua")
loadMod("tabs/server.lua")
loadMod("tabs/sandbox.lua")
loadMod("tabs/malware.lua")
loadMod("tabs/deobfusc.lua")
loadMod("tabs/checker.lua")   -- also loads data/unc.lua, data/sunc.lua, data/myriad.lua
loadMod("tabs/scripts.lua")
loadMod("tabs/env.lua")

-- ── Finalise ──────────────────────────────────────────────────────────────────
if _G._SS.showPage    then _G._SS.showPage(1)    end
if _G._SS.initChecker then _G._SS.initChecker()  end

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="Nexus Executor", Text="Loaded ✓", Duration=2})
end)

end)  -- end pcall

if not _ok then warn("[Nexus] STARTUP ERROR: "..tostring(_err)) end
