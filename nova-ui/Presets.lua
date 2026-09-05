--[[
	NovaUI • Presets
	----------------------------------------------------------------------
	A catalog of ready-to-use shop variations. Each variation is a unique
	combination of:

		Theme      (24)   ×
		Layout     (6)    ×
		CardStyle  (4)

	= 576 distinct shop looks. Every one is a real, buildable config — no
	filler. Pick one by index, by name, at random, or browse them.

		local Presets = require(script.Parent.Presets)

		print(Presets.Count())                 --> 576
		local cfg = Presets.Get(1)             --> a config table
		local cfg = Presets.GetByName("Midnight · Grid · Elevated")
		local cfg = Presets.Random()

		-- build a live shop from a variation + your items:
		local shop = Presets.BuildShop(1, myItems)

	`Presets.Filter{ Theme=, Layout=, CardStyle= }` narrows the catalog,
	e.g. Presets.Filter{ Layout="Carousel" } → every carousel variation.
]]

local Themes = require(script.Parent.Themes)
local Shop   = require(script.Parent.Shop)

local Presets = {}

-- Build the full cartesian catalog once.
local function buildCatalog()
	local list = {}
	local themeNames = Themes.Names()
	for _, theme in ipairs(themeNames) do
		for _, layout in ipairs(Shop.Layouts) do
			for _, style in ipairs(Shop.CardStyles) do
				table.insert(list, {
					Theme     = theme,
					Layout    = layout,
					CardStyle = style,
					Name      = string.format("%s · %s · %s", theme, layout, style),
				})
			end
		end
	end
	return list
end

local Catalog = buildCatalog()
local NameIndex = {}
for i, v in ipairs(Catalog) do NameIndex[v.Name] = i end

-- ── query ────────────────────────────────────────────────────────────────
function Presets.Count() return #Catalog end

function Presets.All() return table.clone(Catalog) end

function Presets.Get(index)
	local v = Catalog[index]
	return v and table.clone(v) or nil
end

function Presets.GetByName(name)
	local i = NameIndex[name]
	return i and table.clone(Catalog[i]) or nil
end

function Presets.Names()
	local names = {}
	for _, v in ipairs(Catalog) do table.insert(names, v.Name) end
	return names
end

function Presets.Random()
	return table.clone(Catalog[math.random(1, #Catalog)])
end

-- Filter{ Theme=, Layout=, CardStyle= } — any field optional.
function Presets.Filter(q)
	q = q or {}
	local out = {}
	for _, v in ipairs(Catalog) do
		if (not q.Theme or v.Theme == q.Theme)
			and (not q.Layout or v.Layout == q.Layout)
			and (not q.CardStyle or v.CardStyle == q.CardStyle) then
			table.insert(out, table.clone(v))
		end
	end
	return out
end

-- ── build ────────────────────────────────────────────────────────────────
-- Turn a variation (index / name / config table) into a live Shop.
-- `items` is a list passed to shop:AddItems. `extra` merges extra Shop.new cfg
-- (Title, Columns, Parent, OnPurchase, …).
function Presets.BuildShop(variation, items, extra)
	local cfg
	if type(variation) == "number" then cfg = Presets.Get(variation)
	elseif type(variation) == "string" then cfg = Presets.GetByName(variation)
	elseif type(variation) == "table" then cfg = variation end
	assert(cfg, "Presets.BuildShop: unknown variation")

	local shopCfg = {
		Theme     = cfg.Theme,
		Layout    = cfg.Layout,
		CardStyle = cfg.CardStyle,
		Title     = cfg.Name,
	}
	for k, v in pairs(extra or {}) do shopCfg[k] = v end

	local shop = Shop.new(shopCfg)
	if items then shop:AddItems(items) end
	shop:Render()
	return shop
end

return Presets
