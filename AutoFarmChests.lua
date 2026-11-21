--!nocheck
--[[
============================================================================
 Auto Farm Chests v2  —  learn the real break call, then farm the best chests
 Built from the whole-game dump (PlaceId 98459174589830).
============================================================================
 WHY v1 DID NOTHING
 ---------------------------------------------------------------------------
  Pets only farm a breakable you have TARGETED, not one you merely stand near,
  and the exact target/damage remote args can't be read from a bytecode dump,
  so the guessed calls no-op'd. v2 stops guessing: it LEARNS the real call.

 HOW IT WORKS NOW
 ---------------------------------------------------------------------------
  * Breakables ("chests") live under workspace.__THINGS.Breakables, each with
    a BreakableID + BreakableClass attribute.
  * You click ONE chest normally. The script captures the exact remote the game
    fires (Breakables_JoinPetBulk / Breakables_PlayerDealDamage, …) and figures
    out which argument is the chest's BreakableID.
  * Then it auto-farms: picks the BEST chest, teleports onto it, and REPLAYS
    that same call with the best chest's ID swapped in — so your pets attack it
    exactly as if you'd clicked it. Broken chests drop lootbags that magnet
    into your inventory. It moves to the next best and loops.

 HOW TO USE
 ---------------------------------------------------------------------------
  1. Run it. Status: "LEARN: click any chest once".
  2. Click a chest in the world (just once).
  3. Status flips to "LEARNED ✓" and it starts farming the best chests.
  If it still does nothing, press "Diagnostics" and send me the F9 console.

 Damage/rewards are server-authoritative — this farms faster, it can't mint
 loot. The game has abuse detection; keep the hop speed sane.
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
S.hopDelay    = S.hopDelay   or 0.6
S.openBoxes   = S.openBoxes  or false
S.hoverStuds  = S.hoverStuds or 4
S.maxDist     = S.maxDist    or 2500     -- never teleport farther than this (stay in map)
S.teleport    = (S.teleport ~= false)    -- teleport onto chests; off = farm only chests near you
S.captured    = S.captured   or nil      -- { calls = {...} } learned break calls
S.version     = (S.version or 0) + 1

local TIER_RANK = {
    normal=1, common=1, uncommon=2, rare=3, epic=4, legendary=5,
    mythical=6, mythic=6, golden=7, gold=7, rainbow=8, void=9,
    event=10, nightmare=11, secret=12,
}

-- ── small utils ──────────────────────────────────────────────────────────────
local function pack(...) return { n = select("#", ...), ... } end
local function unpackn(t) return table.unpack(t, 1, t.n) end

local function character() return lp.Character end
local function root()
    local c = character()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart"))
end
local function partOf(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart") end
    return nil
end

-- a chest position is only usable if it's finite, not the origin, and near us
local function validPos(pos)
    if not pos then return false end
    if pos ~= pos then return false end                       -- NaN
    if pos.Magnitude < 1 then return false end                -- (0,0,0) template
    if math.abs(pos.Y) > 100000 then return false end         -- absurd height = out of map
    return true
end
local function distFromMe(pos)
    local r = root()
    if not r then return math.huge end
    return (pos - r.Position).Magnitude
end
local CollectionService = game:GetService("CollectionService")

-- read a breakable's id no matter the exact attribute name
local function idOf(b)
    local attrs = b:GetAttributes()
    -- exact common names first
    local v = attrs.BreakableID or attrs.BreakableUID or attrs.BreakableUniqueID
    if v ~= nil then return v end
    -- any attribute whose key looks like a breakable id / uid
    for k, val in pairs(attrs) do
        local lk = k:lower()
        if lk:find("breakable",1,true) and (lk:find("id",1,true) or lk:find("uid",1,true)) then return val end
    end
    -- else any "breakable*" attribute value at all (lets us at least detect it)
    for k, val in pairs(attrs) do
        if k:lower():find("breakable",1,true) then return val end
    end
    return nil
end

-- does this instance look like a breakable/chest?
local function isBreakable(d)
    local attrs = d:GetAttributes()
    for k in pairs(attrs) do
        if k:lower():find("breakable",1,true) then return true end
    end
    local n = d.Name:lower()
    if n:find("breakable",1,true) or n:find("chest",1,true) or n:find("crate",1,true) then return true end
    return false
end

-- walk up to the owning Model (so we score/teleport the whole chest, not a sub-part)
local function ownerModel(d)
    local m = d
    while m and m.Parent and m.Parent ~= Workspace do
        if m:IsA("Model") and idOf(m) ~= nil then return m end
        m = m.Parent
    end
    return (d:IsA("Model") and d) or d
end

local function scanBreakables()
    local out, seen = {}, {}
    local function add(d)
        local b = (idOf(d) ~= nil) and d or ownerModel(d)
        if b and not seen[b] then seen[b] = true; table.insert(out, b) end
    end
    -- 1) CollectionService tags that commonly mark interactables/breakables
    for _, tag in ipairs({ "Breakable","Breakables","Interactable","Chest","Chests","BreakableModel" }) do
        local ok, tagged = pcall(function() return CollectionService:GetTagged(tag) end)
        if ok and tagged then
            for _, d in ipairs(tagged) do
                if d:IsDescendantOf(Workspace) and isBreakable(d) then add(d) end
            end
        end
    end
    -- 2) full workspace sweep for anything breakable-ish
    if #out == 0 then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if isBreakable(d) then add(d) end
        end
    end
    -- keep only ones still alive
    local alive = {}
    for _, b in ipairs(out) do
        local hp = b:GetAttribute("health") or b:GetAttribute("Health")
        if hp == nil or (type(hp) == "number" and hp > 0) then table.insert(alive, b) end
    end
    return alive
end

local function scoreOf(b)
    local cls = tostring(b:GetAttribute("BreakableClass") or b:GetAttribute("BreakableType") or b.Name):lower()
    local tier = 1
    for word, rank in pairs(TIER_RANK) do if cls:find(word,1,true) and rank>tier then tier=rank end end
    local chestBonus = (cls:find("chest",1,true) or cls:find("crate",1,true) or cls:find("diamond",1,true)
        or cls:find("vault",1,true) or cls:find("lootb",1,true)) and 20 or 0
    local maxhp = tonumber(b:GetAttribute("maxHealth") or b:GetAttribute("MaxHealth") or b:GetAttribute("health") or 0) or 0
    local hpScore = (maxhp>0) and math.log10(maxhp+10) or 0
    return tier*1000 + chestBonus*100 + hpScore
end
local function pickBest(list)
    local best, bs
    for _, b in ipairs(list) do
        local p = partOf(b)
        if p and validPos(p.Position) then
            local d = distFromMe(p.Position)
            if d <= S.maxDist then
                -- tier/chest score first; among equals the NEAREST wins, and
                -- distance gently lowers score so we never cross the map for a
                -- marginally-better chest.
                local s = scoreOf(b) - d * 0.05
                if not bs or s>bs then best, bs = b, s end
            end
        end
    end
    return best
end

-- ── Network + capture of the real break call ─────────────────────────────────
local Network, PlayerPet, BreakFront
local function requires()
    pcall(function()
        local lib = ReplicatedStorage:WaitForChild("Library", 5)
        local client = lib and lib:FindFirstChild("Client")
        if client then
            local nm=client:FindFirstChild("Network");          if nm then Network   = Network   or require(nm) end
            local pp=client:FindFirstChild("PlayerPet");         if pp then PlayerPet = PlayerPet or require(pp) end
            local bf=client:FindFirstChild("BreakableFrontend"); if bf then BreakFront= BreakFront or require(bf) end
        end
    end)
end

local BREAK_NAMES = {
    Breakables_JoinPetBulk = true,
    Breakables_PlayerDealDamage = true,
    Breakables_LeavePetBulk = false,  -- learned but not replayed (it recalls pets)
}
-- is this a breakable call we care about? returns the event-name string or nil
local function breakNameIn(argl)
    for i=1,argl.n do
        local v = argl[i]
        if type(v)=="string" and BREAK_NAMES[v] ~= nil then return v, i end
    end
    return nil
end
-- find which arg index holds a BreakableID (matches a live chest's id)
local function findIdIndex(argl, liveIds)
    for i=1,argl.n do
        local v = argl[i]
        if (type(v)=="string" or type(v)=="number") and liveIds[v] then return i end
    end
    return nil
end

local function recordCall(info)
    S.captured = S.captured or { calls = {} }
    -- de-dupe by event name
    for _, c in ipairs(S.captured.calls) do
        if c.name == info.name then c.argl=info.argl; c.idIndex=info.idIndex; c.method=info.method; c.kind=info.kind; c.remote=info.remote; return end
    end
    table.insert(S.captured.calls, info)
end

local function liveIdSet()
    local s = {}
    for _, b in ipairs(scanBreakables()) do local id=idOf(b); if id~=nil then s[id]=true end end
    return s
end

local moduleHooked = false
local function installModuleHook()
    if not Network or moduleHooked then return end
    for _, m in ipairs({ "Fire","UnreliableFire","FireAsync","fire","Invoke" }) do
        local orig = rawget(Network, m)
        if type(orig)=="function" then
            local realOrig = orig
            Network[m] = function(a, ...)
                local isSelf = (a == Network)
                local argl = isSelf and pack(...) or pack(a, ...)
                local name = breakNameIn(argl)
                if name and BREAK_NAMES[name] then
                    local idIndex = findIdIndex(argl, liveIdSet())
                    recordCall({ kind="module", method=m, isSelf=isSelf, name=name, argl=argl, idIndex=idIndex })
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
    if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then return end
    local ncc = (type(newcclosure)=="function") and newcclosure or function(f) return f end
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", ncc(function(self, ...)
            local method = getnamecallmethod()
            if method=="FireServer" or method=="fireServer" then
                local argl = pack(...)
                local name = breakNameIn(argl)
                if name and BREAK_NAMES[name] then
                    local idIndex = findIdIndex(argl, liveIdSet())
                    recordCall({ kind="namecall", remote=self, name=name, argl=argl, idIndex=idIndex })
                end
            end
            return old(self, ...)
        end))
        namecallHooked = true
    end)
