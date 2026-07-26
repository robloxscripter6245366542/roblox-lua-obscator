--[[
	EzUI — a single-file, self-contained Roblox UI library
	A modern redesign of Ez Hub's EzLib.

	Everything lives in this one script: no HttpGet, no require, no external
	modules. Executing it directly runs the demo at the bottom so you can see
	the UI immediately. To use it in your own script, delete the demo section
	and keep the returned `EzUI` table:

		local EzUI = loadstring(game:HttpGet("...EzUI.lua"))()
		local win = EzUI.new({ Title = "My Hub", Keybind = Enum.KeyCode.RightShift })
		local tab = win:Tab("Main")
		tab:Button("Click me", function() print("hi") end)
		tab:Toggle("God mode", false, function(on) print(on) end)
		tab:Slider("Speed", 16, 200, 16, function(v) print(v) end)
		tab:Dropdown("Weapon", {"Sword", "Bow"}, "Sword", function(v) print(v) end)
		tab:Keybind("Fly", Enum.KeyCode.F, function(key) print(key) end)
		win:Notify("Loaded", "Welcome to EzUI", 4)

	Built for all devices (PC, mobile, console) and all executors:
	  * A floating ☰ button (draggable; tap to toggle) shows/hides the UI —
	    the primary control on touch devices that have no keyboard.
	  * Window size adapts to the screen and re-fits on rotation/resize.
	  * All controls accept mouse, touch AND gamepad; sliders have an enlarged
	    finger-friendly hit area; whole rows are tappable; controls are
	    controller-selectable so a console D-pad can navigate between them.
	  * Toggle the window with the keyboard (default Right-Shift) or a gamepad
	    button (default ButtonSelect / the Xbox "View" button).
	  * Executor-agnostic mounting: tries gethui / get_hidden_gui / CoreGui /
	    syn.protect_gui and falls back to PlayerGui, so it loads on the weakest
	    executors and even in Studio. task.* and wait are both supported.

	Improvements over the original EzLib:
	  * Depth: soft drop shadow, layered surfaces, subtle strokes.
	  * Real toggle switches (sliding knob) instead of red/green blocks.
	  * Sliders with a filled track + grabbable knob and live value.
	  * Sidebar tabs with an animated selection indicator.
	  * Smooth, consistent tween timing; hover feedback on every control.
	  * A single configurable accent colour drives the whole theme.
	  * Self-contained: cached services, task.wait, gethui() parenting,
	    nil-safe callbacks, no global leaks.
--]]

--==============================================================================
-- Services & compatibility shims
--==============================================================================

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local taskWait  = (task and task.wait) or wait
local taskSpawn = (task and task.spawn) or function(fn, ...) return coroutine.wrap(fn)(...) end

-- Executor-agnostic hidden-GUI parent: try every known API in turn, then
-- fall back to PlayerGui so it still runs on the weakest executors and in
-- Studio (where none of the exploit globals exist).
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

-- Ask the executor to shield the GUI from detection, where supported.
local function protectGui(gui)
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	pcall(function() if protectgui then protectgui(gui) end end)
end

-- Parent the GUI as safely as possible. If CoreGui parenting is blocked by
-- the executor, fall back to PlayerGui so nothing errors out.
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
-- Theme
--==============================================================================

local Theme = {
	Accent     = Color3.fromRGB(88, 128, 255),  -- one colour drives everything
	Background = Color3.fromRGB(24, 26, 32),
	Surface    = Color3.fromRGB(31, 34, 42),
	Surface2   = Color3.fromRGB(39, 43, 53),
	Stroke     = Color3.fromRGB(52, 57, 70),
	Text       = Color3.fromRGB(236, 238, 243),
	SubText    = Color3.fromRGB(150, 156, 170),
	Toggle     = Color3.fromRGB(60, 65, 78),
	Font       = Enum.Font.Gotham,
	FontMedium = Enum.Font.GothamMedium,
	FontBold   = Enum.Font.GothamBold,
}

local SPRING  = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FAST     = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

--==============================================================================
-- Tiny helpers
--==============================================================================

local function new(className, props, children)
	local inst = Instance.new(className)
	-- Interactive classes are made controller-navigable by default (props can
	-- still override). This is what lets a gamepad/console move between rows.
	if className == "TextButton" or className == "ImageButton" or className == "TextBox" then
		inst.Selectable = true
		inst.Active = true
	end
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
		if props.Parent then inst.Parent = props.Parent end
	end
	if children then
		for _, child in ipairs(children) do child.Parent = inst end
	end
	return inst
