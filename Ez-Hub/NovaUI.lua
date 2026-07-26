--[[
	NovaUI — a single-file, reactive, futuristic Roblox hub UI.

	Inspired by Fusion (Elttob): the whole thing is driven by a tiny inlined
	*reactive core* — `State`, `Computed`, and `Observe` with automatic
	dependency tracking — so the interface updates itself when state changes,
	instead of you wiring up every property by hand. Because executors can't
	`require` an external Fusion module, the reactive core is bundled right
	here; everything is in this one script.

	Aesthetic: glassmorphism (translucent surfaces over a real backdrop blur),
	animated neon gradient borders, soft glows, spring motion, scanline sheen.

	All devices, all executors (same hardening as EzUI):
	  * gethui / get_hidden_gui / CoreGui / syn.protect_gui with a PlayerGui
	    fallback; task.* and wait shims; everything pcall-guarded.
	  * Floating draggable ☰ button (touch), keyboard toggle (PC), gamepad
	    button toggle + controller-selectable controls (console).
	  * Responsive sizing that re-fits on rotation/resize.

	Usage:
		local Nova = loadstring(game:HttpGet("...NovaUI.lua"))()
		local win  = Nova.new({ Title = "Nova Hub", Accent = Color3.fromRGB(0,200,255) })
		local tab  = win:Tab("Main", "⚡")
		local flying = Nova.State(false)               -- reactive value
		tab:Toggle("Fly", flying)                       -- bound to state
		tab:Label(Nova.Computed(function()              -- derived, auto-updates
			return "Fly is " .. (flying:get() and "ON" or "OFF")
		end))
		tab:Slider("WalkSpeed", 16, 200, 16, function(v) end)
		win:Notify("Online", "Nova systems nominal.", 4)
--]]

--==============================================================================
-- Services & cross-executor shims
--==============================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")

local taskWait  = (task and task.wait) or wait
local taskSpawn = (task and task.spawn) or function(fn, ...) return coroutine.wrap(fn)(...) end

local function getGuiParent()
	local candidates = {
		function() return gethui and gethui() end,
		function() return get_hidden_gui and get_hidden_gui() end,
		function() return game:GetService("CoreGui") end,
	}
	for _, get in ipairs(candidates) do
		local ok, res = pcall(get)
		if ok and res then return res end
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function protectGui(gui)
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	pcall(function() if protectgui then protectgui(gui) end end)
end

local function mountGui(gui)
	protectGui(gui)
	local parent = getGuiParent()
	local ok = pcall(function() gui.Parent = parent end)
	if not ok or not gui.Parent then
		pcall(function() gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end)
	end
	return gui.Parent
end

--==============================================================================
-- Reactive core (Fusion-inspired, auto-tracking)
--==============================================================================

local Reactive = {}
do
	local captureStack = {}

	local State = {}
	State.__index = State

	function State.new(v)
		return setmetatable({ _value = v, _subs = {} }, State)
	end

	-- Reading inside a Computed registers a dependency automatically.
	function State:get()
		local cap = captureStack[#captureStack]
		if cap then cap[self] = true end
		return self._value
	end

	function State:set(v)
		if self._value == v then return end
		self._value = v
		for fn in pairs(self._subs) do
			taskSpawn(fn) -- isolate subscribers so one error can't break the rest
		end
	end

	function State:subscribe(fn)
		self._subs[fn] = true
		return function() self._subs[fn] = nil end
	end

	-- A value derived from other states; recomputes when any dependency changes.
	local function Computed(fn)
		local out = State.new(nil)
		local disconnects = {}
		local function recompute()
			for _, d in ipairs(disconnects) do d() end
			disconnects = {}
			local cap = {}
			table.insert(captureStack, cap)
			local ok, res = pcall(fn)
			table.remove(captureStack)
			for dep in pairs(cap) do
				table.insert(disconnects, dep:subscribe(recompute))
			end
			if ok then out._value = res; for f in pairs(out._subs) do taskSpawn(f) end end
		end
		recompute()
		return out
	end

	-- Run fn(value) immediately and on every change. Returns an unsubscribe fn.
	local function Observe(state, fn)
		local function run() fn(state._value) end
		run()
		return state:subscribe(run)
	end

	local function isState(v)
		return type(v) == "table" and getmetatable(v) == State
	end

	Reactive.State    = function(v) return State.new(v) end
	Reactive.Computed = Computed
	Reactive.Observe  = Observe
	Reactive.isState  = isState
end

local State    = Reactive.State
local Computed  = Reactive.Computed
local Observe    = Reactive.Observe
local isState    = Reactive.isState

--==============================================================================
-- Theme (one accent gradient drives the whole neon look)
--==============================================================================

local Theme = {
	Accent   = Color3.fromRGB(0, 210, 255),
	Accent2  = Color3.fromRGB(130, 90, 255),
	Bg       = Color3.fromRGB(9, 11, 18),
	Glass    = Color3.fromRGB(16, 19, 30),
	Surface  = Color3.fromRGB(22, 26, 40),
	Surface2 = Color3.fromRGB(30, 36, 54),
	Stroke   = Color3.fromRGB(46, 54, 82),
	Text     = Color3.fromRGB(236, 241, 255),
	Sub      = Color3.fromRGB(140, 150, 180),
	Off      = Color3.fromRGB(38, 44, 64),
	Font     = Enum.Font.GothamMedium,
	Bold     = Enum.Font.GothamBold,
	Mono     = Enum.Font.Code,
}

local function accentSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent),
		ColorSequenceKeypoint.new(1, Theme.Accent2),
	})
