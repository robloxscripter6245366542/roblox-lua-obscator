--[[
==============================================================================
  JJS HUB  —  big multi-tab feature hub
==============================================================================
  A self-contained Roblox UI hub (loadstring-friendly) built around the JJS
  game. Includes an embedded UI library (draggable window, sidebar tabs,
  sections, toggles, sliders, dropdowns, keybinds, textboxes, notifications,
  config save/load) plus a large feature set.

  Feature reliability:
    * COMBAT tab uses the game's verified Knit remotes
      (ReplicatedStorage.Knit.Knit.Services.<Service>.RE.<Signal>).
    * PLAYER / VISUALS / AUTOMATION / TELEPORT / SERVER tabs are universal
      client-side tech that works in most Roblox experiences.

  NOTE: This game ships an AntiCheatService — aggressive movement features
  (fly / noclip / speed / hitbox) can be detected. They default OFF. Using
  automation in an online game violates the game's & Roblox's ToS and can
  get accounts banned. Use at your own risk.
==============================================================================
--]]

--============================================================================
-- Services
--============================================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local TeleportService    = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local function getCamera() return workspace.CurrentCamera end
local function getChar()   return LocalPlayer.Character end
local function getHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

--============================================================================
-- Config / persistence
--============================================================================
local CONFIG_FILE = "jjs_hub_config.json"

local Flags  = {}   -- universal feature flags (flag -> value)
local combat = {    -- combat settings (verified-remote features)
	masterEnabled         = true,
	autoBFChain           = true,
	bfChainMode           = "legit",   -- "legit" | "semi legit"
	offsetStuds           = 5,
	tweenTime             = 0.23,
	lookTime              = 0.5,
	autoFireFist          = true,
	divergentFistDelay    = 0.27,
	autoAim               = true,
	aimMode               = "Camera",  -- "Camera" | "Character"
	cameraSlowness        = 0,
	autoJump              = true,
	jumpDuration          = 0.01,
	jumpPower             = 45,
	legitInfrontCheck     = 10,
	legitSpeed            = 0.2,
	legitArcWidth         = 5.4,
	legitSlowdownInterval = 0.017,
	legitSlowdownAmount   = 0.011,
	legitBehindCheck      = true,
	legitBehindCheckDist  = 10,
	legitSideCheck        = true,
	feintEnabled          = false,
	feintDelay            = 0.32,
	maxTargetDistance     = 0,
	autoComboDash         = false,   -- dash toward target after a hit (combo extend)
	comboDashDelay        = 0.1,
}

local savedFlags = {}
do
	if isfile and readfile and isfile(CONFIG_FILE) then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if ok and type(decoded) == "table" then
			if type(decoded.flags) == "table" then
				savedFlags = decoded.flags
			end
			if type(decoded.combat) == "table" then
				for k, v in pairs(decoded.combat) do
					if combat[k] ~= nil then combat[k] = v end
				end
			end
		end
	end
end

local function saveConfig()
	if not writefile then return end
	pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode({ flags = Flags, combat = combat }))
	end)
end

-- Resolve a flag's starting value from saved config, else fallback.
local function initFlag(flag, fallback)
	local v = savedFlags[flag]
	if v == nil then v = fallback end
	Flags[flag] = v
	return v
end

--============================================================================
-- Theme + low-level UI helpers
--============================================================================
local Theme = {
	bg      = Color3.fromRGB(22, 22, 28),
	bg2     = Color3.fromRGB(30, 30, 38),
	bg3     = Color3.fromRGB(42, 42, 54),
	bg4     = Color3.fromRGB(54, 54, 68),
	accent  = Color3.fromRGB(147, 97, 245),
	text    = Color3.fromRGB(236, 236, 242),
	subtext = Color3.fromRGB(158, 158, 176),
	good    = Color3.fromRGB(86, 214, 122),
	bad     = Color3.fromRGB(228, 82, 96),
	stroke  = Color3.fromRGB(60, 60, 74),
}

local function new(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = inst end
	end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(inst, r)
	new("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = inst })
	return inst
end

local function stroke(inst, col, th)
	new("UIStroke", { Color = col or Theme.stroke, Thickness = th or 1, Parent = inst })
	return inst
end

local function listLayout(parent, padding, dir)
	return new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

--============================================================================
-- Root ScreenGui
--============================================================================
-- Clean up a previous instance if re-executed.
for _, name in ipairs({ "JJSHubGui", "JJSHubNotifs" }) do
	local existing = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild(name)
	if existing then existing:Destroy() end
end

local guiParent
do
	local ok = pcall(function()
		local target = gethui and gethui() or game:GetService("CoreGui")
		guiParent = target
	end)
	if not ok or not guiParent then
		guiParent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

local screen = new("ScreenGui", {
	Name = "JJSHubGui",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	Parent = guiParent,
})

--============================================================================
-- Notifications
--============================================================================
local notifGui = new("ScreenGui", {
	Name = "JJSHubNotifs",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = guiParent,
})
local notifHolder = new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -14, 1, -14),
	Size = UDim2.new(0, 300, 1, -28),
	BackgroundTransparency = 1,
	Parent = notifGui,
})
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = notifHolder,
})

local function notify(title, message, duration)
	duration = duration or 4
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Theme.bg2,
		BackgroundTransparency = 1,
		Parent = notifHolder,
	})
	corner(card, 8)
	stroke(card, Theme.accent, 1)
	new("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0, Parent = card })
	new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -22, 0, 18),
		BackgroundTransparency = 1, Text = title, TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold,
		TextSize = 14, Parent = card,
	})
	new("TextLabel", {
		Position = UDim2.new(0, 14, 0, 28), Size = UDim2.new(1, -22, 0, 20),
		BackgroundTransparency = 1, Text = message, TextColor3 = Theme.subtext,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, Parent = card,
	})
	TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
	task.delay(duration, function()
		if card and card.Parent then
			local t = TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
			t:Play()
			t.Completed:Once(function() card:Destroy() end)
		end
	end)
end

--============================================================================
-- Keybind dispatch
--============================================================================
local keybinds = {}  -- flag -> { key = Enum.KeyCode, press = function }

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	for _, kb in pairs(keybinds) do
		if kb.key and input.KeyCode == kb.key and kb.press then
			kb.press()
		end
	end
end)

--============================================================================
-- UI Library
--============================================================================
local Library = {}

local mainWindow  -- forward ref for dragging util
local function makeDraggable(handle, target)
	local dragging, dragInput, startInput, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