end

local function tween(inst, info, goal)
	local t = TweenService:Create(inst, info, goal)
	t:Play()
	return t
end

local function corner(inst, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = inst })
end

local function stroke(inst, color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

local function padding(inst, all)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all),
		Parent = inst,
	})
end

-- Soft drop shadow behind a frame (slice-scaled image, degrades gracefully).
local function shadow(parent)
	return new("ImageLabel", {
		Name = "Shadow",
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 60, 1, 60),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 0,
		Parent = parent,
	})
end

-- Ripple-ish hover: lighten a surface on mouse enter, restore on leave.
local function hoverHighlight(button, base, hover)
	button.MouseEnter:Connect(function() tween(button, FAST, { BackgroundColor3 = hover }) end)
	button.MouseLeave:Connect(function() tween(button, FAST, { BackgroundColor3 = base }) end)
end

--==============================================================================
-- Drag (bug-fixed: locals only, honours slider lock)
--==============================================================================

local draggingSlider = false  -- shared lock so window drag yields to sliders

local function dragify(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if draggingSlider then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or draggingSlider then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			tween(frame, FAST, {
				Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			})
		end
	end)
end

--==============================================================================
-- Library
--==============================================================================

local EzUI = {}
EzUI.__index = EzUI

-- Global keybind-capture state (fixes original: only accept keyboard keys).
local awaitingKeybind = nil
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if awaitingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
		awaitingKeybind(input.KeyCode)
		awaitingKeybind = nil
	end
end)