end

local SPRING = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GLIDE  = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FAST    = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

--==============================================================================
-- Building blocks
--==============================================================================

local function new(class, props, children)
	local inst = Instance.new(class)
	if class == "TextButton" or class == "ImageButton" or class == "TextBox" then
		inst.Selectable = true  -- controller navigation
		inst.Active = true
	end
	if props then
		for k, v in pairs(props) do if k ~= "Parent" then inst[k] = v end end
		if props.Parent then inst.Parent = props.Parent end
	end
	if children then for _, c in ipairs(children) do c.Parent = inst end end
	return inst
end

local function tween(inst, info, goal)
	local t = TweenService:Create(inst, info, goal); t:Play(); return t
end

local function corner(inst, r) return new("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = inst }) end

local function pad(inst, all)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all), Parent = inst,
	})
end

-- Plain 1px border.
local function stroke(inst, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Theme.Stroke, Thickness = thickness or 1,
		Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = inst,
	})
end

-- Animated neon gradient border (the signature futuristic edge).
local function neonBorder(inst, thickness, transparency)
	local s = new("UIStroke", {
		Thickness = thickness or 1.4,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
	local grad = new("UIGradient", { Color = accentSequence(), Rotation = 0, Parent = s })
	tween(grad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
	return s, grad
end

-- Soft radial glow behind an element (ImageColor tinted to accent).
local function glow(parent, color, transparency, spread)
	return new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://5028857084",
		ImageColor3 = color or Theme.Accent,
		ImageTransparency = transparency or 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24, 24, 24, 24),
		Size = UDim2.new(1, spread or 26, 1, spread or 26),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
end

local function shadow(parent)
	return new("ImageLabel", {
		Name = "Shadow", BackgroundTransparency = 1, Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.4,
		ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 70, 1, 70), Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 0, Parent = parent,
	})
end

-- Vertical glass gradient for translucent panels.
local function glassGradient(inst)
	return new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.02),
			NumberSequenceKeypoint.new(1, 0.10),
		}),
		Parent = inst,
	})
end

-- Bind a text property to a plain string OR a reactive State/Computed.
local function bindText(label, textOrState)
	if isState(textOrState) then
		Observe(textOrState, function(v) label.Text = tostring(v) end)
	else
		label.Text = tostring(textOrState)
	end
end

--==============================================================================
-- Drag (locals only; yields to sliders)
--==============================================================================

local draggingSlider = false

local function dragify(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if draggingSlider then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or draggingSlider then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - dragStart
			tween(frame, FAST, { Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y) })
		end
	end)
end

--==============================================================================
-- Library
--==============================================================================

local NovaUI = {}
NovaUI.__index = NovaUI

-- Expose the reactive core for power users.
NovaUI.State    = State
NovaUI.Computed  = Computed
NovaUI.Observe   = Observe
NovaUI.Theme     = Theme

