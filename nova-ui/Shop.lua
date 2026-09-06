--[[
	NovaUI • Shop
	----------------------------------------------------------------------
	A drop-in shop / store UI builder for Roblox experiences. One module,
	many looks: 6 layouts × 4 card styles × any theme = hundreds of shop
	variations (see Presets.lua). Real Robux purchases go through
	MarketplaceService (dev products & game passes); in-game currency items
	fire a callback instead.

	QUICK START
	----------------------------------------------------------------------
		local Themes = require(script.Parent.Themes)
		local Shop   = require(script.Parent.Shop)

		local shop = Shop.new({
			Title    = "Item Shop",
			Theme    = "Midnight",   -- name or theme table
			Layout   = "Grid",       -- Grid/List/Carousel/Featured/Compact/Showcase
			CardStyle= "Elevated",   -- Flat/Elevated/Outline/Glass
			Columns  = 3,
		})

		shop:AddItem({
			Name="Golden Sword", Price=99, Image="rbxassetid://0",
			Badge="SALE", Category="Weapons",
			ProductId=1234567, PurchaseType="Product", -- Robux dev product
		})
		shop:AddItem({
			Name="VIP", Price=499, Image="rbxassetid://0",
			ProductId=7654321, PurchaseType="Gamepass",
		})
		shop:AddItem({
			Name="Coin Pack", Price=250, Currency="🪙",
			Callback=function(item) print("buy", item.Name) end, -- in-game currency
		})
		shop:Render()

	Every item purchase — Robux or in-game — also fires shop.OnPurchase.
]]

local TweenService     = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")

local Themes = require(script.Parent.Themes)

local LocalPlayer = Players.LocalPlayer

local Shop = {}
Shop.__index = Shop

Shop.Layouts    = { "Grid", "List", "Carousel", "Featured", "Compact", "Showcase" }
Shop.CardStyles = { "Flat", "Elevated", "Outline", "Glass" }

-- ── helpers ──────────────────────────────────────────────────────────────
local FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function tween(i, info, p) local t = TweenService:Create(i, info, p); t:Play(); return t end

local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do inst[k] = v end
	for _, ch in ipairs(children or {}) do ch.Parent = inst end
	return inst
end

local function corner(r, parent) return make("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent }) end
local function pad(px, parent)
	return make("UIPadding", {
		PaddingTop=UDim.new(0,px), PaddingBottom=UDim.new(0,px),
		PaddingLeft=UDim.new(0,px), PaddingRight=UDim.new(0,px), Parent=parent,
	})
end

local function getGuiParent()
	local ok, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 5) end)
	if ok and pg then return pg end
	return CoreGui
end

-- ── constructor ──────────────────────────────────────────────────────────
function Shop.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, Shop)

	local theme = cfg.Theme
	if type(theme) == "string" then theme = Themes.Get(theme) end
	self.Theme = theme or Themes.Get("Midnight")

	self.Config = {
		Title     = cfg.Title or "Shop",
		Layout    = table.find(Shop.Layouts, cfg.Layout) and cfg.Layout or "Grid",
		CardStyle = table.find(Shop.CardStyles, cfg.CardStyle) and cfg.CardStyle or "Elevated",
		Columns   = cfg.Columns or 3,
		Currency  = cfg.Currency or "R$",
		Size      = cfg.Size or UDim2.fromOffset(640, 460),
	}
	self.Items       = {}
	self.Categories  = {}         -- ordered list of category names
	self.ActiveCat   = "All"
	self.OnPurchase  = cfg.OnPurchase   -- function(item)

	-- Root: use provided parent Frame, or create our own ScreenGui.
	if cfg.Parent then
		self.Root = cfg.Parent
		self._ownsGui = false
	else
		self.ScreenGui = make("ScreenGui", {
			Name = "NovaShop", ResetOnSpawn = false, IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = getGuiParent(),
		})
		self.Root = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = self.Config.Size, BackgroundColor3 = self.Theme.Background,
			BorderSizePixel = 0, Parent = self.ScreenGui,
		})
		corner(14, self.Root)
		self._ownsGui = true
	end

	self:_buildChrome()
	return self
end