function Library.CreateWindow(titleText)
	local window = { tabs = {}, activeTab = nil }

	local root = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(660, 460),
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
		Parent = screen,
	})
	corner(root, 10)
	stroke(root, Theme.stroke, 1)
	mainWindow = root

	-- Responsive scaling: shrink the 660x460 window so it fits phone screens.
	local uiScale = new("UIScale", { Parent = root })
	local function updateScale()
		local cam = getCamera()
		local vp = (cam and cam.ViewportSize) or Vector2.new(800, 600)
		local s = math.min(1, (vp.X * 0.96) / 660, (vp.Y * 0.94) / 460)
		uiScale.Scale = math.clamp(s, 0.45, 1)
	end
	updateScale()
	do
		local cam = getCamera()
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
		-- Re-hook the camera on respawn (CurrentCamera gets replaced).
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			local c = getCamera()
			if c then c:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
			updateScale()
		end)
	end

	-- Top bar
	local top = new("Frame", {
		Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.bg2,
		BorderSizePixel = 0, Parent = root,
	})
	corner(top, 10)
	new("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.bg2, BorderSizePixel = 0, Parent = top })

	-- Gojo logo button (top-left). Add your own decal IDs to GOJO_IMAGES for a
	-- real picture; otherwise it shows a random Gojo-themed glyph. Click = re-roll.
	local GOJO_IMAGES = {
		-- "rbxassetid://<your gojo decal id>",
	}
	local GOJO_GLYPHS = { "🕶️", "👁️", "🌀", "💙", "六", "∞" }
	local GOJO_QUOTES = {
		"Nah, I'd win.", "Throughout heaven and earth, I alone am the honored one.",
		"You're weak. Wanna know why?", "Are you the strongest because…",
		"…you're Gojo Satoru, or are you Gojo Satoru because you're the strongest?",
		"Domain Expansion: Unlimited Void.", "With this treasure, I summon…",
	}
	local logo = new("ImageButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.accent,
		AutoButtonColor = false, Image = "", Parent = top,
	})
	corner(logo, 14); stroke(logo, Color3.fromRGB(120, 200, 255), 1)
	local logoGlyph = new("TextLabel", { Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "🕶️", TextColor3 = Theme.text,
		Font = Enum.Font.GothamBold, TextSize = 15, Parent = logo })
	local function rollGojo()
		if #GOJO_IMAGES > 0 then
			logo.Image = GOJO_IMAGES[math.random(1, #GOJO_IMAGES)]
			logoGlyph.Text = ""
		else
			logo.Image = ""
			logoGlyph.Text = GOJO_GLYPHS[math.random(1, #GOJO_GLYPHS)]
		end
	end
	rollGojo()
	logo.MouseButton1Click:Connect(function()
		rollGojo()
		notify("Gojo", GOJO_QUOTES[math.random(1, #GOJO_QUOTES)], 3)
	end)

	new("TextLabel", {
		Position = UDim2.new(0, 48, 0, 0), Size = UDim2.new(1, -150, 1, 0),
		BackgroundTransparency = 1, Text = titleText, TextColor3 = Theme.text,
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold,
		TextSize = 16, Parent = top,
	})
	makeDraggable(top, root)

	local minBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0),
		Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.bg3, Text = "–",
		TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 18, Parent = top,
	})
	corner(minBtn, 6)
	local closeBtn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.bad, Text = "✕",
		TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 13, Parent = top,
	})
	corner(closeBtn, 6)

	-- Sidebar
	local sidebar = new("Frame", {
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(0, 156, 1, -40),
		BackgroundColor3 = Theme.bg2, BorderSizePixel = 0, Parent = root,
	})
	local sideList = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.bg4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		Parent = sidebar,
	})
	listLayout(sideList, 4)
	new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8), Parent = sideList })

	-- Content
	local content = new("Frame", {
		Position = UDim2.new(0, 156, 0, 40), Size = UDim2.new(1, -156, 1, -40),
		BackgroundTransparency = 1, Parent = root,
	})

	-- Minimize / reopen (floating pill)
	local reopen = new("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Theme.accent, Text = "JJS",
		TextColor3 = Theme.text, Font = Enum.Font.GothamBold, TextSize = 15,
		Visible = false, Parent = screen,
	})
	corner(reopen, 26)
	makeDraggable(reopen, reopen)
	minBtn.MouseButton1Click:Connect(function()
		root.Visible = false; reopen.Visible = true
	end)
	reopen.MouseButton1Click:Connect(function()
		root.Visible = true; reopen.Visible = false
	end)
	closeBtn.MouseButton1Click:Connect(function()
		notify("JJS Hub", "Unloaded. Re-execute to reopen.", 3)
		task.wait(0.1)
		screen:Destroy(); notifGui:Destroy()
	end)

	window.root, window.reopen = root, reopen

	function window:SetVisible(v)
		root.Visible = v
		if v then reopen.Visible = false end
	end
	function window:Toggle()
		root.Visible = not root.Visible
		if root.Visible then reopen.Visible = false end
	end

	-- Tab factory
	function window:AddTab(name, icon)
		local tab = {}

		local btn = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.bg3,
			BackgroundTransparency = 1, Text = (icon and (icon .. "  ") or "") .. name,
			TextColor3 = Theme.subtext, TextXAlignment = Enum.TextXAlignment.Left,
			Font = Enum.Font.GothamMedium, TextSize = 13, Parent = sideList,
		})
		corner(btn, 6)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), Parent = btn })

		local page = new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.bg4,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
			Visible = false, Parent = content,
		})
		listLayout(page, 10)
		new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
			PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = page })

		tab.button, tab.page = btn, page

		local function activate()
			for _, t in ipairs(window.tabs) do
				t.page.Visible = false
				t.button.BackgroundTransparency = 1
				t.button.TextColor3 = Theme.subtext
			end
			page.Visible = true
			btn.BackgroundTransparency = 0
			btn.BackgroundColor3 = Theme.bg3
			btn.TextColor3 = Theme.text
			window.activeTab = tab
		end
		btn.MouseButton1Click:Connect(activate)

		-- Section factory
		function tab:AddSection(sectionName)
			local section = {}
			local holder = new("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.bg2, BorderSizePixel = 0, Parent = page,
			})
			corner(holder, 8)
			stroke(holder, Theme.stroke, 1)
			new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = holder })
			local inner = new("Frame", { Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = holder })
			listLayout(inner, 8)
			new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = sectionName,
				TextColor3 = Theme.accent, TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamBold, TextSize = 14, LayoutOrder = 0, Parent = inner,
			})

			local order = 1
			local function nextOrder() order += 1; return order end

			local function rowBase(height)
				return new("Frame", {
					Size = UDim2.new(1, 0, 0, height or 30), BackgroundTransparency = 1,
					LayoutOrder = nextOrder(), Parent = inner,
				})
			end

			function section:Label(text)
				local r = rowBase(20)
				new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.subtext, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, Parent = r })
				return section
			end

			-- Blank auto-laid-out row the caller can populate directly.
			function section:Row(height)
				return rowBase(height)
			end

			function section:Button(text, cb)
				local r = rowBase(32)
				local b = new("TextButton", { Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Theme.bg3, Text = text, TextColor3 = Theme.text,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				corner(b, 6); stroke(b, Theme.stroke, 1)
				b.MouseButton1Click:Connect(function()
					local ok, err = pcall(cb)
					if not ok then notify("Error", tostring(err), 5) end
				end)
				return section
			end

			function section:Toggle(text, flag, default, cb)
				local value = initFlag(flag, default)
				local r = rowBase(30)
				new("TextLabel", { Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				local track = new("TextButton", {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.fromOffset(46, 24), Text = "",
					BackgroundColor3 = value and Theme.accent or Theme.bg4, Parent = r })
				corner(track, 12)
				local knob = new("Frame", {
					AnchorPoint = Vector2.new(value and 1 or 0, 0.5),
					Position = UDim2.new(value and 1 or 0, value and -2 or 2, 0.5, 0),
					Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.text, Parent = track })
				corner(knob, 9)
				local function apply(v, fireCb)
					Flags[flag] = v
					TweenService:Create(track, TweenInfo.new(0.15),
						{ BackgroundColor3 = v and Theme.accent or Theme.bg4 }):Play()
					TweenService:Create(knob, TweenInfo.new(0.15), {
						AnchorPoint = Vector2.new(v and 1 or 0, 0.5),
						Position = UDim2.new(v and 1 or 0, v and -2 or 2, 0.5, 0) }):Play()
					if fireCb and cb then
						local ok, err = pcall(cb, v)
						if not ok then notify("Error", tostring(err), 5) end
					end
				end
				track.MouseButton1Click:Connect(function()
					apply(not Flags[flag], true); saveConfig()
				end)
				if cb then pcall(cb, value) end   -- apply loaded state on build
				return section
			end

			function section:Slider(text, flag, minV, maxV, default, cb, decimals)
				local value = initFlag(flag, default)
				decimals = decimals or 0
				local r = rowBase(46)
				new("TextLabel", { Size = UDim2.new(1, -60, 0, 18), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				local valLabel = new("TextLabel", {
					AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.fromOffset(60, 18), BackgroundTransparency = 1,
					Text = tostring(value), TextColor3 = Theme.accent,
					TextXAlignment = Enum.TextXAlignment.Right, Font = Enum.Font.GothamBold,
					TextSize = 13, Parent = r })
				local bar = new("Frame", { Position = UDim2.new(0, 0, 0, 28),
					Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.bg4, Parent = r })
				corner(bar, 4)
				local fill = new("Frame", {
					Size = UDim2.new((value - minV) / (maxV - minV), 0, 1, 0),
					BackgroundColor3 = Theme.accent, Parent = bar })
				corner(fill, 4)

				local function round(n)
					local m = 10 ^ decimals
					return math.floor(n * m + 0.5) / m
				end
				local dragging = false
				local function setFromX(px)
					local rel = math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					local v = round(minV + (maxV - minV) * rel)
					Flags[flag] = v
					valLabel.Text = tostring(v)
					fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
					if cb then pcall(cb, v) end
				end
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true; setFromX(input.Position.X)
					end
				end)
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						if dragging then dragging = false; saveConfig() end
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch) then
						setFromX(input.Position.X)
					end
				end)
				if cb then pcall(cb, value) end
				return section
			end

			function section:Dropdown(text, flag, options, default, cb)
				local value = initFlag(flag, default)
				local r = rowBase(52)
				new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				local btn = new("TextButton", { Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.bg3,
					Text = tostring(value), TextColor3 = Theme.text, Font = Enum.Font.GothamMedium,
					TextSize = 13, Parent = r })
				corner(btn, 6); stroke(btn, Theme.stroke, 1)
				btn.MouseButton1Click:Connect(function()
					-- cycle through options
					local idx = 1
					for i, opt in ipairs(options) do if opt == Flags[flag] then idx = i break end end
					idx = (idx % #options) + 1
					Flags[flag] = options[idx]
					btn.Text = tostring(options[idx])
					if cb then pcall(cb, options[idx]) end
					saveConfig()
				end)
				if cb then pcall(cb, value) end
				return section
			end

			function section:Textbox(text, flag, default, cb, numeric)
				local value = initFlag(flag, default)
				local r = rowBase(52)
				new("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				local box = new("TextBox", { Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Theme.bg3,
					Text = tostring(value), TextColor3 = Theme.text, ClearTextOnFocus = false,
					Font = Enum.Font.Gotham, TextSize = 13, Parent = r })
				corner(box, 6); stroke(box, Theme.stroke, 1)
				box.FocusLost:Connect(function()
					if numeric then
						local n = tonumber(box.Text)
						if n then
							Flags[flag] = n; box.Text = tostring(n)
							if cb then pcall(cb, n) end
						else
							box.Text = tostring(Flags[flag])
						end
					else
						Flags[flag] = box.Text
						if cb then pcall(cb, box.Text) end
					end
					saveConfig()
				end)
				return section
			end

			function section:Keybind(text, flag, defaultKey, onPress)
				local saved = savedFlags[flag]
				local key = defaultKey
				if type(saved) == "string" and Enum.KeyCode[saved] then key = Enum.KeyCode[saved] end
				Flags[flag] = key and key.Name or "None"
				local r = rowBase(30)
				new("TextLabel", { Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
					Text = text, TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.GothamMedium, TextSize = 13, Parent = r })
				local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(100, 24),
					BackgroundColor3 = Theme.bg3, Text = key and key.Name or "None",
					TextColor3 = Theme.text, Font = Enum.Font.GothamMedium, TextSize = 12, Parent = r })
				corner(btn, 6); stroke(btn, Theme.stroke, 1)
				keybinds[flag] = { key = key, press = onPress }
				btn.MouseButton1Click:Connect(function()
					btn.Text = "..."
					local conn
					conn = UserInputService.InputBegan:Connect(function(input, gp)
						if gp then return end
						if input.UserInputType == Enum.UserInputType.Keyboard then
							keybinds[flag].key = input.KeyCode
							Flags[flag] = input.KeyCode.Name
							btn.Text = input.KeyCode.Name
							saveConfig()
							conn:Disconnect()
						end
					end)
				end)
				return section
			end

			return section
		end

		table.insert(window.tabs, tab)
		if #window.tabs == 1 then activate() end
		return tab
	end

	return window
end

--============================================================================
-- Ability-service remote list (mined from the game's remote dump: 237 services,
-- each exposing ReplicatedStorage.Knit.Knit.Services.<Service>.RE.<Signal>).
--============================================================================
local SERVICE_LIST = {
		"AbsoluteDestructionService", "AbsoluteService", "AchievementService", "AdaptationService",
		"AggravateService", "AmbushService", "AnkleCutterService", "AntiCheatService",
		"AppetizerService", "BackstabService", "BeamService", "BirdControlService",
		"BlackMucusService", "BleedoutService", "BlockService", "BloodEdgeService",
		"BloodRainService", "BluntCutService", "BluntTraumaService", "BodyDisfigureService",
		"BodyRepelService", "BoostOn2Service", "BoostOnService", "BrothersService",
		"BruteForceService", "BudShotService", "BuildService", "ChaosService",
		"CharlesService", "CheapShotService", "ChokeholdService", "ChosoService",
		"CirclingService", "CleaveRushService", "CleavingWhirlService", "CleverService",
		"ClimaxJumpService", "CollapseService", "CopyService", "CopyWheelService",
		"CouponService", "CrushJawService", "CrushingBlowService", "CrushingRushdownService",
		"CursedBudsService", "CursedStrikesService", "CursoryImpactService", "CustomService",
		"DebreeService", "DebugService", "DecisiveStrike2Service", "DecisiveStrikeService",
		"DefenseResponseService", "DespairService", "DetachService", "DirtyPlayService",
		"DismantleService", "DismantleV2Service", "DivergentFistService", "DivineDogService",
		"DivinePummelService", "DomainService", "DreamsService", "DuelService",
		"EarthquakeService", "ElbowDropService", "ElbowRushService", "EmoteService",
		"EnergyRippleService", "EnergySurgeService", "ExecutionService", "ExtendSwingService",
		"EyeCatchService", "FaceBlitzService", "FesteringStrikesService", "FeverBreakerService",
		"FinalJudgementService", "FinalShowdownService", "FlameArrowService", "FlashFreezingService",
		"FlowerBeamService", "FocusStrikeService", "FurnaceArrowService", "GarageSaleService",
		"GarudaReboundService", "GarudaStabService", "GojoService", "GokuService",
		"GraniteBlastService", "GrappleService", "GreatSerpentService", "GroundPitchService",
		"GushingWoundService", "HadNoIdeaService", "HakariService", "HanamiService",
		"HandicapService", "HarutaService", "HeadSplitterService", "HeatEmissionService",
		"HeianService", "HighTimeService", "HiromiService", "HitboxService",
		"HollowPurpleService", "HomerunService", "IdleTransfigurationService", "IdolDebutService",
		"ImpetusUpdraftService", "InfiniteVoidService", "InterrogateService", "ItadoriService",
		"ItemService", "JoinService", "JudgeReachService", "JusticeServedService",
		"KamehamehaService", "KamutokeService", "KiSpamService", "KurourushiService",
		"LapseBlueMaxService", "LapseBlueService", "LitteringService", "LocustService",
		"LoveBeamService", "LuckyRushdownService", "LuckyVolleyService", "MahitoService",
		"MahoragaService", "MahoragaUseService", "MalevolantShrineService", "ManjiKickService",
		"MassBreakerService", "MaxElephantService", "MechamaruService", "MegumiService",
		"MeiMeiService", "MiracleCannonService", "Mokou1Service", "Mokou2Service",
		"Mokou3Service", "Mokou4Service", "MokouService", "MovementService",
		"MurmurateService", "MutualLoveService", "NanamiService", "NaoyaService",
		"NepService", "NightParadeService", "NueService", "OutburstService",
		"OverLuckService", "PebbleThrowService", "PianoDropService", "PiercingBloodService",
		"PigeonViolaService", "PlasmaWaveService", "PressingChargesService", "ProjectionBreakerService",
		"PuppetBarrageService", "RabbitEscapeService", "RankedService", "RapidPunchesService",
		"RatioBreakerService", "RedScaleService", "ReggieService", "ReserveBallService",
		"ResoluteSlashService", "ResoluteSwingService", "ReversalRedMaxService", "ReversalRedService",
		"RevolveService", "RikaDownslamService", "RikaGrabService", "RikaHaymakerService",
		"RikaLaunchService", "RikaLoveBeamService", "RikaService", "RikaSlamService",
		"RikaSmashService", "RikaThrowService", "RisingRageService", "RoachSwarmService",
		"RootRampageService", "RootSwarmService", "RoughEnergyService", "RouletteService",
		"RushService", "RyuService", "SacrilegiousService", "SeaOfBranchesService",
		"SecondHelpingService", "SecondWindService", "SelfPerfectionService", "SeveranceKickService",
		"SeveringPathService", "ShadowSwarmService", "SharpenService", "ShopService",
		"ShutUpService", "ShutterDoorService", "SlicingExorcismService", "SoulfireService",
		"SpeedCrashService", "SpikeWrathService", "StabilizeService", "StaffExtendService",
		"StaffUppercutService", "StockpileService", "SupernovaService", "SurgingThornsService",
		"SwiftKickService", "TechniqueChargeService", "TendrilGrabService", "ThisDessertService",
		"TimeCellMoonPalaceService", "ToadService", "TodoService", "TopSpeedService",
		"TripService", "TripleSentenceService", "TwofoldKickService", "UltraCannon2Service",
		"UltraCannonService", "UltraSpinService", "UnsatisfiedService", "VeilstepService",
		"VerdictService", "WerentInvitedService", "WhatAreYouAfterService", "WideSPStrikesService",
		"WingKingService", "WingThrowService", "WorkshopService", "YukiService",
		"YutaService",
}

--============================================================================
-- Feature runtime state
--============================================================================
local State = {}

-- Shared across tabs: the ability service currently picked in the Remotes tab.
local selectedService = "ItadoriService"

-- Resolve a Knit service remote signal instance (nil, reason on failure).
local function resolveServiceRemote(serviceName, signalName)
	local knit = ReplicatedStorage:FindFirstChild("Knit")
	local inner = knit and knit:FindFirstChild("Knit")
	local services = inner and inner:FindFirstChild("Services")
	if not services then return nil, "Knit.Services not found" end
	local svc = services:FindFirstChild(serviceName)
	if not svc then return nil, "service not found" end
	local re = svc:FindFirstChild("RE")
	local sig = re and re:FindFirstChild(signalName)
	if not sig then return nil, "signal '" .. tostring(signalName) .. "' not found" end
	return sig
end

-- Fire a service signal (arg-less). Returns ok, errorOrReason.
local function fireSignal(serviceName, signalName)
	local sig, reason = resolveServiceRemote(serviceName, signalName)
	if not sig then return false, reason end
	local ok, err = pcall(function() sig:FireServer() end)
	return ok, err
end

--============================================================================
-- Build the hub
--============================================================================
local Window = Library.CreateWindow("JJS HUB  •  v1")

--------------------------------------------------------------------
-- COMBAT
--------------------------------------------------------------------
do
	local tab  = Window:AddTab("Combat", "⚔")
	local main = tab:AddSection("Main")
	main:Toggle("Master Enabled", "cmb_master", combat.masterEnabled, function(v)
		combat.masterEnabled = v; saveConfig() end)
	main:Toggle("Auto BF Chain", "cmb_bfchain", combat.autoBFChain, function(v)
		combat.autoBFChain = v; saveConfig() end)
	main:Dropdown("BF Chain Mode", "cmb_mode", { "legit", "semi legit" }, combat.bfChainMode,
		function(v) combat.bfChainMode = v; saveConfig() end)
	main:Toggle("Auto Blackflash (Divergent Fist)", "cmb_fist", combat.autoFireFist, function(v)
		combat.autoFireFist = v; saveConfig() end)
	main:Slider("Divergent Fist Delay", "cmb_fistdelay", 0, 2, combat.divergentFistDelay,
		function(v) combat.divergentFistDelay = v; saveConfig() end, 2)
	main:Toggle("Feint", "cmb_feint", combat.feintEnabled, function(v)
		combat.feintEnabled = v; saveConfig() end)
	main:Slider("Feint Delay", "cmb_feintdelay", 0, 2, combat.feintDelay,
		function(v) combat.feintDelay = v; saveConfig() end, 2)
	main:Toggle("Auto Dash on Hit (combo extend)", "cmb_combodash", combat.autoComboDash,
		function(v) combat.autoComboDash = v; saveConfig() end)
	main:Slider("Combo Dash Delay", "cmb_combodashdelay", 0, 1, combat.comboDashDelay,
		function(v) combat.comboDashDelay = v; saveConfig() end, 2)

	local jump = tab:AddSection("Jump")
	jump:Toggle("Auto Jump", "cmb_jump", combat.autoJump, function(v)
		combat.autoJump = v; saveConfig() end)
	jump:Slider("Jump Duration", "cmb_jumpdur", 0, 1, combat.jumpDuration,
		function(v) combat.jumpDuration = v; saveConfig() end, 2)
	jump:Slider("Jump Power", "cmb_jumppow", 0, 200, combat.jumpPower,
		function(v) combat.jumpPower = v; saveConfig() end)

	local aim = tab:AddSection("Aiming")
	aim:Toggle("Auto Aim", "cmb_aim", combat.autoAim, function(v)
		combat.autoAim = v; saveConfig() end)
	aim:Dropdown("Aim Mode", "cmb_aimmode", { "Camera", "Character" }, combat.aimMode,
		function(v) combat.aimMode = v; saveConfig() end)
	aim:Slider("Camera Slowness (0 = instant)", "cmb_camslow", 0, 20, combat.cameraSlowness,
		function(v) combat.cameraSlowness = v; saveConfig() end, 1)
	aim:Slider("Look Time", "cmb_looktime", 0, 3, combat.lookTime,
		function(v) combat.lookTime = v; saveConfig() end, 2)
	aim:Slider("Target Distance (0 = any)", "cmb_maxdist", 0, 500, combat.maxTargetDistance,
		function(v) combat.maxTargetDistance = v; saveConfig() end)

	local legit = tab:AddSection("Legit Tuning")
	legit:Slider("Infront Check", "cmb_infront", 0, 60, combat.legitInfrontCheck,
		function(v) combat.legitInfrontCheck = v; saveConfig() end)
	legit:Slider("Speed", "cmb_legitspeed", 0, 2, combat.legitSpeed,
		function(v) combat.legitSpeed = v; saveConfig() end, 2)
	legit:Slider("Arc Width", "cmb_arc", 0, 20, combat.legitArcWidth,
		function(v) combat.legitArcWidth = v; saveConfig() end, 1)
	legit:Slider("Slowdown Interval", "cmb_sdint", 0, 0.2, combat.legitSlowdownInterval,
		function(v) combat.legitSlowdownInterval = v; saveConfig() end, 3)
	legit:Slider("Slowdown Amount", "cmb_sdamt", 0, 0.2, combat.legitSlowdownAmount,
		function(v) combat.legitSlowdownAmount = v; saveConfig() end, 3)
	legit:Toggle("Behind Check", "cmb_behind", combat.legitBehindCheck, function(v)
		combat.legitBehindCheck = v; saveConfig() end)
	legit:Slider("Behind Check Distance", "cmb_behinddist", 0, 60, combat.legitBehindCheckDist,
		function(v) combat.legitBehindCheckDist = v; saveConfig() end)
	legit:Toggle("Side Check", "cmb_side", combat.legitSideCheck, function(v)
		combat.legitSideCheck = v; saveConfig() end)

	local semi = tab:AddSection("Semi-Legit Tuning")
	semi:Slider("Offset Studs", "cmb_offset", 0, 30, combat.offsetStuds,
		function(v) combat.offsetStuds = v; saveConfig() end)
	semi:Slider("Tween Time", "cmb_tween", 0, 2, combat.tweenTime,
		function(v) combat.tweenTime = v; saveConfig() end, 2)

	----------------------------------------------------------------------
	-- Combo tech sequencer (real Jjs remotes, user-tuned timing)
	----------------------------------------------------------------------
	local combo = tab:AddSection("Combo Tech (sequencer)")
	combo:Label("Runs a sequence of REAL remotes with your timing. Dash/Reset "
		.. "Dash = MovementService, M1/M2 = ItemService, and Activated/"
		.. "RightActivated/Deactivated/Ultimate fire the service picked in the "
		.. "Remotes tab. Exact hitstun frames vary per move — tune each delay.")

	local COMBO_ACTIONS = { "None", "Dash", "Reset Dash", "Item M1", "Item M2",
		"Activated", "RightActivated", "Deactivated", "Ultimate" }

	local function doComboAction(action)
		if action == "Dash" then fireSignal("MovementService", "Dash")
		elseif action == "Reset Dash" then fireSignal("MovementService", "ResetDash")
		elseif action == "Item M1" then fireSignal("ItemService", "M1")
		elseif action == "Item M2" then fireSignal("ItemService", "M2")
		elseif action == "Activated" then fireSignal(selectedService, "Activated")
		elseif action == "RightActivated" then fireSignal(selectedService, "RightActivated")
		elseif action == "Deactivated" then fireSignal(selectedService, "Deactivated")
		elseif action == "Ultimate" then fireSignal(selectedService, "Ultimate")
		end
	end

	local comboRunning = false
	local function runCombo()
		if comboRunning then return end
		comboRunning = true
		for i = 1, 5 do
			local action = Flags["combo_a" .. i]
			if action and action ~= "None" then
				doComboAction(action)
				task.wait(Flags["combo_d" .. i] or 0.1)
			end
		end
		comboRunning = false
	end

	for i = 1, 5 do
		combo:Dropdown("Step " .. i .. " action", "combo_a" .. i, COMBO_ACTIONS, "None",
			function() end)
		combo:Slider("Step " .. i .. " delay (s)", "combo_d" .. i, 0, 1.5, 0.1,
			function() end, 2)
	end

	combo:Button("Run Combo Once", function() task.spawn(runCombo) end)
	combo:Keybind("Run Combo Key", "combo_key", Enum.KeyCode.G, function()
		task.spawn(runCombo)
	end)
	combo:Toggle("Loop Combo", "combo_loop", false, function() end)
	task.spawn(function()
		while true do
			if Flags.combo_loop then
				runCombo()
				task.wait(0.05)
			else
				task.wait(0.2)
			end
		end
	end)

	----------------------------------------------------------------------
	-- Combo presets (one-click routes; scale timing with the speed slider)
	----------------------------------------------------------------------
	local presetSec = tab:AddSection("Combo Presets")
	presetSec:Label("One-click routes built from real remotes. Default delays "
		.. "are starting points — scale them all with Timing Scale, then fine-"
		.. "tune the sequencer above for your character/ping.")
	presetSec:Slider("Timing Scale (x)", "combo_speed", 0.5, 2, 1, function() end, 2)

	-- Reusable runner: steps = { {action, delay}, ... }
	local function runSequence(steps)
		if comboRunning then return end
		comboRunning = true
		for _, step in ipairs(steps) do
			doComboAction(step[1])
			task.wait(step[2] * (Flags.combo_speed or 1))
		end
		comboRunning = false
	end

	-- Common Jjs / battlegrounds tech patterns.
	local COMBO_PRESETS = {
		{ "Dash Cancel x4", {
			{ "Item M1", 0.12 }, { "Dash", 0.12 }, { "Item M1", 0.12 }, { "Dash", 0.12 },
			{ "Item M1", 0.12 }, { "Dash", 0.12 }, { "Item M1", 0.12 }, { "Dash", 0.20 } } },
		{ "Reset Dash Chain", {
			{ "Dash", 0.10 }, { "Reset Dash", 0.05 }, { "Dash", 0.10 },
			{ "Reset Dash", 0.05 }, { "Dash", 0.20 } } },
		{ "Ground Combo (M1s → Move)", {
			{ "Item M1", 0.12 }, { "Item M1", 0.12 }, { "Item M1", 0.15 },
			{ "Activated", 0.25 }, { "Dash", 0.20 } } },
		{ "Move Cancel (Activate → Deact → Dash)", {
			{ "Activated", 0.18 }, { "Deactivated", 0.08 }, { "Dash", 0.20 } } },
		{ "Ult Confirm (Move → Dash → Ult)", {
			{ "Activated", 0.20 }, { "Dash", 0.12 }, { "Ultimate", 0.30 } } },
		{ "Drag Loop (M1 → Dash x2)", {
			{ "Item M1", 0.12 }, { "Dash", 0.12 }, { "Item M1", 0.12 },
			{ "Dash", 0.12 }, { "Item M1", 0.20 } } },
		{ "Full Chain (Right → Dash → Move → Dash → Ult)", {
			{ "RightActivated", 0.20 }, { "Dash", 0.12 }, { "Activated", 0.20 },
			{ "Dash", 0.12 }, { "Ultimate", 0.30 } } },
		{ "Stall / Reset (Deact → Reset Dash → Dash)", {
			{ "Deactivated", 0.10 }, { "Reset Dash", 0.05 }, { "Dash", 0.15 } } },
	}
	for _, preset in ipairs(COMBO_PRESETS) do
		local name, steps = preset[1], preset[2]
		presetSec:Button(name, function()
			task.spawn(function() runSequence(steps) end)
		end)
	end
end

--------------------------------------------------------------------
-- PLAYER
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Player", "🏃")
	local move = tab:AddSection("Movement")
	move:Toggle("WalkSpeed", "spd_on", false, function() end)
	move:Slider("WalkSpeed Value", "spd_val", 16, 300, 16, function() end)
	move:Toggle("JumpPower", "jmp_on", false, function() end)
	move:Slider("JumpPower Value", "jmp_val", 50, 400, 50, function() end)
	move:Toggle("Infinite Jump", "infjump", false, function() end)

	local ab = tab:AddSection("Abilities")
	ab:Toggle("Fly (WASD + Space/Shift)", "fly_on", false, function(v)
		if v then State.startFly and State.startFly() else State.stopFly and State.stopFly() end end)
	ab:Slider("Fly Speed", "fly_speed", 10, 400, 60, function() end)
	ab:Toggle("Noclip", "noclip", false, function() end)
	ab:Toggle("Hitbox Expander", "hitbox_on", false, function() end)
	ab:Slider("Hitbox Size", "hitbox_size", 2, 30, 6, function() end, 1)
	ab:Keybind("Fly Toggle Key", "fly_key", Enum.KeyCode.F, function()
		Flags.fly_on = not Flags.fly_on
		if Flags.fly_on then State.startFly and State.startFly()
		else State.stopFly and State.stopFly() end
		notify("Fly", Flags.fly_on and "Enabled" or "Disabled", 1.5)
	end)
end

--------------------------------------------------------------------
-- VISUALS
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Visuals", "👁")
	local esp = tab:AddSection("ESP")
	esp:Toggle("Enable ESP", "esp_on", false, function() end)
	esp:Toggle("Highlight (box)", "esp_box", true, function() end)
	esp:Toggle("Name", "esp_name", true, function() end)
	esp:Toggle("Distance", "esp_dist", true, function() end)
	esp:Toggle("Health", "esp_health", true, function() end)
	esp:Toggle("Team Check (skip same team)", "esp_team", false, function() end)

	local env = tab:AddSection("Environment")
	env:Toggle("Fullbright", "fullbright", false, function(v)
		if v then
			State._savedLighting = State._savedLighting or {
				b = Lighting.Brightness, c = Lighting.ClockTime,
				fe = Lighting.FogEnd, a = Lighting.Ambient }
			Lighting.Brightness = 2; Lighting.ClockTime = 14
			Lighting.FogEnd = 1e9; Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		elseif State._savedLighting then
			Lighting.Brightness = State._savedLighting.b
			Lighting.ClockTime  = State._savedLighting.c
			Lighting.FogEnd     = State._savedLighting.fe
			Lighting.Ambient    = State._savedLighting.a
		end
	end)
	env:Toggle("No Fog", "nofog", false, function(v)
		if v then Lighting.FogEnd = 1e9; Lighting.FogStart = 1e9 end
	end)
	env:Slider("Field of View", "fov", 30, 120, 70, function(v)
		local cam = getCamera(); if cam then cam.FieldOfView = v end
	end)

	local fx = tab:AddSection("Move Effects (visual)")
	fx:Label("Plays the 'Effects' visual remote of the service selected in the "
		.. "Remotes tab. Off by default; many Effects remotes need args, so "
		.. "results vary by move.")
	fx:Button("Play Effects (selected service)", function()
		local ok, err = fireSignal(selectedService, "Effects")
		notify("Effects", ok and (selectedService .. ".Effects played")
			or ("Fail: " .. tostring(err)), ok and 1.5 or 3)
	end)
	fx:Toggle("Auto Effects Loop", "vfx_auto", false, function() end)
	fx:Slider("Auto Effects Rate (per sec)", "vfx_rate", 1, 20, 4, function() end)
	task.spawn(function()
		while true do
			if Flags.vfx_auto then
				fireSignal(selectedService, "Effects")
				task.wait(1 / math.max(1, Flags.vfx_rate or 4))
			else
				task.wait(0.2)
			end
		end
	end)
end

--------------------------------------------------------------------
-- AUTOMATION
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Automation", "🤖")
	local s = tab:AddSection("Utility")
	s:Toggle("Anti-AFK", "antiafk", true, function() end)
	s:Toggle("Auto Rejoin on Kick/Death", "autorejoin", false, function() end)
	s:Label("Anti-AFK prevents the 20-minute idle disconnect.")
end

--------------------------------------------------------------------
-- TELEPORT
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Teleport", "📍")
	local s = tab:AddSection("Players")
	local nameBox = "tp_target"
	s:Textbox("Target Player (name)", nameBox, "", nil, false)
	local function findPlayer(q)
		q = string.lower(q or "")
		if q == "" then return nil end
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and (string.lower(p.Name):sub(1, #q) == q
				or string.lower(p.DisplayName):sub(1, #q) == q) then return p end
		end
		return nil
	end
	s:Button("Teleport to Player", function()
		local target = findPlayer(Flags[nameBox])
		local hrp = getHRP()
		local thrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if hrp and thrp then hrp.CFrame = thrp.CFrame + Vector3.new(0, 4, 3)
			notify("Teleport", "→ " .. target.Name, 2)
		else notify("Teleport", "Player/target not found", 2.5) end
	end)

	local wp = tab:AddSection("Waypoints")
	wp:Textbox("Waypoint Name", "wp_name", "spot1", nil, false)
	wp:Button("Save Current Position", function()
		local hrp = getHRP(); if not hrp then return end
		State.waypoints = State.waypoints or {}
		State.waypoints[Flags.wp_name or "spot1"] = hrp.CFrame
		notify("Waypoint", "Saved '" .. tostring(Flags.wp_name) .. "'", 2)
	end)
	wp:Button("Teleport to Waypoint", function()
		local hrp = getHRP()
		local cf = State.waypoints and State.waypoints[Flags.wp_name or "spot1"]
		if hrp and cf then hrp.CFrame = cf; notify("Waypoint", "Teleported", 1.5)
		else notify("Waypoint", "Not found", 2) end
	end)
end

--------------------------------------------------------------------
-- SERVER
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Server", "🌐")
	local s = tab:AddSection("Server")
	s:Label("Place: " .. tostring(game.PlaceId) .. "  •  Players: "
		.. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
	s:Button("Rejoin Server", function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
	s:Button("Server Hop (new server)", function()
		local ok, body = pcall(function()
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
				.. "/servers/Public?sortOrder=Asc&limit=100"
			return HttpService:JSONDecode((game.HttpGet and game:HttpGet(url))
				or (http_request and http_request({ Url = url }).Body))
		end)
		if ok and body and body.data then
			for _, srv in ipairs(body.data) do
				if type(srv) == "table" and srv.id ~= game.JobId
					and srv.playing and srv.playing < srv.maxPlayers then
					notify("Server Hop", "Teleporting...", 2)
					TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
					return
				end
			end
		end
		notify("Server Hop", "No server found (executor HTTP needed)", 3)
	end)
	s:Button("Copy Job ID", function()
		if setclipboard then setclipboard(game.JobId); notify("Copied", game.JobId, 2)
		else notify("Clipboard", "setclipboard unavailable", 2.5) end
	end)
end

--------------------------------------------------------------------
-- REMOTES  (fire any of the 237 ability-service move remotes)
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Remotes", "📡")
	local rs  = tab:AddSection("Move / Ability Firer")
	rs:Label("Fire any of the game's 237 ability-service remotes "
		.. "(Knit.Services.<Service>.RE.<Signal>). Most moves use 'Activated'. "
		.. "Server-side checks may require the move equipped; no args are sent.")

	local selected = "ItadoriService"
	local signal   = "Activated"

	-- Search box
	local searchRow = rs:Row(28)
	local searchBox = new("TextBox", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.bg3,
		PlaceholderText = "Search service…", Text = "", TextColor3 = Theme.text,
		ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 13, Parent = searchRow })
	corner(searchBox, 6); stroke(searchBox, Theme.stroke, 1)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = searchBox })

	-- Selected label
	local selRow = rs:Row(20)
	local selLabel = new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = "Selected: " .. selected, TextColor3 = Theme.accent,
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold,
		TextSize = 13, Parent = selRow })

	-- Result list
	local listRow = rs:Row(150)
	local listScroll = new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.bg, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.bg4, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), Parent = listRow })
	corner(listScroll, 6)
	listLayout(listScroll, 2)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = listScroll })

	local function rebuildList(query)
		for _, c in ipairs(listScroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		query = string.lower(query or "")
		local count = 0
		for _, svc in ipairs(SERVICE_LIST) do
			if query == "" or string.find(string.lower(svc), query, 1, true) then
				count += 1
				if count > 80 then break end
				local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 24),
					BackgroundColor3 = Theme.bg3, Text = svc, TextColor3 = Theme.text,
					TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham,
					TextSize = 12, Parent = listScroll })
				corner(b, 4)
				new("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = b })
				b.MouseButton1Click:Connect(function()
					selected = svc
					selectedService = svc
					selLabel.Text = "Selected: " .. svc
				end)
			end
		end
	end
	searchBox:GetPropertyChangedSignal("Text"):Connect(function() rebuildList(searchBox.Text) end)
	rebuildList("")

	rs:Dropdown("Signal", "rmt_signal",
		{ "Activated", "RightActivated", "Ultimate", "Dash", "Deactivated", "Effects", "Hitbox" },
		"Activated", function(v) signal = v end)

	rs:Button("Fire Once", function()
		local sig, reason = resolveServiceRemote(selected, signal)
		if sig then
			local ok, err = pcall(function() sig:FireServer() end)
			if ok then notify("Remote", "Fired " .. selected .. "." .. signal, 1.5)
			else notify("Remote", "Error: " .. tostring(err), 3) end
		else
			notify("Remote", tostring(reason), 3)
		end
	end)

	local auto = tab:AddSection("Auto-Fire")
	auto:Toggle("Auto-Fire Selected Remote", "rmt_auto", false, function() end)
	auto:Slider("Rate (per second)", "rmt_rate", 1, 30, 5, function() end)
	auto:Label("⚠ Spamming move remotes is very detectable by AntiCheat.")

	-- Auto-fire loop
	task.spawn(function()
		while true do
			if Flags.rmt_auto then
				local sig = resolveServiceRemote(selected, signal)
				if sig then pcall(function() sig:FireServer() end) end
				task.wait(1 / math.max(1, Flags.rmt_rate or 5))
			else
				task.wait(0.2)
			end
		end
	end)

	-- Quick one-click signals on the currently selected service
	local quick = tab:AddSection("Quick Signals (selected service)")
	quick:Label("Fires the chosen signal on whatever service is selected above.")
	local function quickBtn(label, sigName)
		quick:Button(label, function()
			local ok, err = fireSignal(selected, sigName)
			notify("Remote", ok and (selected .. "." .. sigName .. " fired")
				or ("Fail: " .. tostring(err)), ok and 1.5 or 3)
		end)
	end
	quickBtn("Fire Activated", "Activated")
	quickBtn("Fire RightActivated", "RightActivated")
	quickBtn("Fire Ultimate", "Ultimate")
	quickBtn("Fire Deactivated", "Deactivated")

	-- Effects (visual) — opt-in
	local fx = tab:AddSection("Effects (visual) — optional")
	fx:Label("Fires the selected service's 'Effects' visual remote. Off by "
		.. "default; most Effects remotes need args, so results vary.")
	fx:Button("Fire Effects (selected service)", function()
		local ok, err = fireSignal(selected, "Effects")
		notify("Effects", ok and (selected .. ".Effects fired")
			or ("Fail: " .. tostring(err)), ok and 1.5 or 3)
	end)
	fx:Toggle("Auto Effects Loop", "fx_auto", false, function() end)
	fx:Slider("Auto Effects Rate (per sec)", "fx_rate", 1, 20, 4, function() end)
	task.spawn(function()
		while true do
			if Flags.fx_auto then
				fireSignal(selected, "Effects")
				task.wait(1 / math.max(1, Flags.fx_rate or 4))
			else
				task.wait(0.2)
			end
		end
	end)

	-- Movement (MovementService)
	local mv = tab:AddSection("Movement")
	mv:Button("Dash", function() fireSignal("MovementService", "Dash") end)
	mv:Button("Reset Dash (cooldown)", function() fireSignal("MovementService", "ResetDash") end)
	mv:Button("Parkour", function() fireSignal("MovementService", "Parkour") end)
	mv:Toggle("Auto Dash", "mv_autodash", false, function() end)
	mv:Slider("Auto Dash Rate (per sec)", "mv_dashrate", 1, 15, 3, function() end)
	task.spawn(function()
		while true do
			if Flags.mv_autodash then
				fireSignal("MovementService", "Dash")
				task.wait(1 / math.max(1, Flags.mv_dashrate or 3))
			else
				task.wait(0.2)
			end
		end
	end)

	-- Items (ItemService)
	local it = tab:AddSection("Items")
	it:Button("Item M1", function() fireSignal("ItemService", "M1") end)
	it:Button("Item M2", function() fireSignal("ItemService", "M2") end)
	it:Button("Item Dash", function() fireSignal("ItemService", "Dash") end)
	it:Toggle("Auto Item M1", "it_autom1", false, function() end)
	it:Slider("Auto M1 Rate (per sec)", "it_m1rate", 1, 15, 5, function() end)
	task.spawn(function()
		while true do
			if Flags.it_autom1 then
				fireSignal("ItemService", "M1")
				task.wait(1 / math.max(1, Flags.it_m1rate or 5))
			else
				task.wait(0.2)
			end
		end
	end)

	-- Rewards / misc
	local rw = tab:AddSection("Rewards / Misc")
	rw:Button("Claim Daily", function()
		local ok = fireSignal("AchievementService", "Daily")
		notify("Rewards", ok and "Daily requested" or "Failed", 2)
	end)
	rw:Button("Claim Weekly", function() fireSignal("AchievementService", "Weekly") end)
	rw:Button("Request Achievements", function() fireSignal("AchievementService", "Request") end)
	rw:Label("Reward/emote remotes often need arguments; if nothing happens the "
		.. "server rejected the arg-less call.")
end

--------------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------------
do
	local tab = Window:AddTab("Settings", "⚙")
	local s = tab:AddSection("Interface")
	s:Keybind("Toggle UI", "ui_toggle", Enum.KeyCode.RightControl, function()
		Window:Toggle()
	end)
	s:Button("Save Config", function() saveConfig(); notify("Config", "Saved", 2) end)
	s:Button("Reset Config (rejoin to apply)", function()
		if delfile and isfile and isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
		notify("Config", "Reset. Rejoin/re-execute to apply defaults.", 4)
	end)
	local about = tab:AddSection("About")
	about:Label("JJS Hub — combat uses verified game remotes; Player/Visuals/"
		.. "Automation/Teleport/Server are universal client tech.")
	about:Label("⚠ This game has AntiCheat. Movement features can be detected. "
		.. "Automation violates ToS and risks bans. Use at your own risk.")
end

--============================================================================
-- Universal feature runtime
--============================================================================

-- Continuous character features
RunService.Heartbeat:Connect(function()
	local hum, hrp = getHum(), getHRP()
	if hum then
		if Flags.spd_on then hum.WalkSpeed = Flags.spd_val or 16 end
		if Flags.jmp_on then hum.UseJumpPower = true; hum.JumpPower = Flags.jmp_val or 50 end
	end
	if hrp and Flags.hitbox_on then
		local sz = Flags.hitbox_size or 6
		hrp.Size = Vector3.new(sz, sz, sz)
		hrp.Transparency = 0.7
		hrp.CanCollide = false
	end
end)

-- Noclip
RunService.Stepped:Connect(function()
	if not Flags.noclip then return end
	local char = getChar(); if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
	end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
	if Flags.infjump then
		local hum = getHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- Fly
function State.startFly()
	local hrp, hum = getHRP(), getHum()
	if not hrp then return end
	State.stopFly()
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * 9e9; bv.Velocity = Vector3.zero; bv.Parent = hrp
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(1, 1, 1) * 9e9; bg.P = 9e4; bg.CFrame = hrp.CFrame; bg.Parent = hrp
	State.flyBV, State.flyBG = bv, bg
	if hum then hum.PlatformStand = true end
	State.flyConn = RunService.RenderStepped:Connect(function()
		if not State.flyBV then return end
		local cam = getCamera()
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
		State.flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * (Flags.fly_speed or 60)
		State.flyBG.CFrame = cam.CFrame
	end)
end
function State.stopFly()
	if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
	if State.flyBV then State.flyBV:Destroy(); State.flyBV = nil end
	if State.flyBG then State.flyBG:Destroy(); State.flyBG = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
	if not Flags.antiafk then return end
	local ok, vu = pcall(function() return game:GetService("VirtualUser") end)
	if ok and vu then
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end
end)

-- Auto rejoin on death
Players.LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.Died:Connect(function()
			if Flags.autorejoin then
				task.wait(1)
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
	end
end)

--============================================================================
-- ESP
--============================================================================
local espCache = {}  -- player -> { highlight, billboard, nameLbl, infoLbl }

local function clearEsp(plr)
	local e = espCache[plr]
	if e then
		if e.highlight then e.highlight:Destroy() end
		if e.billboard then e.billboard:Destroy() end
		espCache[plr] = nil
	end
end

local function ensureEsp(plr)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not head then return nil end
	local e = espCache[plr]
	if e and e.highlight and e.highlight.Parent then return e end
	clearEsp(plr)
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.6; hl.OutlineTransparency = 0
	hl.FillColor = Theme.accent; hl.OutlineColor = Color3.new(1, 1, 1)
	hl.Adornee = char; hl.Parent = screen
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 34); bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.AlwaysOnTop = true; bb.Adornee = head; bb.Parent = screen
	local nameLbl = new("TextLabel", { Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1, TextColor3 = Theme.text, Font = Enum.Font.GothamBold,
		TextSize = 13, TextStrokeTransparency = 0.4, Parent = bb })
	local infoLbl = new("TextLabel", { Position = UDim2.new(0, 0, 0, 16),
		Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, TextColor3 = Theme.subtext,
		Font = Enum.Font.Gotham, TextSize = 11, TextStrokeTransparency = 0.5, Parent = bb })
	e = { highlight = hl, billboard = bb, nameLbl = nameLbl, infoLbl = infoLbl }
	espCache[plr] = e
	return e