-- Keyboard-only keybind capture (fixes original: ignore non-keyboard input).
local awaitingKeybind = nil
UserInputService.InputBegan:Connect(function(input)
	if awaitingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
		awaitingKeybind(input.KeyCode); awaitingKeybind = nil
	end
end)

function NovaUI.new(config)
	config = config or {}
	local self = setmetatable({}, NovaUI)

	if config.Accent then Theme.Accent = config.Accent end
	if config.Accent2 then Theme.Accent2 = config.Accent2 end
	self.title          = config.Title or "Nova Hub"
	self.keybind         = config.Keybind or Enum.KeyCode.RightShift
	self.gamepadKeybind  = config.GamepadKeybind or Enum.KeyCode.ButtonSelect
	self.useBlur         = config.Blur ~= false
	self.tabs            = {}
	self.activeTab       = nil

	-- Clean up any previous instance.
	local cleanupTargets = {}
	pcall(function() table.insert(cleanupTargets, getGuiParent()) end)
	pcall(function() table.insert(cleanupTargets, Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
	for _, p in ipairs(cleanupTargets) do
		if p then for _, v in ipairs(p:GetChildren()) do if v.Name == "NovaUI" then v:Destroy() end end end
	end

	local gui = new("ScreenGui", {
		Name = "NovaUI", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	mountGui(gui)
	self.gui = gui

	-- Backdrop blur for real glassmorphism (optional).
	if self.useBlur then
		local blur = Instance.new("BlurEffect")
		blur.Size = 0
		pcall(function() blur.Parent = Lighting end)
		self.blur = blur
	end

	--------------------------------------------------------------------------
	-- Responsive sizing
	--------------------------------------------------------------------------
	local WIN_W, WIN_H = 560, 400
	local function viewport()
		local v = gui.AbsoluteSize
		if v.X < 2 or v.Y < 2 then v = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 600) end
		return v
	end
	local function computeSize()
		local v = viewport()
		return math.floor(math.min(WIN_W, v.X - 24)), math.floor(math.min(WIN_H, v.Y - 48))
	end
	local function expandedSize() local w, h = computeSize(); return UDim2.fromOffset(w, h) end
	local function collapsedSize() local w = computeSize(); return UDim2.fromOffset(w, 48) end

	--------------------------------------------------------------------------
	-- Root window (glass)
	--------------------------------------------------------------------------
	local window = new("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.new(0.5, 0, 0.5, 0),
		Size = expandedSize(), BackgroundColor3 = Theme.Glass,
		BackgroundTransparency = 0.08, BorderSizePixel = 0, Parent = gui,
	})
	shadow(window)
	glassGradient(window)
	corner(window, 14)
	neonBorder(window, 1.6, 0.15)
	self.window = window

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		window.Size = self.minimized and collapsedSize() or expandedSize()
	end)

	--------------------------------------------------------------------------
	-- Title bar
	--------------------------------------------------------------------------
	local topbar = new("Frame", {
		Name = "TopBar", Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.25,
		BorderSizePixel = 0, Parent = window,
	})
	corner(topbar, 14)
	new("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14),
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = topbar })

	-- Glowing accent emblem
	local emblem = new("Frame", {
		Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 18, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = topbar,
	})
	corner(emblem, 6)
	glow(emblem, Theme.Accent, 0.35, 22)

	local titleLabel = new("TextLabel", {
		Font = Theme.Bold, TextSize = 17, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
		Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -140, 1, 0), Parent = topbar,
	})
	bindText(titleLabel, self.title)
	-- Neon sheen sweeping across the title.
	local titleGrad = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.Text),
			ColorSequenceKeypoint.new(0.5, Theme.Accent),
			ColorSequenceKeypoint.new(1, Theme.Text),
		}),
		Offset = Vector2.new(-1, 0), Parent = titleLabel,
	})
	tween(titleGrad, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), { Offset = Vector2.new(1, 0) })

	local function iconButton(offset, symbol, color, onClick)
		local b = new("TextButton", {
			Text = symbol, Font = Theme.Bold, TextSize = 18, TextColor3 = Theme.Sub,
			BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 0.2,
			Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, offset, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5), AutoButtonColor = false, BorderSizePixel = 0, Parent = topbar,
		})
		corner(b, 8)
		b.MouseEnter:Connect(function() tween(b, FAST, { TextColor3 = color, BackgroundTransparency = 0 }) end)
		b.MouseLeave:Connect(function() tween(b, FAST, { TextColor3 = Theme.Sub, BackgroundTransparency = 0.2 }) end)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	self.minimized = false
	iconButton(-48, "–", Theme.Text, function()
		self.minimized = not self.minimized
		tween(window, GLIDE, { Size = self.minimized and collapsedSize() or expandedSize() })
	end)
	iconButton(-14, "✕", Color3.fromRGB(255, 90, 110), function()
		self:Destroy()
	end)

	dragify(window, topbar)

	--------------------------------------------------------------------------
	-- Body: sidebar + content
	--------------------------------------------------------------------------
	local body = new("Frame", {
		Name = "Body", Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 1, -46),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = window,
	})

	local sidebar = new("Frame", {
		Name = "Sidebar", Size = UDim2.new(0, 156, 1, 0),
		BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = body,
	})
	new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = sidebar })

	local tabList = new("ScrollingFrame", {
		Name = "TabList", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebar,
	})
	pad(tabList, 10)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })
	self.tabList = tabList

	local content = new("Frame", {
		Name = "Content", Position = UDim2.new(0, 156, 0, 0), Size = UDim2.new(1, -156, 1, 0),
		BackgroundTransparency = 1, Parent = body,
	})
	self.content = content

	--------------------------------------------------------------------------
	-- Notifications
	--------------------------------------------------------------------------
	self.notifHolder = new("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32), BackgroundTransparency = 1, Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.notifHolder,
	})

	--------------------------------------------------------------------------
	-- Visibility (mouse / touch / keyboard / gamepad)
	--------------------------------------------------------------------------
	local function setVisible(v)
		self.window.Visible = v
		if self.blur then tween(self.blur, GLIDE, { Size = v and 16 or 0 }) end
		if v and self.activeTab and UserInputService.GamepadEnabled then
			pcall(function() game:GetService("GuiService").SelectedObject = self.activeTab.button end)
		elseif not v then
			pcall(function() game:GetService("GuiService").SelectedObject = nil end)
		end
	end
	self.setVisible = setVisible
	if self.blur then tween(self.blur, GLIDE, { Size = 16 }) end

	-- Floating action button (primary control on touch).
	local fab = new("TextButton", {
		Name = "Toggle", Text = "☰", Font = Theme.Bold, TextSize = 24, TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Theme.Accent, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 18, 0, 96),
		AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 60, Parent = gui,
	})
	corner(fab, 25)
	glow(fab, Theme.Accent, 0.35, 30)
	shadow(fab)
	self.floatBtn = fab

	local fabDragging, fabMoved, fabStart, fabStartPos
	fab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			fabDragging = true; fabMoved = false; fabStart = input.Position; fabStartPos = fab.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if fabDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - fabStart
			if d.Magnitude > 5 then fabMoved = true end
			fab.Position = UDim2.new(fabStartPos.X.Scale, fabStartPos.X.Offset + d.X, fabStartPos.Y.Scale, fabStartPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if fabDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			fabDragging = false
			if not fabMoved then setVisible(not self.window.Visible) end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.keybind or input.KeyCode == self.gamepadKeybind then
			setVisible(not self.window.Visible)
		end
	end)

	return self
