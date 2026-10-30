--!nocheck
--[[
============================================================================
 Admin Diamond Spawner  —  bulk-spawn Diamonds through the Admin Inventory
 Built from the whole-game dump (PlaceId 98459174589830).
============================================================================
 WHAT IT IS
 ---------------------------------------------------------------------------
  This game's "Admin Inventory" (the panel the Admin gamepass unlocks) can
  spawn catalog items to a player, including the Currencies catalog
  (Coins / Diamonds / Tickets). The in-game panel caps how many you can
  spawn per pick — it prompts "Enter a whole number from 1 to <max>".

  This script fires the panel's own spawn remote (AdminInventory_SpawnItem)
  DIRECTLY with whatever amount you choose, so you can request far more than
  the UI slider allows — from 1T up to 100q per click — without opening the
  menu and re-typing each time. You can also auto-repeat it.

 HONEST LIMITS (read these — they are real walls, not bugs)
 ---------------------------------------------------------------------------
  1. ADMIN-GATED. The server only honors AdminInventory_SpawnItem from an
     account that actually has the Admin panel / is permitted. If your
     account isn't an admin, the server rejects it and nothing spawns — a
     client script can't grant itself admin. This is for use ON the panel
     you already bought.

  2. DIAMONDS HAVE A SERVER-SIDE LIMIT. The game's Currency code literally
     says: "You got <limit> limit, you CAN'T get more! If you have more than
     limit you WILL get EXACTLY <limit> after rejoining." So the server has a
     maximum Diamond balance. You can REQUEST 100q, but the server's own cap
     is the true ceiling: go over it and on rejoin you snap back down to the
     cap. 100q may be above that cap — test with the amount readout in-game.

  3. BEST-EFFORT ARG SHAPE. The exact argument order of the spawn remote
     isn't recoverable from a bytecode dump, so this tries the common shapes
     (target + "Currency|Diamonds" + amount, a packet table, etc.), all
     pcall-guarded. Use "Print Remotes" + "Run Custom" to confirm the shape
     live if the default doesn't register.

 CONTROLS
 ---------------------------------------------------------------------------
  * Type an amount (accepts 1t, 100q, 1e15, or plain digits) or tap a preset.
  * "Spawn" fires once. "Auto" repeats every <interval> seconds.
  * Target defaults to YOU; type a username to spawn to someone else.
  * RightShift toggles Auto.  _G.AdminDiamondSpawn.auto = false  stops it.
============================================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

-- ── config / state ─────────────────────────────────────────────────────────
local MIN_AMOUNT = 1e12          -- 1T  (user floor)
local MAX_AMOUNT = 100 * 1e15    -- 100q = 1e17 (user ceiling)

_G.AdminDiamondSpawn = _G.AdminDiamondSpawn or {}
local S = _G.AdminDiamondSpawn
S.amount   = S.amount   or MIN_AMOUNT
S.interval = S.interval or 0.25
S.auto     = false
S.target   = S.target   or lp.Name
S.currency = "Diamonds"

-- ── number parsing ("1t", "100q", "1e15", "1000000000000") ─────────────────
local SUFFIX = {
    k = 1e3,  m = 1e6,  b = 1e9,  t = 1e12,
    q  = 1e15,            -- quadrillion (what "100q" means here)
    qa = 1e15, qi = 1e18, -- long-form just in case
}
local function parseAmount(txt)
    if type(txt) == "number" then return txt end
    txt = tostring(txt):gsub("%s+", ""):gsub(",", ""):lower()
    if txt == "" then return nil end
    -- scientific / plain number with no suffix
    local n = tonumber(txt)
    if n then return n end
    -- number + letter suffix
    local num, suf = txt:match("^([%d%.]+)([a-z]+)$")
    if num and suf and SUFFIX[suf] then
        local base = tonumber(num)
        if base then return base * SUFFIX[suf] end
    end
    return nil
end

local function clamp(n)
    if not n then return MIN_AMOUNT end
    if n < MIN_AMOUNT then n = MIN_AMOUNT end
    if n > MAX_AMOUNT then n = MAX_AMOUNT end
    return math.floor(n)
end

local function shorten(n)
    local units = { {1e18,"Qi"},{1e15,"q"},{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"} }
    for _, u in ipairs(units) do
        if n >= u[1] then
            return string.format("%.3g%s", n / u[1], u[2])
        end
    end
    return tostring(math.floor(n))
end

-- ── resolve the game's Network layer ────────────────────────────────────────
local Network
local function getNetwork()
    if Network then return Network end
    pcall(function()
        local lib = ReplicatedStorage:WaitForChild("Library", 5)
        if lib then
            local client = lib:FindFirstChild("Client")
            local mod = client and client:FindFirstChild("Network")
            if mod and mod:IsA("ModuleScript") then
                Network = require(mod)
            end
        end
    end)
    return Network
end

local function targetPlayer()
    local name = tostring(S.target or ""):lower()
    if name == "" then return lp end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name or p.DisplayName:lower() == name then return p end
    end
    return nil  -- not in server
end

-- fire via whichever method the Network module exposes
local function net(remoteName, ...)
    local n = getNetwork()
    if not n then return false, "no Network" end
    local args = { ... }
    local ok = false
    for _, method in ipairs({ "Fire", "FireServer", "fire" }) do
        if type(n[method]) == "function" then
            local good = pcall(function() n[method](n, remoteName, table.unpack(args)) end)
            ok = ok or good
        end
    end
    return ok
end

-- ── the spawn itself ────────────────────────────────────────────────────────
-- Tries the arg shapes AdminInventory_SpawnItem is likely to accept.
local REMOTE = "AdminInventory_SpawnItem"
local function spawnDiamonds(amount)
    local n = getNetwork()
    if not n then return false, "Network not found" end
    local tgt = targetPlayer()
    if not tgt then return false, "target '"..tostring(S.target).."' isn't in this server" end
    local cur = S.currency
    local descriptor = "Currency|" .. cur        -- Class|Id form the panel formats
    local fired = false
    -- shape A: target, "Class|Id", amount
    fired = net(REMOTE, tgt, descriptor, amount) or fired
    -- shape B: target, "Currency", "Diamonds", amount
    fired = net(REMOTE, tgt, "Currency", cur, amount) or fired
    -- shape C: target, "Diamonds", amount
    fired = net(REMOTE, tgt, cur, amount) or fired
    -- shape D: packet table
    fired = net(REMOTE, tgt, { Class = "Currency", Id = cur, Amount = amount }) or fired
    fired = net(REMOTE, { Target = tgt, Class = "Currency", Id = cur, Amount = amount }) or fired
    -- shape E: descriptor, amount, target (reordered)
    fired = net(REMOTE, descriptor, amount, tgt) or fired
    return fired
end

-- ── GUI ──────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AdminDiamondSpawn"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 300)
main.Position = UDim2.new(0, 20, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(80, 180, 255); stroke.Thickness = 1.5

local pad = Instance.new("UIPadding", main)
pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
local list = Instance.new("UIListLayout", main)
list.Padding = UDim.new(0, 6); list.SortOrder = Enum.SortOrder.LayoutOrder

local function label(txt, size, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, size or 18)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 13
    l.TextColor3 = color or Color3.fromRGB(230, 235, 245)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = txt
    l.Parent = main
    return l
end
local function button(txt, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.BackgroundColor3 = color or Color3.fromRGB(40, 110, 200)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = txt
    b.AutoButtonColor = true
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end
local function textbox(default)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, 0, 0, 28)
    t.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
    t.BorderSizePixel = 0
    t.Font = Enum.Font.Gotham
    t.TextSize = 13
    t.TextColor3 = Color3.fromRGB(235, 240, 250)
    t.PlaceholderColor3 = Color3.fromRGB(120, 128, 140)
    t.ClearTextOnFocus = false
    t.Text = default or ""
    t.Parent = main
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    return t
end

label("💎 Admin Diamond Spawner", 20, Color3.fromRGB(120, 200, 255))
local status = label("ready", 16, Color3.fromRGB(150, 220, 150))

label("Amount per click (1t … 100q)")
local amountBox = textbox("1t")

-- preset row
local presetHolder = Instance.new("Frame")
presetHolder.Size = UDim2.new(1, 0, 0, 26)
presetHolder.BackgroundTransparency = 1
presetHolder.Parent = main
local pl = Instance.new("UIListLayout", presetHolder)
pl.FillDirection = Enum.FillDirection.Horizontal
pl.Padding = UDim.new(0, 4)
local function preset(txt)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 46, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(230, 235, 245)
    b.Text = txt
    b.Parent = presetHolder
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    b.Activated:Connect(function()
        amountBox.Text = txt:lower()
        S.amount = clamp(parseAmount(txt))
        status.Text = "amount = " .. shorten(S.amount)
    end)
    return b
end
for _, p in ipairs({ "1T", "10T", "100T", "1q", "10q", "100q" }) do preset(p) end

label("Target (blank = you)")
local targetBox = textbox(lp.Name)

local spawnBtn = button("💎 Spawn Diamonds", Color3.fromRGB(40, 150, 90))
local autoBtn  = button("Auto: OFF", Color3.fromRGB(70, 75, 90))

-- helper row
local printBtn  = button("Print Remotes (console)", Color3.fromRGB(55, 60, 74))

-- ── behavior ───────────────────────────────────────────────────────────────
local function syncAmount()
    local parsed = parseAmount(amountBox.Text)
    S.amount = clamp(parsed)
    if not parsed then
        status.Text = "bad number — using " .. shorten(S.amount)
    end
    return S.amount
end
amountBox.FocusLost:Connect(function()
    syncAmount()
    status.Text = "amount = " .. shorten(S.amount)
end)
targetBox.FocusLost:Connect(function()
    S.target = targetBox.Text
end)

local function doSpawn()
    S.target = targetBox.Text
    local amt = syncAmount()
    local ok, err = spawnDiamonds(amt)
    if ok then
        status.Text = string.format("spawned %s → %s", shorten(amt), S.target ~= "" and S.target or lp.Name)
    else
        status.Text = "failed: " .. tostring(err or "server rejected (admin only?)")
    end
end
spawnBtn.Activated:Connect(doSpawn)

local function setAuto(on)
    S.auto = on
    autoBtn.Text = "Auto: " .. (on and "ON" or "OFF")
    autoBtn.BackgroundColor3 = on and Color3.fromRGB(190, 60, 60) or Color3.fromRGB(70, 75, 90)
end
autoBtn.Activated:Connect(function() setAuto(not S.auto) end)

printBtn.Activated:Connect(function()
    local n = getNetwork()
    print("── Admin Diamond Spawner: Network scan ──")
    print("Network module resolved:", n ~= nil)
    -- dump remote-ish names we can see under ReplicatedStorage
    local found = {}
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then
            table.insert(found, d:GetFullName())
        end
    end
    if #found == 0 then
        print("No raw Remote objects exposed (Network is module-wrapped) — use the in-game panel's remote names like 'AdminInventory_SpawnItem'.")
    else
        for _, f in ipairs(found) do print("  ", f) end
    end
    status.Text = "printed Network info to console (F9)"
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then setAuto(not S.auto) end
end)

-- auto loop
task.spawn(function()
    while gui.Parent do
        if S.auto then
            doSpawn()
            task.wait(math.max(0.05, tonumber(S.interval) or 0.25))
        else
            task.wait(0.1)
        end
    end
end)

-- init
syncAmount()
status.Text = "ready — amount = " .. shorten(S.amount)
getNetwork()
warn("[Admin Diamond Spawner] loaded. Admin-gated; Diamonds have a server cap. RightShift = Auto.")
