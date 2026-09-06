--[[
	NovaUI  •  A modern UI library for Roblox
	----------------------------------------------------------------------
	A single-ModuleScript UI framework for building clean, animated
	interfaces inside real Roblox experiences — menus, HUDs, settings
	panels, admin tools, shops, and more. Works on PC, mobile and console.

	This is a *game* UI library: `require()` it from a LocalScript that lives
	in StarterPlayerScripts / StarterGui and drives the interface.

	QUICK START
	----------------------------------------------------------------------
		local NovaUI = require(path.to.NovaUI)

		local Window = NovaUI:CreateWindow({
			Title    = "My Game",
			SubTitle = "Settings",
			Size     = UDim2.fromOffset(560, 380),
			Accent   = Color3.fromRGB(120, 90, 255),
		})

		local Tab = Window:CreateTab("Main", "rbxassetid://0")
		local Section = Tab:CreateSection("Gameplay")

		Section:CreateToggle({
			Name = "Auto Sprint",
			Default = false,
			Callback = function(state) print("sprint:", state) end,
		})

	Every component returns a handle with :Set(...) / :Get() so you can drive
	it from code. Full API is documented in README.md.

	License / distribution: this file is meant to be published as a single
	asset (ModuleScript) on the Roblox Creator Store. See README.md for the
	recommended way to sell it for Robux and protect it.
]]

local NovaUI = {}
NovaUI.__index = NovaUI
NovaUI.Version = "1.0.0"

-- ── Services ─────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ── Theme ────────────────────────────────────────────────────────────────
local Themes = {
	Dark = {
		Background   = Color3.fromRGB(24, 24, 30),
		Surface      = Color3.fromRGB(32, 32, 40),
		SurfaceAlt   = Color3.fromRGB(40, 40, 50),
		Stroke       = Color3.fromRGB(55, 55, 68),
		Text         = Color3.fromRGB(236, 236, 244),
		SubText      = Color3.fromRGB(150, 150, 165),
		Accent       = Color3.fromRGB(120, 90, 255),
		AccentText   = Color3.fromRGB(255, 255, 255),
	},
	Light = {
		Background   = Color3.fromRGB(244, 245, 250),
		Surface      = Color3.fromRGB(255, 255, 255),
		SurfaceAlt   = Color3.fromRGB(238, 239, 245),
		Stroke       = Color3.fromRGB(220, 221, 230),
		Text         = Color3.fromRGB(28, 28, 36),
		SubText      = Color3.fromRGB(120, 122, 138),
		Accent       = Color3.fromRGB(120, 90, 255),
		AccentText   = Color3.fromRGB(255, 255, 255),
	},
}

