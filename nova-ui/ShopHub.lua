--[[
	NovaUI • ShopHub
	----------------------------------------------------------------------
	A bright-red shop hub: a draggable window with a side-tab rail listing
	shop packs, and a content area that builds the selected pack's store
	(via Shop) with staggered card animations. Wire your game passes once and
	the buy buttons prompt the real purchase.

	QUICK START
	----------------------------------------------------------------------
		local ShopHub = require(path.to.ShopHub)

		local hub = ShopHub.launch({
			Title = "Shop",
			Accent = Color3.fromRGB(255, 40, 45),   -- bright red
			-- map pack "Pass" names to your real game-pass ids:
			GamePasses = { x2Coins = 111111, VIP = 222222, AutoFarm = 333333 },
			CheckOwnership = true,                   -- grey out passes the player owns
		})

	`launch` loads every pack in ShopPacks and shows the hub. Press the
	toggle key (default Right-Ctrl) to hide/show.

	Load-by-asset-id: publish the NovaUI folder as a Roblox asset and load it
	with Loader.lua — see nova-ui/Loader.lua.
]]

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")

local Themes = require(script.Parent.Themes)
local Shop   = require(script.Parent.Shop)
local Anim   = require(script.Parent.Animations)
local Packs  = require(script.Parent.ShopPacks)

local LocalPlayer = Players.LocalPlayer

local ShopHub = {}
ShopHub.__index = ShopHub

-- ── helpers ────────────────────────────────────────────────────────────────
local FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local function tween(i, info, p) local t = TweenService:Create(i, info, p); t:Play(); return t end
local function make(cls, props, kids)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do o[k] = v end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	return o
end
local function corner(r, p) return make("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function stroke(col, t, p) return make("UIStroke", { Color = col, Thickness = t or 1, Parent = p }) end
local function guiParent()
	local ok, pg = pcall(function() return LocalPlayer:WaitForChild("PlayerGui", 5) end)
	return (ok and pg) or CoreGui
end

-- ── constructor ──────────────────────────────────────────────────────────
function ShopHub.new(cfg)
	cfg = cfg or {}
	local self = setmetatable({}, ShopHub)
	self.Theme = Themes.Get(cfg.Theme or "Scarlet") or Themes.Get("Scarlet")
	if cfg.Accent then self.Theme.Accent = cfg.Accent end
	self.GamePasses    = cfg.GamePasses or {}
	self.CheckOwnership = cfg.CheckOwnership ~= false
	self.Glass = cfg.Glass == true   -- clean transparent look
	self.Packs   = {}
	self.TabBtns = {}
	self.Active  = nil
	self.Current = nil
	self.ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl

	local T = self.Theme
	self.ScreenGui = make("ScreenGui", {
		Name = "NovaShopHub", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = guiParent(),
	})
	self.Main = make("Frame", {
		Name = "Hub", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = cfg.Size or UDim2.fromOffset(720, 460), BackgroundColor3 = T.Background,
		BorderSizePixel = 0, Parent = self.ScreenGui,
	})
	corner(14, self.Main)
	stroke(T.Accent, self.Glass and 2 or 1.5, self.Main)

	-- Glass: dim the game behind for readability, then make the window
	-- and its panels semi-transparent for a clean acrylic look.
	if self.Glass then
		local backdrop = make("Frame", {
			Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 0, Parent = self.ScreenGui,
		})
		backdrop.ZIndex = 0
		self.Main.ZIndex = 1
		self.Main.BackgroundTransparency = 0.15
	end

	-- title bar
	local bar = make("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = self.Main })
	make("Frame", { -- accent underline
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, 0),
		Size = UDim2.new(1, -28, 0, 2), BackgroundColor3 = T.Accent, BorderSizePixel = 0, Parent = bar,
	})
	make("TextLabel", {
		Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, Text = cfg.Title or "Shop", TextSize = 20, TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = bar,
	})
	local close = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = T.SurfaceAlt, Text = "✕", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = T.SubText, AutoButtonColor = false, Parent = bar,
	})
	corner(8, close)
	close.MouseButton1Click:Connect(function() self:Toggle(false) end)

	-- side-tab rail
	self.Rail = make("ScrollingFrame", {
		Name = "Rail", Position = UDim2.fromOffset(10, 52), Size = UDim2.new(0, 150, 1, -62),
		BackgroundColor3 = T.Surface, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self.Main,
	})
	corner(10, self.Rail)
	if self.Glass then self.Rail.BackgroundTransparency = 0.3 end
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Rail })
	make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = self.Rail })

	-- content area (a Shop is built into this frame)
	self.Content = make("Frame", {
		Name = "Content", Position = UDim2.fromOffset(170, 52), Size = UDim2.new(1, -180, 1, -62),
		BackgroundTransparency = 1, Parent = self.Main,
	})

	self:_dragify(self.Main, bar)
	UserInputService.InputBegan:Connect(function(i, gpe)
		if not gpe and i.KeyCode == self.ToggleKey then self:Toggle() end
	end)
	return self