end

--==============================================================================
-- Tabs
--==============================================================================

function NovaUI:Tab(name, icon)
	local tab = { name = name, ui = self }

	local button = new("TextButton", {
		Name = name, Text = "", BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 1,
		AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 36), BorderSizePixel = 0, Parent = self.tabList,
	})
	corner(button, 9)

	local indicator = new("Frame", {
		Size = UDim2.new(0, 3, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = button,
	})
	corner(indicator, 2)
	glow(indicator, Theme.Accent, 0.4, 10)

	local label = new("TextLabel", {
		Text = (icon and (icon .. "  ") or "") .. name, Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Sub,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -14, 1, 0), Parent = button,
	})

	local page = new("ScrollingFrame", {
		Name = name, Visible = false, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = self.content,
	})
	pad(page, 14)
	new("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

	tab.button, tab.label, tab.indicator, tab.page = button, label, indicator, page
	table.insert(self.tabs, tab)

	local function select()
		if self.activeTab == tab then return end
		for _, t in ipairs(self.tabs) do
			t.page.Visible = false
			tween(t.button, FAST, { BackgroundTransparency = 1 })
			tween(t.label, FAST, { TextColor3 = Theme.Sub })
			tween(t.indicator, FAST, { Size = UDim2.new(0, 3, 0, 0) })
		end
		page.Visible = true
		tween(button, FAST, { BackgroundTransparency = 0.15 })
		tween(label, FAST, { TextColor3 = Theme.Text })
		tween(indicator, SPRING, { Size = UDim2.new(0, 3, 0, 20) })
		self.activeTab = tab
	end
	button.MouseButton1Click:Connect(select)
	button.MouseEnter:Connect(function() if self.activeTab ~= tab then tween(button, FAST, { BackgroundTransparency = 0.55 }) end end)
	button.MouseLeave:Connect(function() if self.activeTab ~= tab then tween(button, FAST, { BackgroundTransparency = 1 }) end end)
	if not self.activeTab then select() end

	--------------------------------------------------------------------------
	-- Element helpers
	--------------------------------------------------------------------------
	local function card(height)
		local frame = new("Frame", {
			BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.2,
			Size = UDim2.new(1, 0, 0, height or 40), BorderSizePixel = 0, Parent = page,
		})
		corner(frame, 10)
		stroke(frame, Theme.Stroke, 1, 0.45)
		return frame
	end

	local function rowLabel(parent, text)
		local l = new("TextLabel", {
			Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -130, 1, 0), Parent = parent,
		})
		bindText(l, text)
		return l
	end

	function tab:Section(text)
		local l = new("TextLabel", {
			Font = Theme.Bold, TextSize = 12, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Parent = page,
		})
		bindText(l, isState(text) and text or string.upper(tostring(text)))
		return l
	end

	function tab:Label(text)
		local l = new("TextLabel", {
			Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18), Parent = page,
		})
		bindText(l, text)
		return l
	end

	function tab:Button(text, callback)
		callback = callback or function() end
		local frame = card(40)
		local btn = new("TextButton", {
			Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame,
		})
		local lbl = new("TextLabel", {
			Text = tostring(text), Font = Theme.Font, TextSize = 14, TextColor3 = Theme.Text,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame,
		})
		frame.MouseEnter:Connect(function() tween(frame, FAST, { BackgroundTransparency = 0 }); tween(lbl, FAST, { TextColor3 = Theme.Accent }) end)
		frame.MouseLeave:Connect(function() tween(frame, FAST, { BackgroundTransparency = 0.2 }); tween(lbl, FAST, { TextColor3 = Theme.Text }) end)
		btn.MouseButton1Click:Connect(function()
			local g = glow(frame, Theme.Accent, 0.2, 20)
			tween(g, GLIDE, { ImageTransparency = 1 })
			taskWait(0.3); g:Destroy()
			pcall(callback)
		end)
		return { instance = frame }
	end

	-- Toggle bound to a reactive State (pass a State, or a default + callback).
	function tab:Toggle(text, stateOrDefault, callback)
		local state = isState(stateOrDefault) and stateOrDefault or State(stateOrDefault and true or false)
		callback = callback or function() end
		local frame = card(40)
		rowLabel(frame, text)

		local track = new("Frame", {
			Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = frame,
		})
		corner(track, 12)
		local trackGlow = glow(track, Theme.Accent, 1, 14)
		local knob = new("Frame", {
			Size = UDim2.new(0, 18, 0, 18), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = track,
		})
		corner(knob, 9)

		local function render(v)
			tween(track, GLIDE, { BackgroundColor3 = v and Theme.Accent or Theme.Off })
			tween(trackGlow, GLIDE, { ImageTransparency = v and 0.35 or 1 })
			tween(knob, SPRING, {
				Position = v and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = v and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
			})
		end
		Observe(state, render)
		state:subscribe(function() pcall(callback, state._value) end)

		local click = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
		click.MouseButton1Click:Connect(function() state:set(not state:get()) end)

		return state
	end

	function tab:Slider(text, min, max, default, callback)
		callback = callback or function() end
		min, max = min or 0, max or 100
		local state = State(math.clamp(default or min, min, max))
		local frame = card(54)
		rowLabel(frame, text)

		local valueBox = new("TextLabel", {
			Font = Theme.Mono, TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1, Position = UDim2.new(1, -14, 0, 9), AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0, 60, 0, 16), Parent = frame,
		})
		local track = new("Frame", {
			Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -16),
			BackgroundColor3 = Theme.Off, BorderSizePixel = 0, Parent = frame,
		})
		corner(track, 3)
		local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track })
		corner(fill, 3)
		new("UIGradient", { Color = accentSequence(), Parent = fill })
		local knob = new("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, Parent = fill })
		corner(knob, 7)
		glow(knob, Theme.Accent, 0.3, 12)

		Observe(state, function(v)
			local scale = (max == min) and 0 or (v - min) / (max - min)
			tween(fill, FAST, { Size = UDim2.new(scale, 0, 1, 0) })
			valueBox.Text = tostring(v)
		end)
		state:subscribe(function() pcall(callback, state._value) end)

		local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
			Size = UDim2.new(1, -28, 0, 30), Position = UDim2.new(0, 14, 1, -13), AnchorPoint = Vector2.new(0, 0.5), Parent = frame })

		local dragging = false
		local function update(input)
			local scale = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			state:set(math.floor(scale * (max - min) + min + 0.5))
		end
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; draggingSlider = true; update(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false; draggingSlider = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
		end)

		return state
	end

	function tab:Dropdown(text, options, default, callback)
		callback = callback or function() end
		options = options or {}
		local state = State(default or options[1])
		local open = false
		local frame = card(40)
		frame.ClipsDescendants = true
		rowLabel(frame, text)

		local chevron = new("TextLabel", { Text = "▾", Font = Theme.Bold, TextSize = 14, TextColor3 = Theme.Sub,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 16, 0, 40), Parent = frame })
		local current = new("TextLabel", { Font = Theme.Mono, TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -36, 0, 0), Size = UDim2.new(0, 150, 0, 40), Parent = frame })
		Observe(state, function(v) current.Text = tostring(v or "") end)

		local listHolder = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 1, -40), Parent = frame })
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder })
		pad(listHolder, 6)

		local handle = {}
		function handle:Toggle(force)
			open = (force ~= nil) and force or not open
			tween(frame, GLIDE, { Size = UDim2.new(1, 0, 0, open and (40 + #options * 30 + 12) or 40) })
			tween(chevron, FAST, { Rotation = open and 180 or 0 })
		end
		local function rebuild()
			for _, c in ipairs(listHolder:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			for _, opt in ipairs(options) do
				local o = new("TextButton", { Text = tostring(opt), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Sub,
					BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 0.2, AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Parent = listHolder })
				corner(o, 6)
				o.MouseEnter:Connect(function() tween(o, FAST, { BackgroundTransparency = 0, TextColor3 = Theme.Text }) end)
				o.MouseLeave:Connect(function() tween(o, FAST, { BackgroundTransparency = 0.2, TextColor3 = Theme.Sub }) end)
				o.MouseButton1Click:Connect(function() state:set(opt); handle:Toggle(false) end)
			end
		end
		state:subscribe(function() pcall(callback, state._value) end)
		local click = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = frame })
		click.MouseButton1Click:Connect(function() handle:Toggle() end)
		rebuild()
		state.Refresh = function(_, newOptions) options = newOptions or options; rebuild(); handle:Toggle(false) end
		return state
	end

	function tab:Textbox(text, placeholder, callback)
		callback = callback or function() end
		local state = State("")
		local frame = card(40)
		rowLabel(frame, text)
		local boxBG = new("Frame", { Size = UDim2.new(0, 130, 0, 26), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = frame })
		corner(boxBG, 7)
		stroke(boxBG, Theme.Stroke, 1, 0.4)
		local box = new("TextBox", { Text = "", PlaceholderText = placeholder or "…", ClearTextOnFocus = false, Font = Theme.Font, TextSize = 13,
			TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Sub, BackgroundTransparency = 1, Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 8, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left, Parent = boxBG })
		box.FocusLost:Connect(function(enter) if enter then state:set(box.Text); pcall(callback, box.Text) end end)
		Observe(state, function(v) if box.Text ~= v then box.Text = v end end)
		return state
	end

	function tab:Keybind(text, default, callback)
		callback = callback or function() end
		local key = default or Enum.KeyCode.Unknown
		local frame = card(40)
		rowLabel(frame, text)
		local btn = new("TextButton", { Text = key.Name, Font = Theme.Mono, TextSize = 13, TextColor3 = Theme.Accent,
			BackgroundColor3 = Theme.Surface2, BackgroundTransparency = 0.1, AutoButtonColor = false,
			Size = UDim2.new(0, 96, 0, 26), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BorderSizePixel = 0, Parent = frame })
		corner(btn, 7)
		stroke(btn, Theme.Stroke, 1, 0.4)
		btn.MouseButton1Click:Connect(function()
			btn.Text = "[ ... ]"
			awaitingKeybind = function(kc) key = kc; btn.Text = kc.Name; pcall(callback, kc) end
		end)
		return { Get = function() return key end }
	end

	return tab
end

--==============================================================================
-- Notifications
--==============================================================================

function NovaUI:Notify(title, text, duration)
	duration = duration or 4
	local card = new("Frame", { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, Parent = self.notifHolder })
	corner(card, 12)
	neonBorder(card, 1.2, 0.25)
	glow(card, Theme.Accent, 0.75, 24)
	new("Frame", { Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 9, 0, 9), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = card })

	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -26, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 20, 0, 0), Parent = card })
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
	pad(inner, 11)
	new("TextLabel", { Text = tostring(title), Font = Theme.Bold, TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = inner })
	new("TextLabel", { Text = tostring(text), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Sub, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Parent = inner })

	card.BackgroundTransparency = 1
	tween(card, GLIDE, { BackgroundTransparency = 0.1 })
	taskSpawn(function()
		taskWait(duration)
		tween(card, FAST, { BackgroundTransparency = 1 })
		for _, c in ipairs(card:GetDescendants()) do
			if c:IsA("TextLabel") then tween(c, FAST, { TextTransparency = 1 }) end
			if c:IsA("UIStroke") then tween(c, FAST, { Transparency = 1 }) end
			if c:IsA("ImageLabel") then tween(c, FAST, { ImageTransparency = 1 }) end
		end
		taskWait(0.18)
		card:Destroy()
	end)
