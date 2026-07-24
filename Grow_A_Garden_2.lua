--[[
	Grow a Garden 2  |  Emerald
	------------------------------------------------------------------
	A feature hub for "Grow a Garden 2" (PlaceId 77085202503540),
	built on WindUI (https://github.com/Footagesus/WindUI, MIT) with an
	emerald-green theme.

	Everything here drives the game's own networking layer
	(ReplicatedStorage.SharedModules.Networking, a ByteNet-style "Packet"
	library). Remote definitions, argument order, and the fruit-scan /
	plant / sell logic were all reconstructed from the live game dump, so
	the calls mirror exactly what the real client sends.

	This is a client-side automation script intended for executors.
	------------------------------------------------------------------
]]

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

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
		-- Fallback mirror
		result = loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua"
		))()
	end
	WindUI = result
end

--============================================================--
--  Emerald theme
--============================================================--
local Emerald   = Color3.fromHex("#10B981") -- primary emerald
local EmeraldHi = Color3.fromHex("#34D399") -- light emerald
local EmeraldLo = Color3.fromHex("#059669") -- deep emerald
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
--  Networking (the game's remote table)
--============================================================--
local Net
do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
	end)
	if ok then
		Net = mod
	else
		WindUI:Notify({
			Title = "Networking unavailable",
			Content = "Could not require SharedModules.Networking. Remote features are disabled.",
			Icon = "triangle-alert",
			Duration = 8,
		})
	end
end

-- Safely fire a remote by dotted path, e.g. fire("SeedShop","PurchaseSeed", "Carrot")
local function fire(...)
	if not Net then return end
	local args = { ... }
	local node = Net
	local i = 1
	while i <= #args and typeof(node) == "table" and node[args[i]] ~= nil and typeof(node[args[i]]) ~= "function" do
		-- descend while the next arg is a valid sub-table / remote key
		local nxt = node[args[i]]
		if type(nxt) == "table" and nxt.Fire == nil then
			node = nxt
			i += 1
		else
			node = nxt
			i += 1
			break
		end
	end
	if type(node) == "table" and node.Fire then
		local callArgs = {}
		for j = i, #args do callArgs[#callArgs + 1] = args[j] end
		return select(2, pcall(function()
			return node:Fire(table.unpack(callArgs))
		end))
	end
end

-- Direct remote accessor: remote("SeedShop","PurchaseSeed") -> packet object (or nil)
local function remote(...)
	if not Net then return nil end
	local node = Net
	for _, key in ipairs({ ... }) do
		if type(node) ~= "table" then return nil end
		node = node[key]
	end
	return node
end

--============================================================--
--  Data (seed / gear / egg / crate names from the game dump)
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
	if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
		return char, char.HumanoidRootPart, char:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

-- Player's plot folder (workspace.Gardens.Plot<PlotId>)
local function getPlayerPlot()
	local plotId = LocalPlayer:GetAttribute("PlotId")
	local gardens = Workspace:FindFirstChild("Gardens")
	if plotId and gardens then
		return gardens:FindFirstChild("Plot" .. tostring(plotId))
	end
	return nil
end