end

function ShopHub:_dragify(frame, handle)
	local dragging, start, origin
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, origin = true, i.Position, frame.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			frame.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
		end
	end)
end

-- ── packs ──────────────────────────────────────────────────────────────────
function ShopHub:AddPack(pack)
	table.insert(self.Packs, pack)
	local T = self.Theme
	local btn = make("TextButton", {
		Name = pack.Name, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.SurfaceAlt,
		BackgroundTransparency = 1, AutoButtonColor = false, Text = "  " .. pack.Name,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = self.Rail,
	})
	corner(8, btn)
	self.TabBtns[pack] = btn
	btn.MouseButton1Click:Connect(function() self:Select(pack) end)
	if #self.Packs == 1 then self:Select(pack) end
	return self
end

-- Resolve game-pass hooks + ownership into concrete Shop items.
function ShopHub:_resolveItems(pack)
	local out = {}
	for _, raw in ipairs(pack.Items) do
		local item = table.clone(raw)
		item.Currency = item.Currency or pack.Currency
		if item.Pass then
			local id = self.GamePasses[item.Pass]
			if id then
				item.ProductId = id
				item.PurchaseType = "Gamepass"
				if self.CheckOwnership then
					local ok, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, id)
					end)
					if ok and owns then item.Owned = true end
				end
			end
		end
		table.insert(out, item)
	end
	return out
end

function ShopHub:Select(pack)
	if self.Active == pack then return end
	-- repaint rail
	for p, btn in pairs(self.TabBtns) do
		local on = (p == pack)
		tween(btn, FAST, { BackgroundTransparency = on and 0 or 1, BackgroundColor3 = self.Theme.SurfaceAlt })
		tween(btn, FAST, { TextColor3 = on and self.Theme.Text or self.Theme.SubText })
	end
	self.Active = pack

	-- The shop is built into Content (no own ScreenGui), so clear it by hand.
	for _, child in ipairs(self.Content:GetChildren()) do child:Destroy() end
	self.Current = nil
	-- Glass mode only makes the WINDOW transparent — packs keep their own
	-- layout, card style and colours (the features are untouched).
	local shop = Shop.new({
		Parent = self.Content,
		Theme = pack.Theme or self.Theme,
		Layout = pack.Layout or "Grid",
		CardStyle = pack.CardStyle or "Elevated",
		Title = pack.Name,
		Columns = pack.Columns or 3,
		Currency = pack.Currency or "R$",
	})
	if pack.Accent then shop.Theme.Accent = pack.Accent end
	shop:AddItems(self:_resolveItems(pack))
	shop:Render()
	self.Current = shop
	-- animate the cards in
	task.defer(function()
		if shop.Body then Anim.Stagger(shop.Body, "PopIn", 0.03) end
	end)
end

-- ── lifecycle ──────────────────────────────────────────────────────────────
function ShopHub:Show() self.Main.Visible = true; Anim.PopIn(self.Main) end
function ShopHub:Toggle(state)
	if state == nil then state = not self.Main.Visible end
	if state then self:Show()
	else Anim.PopOut(self.Main) end
end
function ShopHub:Destroy() if self.ScreenGui then self.ScreenGui:Destroy() end end

-- ── one-call launcher: loads every ShopPack ──────────────────────────────
function ShopHub.launch(cfg)
	local hub = ShopHub.new(cfg)
	for _, pack in ipairs(Packs) do hub:AddPack(pack) end
	hub:Show()
	return hub
end

return ShopHub
