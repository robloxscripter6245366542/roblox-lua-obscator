--!nocheck
--[[
============================================================================
 Admin Diamond Spawner  —  capture & replay the real Admin panel's spawn
 Built from the whole-game dump (PlaceId 98459174589830).
============================================================================
 WHY THIS VERSION
 ---------------------------------------------------------------------------
  The game's own Admin Inventory button already works (you typed 100q and it
  spawned). The exact arguments it sends to AdminInventory_SpawnItem can't be
  read from a bytecode dump, so guessing them failed. So instead of guessing,
  this LEARNS the call: it watches the game's own spawn once, records the
  exact remote + arguments, then REPLAYS that same call for you — manually or
  on an always-on loop — at whatever amount you choose.

 HOW TO USE  (one-time learn, then it's automatic)
 ---------------------------------------------------------------------------
  1. Run this script. The panel shows "LEARN: spawn once in the real menu".
  2. Open the game's real Admin Inventory, pick Diamonds, type any amount,
     press its spawn button ONCE. (Do it on yourself.)
  3. This captures the exact call. Status flips to "LEARNED ✓". From then on
     the loop auto-replays it (default amount 100q), and the Spawn button /
     Auto work. You only have to teach it once per session.

 It still only works if your account actually has the Admin panel, and
 Diamonds still have a server-side cap (over it → snaps back on rejoin).
 Those are server rules a client can't change — but the amount the real
 panel let through, this will let through too, because it's the same call.

 CONTROLS:  RightShift = Auto on/off.  _G.AdminDiamondSpawn.running=false stops.
============================================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ── config / state ─────────────────────────────────────────────────────────
local MIN_AMOUNT = 1e12          -- 1T
local MAX_AMOUNT = 100 * 1e15    -- 100q = 1e17
local SPAWN_NAME = "AdminInventory_SpawnItem"
local AMOUNT_FLOOR_FOR_SWAP = 1e6  -- only numbers this big are treated as "the amount"

_G.AdminDiamondSpawn = _G.AdminDiamondSpawn or {}
local S = _G.AdminDiamondSpawn
S.amount         = S.amount         or 100 * 1e15   -- default 100q
S.interval       = S.interval       or 0.25
S.auto           = true
S.target         = S.target         or lp.Name
S.running        = true
S.overrideAmount = (S.overrideAmount ~= false)      -- swap captured amount with S.amount
S.captured       = S.captured       or nil          -- the learned call
S.version        = (S.version or 0) + 1

-- ── number parsing / formatting ─────────────────────────────────────────────
local SUFFIX = { k=1e3, m=1e6, b=1e9, t=1e12, q=1e15, qa=1e15, qi=1e18 }
local function parseAmount(txt)
    if type(txt) == "number" then return txt end
    txt = tostring(txt):gsub("%s+",""):gsub(",",""):lower()
    if txt == "" then return nil end
    local n = tonumber(txt)
    if n then return n end
    local num, suf = txt:match("^([%d%.]+)([a-z]+)$")
    if num and suf and SUFFIX[suf] then
        local base = tonumber(num)
        if base then return base * SUFFIX[suf] end
    end
    return nil
end
local function clamp(n)
    if not n then return S.amount end
    if n < MIN_AMOUNT then n = MIN_AMOUNT end
    if n > MAX_AMOUNT then n = MAX_AMOUNT end
    return math.floor(n)
end
local function shorten(n)
    for _, u in ipairs({ {1e18,"Qi"},{1e15,"q"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }) do
        if n >= u[1] then return string.format("%.3g%s", n/u[1], u[2]) end
    end
    return tostring(math.floor(n))
end

-- ── Network resolve ──────────────────────────────────────────────────────────
local Network
local function getNetwork()
    if Network then return Network end
    pcall(function()
        local lib = ReplicatedStorage:WaitForChild("Library", 5)
        local client = lib and lib:FindFirstChild("Client")
        local mod = client and client:FindFirstChild("Network")
        if mod and mod:IsA("ModuleScript") then Network = require(mod) end
    end)
    return Network
end

-- ── CAPTURE layer ────────────────────────────────────────────────────────────
-- Record { kind, ... } describing the exact spawn call so we can replay it.

-- copy a vararg list, skipping nothing
local function pack(...) return { n = select("#", ...), ... } end
local function unpackn(t) return table.unpack(t, 1, t.n) end

-- does this arg list look like the admin-spawn call? (name appears as a string)
local function looksLikeSpawn(t)
    for i = 1, t.n do
        if t[i] == SPAWN_NAME then return true end
    end
    return false
end

-- replace the single largest number (>= floor) with `amount`, on a copy
local function withAmount(t, amount)
    local copy = { n = t.n }
    local bestIdx, bestVal
    for i = 1, t.n do
        copy[i] = t[i]
        if type(t[i]) == "number" and t[i] >= AMOUNT_FLOOR_FOR_SWAP then
            if not bestVal or t[i] > bestVal then bestVal, bestIdx = t[i], i end
        end
    end
    if bestIdx then copy[bestIdx] = amount end
    return copy
end

-- (1) module-level hook: wrap Network's fire/invoke methods (pure Lua, safe)
local moduleHooked = false
local function installModuleHook()
    local n = getNetwork()
    if not n or moduleHooked then return end
    for _, m in ipairs({ "Fire", "FireServer", "fire", "Invoke", "invoke", "InvokeServer" }) do
        local orig = rawget(n, m)
        if type(orig) == "function" then
            local realOrig = orig
            n[m] = function(a, ...)
                local isSelf = (a == n)
                local argl = isSelf and pack(...) or pack(a, ...)
                if looksLikeSpawn(argl) or (not isSelf and a == SPAWN_NAME) or (isSelf and argl[1] == SPAWN_NAME) then
                    S.captured = { kind = "module", method = m, isSelf = isSelf, argl = argl }
                end
                if isSelf then return realOrig(a, ...) else return realOrig(a, ...) end
            end
            moduleHooked = true
        end
    end
end

-- (2) executor __namecall hook: capture the raw FireServer (most faithful).
local namecallHooked = false
local function installNamecallHook()
    if namecallHooked then return end
    local hookmeta = (type(hookmetamethod) == "function")
    local getnc    = (type(getnamecallmethod) == "function")
    local ncc      = (type(newcclosure) == "function") and newcclosure or function(f) return f end
    if not (hookmeta and getnc) then return end
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", ncc(function(self, ...)
            local method = getnc()
            if method == "FireServer" or method == "fireServer" then
                local argl = pack(...)
                if looksLikeSpawn(argl) then
                    S.captured = { kind = "namecall", remote = self, argl = argl }
                end
            end
            return old(self, ...)
        end))
        namecallHooked = true
    end)