-- Scan every ripe/collectible fruit that belongs to the local player.
-- Mirrors FruitMagnetController.scanFruitInRange: iterate Gardens > Plants,
-- match UserId, then either single-harvest plants ("" fruitId) or each Fruit.
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
								-- ripe when no age data, or grown past MaxAge
								local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or (age >= maxAge)
								if ripe then
									out[#out + 1] = { plantId = plantId, fruitId = fruitId }
								end
							end
						end
					else
						-- single-harvest plant: collect with empty fruitId
						out[#out + 1] = { plantId = plantId, fruitId = "" }
					end
				end
			end
		end
	end
	return out
end

-- Find seed tools (Backpack + Character) whose "SeedTool" attribute is set.
local function getSeedTools()
	local tools = {}
	local function scan(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("SeedTool") ~= nil then
				tools[#tools + 1] = item
			end
		end
	end
	scan(LocalPlayer:FindFirstChild("Backpack"))
	scan(LocalPlayer.Character)
	return tools
end

-- Equip a tool via the Humanoid.
local function equipTool(tool)
	local char, _, hum = getCharacter()
	if char and hum and tool and tool.Parent ~= char then
		hum:EquipTool(tool)
	end
end

-- A plantable position on the player's plot (top of a PlantArea part).
local function getPlantPosition()
	local plot = getPlayerPlot()
	if not plot then return nil end

	-- Prefer CollectionService-tagged PlantArea parts inside the plot.
	local candidates = {}
	for _, tagged in ipairs(CollectionService:GetTagged("PlantArea")) do
		if tagged:IsDescendantOf(plot) and tagged:IsA("BasePart") then
			candidates[#candidates + 1] = tagged
		end
	end
	if #candidates == 0 then
		-- Fallback: any large flat BasePart in the plot.
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
	local top  = part.Position + Vector3.new(offX, part.Size.Y / 2, offZ)
	return top
end

--============================================================--
--  Window
--============================================================--
local Window = WindUI:CreateWindow({
	Title    = "Grow a Garden 2  |  Emerald",
	Folder   = "GrowAGarden2_Emerald",
	Icon     = "sprout",
	Author   = "WindUI",
	Size      = UDim2.fromOffset(560, 420),
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
	Topbar = {
		Height = 42,
		ButtonsType = "Mac",
	},
})

Window:Tag({ Title = "v" .. tostring(WindUI.Version), Color = EmeraldLo })
Window:Tag({ Title = "Emerald", Color = Emerald })

--============================================================--
--  State + long-running loops
--============================================================--
local State = {
	autoCollect = false, collectDelay = 0.4,
	autoPlant   = false, plantDelay   = 0.6, plantSeeds = {},
	autoSell    = false, sellDelay    = 30,
	autoBuySeeds = false, buySeedList = {}, buySeedDelay = 5,
	autoBuyGear  = false, buyGearList = {},
	autoOpenEgg  = false, openEggList = {}, eggDelay = 3,
	autoMailbox  = false, mailboxDelay = 60,
	antiAfk      = false,
	autoGrowAll  = false, growAllDelay = 30,
	infJump      = false,
}

-- Generic managed loop: starts a coroutine that runs while State[flag] is true.
local Loops = {}
local function startLoop(name, flagKey, delayKey, body)
	if Loops[name] then return end
	Loops[name] = task.spawn(function()
		while State[flagKey] do
			local ok, err = pcall(body)
			if not ok then
				-- swallow per-iteration errors so the loop keeps running
			end
			task.wait(State[delayKey] or 0.5)
		end
		Loops[name] = nil
	end)
end
local function stopLoop(name)
	Loops[name] = nil -- the coroutine exits on next flag check
end

--============================================================--
--  TAB: Home
--============================================================--
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })

HomeTab:Section({ Title = "Welcome" })
HomeTab:Paragraph({
	Title = "Grow a Garden 2 — Emerald",
	Desc  = "An emerald-themed WindUI hub that drives the game's own remotes: "
		.. "auto-collect fruit, auto-plant, auto-sell, shop buying, egg opening, "
		.. "mailbox claiming and more. Toggle features per tab.",
	Image = "sprout",
})

do
	local info = HomeTab:Section({ Title = "Session" })
	local statsPara = HomeTab:Paragraph({
		Title = "Live status",
		Desc  = "Loading…",
	})

	task.spawn(function()
		while true do
			local plot = getPlayerPlot()
			local collectible = #scanCollectible()
			local seeds = #getSeedTools()
			statsPara:SetDesc(string.format(
				"Plot: %s   •   Ripe/collectible: %d   •   Seed tools held: %d",
				plot and plot.Name or "unknown", collectible, seeds
			))
			task.wait(2)
		end
	end)
end

HomeTab:Button({
	Title = "Rejoin server",
	Desc  = "Teleport back into the same server.",
	Callback = function()
		local TeleportService = game:GetService("TeleportService")
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end,
})

--============================================================--
--  TAB: Farm
--============================================================--
local FarmTab = Window:Tab({ Title = "Farm", Icon = "leaf" })

FarmTab:Section({ Title = "Harvesting" })

FarmTab:Toggle({
	Title = "Auto-Collect Fruit",
	Desc  = "Continuously harvests every ripe fruit on your plot.",
	Value = false,
	Callback = function(on)
		State.autoCollect = on
		if on then
			startLoop("collect", "autoCollect", "collectDelay", function()
				local list = scanCollectible()
				for _, e in ipairs(list) do
					fire("Garden", "CollectFruit", e.plantId, e.fruitId)
				end
			end)
		end
	end,
})

FarmTab:Slider({
	Title = "Collect interval",
	Desc  = "Seconds between collection sweeps.",
	Step  = 0.1,
	Value = { Min = 0.1, Max = 5, Default = 0.4 },
	Callback = function(v) State.collectDelay = v end,
})

FarmTab:Button({
	Title = "Collect Now (once)",
	Callback = function()
		local list = scanCollectible()
		for _, e in ipairs(list) do
			fire("Garden", "CollectFruit", e.plantId, e.fruitId)
		end
		WindUI:Notify({ Title = "Collected", Content = ("Harvested %d fruit"):format(#list), Icon = "leaf", Duration = 3 })
	end,
})

FarmTab:Section({ Title = "Planting" })

FarmTab:Dropdown({
	Title  = "Seeds to auto-plant",
	Desc   = "Only seed tools you actually hold will be planted.",
	Values = SeedNames,
	Value  = {},
	Multi  = true,
	AllowNone = true,
	Callback = function(selected)
		local set = {}
		if type(selected) == "table" then
			for _, s in ipairs(selected) do set[s] = true end
		elseif selected then
			set[selected] = true
		end
		State.plantSeeds = set
	end,
})

FarmTab:Toggle({
	Title = "Auto-Plant",
	Desc  = "Equips your seed tools and plants them across your plot.",
	Value = false,
	Callback = function(on)
		State.autoPlant = on
		if on then
			startLoop("plant", "autoPlant", "plantDelay", function()
				local tools = getSeedTools()
				for _, tool in ipairs(tools) do
					local seedName = tool:GetAttribute("SeedTool")
					local wantAny = next(State.plantSeeds) == nil
					if wantAny or State.plantSeeds[seedName] or State.plantSeeds[tostring(seedName)] then
						local pos = getPlantPosition()
						if pos then
							equipTool(tool)
							task.wait(0.05)
							fire("Plant", "PlantSeed", pos, seedName, tool)
						end
					end
				end
			end)
		end
	end,
})

FarmTab:Slider({
	Title = "Plant interval",
	Step  = 0.1,
	Value = { Min = 0.2, Max = 5, Default = 0.6 },
	Callback = function(v) State.plantDelay = v end,
})

FarmTab:Section({ Title = "Grow All" })
FarmTab:Toggle({
	Title = "Auto Grow-All",
	Desc  = "Repeatedly requests the Grow-All action (uses your Grow-All charges).",
	Value = false,
	Callback = function(on)
		State.autoGrowAll = on
		if on then
			startLoop("growall", "autoGrowAll", "growAllDelay", function()
				local r = remote("Garden", "RequestGrowAllData")
				if r and r.Fire then pcall(function() r:Fire() end) end
			end)
		end
	end,
})
FarmTab:Slider({
	Title = "Grow-All interval",
	Step  = 1,
	Value = { Min = 5, Max = 120, Default = 30 },
	Callback = function(v) State.growAllDelay = v end,
})

--============================================================--
--  TAB: Sell
--============================================================--
local SellTab = Window:Tab({ Title = "Sell", Icon = "coins" })

SellTab:Section({ Title = "Selling" })

SellTab:Button({
	Title = "Sell All Now",
	Desc  = "Sells your entire inventory to the nearest NPC.",
	Callback = function()
		fire("NPCS", "SellAll")
		WindUI:Notify({ Title = "Sell All", Content = "Requested Sell All", Icon = "coins", Duration = 3 })
	end,
})

SellTab:Button({
	Title = "Preview Sell All",
	Desc  = "Asks the server what a Sell All would pay out.",
	Callback = function()
		local r = remote("NPCS", "PreviewSellAll")
		if r and r.Fire then
			local ok, res = pcall(function() return r:Fire() end)
			WindUI:Notify({
				Title = "Preview",
				Content = ok and ("Result: " .. tostring(res)) or "Preview failed",
				Icon = "eye", Duration = 4,
			})
		end
	end,
})

SellTab:Toggle({
	Title = "Auto-Sell All",
	Desc  = "Sells everything on an interval. Stand near a sell NPC.",
	Value = false,
	Callback = function(on)
		State.autoSell = on
		if on then
			startLoop("sell", "autoSell", "sellDelay", function()
				fire("NPCS", "SellAll")
			end)
		end
	end,
})

SellTab:Slider({
	Title = "Auto-Sell interval",
	Step  = 5,
	Value = { Min = 5, Max = 300, Default = 30 },
	Callback = function(v) State.sellDelay = v end,
})

--============================================================--
--  TAB: Shop
--============================================================--
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })

ShopTab:Section({ Title = "Seed Shop" })

ShopTab:Dropdown({
	Title  = "Seeds to auto-buy",
	Values = SeedNames,
	Value  = {},
	Multi  = true,
	AllowNone = true,
	Callback = function(selected)
		local list = {}
		if type(selected) == "table" then
			for _, s in ipairs(selected) do list[#list + 1] = s end
		elseif selected then
			list[1] = selected
		end
		State.buySeedList = list
	end,
})

ShopTab:Toggle({
	Title = "Auto-Buy Seeds",
	Desc  = "Purchases the selected seeds each interval (respects stock/afford).",
	Value = false,
	Callback = function(on)
		State.autoBuySeeds = on
		if on then
			startLoop("buyseeds", "autoBuySeeds", "buySeedDelay", function()
				for _, seed in ipairs(State.buySeedList) do
					fire("SeedShop", "PurchaseSeed", seed)
					task.wait(0.15)
				end
			end)
		end
	end,
})

ShopTab:Slider({
	Title = "Buy interval",
	Step  = 1,
	Value = { Min = 1, Max = 60, Default = 5 },
	Callback = function(v) State.buySeedDelay = v end,
})

ShopTab:Button({
	Title = "Buy Selected Seeds Once",
	Callback = function()
		for _, seed in ipairs(State.buySeedList) do
			fire("SeedShop", "PurchaseSeed", seed)
			task.wait(0.15)
		end
	end,
})

ShopTab:Section({ Title = "Gear Shop" })
ShopTab:Input({
	Title = "Gear name",
	Desc  = "Type an exact gear name to purchase.",
	Placeholder = "e.g. Watering Can",
	Callback = function(text)
		if text and text ~= "" then
			fire("GearShop", "PurchaseGear", text)
			WindUI:Notify({ Title = "Gear", Content = "Requested: " .. text, Icon = "shopping-cart", Duration = 3 })
		end
	end,
})

ShopTab:Section({ Title = "Crate Shop" })
ShopTab:Dropdown({
	Title  = "Crate to buy",
	Values = CrateNames,
	Value  = nil,
	AllowNone = true,
	Callback = function(selected)
		if selected and selected ~= "" then
			fire("CrateShop", "PurchaseCrate", selected)
		end
	end,
})

--============================================================--
--  TAB: Eggs & Pets
--============================================================--
local EggTab = Window:Tab({ Title = "Eggs & Pets", Icon = "egg" })

EggTab:Section({ Title = "Eggs" })

EggTab:Dropdown({
	Title  = "Eggs to auto-open",
	Values = EggNames,
	Value  = {},
	Multi  = true,
	AllowNone = true,
	Callback = function(selected)
		local list = {}
		if type(selected) == "table" then
			for _, s in ipairs(selected) do list[#list + 1] = s end
		elseif selected then
			list[1] = selected
		end
		State.openEggList = list
	end,
})

EggTab:Toggle({
	Title = "Auto-Open Eggs",
	Desc  = "Opens the selected eggs on an interval.",
	Value = false,
	Callback = function(on)
		State.autoOpenEgg = on
		if on then
			startLoop("eggs", "autoOpenEgg", "eggDelay", function()
				for _, egg in ipairs(State.openEggList) do
					local r = remote("Egg", "OpenEgg")
					if r and r.Fire then pcall(function() r:Fire(egg) end) end
					task.wait(0.25)
				end
			end)
		end
	end,
})

EggTab:Slider({
	Title = "Egg interval",
	Step  = 1,
	Value = { Min = 1, Max = 30, Default = 3 },
	Callback = function(v) State.eggDelay = v end,
})

EggTab:Section({ Title = "Pets" })
EggTab:Input({
	Title = "Equip pet by name",
	Placeholder = "exact pet name",
	Callback = function(text)
		if text and text ~= "" then
			fire("Pets", "RequestEquipByName", text)
		end
	end,
})
EggTab:Input({
	Title = "Unequip pet by name",
	Placeholder = "exact pet name",
	Callback = function(text)
		if text and text ~= "" then
			fire("Pets", "RequestUnequipByName", text)
		end
	end,
})
EggTab:Button({
	Title = "Purchase Pet Slot",
	Callback = function()
		fire("Pets", "RequestPurchasePetSlot")
	end,
})

--============================================================--
--  TAB: Automation
--============================================================--
local AutoTab = Window:Tab({ Title = "Automation", Icon = "bot" })

AutoTab:Section({ Title = "Mailbox" })
AutoTab:Button({
	Title = "Claim All Mail Now",
	Callback = function()
		fire("Mailbox", "ClaimAll")
		WindUI:Notify({ Title = "Mailbox", Content = "Claimed all mail", Icon = "mail", Duration = 3 })
	end,
})
AutoTab:Toggle({
	Title = "Auto-Claim Mailbox",
	Value = false,
	Callback = function(on)
		State.autoMailbox = on
		if on then
			startLoop("mailbox", "autoMailbox", "mailboxDelay", function()
				fire("Mailbox", "ClaimAll")
			end)
		end
	end,
})
AutoTab:Slider({
	Title = "Mailbox interval",
	Step  = 5,
	Value = { Min = 10, Max = 300, Default = 60 },
	Callback = function(v) State.mailboxDelay = v end,
})

AutoTab:Section({ Title = "Garden" })
AutoTab:Button({
	Title = "Expand Garden",
	Desc  = "Requests a garden expansion (costs in-game currency).",
	Callback = function()
		local r = remote("Actions", "ExpandGarden")
		if r and r.Fire then pcall(function() r:Fire() end) end
	end,
})
AutoTab:Button({
	Title = "Like Current Garden",
	Callback = function()
		local plot = getPlayerPlot()
		local owner = plot and tonumber(plot:GetAttribute("OwnerUserId"))
		fire("Actions", "LikeGarden", owner or LocalPlayer.UserId)
	end,
})

AutoTab:Section({ Title = "Pilgrim / Deliveries" })
AutoTab:Button({
	Title = "Submit Pilgrim Delivery",
	Callback = function()
		local r = remote("Pilgrim", "SubmitDelivery")
		if r and r.Fire then pcall(function() r:Fire() end) end
	end,
})
AutoTab:Button({
	Title = "Claim Pilgrim Reward",
	Callback = function()
		local r = remote("Pilgrim", "ClaimReward")
		if r and r.Fire then pcall(function() r:Fire() end) end
	end,
})

AutoTab:Section({ Title = "Anti-AFK" })
AutoTab:Toggle({
	Title = "Anti-AFK",
	Desc  = "Prevents the 20-minute idle kick.",
	Value = false,
	Callback = function(on)
		State.antiAfk = on
	end,
})

-- Anti-AFK hook
do
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			if State.antiAfk then
				pcall(function()
					VirtualUser:CaptureController()
					VirtualUser:ClickButton2(Vector2.new())
				end)
			end
		end)
	end
end

--============================================================--
--  TAB: Player
--============================================================--
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

PlayerTab:Section({ Title = "Movement" })

local defaultWS, defaultJP = 16, 50
PlayerTab:Slider({
	Title = "Walk Speed",
	Step  = 1,
	Value = { Min = 16, Max = 250, Default = 16 },
	Callback = function(v)
		local _, _, hum = getCharacter()
		if hum then hum.WalkSpeed = v end
		defaultWS = v
	end,
})
PlayerTab:Slider({
	Title = "Jump Power",
	Step  = 1,
	Value = { Min = 50, Max = 350, Default = 50 },
	Callback = function(v)
		local _, _, hum = getCharacter()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = v
		end
		defaultJP = v
	end,
})

PlayerTab:Toggle({
	Title = "Infinite Jump",
	Value = false,
	Callback = function(on) State.infJump = on end,
})

UserInputService.JumpRequest:Connect(function()
	if State.infJump then
		local _, _, hum = getCharacter()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Reapply movement stats on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		task.wait(0.5)
		pcall(function()
			hum.WalkSpeed = defaultWS
			if defaultJP ~= 50 then
				hum.UseJumpPower = true
				hum.JumpPower = defaultJP
			end
		end)
	end
end)

PlayerTab:Section({ Title = "Teleport" })
PlayerTab:Button({
	Title = "To Sell NPC (nearest)",
	Desc  = "Teleports to the closest SellItem prompt / NPC if found.",
	Callback = function()
		local _, hrp = getCharacter()
		if not hrp then return end
		-- Look for a Steven / sell NPC by common tags/names
		local best, bestDist
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (obj.Name == "SellPart" or obj.Name == "Steven" or obj.Parent and obj.Parent.Name:find("Sell")) then
				local d = (obj.Position - hrp.Position).Magnitude
				if not bestDist or d < bestDist then best, bestDist = obj, d end
			end
		end
		if best then
			hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 4))
		else
			WindUI:Notify({ Title = "Teleport", Content = "No sell NPC found nearby", Icon = "map-pin", Duration = 3 })
		end
	end,
})
PlayerTab:Button({
	Title = "To My Plot",
	Callback = function()
		local _, hrp = getCharacter()
		local plot = getPlayerPlot()
		local spawn = plot and plot:FindFirstChild("SpawnPoint")
		if hrp and spawn and spawn:IsA("BasePart") then
			hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
		end
	end,
})

--============================================================--
--  TAB: Settings
--============================================================--
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Section({ Title = "Interface" })
SettingsTab:Button({
	Title = "Copy remote list count",
	Desc  = "Notifies how many remote categories were loaded.",
	Callback = function()
		local n = 0
		if Net then for _ in pairs(Net) do n += 1 end end
		WindUI:Notify({ Title = "Networking", Content = ("%d remote categories loaded"):format(n), Icon = "network", Duration = 4 })
	end,
})
SettingsTab:Toggle({
	Title = "Translucent background",
	Value = true,
	Callback = function(on)
		pcall(function() Window:SetBackgroundTransparency(on and 0.3 or 0) end)
	end,
})
SettingsTab:Button({
	Title = "Destroy UI",
	Desc  = "Closes the hub and stops all loops.",
	Callback = function()
		for k in pairs(State) do
			if type(State[k]) == "boolean" then State[k] = false end
		end
		task.wait(0.2)
		pcall(function() Window:Destroy() end)
	end,
})

SettingsTab:Section({ Title = "About" })
SettingsTab:Paragraph({
	Title = "Grow a Garden 2 — Emerald",
	Desc  = "Built on WindUI. All actions call the game's own Networking remotes "
		.. "(Plant, SeedShop, GearShop, Egg, NPCS, Garden, Mailbox, Actions, Pilgrim). "
		.. "Client-side automation only.",
})

--============================================================--
--  Ready
--============================================================--
WindUI:Notify({
	Title   = "Grow a Garden 2  |  Emerald",
	Content = "Loaded. Press Right-Shift to toggle the menu.",
	Icon    = "sprout",
	Duration = 6,
})