end

RunService.RenderStepped:Connect(function()
	if not Flags.esp_on then
		if next(espCache) then for plr in pairs(espCache) do clearEsp(plr) end end
		return
	end
	local myHRP = getHRP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local skip = false
			if Flags.esp_team and plr.Team and plr.Team == LocalPlayer.Team then skip = true end
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if skip or not hum or not hrp or hum.Health <= 0 then
				clearEsp(plr)
			else
				local e = ensureEsp(plr)
				if e then
					e.highlight.Enabled = Flags.esp_box
					local nameTxt = Flags.esp_name and plr.DisplayName or ""
					e.nameLbl.Text = nameTxt
					local parts = {}
					if Flags.esp_health then table.insert(parts, "HP " .. math.floor(hum.Health)) end
					if Flags.esp_dist and myHRP then
						table.insert(parts, math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m")
					end
					e.infoLbl.Text = table.concat(parts, "  |  ")
					e.billboard.Enabled = (nameTxt ~= "" or #parts > 0)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(clearEsp)

--============================================================================
-- COMBAT engine (verified Knit remotes) — ported from the original script
--============================================================================
local character, humanoid, rootPart, animator, animConnection
local reactionCounter = 0
local aimTarget, lastCamRotation

local REACT_ANIMATION_IDS = {
	["100962226150441"] = true, ["74145636023952"] = true,
	["123171106092050"] = true, ["95852624447551"] = true,
}

RunService:BindToRenderStep("JJSHubAimFix", Enum.RenderPriority.Camera.Value + 1, function()
	if not aimTarget then lastCamRotation = nil; return end
	local cam = getCamera(); if not cam then return end
	local camPos  = cam.CFrame.Position
	local desired = CFrame.new(camPos, aimTarget)
	if combat.cameraSlowness <= 0 then
		cam.CFrame = desired; lastCamRotation = desired.Rotation
	else
		local current = (lastCamRotation and (CFrame.new(camPos) * lastCamRotation)) or cam.CFrame
		local alpha   = 1 / ((combat.cameraSlowness * 3) + 1)
		local result  = current:Lerp(desired, math.clamp(alpha, 0, 1))
		cam.CFrame = result; lastCamRotation = result.Rotation
	end
end)

local function releaseCamera()
	if not aimTarget then return end
	local target = aimTarget
	aimTarget, lastCamRotation = nil, nil
	local cam = getCamera()
	if cam then
		local final = CFrame.new(cam.CFrame.Position, target)
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = final
		task.defer(function() cam.CameraType = Enum.CameraType.Custom end)
	end
end

local function extractAnimationId(anim)
	if not anim then return "" end
	local t = tostring(anim); return t:match("%d+") or t
end

local function getNearestEnemy()
	if not character or not rootPart then return nil end
	local nearest, nearestDist = nil, math.huge
	local origin, maxDist = rootPart.Position, combat.maxTargetDistance or 0
	for _, model in ipairs(workspace:GetDescendants()) do
		if model:IsA("Model") and model ~= character then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local d = (hrp.Position - origin).Magnitude
				if d < nearestDist and (maxDist <= 0 or d <= maxDist) then
					nearestDist, nearest = d, hrp
				end
			end
		end
	end
	return nearest
end

local function onAnimationPlayed(track)
	if not combat.masterEnabled then return end
	local animId = extractAnimationId(track.Animation and track.Animation.AnimationId)
	if not REACT_ANIMATION_IDS[animId] then return end
	reactionCounter += 1
	local myReaction = reactionCounter

	-- Feint
	if combat.feintEnabled then
		task.spawn(function()
			task.wait(combat.feintDelay)
			if character and rootPart then
				local enemy = getNearestEnemy()
				if enemy then
					local toMe = rootPart.Position - enemy.Position
					if enemy.CFrame.LookVector:Dot(toMe.Unit) >= 0 then
						pcall(function()
							ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit")
								:WaitForChild("Services"):WaitForChild("ItadoriService")
								:WaitForChild("RE"):WaitForChild("RightActivated"):FireServer()
						end)
					end
				end
			end
		end)
	end

	-- Auto jump
	if combat.autoJump and rootPart then
		task.spawn(function()
			local deadline = os.clock() + combat.jumpDuration
			while os.clock() < deadline and combat.autoJump and rootPart and rootPart.Parent do
				pcall(function()
					local v = rootPart.AssemblyLinearVelocity
					rootPart.AssemblyLinearVelocity = Vector3.new(v.X, combat.jumpPower, v.Z)
				end)
				RunService.Heartbeat:Wait()
			end
		end)
	end

	-- Auto divergent fist
	if combat.autoFireFist then
		task.spawn(function()
			task.wait(combat.divergentFistDelay)
			pcall(function()
				local char = LocalPlayer.Character
				local moveset = char and char:FindFirstChild("Moveset")
				if moveset then
					local fist = moveset:FindFirstChild("Divergent Fist")
					if fist then
						ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit")
							:WaitForChild("Services"):WaitForChild("DivergentFistService")
							:WaitForChild("RE"):WaitForChild("Activated"):FireServer(fist)
					end
				end
			end)
		end)
	end

	-- Combo extend: dash toward target shortly after the hit
	if combat.autoComboDash then
		task.spawn(function()
			task.wait(combat.comboDashDelay)
			fireSignal("MovementService", "Dash")
		end)
	end

	-- Chain + aim
	if combat.autoBFChain or combat.autoAim then
		task.spawn(function()
			local startTime = os.clock()
			local startPos  = rootPart.Position
			local mode      = "normal"
			local enemy     = getNearestEnemy()

			if combat.autoBFChain and combat.bfChainMode == "legit"
				and combat.legitSideCheck and enemy then
				local toMe = startPos - enemy.Position
				if math.abs(enemy.CFrame.LookVector:Dot(toMe.Unit)) < 0.8 then
					local objSpace = rootPart.CFrame:VectorToObjectSpace(enemy.CFrame.LookVector)
					mode = (objSpace.X > 0) and "270_right" or "270_left"
				end
			end

			if mode == "normal" and combat.autoBFChain and combat.bfChainMode == "legit"
				and combat.legitBehindCheck and enemy then
				local toMe = startPos - enemy.Position
				if toMe.Magnitude <= combat.legitBehindCheckDist
					and enemy.CFrame.LookVector:Dot(toMe.Unit) < 0 then
					if math.random(1, 2) == 1 then
						local objSpace = enemy.CFrame:PointToObjectSpace(startPos)
						mode = (objSpace.X < 0) and "360_left" or "360_right"
					else
						mode = "nothing"
					end
				end
			end

			if mode == "nothing" then releaseCamera(); return end

			local isSpin = (mode == "360_left") or (mode == "360_right")
				or (mode == "270_left") or (mode == "270_right")
			local extraSpeed, slowdownStarted, slowdownAnchor, lastProgress = 0, false, 0, 0

			while true do
				local duration = (combat.bfChainMode == "legit" and combat.autoBFChain
					and (combat.legitSpeed + extraSpeed)) or combat.tweenTime
				local totalTime = duration + combat.lookTime
				local elapsed   = os.clock() - startTime
				if elapsed >= totalTime then break end
				if myReaction ~= reactionCounter or not character.Parent or not rootPart.Parent then
					releaseCamera(); return
				end

				local enemyNow = getNearestEnemy()
				if enemyNow then
					local enemyPos = enemyNow.Position
					local doChain  = combat.autoBFChain
					local lookAt   = enemyPos

					if doChain and combat.bfChainMode == "legit" and not isSpin then
						local delta = enemyPos - startPos
						local dist  = delta.Magnitude
						if dist > 0.1 then
							local dot = rootPart.CFrame.LookVector:Dot(delta.Unit)
							if dist > combat.legitInfrontCheck or dot < 0.4 then doChain = false end
						else
							doChain = false
						end
					end

					if doChain and combat.bfChainMode == "legit" then
						if isSpin then
							lookAt = enemyPos
						else
							local arc  = combat.legitArcWidth
							local d    = startPos - enemyPos
							local ang  = math.atan2(d.Z, d.X)
							local perp = ang + (math.pi * 0.5)
							lookAt = Vector3.new(enemyPos.X + math.cos(perp) * arc, startPos.Y,
								enemyPos.Z + math.sin(perp) * arc)
						end
					end

					if doChain then
						if elapsed < duration then
							local progress = math.clamp(elapsed / duration, 0, 1)
							local newPos, yLock
							if combat.autoJump then yLock = rootPart.Position.Y end

							if combat.bfChainMode == "semi legit" then
								local behind = enemyPos - (enemyNow.CFrame.LookVector * combat.offsetStuds)
								local radius = math.max(combat.offsetStuds, 2)
								local dStart = startPos - enemyPos
								local dEnd   = behind - enemyPos
								local a0, a1 = math.atan2(dStart.Z, dStart.X), math.atan2(dEnd.Z, dEnd.X)
								local da = a1 - a0
								if da > math.pi then da -= (2 * math.pi)
								elseif da < -math.pi then da += (2 * math.pi) end
								local ang = a0 + (da * progress)
								if not yLock then yLock = startPos.Y + ((behind.Y - startPos.Y) * progress) end
								newPos = Vector3.new(enemyPos.X + math.cos(ang) * radius, yLock,
									enemyPos.Z + math.sin(ang) * radius)
							elseif combat.bfChainMode == "legit" then
								local threshold = isSpin and 0.25 or 0.5
								if not slowdownStarted and progress >= threshold then
									slowdownStarted, slowdownAnchor = true, elapsed
								end
								if slowdownStarted then
									local sinceAnchor = elapsed - slowdownAnchor
									if sinceAnchor >= combat.legitSlowdownInterval
										and combat.legitSlowdownInterval > 0 then
										local steps = math.floor(sinceAnchor / combat.legitSlowdownInterval)
										extraSpeed     += steps * combat.legitSlowdownAmount
										slowdownAnchor += steps * combat.legitSlowdownInterval
										duration = combat.legitSpeed + extraSpeed
										progress = math.clamp(elapsed / duration, 0, 1)
									end
									if progress >= 1 then break
									elseif progress <= lastProgress then break end
								end
								lastProgress = progress
								local arc     = combat.legitArcWidth
								local d       = startPos - enemyPos
								local baseAng = math.atan2(d.Z, d.X)
								local sweep   = math.pi
								if mode == "360_left" then sweep = math.pi * 2
								elseif mode == "360_right" then sweep = -math.pi * 2
								elseif mode == "270_left" then sweep = math.pi * 1.5
								elseif mode == "270_right" then sweep = -math.pi * 1.5 end
								local ang = baseAng + (sweep * progress)
								if not yLock then yLock = startPos.Y end
								newPos = Vector3.new(enemyPos.X + math.cos(ang) * arc, yLock,
									enemyPos.Z + math.sin(ang) * arc)
							end

							local canAim = combat.autoAim and mode ~= "360_left" and mode ~= "360_right"
							if canAim then
								if combat.aimMode == "Character" then
									rootPart.CFrame = CFrame.new(newPos, lookAt); releaseCamera()
								elseif combat.aimMode == "Camera" then
									rootPart.CFrame = CFrame.new(newPos) * rootPart.CFrame.Rotation
									aimTarget = lookAt
								end
							else
								rootPart.CFrame = CFrame.new(newPos) * rootPart.CFrame.Rotation
								releaseCamera()
							end
						elseif combat.autoAim and mode ~= "360_left" and mode ~= "360_right" then
							if combat.aimMode == "Character" then
								rootPart.CFrame = CFrame.new(rootPart.Position, lookAt); releaseCamera()
							elseif combat.aimMode == "Camera" then
								aimTarget = lookAt
							end
						else
							releaseCamera()
						end
					elseif combat.autoAim and mode ~= "360_left" and mode ~= "360_right" then
						if combat.aimMode == "Character" then
							rootPart.CFrame = CFrame.new(rootPart.Position, lookAt); releaseCamera()
						elseif combat.aimMode == "Camera" then
							aimTarget = lookAt
						end
					else
						releaseCamera()
					end
				else
					releaseCamera()
				end
				RunService.RenderStepped:Wait()
			end
			releaseCamera()
		end)
	end
end

local function setupCharacter(char)
	character = char
	humanoid  = char:WaitForChild("Humanoid")
	rootPart  = char:WaitForChild("HumanoidRootPart")
	animator  = humanoid:WaitForChild("Animator")
	if animConnection then animConnection:Disconnect() end
	animConnection = animator.AnimationPlayed:Connect(onAnimationPlayed)
end

local function onCharacterAdded(char)
	task.wait(0.1)
	setupCharacter(char)
end
if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

--============================================================================
notify("JJS Hub", "Loaded. PC: RightControl toggles the UI. "
	.. "Mobile: tap the '–' button to minimise, then the 'JJS' bubble to reopen.", 6)