function EzUI.new(config)
	config = config or {}
	local self = setmetatable({}, EzUI)

	if config.Accent then Theme.Accent = config.Accent end
	self.title   = config.Title or "EzUI"
	self.keybind = config.Keybind or Enum.KeyCode.RightShift
	self.gamepadKeybind = config.GamepadKeybind or Enum.KeyCode.ButtonSelect  -- console/gamepad toggle
	self.tabs    = {}
	self.activeTab = nil

	-- Clean up any previous instance across every parent it might live under.
	local cleanupTargets = {}
	pcall(function() table.insert(cleanupTargets, getGuiParent()) end)
	pcall(function() table.insert(cleanupTargets, Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")) end)
	for _, p in ipairs(cleanupTargets) do
		if p then
			for _, v in ipairs(p:GetChildren()) do
				if v.Name == "EzUI" then v:Destroy() end
			end
		end
	end

	local gui = new("ScreenGui", {
		Name = "EzUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 999,  -- sit above in-game GUIs
	})
	mountGui(gui)
	self.gui = gui

	-- Responsive sizing so the window fits both large monitors and phones.
	local WIN_W, WIN_H = 540, 380
	local function viewport()
		local v = gui.AbsoluteSize
		if v.X < 2 or v.Y < 2 then
			v = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 600)
		end
		return v
	end
	local function computeSize()
		local v = viewport()
		return math.floor(math.min(WIN_W, v.X - 24)), math.floor(math.min(WIN_H, v.Y - 48))
	end
	self.computeSize = computeSize
	local function expandedSize() local w, h = computeSize(); return UDim2.fromOffset(w, h) end
	local function collapsedSize() local w = computeSize(); return UDim2.fromOffset(w, 42) end
	self.expandedSize, self.collapsedSize = expandedSize, collapsedSize

	-- Root window
	local window = new("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.new(0.5, 0, 0.5, 0),
		Size = expandedSize(),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = gui,
	})
	shadow(window)
	corner(window, 12)
	stroke(window, Theme.Stroke, 1, 0.2)
	self.window = window

	-- Re-fit when the screen rotates or resizes (mobile orientation changes).
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		window.Size = self.minimized and collapsedSize() or expandedSize()
	end)

	-- Title bar
	local topbar = new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = window,
	})
	corner(topbar, 12)
	new("Frame", { -- cover bottom rounding of the top bar
		Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = topbar,
	})

	local accentDot = new("Frame", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = topbar,
	})
	corner(accentDot, 5)

	new("TextLabel", {
		Text = self.title,
		Font = Theme.FontBold,
		TextSize = 16,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 36, 0, 0),
		Size = UDim2.new(1, -120, 1, 0),
		Parent = topbar,
	})

	-- Close / minimize buttons
	local function iconButton(offset, symbol, color, onClick)
		local b = new("TextButton", {
			Text = symbol,
			Font = Theme.FontBold,
			TextSize = 18,
			TextColor3 = Theme.SubText,
			BackgroundColor3 = Theme.Surface2,
			Size = UDim2.new(0, 26, 0, 26),
			Position = UDim2.new(1, offset, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Parent = topbar,
		})
		corner(b, 6)
		b.MouseEnter:Connect(function() tween(b, FAST, { TextColor3 = color, BackgroundColor3 = Theme.Stroke }) end)
		b.MouseLeave:Connect(function() tween(b, FAST, { TextColor3 = Theme.SubText, BackgroundColor3 = Theme.Surface2 }) end)
		b.MouseButton1Click:Connect(onClick)
		return b
	end

	self.minimized = false
	local content -- forward declaration
	iconButton(-46, "–", Theme.Text, function()
		self.minimized = not self.minimized
		tween(window, SPRING, { Size = self.minimized and collapsedSize() or expandedSize() })
	end)
	iconButton(-14, "✕", Color3.fromRGB(255, 90, 90), function()
		local w = computeSize()
		tween(window, FAST, { Size = UDim2.fromOffset(w, 0), BackgroundTransparency = 1 })
		taskWait(0.16)
		gui:Destroy()
	end)

	dragify(window, topbar)

	-- Body: sidebar (tabs) + content
	local body = new("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(1, 0, 1, -42),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = window,
	})

	local sidebar = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = body,
	})
	new("Frame", { -- right divider
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0, Parent = sidebar,
	})

	local tabList = new("ScrollingFrame", {
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar,
	})
	padding(tabList, 10)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })
	self.tabList = tabList

	content = new("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 150, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1,
		Parent = body,
	})
	self.content = content

	-- Notification container (bottom-right, stacks upward)
	self.notifHolder = new("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 280, 1, -32),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.notifHolder,
	})

	local function setVisible(v)
		self.window.Visible = v
	end
	self.setVisible = setVisible

	-- Floating action button — the primary way to show/hide on mobile (no
	-- keyboard), and a convenience on PC. Draggable; a tap (no drag) toggles.
	local fab = new("TextButton", {
		Name = "Toggle",
		Text = "☰",
		Font = Theme.FontBold,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 18, 0, 90),
		AnchorPoint = Vector2.new(0, 0),
		AutoButtonColor = false,
		BorderSizePixel = 0,
		ZIndex = 60,
		Parent = gui,
	})
	corner(fab, 24)
	shadow(fab)
	self.floatBtn = fab

	local fabDragging, fabMoved, fabStart, fabStartPos
	fab.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			fabDragging = true
			fabMoved = false
			fabStart = input.Position
			fabStartPos = fab.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if fabDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - fabStart
			if delta.Magnitude > 5 then fabMoved = true end
			fab.Position = UDim2.new(
				fabStartPos.X.Scale, fabStartPos.X.Offset + delta.X,
				fabStartPos.Y.Scale, fabStartPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if fabDragging and (input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch) then
			fabDragging = false
			if not fabMoved then setVisible(not self.window.Visible) end
		end
	end)

	-- Toggle shortcut: keyboard (PC) or gamepad button (console). The FAB stays
	-- visible for mobile/touch. Covers all three input families at once.
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == self.keybind or input.KeyCode == self.gamepadKeybind then
			setVisible(not self.window.Visible)
			-- Seed controller selection so a gamepad can navigate immediately.
			if self.window.Visible and self.activeTab and UserInputService.GamepadEnabled then
				pcall(function()
					game:GetService("GuiService").SelectedObject = self.activeTab.button
				end)
			elseif not self.window.Visible then
				pcall(function() game:GetService("GuiService").SelectedObject = nil end)
			end
		end
	end)

	return self
end

--==============================================================================
-- Tabs
--==============================================================================