-- ── Small helpers ────────────────────────────────────────────────────────
local FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function tween(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function make(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function corner(radius, parent)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

local function stroke(color, thickness, parent)
	return make("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(px, parent)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

-- Pick a safe place to parent the root ScreenGui. In real games this is
-- PlayerGui; the CoreGui fallback keeps it usable in Studio test playgrounds.
local function getGuiParent()
	local ok, playerGui = pcall(function()
		return LocalPlayer:WaitForChild("PlayerGui", 5)
	end)
	if ok and playerGui then
		return playerGui
	end
	return CoreGui
end

-- ════════════════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════════════════
function NovaUI:CreateWindow(opts)
	opts = opts or {}

	local self = setmetatable({}, NovaUI)
	self.Theme  = Themes[opts.Theme] and table.clone(Themes[opts.Theme]) or table.clone(Themes.Dark)
	if opts.Accent then
		self.Theme.Accent = opts.Accent
	end
	self.Tabs        = {}
	self.ActiveTab   = nil
	self._themeItems = {}    -- {instance, property, themeKey}

	local T = self.Theme
	local size = opts.Size or UDim2.fromOffset(560, 380)

	-- Root
	self.ScreenGui = make("ScreenGui", {
		Name = "NovaUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		Parent = getGuiParent(),
	})

	-- Main window frame
	self.Main = make("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = T.Background,
		BorderSizePixel = 0,
		Parent = self.ScreenGui,
	})
	corner(12, self.Main)
	stroke(T.Stroke, 1, self.Main)
	self:_track(self.Main, "BackgroundColor3", "Background")

	-- Drop shadow (simple layered frame)
	local shadow = make("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 48, 1, 48),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
		Parent = self.Main,
	})

	-- ── Title bar ────────────────────────────────────────────────────────
	local topBar = make("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = self.Main,
	})
	local titleHolder = make("Frame", {
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		BackgroundTransparency = 1,
		Parent = topBar,
	})
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = titleHolder,
	})
	local title = make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = opts.Title or "NovaUI",
		TextSize = 16,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleHolder,
	})
	self:_track(title, "TextColor3", "Text")
	if opts.SubTitle then
		local sub = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = opts.SubTitle,
			TextSize = 12,
			TextColor3 = T.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = titleHolder,
		})
		self:_track(sub, "TextColor3", "SubText")
	end

	-- Close button
	local closeBtn = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = T.SurfaceAlt,
		Text = "✕",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = T.SubText,
		AutoButtonColor = false,
		Parent = topBar,
	})
	corner(8, closeBtn)
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, FAST, { BackgroundColor3 = Color3.fromRGB(220, 70, 70), TextColor3 = Color3.new(1, 1, 1) })
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, FAST, { BackgroundColor3 = T.SurfaceAlt, TextColor3 = T.SubText })
	end)
	closeBtn.MouseButton1Click:Connect(function()
		self:Toggle(false)
	end)

	-- ── Body: sidebar + content ──────────────────────────────────────────
	local body = make("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		Parent = self.Main,
	})

	self.Sidebar = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, -12),
		Position = UDim2.fromOffset(10, 0),
		BackgroundColor3 = T.Surface,
		BorderSizePixel = 0,
		Parent = body,
	})
	corner(10, self.Sidebar)
	self:_track(self.Sidebar, "BackgroundColor3", "Surface")
	padding(8, self.Sidebar)
	local sideList = make("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.Sidebar,
	})
	self._sideList = sideList

	self.Content = make("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(170, 0),
		Size = UDim2.new(1, -180, 1, -12),
		BackgroundTransparency = 1,
		Parent = body,
	})

	self:_makeDraggable(self.Main, topBar)

	-- Toggle keybind (default: RightShift)
	self.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end)

	return self
end

-- Track an instance property so :SetTheme repaints it.
function NovaUI:_track(inst, prop, key)
	table.insert(self._themeItems, { inst = inst, prop = prop, key = key })
end

function NovaUI:_makeDraggable(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Show / hide the whole window with a scale-fade. Animates a UIScale so the
-- window's real pixel size is never touched.
function NovaUI:Toggle(state)
	if state == nil then
		state = not self.Main.Visible
	end
	local scale = self.Main:FindFirstChildOfClass("UIScale")
		or make("UIScale", { Scale = 1, Parent = self.Main })
	if state then
		self.Main.Visible = true
		scale.Scale = 0.9
		tween(scale, SMOOTH, { Scale = 1 })
	else
		tween(scale, FAST, { Scale = 0.9 }).Completed:Connect(function()
			self.Main.Visible = false
		end)
	end
end

function NovaUI:SetTheme(name)
	local theme = Themes[name]
	if not theme then return end
	local accent = self.Theme.Accent
	self.Theme = table.clone(theme)
	self.Theme.Accent = accent
	for _, item in ipairs(self._themeItems) do
		if item.inst and item.inst.Parent then
			tween(item.inst, FAST, { [item.prop] = self.Theme[item.key] })
		end
	end
end

function NovaUI:Destroy()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB
-- ════════════════════════════════════════════════════════════════════════
function NovaUI:CreateTab(name, icon)
	local T = self.Theme
	local tab = { Name = name, Window = self }

	-- Sidebar button
	local btn = make("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = T.SurfaceAlt,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = self.Sidebar,
	})
	corner(8, btn)
	local label = make("TextLabel", {
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(icon and 34 or 12, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = name,
		TextSize = 13,
		TextColor3 = T.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = btn,
	})
	if icon and icon ~= "" then
		make("ImageLabel", {
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(9, 8),
			BackgroundTransparency = 1,
			Image = icon,
			ImageColor3 = T.SubText,
			Parent = btn,
		})
	end

	-- Content page (scrolling)
	local page = make("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self.Content,
	})
	make("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = page,
	})
	padding(2, page)

	tab.Button = btn
	tab.Label  = label
	tab.Page   = page

	local function select()
		if self.ActiveTab == tab then return end
		for _, other in ipairs(self.Tabs) do
			other.Page.Visible = false
			tween(other.Button, FAST, { BackgroundTransparency = 1 })
			tween(other.Label, FAST, { TextColor3 = self.Theme.SubText })
		end
		tab.Page.Visible = true
		tween(btn, FAST, { BackgroundColor3 = self.Theme.SurfaceAlt, BackgroundTransparency = 0 })
		tween(label, FAST, { TextColor3 = self.Theme.Text })
		self.ActiveTab = tab
	end
	btn.MouseButton1Click:Connect(select)

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		select()
	end

	-- Attach component constructors to this tab.
	setmetatable(tab, { __index = self:_componentFactory(page) })
	return tab
