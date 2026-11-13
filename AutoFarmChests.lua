--!nocheck
--[[
============================================================================
 Auto Farm Chests  —  farm the best breakables, auto-collect into inventory
 Built from the whole-game dump (PlaceId 98459174589830).
============================================================================
 HOW THE GAME WORKS (recovered from the dump)
 ---------------------------------------------------------------------------
  * The "chests" are BREAKABLES: world models tagged with BreakableID /
    BreakableClass attributes (Normal, Legendary, Mythical, Golden, Rainbow,
    Event tiers, plus Chests / Diamond Crates).
  * Your PETS auto-attack the breakable you're standing on / targeting
    (PlayerPet.SetTarget -> Breakables_JoinPetBulk). Your clicks add
    Breakables_PlayerDealDamage. Damage per hit is decided by the SERVER from
    your pets/stats — a script can't inflate it, only automate the farming.
  * When a breakable breaks it drops a LOOTBAG that MAGNETS to you when you're
    near, and the reward is stored in your inventory automatically.
  * Inventory lootboxes open via Network:Invoke("Lootbox_RequestOpen").

 WHAT THIS DOES
 ---------------------------------------------------------------------------
  1. Scans the world for breakables and SCORES them (tier + chest/crate bonus
     + health) so it always farms the BEST one available.
  2. Teleports you onto that breakable so your pets farm it and its lootbag
     magnets into your inventory; also best-effort sends pets + click-damage.
  3. When it's gone, moves to the next best. Loops forever.
  4. Optional "Open Lootboxes" takes/opens boxes sitting in your inventory.

 HONEST LIMITS
 ---------------------------------------------------------------------------
  Damage/rewards are server-authoritative — this farms faster, it doesn't mint
  loot. The game has abuse detection; teleporting very fast can flag you, so
  the hop rate is modest and adjustable. Remote arg shapes for pet-target /
  click-damage are best-effort (pcall-guarded); the teleport+proximity farm
  works on its own even if those no-op.

 CONTROLS:  RightShift = start/stop.  _G.AutoFarmChests.running=false stops.
============================================================================
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- ── state ────────────────────────────────────────────────────────────────────
_G.AutoFarmChests = _G.AutoFarmChests or {}
local S = _G.AutoFarmChests
S.auto        = true
S.running     = true
S.hopDelay    = S.hopDelay    or 0.6     -- seconds on each chest before re-eval
S.bestOnly    = (S.bestOnly ~= false)    -- true = always chase the single best
S.openBoxes   = S.openBoxes   or false   -- auto-open inventory lootboxes
S.hoverStuds  = S.hoverStuds  or 6       -- how high above the chest to sit
S.version     = (S.version or 0) + 1

-- tier ranking (higher = better); unknown tiers score 1
local TIER_RANK = {
    normal = 1, common = 1, uncommon = 2, rare = 3, epic = 4,
    legendary = 5, mythical = 6, mythic = 6, golden = 7, gold = 7,
    rainbow = 8, void = 9, event = 10, nightmare = 11, secret = 12,
}

-- ── helpers ──────────────────────────────────────────────────────────────────
local function root()
    local c = lp.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart"))
end

local function partOf(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart") end
    local p = inst.Parent
    return p and (p:IsA("BasePart") and p or (p.PrimaryPart or p:FindFirstChildWhichIsA("BasePart")))
end

-- find every live breakable in the world (robust: anything with a BreakableID)
local function scanBreakables()
    local out = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        local id = d:GetAttribute("BreakableID") or d:GetAttribute("BreakableUID")
        if id ~= nil then
            local hp = d:GetAttribute("health") or d:GetAttribute("Health")
            if hp == nil or (type(hp) == "number" and hp > 0) then
                table.insert(out, d)
            end
        end
    end
    return out
end

-- score a breakable: tier + chest/crate bonus + health magnitude
local function scoreOf(b)
    local cls = tostring(b:GetAttribute("BreakableClass") or b:GetAttribute("BreakableType") or b.Name):lower()
    local tier = 1
    for word, rank in pairs(TIER_RANK) do
        if cls:find(word, 1, true) and rank > tier then tier = rank end
    end
    local chestBonus = 0
    if cls:find("chest", 1, true) or cls:find("crate", 1, true) or cls:find("diamond", 1, true)
       or cls:find("vault", 1, true) or cls:find("lootb", 1, true) then
        chestBonus = 20
    end
    local maxhp = tonumber(b:GetAttribute("maxHealth") or b:GetAttribute("MaxHealth") or b:GetAttribute("health") or 0) or 0
    -- health contributes on a log scale so a slightly rarer chest still wins
    local hpScore = (maxhp > 0) and (math.log10(maxhp + 10)) or 0
    return tier * 100 + chestBonus * 10 + hpScore
end

local function pickBest(list)
    local best, bestScore
    for _, b in ipairs(list) do
        local p = partOf(b)
        if p then
            local s = scoreOf(b)
            if not bestScore or s > bestScore then best, bestScore = b, s end
        end
    end
    return best, bestScore
end

-- ── Network + game modules (best-effort targeting / damage) ─────────────────
local Network, PlayerPet, BreakFront
local function requires()
    pcall(function()
        local lib = ReplicatedStorage:WaitForChild("Library", 5)
        local client = lib and lib:FindFirstChild("Client")
        if client then
            local nm = client:FindFirstChild("Network");           if nm then Network    = Network    or require(nm) end
            local pp = client:FindFirstChild("PlayerPet");          if pp then PlayerPet  = PlayerPet  or require(pp) end
            local bf = client:FindFirstChild("BreakableFrontend");  if bf then BreakFront = BreakFront or require(bf) end
        end
    end)
end

local function netFire(method, name, ...)
    if not Network then return end
    local f = Network[method]
    if type(f) == "function" then pcall(f, Network, name, ...) end
end

-- tell the game to target this breakable (sends pets + click damage, exact API)
local function targetBreakable(b)
    local id = b:GetAttribute("BreakableID") or b:GetAttribute("BreakableUID")
    -- 1) game's own targeting functions (no arg-guessing when they exist)
    if PlayerPet then
        for _, fn in ipairs({ "SetTarget", "SetTargetBulk" }) do
            if type(PlayerPet[fn]) == "function" then
                pcall(PlayerPet[fn], PlayerPet, b)
                pcall(PlayerPet[fn], PlayerPet, "Breakable", id)
            end
        end
    end
    if BreakFront and type(BreakFront.SetTarget) == "function" then
        pcall(BreakFront.SetTarget, BreakFront, b)
        pcall(BreakFront.SetTarget, BreakFront, id)
    end
    -- 2) raw remotes, best-effort shapes
    netFire("Fire", "Breakables_JoinPetBulk", id)
    netFire("Fire", "Breakables_JoinPetBulk", b)
    netFire("UnreliableFire", "Breakables_PlayerDealDamage", id)
    netFire("UnreliableFire", "Breakables_PlayerDealDamage", b)
end

-- ── teleport onto a breakable ────────────────────────────────────────────────
local function hopTo(b)
    local r, p = root(), partOf(b)
    if not (r and p) then return false end
    r.CFrame = CFrame.new(p.Position + Vector3.new(0, S.hoverStuds, 0))
    return true
end

-- ── optional: open inventory lootboxes ("take all items") ────────────────────
local function openLootboxes()
    if not Network or type(Network.Invoke) ~= "function" then return end
    -- best-effort: fire the open invoke; the game resolves which boxes you own.
    -- If your executor exposes the inventory, this is where UIDs would go.
    pcall(function() Network:Invoke("Lootbox_RequestOpen") end)
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmChests"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 280); main.Position = UDim2.new(0,20,0.5,-140)
main.BackgroundColor3 = Color3.fromRGB(18,20,28); main.BorderSizePixel = 0
main.Active = true; main.Draggable = true; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(120,220,140); stroke.Thickness = 1.5
local pad = Instance.new("UIPadding", main)
pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
local layoutU = Instance.new("UIListLayout", main); layoutU.Padding = UDim.new(0,6); layoutU.SortOrder = Enum.SortOrder.LayoutOrder

local function label(txt,h,c)
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,h or 18); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamMedium; l.TextSize=13; l.TextColor3=c or Color3.fromRGB(230,235,245)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; l.Text=txt; l.Parent=main; return l
end
local function button(txt,c)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,30); b.BackgroundColor3=c or Color3.fromRGB(45,120,70)
    b.BorderSizePixel=0; b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=Color3.fromRGB(255,255,255)
    b.Text=txt; b.Parent=main; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); return b