end

function NovaUI:Destroy()
	local window = self.window
	if window then
		tween(window, FAST, { Size = UDim2.fromOffset(window.AbsoluteSize.X, 0), BackgroundTransparency = 1 })
	end
	if self.blur then tween(self.blur, FAST, { Size = 0 }) end
	taskSpawn(function()
		taskWait(0.18)
		if self.blur then self.blur:Destroy() end
		if self.gui then self.gui:Destroy() end
	end)
end

--==============================================================================
-- Demo (delete this block to use NovaUI purely as a library)
--==============================================================================

do
	local win = NovaUI.new({ Title = "NOVA HUB", Accent = Color3.fromRGB(0, 210, 255), Accent2 = Color3.fromRGB(140, 90, 255) })

	local home = win:Tab("Dashboard", "⚡")
	home:Section("System")
	home:Label("Reactive, glassmorphic, futuristic — one file. Right-Shift / ☰ / gamepad to toggle.")

	local power = NovaUI.State(false)
	home:Toggle("Master power", power)
	home:Label(NovaUI.Computed(function()
		return "Status: " .. (power:get() and "◉ ONLINE" or "○ standby")
	end))
	home:Button("Send test notification", function()
		win:Notify("Signal", "Reactive core is live.", 4)
	end)

	local combat = win:Tab("Combat", "⌖")
	combat:Section("Aimbot")
	combat:Toggle("Enabled", false)
	combat:Slider("FOV", 30, 400, 150)
	combat:Slider("Smoothness", 1, 20, 6)
	combat:Dropdown("Target part", { "Head", "Torso", "HumanoidRootPart" }, "Head")
	combat:Keybind("Aim key", Enum.KeyCode.E)

	local visuals = win:Tab("Visuals", "◈")
	visuals:Section("ESP")
	visuals:Toggle("Boxes", true)
	visuals:Toggle("Tracers", false)
	visuals:Slider("Render range", 100, 5000, 2000)
	visuals:Textbox("Watermark", "Type text…")

	win:Notify("NovaUI", "Futuristic hub online.", 5)
end

return NovaUI
