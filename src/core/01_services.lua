-- ── Services & LocalPlayer ──────────────────────────────────────────────────
local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local UIS       = game:GetService("UserInputService")
local TS        = game:GetService("TweenService")
local RUN       = game:GetService("RunService")
local SG        = game:GetService("StarterGui")
local WS        = game:GetService("Workspace")
local HTTP      = game:GetService("HttpService")
local CSvc      = game:GetService("ContentProvider")
local MktSvc    = game:GetService("MarketplaceService")
local TelSvc    = game:GetService("TeleportService")
local PhysSvc   = game:GetService("PhysicsService")
local CollSvc   = game:GetService("CollectionService")
local DataSvc   = game:GetService("DataStoreService")
local TwSvc     = game:GetService("TweenService")
local CmdSvc    = game:GetService("Chat")

-- ── LocalPlayer — works across all executors (no RunService dependency) ───────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12s — aborting."); return end

-- ── GUI Parent — gethui() preferred (Delta/Synapse), PlayerGui fallback ───────
local function getGuiParent()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h and typeof(h) == "Instance" then return h end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LP:WaitForChild("PlayerGui", 15)
end
local PGui = getGuiParent()
if not PGui then warn("[Nexus] No PlayerGui — aborting."); return end

-- Remove any stale Nexus GUI
local _old = PGui:FindFirstChild("__SS_EXEC__")
if _old then _old:Destroy() end

-- ── Startup notification ──────────────────────────────────────────────────────
local function notify(title, body, duration)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title    = title,
            Text     = body,
            Duration = duration or 3,
        })
    end)
end
notify("Nexus Executor", "Loading…", 2)

-- ── loadstring compat (Delta + all PC executors) ──────────────────────────────
local _ld = loadstring or load

-- ── Executor detection ────────────────────────────────────────────────────────
local function detectExecutor()
    -- Standard API (Delta, Solara, Wave, KRNL 2+)
    if type(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name and name ~= "" then return tostring(name) end
    end
    if type(getexecutorname) == "function" then
        local ok, name = pcall(getexecutorname)
        if ok and name and name ~= "" then return tostring(name) end
    end
    -- Fingerprint by unique globals
    if rawget(_G,"delta")   or rawget(_G,"_DELTA") or rawget(_G,"DELTA")   then return "Delta"     end
    if rawget(_G,"wave")    or rawget(_G,"Wave")                            then return "Wave"      end
    if rawget(_G,"syn")     or rawget(_G,"Synapse")                         then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED")                                             then return "KRNL"      end
    if rawget(_G,"fluxus")  or rawget(_G,"Fluxus")                         then return "Fluxus"    end
    if rawget(_G,"solara")  or rawget(_G,"Solara")                         then return "Solara"    end
    if rawget(_G,"is_sirhurt_closure")                                      then return "SirHurt"   end
    if rawget(_G,"OXYGEN_U")                                               then return "Oxygen U"  end
    if rawget(_G,"ANDROID_APP")                                            then return "Arceus X"  end
    return "Unknown Executor"
end

-- ── Platform detection ────────────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled   -- true on Delta iOS/Android

-- ── Adaptive window dimensions ────────────────────────────────────────────────
-- Compute once from the camera viewport at load time.
-- Mobile: use most of the screen; Desktop: fixed 650×530.
local function _vp() return workspace.CurrentCamera.ViewportSize end
local _VP0   = _vp()
local WIN_W  = isMobile and math.min(math.floor(_VP0.X) - 8,  510) or 650
local WIN_H  = isMobile and math.min(math.floor(_VP0.Y) - 8,  560) or 530
local SIDE_W = isMobile and 50 or 54
-- Space for 10 tab buttons inside (WIN_H - titlebar - top gap)
local _tabArea = WIN_H - 50
local TAB_SP   = isMobile and math.min(37, math.floor(_tabArea / 10)) or 40
local TAB_SZ   = math.max(26, TAB_SP - 6)   -- button height = spacing minus gap

-- ── Utility helpers ───────────────────────────────────────────────────────────
local function safeGet(tbl, key)
    if type(tbl) ~= "table" then return nil end
    return rawget(tbl, key)
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, "not a function" end
    return pcall(fn, ...)
end

local function isFunc(x)  return type(x) == "function" end
local function isTable(x) return type(x) == "table"    end
local function isStr(x)   return type(x) == "string"   end
local function isNum(x)   return type(x) == "number"   end

local function ts() return os.date("[%H:%M:%S] ") end

local function fmtNum(n)
    if n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

local function trunc(s, max)
    s = tostring(s)
    return #s > max and s:sub(1, max) .. "…" or s
end

local function split(s, sep)
    local parts = {}
    for part in s:gmatch("([^" .. sep .. "]+)") do
        parts[#parts+1] = part
    end
    return parts
end

local function trim(s) return (tostring(s):gsub("^%s*(.-)%s*$", "%1")) end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return copy
end

local function tableHas(tbl, val)
    for _, v in tbl do if v == val then return true end end
    return false
end

local function tableMap(tbl, fn)
    local out = {}
    for i, v in tbl do out[i] = fn(v) end
    return out
end

local function tableFilter(tbl, fn)
    local out = {}
    for _, v in tbl do if fn(v) then out[#out+1] = v end end
    return out
end

-- ── Clipboard helper (Delta iOS uses setclipboard) ────────────────────────────
local function copyText(text)
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, text)
        return ok
    end
    return false
end

-- ── Character helpers ─────────────────────────────────────────────────────────
local function getRoot()
    local char = LP and LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = LP and LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function getChar() return LP and LP.Character end

-- ── Session metadata ──────────────────────────────────────────────────────────
local SESSION = {
    startTime   = os.time(),
    executor    = detectExecutor(),
    platform    = isMobile and "Mobile/Touch" or "PC/Desktop",
    isMobile    = isMobile,
    gameId      = game.GameId,
    placeId     = game.PlaceId,
    playerName  = LP.Name,
    displayName = LP.DisplayName,
    winW        = WIN_W,
    winH        = WIN_H,
}