function EzUI:Tab(name)
	local tab = { name = name, ui = self }

	local button = new("TextButton", {
		Name = name,
		Text = "",
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 34),
		BorderSizePixel = 0,
		Parent = self.tabList,
	})
	corner(button, 7)

	local indicator = new("Frame", {
		Size = UDim2.new(0, 3, 0, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = button,
	})
	corner(indicator, 2)

	local label = new("TextLabel", {
		Text = name,
		Font = Theme.FontMedium,
		TextSize = 14,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -14, 1, 0),
		Parent = button,
	})

	local page = new("ScrollingFrame", {
		Name = name,
		Visible = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self.content,
	})
	padding(page, 14)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

	tab.button = button
	tab.label = label
	tab.indicator = indicator
	tab.page = page
	table.insert(self.tabs, tab)

	local function select()
		if self.activeTab == tab then return end
		for _, t in ipairs(self.tabs) do
			t.page.Visible = false
			tween(t.button, FAST, { BackgroundTransparency = 1 })
			tween(t.label, FAST, { TextColor3 = Theme.SubText })
			tween(t.indicator, FAST, { Size = UDim2.new(0, 3, 0, 0) })
		end
		page.Visible = true
		tween(button, FAST, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface2 })
		tween(label, FAST, { TextColor3 = Theme.Text })
		tween(indicator, SPRING, { Size = UDim2.new(0, 3, 0, 18) })
		self.activeTab = tab
	end

	button.MouseButton1Click:Connect(select)
	button.MouseEnter:Connect(function()
		if self.activeTab ~= tab then tween(button, FAST, { BackgroundTransparency = 0.6, BackgroundColor3 = Theme.Surface2 }) end
	end)
	button.MouseLeave:Connect(function()
		if self.activeTab ~= tab then tween(button, FAST, { BackgroundTransparency = 1 }) end
	end)

	if not self.activeTab then select() end

	--------------------------------------------------------------------------
	-- Element builders (each returns a small handle with :Set / :Get where useful)
	--------------------------------------------------------------------------

	local function rowBase(height)
		local frame = new("Frame", {
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, height or 38),
			BorderSizePixel = 0,
			Parent = page,
		})
		corner(frame, 8)
		stroke(frame, Theme.Stroke, 1, 0.4)
		return frame
	end

	local function rowLabel(parent, text, sub)
		local l = new("TextLabel", {
			Text = text,
			Font = Theme.FontMedium,
			TextSize = 14,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = sub and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, sub and 8 or 0),
			Size = UDim2.new(1, -120, sub and 0 or 1, sub and 18 or 0),
			Parent = parent,
		})
		if sub then
			new("TextLabel", {
				Text = sub, Font = Theme.Font, TextSize = 12, TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -120, 0, 14), Parent = parent,
			})
		end
		return l
	end

	function tab:Section(text)
		local l = new("TextLabel", {
			Text = string.upper(text),
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 22),
			Parent = page,
		})
		return l
	end

	function tab:Label(text)
		return new("TextLabel", {
			Text = text, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = page,
		})
	end

	function tab:Button(text, callback)
		callback = callback or function() end
		local frame = rowBase(38)
		hoverHighlight(frame, Theme.Surface, Theme.Surface2)
		local btn = new("TextButton", {
			Text = text, Font = Theme.FontMedium, TextSize = 14, TextColor3 = Theme.Text,
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame,
		})
		btn.MouseButton1Click:Connect(function()
			tween(frame, FAST, { BackgroundColor3 = Theme.Accent })
			taskWait(0.12)
			tween(frame, FAST, { BackgroundColor3 = Theme.Surface2 })
			pcall(callback)
		end)
		return { instance = frame }
	end

	function tab:Toggle(text, default, callback)
		callback = callback or function() end
		local state = default and true or false
		local frame = rowBase(38)
		rowLabel(frame, text)

		local track = new("Frame", {
			Size = UDim2.new(0, 42, 0, 22),
			Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = state and Theme.Accent or Theme.Toggle,
			BorderSizePixel = 0,
			Parent = frame,
		})
		corner(track, 11)
		local knob = new("Frame", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = state and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			AnchorPoint = Vector2.new(state and 1 or 0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Parent = track,
		})
		corner(knob, 8)

		local handle = {}
		local function render(fire)
			tween(track, FAST, { BackgroundColor3 = state and Theme.Accent or Theme.Toggle })
			tween(knob, SPRING, {
				Position = state and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = state and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
			})
			if fire then pcall(callback, state) end
		end
		local click = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
		click.MouseButton1Click:Connect(function() state = not state; render(true) end)

		function handle:Set(v) state = v and true or false; render(true) end
		function handle:Get() return state end
		return handle
	end

	function tab:Slider(text, min, max, default, callback)
		callback = callback or function() end
		min, max = min or 0, max or 100
		local value = math.clamp(default or min, min, max)
		local frame = rowBase(52)
		rowLabel(frame, text)

		local valueBox = new("TextLabel", {
			Text = tostring(math.floor(value)),
			Font = Theme.FontMedium, TextSize = 13, TextColor3 = Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0, 8), AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.new(0, 60, 0, 16), Parent = frame,
		})

		local track = new("Frame", {
			Size = UDim2.new(1, -24, 0, 6),
			Position = UDim2.new(0, 12, 1, -14),
			BackgroundColor3 = Theme.Toggle,
			BorderSizePixel = 0,
			Parent = frame,
		})
		corner(track, 3)
		local fill = new("Frame", {
			Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		corner(fill, 3)
		local knob = new("Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Parent = fill,
		})
		corner(knob, 6)

		-- Invisible, finger-friendly hit area covering the thin track.
		local hitArea = new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 0, 30),
			Position = UDim2.new(0, 12, 1, -11),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = frame,
		})

		local handle = {}
		local function setFromScale(scale, fire)
			scale = math.clamp(scale, 0, 1)
			value = math.floor(scale * (max - min) + min + 0.5)
			valueBox.Text = tostring(value)
			tween(fill, FAST, { Size = UDim2.new(scale, 0, 1, 0) })
			if fire then pcall(callback, value) end
		end

		local dragging = false
		local function update(input)
			local scale = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setFromScale(scale, true)
		end
		hitArea.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; draggingSlider = true; update(input)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false; draggingSlider = false
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end)

		function handle:Set(v)
			v = math.clamp(v, min, max)
			setFromScale((v - min) / (max - min), true)
		end
		function handle:Get() return value end
		return handle
	end

	function tab:Dropdown(text, options, default, callback)
		callback = callback or function() end
		options = options or {}
		local selected = default or options[1]
		local open = false

		local frame = rowBase(38)
		frame.ClipsDescendants = true
		rowLabel(frame, text)

		local chevron = new("TextLabel", {
			Text = "▾", Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.SubText,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0, 16, 0, 38), Parent = frame,
		})
		local current = new("TextLabel", {
			Text = tostring(selected or ""), Font = Theme.FontMedium, TextSize = 13,
			TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -34, 0, 0), Size = UDim2.new(0, 140, 0, 38), Parent = frame,
		})

		local listHolder = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 38),
			Size = UDim2.new(1, 0, 1, -38),
			Parent = frame,
		})
		local listLayout = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder })
		padding(listHolder, 6)

		local handle = {}
		local function rebuild()
			for _, c in ipairs(listHolder:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			for _, opt in ipairs(options) do
				local o = new("TextButton", {
					Text = tostring(opt), Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
					BackgroundColor3 = Theme.Surface2, AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, 26), BorderSizePixel = 0, Parent = listHolder,
				})
				corner(o, 6)
				hoverHighlight(o, Theme.Surface2, Theme.Stroke)
				o.MouseButton1Click:Connect(function()
					selected = opt
					current.Text = tostring(opt)
					pcall(callback, opt)
					handle:Toggle(false)
				end)
			end
		end

		function handle:Toggle(force)
			open = (force ~= nil) and force or not open
			local rows = #options
			local target = open and (38 + rows * 30 + 12) or 38
			tween(frame, SPRING, { Size = UDim2.new(1, 0, 0, target) })
			tween(chevron, FAST, { Rotation = open and 180 or 0 })
		end
		function handle:Set(v) selected = v; current.Text = tostring(v); pcall(callback, v) end
		function handle:Get() return selected end
		function handle:Refresh(newOptions) options = newOptions or options; rebuild() end

		local click = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), Parent = frame })
		click.MouseButton1Click:Connect(function() handle:Toggle() end)
		rebuild()
		return handle
	end

	function tab:Textbox(text, placeholder, callback)
		callback = callback or function() end
		local frame = rowBase(38)
		rowLabel(frame, text)
		local boxBG = new("Frame", {
			Size = UDim2.new(0, 120, 0, 24), Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Theme.Surface2,
			BorderSizePixel = 0, Parent = frame,
		})
		corner(boxBG, 6)
		local box = new("TextBox", {
			Text = "", PlaceholderText = placeholder or "…", ClearTextOnFocus = false,
			Font = Theme.Font, TextSize = 13, TextColor3 = Theme.Text,
			PlaceholderColor3 = Theme.SubText, BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 8, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left, Parent = boxBG,
		})
		box.FocusLost:Connect(function(enter) if enter then pcall(callback, box.Text) end end)
		local handle = {}
		function handle:Set(v) box.Text = tostring(v) end
		function handle:Get() return box.Text end
		return handle
	end

	function tab:Keybind(text, default, callback)
		callback = callback or function() end
		local key = default or Enum.KeyCode.Unknown
		local frame = rowBase(38)
		rowLabel(frame, text)
		local btn = new("TextButton", {
			Text = key.Name, Font = Theme.FontMedium, TextSize = 13, TextColor3 = Theme.Accent,
			BackgroundColor3 = Theme.Surface2, AutoButtonColor = false,
			Size = UDim2.new(0, 90, 0, 24), Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5), BorderSizePixel = 0, Parent = frame,
		})
		corner(btn, 6)
		btn.MouseButton1Click:Connect(function()
			btn.Text = "..."
			awaitingKeybind = function(kc)
				key = kc
				btn.Text = kc.Name
				pcall(callback, kc)
			end
		end)
		local handle = {}
		function handle:Set(k) key = k; btn.Text = k.Name end
		function handle:Get() return key end
		return handle
	end

	return tab