-- ── window chrome (title bar, category tabs, scroll body) ────────────────
function Shop:_buildChrome()
	local T = self.Theme
	local root = self.Root

	-- Header
	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = root,
	})
	make("TextLabel", {
		Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
		Text = self.Config.Title, TextSize = 20, TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})

	-- Balance pill (optional, driven by :SetBalance)
	self.BalancePill = make("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, self._ownsGui and -54 or -18, 0.5, 0),
		Size = UDim2.fromOffset(96, 30), BackgroundColor3 = T.SurfaceAlt,
		Font = Enum.Font.GothamBold, Text = self.Config.Currency .. " 0",
		TextSize = 13, TextColor3 = T.Accent, Parent = header,
	})
	corner(15, self.BalancePill)
	self.BalancePill.Visible = false

	if self._ownsGui then
		local close = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(30, 30), BackgroundColor3 = T.SurfaceAlt,
			Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = T.SubText, AutoButtonColor = false, Parent = header,
		})
		corner(8, close)
		close.MouseButton1Click:Connect(function() self:Destroy() end)
		self:_dragify(root, header)
	end

	-- Category bar
	self.CatBar = make("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 34),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, Parent = root,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.CatBar,
	})

	-- Body (scrolling item area)
	self.Body = make("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 92), Size = UDim2.new(1, -24, 1, -104),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = T.Stroke, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = root,
	})
end

function Shop:_dragify(frame, handle)
	local dragging, startInput, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, i.Position, frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startInput
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- ── data ─────────────────────────────────────────────────────────────────
function Shop:AddItem(item)
	assert(type(item) == "table", "AddItem expects a table")
	table.insert(self.Items, item)
	if item.Category and not table.find(self.Categories, item.Category) then
		table.insert(self.Categories, item.Category)
	end
	return self
end

function Shop:AddItems(list)
	for _, it in ipairs(list) do self:AddItem(it) end
	return self
end

function Shop:SetBalance(n)
	self.BalancePill.Visible = true
	self.BalancePill.Text = self.Config.Currency .. " " .. tostring(n)
	return self
end

-- ── purchase flow ────────────────────────────────────────────────────────
function Shop:_purchase(item)
	if item.ProductId and item.PurchaseType == "Gamepass" then
		pcall(function() MarketplaceService:PromptGamePassPurchase(LocalPlayer, item.ProductId) end)
	elseif item.ProductId then
		pcall(function() MarketplaceService:PromptProductPurchase(LocalPlayer, item.ProductId) end)
	end
	if item.Callback then task.spawn(item.Callback, item) end
	if self.OnPurchase then task.spawn(self.OnPurchase, item) end
end

-- ── card style painter ───────────────────────────────────────────────────
function Shop:_paintCard(card)
	local T = self.Theme
	local style = self.Config.CardStyle
	if style == "Flat" then
		card.BackgroundColor3 = T.Surface
	elseif style == "Elevated" then
		card.BackgroundColor3 = T.Surface
		make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4),
			Size = UDim2.new(1, 24, 1, 24), BackgroundTransparency = 1,
			Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0,0,0),
			ImageTransparency = 0.62, ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(49,49,450,450), ZIndex = 0, Parent = card,
		})
	elseif style == "Outline" then
		card.BackgroundColor3 = T.Background
		make("UIStroke", { Color = T.Stroke, Thickness = 1.5, Parent = card })
	elseif style == "Glass" then
		card.BackgroundColor3 = T.Surface
		card.BackgroundTransparency = 0.15
		make("UIStroke", { Color = T.Stroke, Thickness = 1, Transparency = 0.3, Parent = card })
	end
end

