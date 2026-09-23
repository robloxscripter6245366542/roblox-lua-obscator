--[[
	Grow a Garden 2  |  Emerald  —  Full Edition
	==================================================================
	A complete feature hub for "Grow a Garden 2" (PlaceId 77085202503540),
	built on Verdant UI — our own hand-made, animated UI library — with an
	emerald-green premium theme.

	Everything that touches the game drives the game's own networking
	layer (ReplicatedStorage.SharedModules.Networking, a ByteNet-style
	"Packet" library). The remote table, argument order and the
	fruit-scan / plant / water / steal logic were all reconstructed from
	the live game dump, so calls mirror what the real client sends.

	Tabs:
	  Home · Auto Farm · Sell · Steal · Shop · Eggs & Pets · Tools ·
	  Weather & Codes · Social · Auction · Visuals (ESP) · Player · Settings

	Client-side automation intended for executors.
	==================================================================
]]

--// Services
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local TeleportService    = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--============================================================--
--  Verdant UI  —  our own premium emerald UI library
--  (drop-in: exposes the same API the features below call)
--============================================================--
local TweenService = game:GetService("TweenService")

-- Emerald palette (shared with feature code: ESP colours, tags, etc.)
local Emerald   = Color3.fromHex("#10B981")
local EmeraldHi = Color3.fromHex("#34D399")
local EmeraldLo = Color3.fromHex("#059669")
local Mint      = Color3.fromHex("#6EE7B7")

