--[[
	NovaUI • Demo
	----------------------------------------------------------------------
	Put this LocalScript in StarterPlayerScripts (or StarterGui), with the
	NovaUI ModuleScript next to it. Press F5 in Studio to see the interface.

	Shows tab groups (the section rail beside the tabs), group boxes inside
	the content frame, and every component including the new tools
	(color picker, multi-select, segmented, stepper, progress bar).
]]

local NovaUI = require(script.Parent.NovaUI)

local Window = NovaUI:CreateWindow({
	Title    = "Nebula Sandbox",
	SubTitle = "v1.1 • Settings",
	Size     = UDim2.fromOffset(600, 420),
	Accent   = Color3.fromRGB(120, 90, 255),
	Theme    = "Dark",
	ToggleKey = Enum.KeyCode.RightShift, -- press to hide/show
})

-- ── Section rail: group tabs under headers (like Fluent/WindUI) ───────────
Window:CreateTabGroup("Player")
local main = Window:CreateTab("Gameplay")
local char = Window:CreateTab("Character")

Window:CreateTabGroup("Client")
local ui   = Window:CreateTab("Interface")
local more = Window:CreateTab("Components")

-- ── Tab 1: Gameplay ───────────────────────────────────────────────────────
main:CreateSection("Movement")
main:CreateSlider({
	Name = "Walk Speed", Min = 16, Max = 120, Default = 16,
	Callback = function(v)
		local c = game.Players.LocalPlayer.Character
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end,
})
main:CreateToggle({ Name = "Auto Sprint", Default = false, Callback = function(on) print("Sprint:", on) end })

-- ── Tab 2: Character (group boxes inside the frame) ───────────────────────
local combat = char:CreateGroup("Combat")
combat:CreateToggle({ Name = "Auto Parry", Default = false })
combat:CreateStepper({ Name = "Parry Distance", Min = 5, Max = 60, Step = 5, Default = 20 })

local visuals = char:CreateGroup("Visuals")
visuals:CreateColorPicker({ Name = "Trail Color", Default = Color3.fromRGB(120, 90, 255),
	Callback = function(col) print("color", col) end })
visuals:CreateSegmented({ Name = "Quality", Options = { "Low", "Med", "High" }, Default = "Med" })

-- ── Tab 3: Interface ──────────────────────────────────────────────────────
ui:CreateDropdown({ Name = "Theme", Options = { "Dark", "Light" }, Default = "Dark",
	Callback = function(t) Window:SetTheme(t) end })
ui:CreateInput({ Name = "Display Name", Placeholder = "Enter a name…",
	Callback = function(text, enter) if enter then Window:Notify({ Title = "Saved", Content = text }) end end })
ui:CreateKeybind({ Name = "Quick Action", Default = Enum.KeyCode.E,
	OnPress = function() Window:Notify({ Title = "Pressed!" }) end })

-- ── Tab 4: Components showcase ────────────────────────────────────────────
more:CreateSection("New tools")
more:CreateMultiDropdown({ Name = "Modules", Options = { "ESP", "Fly", "Speed", "Jump" }, Default = { "Speed" },
	Callback = function(list) print("enabled:", table.concat(list, ", ")) end })
local bar = more:CreateProgressBar({ Name = "Loading" })
more:CreateDivider()
more:CreateButton({ Name = "Fill progress", Callback = function()
	for i = 0, 10 do task.wait(0.08); bar:Set(i / 10) end
end })
more:CreateParagraph("About", "NovaUI now ships tab groups, group boxes, and a full component set.")

Window:Notify({ Title = "NovaUI 1.1 loaded", Content = "Right-Shift toggles the menu." })
