--!nocheck
--[[
============================================================================
 Admin Diamond Spawner  —  auto-repeat 1t spawns up to your target
 Built from the whole-game dump (PlaceId 98459174589830).
============================================================================
 THE REAL LIMIT (confirmed in-game)
 ---------------------------------------------------------------------------
  The Admin Panel's "Spawn Currency!" caps EVERY spawn at 1t (one trillion)
  per press — type 100q and the server answers "No more than 1t at a time!".
  That cap is enforced on the SERVER. No client script can push more than 1t
  in a single call; it just gets rejected. So the only way up to 100q is to
  spawn 1t many times.

 WHAT THIS DOES
 ---------------------------------------------------------------------------
  It learns the panel's exact spawn call once, then auto-fires 1t spawns on a
  loop until your Diamonds reach the target you set (default 100q), then stops.
  Reaching 100q from ~20q is ~80,000 spawns of 1t, so it takes a while and
  fires a lot of remotes — the game has abuse detection, so keep the rate
  sane (there's a Rate control; too fast risks a kick). This can't beat the
  1t-per-call server cap — nothing client-side can — it just automates it.

 HOW TO USE
 ---------------------------------------------------------------------------
  1. Run this. Status shows "LEARN: spawn once in the real menu".
  2. Open the real Admin Panel → Spawn Currency → "Diamonds", any amount,
     press Spawn ONCE. (Even a rejected 100q works — we send 1t on replay.)
  3. Status flips to "LEARNED ✓" and it starts auto-spawning 1t up to target.

 CONTROLS:  RightShift = pause/resume.  _G.AdminDiamondSpawn.running=false stops.
============================================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ── config / state ─────────────────────────────────────────────────────────
local PER_CALL   = 1e12               -- server max per spawn = 1t (hard cap)
local TARGET_MAX = 100 * 1e15         -- 100q ceiling for the target field
local SPAWN_NAME = "AdminInventory_SpawnItem"
local AMOUNT_FLOOR_FOR_SWAP = 1e6     -- only numbers this big are "the amount"

_G.AdminDiamondSpawn = _G.AdminDiamondSpawn or {}
local S = _G.AdminDiamondSpawn
S.target       = S.target       or 100 * 1e15      -- default goal: 100q
S.perTick      = S.perTick      or 5               -- spawns fired per interval
S.interval     = S.interval     or 0.2             -- seconds per burst
S.auto         = true
S.running      = true
S.stopAtTarget = (S.stopAtTarget ~= false)
S.captured     = S.captured     or nil
S.version      = (S.version or 0) + 1

-- ── number parsing / formatting ─────────────────────────────────────────────
local SUFFIX = { k=1e3, m=1e6, b=1e9, t=1e12, q=1e15, qa=1e15, qi=1e18, a=1e18 }
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
local function shorten(n)
    if not n then return "?" end
    for _, u in ipairs({ {1e18,"a"},{1e15,"q"},{1e12,"t"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }) do
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

-- ── best-effort Diamonds balance read (for progress + auto-stop) ─────────────
-- Tries a few common places; parses the HUD label last. Precision at the HUD's
-- shortened granularity is fine for a "reached 100q" stop.
local function readDiamonds()
    -- player attribute / value objects
    local a = lp:GetAttribute("Diamonds")
    if type(a) == "number" then return a end
    for _, where in ipairs({ lp, lp:FindFirstChild("leaderstats") }) do
        if where then
            local v = where:FindFirstChild("Diamonds")
            if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then return v.Value end
        end
    end
    -- client Save module (Pet-Sim style): require and probe getters
    local ok, val = pcall(function()
        local lib = ReplicatedStorage:FindFirstChild("Library")
        local client = lib and lib:FindFirstChild("Client")
        local saveMod = client and client:FindFirstChild("Save")
        if not saveMod then return nil end
        local Save = require(saveMod)
        local data
        if type(Save.Get) == "function" then data = Save:Get() or Save.Get() end
        data = data or (type(Save) == "table" and (Save.Data or Save.save or Save))
        if type(data) == "table" then
            local cur = data.Currency or data.Currencies or data
            if type(cur) == "table" and type(cur.Diamonds) == "number" then return cur.Diamonds end
            if type(data.Diamonds) == "number" then return data.Diamonds end
        end
        return nil
    end)
    if ok and type(val) == "number" then return val end
    -- HUD text fallback: find a short-number label near a "Diamonds" context
    local pg = lp:FindFirstChild("PlayerGui")
    if pg then
        local best
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("TextLabel") and (d.Name == "Amount" or d.Name == "Quantity" or d.Name == "Diamonds") then
                local parsed = parseAmount((d.Text or ""):gsub("[^%d%.kmbtqaKMBTQA]", ""))
                if parsed and parsed > (best or 0) then best = parsed end
            end
        end
        if best then return best end
    end
    return nil
end

-- ── CAPTURE layer (learn the real spawn call) ────────────────────────────────
local function pack(...) return { n = select("#", ...), ... } end
local function unpackn(t) return table.unpack(t, 1, t.n) end
local function looksLikeSpawn(t)
    for i = 1, t.n do if t[i] == SPAWN_NAME then return true end end
    return false
end
-- force the amount arg to 1t (the server cap) on a copy, so replay always lands
local function withPerCall(t)
    local copy = { n = t.n }
    local bi, bv
    for i = 1, t.n do
        copy[i] = t[i]
        if type(t[i]) == "number" and t[i] >= AMOUNT_FLOOR_FOR_SWAP then
            if not bv or t[i] > bv then bv, bi = t[i], i end
        end
    end
    if bi then copy[bi] = PER_CALL end
    return copy
end

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
                return realOrig(a, ...)
            end
            moduleHooked = true
        end
    end
end

local namecallHooked = false
local function installNamecallHook()
    if namecallHooked then return end
    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then return end
    local ncc = (type(newcclosure) == "function") and newcclosure or function(f) return f end
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", ncc(function(self, ...)
            local method = getnamecallmethod()
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

-- ── REPLAY one 1t spawn ──────────────────────────────────────────────────────
local function replayOne()
    local c = S.captured
    if not c then return false end
    local argl = withPerCall(c.argl)
    if c.kind == "namecall" and typeof(c.remote) == "Instance" then
        return pcall(function() c.remote:FireServer(unpackn(argl)) end)
    elseif c.kind == "module" then
        local n = getNetwork()
        if n and type(n[c.method]) == "function" then
            if c.isSelf then return pcall(function() n[c.method](n, unpackn(argl)) end)
            else return pcall(function() n[c.method](unpackn(argl)) end) end
        end
    end
    return false
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AdminDiamondSpawn"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 300); main.Position = UDim2.new(0,20,0.5,-150)
main.BackgroundColor3 = Color3.fromRGB(18,20,28); main.BorderSizePixel = 0
main.Active = true; main.Draggable = true; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(80,180,255); stroke.Thickness = 1.5
local pad = Instance.new("UIPadding", main)
pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
local layoutU = Instance.new("UIListLayout", main); layoutU.Padding = UDim.new(0,6); layoutU.SortOrder = Enum.SortOrder.LayoutOrder

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
label("Server cap: 1t per spawn. This repeats 1t up to your target.", 28, Color3.fromRGB(180,190,205))
local status = label("LEARN: spawn once in the real menu", 30, Color3.fromRGB(255,210,120))

label("Target total (stops here, max 100q)")
local targetBox = textbox("100q")

-- rate presets
local rateHolder = Instance.new("Frame"); rateHolder.Size=UDim2.new(1,0,0,26); rateHolder.BackgroundTransparency=1; rateHolder.Parent=main
local rl=Instance.new("UIListLayout",rateHolder); rl.FillDirection=Enum.FillDirection.Horizontal; rl.Padding=UDim.new(0,4)
local function rateBtn(name, perTick, interval)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,90,1,0); b.BackgroundColor3=Color3.fromRGB(45,50,62)
    b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=12; b.TextColor3=Color3.fromRGB(230,235,245)
    b.Text=name; b.Parent=rateHolder; Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.Activated:Connect(function() S.perTick=perTick; S.interval=interval end)
    return b
end
rateBtn("Safe ~5/s", 1, 0.2)
rateBtn("Normal ~25/s", 5, 0.2)
rateBtn("Fast ~100/s", 10, 0.1)

local autoBtn = button("Auto: ON", Color3.fromRGB(190,60,60))

-- ── behavior ───────────────────────────────────────────────────────────────
targetBox.FocusLost:Connect(function()
    local t = parseAmount(targetBox.Text)
    if t then S.target = math.min(t, TARGET_MAX) end
end)

local function updateStatus()
    if not (status and status.Parent) then return end
    if not S.captured then
        status.Text = "LEARN: spawn once in the real menu"
        status.TextColor3 = Color3.fromRGB(255,210,120)
        return
    end
    local bal = readDiamonds()
    local progress = bal and (shorten(bal) .. " / " .. shorten(S.target)) or ("target " .. shorten(S.target))
    if S.stopAtTarget and bal and bal >= S.target then
        status.Text = "DONE ✓  " .. progress
        status.TextColor3 = Color3.fromRGB(150,220,150)
    elseif S.auto then
        status.Text = "spawning 1t…  " .. progress
        status.TextColor3 = Color3.fromRGB(150,220,150)
    else
        status.Text = "paused  " .. progress
        status.TextColor3 = Color3.fromRGB(200,200,120)
    end
end

local function setAuto(on)
    S.auto = on; autoBtn.Text = "Auto: "..(on and "ON" or "OFF")
    autoBtn.BackgroundColor3 = on and Color3.fromRGB(190,60,60) or Color3.fromRGB(70,75,90)
end
autoBtn.Activated:Connect(function() setAuto(not S.auto) end)
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then setAuto(not S.auto) end
end)

-- main loop: burst 1t spawns, stop at target
local MY = S.version
task.spawn(function()
    while S.running and S.version == MY do
        if S.auto and S.captured then
            local bal = readDiamonds()
            if S.stopAtTarget and bal and bal >= S.target then
                updateStatus()
                task.wait(0.5)
            else
                local n = math.max(1, math.floor(tonumber(S.perTick) or 5))
                for _ = 1, n do
                    replayOne()
                    task.wait()        -- one frame between fires (kinder to anti-abuse)
                end
                task.wait(math.max(0, tonumber(S.interval) or 0.2))
            end
        else
            task.wait(0.15)
        end
    end
end)

-- live status refresh
task.spawn(function()
    while S.running and S.version == MY do updateStatus(); task.wait(0.4) end
end)

-- hooks + health
getNetwork(); installModuleHook(); installNamecallHook()
lp.CharacterAdded:Connect(function() task.wait(1); getNetwork(); installModuleHook() end)

setAuto(S.auto); updateStatus()
warn("[Admin Diamond Spawner] loaded. Spawn once in the REAL menu to teach it, then it auto-repeats 1t up to your target (server caps each spawn at 1t).")