end

label("📦 Auto Farm Chests", 20, Color3.fromRGB(140,230,160))
local status = label("starting…", 30, Color3.fromRGB(150,220,150))

local autoBtn  = button("Auto Farm: ON", Color3.fromRGB(190,60,60))
local boxBtn   = button("Open Lootboxes: OFF", Color3.fromRGB(70,75,90))
local speedBtn = button("Hop speed: Normal", Color3.fromRGB(55,60,74))

local function setAuto(on)
    S.auto = on; autoBtn.Text = "Auto Farm: "..(on and "ON" or "OFF")
    autoBtn.BackgroundColor3 = on and Color3.fromRGB(190,60,60) or Color3.fromRGB(70,75,90)
end
autoBtn.Activated:Connect(function() setAuto(not S.auto) end)
boxBtn.Activated:Connect(function()
    S.openBoxes = not S.openBoxes
    boxBtn.Text = "Open Lootboxes: "..(S.openBoxes and "ON" or "OFF")
    boxBtn.BackgroundColor3 = S.openBoxes and Color3.fromRGB(60,110,180) or Color3.fromRGB(70,75,90)
end)
local speeds = { {"Safe",1.0}, {"Normal",0.6}, {"Fast",0.3} }
local speedIdx = 2
speedBtn.Activated:Connect(function()
    speedIdx = speedIdx % #speeds + 1
    S.hopDelay = speeds[speedIdx][2]
    speedBtn.Text = "Hop speed: "..speeds[speedIdx][1]
end)

UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then setAuto(not S.auto) end
end)

-- ── main farm loop ───────────────────────────────────────────────────────────
local MY = S.version
task.spawn(function()
    requires()
    while S.running and S.version == MY do
        if S.auto then
            requires()
            local list = scanBreakables()
            if #list == 0 then
                if status.Parent then status.Text = "no breakables found — waiting…" end
                task.wait(1)
            else
                local best = pickBest(list)
                if best then
                    local cls = tostring(best:GetAttribute("BreakableClass") or best.Name)
                    if hopTo(best) then
                        targetBreakable(best)
                        if status.Parent then
                            status.Text = string.format("farming: %s  (%d in world)", cls, #list)
                            status.TextColor3 = Color3.fromRGB(150,220,150)
                        end
                    end
                    -- sit on it briefly, re-targeting, so pets break it + lootbag magnets in
                    local t0 = os.clock()
                    while S.auto and S.running and S.version == MY and os.clock() - t0 < S.hopDelay do
                        local hp = best:GetAttribute("health") or best:GetAttribute("Health")
                        if best.Parent == nil or (type(hp) == "number" and hp <= 0) then break end
                        hopTo(best); targetBreakable(best)
                        task.wait(0.1)
                    end
                end
                if S.openBoxes then openLootboxes() end
            end
        else
            if status.Parent then status.Text = "paused (RightShift to resume)" end
            task.wait(0.3)
        end
    end
end)

requires()
setAuto(S.auto)
warn("[Auto Farm Chests] loaded — hops onto the best breakable, pets farm it, lootbags magnet into your inventory. RightShift toggles.")