-- Build one item card. `variant` = "tile" (grid) or "row" (list).
function Shop:_makeCard(item, variant)
	local T = self.Theme
	local card = make("Frame", { BorderSizePixel = 0 })
	corner(12, card)
	self:_paintCard(card)

	local isRow = variant == "row"

	-- Thumbnail
	local thumb = make("ImageLabel", {
		BackgroundColor3 = T.SurfaceAlt, Image = item.Image or "",
		ScaleType = Enum.ScaleType.Crop, ZIndex = 2,
		Parent = card,
	})
	corner(10, thumb)
	if isRow then
		thumb.Size = UDim2.fromOffset(56, 56)
		thumb.Position = UDim2.fromOffset(8, 8)
	else
		thumb.Size = UDim2.new(1, -16, 0, 92)
		thumb.Position = UDim2.fromOffset(8, 8)
	end

	-- Badge (SALE / NEW / -50%)
	if item.Badge then
		local badge = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
			Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = T.Accent, Font = Enum.Font.GothamBold,
			Text = "  " .. tostring(item.Badge) .. "  ", TextSize = 11,
			TextColor3 = T.AccentText, ZIndex = 4, Parent = card,
		})
		corner(6, badge)
	end

	-- Name
	local name = make("TextLabel", {
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
		Text = item.Name or "Item", TextSize = 14, TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3, Parent = card,
	})

	-- Price + buy
	local priceStr = (item.Currency or self.Config.Currency) .. " " .. tostring(item.Price or 0)
	local price = make("TextLabel", {
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		Text = priceStr, TextSize = 13, TextColor3 = T.Accent,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = card,
	})
	local buy = make("TextButton", {
		BackgroundColor3 = T.Accent, Font = Enum.Font.GothamBold,
		Text = item.Owned and "Owned" or "Buy", TextSize = 13, TextColor3 = T.AccentText,
		AutoButtonColor = false, ZIndex = 3, Parent = card,
	})
	corner(8, buy)

	if isRow then
		name.Position = UDim2.fromOffset(74, 10); name.Size = UDim2.new(1, -220, 0, 18)
		price.Position = UDim2.fromOffset(74, 32); price.Size = UDim2.new(1, -220, 0, 16)
		buy.AnchorPoint = Vector2.new(1, 0.5); buy.Position = UDim2.new(1, -12, 0.5, 0)
		buy.Size = UDim2.fromOffset(84, 32)
	else
		name.Position = UDim2.fromOffset(10, 108); name.Size = UDim2.new(1, -20, 0, 18)
		price.Position = UDim2.fromOffset(10, 130); price.Size = UDim2.new(1, -20, 0, 16)
		buy.Position = UDim2.new(0, 10, 1, -42); buy.Size = UDim2.new(1, -20, 0, 32)
	end

	-- interactions
	local base = (self.Config.CardStyle == "Outline") and T.Background or T.Surface
	local function hover(on)
		tween(card, FAST, { BackgroundColor3 = on and T.SurfaceAlt or base })
	end
	card.MouseEnter:Connect(function() hover(true) end)
	card.MouseLeave:Connect(function() hover(false) end)

	if not item.Owned then
		buy.MouseButton1Click:Connect(function()
			tween(buy, FAST, { Size = buy.Size - UDim2.fromOffset(6, 4) }).Completed:Connect(function()
				tween(buy, FAST, { Size = buy.Size + UDim2.fromOffset(6, 4) })
			end)
			self:_purchase(item)
		end)
	else
		buy.BackgroundColor3 = T.SurfaceAlt
		buy.TextColor3 = T.SubText
	end

	return card
end

-- ── render ───────────────────────────────────────────────────────────────
function Shop:_clearBody()
	for _, ch in ipairs(self.Body:GetChildren()) do
		if not ch:IsA("UIListLayout") and not ch:IsA("UIGridLayout") and not ch:IsA("UIPadding") then
			ch:Destroy()
		end
	end
	for _, ch in ipairs(self.Body:GetChildren()) do
		if ch:IsA("UIListLayout") or ch:IsA("UIGridLayout") or ch:IsA("UIPadding") then ch:Destroy() end
	end
end

function Shop:_filtered()
	if self.ActiveCat == "All" then return self.Items end
	local out = {}
	for _, it in ipairs(self.Items) do
		if it.Category == self.ActiveCat then table.insert(out, it) end
	end
	return out
end