end

-- ── REPLAY ───────────────────────────────────────────────────────────────────
local function replay(amount)
    local c = S.captured
    if not c then return false, "not learned yet" end
    local argl = S.overrideAmount and withAmount(c.argl, amount) or c.argl
    local ok = false
    if c.kind == "namecall" and typeof(c.remote) == "Instance" then
        ok = pcall(function() c.remote:FireServer(unpackn(argl)) end)
    elseif c.kind == "module" then
        local n = getNetwork()
        if n and type(n[c.method]) == "function" then
            if c.isSelf then
                ok = pcall(function() n[c.method](n, unpackn(argl)) end)
            else
                ok = pcall(function() n[c.method](unpackn(argl)) end)
            end
        end
    end
    return ok
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AdminDiamondSpawn"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 290); main.Position = UDim2.new(0,20,0.5,-145)
main.BackgroundColor3 = Color3.fromRGB(18,20,28); main.BorderSizePixel = 0
main.Active = true; main.Draggable = true; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(80,180,255); stroke.Thickness = 1.5
local pad = Instance.new("UIPadding", main)
pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
local layout = Instance.new("UIListLayout", main); layout.Padding = UDim.new(0,6); layout.SortOrder = Enum.SortOrder.LayoutOrder

local function label(txt,h,c)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,h or 18); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextColor3=c or Color3.fromRGB(230,235,245)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; l.Text=txt; l.Parent=main; return l
end
local function button(txt,c)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,30); b.BackgroundColor3=c or Color3.fromRGB(40,110,200)
    b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Text=txt; b.Parent=main; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); return b