end

-- ════════════════════════════════════════════════════════════════════════
--  COMPONENTS
-- ════════════════════════════════════════════════════════════════════════
function NovaUI:_componentFactory(page)
	local window = self
	local T = self.Theme
	local factory = {}

	-- Shared "card" container for a control.
	local function card(height)
		local c = make("Frame", {
			Size = UDim2.new(1, 0, 0, height or 40),
			BackgroundColor3 = T.Surface,
			BorderSizePixel = 0,
			Parent = page,
		})
		corner(8, c)
		window:_track(c, "BackgroundColor3", "Surface")
		return c
	end

	local function cardLabel(parent, text, sub)
		local holder = make("Frame", {
			Size = UDim2.new(1, sub and -110 or -70, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Parent = parent,
		})
		make("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = holder,
		})
		local name = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 13,
			TextColor3 = T.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = holder,
		})
		window:_track(name, "TextColor3", "Text")
		if sub then
			local s = make("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.Gotham,
				Text = sub,
				TextSize = 11,
				TextColor3 = T.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = holder,
			})
			window:_track(s, "TextColor3", "SubText")
		end
		return holder
	end

	-- ── Section header ───────────────────────────────────────────────────
	function factory:CreateSection(text)
		local lbl = make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = string.upper(text),
			TextSize = 11,
			TextColor3 = T.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = page,
		})
		window:_track(lbl, "TextColor3", "SubText")
		-- Sections can also spawn controls, so mirror the factory.
		return setmetatable({}, { __index = factory })
	end

	-- ── Button ───────────────────────────────────────────────────────────
	function factory:CreateButton(o)
		o = o or {}
		local c = card(40)
		local btn = make("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = c,
		})
		cardLabel(c, o.Name or "Button", o.Description)
		local chev = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = "›",
			TextSize = 18,
			TextColor3 = T.SubText,
			Parent = c,
		})
		btn.MouseEnter:Connect(function() tween(c, FAST, { BackgroundColor3 = window.Theme.SurfaceAlt }) end)
		btn.MouseLeave:Connect(function() tween(c, FAST, { BackgroundColor3 = window.Theme.Surface }) end)
		btn.MouseButton1Click:Connect(function()
			tween(chev, FAST, { TextColor3 = window.Theme.Accent })
			task.delay(0.15, function() tween(chev, FAST, { TextColor3 = window.Theme.SubText }) end)
			if o.Callback then task.spawn(o.Callback) end
		end)
		return { Instance = c }
	end

	-- ── Toggle ───────────────────────────────────────────────────────────
	function factory:CreateToggle(o)
		o = o or {}
		local state = o.Default or false
		local c = card(40)
		cardLabel(c, o.Name or "Toggle", o.Description)

		local track = make("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = state and window.Theme.Accent or T.SurfaceAlt,
			Parent = c,
		})
		corner(11, track)
		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = track,
		})
		corner(9, knob)

		local btn = make("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = c,
		})

		local handle = {}
		local function render(fire)
			tween(track, FAST, { BackgroundColor3 = state and window.Theme.Accent or window.Theme.SurfaceAlt })
			tween(knob, FAST, { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
			if fire and o.Callback then task.spawn(o.Callback, state) end
		end
		btn.MouseButton1Click:Connect(function()
			state = not state
			render(true)
		end)
		function handle:Set(v) state = v and true or false; render(true) end
		function handle:Get() return state end
		return handle
	end

	-- ── Slider ───────────────────────────────────────────────────────────
	function factory:CreateSlider(o)
		o = o or {}
		local min, max = o.Min or 0, o.Max or 100
		local value = math.clamp(o.Default or min, min, max)
		local decimals = o.Decimals or 0
		local c = card(54)
		cardLabel(c, o.Name or "Slider", o.Description)

		local valLabel = make("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 8),
			Size = UDim2.fromOffset(60, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = tostring(value),
			TextSize = 12,
			TextColor3 = window.Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = c,
		})

		local barBg = make("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 12, 1, -12),
			Size = UDim2.new(1, -24, 0, 6),
			BackgroundColor3 = T.SurfaceAlt,
			Parent = c,
		})
		corner(3, barBg)
		local fill = make("Frame", {
			Size = UDim2.fromScale((value - min) / (max - min), 1),
			BackgroundColor3 = window.Theme.Accent,
			Parent = barBg,
		})
		corner(3, fill)
		local knob = make("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 2,
			Parent = barBg,
		})
		corner(7, knob)

		local function round(n)
			local m = 10 ^ decimals
			return math.floor(n * m + 0.5) / m
		end

		local handle, dragging = {}, false
		local function setFromX(x)
			local rel = math.clamp((x - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
			value = round(min + (max - min) * rel)
			fill.Size = UDim2.fromScale(rel, 1)
			knob.Position = UDim2.new(rel, 0, 0.5, 0)
			valLabel.Text = tostring(value)
			if o.Callback then task.spawn(o.Callback, value) end
		end
		barBg.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFromX(i.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				setFromX(i.Position.X)
			end
		end)

		function handle:Set(v)
			value = math.clamp(round(v), min, max)
			local rel = (value - min) / (max - min)
			fill.Size = UDim2.fromScale(rel, 1)
			knob.Position = UDim2.new(rel, 0, 0.5, 0)
			valLabel.Text = tostring(value)
			if o.Callback then task.spawn(o.Callback, value) end
		end
		function handle:Get() return value end
		return handle
	end

	-- ── Dropdown ─────────────────────────────────────────────────────────
	function factory:CreateDropdown(o)
		o = o or {}
		local options = o.Options or {}
		local value = o.Default
		local open = false
		local c = card(40)
		cardLabel(c, o.Name or "Dropdown", o.Description)

		local box = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(130, 28),
			BackgroundColor3 = T.SurfaceAlt,
			Text = tostring(value or "Select"),
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = window.Theme.Text,
			AutoButtonColor = false,
			Parent = c,
		})
		corner(6, box)

		local listFrame = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = T.SurfaceAlt,
			ClipsDescendants = true,
			Visible = false,
			Parent = c,
		})
		listFrame.Position = UDim2.new(0, 0, 1, 4)
		corner(6, listFrame)
		local ll = make("UIListLayout", { Padding = UDim.new(0, 2), Parent = listFrame })
		padding(4, listFrame)

		local handle = {}
		local function rebuild()
			for _, ch in ipairs(listFrame:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			for _, opt in ipairs(options) do
				local ob = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					Text = tostring(opt),
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextColor3 = window.Theme.SubText,
					Parent = listFrame,
				})
				ob.MouseButton1Click:Connect(function()
					value = opt
					box.Text = tostring(opt)
					open = false
					listFrame.Visible = false
					c.Size = UDim2.new(1, 0, 0, 40)
					if o.Callback then task.spawn(o.Callback, opt) end
				end)
			end
		end
		rebuild()

		box.MouseButton1Click:Connect(function()
			open = not open
			listFrame.Visible = open
			local h = open and (#options * 28 + 8) or 0
			c.Size = UDim2.new(1, 0, 0, 40 + h)
			listFrame.Size = UDim2.new(1, 0, 0, h)
		end)

		function handle:Set(v) value = v; box.Text = tostring(v); if o.Callback then task.spawn(o.Callback, v) end end
		function handle:Get() return value end
		function handle:Refresh(newOptions) options = newOptions; rebuild() end
		return handle
	end

	-- ── TextInput ────────────────────────────────────────────────────────
	function factory:CreateInput(o)
		o = o or {}
		local c = card(40)
		cardLabel(c, o.Name or "Input", o.Description)
		local box = make("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(140, 28),
			BackgroundColor3 = T.SurfaceAlt,
			Text = o.Default or "",
			PlaceholderText = o.Placeholder or "Type…",
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = window.Theme.Text,
			PlaceholderColor3 = window.Theme.SubText,
			ClearTextOnFocus = false,
			Parent = c,
		})
		corner(6, box)
		padding(6, box)
		local handle = {}
		box.FocusLost:Connect(function(enter)
			if o.Callback then task.spawn(o.Callback, box.Text, enter) end
		end)
		function handle:Set(v) box.Text = tostring(v) end
		function handle:Get() return box.Text end
		return handle
	end

	-- ── Keybind ──────────────────────────────────────────────────────────
	function factory:CreateKeybind(o)
		o = o or {}
		local key = o.Default
		local listening = false
		local c = card(40)
		cardLabel(c, o.Name or "Keybind", o.Description)
		local box = make("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(90, 28),
			BackgroundColor3 = T.SurfaceAlt,
			Text = key and key.Name or "None",
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = window.Theme.Text,
			AutoButtonColor = false,
			Parent = c,
		})
		corner(6, box)
		box.MouseButton1Click:Connect(function()
			listening = true
			box.Text = "…"
		end)
		UserInputService.InputBegan:Connect(function(input, gpe)
			if listening and input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				key = input.KeyCode
				box.Text = key.Name
				if o.Callback then task.spawn(o.Callback, key) end
			elseif not gpe and key and input.KeyCode == key then
				if o.OnPress then task.spawn(o.OnPress) end
			end
		end)
		local handle = {}
		function handle:Get() return key end
		return handle
	end

	-- ── Label / Paragraph ────────────────────────────────────────────────
	function factory:CreateLabel(text)
		local c = card(34)
		make("TextLabel", {
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamMedium,
			Text = text or "",
			TextSize = 13,
			TextColor3 = window.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = c,
		})
		return { Instance = c }
	end

	function factory:CreateParagraph(title, body)
		local c = card(60)
		c.AutomaticSize = Enum.AutomaticSize.Y
		local holder = make("Frame", {
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(12, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = c,
		})
		padding(10, holder)
		make("UIListLayout", { Padding = UDim.new(0, 4), Parent = holder })
		make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = title or "",
			TextSize = 13,
			TextColor3 = window.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = holder,
		})
		make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = body or "",
			TextSize = 12,
			TextColor3 = window.Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = holder,
		})
		return { Instance = c }
	end

	return factory