end

-- ── replay the learned call(s) against a target chest ────────────────────────
local function replayAt(targetId)
    local cap = S.captured
    if not cap or #cap.calls == 0 then return false end
    local any = false
    for _, c in ipairs(cap.calls) do
        if BREAK_NAMES[c.name] == true then  -- only replay the farming calls
            local argl = { n = c.argl.n }
            for i=1,c.argl.n do argl[i] = c.argl[i] end
            if c.idIndex then argl[c.idIndex] = targetId end
            if c.kind=="namecall" and typeof(c.remote)=="Instance" then
                any = pcall(function() c.remote:FireServer(unpackn(argl)) end) or any
            elseif c.kind=="module" and Network and type(Network[c.method])=="function" then
                if c.isSelf then any = pcall(function() Network[c.method](Network, unpackn(argl)) end) or any
                else any = pcall(function() Network[c.method](unpackn(argl)) end) or any end
            end
        end
    end
    return any
end

-- best-effort direct target (used as a fallback before anything is learned)
local function bestEffortTarget(b)
    local id = idOf(b)
    if PlayerPet then
        for _, fn in ipairs({ "SetTarget" }) do
            if type(PlayerPet[fn])=="function" then
                pcall(PlayerPet[fn], PlayerPet, b); pcall(PlayerPet[fn], PlayerPet, "Breakable", id)
            end
        end
    end
    if BreakFront and type(BreakFront.SetTarget)=="function" then
        pcall(BreakFront.SetTarget, BreakFront, b); pcall(BreakFront.SetTarget, BreakFront, id)
    end