end
local function textbox(d)
    local t=Instance.new("TextBox"); t.Size=UDim2.new(1,0,0,28); t.BackgroundColor3=Color3.fromRGB(30,34,44)
    t.BorderSizePixel=0; t.Font=Enum.Font.Gotham; t.TextSize=13; t.TextColor3=Color3.fromRGB(235,240,250)
    t.ClearTextOnFocus=false; t.Text=d or ""; t.Parent=main; Instance.new("UICorner",t).CornerRadius=UDim.new(0,6); return t
end

label("💎 Admin Diamond Spawner", 20, Color3.fromRGB(120,200,255))
local status = label("LEARN: spawn once in the real menu", 30, Color3.fromRGB(255,210,120))

label("Amount per click (1t … 100q)")
local amountBox = textbox("100q")

local presetHolder = Instance.new("Frame"); presetHolder.Size=UDim2.new(1,0,0,26); presetHolder.BackgroundTransparency=1; presetHolder.Parent=main
local pl=Instance.new("UIListLayout",presetHolder); pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,4)
local function preset(txt)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,46,1,0); b.BackgroundColor3=Color3.fromRGB(45,50,62)
    b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=12; b.TextColor3=Color3.fromRGB(230,235,245)
    b.Text=txt; b.Parent=presetHolder; Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.Activated:Connect(function() amountBox.Text=txt:lower(); S.amount=clamp(parseAmount(txt)) end)
    return b
end
for _,p in ipairs({"1T","10T","100T","1q","10q","100q"}) do preset(p) end

local spawnBtn = button("💎 Spawn Diamonds", Color3.fromRGB(40,150,90))
local autoBtn  = button("Auto: ON", Color3.fromRGB(190,60,60))

-- ── behavior ───────────────────────────────────────────────────────────────
local function syncAmount()
    local parsed = parseAmount(amountBox.Text)
    S.amount = clamp(parsed)
    return S.amount
end
amountBox.FocusLost:Connect(syncAmount)

local function updateStatus(extra)
    if not (status and status.Parent) then return end
    if S.captured then
        status.Text = string.format("LEARNED ✓  %s%s", shorten(S.overrideAmount and S.amount or 0),
            extra and ("  — "..extra) or (S.overrideAmount and "" or " (captured amt)"))
        status.TextColor3 = Color3.fromRGB(150,220,150)
    else
        status.Text = "LEARN: spawn once in the real menu" .. (extra and ("  ("..extra..")") or "")
        status.TextColor3 = Color3.fromRGB(255,210,120)
    end
end

local function doSpawn()
    syncAmount()
    if not S.captured then
        updateStatus("waiting — press the real panel's button once")
        return false
    end
    local ok = replay(S.amount)
    updateStatus(ok and ("spawned "..shorten(S.amount)) or "replay failed (still admin-gated?)")
    return ok
end
spawnBtn.Activated:Connect(doSpawn)

local function setAuto(on)
    S.auto = on; autoBtn.Text = "Auto: "..(on and "ON" or "OFF")
    autoBtn.BackgroundColor3 = on and Color3.fromRGB(190,60,60) or Color3.fromRGB(70,75,90)
end
autoBtn.Activated:Connect(function() setAuto(not S.auto) end)
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then setAuto(not S.auto) end
end)

-- always-on loop
local MY = S.version
task.spawn(function()
    while S.running and S.version == MY do
        if S.auto and S.captured then
            getNetwork(); replay(clamp(S.amount)); updateStatus("auto "..shorten(S.amount))
            task.wait(math.max(0.05, tonumber(S.interval) or 0.25))
        else
            task.wait(0.15)
        end
    end
end)

-- watch for the learn event flipping the status live
task.spawn(function()
    while S.running and S.version == MY do
        if S.captured and (status and status.Parent) and status.TextColor3 ~= Color3.fromRGB(150,220,150) then
            updateStatus()
        end
        task.wait(0.25)
    end
end)

-- install hooks, resolve network, keep healthy across respawns
getNetwork(); installModuleHook(); installNamecallHook()
lp.CharacterAdded:Connect(function() task.wait(1); getNetwork(); installModuleHook() end)

syncAmount(); updateStatus()
warn("[Admin Diamond Spawner] loaded. Spawn once in the REAL admin menu to teach it the exact call, then it auto-replays at your chosen amount.")
