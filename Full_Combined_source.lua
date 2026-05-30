-- ================================================================
--  NEXUS EXECUTOR  –  Modular Bootstrap
--  Each module is loaded via its own pcall + loadstring + HttpGet.
--  If one fails it warns and continues — nothing crashes.
-- ================================================================

local _ok, _err = pcall(function()

-- ── Services ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")

-- ── Wait for LocalPlayer ──────────────────────────────────────────────────────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12 s."); return end

local PGui = LP:WaitForChild("PlayerGui", 15)
if not PGui then warn("[Nexus] No PlayerGui."); return end

-- Remove stale GUI from a previous injection
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
    RAW=RAW, LP=LP, PGui=PGui,
    Players=Players, RS=RS, UIS=UIS, TS=TS,
}

-- ── Use loadstring or load — works on Delta, Synapse, Krnl, Fluxus, etc ──────
local _ld = loadstring or load

-- ════════════════════════════════════════════════════════════════════════════════
--  CORE LIBRARIES  (each in its own pcall — failure warns but never crashes)
-- ════════════════════════════════════════════════════════════════════════════════

-- 1. Theme: colors, fonts, TweenInfos
local themeOk, themeErr = pcall(function()
    return _ld(game:HttpGet(RAW.."lib/theme.lua", true))()
end)
if not themeOk then warn("[Nexus] theme.lua failed: "..tostring(themeErr)) end

-- 2. UI helpers: Frm/Lbl/Btn/Inp/Con/Scr/hov/corner/stroke/pad/listH/listV/rowBar/tw
local uiOk, uiErr = pcall(function()
    return _ld(game:HttpGet(RAW.."lib/ui.lua", true))()
end)
if not uiOk then warn("[Nexus] ui.lua failed: "..tostring(uiErr)) end

-- 3. Bridge: pingBridge, callBridge, Bridge ref
local bridgeOk, bridgeErr = pcall(function()
    return _ld(game:HttpGet(RAW.."lib/bridge.lua", true))()
end)
if not bridgeOk then warn("[Nexus] bridge.lua failed: "..tostring(bridgeErr)) end

-- 4. Window: WIN/TBAR/SIDE/BODY, newTab, showPage, drag, minimize
local windowOk, windowErr = pcall(function()
    return _ld(game:HttpGet(RAW.."lib/window.lua", true))()
end)
if not windowOk then warn("[Nexus] window.lua failed: "..tostring(windowErr)); return end

-- ════════════════════════════════════════════════════════════════════════════════
--  TAB MODULES  (each in its own pcall)
-- ════════════════════════════════════════════════════════════════════════════════

-- Tab 1: Execute (Client LS / Server LS / Require / URL Exec)
local execOk, execErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/execute.lua", true))()
end)
if not execOk then warn("[Nexus] execute.lua failed: "..tostring(execErr)) end

-- Tab 2: Server commands
local serverOk, serverErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/server.lua", true))()
end)
if not serverOk then warn("[Nexus] server.lua failed: "..tostring(serverErr)) end

-- Tab 3: Sandbox bypass
local sandboxOk, sandboxErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/sandbox.lua", true))()
end)
if not sandboxOk then warn("[Nexus] sandbox.lua failed: "..tostring(sandboxErr)) end

-- Tab 4: Malware scanner
local malwareOk, malwareErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/malware.lua", true))()
end)
if not malwareOk then warn("[Nexus] malware.lua failed: "..tostring(malwareErr)) end

-- Tab 5: Deobfuscator
local deobOk, deobErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/deobfusc.lua", true))()
end)
if not deobOk then warn("[Nexus] deobfusc.lua failed: "..tostring(deobErr)) end

-- Tab 6: Function checker (also loads data/unc, data/sunc, data/myriad internally)
local checkerOk, checkerErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/checker.lua", true))()
end)
if not checkerOk then warn("[Nexus] checker.lua failed: "..tostring(checkerErr)) end

-- Tab 7: Script hub
local scriptsOk, scriptsErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/scripts.lua", true))()
end)
if not scriptsOk then warn("[Nexus] scripts.lua failed: "..tostring(scriptsErr)) end

-- Tab 8: Environment diagnostics
local envOk, envErr = pcall(function()
    return _ld(game:HttpGet(RAW.."tabs/env.lua", true))()
end)
if not envOk then warn("[Nexus] env.lua failed: "..tostring(envErr)) end

-- ════════════════════════════════════════════════════════════════════════════════
--  FINALISE
-- ════════════════════════════════════════════════════════════════════════════════
if _G._SS.showPage    then _G._SS.showPage(1)   end
if _G._SS.initChecker then _G._SS.initChecker() end

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="Nexus Executor", Text="Loaded ✓", Duration=2})
end)

end)  -- end outer pcall

if not _ok then warn("[Nexus] STARTUP ERROR: "..tostring(_err)) end
