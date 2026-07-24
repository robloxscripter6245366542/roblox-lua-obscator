--[[
	Grow a Garden 2  |  Emerald  —  Full Edition
	==================================================================
	A complete feature hub for "Grow a Garden 2" (PlaceId 77085202503540),
	built on WindUI (https://github.com/Footagesus/WindUI, MIT) with an
	emerald-green theme.

	Everything that touches the game drives the game's own networking
	layer (ReplicatedStorage.SharedModules.Networking, a ByteNet-style
	"Packet" library). The remote table, argument order and the
	fruit-scan / plant / water / steal logic were all reconstructed from
	the live game dump, so calls mirror what the real client sends.

	Tabs:
	  Home · Auto Farm · Sell · Steal · Shop · Eggs & Pets · Tools ·
	  Weather & Codes · Social · Auction · Visuals (ESP) · Player · Settings

	Client-side automation intended for executors.
	==================================================================
]]

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local TeleportService    = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============================================================--
--  Load WindUI
--============================================================--
local WindUI
do
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(
			"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
		))()
	end)
	if not ok or not result then
		result = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"
		))()
	end
	WindUI = result
end

--============================================================--
--  Emerald theme
--============================================================--
local Emerald   = Color3.fromHex("#10B981")
local EmeraldHi = Color3.fromHex("#34D399")
local EmeraldLo = Color3.fromHex("#059669")
local Mint      = Color3.fromHex("#6EE7B7")

WindUI:AddTheme({
	Name = "Emerald",
	Accent     = Emerald,
	Dialog     = Color3.fromHex("#0B241C"),
	Text        = Color3.fromHex("#E6FBF3"),
	Placeholder = Color3.fromHex("#7FCBB0"),
	Background  = Color3.fromHex("#04120D"),
	Button      = Color3.fromHex("#0F3A2C"),
	Icon        = Color3.fromHex("#B8F5DE"),
	Toggle   = Emerald,
	Slider   = EmeraldHi,
	Checkbox = Emerald,
	ElementBackground = Color3.fromHex("#0A2A20"),
	ElementBackgroundTransparency = 0.30,
})
WindUI:SetTheme("Emerald")

--============================================================--
--  Networking
--============================================================--
local Net
do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
	end)
	if ok then Net = mod end
end

-- remote("A","B") -> packet object (walks the remote tree), or nil
local function remote(...)
	if not Net then return nil end
	local node = Net
	for _, key in ipairs({ ... }) do
		if type(node) ~= "table" then return nil end
		node = node[key]
	end
	return node
end

-- fire("A","B", args...) : leading string keys resolve the remote, the rest are payload.
-- Descends through category tables until it reaches a packet (a table owning a Fire method).
local function fire(...)
	if not Net then return end
	local args = { ... }
	local node, depth = Net, 0
	for i = 1, #args do
		if type(args[i]) == "string" and type(node) == "table" and node[args[i]] ~= nil then
			node = node[args[i]]
			depth = i
			if type(node) ~= "table" or type(node.Fire) == "function" then
				break -- reached a packet (has Fire) or a non-table value
			end
			-- otherwise it's a category table: keep descending
		else
			break
		end
	end
	if type(node) == "table" and type(node.Fire) == "function" then
		local payload = {}
		for j = depth + 1, #args do payload[#payload + 1] = args[j] end
		return select(2, pcall(function()
			return node:Fire(table.unpack(payload))
		end))
	end
end

-- invoke: fire a :Response remote and return the response value.
local function invoke(path, ...)
	local n = remote(table.unpack(path))
	if n and type(n.Fire) == "function" then
		local extra = { ... }
		local ok, res = pcall(function() return n:Fire(table.unpack(extra)) end)
		if ok then return res end
	end
	return nil
end

--============================================================--
--  Data
--============================================================--
local SeedNames = {
	"Carrot", "Strawberry", "Blueberry", "Tomato", "Corn", "Cactus",
	"Grape", "Pineapple", "Apple", "Banana", "Mango", "Coconut",
	"Cherry", "Plum", "Pomegranate", "Sunflower", "Tulip", "Bamboo",
	"Watermelon", "Dragon Fruit", "Star Fruit", "Horned Melon",
	"Mushroom", "Glow Mushroom", "Pepper", "Ghost Pepper", "Green Bean",
	"Venus Fly Trap", "Venom Spitter", "Poison Apple", "Moon Bloom",
	"Sun Bloom", "Eclipse Bloom", "Briar Rose", "Hypno Bloom",
	"Fire Fern", "Dragon's Breath", "Cinnamon Stick", "Romanesco",
	"Atlantic Giant Pumpkin", "Rocket Pop", "Baby Cactus", "Acorn",
	"Conifer Cone", "Amber Cranberry", "Gold", "Rainbow", "Mega",
}
local EggNames   = { "Common Egg", "Big Egg", "Mega Egg", "Rainbow Egg" }
local CrateNames = { "Common Crate", "Rare Crate", "Legendary Crate", "Mythical Crate" }

--============================================================--
--  Core helpers
--============================================================--
local function getCharacter()
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then return char, hrp, hum end
	end
	return nil
end

local function getPlayerPlot()
	local plotId = LocalPlayer:GetAttribute("PlotId")
	local gardens = Workspace:FindFirstChild("Gardens")
	if plotId and gardens then
		return gardens:FindFirstChild("Plot" .. tostring(plotId))
	end
	return nil