local WindUI = {}
WindUI.Version = "Verdant 1.0"
do
	--// theme colours
	local C = {
		Bg      = Color3.fromHex("#06130E"),
		Bg2     = Color3.fromHex("#0A1E16"),
		Elem    = Color3.fromHex("#0E271D"),
		ElemH   = Color3.fromHex("#123326"),
		Stroke  = Color3.fromHex("#1C4A38"),
		Text    = Color3.fromHex("#E9FBF4"),
		Sub     = Color3.fromHex("#7FB6A3"),
		Accent  = Emerald,
		AccentHi = EmeraldHi,
		AccentLo = EmeraldLo,
		Bad     = Color3.fromHex("#F87171"),
	}
	local FONT  = Enum.Font.GothamMedium
	local FONTB = Enum.Font.GothamBold
	local TI  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local TIs = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	--// helpers
	local function new(cls, props, kids)
		local o = Instance.new(cls)
		for k, v in pairs(props or {}) do o[k] = v end
		for _, c in ipairs(kids or {}) do c.Parent = o end
		return o
	end
	local function corner(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
	local function stroke(p, col, tr, th) return new("UIStroke", { Color = col or C.Stroke, Transparency = tr or 0.4, Thickness = th or 1, Parent = p }) end
	local function pad(p, l, r, t, b)
		new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r or l),
			PaddingTop = UDim.new(0, t or l), PaddingBottom = UDim.new(0, b or t or l), Parent = p })
	end
	local function tw(o, goal, ti) local t = TweenService:Create(o, ti or TI, goal); t:Play(); return t end

	local ICONS = {
		house = "🏠", leaf = "🍃", coins = "🪙", swords = "⚔️", ["shopping-cart"] = "🛒",
		egg = "🥚", wand = "🪄", cloud = "☁️", users = "👥", gavel = "⚖️", eye = "👁️",
		user = "🧑", settings = "⚙️", hammer = "🔨", backpack = "🎒", star = "⭐",
		plane = "✈️", sparkles = "✨", calendar = "📅", terminal = "🖥️", sprout = "🌱",
		["triangle-alert"] = "⚠️", gift = "🎁", mail = "✉️", shield = "🛡️", network = "🌐",
		["map-pin"] = "📍", ["octagon-x"] = "🛑", ["refresh-cw"] = "🔄", package = "📦",
		scroll = "📜", ["dice-5"] = "🎲", ["cloud-lightning"] = "🌩️", ["globe"] = "🌍",
	}
	local function iconOf(name) return ICONS[name] or "•" end

	--// mount protected ScreenGui
	local screen = new("ScreenGui", {
		Name = "Verdant_" .. tostring(math.random(100000, 999999)),
		ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999, IgnoreGuiInset = true,
	})
	do
		local ok = pcall(function()
			if syn and syn.protect_gui then syn.protect_gui(screen) end
			if typeof(gethui) == "function" then screen.Parent = gethui()
			else screen.Parent = game:GetService("CoreGui") end
		end)
		if not ok then screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	end
	WindUI._screen = screen

	--// draggable
	local function draggable(frame, handle)
		handle = handle or frame
		local dragging, startPos, startInput
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; startInput = i.Position; startPos = frame.Position
				i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - startInput
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end

	--// notifications holder
	local notifyHolder = new("Frame", {
		Name = "Notify", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32), BackgroundTransparency = 1, Parent = screen,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	function WindUI:Notify(cfg)
		cfg = cfg or {}
		local card = new("Frame", { BackgroundColor3 = C.Bg2, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ClipsDescendants = true }, {})
		corner(card, 10); local st = stroke(card, C.Accent, 0.5)
		pad(card, 12)
		local ic = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, 22, 0, 22),
			Font = FONTB, Text = iconOf(cfg.Icon), TextSize = 16, TextColor3 = C.AccentHi,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 0),
			Size = UDim2.new(1, -28, 0, 18), Font = FONTB, Text = cfg.Title or "Notice", TextSize = 14,
			TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 20),
			Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT,
			Text = cfg.Content or "", TextSize = 12, TextColor3 = C.Sub, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		card.Parent = notifyHolder
		card.Position = UDim2.new(1, 0, 0, 0)
		tw(card, { BackgroundTransparency = 0 }, TIs)
		tw(st, { Transparency = 0.5 }, TIs)
		task.delay(cfg.Duration or 4, function()
			tw(card, { BackgroundTransparency = 1 }, TI)
			task.wait(0.25); card:Destroy()
		end)
	end

	--// window
	function WindUI:CreateWindow(cfg)
		cfg = cfg or {}
		local Window = {}
		local visible = true

		local root = new("Frame", {
			Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 620, 0, 460), BackgroundColor3 = C.Bg, Parent = screen, ClipsDescendants = true,
		})
		corner(root, 14); stroke(root, C.Stroke, 0.2, 1.5)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("#0A1F17"), Color3.fromHex("#050F0B")), Parent = root })

		-- topbar
		local top = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Bg2, Parent = root })
		corner(top, 14)
		new("Frame", { Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = C.Bg2, BorderSizePixel = 0, Parent = top })
		new("Frame", { Name = "dot", Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 16, 0.5, -6), BackgroundColor3 = C.Accent, Parent = top }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
			Font = FONTB, Text = cfg.Title or "Verdant", TextSize = 15, TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
		local tagHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.new(0, 180, 0, 22), Parent = top },
			{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

		local function topBtn(txt, col, xoff)
			local b = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xoff, 0.5, 0),
				Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = C.Elem, Text = txt, Font = FONTB, TextSize = 15,
				TextColor3 = C.Sub, AutoButtonColor = false, Parent = top })
			corner(b, 8)
			b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = col, TextColor3 = C.Text }) end)
			b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = C.Elem, TextColor3 = C.Sub }) end)
			return b
		end
		local closeBtn = topBtn("×", C.Bad, -12)
		local minBtn   = topBtn("–", C.AccentLo, -44)

		-- sidebar
		local side = new("ScrollingFrame", { Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(0, 158, 1, -46),
			BackgroundColor3 = C.Bg2, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = root })
		pad(side, 10, 10, 10, 10)
		local sideList = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })

		-- content
		local content = new("Frame", { Position = UDim2.new(0, 158, 0, 46), Size = UDim2.new(1, -158, 1, -46), BackgroundTransparency = 1, Parent = root })

		draggable(root, top)

		local tabs, activeTab = {}, nil
		local function selectTab(t)
			if activeTab == t then return end
			for _, o in ipairs(tabs) do
				o.page.Visible = false
				tw(o.btn, { BackgroundColor3 = C.Bg2 })
				tw(o.label, { TextColor3 = C.Sub }); tw(o.icon, { TextColor3 = C.Sub })
			end
			activeTab = t
			t.page.Visible = true
			t.page.Position = UDim2.new(0, 12, 0, 0)
			tw(t.page, { Position = UDim2.new(0, 0, 0, 0) }, TIs)
			tw(t.btn, { BackgroundColor3 = C.Elem })
			tw(t.label, { TextColor3 = C.Text }); tw(t.icon, { TextColor3 = C.AccentHi })
		end

		-- element factory shared by all tabs
		local function elementBase(parent, h)
			local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.Elem, Parent = parent })
			corner(f, 8); stroke(f, C.Stroke, 0.55)
			return f
		end
		local function hoverable(f)
			f.MouseEnter:Connect(function() tw(f, { BackgroundColor3 = C.ElemH }) end)
			f.MouseLeave:Connect(function() tw(f, { BackgroundColor3 = C.Elem }) end)
		end
		local function titleBlock(f, title, desc, rightPad)
			new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, desc and 7 or 0),
				Size = UDim2.new(1, -(rightPad or 60), desc and 0 or 1, desc and 18 or 0), Font = FONTB, Text = title or "",
				TextSize = 13, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = desc and Enum.TextYAlignment.Center or Enum.TextYAlignment.Center, Parent = f })
			if desc then
				new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 26),
					Size = UDim2.new(1, -(rightPad or 60), 0, 16), Font = FONT, Text = desc, TextSize = 11,
					TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
			end
		end

		-- Tab
		function Window:Tab(tcfg)
			tcfg = tcfg or {}
			local Tab = {}
			local order = #tabs + 1

			local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.Bg2, Text = "",
				AutoButtonColor = false, LayoutOrder = order, Parent = side })
			corner(btn, 8)
			local icon = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(0, 22, 1, 0), Font = FONTB, Text = iconOf(tcfg.Icon), TextSize = 14,
				TextColor3 = C.Sub, Parent = btn })
			local label = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0),
				Size = UDim2.new(1, -40, 1, 0), Font = FONTB, Text = tcfg.Title or "Tab", TextSize = 13,
				TextColor3 = C.Sub, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })

			local page = new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
				BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.Accent,
				CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content })
			pad(page, 14, 14, 14, 14)
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

			local rec = { btn = btn, icon = icon, label = label, page = page }
			tabs[#tabs + 1] = rec
			btn.MouseButton1Click:Connect(function() selectTab(rec) end)
			btn.MouseEnter:Connect(function() if activeTab ~= rec then tw(btn, { BackgroundColor3 = C.Elem }) end end)
			btn.MouseLeave:Connect(function() if activeTab ~= rec then tw(btn, { BackgroundColor3 = C.Bg2 }) end end)
			if not activeTab then task.defer(function() selectTab(rec) end) end

			--// elements
			function Tab:Section(c)
				local f = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Parent = page })
				new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = FONTB,
					Text = "  " .. ((c and c.Title) or ""):upper(), TextSize = 11, TextColor3 = C.AccentHi,
					TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
				new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, BackgroundTransparency = 0.4, Parent = f })
				return f
			end

			function Tab:Paragraph(c)
				c = c or {}
				local f = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Elem, Parent = page })
				corner(f, 8); stroke(f, C.Stroke, 0.55); pad(f, 12)
				local t = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Font = FONTB,
					Text = c.Title or "", TextSize = 13, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
				local d = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 22),
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = FONT, Text = c.Desc or "",
					TextSize = 12, TextColor3 = C.Sub, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
				return { SetDesc = function(_, txt) d.Text = txt end, SetTitle = function(_, txt) t.Text = txt end }
			end

			function Tab:Button(c)
				c = c or {}
				local f = elementBase(page, c.Desc and 52 or 40)
				titleBlock(f, c.Title, c.Desc, 40)
				new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 20, 0, 20), Font = FONTB, Text = "›",
					TextSize = 20, TextColor3 = C.Sub, Parent = f })
				local click = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = f })
				click.MouseEnter:Connect(function() tw(f, { BackgroundColor3 = C.ElemH }) end)
				click.MouseLeave:Connect(function() tw(f, { BackgroundColor3 = C.Elem }) end)
				click.MouseButton1Click:Connect(function()
					tw(f, { BackgroundColor3 = C.Accent }, TweenInfo.new(0.08))
					task.delay(0.12, function() tw(f, { BackgroundColor3 = C.ElemH }) end)
					if c.Callback then task.spawn(c.Callback) end
				end)
				return f
			end

			function Tab:Toggle(c)
				c = c or {}
				local state = c.Value or c.Default or false
				local f = elementBase(page, c.Desc and 52 or 40)
				titleBlock(f, c.Title, c.Desc, 60)
				local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.new(0, 42, 0, 22), BackgroundColor3 = state and C.Accent or C.Bg, Parent = f })
				corner(track, 11); stroke(track, C.Stroke, 0.5)
				local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, state and 22 or 2, 0.5, 0),
					Size = UDim2.new(0, 18, 0, 18), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
				corner(knob, 9)
				local function set(v, fireCb)
					state = v
					tw(track, { BackgroundColor3 = state and C.Accent or C.Bg })
					tw(knob, { Position = UDim2.new(0, state and 22 or 2, 0.5, 0) })
					if fireCb and c.Callback then task.spawn(c.Callback, state) end
				end
				local click = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = f })
				click.MouseEnter:Connect(function() tw(f, { BackgroundColor3 = C.ElemH }) end)
				click.MouseLeave:Connect(function() tw(f, { BackgroundColor3 = C.Elem }) end)
				click.MouseButton1Click:Connect(function() set(not state, true) end)
				return { Set = function(_, v) set(v, true) end }
			end

			function Tab:Slider(c)
				c = c or {}
				local v = (c.Value and c.Value.Default) or 0
				local mn = (c.Value and c.Value.Min) or 0
				local mx = (c.Value and c.Value.Max) or 100
				local step = c.Step or 1
				local f = elementBase(page, c.Desc and 60 or 48)
				new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -70, 0, 16),
					Font = FONTB, Text = c.Title or "", TextSize = 13, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
				local valLbl = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -12, 0, 6), Size = UDim2.new(0, 56, 0, 16), Font = FONTB, Text = tostring(v),
					TextSize = 12, TextColor3 = C.AccentHi, TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
				local track = new("Frame", { Position = UDim2.new(0, 12, 0, c.Desc and 40 or 30), Size = UDim2.new(1, -24, 0, 6),
					BackgroundColor3 = C.Bg, Parent = f })
				corner(track, 3)
				local fill = new("Frame", { Size = UDim2.new((v - mn) / math.max(mx - mn, 1), 0, 1, 0), BackgroundColor3 = C.Accent, Parent = track })
				corner(fill, 3)
				new("UIGradient", { Color = ColorSequence.new(C.AccentLo, C.AccentHi), Parent = fill })
				local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((v - mn) / math.max(mx - mn, 1), 0, 0.5, 0),
					Size = UDim2.new(0, 14, 0, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
				corner(knob, 7)
				local function setFromAlpha(a)
					a = math.clamp(a, 0, 1)
					local raw = mn + (mx - mn) * a
					raw = math.floor(raw / step + 0.5) * step
					raw = math.clamp(raw, mn, mx)
					v = raw
					local alpha = (v - mn) / math.max(mx - mn, 1)
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					knob.Position = UDim2.new(alpha, 0, 0.5, 0)
					valLbl.Text = (step < 1) and string.format("%.2f", v) or tostring(math.floor(v))
					if c.Callback then task.spawn(c.Callback, v) end
				end
				local dragging = false
				local hit = new("TextButton", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, -8),
					Size = UDim2.new(1, 0, 0, 22), Text = "", Parent = track })
				hit.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = true; setFromAlpha((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
					end
				end)
				hit.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
				end)
				UserInputService.InputChanged:Connect(function(i)
					if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
						setFromAlpha((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
					end
				end)
				return { Set = function(_, val) setFromAlpha((val - mn) / math.max(mx - mn, 1)) end }
			end

			function Tab:Input(c)
				c = c or {}
				local f = elementBase(page, c.Desc and 52 or 40); hoverable(f)
				titleBlock(f, c.Title, c.Desc, 150)
				local box = new("TextBox", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
					Size = UDim2.new(0, 130, 0, 26), BackgroundColor3 = C.Bg, Font = FONT, Text = "",
					PlaceholderText = c.Placeholder or "…", PlaceholderColor3 = C.Sub, TextColor3 = C.Text,
					TextSize = 12, ClearTextOnFocus = false, Parent = f })
				corner(box, 6); stroke(box, C.Stroke, 0.5); pad(box, 8, 8, 0, 0)
				box.FocusLost:Connect(function(enter)
					if c.Callback then task.spawn(c.Callback, box.Text, enter) end
				end)
				return { Set = function(_, t) box.Text = t end }
			end

			function Tab:Dropdown(c)
				c = c or {}
				local multi = c.Multi == true
				local values = c.Values or {}
				local selected = {}
				if multi and type(c.Value) == "table" then for _, x in ipairs(c.Value) do selected[x] = true end
				elseif not multi and c.Value ~= nil then
					local pre = (type(c.Value) == "number") and values[c.Value] or c.Value
					if pre ~= nil then selected[pre] = true end
				end
				local open = false
				local f = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Elem, ClipsDescendants = true, Parent = page })
				corner(f, 8); stroke(f, C.Stroke, 0.55)
				local header = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Text = "", Parent = f })
				new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
					Font = FONTB, Text = c.Title or "", TextSize = 13, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
				local function summary()
					local n, one = 0, nil
					for k in pairs(selected) do n += 1; one = k end
					if n == 0 then return "None" elseif n == 1 then return tostring(one) else return n .. " selected" end
				end
				local sel = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Font = FONT, Text = summary(),
					TextSize = 12, TextColor3 = C.AccentHi, TextXAlignment = Enum.TextXAlignment.Right, Parent = header })
				local arrow = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 16, 0, 16), Font = FONTB, Text = "▾",
					TextSize = 14, TextColor3 = C.Sub, Parent = header })
				local list = new("Frame", { Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Parent = f })
				pad(list, 8, 8, 0, 8)
				new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
				local rows = {}
				local rowsCount = #values
				local function fireCb()
					if not c.Callback then return end
					if multi then
						local t = {} for k in pairs(selected) do t[#t + 1] = k end
						task.spawn(c.Callback, t)
					else
						local one for k in pairs(selected) do one = k end
						task.spawn(c.Callback, one)
					end
				end
				local function refresh()
					sel.Text = summary()
					for val, row in pairs(rows) do
						local on = selected[val] == true
						tw(row, { BackgroundColor3 = on and C.AccentLo or C.Bg })
					end
				end
				local function rebuild(newValues)
					if newValues then
						values = newValues
						local valid = {}
						for _, v in ipairs(values) do valid[v] = true end
						for k in pairs(selected) do if not valid[k] then selected[k] = nil end end
					end
					for _, row in pairs(rows) do row:Destroy() end
					rows = {}
					for i, val in ipairs(values) do
						local row = new("TextButton", { Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = selected[val] and C.AccentLo or C.Bg,
							Text = "  " .. tostring(val), Font = FONT, TextSize = 12, TextColor3 = C.Text,
							TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, LayoutOrder = i, Parent = list })
						corner(row, 6)
						rows[val] = row
						row.MouseButton1Click:Connect(function()
							if multi then
								selected[val] = not selected[val] or nil
							else
								local was = selected[val]
								for k in pairs(selected) do selected[k] = nil end
								if not (was and c.AllowNone) then selected[val] = true end
							end
							refresh(); fireCb()
						end)
					end
					rowsCount = #values
					if open then
						f.Size = UDim2.new(1, 0, 0, 40 + rowsCount * 30 + 8)
						list.Size = UDim2.new(1, 0, 0, rowsCount * 30)
					end
					refresh()
				end
				rebuild()
				header.MouseButton1Click:Connect(function()
					open = not open
					local h = open and (40 + rowsCount * 30 + 8) or 40
					tw(f, { Size = UDim2.new(1, 0, 0, h) }, TIs)
					tw(list, { Size = UDim2.new(1, 0, 0, open and (rowsCount * 30) or 0) }, TIs)
					tw(arrow, { Rotation = open and 180 or 0 })
				end)
				-- :Set(newValues) rebuilds the option list; :Select(val)/:Clear() manage selection.
				return {
					Set = function(_, newValues) rebuild(newValues) end,
					Select = function(_, val) if not multi then for k in pairs(selected) do selected[k] = nil end end selected[val] = true; refresh() end,
					Clear = function(_) for k in pairs(selected) do selected[k] = nil end refresh() end,
				}
			end

			return Tab
		end

		function Window:Tag(tcfg)
			tcfg = tcfg or {}
			local pill = new("Frame", { Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = C.Elem, Parent = tagHolder })
			corner(pill, 10); stroke(pill, tcfg.Color or C.Accent, 0.3)
			new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
				Font = FONTB, Text = "  " .. (tcfg.Title or "") .. "  ", TextSize = 11, TextColor3 = tcfg.Color or C.AccentHi, Parent = pill })
			return pill
		end
		function Window:SetBackgroundTransparency(n) root.BackgroundTransparency = n or 0 end
		function Window:Destroy() pcall(function() screen:Destroy() end) end

		-- open / close animation
		local function setVisible(v)
			visible = v
			if v then
				root.Visible = true
				root.Size = UDim2.new(0, 560, 0, 420)
				tw(root, { Size = UDim2.new(0, 620, 0, 460) }, TIs)
			else
				tw(root, { Size = UDim2.new(0, 560, 0, 420) }, TI)
				task.delay(0.18, function() if not visible then root.Visible = false end end)
			end
		end
		closeBtn.MouseButton1Click:Connect(function() setVisible(false) end)
		minBtn.MouseButton1Click:Connect(function() setVisible(false) end)

		-- floating open button
		local openBtn = new("TextButton", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.new(0, 46, 0, 46), BackgroundColor3 = C.Bg2, Text = "🌱", Font = FONTB, TextSize = 22,
			AutoButtonColor = false, Parent = screen })
		corner(openBtn, 23); stroke(openBtn, C.Accent, 0.2, 1.5)
		draggable(openBtn)
		openBtn.MouseButton1Click:Connect(function() setVisible(not visible) end)

		local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
		UserInputService.InputBegan:Connect(function(i, gp)
			if not gp and i.KeyCode == toggleKey then setVisible(not visible) end
		end)

		WindUI._window = Window
		return Window
	end
end