end

-- ════════════════════════════════════════════════════════════════════════
--  NOTIFICATIONS (toast)
-- ════════════════════════════════════════════════════════════════════════
function NovaUI:Notify(o)
	o = o or {}
	local T = self.Theme
	if not self._notifyHolder then
		self._notifyHolder = make("Frame", {
			Name = "Notifications",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(300, 400),
			BackgroundTransparency = 1,
			Parent = self.ScreenGui,
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = self._notifyHolder,
		})
	end

	local toast = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Surface,
		BackgroundTransparency = 1,
		Parent = self._notifyHolder,
	})
	corner(10, toast)
	stroke(T.Stroke, 1, toast)
	make("Frame", { -- accent bar
		Size = UDim2.new(0, 4, 1, -12),
		Position = UDim2.fromOffset(0, 6),
		BackgroundColor3 = T.Accent,
		BorderSizePixel = 0,
		Parent = toast,
	})
	local holder = make("Frame", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.fromOffset(14, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = toast,
	})
	padding(10, holder)
	make("UIListLayout", { Padding = UDim.new(0, 3), Parent = holder })
	make("TextLabel", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = o.Title or "Notification",
		TextSize = 13,
		TextColor3 = T.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = holder,
	})
	if o.Content then
		make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = o.Content,
			TextSize = 12,
			TextColor3 = T.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = holder,
		})
	end

	toast.BackgroundTransparency = 1
	tween(toast, SMOOTH, { BackgroundTransparency = 0 })
	task.delay(o.Duration or 4, function()
		tween(toast, FAST, { BackgroundTransparency = 1 }).Completed:Connect(function()
			toast:Destroy()
		end)
	end)
end

return NovaUI