end

--==============================================================================
-- Notifications
--==============================================================================

function EzUI:Notify(title, text, duration)
	duration = duration or 4
	local card = new("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = self.notifHolder,
	})
	corner(card, 10)
	stroke(card, Theme.Stroke, 1, 0.3)
	new("Frame", { -- accent bar
		Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 8, 0, 8),
		BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = card,
	})
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 18, 0, 0), Parent = card })
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = inner })
	padding(inner, 10)
	new("TextLabel", {
		Text = title, Font = Theme.FontBold, TextSize = 14, TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18), Parent = inner,
	})
	new("TextLabel", {
		Text = text, Font = Theme.Font, TextSize = 13, TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Parent = inner,
	})

	tween(card, SPRING, { BackgroundTransparency = 0 })
	taskSpawn(function()
		taskWait(duration)
		tween(card, FAST, { BackgroundTransparency = 1 })
		for _, c in ipairs(card:GetDescendants()) do
			if c:IsA("TextLabel") then tween(c, FAST, { TextTransparency = 1 }) end
			if c:IsA("UIStroke") then tween(c, FAST, { Transparency = 1 }) end
		end
		taskWait(0.16)
		card:Destroy()
	end)
end

function EzUI:Destroy()
	if self.gui then self.gui:Destroy() end
