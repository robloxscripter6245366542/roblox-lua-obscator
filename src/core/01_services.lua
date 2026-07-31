-- ── Services ──────────────────────────────────────────────────────────────────
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RUN     = game:GetService("RunService")
local SG      = game:GetService("StarterGui")
local WS      = game:GetService("Workspace")
local HTTP    = game:GetService("HttpService")
local MktSvc  = game:GetService("MarketplaceService")
local TelSvc  = game:GetService("TeleportService")
local CollSvc = game:GetService("CollectionService")
local CmdSvc  = game:GetService("Chat")
-- NOTE: DataStoreService / PhysicsService are server-only; never import them here.

-- ── LocalPlayer — polling loop, works on every executor ───────────────────────
local LP
for _ = 1, 120 do
    LP = Players.LocalPlayer
    if LP then break end
    task.wait(0.1)
end
if not LP then warn("[Nexus] No LocalPlayer after 12 s"); return end

-- ── Notification helper (available immediately, before any GUI) ────────────────
local function notify(title, body, dur)
    pcall(function()
        SG:SetCore("SendNotification",{Title=title,Text=body,Duration=dur or 3})
    end)
end
notify("Nexus Executor","Loading…",3)

-- ── GUI parent — gethui() (Delta/Synapse) → PlayerGui fallback ────────────────
local function getGuiParent()
    if type(gethui)=="function" then
        local ok,h = pcall(gethui)
        if ok and h and typeof(h)=="Instance" then return h end
    end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LP:WaitForChild("PlayerGui",15)
end
local PGui = getGuiParent()
if not PGui then warn("[Nexus] No PlayerGui"); return end

-- Remove any stale GUI
local _old = PGui:FindFirstChild("__SS_EXEC__")
if _old then _old:Destroy() end

-- ── loadstring compat ─────────────────────────────────────────────────────────
local _ld = loadstring or load

-- ── Camera / viewport — safe getter with fallback ─────────────────────────────
-- workspace.CurrentCamera can be nil briefly on mobile. We retry for up to
-- 5 seconds before falling back to a safe default size.
local function getViewport()
    for _ = 1, 50 do
        local cam = WS:FindFirstChildOfClass("Camera")
        if cam then return cam.ViewportSize end
        task.wait(0.1)
    end
    return Vector2.new(800,600)   -- safe fallback if camera never appears
end
local _VP = getViewport()

-- ── Platform & adaptive sizing ────────────────────────────────────────────────
local isMobile = UIS.TouchEnabled   -- true on Delta iOS/Android/iPad

-- Mobile → full-screen. Desktop → fixed 650×530 floating window.
local WIN_W  = isMobile and math.floor(_VP.X) or 650
local WIN_H  = isMobile and math.floor(_VP.Y) or 530
local SIDE_W = 54    -- sidebar width  (desktop only)
local TAB_SP = 40    -- sidebar tab row pitch (desktop only)
local TAB_SZ = 34    -- sidebar button height (desktop only)

-- ── Executor detection ────────────────────────────────────────────────────────
local function detectExecutor()
    if type(identifyexecutor)=="function" then
        local ok,n = pcall(identifyexecutor)
        if ok and n and n~="" then return tostring(n) end
    end
    if type(getexecutorname)=="function" then
        local ok,n = pcall(getexecutorname)
        if ok and n and n~="" then return tostring(n) end
    end
    if rawget(_G,"delta")  or rawget(_G,"_DELTA") or rawget(_G,"DELTA")  then return "Delta"     end
    if rawget(_G,"wave")   or rawget(_G,"Wave")                           then return "Wave"      end
    if rawget(_G,"syn")    or rawget(_G,"Synapse")                        then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED")                                           then return "KRNL"      end
    if rawget(_G,"fluxus") or rawget(_G,"Fluxus")                        then return "Fluxus"    end
    if rawget(_G,"solara") or rawget(_G,"Solara")                        then return "Solara"    end
    if rawget(_G,"is_sirhurt_closure")                                    then return "SirHurt"   end
    if rawget(_G,"ANDROID_APP")                                           then return "Arceus X"  end
    return "Unknown Executor"
end

-- ── Utilities ─────────────────────────────────────────────────────────────────
local function safeGet(t,k) return type(t)=="table" and rawget(t,k) or nil end
local function safeCall(fn,...)
    if type(fn)~="function" then return false,"not a function" end
    return pcall(fn,...)
end
local function isFunc(x)  return type(x)=="function" end
local function isTable(x) return type(x)=="table"    end
local function isStr(x)   return type(x)=="string"   end
local function isNum(x)   return type(x)=="number"   end

local function ts() return os.date("[%H:%M:%S] ") end

local function fmtNum(n)
    if n>=1e9 then return("%.2fB"):format(n/1e9)
    elseif n>=1e6 then return("%.2fM"):format(n/1e6)
    elseif n>=1e3 then return("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

local function trunc(s,max)
    s=tostring(s); return #s>max and s:sub(1,max).."…" or s
end

local function split(s,sep)
    local p={}; for x in s:gmatch("([^"..sep.."]+)") do p[#p+1]=x end; return p
end

local function trim(s) return (tostring(s):gsub("^%s*(.-)%s*$","%1")) end

local function deepCopy(t)
    if type(t)~="table" then return t end
    local c={}; for k,v in pairs(t) do c[k]=deepCopy(v) end; return c
end

local function tableHas(t,v) for _,x in t do if x==v then return true end end; return false end
local function tableMap(t,fn) local o={}; for i,v in t do o[i]=fn(v) end; return o end
local function tableFilter(t,fn) local o={}; for _,v in t do if fn(v) then o[#o+1]=v end end; return o end

-- Clipboard — setclipboard works on Delta iOS/Android/iPad
local function copyText(txt)
    if type(setclipboard)=="function" then return pcall(setclipboard,txt) end
    return false
end

local function getRoot() local c=LP and LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=LP and LP.Character; return c and c:FindFirstChildOfClass("Humanoid")   end
local function getChar() return LP and LP.Character end

-- ── Shared execution helpers ──────────────────────────────────────────────────
-- Compile then run a chunk of Lua.
-- Returns: ok(bool), err(string|nil), stage("compile"|"runtime"|nil)
local function runCode(code)
    local fn, cerr = _ld(code)
    if not fn then return false, tostring(cerr), "compile" end
    local ok, rerr = pcall(fn)
    if not ok then return false, tostring(rerr), "runtime" end
    return true
end

-- Depth-first walk of every script instance under `root`, calling fn(scriptInst).
local function forEachScript(root, fn)
    for _, ch in root:GetChildren() do
        if ch:IsA("LocalScript") or ch:IsA("ModuleScript") or ch:IsA("Script") then
            fn(ch)
        end
        forEachScript(ch, fn)
    end
end

-- Detect whether a (possibly dotted, e.g. "debug.getinfo") global exists.
local function hasGlobal(name)
    local root = name:match("^([^%.]+)%.")
    if root then
        local tbl = (getfenv and getfenv()[root]) or _G[root]
        if type(tbl) == "table" then
            return tbl[name:match("%.(.+)$")] ~= nil
        end
        return false
    end
    if getfenv and getfenv()[name] ~= nil then return true end
    return _G[name] ~= nil
end

-- ── Session ───────────────────────────────────────────────────────────────────
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