end

-- ── teleport onto a chest (safe: never off the map) ──────────────────────────
local function hopTo(b)
    if not S.teleport then return true end              -- teleport disabled: farm in place
    local c, p = character(), partOf(b)
    if not (c and p) then return false end
    local pos = p.Position
    if not validPos(pos) then return false end          -- refuse bad / off-map targets
    if distFromMe(pos) > S.maxDist then return false end -- never fling across the map
    -- land on the chest's top surface, not inside it or in the void
    local topY = pos.Y + p.Size.Y/2
    if b:IsA("Model") then
        local ok, _, sz = pcall(function() return b:GetBoundingBox() end)
        if ok and sz then topY = pos.Y + sz.Y/2 end
    end
    local dest = Vector3.new(pos.X, topY + math.max(2, S.hoverStuds), pos.Z)
    pcall(function() c:PivotTo(CFrame.new(dest)) end)
    return true
end

-- ── optional: open inventory lootboxes ───────────────────────────────────────
local function openLootboxes()
    if Network and type(Network.Invoke)=="function" then
        pcall(function() Network:Invoke("Lootbox_RequestOpen") end)
    end
end

-- ── diagnostics ──────────────────────────────────────────────────────────────
local function diagnostics()
    requires()
    print("──────── Auto Farm Chests diagnostics ────────")
    -- how many instances carry ANY breakable-ish attribute, and what keys
    local withAttr, sampleKeys = 0, {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        for k in pairs(d:GetAttributes()) do
            if k:lower():find("breakable",1,true) then
                withAttr = withAttr + 1
                if #sampleKeys < 12 then sampleKeys[k] = true end
                break
            end
        end
    end
    local keyList = {}
    for k in pairs(sampleKeys) do table.insert(keyList, k) end
    print("instances with a 'breakable' attribute:", withAttr)
    print("attribute keys seen:", (#keyList>0) and table.concat(keyList, ", ") or "(none)")
    for _, tag in ipairs({ "Breakable","Breakables","Interactable","Chest","Chests" }) do
        local ok, tg = pcall(function() return CollectionService:GetTagged(tag) end)
        if ok and tg and #tg>0 then print("tag '"..tag.."':", #tg, "tagged") end
    end
    local list = scanBreakables()
    print("breakables found by scanner:", #list)
    for i=1, math.min(5,#list) do
        local b=list[i]
        local keys = {}
        for k,v in pairs(b:GetAttributes()) do table.insert(keys, k.."="..tostring(v)) end
        print(string.format("  [%d] %s  (%s)", i, b:GetFullName(), table.concat(keys, " ")))
    end
    print("Network resolved:", Network~=nil, " PlayerPet:", PlayerPet~=nil, " BreakableFrontend:", BreakFront~=nil)
    if Network then
        local methods = {}
        for _, m in ipairs({ "Fire","UnreliableFire","FireAsync","Invoke" }) do
            if type(rawget(Network,m))=="function" then table.insert(methods, m) end
        end
        print("Network methods:", table.concat(methods, ", "))
    end
    print("learned calls:", S.captured and #S.captured.calls or 0)
    if S.captured then for _,c in ipairs(S.captured.calls) do
        print("   ", c.name, "idIndex="..tostring(c.idIndex), "argc="..tostring(c.argl.n))
    end end
    print("hookmetamethod available:", type(hookmetamethod)=="function")
    print("──────────────────────────────────────────────")
end

-- ── GUI ───────────────────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "AutoFarmChests"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or lp:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(300, 300); main.Position = UDim2.new(0,20,0.5,-150)
main.BackgroundColor3 = Color3.fromRGB(18,20,28); main.BorderSizePixel = 0
main.Active=true; main.Draggable=true; main.Parent=gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0,10)
local stroke=Instance.new("UIStroke",main); stroke.Color=Color3.fromRGB(120,220,140); stroke.Thickness=1.5
local pad=Instance.new("UIPadding",main); pad.PaddingTop=UDim.new(0,10);pad.PaddingBottom=UDim.new(0,10);pad.PaddingLeft=UDim.new(0,10);pad.PaddingRight=UDim.new(0,10)
local lay=Instance.new("UIListLayout",main); lay.Padding=UDim.new(0,6); lay.SortOrder=Enum.SortOrder.LayoutOrder

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
local status = label("LEARN: click any chest once", 30, Color3.fromRGB(255,210,120))

local autoBtn  = button("Auto Farm: ON", Color3.fromRGB(190,60,60))
local tpBtn    = button("Teleport: ON (stays in map)", Color3.fromRGB(60,110,180))
local boxBtn   = button("Open Lootboxes: OFF", Color3.fromRGB(70,75,90))
local speedBtn = button("Hop speed: Normal", Color3.fromRGB(55,60,74))
local diagBtn  = button("Diagnostics (F9 console)", Color3.fromRGB(60,70,90))

tpBtn.Activated:Connect(function()
    S.teleport = not S.teleport
    tpBtn.Text = "Teleport: "..(S.teleport and "ON (stays in map)" or "OFF (farm nearby)")
    tpBtn.BackgroundColor3 = S.teleport and Color3.fromRGB(60,110,180) or Color3.fromRGB(70,75,90)
end)

local function setAuto(on)
    S.auto=on; autoBtn.Text="Auto Farm: "..(on and "ON" or "OFF")
    autoBtn.BackgroundColor3 = on and Color3.fromRGB(190,60,60) or Color3.fromRGB(70,75,90)
end
autoBtn.Activated:Connect(function() setAuto(not S.auto) end)
boxBtn.Activated:Connect(function()
    S.openBoxes=not S.openBoxes
    boxBtn.Text="Open Lootboxes: "..(S.openBoxes and "ON" or "OFF")
    boxBtn.BackgroundColor3 = S.openBoxes and Color3.fromRGB(60,110,180) or Color3.fromRGB(70,75,90)
end)
local speeds={ {"Safe",1.0},{"Normal",0.6},{"Fast",0.3} }; local si=2
speedBtn.Activated:Connect(function()
    si = si % #speeds + 1; S.hopDelay = speeds[si][2]; speedBtn.Text="Hop speed: "..speeds[si][1]
end)
diagBtn.Activated:Connect(function() diagnostics(); status.Text="diagnostics printed (F9)" end)
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.RightShift then setAuto(not S.auto) end
end)

-- ── loop ──────────────────────────────────────────────────────────────────────
local MY = S.version
task.spawn(function()
    requires(); installModuleHook(); installNamecallHook()
    while S.running and S.version==MY do
        if S.auto then
            requires(); installModuleHook()
            local list = scanBreakables()
            local learned = S.captured and #S.captured.calls>0
            if #list==0 then
                if status.Parent then status.Text="no chests found — press Diagnostics"; status.TextColor3=Color3.fromRGB(255,170,120) end
                task.wait(1)
            else
                local best = pickBest(list)
                if best then
                    local cls = tostring(best:GetAttribute("BreakableClass") or best.Name)
                    hopTo(best)
                    if learned then replayAt(idOf(best)) else bestEffortTarget(best) end
                    if status.Parent then
                        if learned then
                            status.Text=string.format("farming: %s  (%d chests)", cls, #list)
                            status.TextColor3=Color3.fromRGB(150,220,150)
                        else
                            status.Text="LEARN: click any chest once"
                            status.TextColor3=Color3.fromRGB(255,210,120)
                        end
                    end
                    local t0=os.clock()
                    while S.auto and S.running and S.version==MY and os.clock()-t0 < S.hopDelay do
                        local hp = best:GetAttribute("health") or best:GetAttribute("Health")
                        if best.Parent==nil or (type(hp)=="number" and hp<=0) then break end
                        hopTo(best)
                        if learned then replayAt(idOf(best)) else bestEffortTarget(best) end
                        task.wait(0.1)
                    end
                end
                if S.openBoxes then openLootboxes() end
            end
        else
            if status.Parent then status.Text="paused (RightShift to resume)" end
            task.wait(0.3)
        end
    end
end)

requires(); installModuleHook(); installNamecallHook(); setAuto(S.auto)
warn("[Auto Farm Chests] loaded — click a chest ONCE to teach it, then it farms the best chests. Press Diagnostics if nothing happens.")
