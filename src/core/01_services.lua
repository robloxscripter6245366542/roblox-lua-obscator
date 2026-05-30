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

-- ── LocalPlayer — works across all executors ─────────────────────────────────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12s — aborting."); return end

-- ── GUI Parent — gethui() → PlayerGui fallback ────────────────────────────────
local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LP:WaitForChild("PlayerGui", 15)
end
local PGui = getGuiParent()
if not PGui then warn("[Nexus] No PlayerGui — aborting."); return end

-- Remove any stale Nexus GUI
local old = PGui:FindFirstChild("__SS_EXEC__")
if old then old:Destroy() end

-- ── Notification helper ───────────────────────────────────────────────────────
local function notify(title, body, duration)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title    = title,
            Text     = body,
            Duration = duration or 3,
        })
    end)
end
notify("Nexus Executor", "Loading modules…", 2)

-- ── loadstring compat ─────────────────────────────────────────────────────────
local _ld = loadstring or load

-- ── Utility: safe get ─────────────────────────────────────────────────────────
local function safeGet(tbl, key)
    if type(tbl) ~= "table" then return nil end
    return rawget(tbl, key)
end

-- ── Utility: safe call ────────────────────────────────────────────────────────
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, "not a function" end
    return pcall(fn, ...)
end

-- ── Utility: typeof wrapper ───────────────────────────────────────────────────
local function isFunc(x) return type(x) == "function" end
local function isTable(x) return type(x) == "table" end
local function isStr(x) return type(x) == "string" end
local function isNum(x) return type(x) == "number" end

-- ── Utility: timestamp ────────────────────────────────────────────────────────
local function ts() return os.date("[%H:%M:%S] ") end

-- ── Utility: format number ────────────────────────────────────────────────────
local function fmtNum(n)
    if n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

-- ── Utility: truncate string ──────────────────────────────────────────────────
local function trunc(s, max)
    s = tostring(s)
    return #s > max and s:sub(1, max) .. "…" or s
end

-- ── Utility: split string ─────────────────────────────────────────────────────
local function split(s, sep)
    local parts = {}
    for part in s:gmatch("([^" .. sep .. "]+)") do
        parts[#parts+1] = part
    end
    return parts
end

-- ── Utility: trim whitespace ──────────────────────────────────────────────────
local function trim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

-- ── Utility: deep copy table ──────────────────────────────────────────────────
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do copy[k] = deepCopy(v) end
    return copy
end

-- ── Utility: table contains ───────────────────────────────────────────────────
local function tableHas(tbl, val)
    for _, v in tbl do if v == val then return true end end
    return false
end

-- ── Utility: map table ────────────────────────────────────────────────────────
local function tableMap(tbl, fn)
    local out = {}
    for i, v in tbl do out[i] = fn(v) end
    return out
end

-- ── Utility: filter table ─────────────────────────────────────────────────────
local function tableFilter(tbl, fn)
    local out = {}
    for _, v in tbl do if fn(v) then out[#out+1] = v end end
    return out
end

-- ── Utility: executor detection ───────────────────────────────────────────────
local function detectExecutor()
    if identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        if ok and name then return tostring(name) end
    end
    if getexecutorname then
        local ok, name = pcall(getexecutorname)
        if ok and name then return tostring(name) end
    end
    if syn then return "Synapse X (inferred)" end
    if KRNL_LOADED then return "KRNL (inferred)" end
    if fluxus then return "Fluxus (inferred)" end
    if is_sirhurt_closure then return "SirHurt (inferred)" end
    return "Unknown Executor"
end

-- ── Utility: get character root ───────────────────────────────────────────────
local function getRoot()
    local char = LP and LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ── Utility: get humanoid ─────────────────────────────────────────────────────
local function getHum()
    local char = LP and LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ── Utility: get character ────────────────────────────────────────────────────
local function getChar() return LP and LP.Character end

-- ── Session metadata ──────────────────────────────────────────────────────────
local SESSION = {
    startTime   = os.time(),
    executor    = detectExecutor(),
    platform    = UIS.TouchEnabled and "Mobile/Touch" or "PC/Desktop",
    gameId      = game.GameId,
    placeId     = game.PlaceId,
    playerName  = LP.Name,
    displayName = LP.DisplayName,
}
