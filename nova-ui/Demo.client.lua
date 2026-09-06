--[[
	NovaUI • Demo
	----------------------------------------------------------------------
	Put this LocalScript in StarterPlayerScripts (or StarterGui), with the
	NovaUI ModuleScript next to it. Press F5 in Studio to see the interface.

	This shows every component and how to read its value from code.
]]

local NovaUI = require(script.Parent.NovaUI)

local Window = NovaUI:CreateWindow({
	Title    = "Nebula Sandbox",
	SubTitle = "v1.0 • Settings",
	Size     = UDim2.fromOffset(580, 400),
	Accent   = Color3.fromRGB(120, 90, 255),
	Theme    = "Dark",
	ToggleKey = Enum.KeyCode.RightShift, -- press to hide/show
})

-- ── Tab 1: Gameplay ──────────────────────────────────────────────────────
local main = Window:CreateTab("Gameplay")

main:CreateSection("Movement")

local walkSpeed = main:CreateSlider({
	Name    = "Walk Speed",
	Min     = 16, Max = 120, Default = 16,
	Callback = function(v)
		local char = game.Players.LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = v end
	end,
})

main:CreateToggle({
	Name        = "Auto Sprint",
	Description  = "Hold nothing — just run",
	Default      = false,
	Callback     = function(on) print("Sprint:", on) end,
})

main:CreateDropdown({
	Name    = "Camera Mode",
	Options = { "Classic", "Follow", "Cinematic" },
	Default = "Classic",
	Callback = function(mode) print("Camera:", mode) end,
})

-- ── Tab 2: Interface ─────────────────────────────────────────────────────
local ui = Window:CreateTab("Interface")

ui:CreateSection("Appearance")

ui:CreateDropdown({
	Name    = "Theme",
	Options = { "Dark", "Light" },
	Default = "Dark",
	Callback = function(t) Window:SetTheme(t) end,
})

ui:CreateInput({
	Name        = "Display Name",
	Placeholder  = "Enter a name…",
	Callback     = function(text, enter)
		if enter then Window:Notify({ Title = "Saved", Content = "Name set to " .. text }) end
	end,
})

ui:CreateKeybind({
	Name    = "Quick Action",
	Default = Enum.KeyCode.E,
	OnPress = function() Window:Notify({ Title = "Pressed!", Content = "Your bound key fired." }) end,
})

-- ── Tab 3: About ─────────────────────────────────────────────────────────
local about = Window:CreateTab("About")
about:CreateParagraph(
	"NovaUI",
	"A modern UI library for Roblox experiences. Build settings panels, "
	.. "HUDs, admin tools and shops with a few lines of code."
)
about:CreateButton({
	Name     = "Show a notification",
	Callback = function()
		Window:Notify({ Title = "Hello 👋", Content = "This is a NovaUI toast.", Duration = 4 })
	end,
})

Window:Notify({ Title = "NovaUI loaded", Content = "Press Right-Shift to toggle the menu." })