end

--==============================================================================
-- Demo (delete this block if you only want the library)
--==============================================================================

do
	local win = EzUI.new({ Title = "Ez Hub — EzUI", Keybind = Enum.KeyCode.RightShift, Accent = Color3.fromRGB(88, 128, 255) })

	local main = win:Tab("Home")
	main:Section("Welcome")
	main:Label("Redesigned single-file EzUI. Press Right-Shift (PC) or tap the ☰ button (mobile) to toggle.")
	main:Button("Show notification", function()
		win:Notify("Hello", "EzUI notifications stack and fade automatically.", 4)
	end)
	main:Toggle("Enable feature", false, function(on) print("feature:", on) end)

	local combat = win:Tab("Combat")
	combat:Section("Aimbot")
	combat:Toggle("Aimbot", false, function(on) print("aimbot", on) end)
	combat:Slider("FOV", 30, 400, 150, function(v) print("fov", v) end)
	combat:Slider("Smoothness", 1, 20, 5, function(v) print("smooth", v) end)
	combat:Keybind("Aim key", Enum.KeyCode.E, function(k) print("key", k) end)
	combat:Dropdown("Target part", { "Head", "Torso", "HumanoidRootPart" }, "Head", function(v) print("part", v) end)

	local visuals = win:Tab("Visuals")
	visuals:Section("ESP")
	visuals:Toggle("Boxes", true, function() end)
	visuals:Toggle("Tracers", false, function() end)
	visuals:Slider("Render range", 100, 5000, 2000, function() end)
	visuals:Textbox("Watermark", "Type text…", function(t) print("wm", t) end)

	win:Notify("EzUI loaded", "Single-file build ready.", 5)
end

return EzUI