--============================================================--
--  Networking
--============================================================--
local Net
do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
	end)
	if ok then Net = mod end
end

-- remote("A","B") -> packet object (walks the remote tree), or nil
local function remote(...)
	if not Net then return nil end
	local node = Net
	for _, key in ipairs({ ... }) do
		if type(node) ~= "table" then return nil end
		node = node[key]
	end
	return node
end

-- fire("A","B", args...) : leading string keys resolve the remote, the rest are payload.
-- Descends through category tables until it reaches a packet (a table owning a Fire method).
local function fire(...)
	if not Net then return end
	local argc = select("#", ...)
	local args = table.pack(...)
	local node, depth = Net, 0
	for i = 1, argc do
		if type(args[i]) == "string" and type(node) == "table" and node[args[i]] ~= nil then
			node = node[args[i]]
			depth = i
			if type(node) ~= "table" or type(node.Fire) == "function" then
				break -- reached a packet (has Fire) or a non-table value
			end
			-- otherwise it's a category table: keep descending
		else
			break
		end
	end
	if type(node) == "table" and type(node.Fire) == "function" then
		return select(2, pcall(function()
			return node:Fire(table.unpack(args, depth + 1, argc))
		end))
	end
end

-- invoke: fire a :Response remote and return the response value.
local function invoke(path, ...)
	local n
	if type(path) == "table" then n = remote(table.unpack(path)) else n = remote(path) end
	if n and type(n.Fire) == "function" then
		local argc = select("#", ...)
		local extra = table.pack(...)
		local ok, res = pcall(function() return n:Fire(table.unpack(extra, 1, argc)) end)
		if ok then return res end
	end
	return nil
end

