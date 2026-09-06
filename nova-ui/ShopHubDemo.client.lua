--[[
	NovaUI • ShopHub Demo
	----------------------------------------------------------------------
	Put this LocalScript in StarterPlayerScripts with the NovaUI modules
	(Themes, Shop, Presets, Animations, ShopPacks, ShopHub) beside it.
	Press F5. Right-Ctrl toggles the hub.

	Fill GamePasses with your real game-pass ids to make the buy buttons
	prompt the actual purchase (and grey out passes the player already owns).
]]

local ShopHub = require(script.Parent.ShopHub)

ShopHub.launch({
	Title  = "🔥 Shop",
	Accent = Color3.fromRGB(255, 40, 45), -- bright red
	Theme  = "Scarlet",
	CheckOwnership = true,
	GamePasses = {
		-- name (used by ShopPacks "Pass") = your real game-pass id
		x2Coins  = 0,
		x3Coins  = 0,
		x2Luck   = 0,
		AutoFarm = 0,
		Weapons  = 0,
		Skins    = 0,
		Survivor = 0,
		AutoParry = 0,
		GodMode  = 0,
		x2Cash   = 0,
		Season   = 0,
	},
})
