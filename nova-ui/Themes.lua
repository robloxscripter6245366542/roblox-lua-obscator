--[[
	NovaUI • Themes
	----------------------------------------------------------------------
	A catalog of ready-made color themes. Each theme matches the shape
	NovaUI / Shop expect:

		{ Background, Surface, SurfaceAlt, Stroke, Text, SubText,
		  Accent, AccentText }

	Use a theme by name:  Themes.Get("Midnight")   → theme table
	List every name:      Themes.Names()           → { "Midnight", ... }

	Mix these with Shop's 6 layouts and 4 card styles for hundreds of
	distinct shop looks (see Presets.lua).
]]

local function c(r, g, b) return Color3.fromRGB(r, g, b) end

local Themes = {}

-- name = { palette }
local Catalog = {
	-- ── Dark family ──────────────────────────────────────────────────────
	Midnight = {
		Background=c(18,18,24), Surface=c(26,26,34), SurfaceAlt=c(36,36,46),
		Stroke=c(48,48,62), Text=c(236,236,244), SubText=c(150,150,168),
		Accent=c(120,90,255), AccentText=c(255,255,255),
	},
	Obsidian = {
		Background=c(12,12,14), Surface=c(20,20,24), SurfaceAlt=c(30,30,36),
		Stroke=c(44,44,52), Text=c(240,240,245), SubText=c(140,140,150),
		Accent=c(0,200,180), AccentText=c(8,8,10),
	},
	Graphite = {
		Background=c(28,30,34), Surface=c(38,40,46), SurfaceAlt=c(50,52,60),
		Stroke=c(64,66,76), Text=c(232,234,240), SubText=c(158,160,170),
		Accent=c(255,138,76), AccentText=c(20,20,20),
	},
	Nord = {
		Background=c(46,52,64), Surface=c(59,66,82), SurfaceAlt=c(67,76,94),
		Stroke=c(76,86,106), Text=c(236,239,244), SubText=c(180,190,206),
		Accent=c(136,192,208), AccentText=c(24,28,36),
	},
	Dracula = {
		Background=c(40,42,54), Surface=c(52,54,70), SurfaceAlt=c(68,71,90),
		Stroke=c(88,91,112), Text=c(248,248,242), SubText=c(180,182,200),
		Accent=c(189,147,249), AccentText=c(30,30,40),
	},
	Carbon = {
		Background=c(16,17,19), Surface=c(24,26,29), SurfaceAlt=c(34,37,41),
		Stroke=c(48,52,58), Text=c(230,232,236), SubText=c(138,142,150),
		Accent=c(240,60,90), AccentText=c(255,255,255),
	},
	Cyberpunk = {
		Background=c(15,12,30), Surface=c(26,20,48), SurfaceAlt=c(40,30,72),
		Stroke=c(90,40,140), Text=c(240,235,255), SubText=c(170,150,210),
		Accent=c(255,0,170), AccentText=c(255,255,255),
	},
	Matrix = {
		Background=c(8,14,10), Surface=c(14,24,16), SurfaceAlt=c(20,34,22),
		Stroke=c(30,60,34), Text=c(190,255,200), SubText=c(110,180,120),
		Accent=c(0,255,120), AccentText=c(4,10,6),
	},
	DeepSea = {
		Background=c(10,22,34), Surface=c(16,34,52), SurfaceAlt=c(24,48,72),
		Stroke=c(34,68,100), Text=c(224,238,250), SubText=c(150,180,205),
		Accent=c(60,200,255), AccentText=c(6,18,28),
	},
	Wine = {
		Background=c(28,14,20), Surface=c(42,20,30), SurfaceAlt=c(58,28,42),
		Stroke=c(80,40,58), Text=c(248,232,238), SubText=c(196,150,166),
		Accent=c(230,60,110), AccentText=c(255,255,255),
	},
	Forest = {
		Background=c(18,26,20), Surface=c(28,40,32), SurfaceAlt=c(40,54,44),
		Stroke=c(56,74,60), Text=c(232,242,232), SubText=c(160,180,162),
		Accent=c(120,200,90), AccentText=c(14,22,14),
	},
	Ember = {
		Background=c(24,16,14), Surface=c(36,24,20), SurfaceAlt=c(52,34,28),
		Stroke=c(74,48,40), Text=c(246,236,230), SubText=c(196,166,152),
		Accent=c(255,120,40), AccentText=c(20,12,8),
	},
	RoseGold = {
		Background=c(30,22,24), Surface=c(44,32,34), SurfaceAlt=c(60,44,46),
		Stroke=c(84,62,64), Text=c(248,238,238), SubText=c(200,172,172),
		Accent=c(240,170,150), AccentText=c(30,20,20),
	},
	Neon = {
		Background=c(10,10,16), Surface=c(18,18,28), SurfaceAlt=c(28,28,44),
		Stroke=c(50,50,80), Text=c(235,235,255), SubText=c(150,150,190),
		Accent=c(57,255,20), AccentText=c(8,8,12),
	},
	Royal = {
		Background=c(18,20,40), Surface=c(28,32,58), SurfaceAlt=c(40,46,80),
		Stroke=c(58,66,110), Text=c(232,236,252), SubText=c(160,170,210),
		Accent=c(255,196,64), AccentText=c(24,26,48),
	},
	Slate = {
		Background=c(22,24,28), Surface=c(32,35,40), SurfaceAlt=c(44,48,55),
		Stroke=c(60,64,72), Text=c(228,230,235), SubText=c(150,154,162),
		Accent=c(96,165,250), AccentText=c(12,16,24),
	},

	-- ── Light family ─────────────────────────────────────────────────────
	Daylight = {
		Background=c(244,245,250), Surface=c(255,255,255), SurfaceAlt=c(236,238,245),
		Stroke=c(220,222,232), Text=c(28,28,36), SubText=c(120,124,140),
		Accent=c(120,90,255), AccentText=c(255,255,255),
	},
	Paper = {
		Background=c(248,246,240), Surface=c(255,254,250), SurfaceAlt=c(240,236,226),
		Stroke=c(224,218,206), Text=c(40,36,30), SubText=c(140,132,120),
		Accent=c(220,110,60), AccentText=c(255,255,255),
	},
	Mint = {
		Background=c(238,248,244), Surface=c(255,255,255), SurfaceAlt=c(226,242,236),
		Stroke=c(206,230,222), Text=c(24,44,38), SubText=c(110,150,140),
		Accent=c(20,190,150), AccentText=c(255,255,255),
	},
	Sky = {
		Background=c(238,244,252), Surface=c(255,255,255), SurfaceAlt=c(226,236,248),
		Stroke=c(204,220,240), Text=c(26,36,52), SubText=c(112,132,160),
		Accent=c(40,150,255), AccentText=c(255,255,255),
	},
	Sakura = {
		Background=c(252,242,246), Surface=c(255,255,255), SurfaceAlt=c(248,232,238),
		Stroke=c(240,214,224), Text=c(52,32,42), SubText=c(160,124,138),
		Accent=c(245,120,160), AccentText=c(255,255,255),
	},
	Sand = {
		Background=c(246,242,234), Surface=c(255,253,248), SurfaceAlt=c(238,230,216),
		Stroke=c(222,210,190), Text=c(46,40,30), SubText=c(146,134,112),
		Accent=c(210,160,70), AccentText=c(30,24,10),
	},
	Lavender = {
		Background=c(244,242,252), Surface=c(255,255,255), SurfaceAlt=c(236,232,248),
		Stroke=c(220,214,240), Text=c(38,32,52), SubText=c(130,122,158),
		Accent=c(150,110,240), AccentText=c(255,255,255),
	},
	Frost = {
		Background=c(240,244,246), Surface=c(252,254,255), SurfaceAlt=c(228,236,240),
		Stroke=c(206,218,224), Text=c(30,40,44), SubText=c(120,138,146),
		Accent=c(0,180,200), AccentText=c(255,255,255),
	},
}

function Themes.Get(name)
	local t = Catalog[name]
	if not t then return nil end
	return table.clone(t)
end

function Themes.Names()
	local names = {}
	for name in pairs(Catalog) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Themes.Count()
	local n = 0
	for _ in pairs(Catalog) do n += 1 end
	return n
end

-- Direct access, e.g. Themes.Midnight
setmetatable(Themes, {
	__index = function(_, k)
		local t = Catalog[k]
		return t and table.clone(t) or nil
	end,
})

return Themes
