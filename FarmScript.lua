-- ServerScriptService > FarmScript (Script)
local Players = game:GetService("Players")

local CropData = {
	Wheat   = { GrowTime = 10, Value = 5,  Color = "Bright green" },
	Carrot  = { GrowTime = 15, Value = 10, Color = "Bright orange" },
	Pumpkin = { GrowTime = 25, Value = 25, Color = "Neon orange" },
}

local crops = {}

Players.PlayerAdded:Connect(function(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats
end)

local function CreateCrop(player, cropType, position)
	local data = CropData[cropType]

	local crop = Instance.new("Part")
	crop.Name = cropType
	crop.Size = Vector3.new(1, 1, 1)
	crop.Anchored = true
	crop.Position = position
	crop.BrickColor = BrickColor.new(data.Color)
	crop.Parent = workspace

	local click = Instance.new("ClickDetector")
	click.Parent = crop

	crops[crop] = {
		Owner = player,
		Value = data.Value,
	}

	task.spawn(function()
		for _ = 1, data.GrowTime do
			task.wait(1)
			if crop.Parent then
				crop.Size += Vector3.new(0, 0.1, 0)
			end
		end
		if crop.Parent then
			crop:SetAttribute("Ready", true)
			crop.BrickColor = BrickColor.new("Bright yellow")
		end
	end)

	click.MouseClick:Connect(function(clickingPlayer)
		if clickingPlayer ~= player then return end
		if crop:GetAttribute("Ready") ~= true then return end

		local entry = crops[crop]
		if not entry then return end

		clickingPlayer.leaderstats.Coins.Value += entry.Value
		crops[crop] = nil
		crop:Destroy()
	end)
end

local farmPlot = workspace:WaitForChild("FarmPlot")

local detector = Instance.new("ClickDetector")
detector.Parent = farmPlot

local cropTypes = { "Wheat", "Carrot", "Pumpkin" }

detector.MouseClick:Connect(function(player)
	local cropType = cropTypes[math.random(1, #cropTypes)]
	local offset = Vector3.new(math.random(-8, 8), 2, math.random(-8, 8))
	CreateCrop(player, cropType, farmPlot.Position + offset)
end)

while true do
	task.wait(30)
	for crop, data in pairs(crops) do
		if crop.Parent and not data.Rainbow and math.random(1, 100) <= 5 then
			data.Rainbow = true
			data.Value *= 5
			crop.Material = Enum.Material.Neon
			crop.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
			print("Rainbow Crop Created!")
		end
	end
end
