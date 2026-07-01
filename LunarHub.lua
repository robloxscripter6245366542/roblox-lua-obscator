--[[

    Lunar Hub  —  Pink Glass Edition
    Built on top of WindUI (https://github.com/Footagesus/WindUI)

    Pink/violet "glass" theme (Acrylic + translucent panels), a Home
    dashboard (player info, job id / rejoin, live ping), safer loading
    (no remote loadstring), and a full WindUI element showcase.

]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local Stats = cloneref(game:GetService("Stats"))
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))

local LocalPlayer = Players.LocalPlayer

-- */  Load WindUI (no remote loadstring — local module or ReplicatedStorage only)  /* --
local WindUI
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)

	if ok then
		WindUI = result
	elseif RunService:IsStudio() then
		WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
	else
		error(
			"Lunar Hub: WindUI could not be found. Place the WindUI module at './src/Init' "
				.. "(relative require) or under ReplicatedStorage/WindUI/Init before running this script.",
			0
		)
	end
end

-- */  Icons  /* --
-- Registers the Solar icon set used across the tabs below. This was missing
-- from the original example, so tab/window icons silently failed to render.
WindUI.Creator.AddIcons("solar", {
	["CheckSquareBold"] = "rbxassetid://132438947521974",
	["CursorSquareBold"] = "rbxassetid://120306472146156",
	["FileTextBold"] = "rbxassetid://89294979831077",
	["FolderWithFilesBold"] = "rbxassetid://74631950400584",
	["HamburgerMenuBold"] = "rbxassetid://134384554225463",
	["Home2Bold"] = "rbxassetid://92190299966310",
	["InfoSquareBold"] = "rbxassetid://119096461016615",
	["PasswordMinimalisticInputBold"] = "rbxassetid://109919668957167",
	["SolarSquareTransferHorizontalBold"] = "rbxassetid://125444491429160",
})

-- */  Colors — Lunar palette (pink / violet glass)  /* --
local Pink = Color3.fromHex("#FF6FB0")
local Rose = Color3.fromHex("#EC4899")
local Fuchsia = Color3.fromHex("#D946EF")
local Violet = Color3.fromHex("#B15CFF")
local Lavender = Color3.fromHex("#C9A6FF")
local Grey = Color3.fromHex("#B79AC9")
local Red = Color3.fromHex("#FF4D6D")

-- */  Theme — "Lunar" (pink glass)  /* --
WindUI:AddTheme({
	Name = "Lunar",

	Accent = Pink,
	Dialog = Color3.fromHex("#241129"),

	Text = Color3.fromHex("#FBEAF6"),
	Placeholder = Color3.fromHex("#B98FCF"),
	Background = Color3.fromHex("#160A1E"),
	Button = Color3.fromHex("#3A1F45"),
	Icon = Color3.fromHex("#FFD3EC"),

	Toggle = Pink,
	Slider = Color3.fromHex("#FF9BD2"),
	Checkbox = Pink,

	ElementBackground = Color3.fromHex("#2A1533"),
	ElementBackgroundTransparency = 0.35,
})
WindUI:SetTheme("Lunar")

-- */  Popup  /* --
local function createWelcomePopup()
	return WindUI:Popup({
		Title = "Welcome to Lunar Hub",
		Icon = "moon",
		Content = "A pink glass UI built on WindUI. Enjoy the frosted panels!",
		Buttons = {
			{
				Title = "Let's go",
				Icon = "sparkles",
				Variant = "Primary",
			},
			{
				Title = "Join Discord",
				Icon = "message-circle",
				Variant = "Secondary",
				Callback = function()
					if setclipboard then
						setclipboard("https://discord.gg/lunarhub")
					end
				end,
			},
			{
				Title = "Maybe later",
				Icon = "moon",
				Variant = "Tertiary",
			},
		},
	})
end

-- */  Window  /* --
local Window = WindUI:CreateWindow({
	Title = "Lunar Hub  |  Pink Glass Edition",
	Folder = "LunarHub",
	Icon = "moon",
	NewElements = true,

	HideSearchBar = false,

	Acrylic = true,
	Transparent = true,
	HidePanelBackground = true,
	Radius = 20,
	ToggleKey = Enum.KeyCode.RightShift,

	OpenButton = {
		Title = "Open Lunar Hub",
		CornerRadius = UDim.new(1, 0),
		StrokeThickness = 2,
		Enabled = true,
		Draggable = true,
		OnlyMobile = false,
		Scale = 0.5,

		Color = ColorSequence.new(
			Color3.fromHex("#FF7FC0"),
			Color3.fromHex("#B15CFF")
		),
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

Window:SetBackgroundTransparency(0.35)

createWelcomePopup()

-- */  Tags  /* --
do
	Window:Tag({
		Title = "v" .. WindUI.Version,
		Icon = "moon",
		Color = Color3.fromHex("#241129"),
		Border = true,
	})
end

-- */ Other Functions /* --
local function parseJSON(luau_table, indent, level, visited)
	indent = indent or 2
	level = level or 0
	visited = visited or {}

	local currentIndent = string.rep(" ", level * indent)
	local nextIndent = string.rep(" ", (level + 1) * indent)

	if luau_table == nil then
		return "null"
	end

	local dataType = type(luau_table)

	if dataType == "table" then
		if visited[luau_table] then
			return '"[Circular Reference]"'
		end

		visited[luau_table] = true

		local isArray = true
		local maxIndex = 0

		for k, _ in pairs(luau_table) do
			if type(k) == "number" and k > maxIndex then
				maxIndex = k
			end
			if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
				isArray = false
				break
			end
		end

		local count = 0
		for _ in pairs(luau_table) do
			count = count + 1
		end
		if count ~= maxIndex and isArray then
			isArray = false
		end

		if count == 0 then
			return "{}"
		end

		if isArray then
			local result = "[\n"

			for i = 1, maxIndex do
				result = result .. nextIndent .. parseJSON(luau_table[i], indent, level + 1, visited)
				if i < maxIndex then
					result = result .. ","
				end
				result = result .. "\n"
			end

			result = result .. currentIndent .. "]"
			return result
		else
			local result = "{\n"
			local first = true

			local keys = {}
			for k in pairs(luau_table) do
				table.insert(keys, k)
			end
			table.sort(keys, function(a, b)
				if type(a) == type(b) then
					return tostring(a) < tostring(b)
				else
					return type(a) < type(b)
				end
			end)

			for _, k in ipairs(keys) do
				local v = luau_table[k]
				if not first then
					result = result .. ",\n"
				else
					first = false
				end

				if type(k) == "string" then
					result = result .. nextIndent .. '"' .. k .. '": '
				else
					result = result .. nextIndent .. '"' .. tostring(k) .. '": '
				end

				result = result .. parseJSON(v, indent, level + 1, visited)
			end

			result = result .. "\n" .. currentIndent .. "}"
			return result
		end
	elseif dataType == "string" then
		local escaped = luau_table:gsub("\\", "\\\\")
		escaped = escaped:gsub('"', '\\"')
		escaped = escaped:gsub("\n", "\\n")
		escaped = escaped:gsub("\r", "\\r")
		escaped = escaped:gsub("\t", "\\t")

		return '"' .. escaped .. '"'
	elseif dataType == "number" then
		return tostring(luau_table)
	elseif dataType == "boolean" then
		return luau_table and "true" or "false"
	elseif dataType == "function" then
		return '"function"'
	else
		return '"' .. dataType .. '"'
	end
end

local function tableToClipboard(luau_table, indent)
	indent = indent or 4
	local jsonString = parseJSON(luau_table, indent)
	if setclipboard then
		setclipboard(jsonString)
	end
	return jsonString
end

-- */  Home Tab  /* --
do
	local HomeTab = Window:Tab({
		Title = "Home",
		Desc = "Dashboard",
		Icon = "moon",
		IconColor = Pink,
		IconShape = "Square",
		Border = true,
	})

	local WelcomeSection = HomeTab:Section({
		Title = "Welcome",
	})

	local WelcomeParagraph = WelcomeSection:Paragraph({
		Title = "Welcome, " .. LocalPlayer.DisplayName .. "!",
		Desc = "@" .. LocalPlayer.Name,
		Image = "moon",
		ImageSize = 48,
		Buttons = {
			{
				Title = "Copy Job ID",
				Icon = "clipboard-copy",
				Callback = function()
					if setclipboard then
						setclipboard(game.JobId)
					end
					WindUI:Notify({
						Title = "Copied",
						Content = "Job ID copied to clipboard.",
					})
				end,
			},
			{
				Title = "Rejoin",
				Icon = "refresh-cw",
				Callback = function()
					pcall(function()
						TeleportService:Teleport(game.PlaceId, LocalPlayer)
					end)
				end,
			},
		},
	})

	task.spawn(function()
		local ok, thumbnail = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok and thumbnail then
			WelcomeParagraph:SetImage(thumbnail)
		end
	end)

	HomeTab:Space()

	local SessionSection = HomeTab:Section({
		Title = "Session Info",
	})

	local gameName = "Unknown Game"
	do
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(game.PlaceId)
		end)
		if ok and info and info.Name then
			gameName = info.Name
		end
	end

	local SessionParagraph = SessionSection:Paragraph({
		Title = gameName,
		Desc = ("Players: %d  •  Ping: -- ms"):format(#Players:GetPlayers()),
		Icon = "moon",
	})

	task.spawn(function()
		while Window and not Window.Destroyed do
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)

			SessionParagraph:SetDesc(("Players: %d  •  Ping: %d ms"):format(#Players:GetPlayers(), ping))

			task.wait(5)
		end
	end)

	HomeTab:Space()

	HomeTab:Button({
		Title = "Copy Game Link",
		Icon = "link",
		Justify = "Center",
		Callback = function()
			if setclipboard then
				setclipboard("https://www.roblox.com/games/" .. game.PlaceId)
			end
			WindUI:Notify({
				Title = "Copied",
				Content = "Game link copied to clipboard.",
			})
		end,
	})
end

-- */  About Tab  /* --
do
	local AboutTab = Window:Tab({
		Title = "About Lunar Hub",
		Desc = "Pink glass edition",
		Icon = "solar:info-square-bold",
		IconColor = Grey,
		IconShape = "Square",
		Border = true,
	})

	local AboutSection = AboutTab:Section({
		Title = "About Lunar Hub",
	})

	AboutSection:Image({
		Image = "https://repository-images.githubusercontent.com/880118829/22c020eb-d1b1-4b34-ac4d-e33fd88db38d",
		AspectRatio = "16:9",
		Radius = 9,
	})

	AboutSection:Space({ Columns = 3 })

	AboutSection:Section({
		Title = "What is Lunar Hub?",
		TextSize = 24,
		FontWeight = Enum.FontWeight.SemiBold,
	})

	AboutSection:Space()

	AboutSection:Section({
		Title = "Lunar Hub is a pink, frosted-glass interface built on top of WindUI.\n"
			.. "It uses WindUI's Acrylic + translucent panels for a soft glassmorphism look, "
			.. "with a custom 'Lunar' pink/violet theme layered on top.\n"
			.. "Written entirely in Lua (Luau), the scripting language used in Roblox.",
		TextSize = 18,
		TextTransparency = 0.35,
		FontWeight = Enum.FontWeight.Medium,
	})

	AboutTab:Space({ Columns = 4 })

	AboutTab:Button({
		Title = "Show Welcome Popup",
		Color = Pink,
		Justify = "Center",
		IconAlign = "Left",
		Icon = "sparkles",
		Callback = function()
			createWelcomePopup()
		end,
	})
	AboutTab:Space({ Columns = 1 })

	AboutTab:Button({
		Title = "Export Lunar Hub JSON (copy)",
		Color = Violet,
		Justify = "Center",
		IconAlign = "Left",
		Icon = "clipboard-copy",
		Callback = function()
			tableToClipboard(WindUI)
			WindUI:Notify({
				Title = "Lunar Hub JSON",
				Content = "Copied to Clipboard!",
			})
		end,
	})
	AboutTab:Space({ Columns = 1 })

	AboutTab:Button({
		Title = "Destroy Window",
		Color = Red,
		Justify = "Center",
		Icon = "shredder",
		IconAlign = "Left",
		Callback = function()
			Window:Dialog({
				Title = "Destroy Lunar Hub?",
				Icon = "shredder",
				Content = "This closes the UI completely — you'll need to rerun the script to bring it back.",
				Buttons = {
					{
						Title = "Cancel",
						Variant = "Secondary",
					},
					{
						Title = "Destroy",
						Icon = "shredder",
						Variant = "Primary",
						Callback = function()
							Window:Destroy()
						end,
					},
				},
			})
		end,
	})
end

-- */  Elements Section  /* --
local ElementsSection = Window:Section({
	Title = "Elements",
})
local ConfigUsageSection = Window:Section({
	Title = "Config Usage",
})
local OtherSection = Window:Section({
	Title = "Other",
})

-- */  Overview Tab  /* --
do
	local OverviewTab = ElementsSection:Tab({
		Title = "Overview",
		Icon = "solar:home-2-bold",
		IconColor = Grey,
		IconShape = "Square",
		Border = true,
	})

	OverviewTab:Section({
		Title = "Group's Example",
	})

	local OverviewGroup1 = OverviewTab:Group({})

	OverviewGroup1:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup1:Space()
	OverviewGroup1:Button({
		Title = "Button 2",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 2")
		end,
	})

	OverviewTab:Space()

	local OverviewGroup2 = OverviewTab:Group({})

	OverviewGroup2:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup2:Space()
	OverviewGroup2:Toggle({
		Title = "Toggle 2",
		Callback = function(v)
			print("clicked toggle 2:", v)
		end,
	})
	OverviewGroup2:Space()
	OverviewGroup2:Colorpicker({
		Title = "Colorpicker 3",
		Default = Pink,
		Callback = function(color)
			print(color)
		end,
	})

	OverviewTab:Space()

	local OverviewGroup3 = OverviewTab:Group({})

	local OverviewGroup3Section1 = OverviewGroup3:Section({
		Title = "Section 1",
		Desc = "Section example",
		Box = true,
		BoxBorder = true,
		Opened = true,
	})
	OverviewGroup3Section1:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup3Section1:Space()
	OverviewGroup3Section1:Toggle({
		Title = "Toggle 2",
		Callback = function(v)
			print("clicked toggle 2:", v)
		end,
	})

	OverviewGroup3:Space()

	local OverviewGroup3Section2 = OverviewGroup3:Section({
		Title = "Section 2",
		Box = true,
		BoxBorder = true,
		Opened = true,
	})
	OverviewGroup3Section2:Button({
		Title = "Button 1",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 1")
		end,
	})
	OverviewGroup3Section2:Space()
	OverviewGroup3Section2:Button({
		Title = "Button 2",
		Justify = "Center",
		Icon = "",
		Callback = function()
			print("clicked button 2")
		end,
	})
end

-- */  Toggle Tab  /* --
do
	local ToggleTab = ElementsSection:Tab({
		Title = "Toggle",
		Icon = "solar:check-square-bold",
		IconColor = Rose,
		IconShape = "Square",
		Border = true,
	})

	ToggleTab:Toggle({
		Title = "Toggle",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Toggle",
		Desc = "Toggle example",
	})

	ToggleTab:Space()

	local ToggleGroup1 = ToggleTab:Group()
	ToggleGroup1:Toggle({})
	ToggleGroup1:Space()
	ToggleGroup1:Toggle({})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Checkbox",
		Type = "Checkbox",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Checkbox",
		Desc = "Checkbox example",
		Type = "Checkbox",
	})

	ToggleTab:Space()

	ToggleTab:Toggle({
		Title = "Toggle",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	ToggleTab:Toggle({
		Title = "Toggle",
		Desc = "Toggle example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Button Tab  /* --
do
	local ButtonTab = ElementsSection:Tab({
		Title = "Button",
		Icon = "solar:cursor-square-bold",
		IconColor = Fuchsia,
		IconShape = "Square",
		Border = true,
	})

	local HighlightButton
	HighlightButton = ButtonTab:Button({
		Title = "Highlight Button",
		Icon = "mouse",
		Callback = function()
			print("clicked highlight")
			HighlightButton:Highlight()
		end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Pink Button",
		Color = Pink,
		Icon = "",
		Callback = function() end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Violet Button",
		Desc = "With description",
		Color = Violet,
		Icon = "",
		Callback = function() end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Notify Button",
		Callback = function()
			WindUI:Notify({
				Title = "Hello",
				Content = "Welcome to Lunar Hub!",
				Icon = "solar:bell-bold",
				Duration = 5,
				CanClose = false,
			})
		end,
	})

	ButtonTab:Button({
		Title = "Notify Button 2",
		Callback = function()
			WindUI:Notify({
				Title = "Hello",
				Content = "Welcome to Lunar Hub!",
				Duration = 5,
				CanClose = false,
			})
		end,
	})

	ButtonTab:Space()

	ButtonTab:Button({
		Title = "Button",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	ButtonTab:Button({
		Title = "Button",
		Desc = "Button example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Input Tab  /* --
do
	local InputTab = ElementsSection:Tab({
		Title = "Input",
		Icon = "solar:password-minimalistic-input-bold",
		IconColor = Violet,
		IconShape = "Square",
		Border = true,
	})

	InputTab:Input({
		Title = "Input",
		Icon = "mouse",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Type = "Textarea",
		Icon = "mouse",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Type = "Textarea",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input",
		Desc = "Input example",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input Textarea",
		Desc = "Input example",
		Type = "Textarea",
	})

	InputTab:Space()

	InputTab:Input({
		Title = "Input",
		Locked = true,
		LockedTitle = "This element is locked",
	})

	InputTab:Input({
		Title = "Input",
		Desc = "Input example",
		Locked = true,
		LockedTitle = "This element is locked",
	})
end

-- */  Slider Tab  /* --
do
	local SliderTab = ElementsSection:Tab({
		Title = "Slider",
		Icon = "solar:square-transfer-horizontal-bold",
		IconColor = Rose,
		IconShape = "Square",
		Border = true,
	})

	SliderTab:Section({
		Title = "Default Slider with Tooltip and without textbox",
		TextSize = 14,
	})

	SliderTab:Slider({
		Title = "Slider Example",
		Desc = "Hahahahaha hello",
		IsTooltip = true,
		IsTextbox = false,
		Width = 200,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider without description",
		TextSize = 14,
	})

	SliderTab:Slider({
		Title = "Slider Example",
		Step = 1,
		Width = 200,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider without titles",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider with icons ('from' only)",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 200,
			Default = 100,
		},
		Icons = {
			From = "sfsymbols:sunMinFill",
		},
		Callback = function(value)
			print(value)
		end,
	})

	SliderTab:Space()

	SliderTab:Section({
		Title = "Slider with icons (from & to)",
		TextSize = 14,
	})

	SliderTab:Slider({
		IsTooltip = true,
		Step = 1,
		Value = {
			Min = 0,
			Max = 100,
			Default = 50,
		},
		Icons = {
			From = "sfsymbols:sunMinFill",
			To = "sfsymbols:sunMaxFill",
		},
		Callback = function(value)
			print(value)
		end,
	})
end

-- */  Dropdown Tab  /* --
do
	local DropdownTab = ElementsSection:Tab({
		Title = "Dropdown",
		Icon = "solar:hamburger-menu-bold",
		IconColor = Lavender,
		IconShape = "Square",
		Border = true,
	})

	DropdownTab:Dropdown({
		Title = "Advanced Dropdown (example)",
		Values = {
			{
				Title = "New file",
				Desc = "Create a new file",
				Icon = "file-plus",
				Callback = function()
					print("Clicked 'New File'")
				end,
			},
			{
				Title = "Copy link",
				Desc = "Copy the file link",
				Icon = "copy",
				Callback = function()
					print("Clicked 'Copy link'")
				end,
			},
			{
				Title = "Edit file",
				Desc = "Allows you to edit the file",
				Icon = "file-pen",
				Callback = function()
					print("Clicked 'Edit file'")
				end,
			},
			{
				Type = "Divider",
			},
			{
				Title = "Delete file",
				Desc = "Permanently delete the file",
				Icon = "trash",
				Callback = function()
					print("Clicked 'Delete file'")
				end,
			},
		},
	})

	DropdownTab:Space()

	DropdownTab:Dropdown({
		Title = "Multi Dropdown",
		Values = {
			"Привет",
			"Hello",
			"Сәлем",
			"Bonjour",
		},
		Value = nil,
		AllowNone = true,
		Multi = true,
		Callback = function(selectedValue)
			print("Selected: " .. selectedValue)
		end,
	})

	DropdownTab:Space()

	DropdownTab:Dropdown({
		Title = "No Multi Dropdown (default)",
		Values = {
			"Привет",
			"Hello",
			"Сәлем",
			"Bonjour",
		},
		Value = 1,
		Callback = function(selectedValue)
			print("Selected: " .. selectedValue)
		end,
	})

	DropdownTab:Space()
end

-- */  Config Usage  /* --
local canUseFileSystem = not RunService:IsStudio() and typeof(writefile) == "function" and typeof(isfile) == "function"

if canUseFileSystem then
	do -- config elements
		local ConfigElementsTab = ConfigUsageSection:Tab({
			Title = "Config Elements",
			Icon = "solar:file-text-bold",
			IconColor = Violet,
			IconShape = "Square",
			Border = true,
		})

		-- All elements are taken from the official documentation: https://footagesus.github.io/WindUI-Docs/docs

		ConfigElementsTab:Colorpicker({
			Flag = "ColorpickerTest",
			Title = "Colorpicker",
			Desc = "Colorpicker Description",
			Default = Pink,
			Transparency = 0,
			Locked = false,
			Callback = function(color)
				print("Background color: " .. tostring(color))
			end,
		})

		ConfigElementsTab:Space()

		ConfigElementsTab:Dropdown({
			Flag = "DropdownTest",
			Title = "Advanced Dropdown",
			Values = {
				{
					Title = "Category A",
					Icon = "bird",
				},
				{
					Title = "Category B",
					Icon = "house",
				},
				{
					Title = "Category C",
					Icon = "droplet",
				},
			},
			Value = "Category A",
			Callback = function(option)
				print("Category selected: " .. option.Title .. " with icon " .. option.Icon)
			end,
		})
		ConfigElementsTab:Dropdown({
			Flag = "DropdownTest2",
			Title = "Advanced Dropdown 2",
			Values = {
				{
					Title = "Category A",
					Icon = "bird",
				},
				{
					Title = "Category B",
					Icon = "house",
				},
				{
					Title = "Category C",
					Icon = "droplet",
					Locked = true,
				},
			},
			Value = "Category A",
			Multi = true,
			Callback = function(options)
				local titles = {}
				for _, v in ipairs(options) do
					table.insert(titles, v.Title)
				end
				print("Selected: " .. table.concat(titles, ", "))
			end,
		})

		ConfigElementsTab:Space()

		ConfigElementsTab:Input({
			Flag = "InputTest",
			Title = "Input",
			Desc = "Input Description",
			Value = "Default value",
			InputIcon = "bird",
			Type = "Input",
			Placeholder = "Enter text...",
			Callback = function(input)
				print("Text entered: " .. input)
			end,
		})

		ConfigElementsTab:Space()

		ConfigElementsTab:Keybind({
			Flag = "KeybindTest",
			Title = "Keybind",
			Desc = "Keybind to open ui",
			Value = "G",
			Callback = function(v)
				Window:SetToggleKey(Enum.KeyCode[v])
			end,
		})

		ConfigElementsTab:Space()

		ConfigElementsTab:Slider({
			Flag = "SliderTest",
			Title = "Slider",
			Step = 1,
			Value = {
				Min = 20,
				Max = 120,
				Default = 70,
			},
			Callback = function(value)
				print(value)
			end,
		})
		ConfigElementsTab:Slider({
			Flag = "SliderTest2",
			Icons = {
				From = "sfsymbols:sunMinFill",
				To = "sfsymbols:sunMaxFill",
			},
			Step = 1,
			IsTooltip = true,
			Value = {
				Min = 0,
				Max = 100,
				Default = 50,
			},
			Callback = function(value)
				print(value)
			end,
		})

		ConfigElementsTab:Space()

		ConfigElementsTab:Toggle({
			Flag = "PanelBackgroundTest",
			Title = "Toggle Panel Background",
			Value = not Window.HidePanelBackground,
			Callback = function(state)
				Window:SetPanelBackground(state)
			end,
		})

		ConfigElementsTab:Toggle({
			Flag = "ToggleTest",
			Title = "Toggle",
			Desc = "Toggle Description",
			Value = false,
			Callback = function(state)
				print("Toggle Activated" .. tostring(state))
			end,
		})
	end

	do -- config panel
		local ConfigTab = ConfigUsageSection:Tab({
			Title = "Config Usage",
			Icon = "solar:folder-with-files-bold",
			IconColor = Fuchsia,
			IconShape = "Square",
			Border = true,
		})

		local ConfigManager = Window.ConfigManager
		local ConfigName = "default"

		local ConfigNameInput = ConfigTab:Input({
			Title = "Config Name",
			Icon = "file-cog",
			Callback = function(value)
				ConfigName = value
			end,
		})

		ConfigTab:Space()

		local AllConfigs = ConfigManager:AllConfigs()
		local DefaultValue = table.find(AllConfigs, ConfigName) and ConfigName or nil

		local AllConfigsDropdown = ConfigTab:Dropdown({
			Title = "All Configs",
			Desc = "Select existing configs",
			Values = AllConfigs,
			Value = DefaultValue,
			Callback = function(value)
				ConfigName = value
				ConfigNameInput:Set(value)
			end,
		})

		ConfigTab:Space()

		ConfigTab:Button({
			Title = "Save Config",
			Icon = "",
			Justify = "Center",
			Callback = function()
				Window.CurrentConfig = ConfigManager:Config(ConfigName)
				if Window.CurrentConfig:Save() then
					WindUI:Notify({
						Title = "Config Saved",
						Desc = "Config '" .. ConfigName .. "' saved",
						Icon = "check",
					})
				end

				AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
			end,
		})

		ConfigTab:Space()

		ConfigTab:Button({
			Title = "Load Config",
			Icon = "",
			Justify = "Center",
			Callback = function()
				Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
				if Window.CurrentConfig:Load() then
					WindUI:Notify({
						Title = "Config Loaded",
						Desc = "Config '" .. ConfigName .. "' loaded",
						Icon = "refresh-cw",
					})
				end
			end,
		})

		ConfigTab:Space()

		ConfigTab:Button({
			Title = "Print AutoLoad Configs",
			Icon = "",
			Justify = "Center",
			Callback = function()
				local ok, decoded = pcall(HttpService.JSONDecode, HttpService, ConfigManager:GetAutoLoadConfigs())
				if ok then
					print(decoded)
				end
			end,
		})
	end
end

-- */  Other  /* --
do
	local InviteCode = "lunar-hub-pink-glass"
	local DiscordAPI = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"

	local Response
	if WindUI.Creator.Request then
		local ok, body = pcall(function()
			return WindUI.Creator.Request({
				Url = DiscordAPI,
				Method = "GET",
				Headers = {
					["User-Agent"] = "LunarHub/PinkGlass",
					["Accept"] = "application/json",
				},
			}).Body
		end)

		if ok and body then
			local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
			if decodeOk then
				Response = decoded
			end
		end
	end

	local DiscordTab = OtherSection:Tab({
		Title = "Discord",
		Border = true,
	})

	if Response and Response.guild then
		DiscordTab:Section({
			Title = "Join our Discord server!",
			TextSize = 20,
		})
		DiscordTab:Paragraph({
			Title = tostring(Response.guild.name),
			Desc = tostring(Response.guild.description),
			Image = "https://cdn.discordapp.com/icons/"
				.. Response.guild.id
				.. "/"
				.. Response.guild.icon
				.. ".png?size=1024",
			ImageSize = 48,
			Buttons = {
				{
					Title = "Copy link",
					Icon = "link",
					Callback = function()
						if setclipboard then
							setclipboard("https://discord.gg/" .. InviteCode)
						end
					end,
				},
			},
		})
	else
		DiscordTab:Paragraph({
			Title = "Discord invite is not available right now.",
			TextSize = 20,
			Justify = "Center",
			Image = "solar:info-circle-bold",
			Color = "Red",
			Buttons = {
				{
					Title = "Get/Copy Invite Link",
					Icon = "link",
					Callback = function()
						if setclipboard then
							setclipboard("https://discord.gg/" .. InviteCode)
						else
							WindUI:Notify({
								Title = "Discord Invite Link",
								Content = "https://discord.gg/" .. InviteCode,
							})
						end
					end,
				},
			},
		})
	end
end

-- */  Example / Search Demo Tab  /* --
local Tabs = {
	ExampleTab = Window:Tab({
		Title = "Search Demo",
		Icon = "moon",
	}),
}

local dropdownA

local LargeListA = {}
do
	LargeListA[1] = "All"
	for i = 2, 100 do
		LargeListA[i] = "Item A" .. i
	end
end

local LargeListB = {}
for i = 1, 10 do
	LargeListB[i] = "Data B" .. i
end

Tabs.ExampleTab:Dropdown({
	Title = "Main Category",
	Values = { "All", "Other Option" },
	Value = "All",
	Callback = function(option)
		if dropdownA then
			task.spawn(function()
				if option == "All" then
					dropdownA:Refresh(LargeListA)
				else
					dropdownA:Refresh(LargeListB)
				end

				dropdownA:Select({ "All" })
			end)
		end
	end,
})

dropdownA = Tabs.ExampleTab:Dropdown({
	Title = "Target",
	Values = LargeListA,
	Multi = true,
	Value = { "All" },
	Callback = function(option) end,
})