end

-- Enumerate this player's ripe / collectible fruit (returns id pairs).
local function scanCollectible()
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				local uid = tonumber(plant:GetAttribute("UserId"))
				local plantId = plant:GetAttribute("PlantId")
				if uid == myId and typeof(plantId) == "string" then
					local fruitsFolder = plant:FindFirstChild("Fruits")
					if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if typeof(fruitId) == "string" then
								local age    = fruit:GetAttribute("Age")
								local maxAge = fruit:GetAttribute("MaxAge")
								local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or (age >= maxAge)
								if ripe then out[#out + 1] = { plantId = plantId, fruitId = fruitId } end
							end
						end
					else
						out[#out + 1] = { plantId = plantId, fruitId = "" }
					end
				end
			end
		end
	end
	return out
end

-- Enumerate fruit belonging to OTHER players (for steal), returns {owner,plantId,fruitId}.
local function scanStealable(maxDist)
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	local _, hrp = getCharacter()
	if not gardens or not hrp then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				local uid = tonumber(plant:GetAttribute("UserId"))
				local plantId = plant:GetAttribute("PlantId")
				if uid and uid ~= myId and typeof(plantId) == "string" then
					local fruitsFolder = plant:FindFirstChild("Fruits")
					if fruitsFolder then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if typeof(fruitId) == "string" then
								local part = fruit:IsA("BasePart") and fruit or fruit:FindFirstChildWhichIsA("BasePart")
								local pos = part and part.Position or (fruit:IsA("Model") and fruit:GetPivot().Position)
								if not maxDist or (pos and (pos - hrp.Position).Magnitude <= maxDist) then
									out[#out + 1] = { owner = uid, plantId = plantId, fruitId = fruitId }
								end
							end
						end
					end
				end
			end
		end
	end
	return out
end

local function getToolsWithAttribute(attr)
	local tools = {}
	local function scan(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute(attr) ~= nil then
				tools[#tools + 1] = item
			end
		end
	end
	scan(LocalPlayer:FindFirstChild("Backpack"))
	scan(LocalPlayer.Character)
	return tools
end
local function getSeedTools() return getToolsWithAttribute("SeedTool") end
local function getWateringCans() return getToolsWithAttribute("WateringCan") end

local function getEquippedTool()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Tool")
end

local function equipTool(tool)
	local char, _, hum = getCharacter()
	if char and hum and tool and tool.Parent ~= char then
		hum:EquipTool(tool)
	end
end

local function getPlantPosition()
	local plot = getPlayerPlot()
	if not plot then return nil end
	local candidates = {}
	for _, tagged in ipairs(CollectionService:GetTagged("PlantArea")) do
		if tagged:IsDescendantOf(plot) and tagged:IsA("BasePart") then
			candidates[#candidates + 1] = tagged
		end
	end
	if #candidates == 0 then
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("BasePart") and d.Size.X > 4 and d.Size.Z > 4 then
				candidates[#candidates + 1] = d
			end
		end
	end
	if #candidates == 0 then return nil end
	local part = candidates[math.random(1, #candidates)]
	local offX = (math.random() - 0.5) * math.max(part.Size.X - 2, 0)
	local offZ = (math.random() - 0.5) * math.max(part.Size.Z - 2, 0)
	return part.Position + Vector3.new(offX, part.Size.Y / 2, offZ)
end

-- Enumerate this player's plant models (for watering / merging / ESP).
local function myPlantModels()
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				if tonumber(plant:GetAttribute("UserId")) == myId then
					out[#out + 1] = plant
				end
			end
		end
	end
	return out
end

local function modelPosition(inst)
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then
		if inst.PrimaryPart then return inst.PrimaryPart.Position end
		local ok, cf = pcall(function() return inst:GetPivot() end)
		if ok then return cf.Position end
	end
	local bp = inst:FindFirstChildWhichIsA("BasePart")
	return bp and bp.Position
end

--============================================================--
--  Window
--============================================================--
local Window = WindUI:CreateWindow({
	Title    = "Grow a Garden 2  |  Emerald",
	Folder   = "GrowAGarden2_Emerald",
	Icon     = "sprout",
	Size      = UDim2.fromOffset(600, 460),
	NewElements = true,
	HideSearchBar = false,
	Acrylic  = true,
	Transparent = true,
	Radius   = 18,
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = "Grow a Garden 2",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		Enabled = true,
		Draggable = true,
		Color = ColorSequence.new(EmeraldHi, EmeraldLo),
	},
	Topbar = { Height = 42, ButtonsType = "Mac" },
})
Window:Tag({ Title = "v" .. tostring(WindUI.Version), Color = EmeraldLo })
Window:Tag({ Title = "Full Edition", Color = Emerald })

--============================================================--
--  State + loop manager
--============================================================--
local State = {}
local Loops = {}
local function startLoop(name, flagKey, delayKey, body)
	if Loops[name] then return end
	Loops[name] = task.spawn(function()
		while State[flagKey] do
			pcall(body)
			task.wait(State[delayKey] or 0.5)
		end
		Loops[name] = nil
	end)
end

--============================================================--
--  TAB: Home
--============================================================--
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })
HomeTab:Section({ Title = "Welcome" })
HomeTab:Paragraph({
	Title = "Grow a Garden 2 — Emerald · Full Edition",
	Desc  = "Auto-farm, steal, shop, eggs & pets, tools, weather, social, "
		.. "auction and a full ESP/visuals suite — all driving the game's own remotes.",
	Image = "sprout",
})
do
	HomeTab:Section({ Title = "Live status" })
	local statsPara = HomeTab:Paragraph({ Title = "Session", Desc = "Loading…" })
	task.spawn(function()
		while true do
			local plot = getPlayerPlot()
			statsPara:SetDesc(string.format(
				"Plot: %s   •   Ripe: %d   •   Seed tools: %d   •   Networking: %s",
				plot and plot.Name or "unknown",
				#scanCollectible(), #getSeedTools(), Net and "loaded" or "unavailable"
			))
			task.wait(2)
		end
	end)
end
HomeTab:Button({
	Title = "Rejoin server",
	Callback = function()
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
	end,
})

--============================================================--
--  TAB: Auto Farm
--============================================================--
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "leaf" })

FarmTab:Section({ Title = "Harvest" })
State.autoCollect, State.collectDelay = false, 0.4
FarmTab:Toggle({
	Title = "Auto-Collect Fruit",
	Desc  = "Harvests every ripe fruit on your plot.",
	Value = false,
	Callback = function(on)
		State.autoCollect = on
		if on then startLoop("collect", "autoCollect", "collectDelay", function()
			for _, e in ipairs(scanCollectible()) do fire("Garden", "CollectFruit", e.plantId, e.fruitId) end
		end) end
	end,
})
FarmTab:Slider({ Title = "Collect interval", Step = 0.1, Value = { Min = 0.1, Max = 5, Default = 0.4 },
	Callback = function(v) State.collectDelay = v end })

FarmTab:Section({ Title = "Plant" })
State.plantSeeds = {}
FarmTab:Dropdown({
	Title = "Seeds to auto-plant", Values = SeedNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local set = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do set[s] = true end elseif sel then set[sel] = true end
		State.plantSeeds = set
	end,
})
State.autoPlant, State.plantDelay = false, 0.6
FarmTab:Toggle({
	Title = "Auto-Plant",
	Desc  = "Equips seed tools and plants across your plot.",
	Value = false,
	Callback = function(on)
		State.autoPlant = on
		if on then startLoop("plant", "autoPlant", "plantDelay", function()
			for _, tool in ipairs(getSeedTools()) do
				local seedName = tool:GetAttribute("SeedTool")
				if next(State.plantSeeds) == nil or State.plantSeeds[seedName] then
					local pos = getPlantPosition()
					if pos then equipTool(tool); task.wait(0.05); fire("Plant", "PlantSeed", pos, seedName, tool) end
				end
			end
		end) end
	end,
})
FarmTab:Slider({ Title = "Plant interval", Step = 0.1, Value = { Min = 0.2, Max = 5, Default = 0.6 },
	Callback = function(v) State.plantDelay = v end })

FarmTab:Section({ Title = "Water" })
State.autoWater, State.waterDelay = false, 1
FarmTab:Toggle({
	Title = "Auto-Water Plants",
	Desc  = "Equips a watering can and waters your plants (boosts growth).",
	Value = false,
	Callback = function(on)
		State.autoWater = on
		if on then startLoop("water", "autoWater", "waterDelay", function()
			local cans = getWateringCans()
			if #cans == 0 then return end
			local can = cans[1]
			local attr = can:GetAttribute("WateringCan")
			equipTool(can)
			for _, plant in ipairs(myPlantModels()) do
				local pos = modelPosition(plant)
				if pos then fire("WateringCan", "UseWateringCan", pos - Vector3.new(0, 0.3, 0), attr, can); task.wait(0.05) end
			end
		end) end
	end,
})
FarmTab:Slider({ Title = "Water interval", Step = 0.5, Value = { Min = 0.5, Max = 15, Default = 1 },
	Callback = function(v) State.waterDelay = v end })

FarmTab:Section({ Title = "Grow-All & Merge" })
State.autoGrowAll, State.growAllDelay = false, 30
FarmTab:Toggle({
	Title = "Auto Grow-All",
	Value = false,
	Callback = function(on)
		State.autoGrowAll = on
		if on then startLoop("growall", "autoGrowAll", "growAllDelay", function()
			local r = remote("Garden", "RequestGrowAllData")
			if r and r.Fire then pcall(function() r:Fire() end) end
		end) end
	end,
})
FarmTab:Slider({ Title = "Grow-All interval", Step = 1, Value = { Min = 5, Max = 120, Default = 30 },
	Callback = function(v) State.growAllDelay = v end })

--============================================================--
--  TAB: Sell
--============================================================--
local SellTab = Window:Tab({ Title = "Sell", Icon = "coins" })
SellTab:Section({ Title = "Selling" })
SellTab:Button({ Title = "Sell All Now", Desc = "Sells inventory to the nearest NPC.",
	Callback = function() fire("NPCS", "SellAll"); WindUI:Notify({ Title = "Sell All", Content = "Requested", Icon = "coins", Duration = 3 }) end })
SellTab:Button({ Title = "Preview Sell All",
	Callback = function()
		local res = invoke({ "NPCS", "PreviewSellAll" })
		WindUI:Notify({ Title = "Preview", Content = "Result: " .. tostring(res), Icon = "eye", Duration = 4 })
	end })
State.autoSell, State.sellDelay = false, 30
SellTab:Toggle({ Title = "Auto-Sell All", Desc = "Stand near a sell NPC.", Value = false,
	Callback = function(on)
		State.autoSell = on
		if on then startLoop("sell", "autoSell", "sellDelay", function() fire("NPCS", "SellAll") end) end
	end })
SellTab:Slider({ Title = "Auto-Sell interval", Step = 5, Value = { Min = 5, Max = 300, Default = 30 },
	Callback = function(v) State.sellDelay = v end })

--============================================================--
--  TAB: Steal
--============================================================--
local StealTab = Window:Tab({ Title = "Steal", Icon = "swords" })
StealTab:Section({ Title = "Fruit Steal" })
StealTab:Paragraph({ Title = "How it works", Desc = "Scans other players' gardens for fruit near you and steals it via the game's Steal remote (BeginSteal → CompleteSteal)." })
State.stealRange = 120
StealTab:Slider({ Title = "Steal range (studs)", Step = 5, Value = { Min = 20, Max = 400, Default = 120 },
	Callback = function(v) State.stealRange = v end })
StealTab:Button({ Title = "Steal Nearby Once",
	Callback = function()
		local list = scanStealable(State.stealRange)
		for _, e in ipairs(list) do
			fire("Steal", "BeginSteal", e.owner, e.plantId, e.fruitId)
			fire("Steal", "CompleteSteal")
			task.wait(0.1)
		end
		WindUI:Notify({ Title = "Steal", Content = ("Attempted %d"):format(#list), Icon = "swords", Duration = 3 })
	end })
State.autoSteal, State.stealDelay = false, 1
StealTab:Toggle({ Title = "Auto-Steal", Value = false,
	Callback = function(on)
		State.autoSteal = on
		if on then startLoop("steal", "autoSteal", "stealDelay", function()
			for _, e in ipairs(scanStealable(State.stealRange)) do
				fire("Steal", "BeginSteal", e.owner, e.plantId, e.fruitId)
				fire("Steal", "CompleteSteal")
				task.wait(0.08)
			end
		end) end
	end })
StealTab:Slider({ Title = "Auto-Steal interval", Step = 0.5, Value = { Min = 0.5, Max = 10, Default = 1 },
	Callback = function(v) State.stealDelay = v end })

--============================================================--
--  TAB: Shop
--============================================================--
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
ShopTab:Section({ Title = "Seed Shop" })
State.buySeedList, State.autoBuySeeds, State.buySeedDelay = {}, false, 5
ShopTab:Dropdown({ Title = "Seeds to auto-buy", Values = SeedNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local list = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do list[#list + 1] = s end elseif sel then list[1] = sel end
		State.buySeedList = list
	end })
ShopTab:Toggle({ Title = "Auto-Buy Seeds", Value = false,
	Callback = function(on)
		State.autoBuySeeds = on
		if on then startLoop("buyseeds", "autoBuySeeds", "buySeedDelay", function()
			for _, seed in ipairs(State.buySeedList) do fire("SeedShop", "PurchaseSeed", seed); task.wait(0.15) end
		end) end
	end })
ShopTab:Slider({ Title = "Buy interval", Step = 1, Value = { Min = 1, Max = 60, Default = 5 },
	Callback = function(v) State.buySeedDelay = v end })
ShopTab:Button({ Title = "Buy Selected Once",
	Callback = function() for _, seed in ipairs(State.buySeedList) do fire("SeedShop", "PurchaseSeed", seed); task.wait(0.15) end end })

ShopTab:Section({ Title = "Gear Shop" })
ShopTab:Input({ Title = "Buy gear (exact name)", Placeholder = "e.g. Watering Can",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "PurchaseGear", t) end end })
ShopTab:Input({ Title = "Equip gear (exact name)", Placeholder = "gear name",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "EquipGear", t) end end })
ShopTab:Input({ Title = "Unequip gear (exact name)", Placeholder = "gear name",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "UnequipGear", t) end end })

ShopTab:Section({ Title = "Crates & Seed Packs" })
ShopTab:Dropdown({ Title = "Buy crate", Values = CrateNames, Value = nil, AllowNone = true,
	Callback = function(sel) if sel and sel ~= "" then fire("CrateShop", "PurchaseCrate", sel) end end })
ShopTab:Input({ Title = "Open seed pack (id/name)", Placeholder = "seed pack id",
	Callback = function(t) if t and t ~= "" then invoke({ "SeedPack", "OpenSeedPack" }, t) end end })

--============================================================--
--  TAB: Eggs & Pets
--============================================================--
local EggTab = Window:Tab({ Title = "Eggs & Pets", Icon = "egg" })
EggTab:Section({ Title = "Eggs" })
State.openEggList, State.autoOpenEgg, State.eggDelay = {}, false, 3
EggTab:Dropdown({ Title = "Eggs to auto-open", Values = EggNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local list = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do list[#list + 1] = s end elseif sel then list[1] = sel end
		State.openEggList = list
	end })
EggTab:Toggle({ Title = "Auto-Open Eggs", Value = false,
	Callback = function(on)
		State.autoOpenEgg = on
		if on then startLoop("eggs", "autoOpenEgg", "eggDelay", function()
			for _, egg in ipairs(State.openEggList) do invoke({ "Egg", "OpenEgg" }, egg); task.wait(0.25) end
		end) end
	end })
EggTab:Slider({ Title = "Egg interval", Step = 1, Value = { Min = 1, Max = 30, Default = 3 },
	Callback = function(v) State.eggDelay = v end })

EggTab:Section({ Title = "Wild Pets" })
State.autoTame, State.tameDelay, State.tameRange = false, 1, 150
EggTab:Toggle({ Title = "Auto-Tame Wild Pets", Desc = "Tames nearby wild pets (CollectionService 'WildPet').", Value = false,
	Callback = function(on)
		State.autoTame = on
		if on then startLoop("tame", "autoTame", "tameDelay", function()
			local _, hrp = getCharacter(); if not hrp then return end
			local tagged = CollectionService:GetTagged("WildPet")
			if #tagged == 0 then
				local wp = Workspace:FindFirstChild("WildPets")
				if wp then tagged = wp:GetChildren() end
			end
			for _, pet in ipairs(tagged) do
				local pos = modelPosition(pet)
				if pos and (pos - hrp.Position).Magnitude <= State.tameRange then
					fire("Pets", "WildPetTame", pet); task.wait(0.1)
				end
			end
		end) end
	end })
EggTab:Slider({ Title = "Tame range", Step = 10, Value = { Min = 20, Max = 500, Default = 150 },
	Callback = function(v) State.tameRange = v end })

EggTab:Section({ Title = "Pets" })
EggTab:Input({ Title = "Equip pet by name", Placeholder = "exact pet name",
	Callback = function(t) if t and t ~= "" then fire("Pets", "RequestEquipByName", t) end end })
EggTab:Input({ Title = "Unequip pet by name", Placeholder = "exact pet name",
	Callback = function(t) if t and t ~= "" then fire("Pets", "RequestUnequipByName", t) end end })
EggTab:Button({ Title = "Purchase Pet Slot", Callback = function() fire("Pets", "RequestPurchasePetSlot") end })
EggTab:Button({ Title = "Snap Pets To Me",
	Callback = function() local _, hrp = getCharacter(); if hrp then fire("Pets", "SnapPets", hrp.Position) end end })

--============================================================--
--  TAB: Tools / Abilities
--============================================================--
local ToolTab = Window:Tab({ Title = "Tools", Icon = "wand" })
ToolTab:Section({ Title = "Targeted tools" })
ToolTab:Paragraph({ Title = "Note", Desc = "Equip the matching tool first. Actions fire at the nearest other player." })

local function nearestPlayer()
	local _, hrp = getCharacter(); if not hrp then return nil end
	local best, bestD
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local h = p.Character:FindFirstChild("HumanoidRootPart")
			if h then local d = (h.Position - hrp.Position).Magnitude; if not bestD or d < bestD then best, bestD = p, d end end
		end
	end
	return best
end

ToolTab:Button({ Title = "Freeze Ray → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("FreezeRay", "Fire", p.Character.HumanoidRootPart.Position, t) end
	end })
ToolTab:Button({ Title = "Strawberry Sniper → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("StrawberrySniper", "Fire", p.Character.HumanoidRootPart.Position, p.Character, t) end
	end })
ToolTab:Button({ Title = "Grappling Hook → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("GrapplingHook", "Fire", p.Character.HumanoidRootPart.Position, t) end
	end })
ToolTab:Button({ Title = "Power Hose → nearest",
	Callback = function()
		local p = nearestPlayer()
		if p and p.Character then fire("PowerHose", "Activate", p.Character.HumanoidRootPart) end
	end })
ToolTab:Button({ Title = "Bull Horn Blast",
	Callback = function() local _, hrp = getCharacter(); if hrp then fire("BullHorn", "Blast", hrp.Position) end end })
ToolTab:Button({ Title = "Flashbang", Callback = function() fire("Flashbang", "Flashbang") end })
ToolTab:Button({ Title = "Swing Shovel", Callback = function() local t = getEquippedTool(); if t then fire("Shovel", "SwingShovel", t) end end })
ToolTab:Button({ Title = "Swing Crowbar", Callback = function() fire("Crowbar", "SwingCrowbar") end })

ToolTab:Section({ Title = "Fruit magnet" })
ToolTab:Button({ Title = "Activate held Magnet on me",
	Callback = function() local t = getEquippedTool(); if t then fire("FruitMagnet", "Activate", t, 60, 1) end end })

--============================================================--
--  TAB: Weather & Codes
--============================================================--
local WeatherTab = Window:Tab({ Title = "Weather", Icon = "cloud" })
WeatherTab:Section({ Title = "Redeem codes" })
WeatherTab:Input({ Title = "Redeem code", Placeholder = "enter code",
	Callback = function(t)
		if t and t ~= "" then
			local res = invoke({ "Settings", "SubmitCode" }, t)
			WindUI:Notify({ Title = "Code", Content = tostring(res) ~= "nil" and ("Result: " .. tostring(res)) or "Submitted", Icon = "gift", Duration = 4 })
		end
	end })

WeatherTab:Section({ Title = "Weather staves (equip first)" })
WeatherTab:Button({ Title = "Weather Staff — Trigger", Callback = function() fire("WeatherStaff", "TriggerWeather") end })
WeatherTab:Button({ Title = "Wind Staff — Tornado", Callback = function() fire("WindStaff", "TriggerTornado") end })

WeatherTab:Section({ Title = "Weather machine" })
WeatherTab:Button({ Title = "Signal Entered Machine",
	Callback = function() fire("WeatherMachine", "PlayerEntered", tostring(LocalPlayer.UserId), "") end })

WeatherTab:Section({ Title = "Notifications" })
State.weatherNotify = true
WeatherTab:Toggle({ Title = "Notify on weather events", Value = true,
	Callback = function(on) State.weatherNotify = on end })
do
	local events = { "RainStart","BloodmoonStart","EclipseStart","BlizzardStart","NightStart","RainbowStart","LightningStart" }
	for _, ev in ipairs(events) do
		local r = remote("WeatherEffects", ev)
		if r and r.OnClientEvent then
			pcall(function()
				r.OnClientEvent:Connect(function()
					if State.weatherNotify then
						WindUI:Notify({ Title = "Weather", Content = ev:gsub("Start", "") .. " started!", Icon = "cloud-lightning", Duration = 5 })
					end
				end)
			end)
		end
	end
end

--============================================================--
--  TAB: Social
--============================================================--
local SocialTab = Window:Tab({ Title = "Social", Icon = "users" })
SocialTab:Section({ Title = "Mailbox" })
SocialTab:Button({ Title = "Claim All Mail", Callback = function() fire("Mailbox", "ClaimAll"); WindUI:Notify({ Title = "Mailbox", Content = "Claimed", Icon = "mail", Duration = 3 }) end })
State.autoMailbox, State.mailboxDelay = false, 60
SocialTab:Toggle({ Title = "Auto-Claim Mailbox", Value = false,
	Callback = function(on)
		State.autoMailbox = on
		if on then startLoop("mailbox", "autoMailbox", "mailboxDelay", function() fire("Mailbox", "ClaimAll") end) end
	end })
SocialTab:Slider({ Title = "Mailbox interval", Step = 5, Value = { Min = 10, Max = 300, Default = 60 },
	Callback = function(v) State.mailboxDelay = v end })

SocialTab:Section({ Title = "Guild" })
SocialTab:Button({ Title = "Show My Guild",
	Callback = function()
		local g = invoke({ "Guild", "GetMyGuild" })
		WindUI:Notify({ Title = "Guild", Content = g and (typeof(g) == "table" and (g.Name or "In a guild") or tostring(g)) or "No guild", Icon = "shield", Duration = 5 })
	end })

SocialTab:Section({ Title = "Gifting" })
State.giftTarget = nil
SocialTab:Input({ Title = "Gift target UserId", Placeholder = "numeric UserId",
	Callback = function(t) State.giftTarget = tonumber(t) end })
SocialTab:Button({ Title = "Send held item as gift",
	Callback = function()
		local t = getEquippedTool()
		if State.giftTarget and t then fire("Gifting", "Send", State.giftTarget, t.Name, t:GetAttribute("ItemId") or "") end
	end })

SocialTab:Section({ Title = "Garden" })
SocialTab:Button({ Title = "Expand Garden",
	Callback = function() local r = remote("Actions", "ExpandGarden"); if r and r.Fire then pcall(function() r:Fire() end) end end })

SocialTab:Section({ Title = "Pilgrim" })
SocialTab:Button({ Title = "Submit Delivery", Callback = function() local r = remote("Pilgrim", "SubmitDelivery"); if r and r.Fire then pcall(function() r:Fire() end) end end })
SocialTab:Button({ Title = "Claim Reward", Callback = function() local r = remote("Pilgrim", "ClaimReward"); if r and r.Fire then pcall(function() r:Fire() end) end end })

--============================================================--
--  TAB: Auction
--============================================================--
local AuctionTab = Window:Tab({ Title = "Auction", Icon = "gavel" })
AuctionTab:Section({ Title = "Auctioneer" })
AuctionTab:Button({ Title = "Request Snapshot",
	Callback = function()
		local snap = invoke({ "Auctioneer", "RequestSnapshot" })
		WindUI:Notify({ Title = "Auction", Content = snap and "Snapshot received" or "No data", Icon = "gavel", Duration = 4 })
	end })
State.auctionLot, State.auctionPrice = "", 0
AuctionTab:Input({ Title = "Lot id", Placeholder = "lot id", Callback = function(t) State.auctionLot = t end })
AuctionTab:Input({ Title = "Bid price", Placeholder = "amount", Callback = function(t) State.auctionPrice = tonumber(t) or 0 end })
AuctionTab:Button({ Title = "Purchase Lot",
	Callback = function()
		if State.auctionLot ~= "" then fire("Auctioneer", "PurchaseLot", State.auctionLot, State.auctionPrice) end
	end })

--============================================================--
--  TAB: Visuals (ESP)
--============================================================--
local ESPTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

-- ESP manager: keeps Highlight + BillboardGui instances keyed by target.
local ESP = { fruit = {}, players = {}, pets = {}, eggs = {} }
local function clearGroup(group)
	for k, obj in pairs(group) do
		if typeof(obj) == "Instance" then obj:Destroy() end
		group[k] = nil
	end
end
local function makeHighlight(adornee, fill, outline)
	local h = Instance.new("Highlight")
	h.FillColor = fill
	h.OutlineColor = outline or Color3.new(1, 1, 1)
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = adornee
	return h
end
local function makeLabel(adornee, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 26)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = adornee
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = color or Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text = text
	lbl.Parent = bb
	bb.Parent = adornee
	return bb
end

State.espFruit, State.espPlayers, State.espPets, State.espEggs = false, false, false, false

ESPTab:Section({ Title = "Farm ESP" })
ESPTab:Toggle({ Title = "Ripe Fruit ESP", Desc = "Green highlight on fruit ready to collect.", Value = false,
	Callback = function(on) State.espFruit = on; if not on then clearGroup(ESP.fruit) end end })
ESPTab:Toggle({ Title = "Egg ESP", Value = false,
	Callback = function(on) State.espEggs = on; if not on then clearGroup(ESP.eggs) end end })
ESPTab:Toggle({ Title = "Pet ESP", Value = false,
	Callback = function(on) State.espPets = on; if not on then clearGroup(ESP.pets) end end })

ESPTab:Section({ Title = "Player ESP" })
ESPTab:Toggle({ Title = "Player ESP", Desc = "Highlight + name/distance on other players.", Value = false,
	Callback = function(on) State.espPlayers = on; if not on then clearGroup(ESP.players) end end })

-- ESP render loop
task.spawn(function()
	while true do
		pcall(function()
			local _, hrp = getCharacter()
			-- Fruit ESP
			if State.espFruit then
				local gardens = Workspace:FindFirstChild("Gardens")
				local seen = {}
				if gardens then
					for _, garden in ipairs(gardens:GetChildren()) do
						local plants = garden:FindFirstChild("Plants")
						if plants then
							for _, plant in ipairs(plants:GetChildren()) do
								local fruits = plant:FindFirstChild("Fruits")
								if fruits then
									for _, fruit in ipairs(fruits:GetChildren()) do
										local age, maxAge = fruit:GetAttribute("Age"), fruit:GetAttribute("MaxAge")
										local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or age >= maxAge
										if ripe and (fruit:IsA("Model") or fruit:IsA("BasePart")) then
											seen[fruit] = true
											if not ESP.fruit[fruit] then ESP.fruit[fruit] = makeHighlight(fruit, EmeraldHi, Emerald) end
										end
									end
								end
							end
						end
					end
				end
				for inst in pairs(ESP.fruit) do if not seen[inst] or not inst.Parent then if ESP.fruit[inst] then ESP.fruit[inst]:Destroy() end; ESP.fruit[inst] = nil end end
			end
			-- Egg ESP
			if State.espEggs then
				local seen = {}
				for _, egg in ipairs(CollectionService:GetTagged("Egg")) do
					if egg:IsA("Model") or egg:IsA("BasePart") then
						seen[egg] = true
						if not ESP.eggs[egg] then ESP.eggs[egg] = makeHighlight(egg, Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 170, 0)) end
					end
				end
				for inst in pairs(ESP.eggs) do if not seen[inst] or not inst.Parent then ESP.eggs[inst]:Destroy(); ESP.eggs[inst] = nil end end
			end
			-- Pet ESP
			if State.espPets then
				local seen = {}
				local pools = { CollectionService:GetTagged("WildPet") }
				local wp = Workspace:FindFirstChild("WildPets"); if wp then pools[#pools + 1] = wp:GetChildren() end
				for _, pool in ipairs(pools) do
					for _, pet in ipairs(pool) do
						if pet:IsA("Model") then
							seen[pet] = true
							if not ESP.pets[pet] then ESP.pets[pet] = makeHighlight(pet, Mint, Color3.new(1, 1, 1)) end
						end
					end
				end
				for inst in pairs(ESP.pets) do if not seen[inst] or not inst.Parent then ESP.pets[inst]:Destroy(); ESP.pets[inst] = nil end end
			end
			-- Player ESP
			if State.espPlayers then
				local seen = {}
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character then
						local char = p.Character
						local h = char:FindFirstChild("HumanoidRootPart")
						if h then
							seen[p] = true
							local rec = ESP.players[p]
							if not rec then
								rec = { hl = makeHighlight(char, Color3.fromRGB(255, 80, 80), Color3.new(1, 1, 1)), bb = makeLabel(h, p.Name, Color3.fromRGB(255, 120, 120)) }
								ESP.players[p] = rec
							else
								if rec.hl.Adornee ~= char then rec.hl.Adornee = char; rec.hl.Parent = char end
								local dist = hrp and math.floor((h.Position - hrp.Position).Magnitude) or 0
								local lbl = rec.bb:FindFirstChildOfClass("TextLabel")
								if lbl then lbl.Text = string.format("%s  [%dm]", p.Name, dist) end
							end
						end
					end
				end
				for p, rec in pairs(ESP.players) do
					if not seen[p] then
						if rec.hl then rec.hl:Destroy() end
						if rec.bb then rec.bb:Destroy() end
						ESP.players[p] = nil
					end
				end
			end
		end)
		task.wait(0.5)
	end
end)

ESPTab:Section({ Title = "World" })
State.fullbright, State.noFog = false, false
local savedLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient }
ESPTab:Toggle({ Title = "Fullbright", Value = false,
	Callback = function(on)
		State.fullbright = on
		if on then
			Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		else
			Lighting.Brightness = savedLighting.Brightness; Lighting.ClockTime = savedLighting.ClockTime
			Lighting.GlobalShadows = savedLighting.GlobalShadows; Lighting.Ambient = savedLighting.Ambient
		end
	end })
ESPTab:Toggle({ Title = "No Fog", Value = false,
	Callback = function(on)
		State.noFog = on
		Lighting.FogEnd = on and 1e9 or savedLighting.FogEnd
	end })

--============================================================--
--  TAB: Player
--============================================================--
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
PlayerTab:Section({ Title = "Movement" })
local defaultWS, defaultJP = 16, 50
PlayerTab:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 350, Default = 16 },
	Callback = function(v) defaultWS = v; local _, _, hum = getCharacter(); if hum then hum.WalkSpeed = v end end })
PlayerTab:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 },
	Callback = function(v) defaultJP = v; local _, _, hum = getCharacter(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end })
State.infJump = false
PlayerTab:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(on) State.infJump = on end })
UserInputService.JumpRequest:Connect(function()
	if State.infJump then local _, _, hum = getCharacter(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

State.noclip = false
PlayerTab:Toggle({ Title = "Noclip", Desc = "Walk through walls / plants.", Value = false,
	Callback = function(on) State.noclip = on end })
RunService.Stepped:Connect(function()
	if State.noclip then
		local char = LocalPlayer.Character
		if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
	end
end)

State.fly, State.flySpeed = false, 60
local flyBV, flyBG
PlayerTab:Toggle({ Title = "Fly", Desc = "WASD + Space/Shift. Toggle off to stop.", Value = false,
	Callback = function(on)
		State.fly = on
		local _, hrp = getCharacter()
		if on and hrp then
			flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
			flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9); flyBG.P = 1e4; flyBG.Parent = hrp
		else
			if flyBV then flyBV:Destroy(); flyBV = nil end
			if flyBG then flyBG:Destroy(); flyBG = nil end
		end
	end })
PlayerTab:Slider({ Title = "Fly speed", Step = 5, Value = { Min = 10, Max = 300, Default = 60 },
	Callback = function(v) State.flySpeed = v end })
RunService.RenderStepped:Connect(function()
	if State.fly and flyBV and flyBG then
		local _, hrp = getCharacter()
		if not hrp then return end
		flyBG.CFrame = Camera.CFrame
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
		flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * State.flySpeed
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		task.wait(0.5)
		pcall(function()
			hum.WalkSpeed = defaultWS
			if defaultJP ~= 50 then hum.UseJumpPower = true; hum.JumpPower = defaultJP end
		end)
	end
end)

PlayerTab:Section({ Title = "Teleport" })
PlayerTab:Button({ Title = "To My Plot",
	Callback = function()
		local _, hrp = getCharacter(); local plot = getPlayerPlot()
		local spawn = plot and plot:FindFirstChild("SpawnPoint")
		if hrp and spawn and spawn:IsA("BasePart") then hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
	end })
PlayerTab:Button({ Title = "To Nearest Sell NPC",
	Callback = function()
		local _, hrp = getCharacter(); if not hrp then return end
		local best, bestD
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (obj.Name == "SellPart" or obj.Name == "Steven" or (obj.Parent and tostring(obj.Parent.Name):find("Sell"))) then
				local d = (obj.Position - hrp.Position).Magnitude; if not bestD or d < bestD then best, bestD = obj, d end
			end
		end
		if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 4)) else WindUI:Notify({ Title = "Teleport", Content = "No sell NPC found", Icon = "map-pin", Duration = 3 }) end
	end })