function Shop:_renderCategories()
	for _, ch in ipairs(self.CatBar:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	local T = self.Theme
	local names = { "All" }
	for _, cn in ipairs(self.Categories) do table.insert(names, cn) end

	for _, cn in ipairs(names) do
		local active = (cn == self.ActiveCat)
		local tab = make("TextButton", {
			Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = active and T.Accent or T.SurfaceAlt,
			Font = Enum.Font.GothamMedium, Text = "  " .. cn .. "  ", TextSize = 12,
			TextColor3 = active and T.AccentText or T.SubText, AutoButtonColor = false,
			Parent = self.CatBar,
		})
		corner(8, tab)
		tab.MouseButton1Click:Connect(function()
			self.ActiveCat = cn
			self:_renderCategories()
			self:_renderItems()
		end)
	end
end

function Shop:_renderItems()
	self:_clearBody()
	local layout = self.Config.Layout
	local items = self:_filtered()

	-- Normalize scroll direction (Carousel flips it to X; everything else is Y).
	if layout ~= "Carousel" then
		self.Body.ScrollingDirection = Enum.ScrollingDirection.Y
		self.Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
		self.Body.CanvasSize = UDim2.new()
	end

	local grid = (layout == "Grid" or layout == "Compact" or layout == "Showcase")
	if grid then
		local cols = self.Config.Columns
		local cardH
		if layout == "Compact" then cardH = 150; cols = math.max(cols, 4)
		elseif layout == "Showcase" then cardH = 210; cols = math.max(1, cols - 1)
		else cardH = 190 end
		local g = make("UIGridLayout", {
			CellPadding = UDim2.fromOffset(10, 10),
			CellSize = UDim2.new(1 / cols, -10, 0, cardH),
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Body,
		})
		g.HorizontalAlignment = Enum.HorizontalAlignment.Left
		for _, it in ipairs(items) do
			self:_makeCard(it, "tile").Parent = self.Body
		end

	elseif layout == "List" then
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Body })
		for _, it in ipairs(items) do
			local row = self:_makeCard(it, "row")
			row.Size = UDim2.new(1, 0, 0, 72)
			row.Parent = self.Body
		end

	elseif layout == "Carousel" then
		self.Body.ScrollingDirection = Enum.ScrollingDirection.X
		self.Body.AutomaticCanvasSize = Enum.AutomaticSize.X
		self.Body.CanvasSize = UDim2.new()
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
			VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = self.Body,
		})
		for _, it in ipairs(items) do
			local tile = self:_makeCard(it, "tile")
			tile.Size = UDim2.fromOffset(180, 200)
			tile.Parent = self.Body
		end

	elseif layout == "Featured" then
		make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Body })
		for idx, it in ipairs(items) do
			if idx == 1 then
				local hero = self:_makeCard(it, "tile")
				hero.Size = UDim2.new(1, 0, 0, 220)
				hero.LayoutOrder = 0
				hero.Parent = self.Body
			else
				local row = self:_makeCard(it, "row")
				row.Size = UDim2.new(1, 0, 0, 72)
				row.LayoutOrder = idx
				row.Parent = self.Body
			end
		end
	end
end

-- Public: (re)build everything.
function Shop:Render()
	self:_renderCategories()
	self:_renderItems()
	return self
end
Shop.Refresh = Shop.Render

-- Live-swap the theme.
function Shop:SetTheme(theme)
	if type(theme) == "string" then theme = Themes.Get(theme) end
	if not theme then return self end
	self.Theme = theme
	if self._ownsGui then self.Root.BackgroundColor3 = theme.Background end
	-- rebuild chrome + items with the new palette
	for _, ch in ipairs(self.Root:GetChildren()) do
		if ch:IsA("Frame") or ch:IsA("ScrollingFrame") or ch:IsA("TextLabel") then ch:Destroy() end
	end
	self:_buildChrome()
	self:Render()
	return self
end

function Shop:SetLayout(name)
	if table.find(Shop.Layouts, name) then
		self.Config.Layout = name
		-- reset body scroll direction that Carousel may have changed
		self.Body.ScrollingDirection = Enum.ScrollingDirection.Y
		self.Body.AutomaticCanvasSize = Enum.AutomaticSize.Y
		self.Body.CanvasSize = UDim2.new()
		self:_renderItems()
	end
	return self
end

function Shop:SetCardStyle(name)
	if table.find(Shop.CardStyles, name) then
		self.Config.CardStyle = name
		self:_renderItems()
	end
	return self
end

function Shop:Destroy()
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

return Shop