-- Enumerate every remote path in Net that owns a Fire method -> {"Garden.CollectFruit", ...}
local function allRemotePaths()
	local paths = {}
	local function walk(node, prefix)
		if type(node) ~= "table" then return end
		if type(node.Fire) == "function" and prefix ~= "" then
			paths[#paths + 1] = prefix
			return
		end
		for k, v in pairs(node) do
			if type(k) == "string" and type(v) == "table" then
				walk(v, prefix == "" and k or (prefix .. "." .. k))
			end
		end
	end
	if Net then walk(Net, "") end
	table.sort(paths)
	return paths
end

-- Parse a comma-separated arg string into typed values (number / bool / nil / string).
-- Returns a packed table with `.n` so positions survive a "nil" argument.
local function parseArgs(str)
	local out = { n = 0 }
	if not str or str == "" then return out end
	for token in string.gmatch(str, "([^,]+)") do
		local t = token:match("^%s*(.-)%s*$")
		out.n += 1
		if t == "true" then out[out.n] = true
		elseif t == "false" then out[out.n] = false
		elseif t == "nil" then out[out.n] = nil
		elseif tonumber(t) ~= nil then out[out.n] = tonumber(t)
		else out[out.n] = t end
	end
	return out
end

--============================================================--
--  Data
--============================================================--
local SeedNames = {
	"Carrot", "Strawberry", "Blueberry", "Tomato", "Corn", "Cactus",
	"Grape", "Pineapple", "Apple", "Banana", "Mango", "Coconut",
	"Cherry", "Plum", "Pomegranate", "Sunflower", "Tulip", "Bamboo",
	"Watermelon", "Dragon Fruit", "Star Fruit", "Horned Melon",
	"Mushroom", "Glow Mushroom", "Pepper", "Ghost Pepper", "Green Bean",
	"Venus Fly Trap", "Venom Spitter", "Poison Apple", "Moon Bloom",
	"Sun Bloom", "Eclipse Bloom", "Briar Rose", "Hypno Bloom",
	"Fire Fern", "Dragon's Breath", "Cinnamon Stick", "Romanesco",
	"Atlantic Giant Pumpkin", "Rocket Pop", "Baby Cactus", "Acorn",
	"Conifer Cone", "Amber Cranberry", "Gold", "Rainbow", "Mega",
}
local EggNames   = { "Common Egg", "Big Egg", "Mega Egg", "Rainbow Egg" }
local CrateNames = { "Common Crate", "Rare Crate", "Legendary Crate", "Mythical Crate" }

--============================================================--
--  Core helpers
--============================================================--
local function getCharacter()
	local char = LocalPlayer.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then return char, hrp, hum end
	end
	return nil
end

local function getPlayerPlot()
	local plotId = LocalPlayer:GetAttribute("PlotId")
	local gardens = Workspace:FindFirstChild("Gardens")
	if plotId and gardens then
		return gardens:FindFirstChild("Plot" .. tostring(plotId))
	end
	return nil
end

-- Enumerate this player's ripe / collectible fruit (returns id pairs).
local function scanCollectible()
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				local uid = tonumber(plant:GetAttribute("UserId"))
				local plantId = plant:GetAttribute("PlantId")
				if uid == myId and typeof(plantId) == "string" then
					local fruitsFolder = plant:FindFirstChild("Fruits")
					if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if typeof(fruitId) == "string" then
								local age    = fruit:GetAttribute("Age")
								local maxAge = fruit:GetAttribute("MaxAge")
								local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or (age >= maxAge)
								if ripe then out[#out + 1] = { plantId = plantId, fruitId = fruitId } end
							end
						end
					else
						out[#out + 1] = { plantId = plantId, fruitId = "" }
					end
				end
			end
		end
	end
	return out
end

-- Enumerate fruit belonging to OTHER players (for steal), returns {owner,plantId,fruitId}.
local function scanStealable(maxDist)
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	local _, hrp = getCharacter()
	if not gardens or not hrp then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				local uid = tonumber(plant:GetAttribute("UserId"))
				local plantId = plant:GetAttribute("PlantId")
				if uid and uid ~= myId and typeof(plantId) == "string" then
					local fruitsFolder = plant:FindFirstChild("Fruits")
					if fruitsFolder then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if typeof(fruitId) == "string" then
								local part = fruit:IsA("BasePart") and fruit or fruit:FindFirstChildWhichIsA("BasePart")
								local pos = part and part.Position or (fruit:IsA("Model") and fruit:GetPivot().Position)
								if not maxDist or (pos and (pos - hrp.Position).Magnitude <= maxDist) then
									out[#out + 1] = { owner = uid, plantId = plantId, fruitId = fruitId }
								end
							end
						end
					end
				end
			end
		end
	end
	return out
end

local function getToolsWithAttribute(attr)
	local tools = {}
	local function scan(container)
		if not container then return end
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute(attr) ~= nil then
				tools[#tools + 1] = item
			end
		end
	end
	scan(LocalPlayer:FindFirstChild("Backpack"))
	scan(LocalPlayer.Character)
	return tools
end
local function getSeedTools() return getToolsWithAttribute("SeedTool") end
local function getWateringCans() return getToolsWithAttribute("WateringCan") end

local function getEquippedTool()
	local char = LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Tool")
end

local function equipTool(tool)
	local char, _, hum = getCharacter()
	if char and hum and tool and tool.Parent ~= char then
		hum:EquipTool(tool)
	end
end

local function getPlantPosition()
	local plot = getPlayerPlot()
	if not plot then return nil end
	local candidates = {}
	for _, tagged in ipairs(CollectionService:GetTagged("PlantArea")) do
		if tagged:IsDescendantOf(plot) and tagged:IsA("BasePart") then
			candidates[#candidates + 1] = tagged
		end
	end
	if #candidates == 0 then
		for _, d in ipairs(plot:GetDescendants()) do
			if d:IsA("BasePart") and d.Size.X > 4 and d.Size.Z > 4 then
				candidates[#candidates + 1] = d
			end
		end
	end
	if #candidates == 0 then return nil end
	local part = candidates[math.random(1, #candidates)]
	local offX = (math.random() - 0.5) * math.max(part.Size.X - 2, 0)
	local offZ = (math.random() - 0.5) * math.max(part.Size.Z - 2, 0)
	return part.Position + Vector3.new(offX, part.Size.Y / 2, offZ)
end

-- Enumerate this player's plant models (for watering / merging / ESP).
local function myPlantModels()
	local out = {}
	local gardens = Workspace:FindFirstChild("Gardens")
	if not gardens then return out end
	local myId = LocalPlayer.UserId
	for _, garden in ipairs(gardens:GetChildren()) do
		local plants = garden:FindFirstChild("Plants")
		if plants then
			for _, plant in ipairs(plants:GetChildren()) do
				if tonumber(plant:GetAttribute("UserId")) == myId then
					out[#out + 1] = plant
				end
			end
		end
	end
	return out
end

local function modelPosition(inst)
	if inst:IsA("BasePart") then return inst.Position end
	if inst:IsA("Model") then
		if inst.PrimaryPart then return inst.PrimaryPart.Position end
		local ok, cf = pcall(function() return inst:GetPivot() end)
		if ok then return cf.Position end
	end
	local bp = inst:FindFirstChildWhichIsA("BasePart")
	return bp and bp.Position
end

--============================================================--
--  Window
--============================================================--
local Window = WindUI:CreateWindow({
	Title    = "Grow a Garden 2  |  Emerald",
	Folder   = "GrowAGarden2_Emerald",
	Icon     = "sprout",
	Size      = UDim2.fromOffset(600, 460),
	NewElements = true,
	HideSearchBar = false,
	Acrylic  = true,
	Transparent = true,
	Radius   = 18,
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = "Grow a Garden 2",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		Enabled = true,
		Draggable = true,
		Color = ColorSequence.new(EmeraldHi, EmeraldLo),
	},
	Topbar = { Height = 42, ButtonsType = "Mac" },
})
Window:Tag({ Title = "v" .. tostring(WindUI.Version), Color = EmeraldLo })
Window:Tag({ Title = "Full Edition", Color = Emerald })

--============================================================--
--  State + loop manager
--============================================================--
local State = {}
local Loops = {}
local function startLoop(name, flagKey, delayKey, body)
	if Loops[name] then return end
	Loops[name] = task.spawn(function()
		while State[flagKey] do
			pcall(body)
			task.wait(State[delayKey] or 0.5)
		end
		Loops[name] = nil
	end)
end

--============================================================--
--  TAB: Home
--============================================================--
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })
HomeTab:Section({ Title = "Welcome" })
HomeTab:Paragraph({
	Title = "Grow a Garden 2 — Emerald · Full Edition",
	Desc  = "Auto-farm, steal, shop, eggs & pets, tools, weather, social, "
		.. "auction and a full ESP/visuals suite — all driving the game's own remotes.",
	Image = "sprout",
})
do
	HomeTab:Section({ Title = "Live status" })
	local statsPara = HomeTab:Paragraph({ Title = "Session", Desc = "Loading…" })
	task.spawn(function()
		while true do
			local plot = getPlayerPlot()
			statsPara:SetDesc(string.format(
				"Plot: %s   •   Ripe: %d   •   Seed tools: %d   •   Networking: %s",
				plot and plot.Name or "unknown",
				#scanCollectible(), #getSeedTools(), Net and "loaded" or "unavailable"
			))
			task.wait(2)
		end
	end)
end
HomeTab:Button({
	Title = "Rejoin server",
	Callback = function()
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
	end,
})

--============================================================--
--  TAB: Auto Farm
--============================================================--
local FarmTab = Window:Tab({ Title = "Auto Farm", Icon = "leaf" })

FarmTab:Section({ Title = "Harvest" })
State.autoCollect, State.collectDelay = false, 0.15
FarmTab:Toggle({
	Title = "Auto-Collect Fruit",
	Desc  = "Harvests every ripe fruit on your plot.",
	Value = false,
	Callback = function(on)
		State.autoCollect = on
		if on then startLoop("collect", "autoCollect", "collectDelay", function()
			for _, e in ipairs(scanCollectible()) do fire("Garden", "CollectFruit", e.plantId, e.fruitId) end
		end) end
	end,
})
FarmTab:Slider({ Title = "Collect interval", Step = 0.05, Value = { Min = 0.05, Max = 5, Default = 0.15 },
	Callback = function(v) State.collectDelay = v end })

FarmTab:Section({ Title = "Plant" })
State.plantSeeds = {}
FarmTab:Dropdown({
	Title = "Seeds to auto-plant", Values = SeedNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local set = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do set[s] = true end elseif sel then set[sel] = true end
		State.plantSeeds = set
	end,
})
State.autoPlant, State.plantDelay = false, 0.6
FarmTab:Toggle({
	Title = "Auto-Plant",
	Desc  = "Equips seed tools and plants across your plot.",
	Value = false,
	Callback = function(on)
		State.autoPlant = on
		if on then startLoop("plant", "autoPlant", "plantDelay", function()
			for _, tool in ipairs(getSeedTools()) do
				local seedName = tool:GetAttribute("SeedTool")
				if next(State.plantSeeds) == nil or State.plantSeeds[seedName] then
					local pos = getPlantPosition()
					if pos then equipTool(tool); task.wait(0.05); fire("Plant", "PlantSeed", pos, seedName, tool) end
				end
			end
		end) end
	end,
})
FarmTab:Slider({ Title = "Plant interval", Step = 0.1, Value = { Min = 0.2, Max = 5, Default = 0.6 },
	Callback = function(v) State.plantDelay = v end })

FarmTab:Section({ Title = "Water" })
State.autoWater, State.waterDelay = false, 1
FarmTab:Toggle({
	Title = "Auto-Water Plants",
	Desc  = "Equips a watering can and waters your plants (boosts growth).",
	Value = false,
	Callback = function(on)
		State.autoWater = on
		if on then startLoop("water", "autoWater", "waterDelay", function()
			local cans = getWateringCans()
			if #cans == 0 then return end
			local can = cans[1]
			local attr = can:GetAttribute("WateringCan")
			equipTool(can)
			for _, plant in ipairs(myPlantModels()) do
				local pos = modelPosition(plant)
				if pos then fire("WateringCan", "UseWateringCan", pos - Vector3.new(0, 0.3, 0), attr, can); task.wait(0.05) end
			end
		end) end
	end,
})
FarmTab:Slider({ Title = "Water interval", Step = 0.5, Value = { Min = 0.5, Max = 15, Default = 1 },
	Callback = function(v) State.waterDelay = v end })

FarmTab:Section({ Title = "Grow-All & Merge" })
State.autoGrowAll, State.growAllDelay = false, 30
FarmTab:Toggle({
	Title = "Auto Grow-All",
	Value = false,
	Callback = function(on)
		State.autoGrowAll = on
		if on then startLoop("growall", "autoGrowAll", "growAllDelay", function()
			local r = remote("Garden", "RequestGrowAllData")
			if r and r.Fire then pcall(function() r:Fire() end) end
		end) end
	end,
})
FarmTab:Slider({ Title = "Grow-All interval", Step = 1, Value = { Min = 5, Max = 120, Default = 30 },
	Callback = function(v) State.growAllDelay = v end })

--============================================================--
--  TAB: Sell
--============================================================--
local SellTab = Window:Tab({ Title = "Sell", Icon = "coins" })
SellTab:Section({ Title = "Selling" })
SellTab:Button({ Title = "Sell All Now", Desc = "Sells inventory to the nearest NPC.",
	Callback = function() fire("NPCS", "SellAll"); WindUI:Notify({ Title = "Sell All", Content = "Requested", Icon = "coins", Duration = 3 }) end })
SellTab:Button({ Title = "Preview Sell All",
	Callback = function()
		local res = invoke({ "NPCS", "PreviewSellAll" })
		WindUI:Notify({ Title = "Preview", Content = "Result: " .. tostring(res), Icon = "eye", Duration = 4 })
	end })
State.autoSell, State.sellDelay = false, 30
SellTab:Toggle({ Title = "Auto-Sell All", Desc = "Stand near a sell NPC.", Value = false,
	Callback = function(on)
		State.autoSell = on
		if on then startLoop("sell", "autoSell", "sellDelay", function() fire("NPCS", "SellAll") end) end
	end })
SellTab:Slider({ Title = "Auto-Sell interval", Step = 5, Value = { Min = 5, Max = 300, Default = 30 },
	Callback = function(v) State.sellDelay = v end })

--============================================================--
--  TAB: Steal
--============================================================--
local StealTab = Window:Tab({ Title = "Steal", Icon = "swords" })
StealTab:Section({ Title = "Fruit Steal" })
StealTab:Paragraph({ Title = "How it works", Desc = "Scans other players' gardens for fruit near you and steals it via the game's Steal remote (BeginSteal → CompleteSteal)." })
State.stealRange = 2000
State.stealFast = true
StealTab:Slider({ Title = "Steal range (studs)", Step = 25, Value = { Min = 50, Max = 2000, Default = 2000 },
	Callback = function(v) State.stealRange = v end })
StealTab:Toggle({ Title = "Fast mode (no per-fruit delay)", Desc = "Fires all steals back-to-back each sweep.", Value = true,
	Callback = function(on) State.stealFast = on end })
StealTab:Button({ Title = "Steal Nearby Once",
	Callback = function()
		local list = scanStealable(State.stealRange)
		for _, e in ipairs(list) do
			fire("Steal", "BeginSteal", e.owner, e.plantId, e.fruitId)
			fire("Steal", "CompleteSteal")
			if not State.stealFast then task.wait(0.05) end
		end
		WindUI:Notify({ Title = "Steal", Content = ("Attempted %d"):format(#list), Icon = "swords", Duration = 3 })
	end })
State.autoSteal, State.stealDelay = false, 0.3
StealTab:Toggle({ Title = "Auto-Steal", Value = false,
	Callback = function(on)
		State.autoSteal = on
		if on then startLoop("steal", "autoSteal", "stealDelay", function()
			for _, e in ipairs(scanStealable(State.stealRange)) do
				fire("Steal", "BeginSteal", e.owner, e.plantId, e.fruitId)
				fire("Steal", "CompleteSteal")
				if not State.stealFast then task.wait(0.03) end
			end
		end) end
	end })
StealTab:Slider({ Title = "Auto-Steal interval", Step = 0.1, Value = { Min = 0.1, Max = 10, Default = 0.3 },
	Callback = function(v) State.stealDelay = v end })

--============================================================--
--  TAB: Shop
--============================================================--
local ShopTab = Window:Tab({ Title = "Shop", Icon = "shopping-cart" })
ShopTab:Section({ Title = "Seed Shop" })
State.buySeedList, State.autoBuySeeds, State.buySeedDelay = {}, false, 1
State.buyAllSeeds, State.buyFast = false, true
local function seedsToBuy()
	if State.buyAllSeeds or next(State.buySeedList) == nil then return SeedNames end
	return State.buySeedList
end
ShopTab:Dropdown({ Title = "Seeds to auto-buy", Values = SeedNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local list = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do list[#list + 1] = s end elseif sel then list[1] = sel end
		State.buySeedList = list
	end })
ShopTab:Toggle({ Title = "Buy ALL seeds", Desc = "Ignores the dropdown and buys every seed each sweep.", Value = false,
	Callback = function(on) State.buyAllSeeds = on end })
ShopTab:Toggle({ Title = "Fast mode (no per-seed delay)", Value = true,
	Callback = function(on) State.buyFast = on end })
ShopTab:Toggle({ Title = "Auto-Buy Seeds", Value = false,
	Callback = function(on)
		State.autoBuySeeds = on
		if on then startLoop("buyseeds", "autoBuySeeds", "buySeedDelay", function()
			for _, seed in ipairs(seedsToBuy()) do
				fire("SeedShop", "PurchaseSeed", seed)
				if not State.buyFast then task.wait(0.05) end
			end
		end) end
	end })
ShopTab:Slider({ Title = "Buy interval", Step = 0.1, Value = { Min = 0.1, Max = 30, Default = 1 },
	Callback = function(v) State.buySeedDelay = v end })
ShopTab:Button({ Title = "Buy All / Selected Once",
	Callback = function()
		local n = 0
		for _, seed in ipairs(seedsToBuy()) do fire("SeedShop", "PurchaseSeed", seed); n += 1; if not State.buyFast then task.wait(0.05) end end
		WindUI:Notify({ Title = "Shop", Content = ("Bought %d seed types"):format(n), Icon = "shopping-cart", Duration = 3 })
	end })

ShopTab:Section({ Title = "Gear Shop" })
ShopTab:Input({ Title = "Buy gear (exact name)", Placeholder = "e.g. Watering Can",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "PurchaseGear", t) end end })
ShopTab:Input({ Title = "Equip gear (exact name)", Placeholder = "gear name",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "EquipGear", t) end end })
ShopTab:Input({ Title = "Unequip gear (exact name)", Placeholder = "gear name",
	Callback = function(t) if t and t ~= "" then fire("GearShop", "UnequipGear", t) end end })

ShopTab:Section({ Title = "Crates & Seed Packs" })
ShopTab:Dropdown({ Title = "Buy crate", Values = CrateNames, Value = nil, AllowNone = true,
	Callback = function(sel) if sel and sel ~= "" then fire("CrateShop", "PurchaseCrate", sel) end end })
ShopTab:Input({ Title = "Open seed pack (id/name)", Placeholder = "seed pack id",
	Callback = function(t) if t and t ~= "" then invoke({ "SeedPack", "OpenSeedPack" }, t) end end })

--============================================================--
--  TAB: Eggs & Pets
--============================================================--
local EggTab = Window:Tab({ Title = "Eggs & Pets", Icon = "egg" })
EggTab:Section({ Title = "Eggs" })
State.openEggList, State.autoOpenEgg, State.eggDelay = {}, false, 3
EggTab:Dropdown({ Title = "Eggs to auto-open", Values = EggNames, Value = {}, Multi = true, AllowNone = true,
	Callback = function(sel)
		local list = {}
		if type(sel) == "table" then for _, s in ipairs(sel) do list[#list + 1] = s end elseif sel then list[1] = sel end
		State.openEggList = list
	end })
EggTab:Toggle({ Title = "Auto-Open Eggs", Value = false,
	Callback = function(on)
		State.autoOpenEgg = on
		if on then startLoop("eggs", "autoOpenEgg", "eggDelay", function()
			for _, egg in ipairs(State.openEggList) do invoke({ "Egg", "OpenEgg" }, egg); task.wait(0.25) end
		end) end
	end })
EggTab:Slider({ Title = "Egg interval", Step = 1, Value = { Min = 1, Max = 30, Default = 3 },
	Callback = function(v) State.eggDelay = v end })

EggTab:Section({ Title = "Wild Pets" })
State.autoTame, State.tameDelay, State.tameRange = false, 1, 150
EggTab:Toggle({ Title = "Auto-Tame Wild Pets", Desc = "Tames nearby wild pets (CollectionService 'WildPet').", Value = false,
	Callback = function(on)
		State.autoTame = on
		if on then startLoop("tame", "autoTame", "tameDelay", function()
			local _, hrp = getCharacter(); if not hrp then return end
			local tagged = CollectionService:GetTagged("WildPet")
			if #tagged == 0 then
				local wp = Workspace:FindFirstChild("WildPets")
				if wp then tagged = wp:GetChildren() end
			end
			for _, pet in ipairs(tagged) do
				local pos = modelPosition(pet)
				if pos and (pos - hrp.Position).Magnitude <= State.tameRange then
					fire("Pets", "WildPetTame", pet); task.wait(0.1)
				end
			end
		end) end
	end })
EggTab:Slider({ Title = "Tame range", Step = 10, Value = { Min = 20, Max = 500, Default = 150 },
	Callback = function(v) State.tameRange = v end })

EggTab:Section({ Title = "Pets" })
EggTab:Input({ Title = "Equip pet by name", Placeholder = "exact pet name",
	Callback = function(t) if t and t ~= "" then fire("Pets", "RequestEquipByName", t) end end })
EggTab:Input({ Title = "Unequip pet by name", Placeholder = "exact pet name",
	Callback = function(t) if t and t ~= "" then fire("Pets", "RequestUnequipByName", t) end end })
EggTab:Button({ Title = "Purchase Pet Slot", Callback = function() fire("Pets", "RequestPurchasePetSlot") end })
EggTab:Button({ Title = "Snap Pets To Me",
	Callback = function() local _, hrp = getCharacter(); if hrp then fire("Pets", "SnapPets", hrp.Position) end end })

--============================================================--
--  TAB: Tools / Abilities
--============================================================--
local ToolTab = Window:Tab({ Title = "Tools", Icon = "wand" })
ToolTab:Section({ Title = "Targeted tools" })
ToolTab:Paragraph({ Title = "Note", Desc = "Equip the matching tool first. Actions fire at the nearest other player." })

local function nearestPlayer()
	local _, hrp = getCharacter(); if not hrp then return nil end
	local best, bestD
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local h = p.Character:FindFirstChild("HumanoidRootPart")
			if h then local d = (h.Position - hrp.Position).Magnitude; if not bestD or d < bestD then best, bestD = p, d end end
		end
	end
	return best
end

ToolTab:Button({ Title = "Freeze Ray → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("FreezeRay", "Fire", p.Character.HumanoidRootPart.Position, t) end
	end })
ToolTab:Button({ Title = "Strawberry Sniper → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("StrawberrySniper", "Fire", p.Character.HumanoidRootPart.Position, p.Character, t) end
	end })
ToolTab:Button({ Title = "Grappling Hook → nearest",
	Callback = function()
		local t = getEquippedTool(); local p = nearestPlayer()
		if t and p and p.Character then fire("GrapplingHook", "Fire", p.Character.HumanoidRootPart.Position, t) end
	end })
ToolTab:Button({ Title = "Power Hose → nearest",
	Callback = function()
		local p = nearestPlayer()
		if p and p.Character then fire("PowerHose", "Activate", p.Character.HumanoidRootPart) end
	end })
ToolTab:Button({ Title = "Bull Horn Blast",
	Callback = function() local _, hrp = getCharacter(); if hrp then fire("BullHorn", "Blast", hrp.Position) end end })
ToolTab:Button({ Title = "Flashbang", Callback = function() fire("Flashbang", "Flashbang") end })
ToolTab:Button({ Title = "Swing Shovel", Callback = function() local t = getEquippedTool(); if t then fire("Shovel", "SwingShovel", t) end end })
ToolTab:Button({ Title = "Swing Crowbar", Callback = function() fire("Crowbar", "SwingCrowbar") end })

ToolTab:Section({ Title = "Fruit magnet" })
ToolTab:Button({ Title = "Activate held Magnet on me",
	Callback = function() local t = getEquippedTool(); if t then fire("FruitMagnet", "Activate", t, 60, 1) end end })

--============================================================--
--  TAB: Weather & Codes
--============================================================--
local WeatherTab = Window:Tab({ Title = "Weather", Icon = "cloud" })
WeatherTab:Section({ Title = "Redeem codes" })
WeatherTab:Input({ Title = "Redeem code", Placeholder = "enter code",
	Callback = function(t)
		if t and t ~= "" then
			local res = invoke({ "Settings", "SubmitCode" }, t)
			WindUI:Notify({ Title = "Code", Content = tostring(res) ~= "nil" and ("Result: " .. tostring(res)) or "Submitted", Icon = "gift", Duration = 4 })
		end
	end })

WeatherTab:Section({ Title = "Weather staves (equip first)" })
WeatherTab:Button({ Title = "Weather Staff — Trigger", Callback = function() fire("WeatherStaff", "TriggerWeather") end })
WeatherTab:Button({ Title = "Wind Staff — Tornado", Callback = function() fire("WindStaff", "TriggerTornado") end })

WeatherTab:Section({ Title = "Weather machine" })
WeatherTab:Button({ Title = "Signal Entered Machine",
	Callback = function() fire("WeatherMachine", "PlayerEntered", tostring(LocalPlayer.UserId), "") end })

WeatherTab:Section({ Title = "Notifications" })
State.weatherNotify = true
WeatherTab:Toggle({ Title = "Notify on weather events", Value = true,
	Callback = function(on) State.weatherNotify = on end })
do
	local events = { "RainStart","BloodmoonStart","EclipseStart","BlizzardStart","NightStart","RainbowStart","LightningStart" }
	for _, ev in ipairs(events) do
		local r = remote("WeatherEffects", ev)
		if r and r.OnClientEvent then
			pcall(function()
				r.OnClientEvent:Connect(function()
					if State.weatherNotify then
						WindUI:Notify({ Title = "Weather", Content = ev:gsub("Start", "") .. " started!", Icon = "cloud-lightning", Duration = 5 })
					end
				end)
			end)
		end
	end
end

--============================================================--
--  TAB: Social
--============================================================--
local SocialTab = Window:Tab({ Title = "Social", Icon = "users" })
SocialTab:Section({ Title = "Mailbox" })
SocialTab:Button({ Title = "Claim All Mail", Callback = function() fire("Mailbox", "ClaimAll"); WindUI:Notify({ Title = "Mailbox", Content = "Claimed", Icon = "mail", Duration = 3 }) end })
State.autoMailbox, State.mailboxDelay = false, 60
SocialTab:Toggle({ Title = "Auto-Claim Mailbox", Value = false,
	Callback = function(on)
		State.autoMailbox = on
		if on then startLoop("mailbox", "autoMailbox", "mailboxDelay", function() fire("Mailbox", "ClaimAll") end) end
	end })
SocialTab:Slider({ Title = "Mailbox interval", Step = 5, Value = { Min = 10, Max = 300, Default = 60 },
	Callback = function(v) State.mailboxDelay = v end })

SocialTab:Section({ Title = "Guild" })
SocialTab:Button({ Title = "Show My Guild",
	Callback = function()
		local g = invoke({ "Guild", "GetMyGuild" })
		WindUI:Notify({ Title = "Guild", Content = g and (typeof(g) == "table" and (g.Name or "In a guild") or tostring(g)) or "No guild", Icon = "shield", Duration = 5 })
	end })

SocialTab:Section({ Title = "Gifting" })
State.giftTarget = nil
SocialTab:Input({ Title = "Gift target UserId", Placeholder = "numeric UserId",
	Callback = function(t) State.giftTarget = tonumber(t) end })
SocialTab:Button({ Title = "Send held item as gift",
	Callback = function()
		local t = getEquippedTool()
		if State.giftTarget and t then fire("Gifting", "Send", State.giftTarget, t.Name, t:GetAttribute("ItemId") or "") end
	end })

SocialTab:Section({ Title = "Garden" })
SocialTab:Button({ Title = "Expand Garden",
	Callback = function() local r = remote("Actions", "ExpandGarden"); if r and r.Fire then pcall(function() r:Fire() end) end end })

SocialTab:Section({ Title = "Pilgrim" })
SocialTab:Button({ Title = "Submit Delivery", Callback = function() local r = remote("Pilgrim", "SubmitDelivery"); if r and r.Fire then pcall(function() r:Fire() end) end end })
SocialTab:Button({ Title = "Claim Reward", Callback = function() local r = remote("Pilgrim", "ClaimReward"); if r and r.Fire then pcall(function() r:Fire() end) end end })

--============================================================--
--  TAB: Auction
--============================================================--
local AuctionTab = Window:Tab({ Title = "Auction", Icon = "gavel" })
AuctionTab:Section({ Title = "Auctioneer" })
AuctionTab:Button({ Title = "Request Snapshot",
	Callback = function()
		local snap = invoke({ "Auctioneer", "RequestSnapshot" })
		WindUI:Notify({ Title = "Auction", Content = snap and "Snapshot received" or "No data", Icon = "gavel", Duration = 4 })
	end })
State.auctionLot, State.auctionPrice = "", 0
AuctionTab:Input({ Title = "Lot id", Placeholder = "lot id", Callback = function(t) State.auctionLot = t end })
AuctionTab:Input({ Title = "Bid price", Placeholder = "amount", Callback = function(t) State.auctionPrice = tonumber(t) or 0 end })
AuctionTab:Button({ Title = "Purchase Lot",
	Callback = function()
		if State.auctionLot ~= "" then fire("Auctioneer", "PurchaseLot", State.auctionLot, State.auctionPrice) end
	end })

--============================================================--
--  TAB: Visuals (ESP)
--============================================================--
local ESPTab = Window:Tab({ Title = "Visuals", Icon = "eye" })

-- ESP manager: keeps Highlight + BillboardGui instances keyed by target.
local ESP = { fruit = {}, players = {}, pets = {}, eggs = {} }
local function clearGroup(group)
	for k, obj in pairs(group) do
		if typeof(obj) == "Instance" then obj:Destroy() end
		group[k] = nil
	end
end
local function makeHighlight(adornee, fill, outline)
	local h = Instance.new("Highlight")
	h.FillColor = fill
	h.OutlineColor = outline or Color3.new(1, 1, 1)
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = adornee
	h.Parent = adornee
	return h
end
local function makeLabel(adornee, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 26)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = adornee
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = color or Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0.4
	lbl.Text = text
	lbl.Parent = bb
	bb.Parent = adornee
	return bb
end

State.espFruit, State.espPlayers, State.espPets, State.espEggs = false, false, false, false

ESPTab:Section({ Title = "Farm ESP" })
ESPTab:Toggle({ Title = "Ripe Fruit ESP", Desc = "Green highlight on fruit ready to collect.", Value = false,
	Callback = function(on) State.espFruit = on; if not on then clearGroup(ESP.fruit) end end })
ESPTab:Toggle({ Title = "Egg ESP", Value = false,
	Callback = function(on) State.espEggs = on; if not on then clearGroup(ESP.eggs) end end })
ESPTab:Toggle({ Title = "Pet ESP", Value = false,
	Callback = function(on) State.espPets = on; if not on then clearGroup(ESP.pets) end end })

ESPTab:Section({ Title = "Player ESP" })
ESPTab:Toggle({ Title = "Player ESP", Desc = "Highlight + name/distance on other players.", Value = false,
	Callback = function(on) State.espPlayers = on; if not on then clearGroup(ESP.players) end end })

-- ESP render loop
task.spawn(function()
	while true do
		pcall(function()
			local _, hrp = getCharacter()
			-- Fruit ESP
			if State.espFruit then
				local gardens = Workspace:FindFirstChild("Gardens")
				local seen = {}
				if gardens then
					for _, garden in ipairs(gardens:GetChildren()) do
						local plants = garden:FindFirstChild("Plants")
						if plants then
							for _, plant in ipairs(plants:GetChildren()) do
								local fruits = plant:FindFirstChild("Fruits")
								if fruits then
									for _, fruit in ipairs(fruits:GetChildren()) do
										local age, maxAge = fruit:GetAttribute("Age"), fruit:GetAttribute("MaxAge")
										local ripe = (typeof(age) ~= "number" or typeof(maxAge) ~= "number") or age >= maxAge
										if ripe and (fruit:IsA("Model") or fruit:IsA("BasePart")) then
											seen[fruit] = true
											if not ESP.fruit[fruit] then ESP.fruit[fruit] = makeHighlight(fruit, EmeraldHi, Emerald) end
										end
									end
								end
							end
						end
					end
				end
				for inst in pairs(ESP.fruit) do if not seen[inst] or not inst.Parent then if ESP.fruit[inst] then ESP.fruit[inst]:Destroy() end; ESP.fruit[inst] = nil end end
			end
			-- Egg ESP
			if State.espEggs then
				local seen = {}
				for _, egg in ipairs(CollectionService:GetTagged("Egg")) do
					if egg:IsA("Model") or egg:IsA("BasePart") then
						seen[egg] = true
						if not ESP.eggs[egg] then ESP.eggs[egg] = makeHighlight(egg, Color3.fromRGB(255, 210, 90), Color3.fromRGB(255, 170, 0)) end
					end
				end
				for inst in pairs(ESP.eggs) do if not seen[inst] or not inst.Parent then ESP.eggs[inst]:Destroy(); ESP.eggs[inst] = nil end end
			end
			-- Pet ESP
			if State.espPets then
				local seen = {}
				local pools = { CollectionService:GetTagged("WildPet") }
				local wp = Workspace:FindFirstChild("WildPets"); if wp then pools[#pools + 1] = wp:GetChildren() end
				for _, pool in ipairs(pools) do
					for _, pet in ipairs(pool) do
						if pet:IsA("Model") then
							seen[pet] = true
							if not ESP.pets[pet] then ESP.pets[pet] = makeHighlight(pet, Mint, Color3.new(1, 1, 1)) end
						end
					end
				end
				for inst in pairs(ESP.pets) do if not seen[inst] or not inst.Parent then ESP.pets[inst]:Destroy(); ESP.pets[inst] = nil end end
			end
			-- Player ESP
			if State.espPlayers then
				local seen = {}
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character then
						local char = p.Character
						local h = char:FindFirstChild("HumanoidRootPart")
						if h then
							seen[p] = true
							local rec = ESP.players[p]
							if not rec then
								rec = { hl = makeHighlight(char, Color3.fromRGB(255, 80, 80), Color3.new(1, 1, 1)), bb = makeLabel(h, p.Name, Color3.fromRGB(255, 120, 120)) }
								ESP.players[p] = rec
							else
								-- recreate adornments that died when the player respawned
								if not rec.hl or rec.hl.Parent == nil then
									rec.hl = makeHighlight(char, Color3.fromRGB(255, 80, 80), Color3.new(1, 1, 1))
								elseif rec.hl.Adornee ~= char then
									rec.hl.Adornee = char
								end
								if not rec.bb or rec.bb.Parent == nil then
									rec.bb = makeLabel(h, p.Name, Color3.fromRGB(255, 120, 120))
								end
								local dist = hrp and math.floor((h.Position - hrp.Position).Magnitude) or 0
								local lbl = rec.bb:FindFirstChildOfClass("TextLabel")
								if lbl then lbl.Text = string.format("%s  [%dm]", p.Name, dist) end
							end
						end
					end
				end
				for p, rec in pairs(ESP.players) do
					if not seen[p] then
						if rec.hl then rec.hl:Destroy() end
						if rec.bb then rec.bb:Destroy() end
						ESP.players[p] = nil
					end
				end
			end
		end)
		task.wait(0.5)
	end
end)

ESPTab:Section({ Title = "World" })
State.fullbright, State.noFog = false, false
local savedLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient }
ESPTab:Toggle({ Title = "Fullbright", Value = false,
	Callback = function(on)
		State.fullbright = on
		if on then
			Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		else
			Lighting.Brightness = savedLighting.Brightness; Lighting.ClockTime = savedLighting.ClockTime
			Lighting.GlobalShadows = savedLighting.GlobalShadows; Lighting.Ambient = savedLighting.Ambient
		end
	end })
ESPTab:Toggle({ Title = "No Fog", Value = false,
	Callback = function(on)
		State.noFog = on
		Lighting.FogEnd = on and 1e9 or savedLighting.FogEnd
	end })

--============================================================--
--  TAB: Player
--============================================================--
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
PlayerTab:Section({ Title = "Movement" })
local defaultWS, defaultJP = 16, 50
PlayerTab:Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 350, Default = 16 },
	Callback = function(v) defaultWS = v; local _, _, hum = getCharacter(); if hum then hum.WalkSpeed = v end end })
PlayerTab:Slider({ Title = "Jump Power", Step = 1, Value = { Min = 50, Max = 500, Default = 50 },
	Callback = function(v) defaultJP = v; local _, _, hum = getCharacter(); if hum then hum.UseJumpPower = true; hum.JumpPower = v end end })
State.infJump = false
PlayerTab:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(on) State.infJump = on end })
UserInputService.JumpRequest:Connect(function()
	if State.infJump then local _, _, hum = getCharacter(); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

State.noclip = false
PlayerTab:Toggle({ Title = "Noclip", Desc = "Walk through walls / plants.", Value = false,
	Callback = function(on) State.noclip = on end })
RunService.Stepped:Connect(function()
	if State.noclip then
		local char = LocalPlayer.Character
		if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
	end
end)

State.fly, State.flySpeed = false, 60
local flyBV, flyBG
PlayerTab:Toggle({ Title = "Fly", Desc = "WASD + Space/Shift. Toggle off to stop.", Value = false,
	Callback = function(on)
		State.fly = on
		local _, hrp = getCharacter()
		if on and hrp then
			flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
			flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9); flyBG.P = 1e4; flyBG.Parent = hrp
		else
			if flyBV then flyBV:Destroy(); flyBV = nil end
			if flyBG then flyBG:Destroy(); flyBG = nil end
		end
	end })
PlayerTab:Slider({ Title = "Fly speed", Step = 5, Value = { Min = 10, Max = 300, Default = 60 },
	Callback = function(v) State.flySpeed = v end })
RunService.RenderStepped:Connect(function()
	if not State.fly then return end
	local _, hrp = getCharacter()
	if not hrp then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	-- self-heal movers destroyed on respawn
	if not flyBV or flyBV.Parent == nil then
		if flyBV then pcall(function() flyBV:Destroy() end) end
		flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9); flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
	end
	if not flyBG or flyBG.Parent == nil then
		if flyBG then pcall(function() flyBG:Destroy() end) end
		flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9); flyBG.P = 1e4; flyBG.Parent = hrp
	end
	flyBG.CFrame = cam.CFrame
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
	flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * State.flySpeed
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		task.wait(0.5)
		pcall(function()
			hum.WalkSpeed = defaultWS
			if defaultJP ~= 50 then hum.UseJumpPower = true; hum.JumpPower = defaultJP end
		end)
	end
end)

PlayerTab:Section({ Title = "Teleport" })
PlayerTab:Button({ Title = "To My Plot",
	Callback = function()
		local _, hrp = getCharacter(); local plot = getPlayerPlot()
		local spawn = plot and plot:FindFirstChild("SpawnPoint")
		if hrp and spawn and spawn:IsA("BasePart") then hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
	end })
PlayerTab:Button({ Title = "To Nearest Sell NPC",
	Callback = function()
		local _, hrp = getCharacter(); if not hrp then return end
		local best, bestD
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and (obj.Name == "SellPart" or obj.Name == "Steven" or (obj.Parent and tostring(obj.Parent.Name):find("Sell"))) then
				local d = (obj.Position - hrp.Position).Magnitude; if not bestD or d < bestD then best, bestD = obj, d end
			end
		end
		if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 4)) else WindUI:Notify({ Title = "Teleport", Content = "No sell NPC found", Icon = "map-pin", Duration = 3 }) end
	end })

PlayerTab:Section({ Title = "Anti-AFK" })
State.antiAfk = false
PlayerTab:Toggle({ Title = "Anti-AFK", Value = false, Callback = function(on) State.antiAfk = on end })
do
	local ok, idle = pcall(function() return LocalPlayer.Idled end)
	if ok and idle then
		idle:Connect(function()
			if State.antiAfk then pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
		end)
	end
end

--============================================================--
--  TAB: Placement (best-effort: uses held tool + plot position)
--============================================================--
local PlaceTab = Window:Tab({ Title = "Placement", Icon = "hammer" })
PlaceTab:Paragraph({ Title = "Note", Desc = "Equip the matching item first; it's placed at a point on your plot." })
local function placeHeld(category, method, extra)
	local tool = getEquippedTool()
	local pos = getPlantPosition()
	if not tool or not pos then
		WindUI:Notify({ Title = "Placement", Content = "Hold a placeable item on your plot first", Icon = "triangle-alert", Duration = 3 })
		return
	end
	local args = { category, method, pos, tool.Name, tool }
	if extra then for _, e in ipairs(extra) do args[#args + 1] = e end end
	fire(table.unpack(args))
end
PlaceTab:Section({ Title = "Place held item" })
PlaceTab:Button({ Title = "Place Sprinkler", Callback = function() placeHeld("Place", "PlaceSprinkler", { 0 }) end })
PlaceTab:Button({ Title = "Place Gnome",     Callback = function() placeHeld("Place", "PlaceGnome") end })
PlaceTab:Button({ Title = "Place Raccoon",   Callback = function() placeHeld("Place", "PlaceRaccoon") end })
PlaceTab:Button({ Title = "Place Ladder",    Callback = function() placeHeld("Place", "PlaceLadder") end })
PlaceTab:Button({ Title = "Place Rake",      Callback = function() placeHeld("Place", "PlaceRake", { 0, 0 }) end })
PlaceTab:Button({ Title = "Place Bird",      Callback = function() placeHeld("Place", "PlaceBird") end })
PlaceTab:Button({ Title = "Place Prop",      Callback = function() placeHeld("Prop", "PlaceProp", { 0 }) end })
PlaceTab:Button({ Title = "Use Teleporter (here)", Callback = function()
	local _, hrp = getCharacter(); if hrp then fire("Place", "UseTeleporter", hrp.Position) end end })

--============================================================--
--  TAB: Inventory
--============================================================--
local InvTab = Window:Tab({ Title = "Inventory", Icon = "backpack" })
InvTab:Section({ Title = "Sell specific" })
InvTab:Input({ Title = "Sell fruit by id", Placeholder = "fruit id",
	Callback = function(t) if t and t ~= "" then local r = invoke({ "NPCS", "SellFruit" }, t); WindUI:Notify({ Title = "Sell Fruit", Content = tostring(r), Icon = "coins", Duration = 3 }) end end })
InvTab:Input({ Title = "Sell pet by id", Placeholder = "pet id",
	Callback = function(t) if t and t ~= "" then local r = invoke({ "NPCS", "SellPet" }, t); WindUI:Notify({ Title = "Sell Pet", Content = tostring(r), Icon = "coins", Duration = 3 }) end end })
InvTab:Section({ Title = "Daily deal" })
InvTab:Button({ Title = "Check Daily Deal", Callback = function() local r = invoke({ "NPCS", "CheckDailyDeal" }); WindUI:Notify({ Title = "Daily Deal", Content = r and "Available" or "None", Icon = "calendar", Duration = 4 }) end })
InvTab:Button({ Title = "Use Daily Deal (All)", Callback = function() invoke({ "NPCS", "UseDailyDealAll" }) end })
InvTab:Section({ Title = "Double or Nothing" })
InvTab:Button({ Title = "Double or Nothing", Callback = function() local r = invoke({ "NPCS", "DoubleOrNothing" }); WindUI:Notify({ Title = "DoN", Content = tostring(r), Icon = "dice-5", Duration = 4 }) end })
InvTab:Button({ Title = "Cash Out", Callback = function() invoke({ "NPCS", "CashOutDoubleOrNothing" }) end })
InvTab:Section({ Title = "Favorites & layout" })
InvTab:Input({ Title = "Favorite fruit by id", Placeholder = "fruit id",
	Callback = function(t) if t and t ~= "" then invoke({ "Backpack", "SetFruitFavorite" }, t, true) end end })
InvTab:Input({ Title = "Favorite pet by id", Placeholder = "pet id",
	Callback = function(t) if t and t ~= "" then invoke({ "Backpack", "SetPetFavorite" }, t, true) end end })
InvTab:Input({ Title = "Promote fruit by id", Placeholder = "fruit id",
	Callback = function(t) if t and t ~= "" then invoke({ "Backpack", "PromoteFruit" }, t) end end })
InvTab:Section({ Title = "Plant management" })
InvTab:Input({ Title = "Pot plant by id", Placeholder = "plant id",
	Callback = function(t) if t and t ~= "" then fire("Garden", "PotPlant", t) end end })
InvTab:Button({ Title = "Sell All Pets (loop inventory)", Desc = "Best-effort: sells pets found in Backpack by name.",
	Callback = function()
		local bp = LocalPlayer:FindFirstChild("Backpack")
		if bp then for _, tool in ipairs(bp:GetChildren()) do
			local id = tool:GetAttribute("PetId") or tool:GetAttribute("Id")
			if id then invoke({ "NPCS", "SellPet" }, id); task.wait(0.1) end
		end end
	end })

--============================================================--
--  TAB: Skills
--============================================================--
local SkillTab = Window:Tab({ Title = "Skills", Icon = "star" })
SkillTab:Button({ Title = "Request Skill Data", Callback = function()
	local r = invoke({ "SkillPoints", "RequestSkillData" })
	WindUI:Notify({ Title = "Skills", Content = r and "Data received" or "No data", Icon = "star", Duration = 4 })
end })
SkillTab:Input({ Title = "Spend skill point on", Placeholder = "skill name",
	Callback = function(t) if t and t ~= "" then fire("SkillPoints", "SpendSkillPoint", t) end end })

--============================================================--
--  TAB: Travel
--============================================================--
local TravelTab = Window:Tab({ Title = "Travel", Icon = "plane" })
TravelTab:Button({ Title = "Get Travel Targets", Callback = function()
	local r = invoke({ "Worlds", "GetTravelTargets" })
	WindUI:Notify({ Title = "Worlds", Content = r and "Targets received" or "None", Icon = "globe", Duration = 4 })
end })
TravelTab:Input({ Title = "Request travel to world", Placeholder = "world name/id",
	Callback = function(t) if t and t ~= "" then fire("Worlds", "RequestTravel", t) end end })
TravelTab:Input({ Title = "Teleport button request", Placeholder = "destination id",
	Callback = function(t) if t and t ~= "" then fire("TeleportButton", "Request", t) end end })
TravelTab:Button({ Title = "Anti-AFK Server Hop", Desc = "Requests the game's own server hop.",
	Callback = function() fire("AntiAfk", "RequestHop") end })

--============================================================--
--  TAB: Fun
--============================================================--
local FunTab = Window:Tab({ Title = "Fun", Icon = "sparkles" })
FunTab:Section({ Title = "Toys" })
FunTab:Button({ Title = "Roll Magic Dice (held)", Callback = function() local t = getEquippedTool(); if t then fire("MagicDice", "PlayRoll", t) end end })
FunTab:Button({ Title = "Wheelbarrow Charge", Callback = function() fire("Wheelbarrow", "Charge") end })
FunTab:Button({ Title = "Carpet Equip", Callback = function() fire("Carpet", "Equip") end })
FunTab:Button({ Title = "Carpet Unequip", Callback = function() fire("Carpet", "Unequip") end })
FunTab:Section({ Title = "Sign / Megaphone / Boombox" })
FunTab:Input({ Title = "Set sign text", Placeholder = "text", Callback = function(t) if t then fire("SignTool", "SetSignText", t) end end })
FunTab:Input({ Title = "Set sign image id", Placeholder = "rbxassetid", Callback = function(t) if t then fire("SignTool", "SetSignImage", t) end end })
FunTab:Input({ Title = "Megaphone sound id", Placeholder = "sound id", Callback = function(t) if t then fire("Megaphone", "SetSoundId", t) end end })
FunTab:Button({ Title = "Megaphone Play", Callback = function() fire("Megaphone", "Play", 1, false) end })
FunTab:Section({ Title = "Chat" })
FunTab:Input({ Title = "Chat announcement", Placeholder = "message", Callback = function(t) if t and t ~= "" then fire("ChatAnnouncement", t) end end })

--============================================================--
--  TAB: Events
--============================================================--
local EventTab = Window:Tab({ Title = "Events", Icon = "calendar" })
EventTab:Section({ Title = "Stock & releases" })
EventTab:Button({ Title = "Request Fruit Stock", Callback = function()
	local r = invoke({ "FruitStock", "Request" }); WindUI:Notify({ Title = "Fruit Stock", Content = r and "Received" or "None", Icon = "package", Duration = 4 }) end })
EventTab:Button({ Title = "Request Changelog", Callback = function()
	local r = invoke({ "Release", "ChangelogRequest" }); WindUI:Notify({ Title = "Changelog", Content = r and "Received" or "None", Icon = "scroll", Duration = 4 }) end })
EventTab:Section({ Title = "Pet Hunt" })
EventTab:Input({ Title = "Join pet hunt queue", Placeholder = "queue id", Callback = function(t) if t and t ~= "" then invoke({ "PetHunt", "JoinQueue" }, t) end end })
EventTab:Button({ Title = "Leave pet hunt queue", Callback = function() invoke({ "PetHunt", "LeaveQueue" }) end })
EventTab:Section({ Title = "Crate & tutorial" })
EventTab:Input({ Title = "Open crate by id", Placeholder = "crate id", Callback = function(t) if t and t ~= "" then invoke({ "Crate", "OpenCrate" }, t) end end })
EventTab:Button({ Title = "Complete Tutorial", Callback = function() fire("Tutorial", "Complete") end })
EventTab:Input({ Title = "Play cutscene", Placeholder = "cutscene id", Callback = function(t) if t and t ~= "" then fire("PlayCutscene", t) end end })

--============================================================--
--  TAB: Remotes (generic runner — reaches EVERY remote)
--============================================================--
local RemoteTab = Window:Tab({ Title = "Remotes", Icon = "terminal" })
RemoteTab:Section({ Title = "Fire any remote" })
local remotePaths = allRemotePaths()
RemoteTab:Paragraph({ Title = "Coverage", Desc = ("%d remotes discovered in the game's Networking module. Pick one, supply comma-separated args, and Fire (or Invoke for a response)."):format(#remotePaths) })
local selectedRemote = remotePaths[1]
local remoteArgs = ""
if #remotePaths > 0 then
	RemoteTab:Dropdown({
		Title = "Remote", Values = remotePaths, Value = remotePaths[1], AllowNone = false,
		Callback = function(v) if type(v) == "table" then selectedRemote = v[1] else selectedRemote = v end end,
	})
else
	RemoteTab:Paragraph({ Title = "No remotes", Desc = "Networking module unavailable — remote features are disabled." })
end
RemoteTab:Input({ Title = "Arguments (comma-separated)", Placeholder = "e.g. Carrot, 5, true", Callback = function(t) remoteArgs = t or "" end })
RemoteTab:Button({ Title = "Fire", Callback = function()
	if not selectedRemote then return end
	local combined, base = {}, 0
	for seg in string.gmatch(selectedRemote, "([^.]+)") do base += 1; combined[base] = seg end
	local args = parseArgs(remoteArgs)
	for i = 1, args.n do combined[base + i] = args[i] end
	fire(table.unpack(combined, 1, base + args.n))
	WindUI:Notify({ Title = "Remote fired", Content = selectedRemote, Icon = "terminal", Duration = 3 })
end })
RemoteTab:Button({ Title = "Invoke (show response)", Callback = function()
	if not selectedRemote then return end
	local path = {}
	for seg in string.gmatch(selectedRemote, "([^.]+)") do path[#path + 1] = seg end
	local args = parseArgs(remoteArgs)
	local res = invoke(path, table.unpack(args, 1, args.n))
	WindUI:Notify({ Title = selectedRemote, Content = "Response: " .. tostring(res), Icon = "terminal", Duration = 5 })
end })

-- ---- Raw instance remotes (RemoteEvent / RemoteFunction not in the Packet table) ----
RemoteTab:Section({ Title = "Raw instance remotes" })
local rawMap, rawNames = {}, {}
do
	local skip = ReplicatedStorage:FindFirstChild("SharedModules")
	skip = skip and skip:FindFirstChild("Packet")
	skip = skip and skip:FindFirstChild("RemoteEvent") -- don't fire the Packet tunnel directly
	for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
		if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent")) and d ~= skip then
			local nm = d:GetFullName()
			if not rawMap[nm] then rawMap[nm] = d; rawNames[#rawNames + 1] = nm end
		end
	end
	table.sort(rawNames)
end
local rawSel = rawNames[1]
local rawArgs = ""
RemoteTab:Paragraph({ Title = "Raw remotes", Desc = ("%d raw RemoteEvent/RemoteFunction instances found (Charm, Replica, FireFernLit, StarFruitBeam, Cmdr, …)."):format(#rawNames) })
if #rawNames > 0 then
	RemoteTab:Dropdown({ Title = "Raw remote", Values = rawNames, Value = rawNames[1], AllowNone = false,
		Callback = function(v) if type(v) == "table" then rawSel = v[1] else rawSel = v end end })
	RemoteTab:Input({ Title = "Raw args (comma-separated)", Placeholder = "e.g. 5, true, hello", Callback = function(t) rawArgs = t or "" end })
	RemoteTab:Button({ Title = "Fire / Invoke raw", Callback = function()
		local inst = rawMap[rawSel]
		if not inst then return end
		local a = parseArgs(rawArgs)
		if inst:IsA("RemoteFunction") then
			local ok, res = pcall(function() return inst:InvokeServer(table.unpack(a, 1, a.n)) end)
			WindUI:Notify({ Title = inst.Name, Content = ok and ("Response: " .. tostring(res)) or "Invoke failed", Icon = "terminal", Duration = 5 })
		else
			pcall(function() inst:FireServer(table.unpack(a, 1, a.n)) end)
			WindUI:Notify({ Title = "Fired", Content = inst.Name, Icon = "terminal", Duration = 3 })
		end
	end })
end

-- ---- Quick buttons for known standalone remotes ----
RemoteTab:Section({ Title = "Standalone shortcuts" })
RemoteTab:Button({ Title = "Fire Fern — Lit", Callback = function()
	local r = ReplicatedStorage:FindFirstChild("FireFernLit")
	if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
end })
RemoteTab:Button({ Title = "Star Fruit Beam", Callback = function()
	local r = ReplicatedStorage:FindFirstChild("StarFruitBeam")
	if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
end })
RemoteTab:Button({ Title = "Request Data (Replica refresh)", Callback = function()
	local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local r = re and re:FindFirstChild("ReplicaRequestData")
	if r then pcall(function() r:FireServer() end); WindUI:Notify({ Title = "Replica", Content = "Requested data", Icon = "refresh-cw", Duration = 3 }) end
end })
RemoteTab:Button({ Title = "Charm — Request State Sync", Callback = function()
	local n = ReplicatedStorage:FindFirstChild("SharedModules")
	n = n and n:FindFirstChild("Networking"); n = n and n:FindFirstChild("Charm"); n = n and n:FindFirstChild("RequestState")
	if n then pcall(function() n:FireServer() end) end
end })

-- ---- Cmdr admin command runner (works only if you have Cmdr access) ----
RemoteTab:Section({ Title = "Cmdr command (admin only)" })
RemoteTab:Input({ Title = "Run Cmdr command", Placeholder = "e.g. help",
	Callback = function(text)
		if not text or text == "" then return end
		local cc = ReplicatedStorage:FindFirstChild("CmdrClient")
		if not cc then WindUI:Notify({ Title = "Cmdr", Content = "CmdrClient not found", Icon = "triangle-alert", Duration = 3 }); return end
		local ok = pcall(function()
			local Cmdr = require(cc)
			if Cmdr.Dispatcher and Cmdr.Dispatcher.Run then Cmdr.Dispatcher:Run(text)
			elseif Cmdr.Run then Cmdr:Run(text) end
		end)
		WindUI:Notify({ Title = "Cmdr", Content = ok and ("Ran: " .. text) or "Command blocked / no access", Icon = "terminal", Duration = 4 })
	end })

--============================================================--
--  TAB: Teleports (players + server hop)
--============================================================--
local TpTab = Window:Tab({ Title = "Teleports", Icon = "plane" })
TpTab:Section({ Title = "Players" })
local function playerNames()
	local names = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then names[#names + 1] = p.Name end
	end
	table.sort(names)
	return names
end
State.tpTarget = nil
local playerDrop = TpTab:Dropdown({ Title = "Select player", Values = playerNames(), Value = nil, AllowNone = true,
	Callback = function(v) State.tpTarget = (type(v) == "table") and v[1] or v end })
TpTab:Button({ Title = "Refresh player list", Callback = function()
	pcall(function() playerDrop:Set(playerNames()) end)
	WindUI:Notify({ Title = "Players", Content = ("%d others online"):format(#playerNames()), Icon = "users", Duration = 3 })
end })
TpTab:Button({ Title = "Teleport to selected", Callback = function()
	local _, hrp = getCharacter()
	local tp = State.tpTarget and Players:FindFirstChild(State.tpTarget)
	local thrp = tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
	if hrp and thrp then hrp.CFrame = thrp.CFrame + Vector3.new(0, 4, 0)
	else WindUI:Notify({ Title = "Teleport", Content = "Player not found", Icon = "map-pin", Duration = 3 }) end
end })
State.spectate, State.spectateReset = false, nil
TpTab:Toggle({ Title = "Spectate selected", Value = false,
	Callback = function(on)
		State.spectate = on
		local cam = Workspace.CurrentCamera
		if on then
			local tp = State.tpTarget and Players:FindFirstChild(State.tpTarget)
			if tp and tp.Character and tp.Character:FindFirstChildOfClass("Humanoid") then
				State.spectateReset = cam.CameraSubject
				cam.CameraSubject = tp.Character:FindFirstChildOfClass("Humanoid")
			end
		else
			local char = LocalPlayer.Character
			cam.CameraSubject = (char and char:FindFirstChildOfClass("Humanoid")) or State.spectateReset
		end
	end })

TpTab:Section({ Title = "Server" })
TpTab:Button({ Title = "Rejoin server", Callback = function()
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end })
TpTab:Button({ Title = "Server Hop (new server)", Desc = "Finds another public server and teleports.",
	Callback = function()
		WindUI:Notify({ Title = "Server Hop", Content = "Searching for a server…", Icon = "globe", Duration = 3 })
		task.spawn(function()
			local ok, body = pcall(function()
				return game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			end)
			if not ok or not body then WindUI:Notify({ Title = "Server Hop", Content = "Server list unavailable", Icon = "triangle-alert", Duration = 4 }); return end
			local HttpService = game:GetService("HttpService")
			local dec = select(2, pcall(function() return HttpService:JSONDecode(body) end))
			if not dec or not dec.data then WindUI:Notify({ Title = "Server Hop", Content = "Could not parse servers", Icon = "triangle-alert", Duration = 4 }); return end
			for _, s in ipairs(dec.data) do
				if type(s) == "table" and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
					pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) end)
					return
				end
			end
			WindUI:Notify({ Title = "Server Hop", Content = "No open server found", Icon = "map-pin", Duration = 4 })
		end)
	end })

--============================================================--
--  TAB: Performance
--============================================================--
local PerfTab = Window:Tab({ Title = "Performance", Icon = "sparkles" })
PerfTab:Section({ Title = "FPS" })
local fpsPara = PerfTab:Paragraph({ Title = "Live FPS / Ping", Desc = "Measuring…" })
do
	local frames, last = 0, os.clock()
	RunService.RenderStepped:Connect(function() frames += 1 end)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			local fps = math.floor(frames / (now - last) + 0.5)
			frames, last = 0, now
			local ping = "?"
			pcall(function()
				local stat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
				ping = math.floor(stat:GetValue()) .. "ms"
			end)
			pcall(function() fpsPara:SetDesc(("FPS: %d   •   Ping: %s"):format(fps, ping)) end)
		end
	end)
end

PerfTab:Section({ Title = "Boost" })
State.fpsBoost = false
local boostConn
local function applyBoost(root)
	for _, d in ipairs(root:GetDescendants()) do
		pcall(function()
			if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
				d.Enabled = false
			elseif d:IsA("BasePart") then
				d.Material = Enum.Material.SmoothPlastic; d.Reflectance = 0
			elseif d:IsA("Decal") or d:IsA("Texture") then
				d.Transparency = 1
			elseif d:IsA("PostEffect") then
				d.Enabled = false
			end
		end)
	end
end
PerfTab:Toggle({ Title = "FPS Boost", Desc = "Strips particles/textures/effects (visual downgrade).", Value = false,
	Callback = function(on)
		State.fpsBoost = on
		if on then
			pcall(function()
				Lighting.GlobalShadows = false; Lighting.FogEnd = 1e9
				local t = Workspace:FindFirstChildOfClass("Terrain")
				if t then t.WaterWaveSize = 0; t.WaterWaveSpeed = 0; t.WaterReflectance = 0; t.Decoration = false end
			end)
			applyBoost(Workspace); applyBoost(Lighting)
			if not boostConn then
				boostConn = Workspace.DescendantAdded:Connect(function(d)
					if not State.fpsBoost then return end
					task.defer(function()
						pcall(function()
							if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") then d.Enabled = false
							elseif d:IsA("BasePart") then d.Material = Enum.Material.SmoothPlastic end
						end)
					end)
				end)
			end
			WindUI:Notify({ Title = "Performance", Content = "FPS Boost applied", Icon = "sparkles", Duration = 3 })
		else
			if boostConn then boostConn:Disconnect(); boostConn = nil end
			WindUI:Notify({ Title = "Performance", Content = "Boost off (rejoin to fully restore visuals)", Icon = "refresh-cw", Duration = 4 })
		end
	end })

PerfTab:Section({ Title = "Connection" })
State.autoReconnect = false
PerfTab:Toggle({ Title = "Auto-Reconnect on disconnect", Value = false,
	Callback = function(on) State.autoReconnect = on end })
do
	local gs = game:GetService("GuiService")
	local ok = pcall(function() return gs.ErrorMessageChanged end)
	if ok then
		gs.ErrorMessageChanged:Connect(function()
			if State.autoReconnect then
				task.wait(1)
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
				pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
			end
		end)
	end
end

-- keep the Teleports player dropdown fresh as players join/leave
Players.PlayerAdded:Connect(function() pcall(function() playerDrop:Set(playerNames()) end) end)
Players.PlayerRemoving:Connect(function() task.defer(function() pcall(function() playerDrop:Set(playerNames()) end) end) end)

--============================================================--
--  TAB: Settings
--============================================================--
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
SettingsTab:Section({ Title = "Interface" })
SettingsTab:Toggle({ Title = "Translucent background", Value = true,
	Callback = function(on) pcall(function() Window:SetBackgroundTransparency(on and 0.3 or 0) end) end })
SettingsTab:Button({ Title = "Remote categories loaded",
	Callback = function()
		local n = 0; if Net then for _ in pairs(Net) do n += 1 end end
		WindUI:Notify({ Title = "Networking", Content = ("%d categories"):format(n), Icon = "network", Duration = 4 })
	end })
SettingsTab:Button({ Title = "Stop ALL automation",
	Callback = function()
		for k in pairs(State) do if type(State[k]) == "boolean" then State[k] = false end end
		clearGroup(ESP.fruit); clearGroup(ESP.eggs); clearGroup(ESP.pets)
		for p, rec in pairs(ESP.players) do if rec.hl then rec.hl:Destroy() end; if rec.bb then rec.bb:Destroy() end; ESP.players[p] = nil end
		WindUI:Notify({ Title = "Stopped", Content = "All loops & ESP disabled", Icon = "octagon-x", Duration = 3 })
	end })
SettingsTab:Button({ Title = "Destroy UI",
	Callback = function()
		for k in pairs(State) do if type(State[k]) == "boolean" then State[k] = false end end
		task.wait(0.2); pcall(function() Window:Destroy() end)
	end })

SettingsTab:Section({ Title = "About" })
SettingsTab:Paragraph({ Title = "Grow a Garden 2 — Emerald · Full Edition",
	Desc = "Built on Verdant UI (custom, hand-made). Auto-farm, steal, shop, eggs/pets, tools, "
		.. "weather, social, auction and a full ESP suite, all driving the game's Networking remotes." })

WindUI:Notify({ Title = "Grow a Garden 2  |  Emerald", Content = "Full Edition loaded. Right-Shift toggles the menu.", Icon = "sprout", Duration = 6 })