PlayerTab:Section({ Title = "Anti-AFK" })
State.antiAfk = false
PlayerTab:Toggle({ Title = "Anti-AFK", Value = false, Callback = function(on) State.antiAfk = on end })
do
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			if State.antiAfk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
		end)
	end
end

--============================================================--
--  TAB: Settings
--============================================================--
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
SettingsTab:Section({ Title = "Interface" })
SettingsTab:Toggle({ Title = "Translucent background", Value = true,
	Callback = function(on) pcall(function() Window:SetBackgroundTransparency(on and 0.3 or 0) end) end })
SettingsTab:Button({ Title = "Remote categories loaded",
	Callback = function()
		local n = 0; if Net then for _ in pairs(Net) do n += 1 end end
		WindUI:Notify({ Title = "Networking", Content = ("%d categories"):format(n), Icon = "network", Duration = 4 })
	end })
SettingsTab:Button({ Title = "Stop ALL automation",
	Callback = function()
		for k in pairs(State) do if type(State[k]) == "boolean" then State[k] = false end end
		clearGroup(ESP.fruit); clearGroup(ESP.eggs); clearGroup(ESP.pets)
		for p, rec in pairs(ESP.players) do if rec.hl then rec.hl:Destroy() end; if rec.bb then rec.bb:Destroy() end; ESP.players[p] = nil end
		WindUI:Notify({ Title = "Stopped", Content = "All loops & ESP disabled", Icon = "octagon-x", Duration = 3 })
	end })
SettingsTab:Button({ Title = "Destroy UI",
	Callback = function()
		for k in pairs(State) do if type(State[k]) == "boolean" then State[k] = false end end
		task.wait(0.2); pcall(function() Window:Destroy() end)
	end })

SettingsTab:Section({ Title = "About" })
SettingsTab:Paragraph({ Title = "Grow a Garden 2 — Emerald · Full Edition",
	Desc = "Built on WindUI. Auto-farm, steal, shop, eggs/pets, tools, weather, "
		.. "social, auction and a full ESP suite, all driving the game's Networking remotes." })

WindUI:Notify({ Title = "Grow a Garden 2  |  Emerald", Content = "Full Edition loaded. Right-Shift toggles the menu.", Icon = "sprout", Duration = 6 })
