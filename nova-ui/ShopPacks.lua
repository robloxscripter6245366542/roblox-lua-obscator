--[[
	NovaUI • ShopPacks
	----------------------------------------------------------------------
	A free library of ready-made shop packs. Each pack is a complete,
	themed store — a look (theme/layout/card style/accent), a currency, and
	a full item list with categories, badges and game-pass hooks. Drop them
	into ShopHub for a side-tab browser of dozens of shops.

	Game passes: give an item `Pass = "<name>"` and map that name to a real
	game-pass id in ShopHub's `GamePasses` config; ShopHub fills in the
	ProductId + PurchaseType and (optionally) marks it Owned.

	Every pack here is genuinely buildable — no filler.
]]

local RED   = Color3.fromRGB(255, 40, 45)
local GOLD  = Color3.fromRGB(255, 196, 64)
local CYAN  = Color3.fromRGB(60, 200, 255)
local GREEN = Color3.fromRGB(120, 200, 90)

local Packs = {
	-- 1 ─ Weapons -----------------------------------------------------------
	{
		Name = "Arsenal", Theme = "Scarlet", Layout = "Grid", CardStyle = "Elevated",
		Accent = RED, Currency = "R$",
		Items = {
			{ Name="Golden Sword", Price=99,  Category="Melee",  Badge="SALE" },
			{ Name="Shadow Blade", Price=299, Category="Melee",  Badge="NEW"  },
			{ Name="Frost Katana", Price=249, Category="Melee"                 },
			{ Name="Plasma Rifle", Price=399, Category="Ranged", Badge="HOT"  },
			{ Name="Frost Bow",    Price=149, Category="Ranged"                },
			{ Name="Rail Cannon",  Price=699, Category="Ranged", Badge="BEST" },
			{ Name="Grenade Pack", Price=59,  Category="Throwable"             },
			{ Name="Sticky Bomb",  Price=89,  Category="Throwable"             },
			{ Name="VIP Weapons",  Price=499, Category="Passes", Pass="Weapons" },
		},
	},
	-- 2 ─ Simulator ---------------------------------------------------------
	{
		Name = "Boost Sim", Theme = "Inferno", Layout = "Compact", CardStyle = "Flat",
		Accent = Color3.fromRGB(255,90,30), Currency = "🪙",
		Items = {
			{ Name="x2 Coins",   Price=250, Category="Boosts", Badge="x2",  Pass="x2Coins" },
			{ Name="x3 Coins",   Price=450, Category="Boosts", Badge="x3",  Pass="x3Coins" },
			{ Name="x2 Luck",    Price=300, Category="Boosts", Pass="x2Luck" },
			{ Name="Auto Farm",  Price=800, Category="Boosts", Badge="BEST", Pass="AutoFarm" },
			{ Name="Coin Pack S",Price=100, Category="Coins" },
			{ Name="Coin Pack M",Price=250, Category="Coins" },
			{ Name="Coin Pack L",Price=500, Category="Coins", Badge="POPULAR" },
			{ Name="Mega Chest", Price=999, Category="Coins", Badge="HUGE" },
		},
	},
	-- 3 ─ Pets --------------------------------------------------------------
	{
		Name = "Pet Palace", Theme = "Sakura", Layout = "Grid", CardStyle = "Glass",
		Accent = Color3.fromRGB(245,120,160), Currency = "🐾",
		Items = {
			{ Name="Puppy",       Price=75,  Category="Common"                },
			{ Name="Kitten",      Price=75,  Category="Common"                },
			{ Name="Dragon",      Price=650, Category="Legendary", Badge="NEW" },
			{ Name="Phoenix",     Price=900, Category="Legendary", Badge="RARE" },
			{ Name="Robot Pet",   Price=400, Category="Epic"                  },
			{ Name="Ghost Pet",   Price=350, Category="Epic",  Badge="SPOOKY" },
			{ Name="Pet Slot +1", Price=120, Category="Upgrades"              },
			{ Name="Golden Egg",  Price=500, Category="Eggs", Badge="LUCKY"   },
		},
	},
	-- 4 ─ Vehicles ----------------------------------------------------------
	{
		Name = "Garage", Theme = "Slate", Layout = "List", CardStyle = "Outline",
		Accent = CYAN, Currency = "R$",
		Items = {
			{ Name="Sports Car",  Price=350, Category="Cars",  Badge="FAST" },
			{ Name="Muscle Car",  Price=300, Category="Cars"                },
			{ Name="Hyper Car",   Price=850, Category="Cars",  Badge="TOP"  },
			{ Name="Dirt Bike",   Price=180, Category="Bikes"               },
			{ Name="Hover Board", Price=220, Category="Bikes", Badge="NEW"  },
			{ Name="Helicopter",  Price=999, Category="Air",   Badge="BEST" },
			{ Name="Jetpack",     Price=399, Category="Air"                 },
		},
	},
	-- 5 ─ RPG Shop ----------------------------------------------------------
	{
		Name = "Adventurer", Theme = "Royal", Layout = "Featured", CardStyle = "Elevated",
		Accent = GOLD, Currency = "💎",
		Items = {
			{ Name="Legendary Chest", Price=999, Category="Featured", Badge="LIMITED" },
			{ Name="Health Potion",   Price=25,  Category="Potions"  },
			{ Name="Mana Potion",     Price=25,  Category="Potions"  },
			{ Name="Strength Elixir", Price=120, Category="Potions", Badge="+STR" },
			{ Name="Iron Armor",      Price=200, Category="Armor"    },
			{ Name="Dragon Armor",    Price=750, Category="Armor",  Badge="RARE" },
			{ Name="Teleport Scroll", Price=60,  Category="Utility"  },
			{ Name="Revive Token",    Price=150, Category="Utility", Badge="SAVE" },
		},
	},
	-- 6 ─ Skins ------------------------------------------------------------
	{
		Name = "Skins", Theme = "Cyberpunk", Layout = "Grid", CardStyle = "Glass",
		Accent = Color3.fromRGB(255,0,170), Currency = "R$",
		Items = {
			{ Name="Neon Glow",   Price=120, Category="Body",  Badge="GLOW" },
			{ Name="Galaxy",      Price=200, Category="Body",  Badge="RARE" },
			{ Name="Golden Trim", Price=300, Category="Body"   },
			{ Name="Fire Trail",  Price=150, Category="Trails", Badge="HOT" },
			{ Name="Ice Trail",   Price=150, Category="Trails" },
			{ Name="Rainbow Aura",Price=400, Category="Auras", Badge="BEST" },
			{ Name="Shadow Aura", Price=350, Category="Auras"  },
			{ Name="VIP Skins",   Price=499, Category="Passes", Pass="Skins" },
		},
	},
	-- 7 ─ Farming ----------------------------------------------------------
	{
		Name = "Harvest", Theme = "Forest", Layout = "Grid", CardStyle = "Flat",
		Accent = GREEN, Currency = "🌱",
		Items = {
			{ Name="Wheat Seeds",  Price=20,  Category="Seeds"  },
			{ Name="Pumpkin Seeds",Price=45,  Category="Seeds", Badge="FALL" },
			{ Name="Golden Seeds", Price=250, Category="Seeds", Badge="RARE" },
			{ Name="Sprinkler",    Price=180, Category="Tools", Badge="AUTO" },
			{ Name="Fertilizer",   Price=90,  Category="Tools"  },
			{ Name="Bigger Plot",  Price=350, Category="Land"   },
			{ Name="Auto Harvest", Price=800, Category="Passes", Pass="AutoFarm", Badge="BEST" },
		},
	},
	-- 8 ─ Space ------------------------------------------------------------
	{
		Name = "Starbase", Theme = "DeepSea", Layout = "Showcase", CardStyle = "Elevated",
		Accent = Color3.fromRGB(60,200,255), Currency = "⭐",
		Items = {
			{ Name="Scout Ship",   Price=300, Category="Ships"  },
			{ Name="Battle Cruiser",Price=800,Category="Ships", Badge="TOP" },
			{ Name="Cargo Hauler", Price=450, Category="Ships"  },
			{ Name="Laser Upgrade",Price=200, Category="Upgrades", Badge="+DMG" },
			{ Name="Shield Core",  Price=250, Category="Upgrades" },
			{ Name="Warp Drive",   Price=650, Category="Upgrades", Badge="FAST" },
			{ Name="Fuel Pack",    Price=80,  Category="Consumables" },
		},
	},
	-- 9 ─ Horror -----------------------------------------------------------
	{
		Name = "Nightmare", Theme = "Obsidian", Layout = "List", CardStyle = "Outline",
		Accent = Color3.fromRGB(0,200,180), Currency = "🩸",
		Items = {
			{ Name="Flashlight",   Price=40,  Category="Gear",   Badge="START" },
			{ Name="Med Kit",      Price=90,  Category="Gear"    },
			{ Name="Crucifix",     Price=200, Category="Relics", Badge="HOLY" },
			{ Name="Ouija Board",  Price=150, Category="Relics"  },
			{ Name="Ghost Skin",   Price=250, Category="Cosmetic", Badge="RARE" },
			{ Name="Survivor Pass",Price=499, Category="Passes", Pass="Survivor", Badge="BEST" },
		},
	},
	-- 10 ─ Anime -----------------------------------------------------------
	{
		Name = "Anime Ball", Theme = "Neon", Layout = "Grid", CardStyle = "Glass",
		Accent = Color3.fromRGB(57,255,20), Currency = "R$",
		Items = {
			{ Name="Auto Parry",  Price=350, Category="Abilities", Badge="PRO", Pass="AutoParry" },
			{ Name="Speed Aura",  Price=200, Category="Abilities" },
			{ Name="Dash x2",     Price=180, Category="Abilities", Badge="x2" },
			{ Name="Katana Skin", Price=250, Category="Cosmetic"  },
			{ Name="Dragon Trail",Price=300, Category="Cosmetic", Badge="RARE" },
			{ Name="Emote Pack",  Price=120, Category="Cosmetic"  },
			{ Name="God Mode",    Price=999, Category="Passes", Pass="GodMode", Badge="OP" },
		},
	},
	-- 11 ─ Tycoon ----------------------------------------------------------
	{
		Name = "Tycoon", Theme = "Ember", Layout = "Compact", CardStyle = "Flat",
		Accent = Color3.fromRGB(255,120,40), Currency = "💵",
		Items = {
			{ Name="Conveyor",     Price=100, Category="Machines" },
			{ Name="Smelter",      Price=250, Category="Machines", Badge="+CASH" },
			{ Name="Refinery",     Price=600, Category="Machines", Badge="TOP" },
			{ Name="Dropper x2",   Price=200, Category="Upgrades", Badge="x2" },
			{ Name="Wall Skin",    Price=80,  Category="Cosmetic"  },
			{ Name="Neon Base",    Price=180, Category="Cosmetic"  },
			{ Name="2x Cash",      Price=450, Category="Passes", Pass="x2Cash", Badge="BEST" },
		},
	},
	-- 12 ─ Battle Pass -----------------------------------------------------
	{
		Name = "Season", Theme = "Crimson", Layout = "Featured", CardStyle = "Elevated",
		Accent = Color3.fromRGB(230,25,60), Currency = "R$",
		Items = {
			{ Name="Season Pass",   Price=799, Category="Featured", Badge="SEASON", Pass="Season" },
			{ Name="Tier Skip x5",  Price=150, Category="Tiers", Badge="x5" },
			{ Name="Tier Skip x25", Price=600, Category="Tiers", Badge="x25" },
			{ Name="Exclusive Skin",Price=0,   Category="Rewards", Owned=true },
			{ Name="Emote: Wave",   Price=0,   Category="Rewards", Owned=true },
			{ Name="Coin Boost",    Price=250, Category="Rewards" },
		},
	},
}

return Packs
