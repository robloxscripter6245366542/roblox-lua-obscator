--[[
	NovaUI • Shop Demo
	----------------------------------------------------------------------
	Put this LocalScript in StarterPlayerScripts with Themes.lua, Shop.lua
	and Presets.lua beside it (as ModuleScripts). Press F5 in Studio.

	Press  ]  to jump to the next of the 576 shop variations.
	Press  [  to go back one.
	Press  R  for a random variation.
]]

local UserInputService = game:GetService("UserInputService")

local Presets = require(script.Parent.Presets)

-- Sample catalog. Set ProductId + PurchaseType to wire real Robux purchases.
local ITEMS = {
	{ Name="Golden Sword", Price=99,  Category="Weapons", Badge="SALE",  Image="rbxassetid://0" },
	{ Name="Frost Bow",    Price=149, Category="Weapons",                Image="rbxassetid://0" },
	{ Name="Shadow Blade", Price=299, Category="Weapons", Badge="NEW",   Image="rbxassetid://0" },
	{ Name="Speed Coil",   Price=75,  Category="Gear",                   Image="rbxassetid://0" },
	{ Name="Jetpack",      Price=399, Category="Gear",    Badge="HOT",   Image="rbxassetid://0" },
	{ Name="Grapple Hook", Price=199, Category="Gear",                  Image="rbxassetid://0" },
	{ Name="VIP Pass",     Price=499, Category="Passes",  Badge="BEST",  Image="rbxassetid://0",
	  ProductId=0, PurchaseType="Gamepass" },
	{ Name="2x Coins",     Price=299, Category="Passes",                 Image="rbxassetid://0",
	  ProductId=0, PurchaseType="Gamepass" },
	{ Name="Coin Pack",    Price=250, Category="Currency", Currency="🪙", Image="rbxassetid://0",
	  Callback=function(item) print("Grant coins for", item.Name) end },
	{ Name="Owned Skin",   Price=0,   Category="Skins",   Owned=true,    Image="rbxassetid://0" },
}

print(("NovaUI Shop: %d variations available"):format(Presets.Count()))

local index = 1
local shop

local function show(i)
	index = ((i - 1) % Presets.Count()) + 1
	if shop then shop:Destroy() end
	local variation = Presets.Get(index)
	shop = Presets.BuildShop(index, ITEMS, {
		Columns = 3,
		OnPurchase = function(item) print("Purchased:", item.Name) end,
	})
	shop:SetBalance(1000)
	print(("[%d/%d] %s"):format(index, Presets.Count(), variation.Name))
end

show(1)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightBracket then show(index + 1)
	elseif input.KeyCode == Enum.KeyCode.LeftBracket then show(index - 1)
	elseif input.KeyCode == Enum.KeyCode.R then show(math.random(1, Presets.Count())) end
end)
