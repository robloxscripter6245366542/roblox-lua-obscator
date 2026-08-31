-- Nexus V2 (cleaned: removed data-logging Discord webhook and execution telemetry)

local t1 = {}
local t2 = {
	value1 = game:GetService("Players"),
	value2 = game:GetService("RunService"),
	value3 = game:GetService("UserInputService"),
	value4 = game:GetService("TweenService"),
	value5 = game:GetService("GuiService")
}

t2.value6 = game:GetService("Lighting")
t2.value7 = game:GetService("ReplicatedStorage")

local SoundService = game:GetService("SoundService")

t2.value8 = t2.value1.LocalPlayer
t2.value9 = workspace.CurrentCamera
t2.value10 = t2.value8:WaitForChild("PlayerGui")

t2.value12 = game:GetService("HttpService")
local n1 = 155615604
t1.value1 = game
if n1 ~= t1.value1.PlaceId then
    warn("[Nexus V2] Wrong game. This script only works in place " .. tostring(n1) .. " (current: " .. tostring(game.PlaceId) .. ")")

    return
end
local t9 = {
	value1 = t2.value3.TouchEnabled and not t2.value3.KeyboardEnabled
}
if t2.value3.TouchEnabled and t2.value3.MouseEnabled == false then
    t9.value1 = true
end
pcall(function()
    local v81 = t2.value9 and t2.value9.ViewportSize

    if t2.value3.TouchEnabled and (v81 and (v81.X > 0 and v81.X <= 900)) then
        t9.value1 = true
    end
end)
t1.value1 = Enum.HighlightDepthMode.AlwaysOnTop
t9.value2 = t1.value1
t9.value3 = 0.18
t9.value4 = 0.08
t9.value5 = "NexusV2"
t9.value6 = "nexusv2"
t9.value7 = "total_executions"
t9.value8 = {
	"Head",
	"Torso",
	"UpperTorso",
	"LowerTorso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
	"LeftUpperArm",
	"RightUpperArm",
	"LeftLowerArm",
	"RightLowerArm",
	"LeftHand",
	"RightHand",
	"LeftUpperLeg",
	"RightUpperLeg",
	"LeftLowerLeg",
	"RightLowerLeg",
	"LeftFoot",
	"RightFoot"
}
local color3 = Color3.fromRGB(10, 10, 10)

t1.value1 = Color3.fromRGB(14, 14, 14)
t1.value2 = Color3.fromRGB(18, 18, 18)
t1.value3 = Color3.fromRGB(28, 28, 28)

local color3_2 = Color3.fromRGB(36, 36, 36)
local color3_3 = Color3.fromRGB(245, 245, 245)

t1.value4 = Color3.fromRGB(120, 120, 125)

local color3_4 = Color3.fromRGB(255, 255, 255)

t1.value7 = Color3.fromRGB(255, 255, 255)

local color3_5 = Color3.fromRGB(32, 32, 32)

t1.value5 = Color3.fromRGB(200, 55, 60)
t1.value6 = Color3.fromRGB(45, 45, 48)
t9.value9 = {
	Background = color3,
	Sidebar = t1.value1,
	Card = t1.value2,
	Element = t1.value3,
	ElementHover = color3_2,
	Text = color3_3,
	TextDark = t1.value4,
	Accent = color3_4,
	Toggle = t1.value7,
	Stroke = color3_5,
	Danger = t1.value5,
	Track = t1.value6
}
local color3_6 = Color3.fromRGB(90, 160, 255)

t1.value5 = Color3.fromRGB(80, 200, 180)
t1.value1 = Color3.fromRGB(180, 100, 255)
t1.value6 = Color3.fromRGB(255, 90, 110)
t1.value2 = Color3.fromRGB(100, 210, 100)
t1.value7 = Color3.fromRGB(255, 170, 60)
t1.value3 = Color3.fromRGB(255, 220, 80)
t1.value8 = Color3.fromRGB(255, 120, 200)

local color3_7 = Color3.fromRGB(100, 200, 255)

t1.value9 = Color3.fromRGB(0, 220, 180)

local color3_8 = Color3.fromRGB(255, 80, 50)

t1.value10 = Color3.fromRGB(160, 160, 180)
t1.value4 = Color3.fromRGB(255, 140, 0)
t1.value11 = Color3.fromRGB(70, 130, 255)

local color3_9 = Color3.fromRGB(200, 80, 255)
local fromRGB = Color3.fromRGB
local _ = {
	color3_6,
	t1.value5,
	t1.value1,
	t1.value6,
	t1.value2,
	t1.value7,
	t1.value3,
	t1.value8,
	color3_7,
	t1.value9,
	color3_8,
	t1.value10,
	t1.value4,
	t1.value11,
	color3_9,
	fromRGB(50, 255, 150)
}

t1.value5 = Color3.fromRGB(24, 24, 27)
t1.value1 = Color3.fromRGB(30, 30, 34)
t1.value6 = Color3.fromRGB(20, 24, 32)
t1.value2 = Color3.fromRGB(28, 20, 28)
t1.value7 = Color3.fromRGB(20, 28, 24)
t1.value3 = Color3.fromRGB(32, 20, 20)
t1.value8 = Color3.fromRGB(18, 22, 28)

local color3_10 = Color3.fromRGB(28, 28, 20)

t1.value9 = Color3.fromRGB(22, 18, 28)

local color3_11 = Color3.fromRGB(16, 16, 18)

t1.value10 = Color3.fromRGB(35, 30, 28)
t1.value4 = Color3.fromRGB(12, 14, 20)
t1.value11 = Color3.fromRGB(40, 40, 48)

local color3_12 = Color3.fromRGB(25, 18, 22)
local color3_13 = Color3.fromRGB(18, 25, 22)
local fromRGB2 = Color3.fromRGB
local _ = {
	t1.value5,
	t1.value1,
	t1.value6,
	t1.value2,
	t1.value7,
	t1.value3,
	t1.value8,
	color3_10,
	t1.value9,
	color3_11,
	t1.value10,
	t1.value4,
	t1.value11,
	color3_12,
	color3_13,
	fromRGB2(10, 12, 16)
}

t1.value2 = {
	W = false,
	A = false,
	S = false,
	D = false,
	Up = false,
	Down = false
}
local t10 = {
	Prisoners = false,
	Criminals = false,
	Police = false
}
t1.value1 = math.clamp(t2.value6.ClockTime, 0, 24)

local t11 = {
	cameraLock = false,
	highlights = false,
	espNames = true,
	espHealth = true,
	espDistance = true,
	espTracers = true,
	espBoxes = true,
	espTeamColors = false,
	espChams = false,
	espRangeOn = false,
	espMaxRange = 1000,
	silentRangeOn = false,
	silentMaxRange = 1000,
	aimlock = false,
	fovCircle = false,
	legit = false,
	silentAim = false,
	triggerbot = false,
	hbe = false,
	hbeSize = 15,
	mp5Mod = false,
	lastTriggerShot = 0,
	legitPart = "Head",
	lastLegit = 0,
	fovRadius = 120,
	aimSmooth = 8,
	hitChance = 100,
	reactionMs = 0,
	switchDelay = 0.15,
	lastTargetSwitch = 0,
	humanizeSilent = false,
	lastSilentTarget = nil,
	dmgMarkers = false,
	dmgStack = false,
	lastShotAt = 0,
	invisible = false,
	xray = false,
	fly = false,
	doors = false,
	walkSpeedOn = false,
	spinbot = false,
	longArrest = false,
	freecam = false,
	walkSpeed = 16,
	jumpHeight = 7.2,
	flySpeed = 50,
	mobileKeys = t1.value2,
	freecamConn = nil,
	freecamCF = nil,
	freecamYaw = 0,
	freecamPitch = 0,
	targetIndex = 1,
	aimName = "",
	aimTeams = t10,
	clockOn = false,
	clockTime = t1.value1,
	fullbright = false,
	minimized = false,
	tab = "Home",
	killSoundId = "",
	headSoundId = "",
	killVol = 0.5,
	headVol = 0.5,
	killfeedUI = false,
	silentTarget = nil,
	silentHL = nil,
	flyTarget = nil,
	vehicle = nil,
	tween = nil,
	speedConn = nil,
	flyConn = nil,
	noclipConn = nil,
	worldNoclipConn = nil,
	doorsConn = nil,
	worldNoclip = false,
	bv = nil,
	bg = nil,
	listening = nil,
	lastHeadShot = nil
}
t1.value6 = {}
t1.value1 = {}
t9.value10 = t11

-- Config persistence: save/restore UI & visual preferences only.
-- Aim/combat toggles are intentionally NOT persisted, so nothing auto-arms on load.
do
    local CONFIG_FOLDER = "NexusV2"
    local CONFIG_FILE = "NexusV2/config.json"
    local PERSIST_KEYS = {
        "tab", "minimized", "killfeedUI",
        "killSoundId", "headSoundId", "killVol", "headVol",
        "clockOn", "clockTime", "fullbright",
        "dmgMarkers", "dmgStack"
    }

    local function hasFileApi()
        return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
    end

    local function serializeConfig()
        local data = {}

        for _, k in ipairs(PERSIST_KEYS) do
            local v = t9.value10[k]
            local tv = type(v)

            if tv == "boolean" or tv == "number" or tv == "string" then
                data[k] = v
            end
        end

        local ok, encoded = pcall(function()
            return t2.value12:JSONEncode(data)
        end)

        return ok and encoded or nil
    end

    local function saveConfig()
        if not hasFileApi() then
            return
        end

        local encoded = serializeConfig()

        if not encoded then
            return
        end

        pcall(function()
            if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then
                makefolder(CONFIG_FOLDER)
            end

            writefile(CONFIG_FILE, encoded)
        end)
    end

    local function loadConfig()
        if not hasFileApi() then
            return
        end

        local ok, decoded = pcall(function()
            if not isfile(CONFIG_FILE) then
                return nil
            end

            return t2.value12:JSONDecode(readfile(CONFIG_FILE))
        end)

        if not ok or type(decoded) ~= "table" then
            return
        end

        for _, k in ipairs(PERSIST_KEYS) do
            local saved = decoded[k]

            if saved ~= nil and type(saved) == type(t9.value10[k]) then
                t9.value10[k] = saved
            end
        end
    end

    -- Restore saved preferences before the UI is built.
    loadConfig()

    -- Persist automatically a few seconds after any tracked preference changes.
    task.spawn(function()
        local last = serializeConfig()

        while true do
            task.wait(4)

            local current = serializeConfig()

            if current and current ~= last then
                last = current
                saveConfig()
            end
        end
    end)
end

t9.value11 = {}
t9.value12 = t1.value1
t9.value13 = t1.value6
t9.value14 = {}
t1.value2 = {
	Fly = nil,
	Aimlock = nil,
	Doors = nil,
	SilentAim = nil
}
t9.value15 = t1.value2
t9.value16 = {}
t9.value17 = {}
t9.value18 = {}
t9.value19 = {}
t9.value20 = {}
t1.value9 = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
t9.value21 = t1.value9
t9.value22 = {}
t9.value23 = {}
function t9.value25()
    return nil
end
t9.value26 = Instance.new("Sound")

local value26 = t9.value26
t1.value10 = "Name"
value26[t1.value10] = "NexusKillSound"
local value26_2 = t9.value26
t1.value10 = "Volume"
function t1.value1()
    if t9.value10.speedConn then
        t9.value10.speedConn:Disconnect()
        t9.value10.speedConn = nil
    end
end
t1.value5 = t9.value10.killVol
value26_2[t1.value10] = t1.value5
local value26_3 = t9.value26
t1.value10 = "Parent"
value26_3[t1.value10] = SoundService
t1.value10 = Instance
function t1.value3(p2)
    if t9.value10.espTeamColors then
        if p2.Team then
            return p2.TeamColor.Color
        end

        local v102 = p2.Team and p2.Team.Name or ""
        local v103 = string.lower(v102)

        if string.find(v103, "guard") or string.find(v103, "police") then
            return Color3.fromRGB(50, 120, 255)
        end

        if string.find(v103, "criminal") then
            return Color3.fromRGB(255, 60, 60)
        end

        if string.find(v103, "inmate") or string.find(v103, "prison") then
            return Color3.fromRGB(255, 140, 40)
        end

        return Color3.fromRGB(200, 200, 200)
    end

    return t9.value9.Accent or Color3.fromRGB(90, 160, 255)
end
function t1.value2(p3)
    if not p3 then
        return
    end

    if not t9.value10.legit then
        return p3:FindFirstChild("Head")
    end

    if tick() - t9.value10.lastLegit >= t9.value4 then
        t9.value10.lastLegit = tick()

        local t13 = {}

        for _, v in ipairs(t9.value8) do
            local v2 = p3:FindFirstChild(v)

            if v2 and v2:IsA("BasePart") then
                table.insert(t13, v)
            end
        end

        t9.value10.legitPart = #t13 > 0 and t13[math.random(1, #t13)] or "Head"
    end

    local t9value10legitPart = p3:FindFirstChild(t9.value10.legitPart)

    return t9value10legitPart and (not not t9value10legitPart:IsA("BasePart") and t9value10legitPart) or p3:FindFirstChild("Head")
end
t1.value10 = t1.value10.new("Sound")

function t1.value4(p4)
    local v111 = p4.Character and p4.Character:FindFirstChildOfClass("Humanoid")

    return v111 and v111.Health > 0
end
t9.value27 = t1.value10
t1.value10 = t9.value27
t1.value5 = "Name"
t1.value10[t1.value5] = "NexusHeadshotSound"
t1.value10 = t9.value27
t1.value5 = "Volume"
t1.value6 = t9.value10.headVol
t1.value10[t1.value5] = t1.value6
function t1.value7(p5)
    local p5Name = p5.Name
    local t14 = { p5Name }
    pcall(function()
        if p5:IsA("StringValue") then
            table.insert(t14, p5.Value)
        end
        if p5:IsA("TextLabel") or (p5:IsA("TextButton") or p5:IsA("TextBox")) then
            table.insert(t14, p5.Text)
        end
        for v786, v787 in ipairs(p5:GetDescendants()) do

            if v787:IsA("TextLabel") or v787:IsA("TextButton") then
                table.insert(t14, v787.Text)
            elseif v787:IsA("StringValue") then
                table.insert(t14, v787.Value)
            end
        end
        for _, child in ipairs(p5:GetChildren()) do
            if child:IsA("StringValue") or child:IsA("ObjectValue") then
                table.insert(t14, child.Name)

                if child:IsA("StringValue") then
                    table.insert(t14, child.Value)
                end
            end
        end
    end)

    return t14
end
t1.value10 = t9.value27
function t1.value8(p6)
    if p6 then
        local value10 = t9.value10
        local timestamp = tick()

        value10.lastHeadShot = {
			plr = p6,
			t = timestamp
		}
    end
end
t1.value5 = "Parent"
function t1.value9()
    if t9.value10.headSoundId == "" or t9.value27.SoundId == "" then
        return
    end

    t9.value27.Volume = t9.value10.headVol
    pcall(function()
        t9.value27:Stop()
        t9.value27.TimePosition = 0
        t9.value27:Play()
    end)
end
t1.value10[t1.value5] = SoundService
function t1.value5(p7)
    local _tostring = tostring

    if not p7 then
        p7 = ""
    end

    local v128 = _tostring(p7):match("%d+")

    t9.value10.killSoundId = v128 or ""
    t9.value26.SoundId = t9.value10.killSoundId ~= "" and "rbxassetid://" .. t9.value10.killSoundId or ""
end
function t1.value6(p8)
    local _tostring = tostring

    if not p8 then
        p8 = ""
    end

    local v134 = _tostring(p8):match("%d+")

    t9.value10.headSoundId = v134 or ""
    t9.value27.SoundId = t9.value10.headSoundId ~= "" and "rbxassetid://" .. t9.value10.headSoundId or ""
end
t9.value28 = t1.value5
function t1.value5(p9)
    t9.value10.doors = p9

    if t9.value10.doorsConn then
        t9.value10.doorsConn:Disconnect()
        t9.value10.doorsConn = nil
    end

    if p9 then

        for v138, v139 in ipairs(t9.value14) do

            local v140 = v139

            if v140.clone and v140.clone.Parent then
                pcall(function()
                    v140.clone:Destroy()
                end)
            end
        end
        table.clear(t9.value14)
        for _, v in ipairs({
			"CellDoors",
			"Doors"
		}) do
            local v3 = workspace:FindFirstChild(v)

            if v3 then
                local ok10, result10 = pcall(function()
                    return v3:Clone()
                end)

                if ok10 and result10 then
                    local insert = table.insert
                    local value14 = t9.value14
                    local v3Parent = v3.Parent

                    insert(value14, {
						clone = result10,
						parent = v3Parent
					})
                    v3:Destroy()
                end
            end
        end
        t9.value10.doorsConn = workspace.ChildAdded:Connect(function(child)
            task.wait(0.05)

            if t9.value10.doors and child.Name == "CellDoors" or child.Name == "Doors" then
                local ok11, result11 = pcall(function()
                    return child:Clone()
                end)

                if ok11 and result11 then
                    local insert = table.insert
                    local value14 = t9.value14
                    local childParent = child.Parent

                    insert(value14, {
						clone = result11,
						parent = childParent
					})
                    child:Destroy()
                end
            end
        end)

        return
    end

    for _, v in ipairs(t9.value14) do
        local v151 = v

        if v151.clone and v151.parent then
            pcall(function()
                v151.clone.Parent = v151.parent
            end)
        end
    end

    table.clear(t9.value14)
end
t9.value29 = t1.value6
function t1.value6()
    if t9.value10.killSoundId == "" or t9.value26.SoundId == "" then
        return
    end

    t9.value26.Volume = t9.value10.killVol
    pcall(function()
        t9.value26:Stop()
        t9.value26.TimePosition = 0
        t9.value26:Play()
    end)
end
function t1.value10(p10)
    if type(p10) ~= "string" or p10 == "" then
        return ""
    end

    return (p10:match("^%s*(%S+)") or ""):lower()
end
t9.value30 = t1.value6
t9.value31 = t1.value9
function t1.value6()
    getgenv().HBE = false
end
function t1.value9()
    if not t9.value10.walkSpeedOn then
        return
    end

    local v153 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

    if v153 and v153.WalkSpeed ~= t9.value10.walkSpeed then
        v153.WalkSpeed = t9.value10.walkSpeed
    end
end
t9.value32 = t1.value8
t9.value33 = t1.value10
function t1.value8()
    table.clear(t9.value11)
    for v156, v157 in ipairs(t2.value1:GetPlayers()) do

        if v157 ~= t2.value8 and (v157.Character and v157.Character:FindFirstChild("HumanoidRootPart")) then
            table.insert(t9.value11, v157)
        end
    end
    if t9.value10.targetIndex > #t9.value11 then
        t9.value10.targetIndex = math.max(1, #t9.value11)
    end
end
t9.value34 = t1.value7
t9.value35 = nil
local function v53(p11)
    if not p11 then
        return false
    end

    local v159 = string.lower(t2.value8.Name)
    local v160 = t2.value8.DisplayName and string.lower(t2.value8.DisplayName) or ""

    for _, v in ipairs(t9.value34(p11)) do
        local v163 = t9.value33(v)

        if v163 ~= "" and v163 == v159 or v160 ~= "" and v163 == v160 then
            return true
        end
    end

    return false
end
function t1.value7(p12)
    local u165
    local u166
    local v167, v168, v169 = ipairs(t9.value34(p12))
    local g171
    local v175
    local v174
    repeat
        local v170

        repeat
            v169, v170 = v167(v168, v169)

            if not v169 then
                g171 = true
            end

            if g171 then
                break
            end
        until type(v170) == "string" and v170 ~= ""

        if g171 then
            break
        end

        local v172, v173 = v170:match("^%s*(.-)%s+[Kk]illed%s+(.-)%s+[Ww]ith%s+.+$")

        if v172 and (v173 and (v172 ~= "" and v173 ~= "")) then
            u165 = v172
            u166 = v173
            g171 = true
        end

        if g171 then
            break
        end

        v174, v175 = v170:match("^%s*(.-)%s+[Kk]illed%s+(.+)$")
    until v174 and (v175 and (v174 ~= "" and v175 ~= ""))
    if not g171 then
        if not g171 then
            local v176 = v175:gsub("%s+[Ww]ith%s+.+$", "")

            u165 = v174
            u166 = v176
        end
    end
    if not u165 then
        pcall(function()
            local v803 = p12:FindFirstChild("Killer") or p12:FindFirstChild("killer")
            local Victim = p12:FindFirstChild("Victim")

            if not Victim then
                Victim = p12:FindFirstChild("victim") or (p12:FindFirstChild("Killed") or p12:FindFirstChild("killed"))
            end

            if v803 then
                if v803:IsA("ObjectValue") and (v803.Value and v803.Value:IsA("Player")) then
                    u165 = v803.Value.Name
                elseif v803:IsA("StringValue") and v803.Value ~= "" then
                    u165 = v803.Value
                end
            end

            if Victim then
                if Victim:IsA("ObjectValue") and (Victim.Value and Victim.Value:IsA("Player")) then
                    u166 = Victim.Value.Name

                    return
                end

                if Victim:IsA("StringValue") and Victim.Value ~= "" then
                    u166 = Victim.Value
                end
            end
        end)
    end
    if u165 then
        u165 = u165:gsub("^%s+", ""):gsub("%s+$", "")
    end
    if u166 then
        u166 = u166:gsub("^%s+", ""):gsub("%s+$", "")
    end

    return u165, u166
end
function t9.value36(p13)
    if type(p13) ~= "string" then
        return ""
    end

    local v130 = p13:gsub("^%s+", ""):gsub("%s+$", "")
    local v131 = v130:match("^(.-)%s*%(@[^%)]+%)%s*$")

    if v131 and v131 ~= "" then
        v130 = v131:gsub("%s+$", "")
    end

    return (v130:gsub("@[%w_]+", ""):gsub("[%(%)]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
t9.value37 = nil
function t9.value37(p14)
    if type(p14) ~= "string" or p14 == "" then
        return nil
    end

    local v182 = t9.value36(p14)
    local v183 = string.lower(v182)
    local v184 = string.lower(p14)
    local v185, v186, v187 = ipairs(t2.value1:GetPlayers())
    local v188

    repeat
        v187, v188 = v185(v186, v187)

        if not v187 then
            local v189 = p14:match("%(@([%w_]+)%)") or p14:match("@([%w_]+)")

            if v189 then
                local v190 = string.lower(v189)

                for _, player in ipairs(t2.value1:GetPlayers()) do
                    if v190 == string.lower(player.Name) then
                        return player
                    end
                end
            end

            return nil
        end

        if v183 == string.lower(v188.Name) or v184 == string.lower(v188.Name) then
            return v188
        end
    until v188.DisplayName and v183 == string.lower(v188.DisplayName) or v184 == string.lower(v188.DisplayName)

    return v188
end
function t1.value10(p15)
    local v194 = t9.value37(p15)

    if v194 and v194.Team then
        return v194.TeamColor.Color
    end

    return Color3.fromRGB(230, 230, 230)
end
function t9.value38(p16)
    local v178 = t9.value37(p16)

    if v178 then
        local DisplayName = v178.DisplayName

        if type(DisplayName) == "string" and DisplayName ~= "" then
            return DisplayName
        end

        return v178.Name
    end

    local v180 = t9.value36(p16)

    return v180 ~= "" and v180 or "?"
end
t9.value39 = t1.value10
t9.value40 = t1.value7
t9.value41 = nil
t9.value42 = nil
function t1.value7()
    if t9.value41 and t9.value41.Parent then
        return
    end

    t9.value41 = Instance.new("ScreenGui")
    t9.value41.Name = "NexusKillfeed"
    t9.value41.ResetOnSpawn = false
    t9.value41.IgnoreGuiInset = true
    t9.value41.DisplayOrder = 50
    t9.value41.Parent = t2.value10
    t9.value42 = Instance.new("Frame")
    t9.value42.Name = "List"
    t9.value42.AnchorPoint = Vector2.new(1, 0)
    t9.value42.Position = UDim2.new(1, -16, 0, 80)
    t9.value42.Size = UDim2.new(0, 0, 0, 0)
    t9.value42.AutomaticSize = Enum.AutomaticSize.XY
    t9.value42.BackgroundTransparency = 1
    t9.value42.Parent = t9.value41

    local UIListLayout = Instance.new("UIListLayout")

    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    UIListLayout.Parent = t9.value42
end
t9.value43 = {}
function t1.value11()
    local aimTeams = t9.value10.aimTeams

    return aimTeams and aimTeams.Prisoners or (aimTeams.Criminals or aimTeams.Police)
end
t9.value44 = 5
t9.value45 = nil
function t1.value10()
    for _, v in ipairs(t9.value43) do
        local v201 = v

        pcall(function()
            v201:Destroy()
        end)
    end

    table.clear(t9.value43)

    if t9.value41 then
        pcall(function()
            t9.value41:Destroy()
        end)
        t9.value41 = nil
        t9.value42 = nil
    end
end
function t1.value12(p17, p18)
    if not t9.value10.killfeedUI then
        return
    end

    t9.value45()

    local v204 = t9.value38(p17)
    local v205 = t9.value38(p18)

    if v204 == "" then
        v204 = "?"
    end

    if v205 == "" then
        v205 = "?"
    end

    while #t9.value43 >= t9.value44 do
        local v206 = table.remove(t9.value43, 1)

        if v206 then
            pcall(function()
                v206:Destroy()
            end)
        end
    end

    local v207 = t9.value39(p17 or v204)
    local v208 = t9.value39(p18 or v205)
    local v209 = math.max(28, #v204 * 7 + 6)
    local v210 = math.max(28, #v205 * 7 + 6)
    local v211 = 20 + v209 + 6 + 48 + 6 + v210
    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.new(0, v211, 0, 26)
    Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    Frame.BackgroundTransparency = 0.25
    Frame.BorderSizePixel = 0
    Frame.Parent = t9.value42
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local UIStroke = Instance.new("UIStroke")

    UIStroke.Color = Color3.fromRGB(40, 40, 44)
    UIStroke.Transparency = 0.4
    UIStroke.Parent = Frame

    local UIListLayout = Instance.new("UIListLayout")

    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.Padding = UDim.new(0, 6)
    UIListLayout.Parent = Frame

    local UIPadding = Instance.new("UIPadding")

    UIPadding.PaddingLeft = UDim.new(0, 10)
    UIPadding.PaddingRight = UDim.new(0, 10)
    UIPadding.Parent = Frame

    local function v216(p19, p20, p21)
        local TextLabel = Instance.new("TextLabel")

        TextLabel.Size = UDim2.new(0, p21, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = p19
        TextLabel.TextColor3 = p20
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.TextSize = 12
        TextLabel.TextXAlignment = Enum.TextXAlignment.Center
        TextLabel.TextTruncate = Enum.TextTruncate.None
        TextLabel.Parent = Frame

        return TextLabel
    end

    v216(v204, v207, v209)

    local TextLabel = Instance.new("TextLabel")

    TextLabel.Size = UDim2.new(0, 48, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "killed"
    TextLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.TextSize = 11
    TextLabel.Parent = Frame
    v216(v205, v208, v210)
    table.insert(t9.value43, Frame)
    Frame.BackgroundTransparency = 1

    for _, descendant in ipairs(Frame:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            descendant.TextTransparency = 1
        end
    end

    task.spawn(function()
        for i = 1, 8 do
            local v810 = 1 - i / 8

            Frame.BackgroundTransparency = 0.25 + v810 * 0.75

            for _, descendant in ipairs(Frame:GetDescendants()) do
                if descendant:IsA("TextLabel") then
                    descendant.TextTransparency = v810
                end
            end

            task.wait(0.02)
        end

        Frame.BackgroundTransparency = 0.25

        for _, descendant in ipairs(Frame:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                descendant.TextTransparency = 0
            end
        end
    end)
    task.delay(8, function()
        if not Frame.Parent then
            return
        end

        for i = #t9.value43, 1, -1 do
            local v816 = i

            if t9.value43[v816] == Frame then
                table.remove(t9.value43, v816)

                break
            end
        end

        pcall(function()
            Frame:Destroy()
        end)
    end)
end
t9.value45 = t1.value7
t9.value46 = nil
t9.value47 = t1.value10
t9.value48 = t1.value12
t1.value13 = task
function t1.value7(p22)
    if not p22 then
        return false
    end

    local v221 = string.lower(p22.Name or "")

    return v221 == "floor" or v221 == "ground"
end
t1.value13.spawn(function()
    local v222 = t2.value7:FindFirstChild("Killfeed") or t2.value7:WaitForChild("Killfeed", 30)

    if not v222 then
        warn("[Nexus] Killfeed not found")

        return
    end

    v222.ChildAdded:Connect(function(child)
        task.defer(function()
            task.wait(0.05)

            if v53(child) then
                t9.value30()
            end

            if t9.value10.killfeedUI then
                local v1256, v1257 = t9.value40(child)

                if v1256 or v1257 then
                    t9.value48(v1256, v1257)
                end
            end
        end)
    end)
end)

function t1.value14()
    if t9.value1 then
        local v223 = t2.value9 and t2.value9.ViewportSize or Vector2.new(800, 600)

        return Vector2.new(v223.X * 0.5, v223.Y * 0.5)
    end

    local MouseLocation = t2.value3:GetMouseLocation()
    local GuiInset = t2.value5:GetGuiInset()

    return Vector2.new(MouseLocation.X - GuiInset.X, MouseLocation.Y - GuiInset.Y)
end
t1.value10 = {}
function t1.value13()
    if t9.value1 then
        local v226 = t2.value9 and t2.value9.ViewportSize or Vector2.new(800, 600)

        return Vector2.new(v226.X * 0.5, v226.Y * 0.5)
    end

    return t2.value3:GetMouseLocation()
end
function t1.value12()
    if t9.value1 or not t9.value10.freecam then
        return
    end
    local minimized = t9.value10.minimized
    local u228 = not minimized
    pcall(function()
        if u228 then
            t2.value3.MouseBehavior = Enum.MouseBehavior.Default
            t2.value3.MouseIconEnabled = true

            return
        end

        t2.value3.MouseBehavior = Enum.MouseBehavior.LockCenter
        t2.value3.MouseIconEnabled = false
    end)
end
function t1.value16(p23)
    if not p23 then
        return false
    end

    local raycastParams = RaycastParams.new()

    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local t15 = {}

    if t2.value8.Character then
        table.insert(t15, t2.value8.Character)
    end

    if p23.Parent then
        table.insert(t15, p23.Parent)
    end

    raycastParams.FilterDescendantsInstances = t15

    local CFramePosition = t2.value9.CFrame.Position
    local v233 = p23.Position - CFramePosition

    if v233.Magnitude < 0.5 then
        return true
    end

    return workspace:Raycast(CFramePosition, v233, raycastParams) == nil
end
t9.value49 = t1.value13
t9.value50 = t1.value14
function t1.value14()
    if t9.value10.freecam then
        return
    end

    t2.value9.CameraType = Enum.CameraType.Custom

    local v234 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

    if v234 then
        t2.value9.CameraSubject = v234
    end
end
function t1.value13()
    if t9.value10.freecamConn then
        pcall(function()
            t9.value10.freecamConn:Disconnect()
        end)
        t9.value10.freecamConn = nil
    end

    t9.value10.freecam = false
    t9.value10.freecamCF = nil
    pcall(function()
        t2.value3.MouseBehavior = Enum.MouseBehavior.Default
        t2.value3.MouseIconEnabled = true
    end)
    t2.value9.CameraType = Enum.CameraType.Custom

    local v235 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

    if v235 then
        t2.value9.CameraSubject = v235

        if t9.value10.walkSpeedOn then
            v235.WalkSpeed = t9.value10.walkSpeed
            v235.JumpHeight = t9.value10.jumpHeight
        else
            v235.WalkSpeed = 16
            v235.JumpHeight = 7.2
        end
    end

    if t9.value1 and t9.value22.setFlyPadVisible then
        t9.value22.setFlyPadVisible(t9.value10.fly == true)
    end

    if t9.value10.mobileKeys then
        for k in pairs(t9.value10.mobileKeys) do
            t9.value10.mobileKeys[k] = false
        end
    end
end
t9.value51 = t1.value14
function t1.value14()
    local Character = t2.value8.Character
    local v238 = Character and Character:FindFirstChildOfClass("Humanoid")
    local v239 = Character and Character:FindFirstChild("HumanoidRootPart")

    if v238 then
        v238.WalkSpeed = 0
        v238.JumpHeight = 0
        pcall(function()
            v238.JumpPower = 0
        end)
        v238:Move(Vector3.zero, false)
    end

    if v239 then
        v239.AssemblyLinearVelocity = Vector3.zero
        v239.AssemblyAngularVelocity = Vector3.zero
    end
end
t9.value52 = t1.value12
t9.value53 = t1.value14
function t1.value15()
    if t9.value10.freecamConn then
        pcall(function()
            t9.value10.freecamConn:Disconnect()
        end)
        t9.value10.freecamConn = nil
    end

    t9.value10.freecam = true

    if t9.value10.fly then
        t9.value10.fly = false
        pcall(stopFly)

        if t9.value16.Fly then
            pcall(function()
                t9.value16.Fly(false)
            end)
        end
    end

    t2.value9.CameraType = Enum.CameraType.Scriptable

    local value9CFrame = t2.value9.CFrame

    t9.value10.freecamCF = value9CFrame

    local LookVector = value9CFrame.LookVector

    t9.value10.freecamYaw = math.atan2(-LookVector.X, -LookVector.Z)
    t9.value10.freecamPitch = math.asin((math.clamp(LookVector.Y, -1, 1)))
    t9.value52()
    t9.value53()

    if t9.value1 and t9.value22.setFlyPadVisible then
        t9.value22.setFlyPadVisible(true)
    end

    t9.value10.freecamConn = t2.value2.RenderStepped:Connect(function(dt)
        if not t9.value10.freecam then
            return
        end

        t9.value53()
        t9.value52()

        local v819 = t9.value10.flySpeed or 50

        if t2.value3:IsKeyDown(Enum.KeyCode.LeftShift) then
            v819 *= 2
        end

        local minimized = t9.value10.minimized

        if not t9.value1 and not not minimized then
            local MouseDelta = t2.value3:GetMouseDelta()

            t9.value10.freecamYaw = t9.value10.freecamYaw - MouseDelta.X * 0.004
            t9.value10.freecamPitch = math.clamp(t9.value10.freecamPitch - MouseDelta.Y * 0.004, -1.4, 1.4)
        end

        local v822 = CFrame.Angles(0, t9.value10.freecamYaw, 0) * CFrame.Angles(t9.value10.freecamPitch, 0, 0)
        local v823 = t9.value10.freecamCF and t9.value10.freecamCF.Position or t2.value9.CFrame.Position
        local LookVector2 = v822.LookVector
        local RightVector = v822.RightVector
        local zero = Vector3.zero
        local v827 = t9.value10.mobileKeys or {}

        if t2.value3:IsKeyDown(Enum.KeyCode.W) or v827.W then
            zero += LookVector2
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.S) or v827.S then
            zero -= LookVector2
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.A) or v827.A then
            zero -= RightVector
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.D) or v827.D then
            zero += RightVector
        end

        local v828 = t2.value3:IsKeyDown(Enum.KeyCode.E)

        if not v828 then
            v828 = t2.value3:IsKeyDown(Enum.KeyCode.Space) or v827.Up
        end

        if v828 then
            zero += Vector3.yAxis
        end

        local v829 = t2.value3:IsKeyDown(Enum.KeyCode.Q)

        if not v829 then
            v829 = t2.value3:IsKeyDown(Enum.KeyCode.LeftControl) or v827.Down
        end

        if v829 then
            zero -= Vector3.yAxis
        end

        local v830 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

        if v830 then
            local MoveDirection = v830.MoveDirection

            if MoveDirection.Magnitude > 0.05 then
                zero += MoveDirection
            end
        end

        if zero.Magnitude > 0 then
            v823 += zero.Unit * v819 * dt
        end

        t9.value10.freecamCF = CFrame.new(v823) * v822
        t2.value9.CameraType = Enum.CameraType.Scriptable
        t2.value9.CFrame = t9.value10.freecamCF
    end)
end
function t1.value12(p24, p25)
    if not p24 then
        return
    end

    local GetDescendants = p24.GetDescendants

    for _, v in ipairs(GetDescendants(p24)) do
        if v:IsA("BasePart") then
            v.CanCollide = not p25
        end
    end
end
function t1.value14(p26)
    local v248, v249 = t2.value9:WorldToViewportPoint(p26)

    if not v249 or v248.Z < 0 then
        return false
    end

    return (Vector2.new(v248.X, v248.Y) - t9.value50()).Magnitude <= t9.value10.fovRadius
end
t9.value54 = t1.value13
t9.value55 = nil
function t1.value13(p27)
    if p27 then
        t9.value55()

        return
    end

    t9.value54()
end
t9.value56 = nil
t9.value55 = t1.value15
t9.value57 = t1.value13
function t1.value13(p28)
    local v252 = t9.value46[p28]

    if v252 then
        if v252.gui then
            pcall(function()
                v252.gui:Destroy()
            end)
        end

        if v252.conn then
            pcall(function()
                v252.conn:Disconnect()
            end)
        end

        t9.value46[p28] = nil
    end
end
t9.value58 = t1.value4
t9.value59 = nil
function t9.value60(p29)
    local v94 = string.lower((t9.value10.aimName or ""):gsub("^%s+", ""):gsub("%s+$", ""))

    if v94 == "" then
        return true
    end

    local v95 = string.lower(p29.Name)
    local v96 = p29.DisplayName and string.lower(p29.DisplayName) or ""
    local v97 = v95 == v94

    if not v97 then
        v97 = v96 == v94 or (string.find(v95, v94, 1, true) or string.find(v96, v94, 1, true))
    end

    return v97
end
t9.value61 = t1.value11
local function v54(p30)
    if string.lower((t9.value10.aimName or ""):gsub("^%s+", ""):gsub("%s+$", "")) ~= "" then
        return t9.value60(p30)
    end

    if not t9.value61() then
        return true
    end

    if not p30.Team then
        return false
    end

    local TeamName = p30.Team.Name
    local aimTeams = t9.value10.aimTeams

    if aimTeams.Prisoners and TeamName == "Inmates" then
        return true
    end

    if aimTeams.Criminals and TeamName == "Criminals" then
        return true
    end

    if aimTeams.Police and TeamName == "Guards" then
        return true
    end

    return false
end
t9.value62 = t1.value14
t9.value63 = t1.value16
function t9.value64(p31)
    local v121 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")
    local v122 = p31 and (p31.Character and p31.Character:FindFirstChild("HumanoidRootPart"))

    if not v121 or not v122 then
        return 1e999
    end

    return (v122.Position - v121.Position).Magnitude
end
function t9.value65(p32, p33, p34)
    local v259 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")
    if not v259 then
        return
    end
    local n2 = 1e999
    local v261
    for _, player in ipairs(t2.value1:GetPlayers()) do
        if player ~= t2.value8 and (player.Character and (player.Character:FindFirstChild("HumanoidRootPart") and t9.value58(player))) then
            local Head = player.Character:FindFirstChild("Head")
            local v265 = Head ~= nil

            if v265 and (p32 and not v54(player)) then
                v265 = false
            end

            if v265 and (not not p33 and not t9.value62(Head.Position)) or not t9.value63(Head) then
                v265 = false
            end

            if v265 then
                local Magnitude = (player.Character.HumanoidRootPart.Position - v259.Position).Magnitude

                if (not p34 or not (p34 < Magnitude)) and Magnitude < n2 then
                    v261 = player
                    n2 = Magnitude
                end
            end
        end
    end

    return v261
end
t9.value66 = t1.value8
t9.value67 = t1.value2
function t1.value2(p35, p36)
    local function v272(p37)
        if not p37 then
            return false
        end

        for _, child in ipairs(p37:GetChildren()) do
            if child:IsA("Tool") and string.find(string.lower(child.Name), p36) then
                return true
            end
        end
    end

    p36 = string.lower(p36)

    return v272(p35:FindFirstChild("Backpack")) or p35.Character and v272(p35.Character)
end
t9.value68 = t1.value3
function t9.value69(p38)
    local v100 = t9.value23[p38]

    if v100 and v100.conn then
        pcall(function()
            v100.conn:Disconnect()
        end)
    end

    t9.value23[p38] = nil
end
t9.value46 = {}
t9.value70 = nil
function t1.value2(p39, p40)
    if not t9.value10.dmgMarkers or p40 <= 0 then
        return
    end

    local Character = p39.Character

    if not Character then
        return
    end

    local v276 = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")

    if not v276 then
        return
    end

    local function v277(p41)
        local BillboardGui = Instance.new("BillboardGui")

        BillboardGui.Name = "NexusDmg"
        BillboardGui.AlwaysOnTop = true
        BillboardGui.Size = UDim2.new(0, 80, 0, 40)
        BillboardGui.StudsOffset = Vector3.new(-1.5, 2.8, 0)
        BillboardGui.Adornee = v276
        BillboardGui.Parent = v276

        local TextLabel = Instance.new("TextLabel")

        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = p41
        TextLabel.TextColor3 = t9.value9.Accent
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.TextStrokeTransparency = 0
        TextLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        TextLabel.Parent = BillboardGui

        local UIStroke = Instance.new("UIStroke")

        UIStroke.Thickness = 2
        UIStroke.Color = Color3.new(0, 0, 0)
        UIStroke.Parent = TextLabel

        return BillboardGui, TextLabel
    end

    local CurrentCamera = workspace.CurrentCamera
    local v279 = CurrentCamera and (CurrentCamera.CFrame.Position - v276.Position).Magnitude or 20
    local v280 = math.clamp(math.floor(10 + v279 * 0.25 + 0.5), 11, 40)

    if t9.value10.dmgStack then
        local v281 = t9.value46[p39]

        if v281 and (v281.gui and v281.gui.Parent) then
            v281.total = v281.total + p40
            v281.label.Text = tostring((math.floor(v281.total + 0.5)))
            v281.label.TextSize = v280
            v281.label.TextColor3 = t9.value9.Accent
            v281.expire = tick() + 1.6

            return
        end

        t9.value70(p39)

        local v282, v283 = v277((tostring((math.floor(p40 + 0.5)))))

        v283.TextSize = v280

        local value46 = t9.value46
        local v285 = tick() + 1.6

        value46[p39] = {
			gui = v282,
			label = v283,
			total = p40,
			expire = v285
		}
        task.spawn(function()
            while t9.value46[p39] do
                local v839 = t9.value46[p39]

                if tick() >= v839.expire then
                    t9.value70(p39)

                    return
                end

                task.wait(0.1)
            end
        end)

        return
    end

    local v286, v287 = v277((tostring((math.floor(p40 + 0.5)))))
    local v288 = v286
    local v289 = v287

    v289.TextSize = v280
    task.delay(1.2, function()
        if v288 and v288.Parent then
            t2.value4:Create(v289, TweenInfo.new(0.25), {
				TextTransparency = 1
			}):Play()
            task.delay(0.3, function()
                pcall(function()
                    v288:Destroy()
                end)
            end)
        end
    end)
end
t9.value70 = t1.value13
t9.value71 = nil
function t1.value3(p42)
    t9.value69(p42)

    local Character = p42.Character

    if not Character then
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return
    end

    local Health = Humanoid.Health
    local connection = Humanoid.HealthChanged:Connect(function(p43)
        local v841 = Health
        local v842 = p43 < Health
        local v843 = v841 - p43

        Health = p43

        if not v842 then
            return
        end

        local lastHeadShot = t9.value10.lastHeadShot

        if lastHeadShot and (lastHeadShot.plr == p42 and tick() - lastHeadShot.t <= 0.75) then
            t9.value31()
            t9.value10.lastHeadShot = nil
        end

        if t9.value10.dmgMarkers and (p42 ~= t2.value8 and tick() - (t9.value10.lastShotAt or 0) <= 0.9) then
            t9.value71(p42, v843)
        end
    end)
    local value23 = t9.value23
    local v296 = Health

    value23[p42] = {
		hum = Humanoid,
		conn = connection,
		lastHp = v296
	}
end
t9.value71 = t1.value2
t9.value72 = t1.value3
function t1.value3(p44)
    t9.value10.invisible = not not p44

    local Character = t2.value8.Character

    if not Character then
        return
    end

    for _, descendant in ipairs(Character:GetDescendants()) do
        if descendant:IsA("BasePart") or (descendant:IsA("Decal") or descendant:IsA("Texture")) then
            pcall(function()
                if descendant:IsA("BasePart") then
                    descendant.LocalTransparencyModifier = not p44 and 0 or 1

                    return
                end

                if descendant:IsA("Decal") or descendant:IsA("Texture") then
                    if p44 then
                        if descendant:GetAttribute("NexusOldTrans") == nil then
                            descendant:SetAttribute("NexusOldTrans", descendant.Transparency)
                        end

                        descendant.Transparency = 1

                        return
                    end

                    local NexusOldTrans = descendant:GetAttribute("NexusOldTrans")

                    descendant.Transparency = typeof(NexusOldTrans) == "number" and NexusOldTrans or 0
                end
            end)
        end

        if descendant:IsA("ParticleEmitter") or (descendant:IsA("Trail") or descendant:IsA("Beam")) then
            pcall(function()
                descendant.Enabled = not p44
            end)
        end
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        pcall(function()
            Humanoid.NameDisplayDistance = not p44 and 100 or 0
        end)
    end
end
t9.value56 = t1.value10
t9.value73 = nil
function t1.value2()
    if t9.value35 then
        pcall(function()
            t9.value35:Disconnect()
        end)
        t9.value35 = nil
    end

    if t9.value59 then
        pcall(function()
            t9.value59:Destroy()
        end)
        t9.value59 = nil
    end
end
t9.value74 = 0.4
function t9.value75(p45)
    local Character = t2.value8.Character

    return Character and p45:IsDescendantOf(Character)
end
local function v55(p46)
    if not p46:IsA("BasePart") then
        return
    end

    if t9.value75(p46) then
        return
    end

    if t9.value56[p46] == nil then
        t9.value56[p46] = p46.Transparency
    end

    pcall(function()
        p46.Transparency = t9.value74
    end)
end
function t9.value76(p47)
    local v268 = t9.value56[p47]

    if v268 == nil then
        return
    end

    pcall(function()
        if p47.Parent then
            p47.Transparency = v268
        end
    end)
    t9.value56[p47] = nil
end
local function v56(p48)
    t9.value10.xray = not not p48

    if t9.value73 then
        pcall(function()
            t9.value73:Disconnect()
        end)
        t9.value73 = nil
    end

    if p48 then
        for _, descendant in ipairs(workspace:GetDescendants()) do
            v55(descendant)
        end

        workspace.DescendantAdded:Connect(function(descendant)
            if not t9.value10.xray then
                return
            end

            task.defer(function()
                v55(descendant)
            end)
        end)

        return
    end

    for k in pairs(t9.value56) do
        t9.value76(k)
    end

    table.clear(t9.value56)
end
t9.value77 = t1.value9
function t9.value78()
    local v98 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

    if v98 and v98.JumpHeight ~= t9.value10.jumpHeight then
        v98.JumpHeight = t9.value10.jumpHeight
    end
end
function t9.value79()
    if t9.value10.speedConn then
        t9.value10.speedConn:Disconnect()
    end

    t9.value10.speedConn = t2.value2.Heartbeat:Connect(function()
        t9.value77()
        t9.value78()
    end)
end
t9.value80 = t1.value1
t9.value81 = nil
t9.value81 = t1.value12
function t9.value82(p49)
    if t2.value8.Character then
        for _, descendant in ipairs(t2.value8.Character:GetDescendants()) do
            if descendant:IsA("BasePart") then
                descendant.CanCollide = not p49
            end
        end
    end

    if t9.value10.vehicle then
        t9.value81(t9.value10.vehicle, p49)
    end
end
t9.value83 = t1.value7
function t9.value84()
    if not t9.value10.worldNoclip then
        return
    end

    local Character = t2.value8.Character

    if not Character then
        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not HumanoidRootPart then
        return
    end

    if Humanoid.Sit or Humanoid.SeatPart then
        return
    end

    local MoveDirection = Humanoid.MoveDirection

    if MoveDirection.Magnitude < 0.15 then
        return
    end

    local vector3 = Vector3.new(MoveDirection.X, 0, MoveDirection.Z)

    if vector3.Magnitude < 0.15 then
        return
    end

    local Unit = vector3.Unit
    local raycastParams = RaycastParams.new()

    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { Character }
    raycastParams.IgnoreWater = true

    local raycastResult = workspace:Raycast(HumanoidRootPart.Position, Unit * 2.2, raycastParams)

    if not raycastResult or not raycastResult.Instance then
        return
    end

    if t9.value83(raycastResult.Instance) then
        return
    end

    if raycastResult.Normal.Y > 0.45 then
        return
    end

    local n3 = 0.6
    local v319 = raycastResult.Position + Unit * 0.35
    local n4 = 0.35
    local raycastResultPosition = raycastResult.Position

    while n4 < 14 do
        local raycastResult2 = workspace:Raycast(v319, Unit * n3, raycastParams)
        local v323 = raycastResult2

        if raycastResult2 then
            v323 = raycastResult2.Instance and (not t9.value83(raycastResult2.Instance) and raycastResult2.Normal.Y <= 0.45)
        end

        if not v323 then
            local v324 = (raycastResult2 and raycastResult2.Position or v319 + Unit * n3) + Unit * 1.25
            local vector3_2 = Vector3.new(v324.X, HumanoidRootPart.Position.Y, v324.Z)
            local raycastResult3 = workspace:Raycast(vector3_2 - Unit * 0.5, Unit * 0.75, raycastParams)

            if raycastResult3 and (raycastResult3.Normal.Y <= 0.45 and not t9.value83(raycastResult3.Instance)) then
                local v327 = raycastResultPosition + Unit * 2

                vector3_2 = Vector3.new(v327.X, HumanoidRootPart.Position.Y, v327.Z)
            end

            HumanoidRootPart.CFrame = CFrame.new(vector3_2) * (HumanoidRootPart.CFrame - HumanoidRootPart.Position)

            return
        end

        raycastResultPosition = raycastResult2.Position
        v319 = raycastResult2.Position + Unit * 0.2
        n4 += 0.2
    end
end
function t1.value1(p50)
    t9.value10.worldNoclip = not not p50

    if t9.value10.worldNoclipConn then
        pcall(function()
            t9.value10.worldNoclipConn:Disconnect()
        end)
        t9.value10.worldNoclipConn = nil
    end

    if p50 then
        t9.value10.worldNoclipConn = t2.value2.Heartbeat:Connect(function()
            t9.value84()
        end)
    end
end
t9.value85 = t1.value1
t9.value86 = t1.value5
function t1.value1()
    local Character = t2.value8.Character
    if not Character then
        return
    end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HumanoidRootPart then
        return
    end
    local Model
    local SeatPart = Humanoid.SeatPart
    local AssemblyRootPart
    if SeatPart and SeatPart:IsA("VehicleSeat") or SeatPart:IsA("Seat") then
        AssemblyRootPart = SeatPart.AssemblyRootPart
        Model = SeatPart:FindFirstAncestorOfClass("Model")

        if not AssemblyRootPart and Model then
            AssemblyRootPart = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart")
        end
    end
    local value10 = t9.value10
    local value10_2 = t9.value10
    value10.flyTarget = AssemblyRootPart or HumanoidRootPart
    value10_2.vehicle = Model
    Humanoid.PlatformStand = true
    t9.value82(true)
    if t9.value10.noclipConn then
        t9.value10.noclipConn:Disconnect()
    end
    t9.value10.noclipConn = t2.value2.Stepped:Connect(function()
        if t9.value10.fly then
            t9.value82(true)
        end
    end)
    if t9.value10.bv then
        t9.value10.bv:Destroy()
    end
    if t9.value10.bg then
        t9.value10.bg:Destroy()
    end
    t9.value10.bv = Instance.new("BodyVelocity")
    t9.value10.bv.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
    t9.value10.bv.Velocity = Vector3.zero
    t9.value10.bv.Parent = t9.value10.flyTarget
    t9.value10.bg = Instance.new("BodyGyro")
    t9.value10.bg.MaxTorque = Vector3.new(1000000000, 1000000000, 1000000000)
    t9.value10.bg.P = 10000
    t9.value10.bg.Parent = t9.value10.flyTarget
    if t9.value10.flyConn then
        t9.value10.flyConn:Disconnect()
    end
    t9.value10.flyConn = t2.value2.RenderStepped:Connect(function()
        if not t9.value10.fly or (not t9.value10.bv or not t9.value10.bg) then
            return
        end

        local value9CFrame = t2.value9.CFrame
        local zero = Vector3.zero
        local v849 = t9.value10.mobileKeys or {}

        if t2.value3:IsKeyDown(Enum.KeyCode.W) or v849.W then
            zero += value9CFrame.LookVector
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.S) or v849.S then
            zero -= value9CFrame.LookVector
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.A) or v849.A then
            zero -= value9CFrame.RightVector
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.D) or v849.D then
            zero += value9CFrame.RightVector
        end

        if t2.value3:IsKeyDown(Enum.KeyCode.Space) or v849.Up then
            zero += Vector3.yAxis
        end

        local v850 = t2.value3:IsKeyDown(Enum.KeyCode.LeftControl)

        if not v850 then
            v850 = t2.value3:IsKeyDown(Enum.KeyCode.LeftShift) or v849.Down
        end

        if v850 then
            zero -= Vector3.yAxis
        end

        if zero.Magnitude > 0 then
            zero = zero.Unit * t9.value10.flySpeed
        end

        local bv = t9.value10.bv
        local bg = t9.value10.bg

        bv.Velocity = zero
        bg.CFrame = value9CFrame
    end)
    if t9.value1 and t9.value22.setFlyPadVisible then
        t9.value22.setFlyPadVisible(true)
    end
end
t9.value87 = t1.value1
function t9.value88()
    if t9.value10.flyConn then
        t9.value10.flyConn:Disconnect()
        t9.value10.flyConn = nil
    end

    if t9.value10.noclipConn then
        t9.value10.noclipConn:Disconnect()
        t9.value10.noclipConn = nil
    end

    if t9.value10.bv then
        t9.value10.bv:Destroy()
        t9.value10.bv = nil
    end

    if t9.value10.bg then
        t9.value10.bg:Destroy()
        t9.value10.bg = nil
    end

    t9.value82(false)

    if t9.value10.vehicle then
        t9.value81(t9.value10.vehicle, false)
    end

    local value10 = t9.value10
    local value10_3 = t9.value10

    value10.flyTarget = nil
    value10_3.vehicle = nil

    local v331 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

    if v331 then
        v331.PlatformStand = false
    end

    if t9.value1 and t9.value22.setFlyPadVisible then
        t9.value22.setFlyPadVisible(false)
    end

    if t9.value10.mobileKeys then
        for k in pairs(t9.value10.mobileKeys) do
            t9.value10.mobileKeys[k] = false
        end
    end
end
t9.value35 = nil
t9.value59 = nil
t9.value89 = 50
t9.value90 = t1.value2
function t9.value91()
    t9.value90()

    local Character = t2.value8.Character
    local v342 = Character and Character:FindFirstChild("HumanoidRootPart")

    if not v342 then
        return
    end

    local BodyAngularVelocity = Instance.new("BodyAngularVelocity")

    BodyAngularVelocity.Name = "NexusSpinbot"
    BodyAngularVelocity.MaxTorque = Vector3.new(0, 1e999, 0)
    BodyAngularVelocity.AngularVelocity = Vector3.new(0, t9.value89, 0)
    BodyAngularVelocity.P = 1250
    BodyAngularVelocity.Parent = v342
    t9.value59 = BodyAngularVelocity
    t2.value2.Heartbeat:Connect(function()
        if not t9.value10.spinbot then
            return
        end

        local v853 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")

        if not v853 then
            return
        end

        if not t9.value59 or v853 ~= t9.value59.Parent then
            if t9.value59 then
                pcall(function()
                    t9.value59:Destroy()
                end)
            end

            local BodyAngularVelocity2 = Instance.new("BodyAngularVelocity")

            BodyAngularVelocity2.Name = "NexusSpinbot"
            BodyAngularVelocity2.MaxTorque = Vector3.new(0, 1e999, 0)
            BodyAngularVelocity2.AngularVelocity = Vector3.new(0, t9.value89, 0)
            BodyAngularVelocity2.P = 1250
            BodyAngularVelocity2.Parent = v853
            t9.value59 = BodyAngularVelocity2

            return
        end

        t9.value59.AngularVelocity = Vector3.new(0, t9.value89, 0)
    end)
end
function t9.value92(p51)
    t9.value10.spinbot = not not p51

    if p51 then
        t9.value91()

        return
    end

    t9.value90()
end
pcall(t1.value6)
t9.value93 = nil
t1.value6 = Vector3.new(2, 2, 1)
t9.value94 = t1.value6
pcall(function()
    local v345 = getrawmetatable(game)

    setreadonly(v345, false)

    local __index = v345.__index

    function v345.__index(p52, p53)
        local hbe = t9.value10.hbe

        if hbe then
            hbe = p53 == "Size"

            if hbe then
                hbe = typeof(p52) == "Instance" and (p52:IsA("BasePart") and p52.Name == "HumanoidRootPart")
            end
        end

        if hbe then
            local p52Parent = p52.Parent

            if p52Parent and p52Parent:FindFirstChildOfClass("Humanoid") then
                local player = t2.value1:GetPlayerFromCharacter(p52Parent)

                if player and player ~= t2.value8 then
                    return t9.value94
                end
            end
        end

        return __index(p52, p53)
    end

    setreadonly(v345, true)
end)

function t1.value2(p54)
    if not p54 or p54 == t2.value8 then
        return
    end

    local Character = p54.Character
    local v349 = Character and Character:FindFirstChild("HumanoidRootPart")

    if not v349 then
        return
    end

    local v350 = t9.value10.hbeSize or 15
    local v351 = t9.value9.Accent or Color3.fromRGB(255, 0, 0)

    pcall(function()
        v349.Size = Vector3.new(v350, v350, v350)
        v349.Color = v351
        v349.CanCollide = false
        v349.Transparency = 0.5
    end)
end
function t9.value95(p55)
    local v353 = p55 and p55.Character
    local v354 = v353 and v353:FindFirstChild("HumanoidRootPart")

    if v354 then
        pcall(function()
            v354.Size = t9.value94
            v354.Transparency = 1
            v354.CanCollide = false
        end)
    end
end
t9.value96 = t1.value2
function t9.value97()
    if t9.value93 then
        pcall(function()
            t9.value93:Disconnect()
        end)
        t9.value93 = nil
    end

    pcall(function()
        getgenv().HBE = false
    end)

    for _, player in ipairs(t2.value1:GetPlayers()) do
        if player ~= t2.value8 then
            t9.value95(player)
        end
    end
end
function t9.value98()
    t9.value97()
    pcall(function()
        getgenv().HBE = true
    end)
    t2.value2.RenderStepped:Connect(function()
        if not t9.value10.hbe then
            return
        end

        for _, player in ipairs(t2.value1:GetPlayers()) do
            if player ~= t2.value8 then
                t9.value96(player)
            end
        end
    end)
end
function t1.value1(p56)
    t9.value10.hbe = not not p56

    if p56 then
        t9.value98()

        return
    end

    t9.value97()
end
t9.value99 = t1.value1
t9.value100 = nil
t9.value101 = nil
local vector2 = Vector2.new(0, 384)

t1.value1 = {
	Damage = 11,
	MaxAmmo = 25,
	FireRate = 0.04,
	AutoFire = true,
	Range = 1100,
	AccurateRange = 155,
	ReloadTime = 2,
	ShootSoundId = "rbxassetid://7698730413",
	SecondarySoundId = nil,
	ReloadSoundId = "http://www.roblox.com/asset/?id=2934887229",
	SlotType = "Primary",
	Icon = "rbxassetid://93481383611512",
	ImageRectOffset = vector2
}
t9.value102 = t1.value1
function t1.value2()
    local Character = t2.value8.Character

    if not Character then
        return false
    end

    for _, child in ipairs(Character:GetChildren()) do
        if child:IsA("Tool") then
            return true
        end
    end

    return false
end
function t1.value1()
    if not t9.value10.cameraLock or #t9.value11 == 0 then
        return
    end

    local v366 = t9.value11[t9.value10.targetIndex]
    local v367 = v366 and (v366.Character and v366.Character:FindFirstChild("HumanoidRootPart"))
    local v368 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")

    if not v367 or not v368 then
        return
    end

    if t9.value10.tween then
        t9.value10.tween:Cancel()
        t9.value10.tween = nil
    end

    t9.value10.tween = t2.value4:Create(v368, TweenInfo.new(t9.value3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = v367.CFrame * CFrame.new(0, 3, 0)
	})
    t9.value10.tween:Play()
    t9.value10.tween.Completed:Connect(function()
        t9.value10.tween = nil
    end)
end
function t9.value103()
    local ok12, result12 = pcall(function()
        local SharedModules = t2.value7:FindFirstChild("SharedModules")
        local v863 = SharedModules and SharedModules:FindFirstChild("ToolProperties")
        local v864 = v863 and v863:FindFirstChild("MP5")

        if not v864 then
            return nil
        end

        return require(v864)
    end)

    if ok12 then
        ok12 = type(result12) == "table"
    end

    if ok12 then
        return result12
    end

    return nil
end
function t1.value3()
    local v369 = t9.value103()

    if not v369 then
        return false
    end

    if not t9.value100 then
        t9.value100 = {}

        for k, v in pairs(v369) do
            t9.value100[k] = v
        end
    end

    for k, v in pairs(t9.value102) do
        v369[k] = v
    end

    return true
end
t9.value104 = t1.value3
function t1.value3()
    local v377 = t9.value103()

    if v377 and t9.value100 then

        for v380, v381 in pairs(t9.value100) do

            v377[v380] = v381
        end
        for k in pairs(t9.value102) do
            local v383 = k

            if t9.value100[v383] == nil then
                v377[v383] = nil
            end
        end
    end
end
t9.value105 = t1.value3
function t1.value3(p57)
    if p57 == nil then
        return false
    end

    local v385 = typeof(p57)

    if v385 == "Vector3" or v385 == "vector" then
        return true
    end

    return pcall(function()
        return p57.X, p57.Y, p57.Z
    end) and typeof(p57.X) == "number"
end
function t1.value4(p58)
    local v391 = workspace:FindFirstChild(p58, true) or game:FindFirstChild(p58, true)

    if not v391 then
        return
    end

    if v391:IsA("BasePart") or v391:IsA("SpawnLocation") then
        return v391.CFrame
    end

    if v391:IsA("Model") then
        local v392 = v391.PrimaryPart or v391:FindFirstChildWhichIsA("BasePart", true)

        if v392 then
            return v392.CFrame
        end
    end

    if v391:IsA("Folder") or v391:IsA("Configuration") then
        local BasePart = v391:FindFirstChildWhichIsA("BasePart", true)

        if BasePart then
            return BasePart.CFrame
        end
    end
end
function t1.value5(p59, p60, p61)
    if not p60 then
        p60 = Vector3.new(0, 0, 3)
    end

    local Character = t2.value8.Character

    if Character then
        Character = t2.value8.Character:FindFirstChild("HumanoidRootPart")
    end

    if not Character then
        return
    end

    local cFrame

    if p61 then
        cFrame = CFrame.new(p61)
    else
        local v399 = workspace:FindFirstChild("Prison_ITEMS") and workspace.Prison_ITEMS:FindFirstChild("giver")
        local v400 = v399 and v399:FindFirstChild(p59)

        if not v400 then
            return
        end

        local v401 = v400:IsA("BasePart") and v400 or (v400.PrimaryPart or v400:FindFirstChildWhichIsA("BasePart", true))

        if not v401 then
            return
        end

        cFrame = v401.CFrame * CFrame.new(p60)
    end

    if t9.value10.tween then
        t9.value10.tween:Cancel()
        t9.value10.tween = nil
    end

    local CharacterCFrame = Character.CFrame
    local v403 = t2.value4:Create(Character, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {
		CFrame = cFrame
	})

    t9.value10.tween = v403
    v403:Play()
    v403.Completed:Wait()
    t9.value10.tween = nil

    local timestamp = tick()

    while true do
        local v405 = not (function()
            local function v865(p62)
                if not p62 then
                    return false
                end

                if p62:FindFirstChild(p59) then
                    return true
                end

                local GetChildren = p62.GetChildren

                for _, v in ipairs(GetChildren(p62)) do
                    if v:IsA("Tool") and string.find(string.lower(v.Name), string.lower(p59), 1, true) then
                        return true
                    end
                end
            end

            return v865(t2.value8:FindFirstChild("Backpack")) or v865(t2.value8.Character)
        end)()

        if v405 then
            v405 = tick() - timestamp < 8
        end

        if not v405 then
            break
        end

        if Character.Parent then
            Character.CFrame = cFrame
        end

        task.wait(0.05)
    end

    if Character.Parent then
        local v406 = t2.value4:Create(Character, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {
			CFrame = CharacterCFrame
		})

        t9.value10.tween = v406
        v406:Play()
        v406.Completed:Connect(function()
            t9.value10.tween = nil
        end)
    end
end
local function v58(p63)
    t9.value10.mp5Mod = not not p63

    if t9.value101 then
        pcall(function()
            t9.value101:Disconnect()
        end)
        t9.value101 = nil
    end

    if p63 then
        t9.value104()
        task.spawn(function()
            while t9.value10.mp5Mod do
                t9.value104()
                task.wait(0.5)
            end
        end)

        return
    end

    t9.value105()
end
t9.value106 = nil
t9.value107 = 100
t9.value108 = 0
function t9.value109()
    local Character = t2.value8.Character

    if not Character then
        return false
    end

    for _, child in ipairs(Character:GetChildren()) do
        if child:IsA("Tool") and string.find(string.lower(child.Name), "handcuff", 1, true) then
            return true
        end
    end

    return false
end
t9.value110 = nil
function t1.value6()
    if not t9.value10.longArrest then
        return
    end

    if not t9.value109() then
        return
    end

    if tick() - t9.value108 < 0.35 then
        return
    end

    local v420 = t9.value110()

    if not v420 then
        return
    end

    tick()
    pcall(function()
        local Remotes = t2.value7:FindFirstChild("Remotes")
        local v869 = Remotes and Remotes:FindFirstChild("ArrestPlayer")

        if v869 then
            if v869:IsA("RemoteFunction") then
                v869:InvokeServer(v420, 1)

                return
            end

            if v869:IsA("RemoteEvent") then
                v869:FireServer(v420, 1)
            end
        end
    end)
end
function t9.value110()
    local v413 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")
    if not v413 then
        return nil
    end
    local function v414(p64)
        if not p64 or (p64 == t2.value8 or not p64.Parent) then
            return false
        end

        if not t9.value58(p64) then
            return false
        end

        local v867 = p64.Character and p64.Character:FindFirstChild("HumanoidRootPart")

        if not v867 then
            return false
        end

        return (v867.Position - v413.Position).Magnitude <= t9.value107
    end
    if t9.value10.silentTarget and v414(t9.value10.silentTarget) then
        return t9.value10.silentTarget
    end
    local value107 = t9.value107
    local v416
    for _, player in ipairs(t2.value1:GetPlayers()) do
        if v414(player) and v54(player) then
            local Magnitude = (player.Character.HumanoidRootPart.Position - v413.Position).Magnitude

            if Magnitude < value107 then
                v416 = player
                value107 = Magnitude
            end
        end
    end

    return v416
end
t9.value111 = t1.value6
t9.value112 = nil
function t1.value6(p65, p66, p67)
    local v424 = p66 or 0
    local value8 = t2.value8
    local v426 = p67 or 0
    local v427 = value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")
    local v428 = t9.value112(p65)

    if not v427 or not v428 then
        return
    end

    if t9.value10.tween then
        t9.value10.tween:Cancel()
        t9.value10.tween = nil
    end

    local v429 = v428.Position + Vector3.new(0, v424, 0) + v428.RightVector * -v426
    local cFrame = CFrame.new(v429, v429 + v427.CFrame.LookVector)

    t9.value10.tween = t2.value4:Create(v427, TweenInfo.new(t9.value3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = cFrame
	})
    t9.value10.tween:Play()
    t9.value10.tween.Completed:Connect(function()
        t9.value10.tween = nil
    end)
end
t9.value112 = t1.value4
t9.value113 = t1.value6
function t9.value114(p68)
    local v387 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")

    if not v387 then
        return
    end

    if t9.value10.tween then
        t9.value10.tween:Cancel()
        t9.value10.tween = nil
    end

    local cFrame = CFrame.new(p68, p68 + v387.CFrame.LookVector)

    t9.value10.tween = t2.value4:Create(v387, TweenInfo.new(t9.value3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = cFrame
	})
    t9.value10.tween:Play()
    t9.value10.tween.Completed:Connect(function()
        t9.value10.tween = nil
    end)
end
t9.value115 = t1.value1
t9.value116 = t1.value5
function t9.value117()
    if t9.value10.silentHL then
        pcall(function()
            t9.value10.silentHL:Destroy()
        end)
        t9.value10.silentHL = nil
    end

    t9.value10.silentTarget = nil
end
function t1.value1()
    if not t9.value10.silentAim then
        t9.value117()

        return
    end

    local v431 = t9.value10.silentRangeOn and t9.value10.silentMaxRange or nil
    local v432 = t9.value65(true, true, v431)

    if not v432 or (not v432.Character or not t9.value58(v432)) then
        t9.value117()

        return
    end

    if v432 == t9.value10.silentTarget and (t9.value10.silentHL and t9.value10.silentHL.Parent == v432.Character) then
        t9.value10.silentHL.FillColor = t9.value9.Accent
        t9.value10.silentHL.OutlineColor = t9.value9.Accent

        return
    end

    t9.value117()
    t9.value10.silentTarget = v432

    local Highlight = Instance.new("Highlight")

    Highlight.Name = "NexusSilentAimTarget"
    Highlight.DepthMode = t9.value2
    Highlight.FillTransparency = 0.45
    Highlight.OutlineTransparency = 0
    Highlight.FillColor = t9.value9.Accent
    Highlight.OutlineColor = t9.value9.Accent
    Highlight.Parent = v432.Character
    t9.value10.silentHL = Highlight
end
t9.value118 = t1.value1
function t1.value1()
    if type(mouse1click) == "function" then
        mouse1click()

        return true, "mouse1click"
    end

    if type(mouse1press) == "function" then
        mouse1press()

        if type(mouse1release) == "function" then
            task.delay(0.03, function()
                pcall(mouse1release)
            end)
        end

        return true, "mouse1press"
    end

    local ok13, result13 = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    local v441 = result13

    if ok13 then
        ok13 = v441
    end

    if ok13 then
        local MouseLocation = t2.value3:GetMouseLocation()

        v441:SendMouseButtonEvent(MouseLocation.X, MouseLocation.Y, 0, true, game, 1)
        task.delay(0.03, function()
            pcall(function()
                v441:SendMouseButtonEvent(MouseLocation.X, MouseLocation.Y, 0, false, game, 1)
            end)
        end)

        return true, "VirtualInputManager"
    end

    return false, "no mouse click API found"
end
function t1.value4(p69)
    local timestamp = tick()

    if timestamp - t9.value106 < 2 then
        return
    end

    t9.value106 = timestamp
    warn("[Nexus Triggerbot] " .. tostring(p69))
end
function t9.value119()
    if not t9.value10.silentAim then
        return nil
    end

    local silentTarget = t9.value10.silentTarget

    if not silentTarget or not silentTarget.Parent then
        return nil
    end

    local Character = silentTarget.Character

    if not Character or (not t9.value58(silentTarget) or not v54(silentTarget)) then
        return nil
    end

    if t9.value10.silentRangeOn and t9.value64(silentTarget) > (t9.value10.silentMaxRange or 1000) then
        return nil
    end

    local Head = Character:FindFirstChild("Head")

    if not Head then
        return nil
    end

    if not t9.value62(Head.Position) then
        return nil
    end

    if t9.value10.legit then
        return t9.value67(Character) or Head
    end

    return Head
end
t9.value120 = t1.value2
function t9.value121()
    if t9.value10.silentAim then
        local v445 = t9.value119()

        if v445 and t9.value63(v445) then
            return v445
        end
    end
    local v446 = t9.value10.silentRangeOn and t9.value10.silentMaxRange
    local value8 = t2.value8
    local v448 = v446 or nil
    local v449 = value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")
    if not v449 then
        return nil
    end
    local n5 = 1e999
    local v451
    for _, player in ipairs(t2.value1:GetPlayers()) do
        if player ~= t2.value8 and (t9.value58(player) and (v54(player) and player.Character)) then
            local Head = player.Character:FindFirstChild("Head")
            local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

            if Head and (HumanoidRootPart and t9.value62(Head.Position)) then
                if t9.value10.legit then
                    Head = t9.value67(player.Character) or Head
                end

                if Head and t9.value63(Head) then
                    local v456 = v448
                    local Magnitude = (HumanoidRootPart.Position - v449.Position).Magnitude

                    if v448 then
                        v456 = v448 < Magnitude
                    end

                    if not v456 and Magnitude < n5 then
                        v451 = Head
                        n5 = Magnitude
                    end
                end
            end
        end
    end

    return v451
end
function t1.value2(p70)
    if typeof(p70) == "Instance" and p70:IsA("BasePart") then
        p70 = p70.Position
    end

    if typeof(p70) ~= "Vector3" then
        p70 = Vector3.new(p70.X or 0, p70.Y or 0, p70.Z or 0)
    end

    if type(vector) == "table" and type(vector.create) == "function" then
        return vector.create(p70.X, p70.Y, p70.Z)
    end

    return p70
end
t9.value106 = 0
t9.value122 = t1.value4
t9.value123 = nil
function t1.value2()
    if not t9.value10.triggerbot then
        return
    end
    if not t9.value10.minimized then
        return
    end
    if t9.value22.MainFrame and t9.value22.MainFrame.Visible then
        return
    end
    if not t9.value120() then
        return
    end
    local v464 = t9.value121()
    if not v464 then
        return
    end
    if not t9.value63(v464) then
        return
    end
    local timestamp = tick()
    if timestamp - (t9.value10.lastTriggerShot or 0) < 0.004 then
        return
    end
    t9.value10.lastTriggerShot = timestamp
    local success, result, v467 = pcall(t9.value123)
    if not success then
        t9.value122("error: " .. tostring(result))

        return
    end
    if result then
        if timestamp - t9.value106 > 3 then
            print("[Nexus Triggerbot] click via " .. tostring(v467))

            return
        end
    else
        t9.value122("failed: " .. tostring(v467))
    end
end
t9.value123 = t1.value1
t9.value124 = t1.value2
function t9.value125(p71)
    if typeof(p71) == "Instance" and p71:IsA("BasePart") then
        p71 = p71.Position
    end

    if typeof(p71) ~= "Vector3" then
        p71 = Vector3.new(p71.X or 0, p71.Y or 0, p71.Z or 0)
    end

    if type(vector) == "table" and type(vector.create) == "function" then
        return vector.create(p71.X, p71.Y, p71.Z)
    end

    return p71
end
t9.value126 = t1.value3
function t9.value127(p72)
    if typeof(p72) == "Vector3" then
        return p72
    end

    if typeof(p72) == "Instance" and p72:IsA("BasePart") then
        return p72.Position
    end

    if p72 ~= nil and (pcall(function()
        return p72.X, p72.Y, p72.Z
    end) and p72.X) then
        return Vector3.new(p72.X, p72.Y, p72.Z)
    end

    return nil
end
function t9.value128()
    local Character = t2.value8.Character

    if not Character then
        return t2.value9.CFrame.Position
    end

    for _, child in ipairs(Character:GetChildren()) do
        if not child:IsA("Tool") then
            continue
        end

        local Handle = child:FindFirstChild("Handle")

        if Handle and Handle:IsA("BasePart") then
            return Handle.Position
        end
    end

    local Head = Character:FindFirstChild("Head")

    if Head then
        return Head.Position
    end

    return t2.value9.CFrame.Position
end
function t9.value129(p73, p74)
    local Magnitude = (p73 - p74).Magnitude
    local v437 = (p73 + p74) / 2
    local Part = Instance.new("Part")

    Part.Name = "RayPart"
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    Part.Transparency = 0.5
    Part.Size = Vector3.new(0.1, 0.1, Magnitude)
    Part.CFrame = CFrame.new(v437, p74)
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.BrickColor = BrickColor.Yellow()
    game:GetService("Debris"):AddItem(Part, 0.05)
    Part.Parent = workspace.CurrentCamera
end
local function v59(p75, p76)
    local u471 = t9.value127(p75) or t9.value128()
    local u472 = t9.value127(p76)

    if not u471 or not u472 then
        return
    end

    if (u472 - u471).Magnitude < 1 then
        return
    end

    if not pcall(function()
        require(t2.value7.SharedModules.GunTracers).createBullet(u471, u472)
    end) then
        pcall(t9.value129, u471, u472)
    end
end
t9.value130 = nil
function t9.value130(p77, p78)
    if type(p77) ~= "table" or (p78 or 0) > 8 then
        return nil
    end

    local v475 = rawget(p77, 1)
    local v476 = rawget(p77, 2)
    local v477 = t9.value126(v475)

    if v477 then
        v477 = t9.value126(v476)
    end

    if v477 then
        return t9.value127(v475)
    end

    for _, v in pairs(p77) do
        if type(v) ~= "table" then
            continue
        end

        local v480 = t9.value130(v, (p78 or 0) + 1)

        if v480 then
            return v480
        end
    end

    return nil
end
t9.value131 = nil
function t9.value131(p79, p80)
    if type(p79) ~= "table" or (p80 or 0) > 10 then
        return p79
    end

    local t17 = {}

    for k, v in pairs(p79) do
        local v486 = type(v) == "table"

        if v486 then
            local v487 = p80 or 0

            v486 = t9.value131(v, v487 + 1)
        end

        t17[k] = v486 or v
    end

    return t17
end
t9.value132 = nil
function t9.value132(p81, p82, p83)
    if type(p81) ~= "table" or (p83 > 8 or not p82) then
        return false
    end

    local v491 = false
    local v492 = rawget(p81, 1)
    local v493 = rawget(p81, 2)
    local v494 = rawget(p81, 3)
    local v495 = t9.value126(v492)

    if v495 then
        v495 = t9.value126(v493)
    end

    if v495 then
        rawset(p81, 2, t9.value125(p82.Position))

        if typeof(v494) == "Instance" or v494 == nil then
            rawset(p81, 3, p82)
        end

        v491 = true
    elseif t9.value126(v493) and typeof(v494) == "Instance" then
        rawset(p81, 2, t9.value125(p82.Position))
        rawset(p81, 3, p82)
        v491 = true
    end

    for _, v in pairs(p81) do
        if type(v) == "table" and t9.value132(v, p82, p83 + 1) then
            v491 = true
        end
    end

    return v491
end
function t9.value133(p84)
    local u116
    local function u117(p85, p86)
        if type(p85) ~= "table" or p86 > 8 then
            return
        end

        local v792 = rawget(p85, 3)

        if typeof(v792) == "Instance" and (v792:IsA("BasePart") and v792.Name == "Head") then
            local Parent = v792.Parent

            if Parent then
                local player = t2.value1:GetPlayerFromCharacter(Parent)

                if player and player ~= t2.value8 then
                    u116 = player
                end
            end
        end

        for _, v in pairs(p85) do
            if type(v) == "table" then
                u117(v, p86 + 1)
            end
        end
    end
    for i = 1, #p84 do
        local v119 = i

        if type(p84[v119]) == "table" then
            u117(p84[v119], 0)
        end
    end

    return u116
end
if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
    local v60 = type(newcclosure) == "function" and newcclosure or function(p87)
        return p87
    end
    local u61
    u61 = hookmetamethod(game, "__namecall", v60(function(p88, ...)
        if getnamecallmethod() ~= "FireServer" then
            return u61(p88, ...)
        end

        local v500 = false

        if type(checkcaller) == "function" then
            local result14

            v500, result14 = pcall(checkcaller)

            if v500 then
                v500 = result14 == true
            end
        end

        if v500 then
            return u61(p88, ...)
        end

        local ok14, result15 = pcall(function()
            return p88.Name
        end)
        local v504 = not ok14

        if not v504 then
            v504 = result15 ~= "ShootEvent"
        end

        if v504 then
            return u61(p88, ...)
        end

        t9.value10.lastShotAt = tick()

        local v505 = select("#", ...)
        local t18 = table.create(v505)

        for i = 1, v505 do
            t18[i] = select(i, ...)
        end

        if t9.value10.silentAim then
            local v508 = t9.value119()

            if v508 and v508.Parent then
                local t19 = table.create(v505)
                local v510 = false

                for i = 1, v505 do
                    local v512 = i
                    local v513 = t18[v512]

                    if type(v513) == "table" then
                        local v514 = t9.value131(v513, 0)

                        pcall(t9.value132, v514, v508, 0)
                        t19[v512] = v514
                        v510 = true
                    else
                        t19[v512] = v513
                    end
                end

                if v510 then
                    pcall(function()
                        if t9.value10.silentTarget and v508.Name == "Head" then
                            t9.value32(t9.value10.silentTarget)
                        end
                    end)

                    local Position = v508.Position
                    local u516 = t9.value128()

                    for i = 1, v505 do
                        local v518 = i

                        if type(t18[v518]) ~= "table" then
                            continue
                        end

                        local v519 = t9.value130(t18[v518], 0)

                        if v519 then
                            u516 = v519

                            break
                        end
                    end

                    task.defer(function()
                        v59(u516, Position)
                    end)

                    if type(setnamecallmethod) == "function" then
                        pcall(setnamecallmethod, "FireServer")
                    end

                    return u61(p88, unpack(t19, 1, v505))
                end
            end
        end

        pcall(function()
            local v870 = t9.value133(t18)

            if v870 then
                t9.value32(v870)
            end
        end)

        return (function()
            if type(setnamecallmethod) == "function" then
                pcall(setnamecallmethod, "FireServer")
            end

            return u61(p88, unpack(t18, 1, v505))
        end)()
    end))
else
    warn("[Nexus] Silent aim needs hookmetamethod")
end
function t9.value134()
    return t9.value9.Accent or Color3.fromRGB(90, 160, 255)
end
t9.value135 = nil
function t9.value135(p89)
    if p89 == nil then
        return
    end

    if type(p89) == "table" and p89.Remove == nil then
        for _, v in pairs(p89) do
            t9.value135(v)
        end

        return
    end

    pcall(function()
        if p89.Visible ~= nil then
            p89.Visible = false
        end

        if type(p89.Remove) == "function" then
            p89:Remove()
        end
    end)
end
function t1.value1(p90, p91, p92, p93, p94)
    if not p90 then
        return
    end

    p90.From = p91
    p90.To = p92
    p90.Color = p93 or t9.value134()
    p90.Thickness = p94 or 1.5
    p90.Transparency = 1
    p90.Visible = true
end
t9.value136 = nil
function t1.value2(p95)
    local v539 = t9.value13[p95]

    if not v539 then
        return
    end

    t9.value135(v539)
    t9.value13[p95] = nil
end
function t1.value3()
    for k in pairs(t9.value13) do
        t9.value136(k)
    end

    table.clear(t9.value13)
end
t9.value136 = t1.value2
t9.value137 = t1.value3
function t9.value138(p96)
    if not t9.value21 then
        return nil
    end

    local ok15, result16 = pcall(function()
        return Drawing.new(p96)
    end)

    return ok15 and result16 or nil
end
function t9.value139(p97)
    local v525 = t9.value13[p97]

    if v525 and type(v525) == "table" then
        return v525
    end

    local t20 = {}

    t9.value13[p97] = t20

    return t20
end
t9.value140 = t1.value1
function t1.value2(p98)
    if not p98 or not p98.chamsOrig then
        return
    end

    for k, v in pairs(p98.chamsOrig) do
        local v558 = k
        local v559 = v

        if v558 and v558.Parent then
            pcall(function()
                for k2, v4 in pairs(v559) do
                    v558[k2] = v4
                end
            end)
        end
    end

    p98.chamsOrig = nil
    p98.chamsChar = nil
    p98.chamsColor = nil
end
function t1.value3(p99, p100)
    local v562 = not p99

    if not v562 then
        v562 = not p99.chamsOrig or p100 == p99.chamsColor
    end

    if v562 then
        return
    end

    for k in pairs(p99.chamsOrig) do
        local v564 = k
        local v565 = v564

        if v565 then
            v565 = v564.Parent and (v564:IsA("BasePart") and v564.Name ~= "Handle")
        end

        if v565 then
            pcall(function()
                v564.Color = p100
            end)
        end
    end

    p99.chamsColor = p100
end
function t1.value1(p101)
    local v567, v568 = t2.value9:WorldToViewportPoint(p101)

    return Vector2.new(v567.X, v567.Y), v568 and v567.Z > 0, v567.Z
end
function t9.value141(p102)
    local Head = p102:FindFirstChild("Head")
    local v543 = not Head
    local HumanoidRootPart = p102:FindFirstChild("HumanoidRootPart")

    if not v543 then
        v543 = not HumanoidRootPart
    end

    if v543 then
        return nil
    end

    local ViewportSize = t2.value9.ViewportSize

    local function v546(p103)
        local v872, v873 = t2.value9:WorldToViewportPoint(p103)
        local v874 = not v873

        if not v874 then
            v874 = v872.Z <= 0
        end

        if v874 then
            return nil
        end

        local v875 = v872.X < 0

        if not v875 then
            v875 = v872.Y < 0 or (v872.X > ViewportSize.X or v872.Y > ViewportSize.Y)
        end

        if v875 then
            return nil
        end

        return Vector2.new(v872.X, v872.Y), v872.Z
    end

    local v547 = v546(Head.Position + Vector3.new(0, 0.8, 0))
    local v548 = v546(HumanoidRootPart.Position - Vector3.new(0, 3, 0))
    local v549 = v546(HumanoidRootPart.Position)

    if not v547 or (not v548 or not v549) then
        return nil
    end

    local v550 = math.abs(v548.Y - v547.Y)

    if v550 < 10 or v550 > ViewportSize.Y * 0.8 then
        return nil
    end

    local v551 = math.clamp(v550 * 0.5, 10, ViewportSize.X * 0.35)
    local X = v549.X
    local v553 = X - v551 * 0.5
    local v554 = X + v551 * 0.5

    return v553, math.min(v547.Y, v548.Y), v554, (math.max(v547.Y, v548.Y))
end
t9.value142 = t1.value2
local function v62(_, p105, p106, p107)
    if p105 == p106.chamsChar and (p107 == p106.chamsColor and p106.chamsOrig) then
        return
    end
    if p106.chamsChar and p105 ~= p106.chamsChar then
        t9.value142(p106)
    end
    if not p106.chamsOrig then
        p106.chamsOrig = {}
    end
    local chamsOrig = p106.chamsOrig
    local function v574(p108, p109)
        if chamsOrig[p108] then
            return
        end

        local t21 = {}

        for _, v in ipairs(p109) do
            local v883 = v

            pcall(function()
                t21[v883] = p108[v883]
            end)
        end

        chamsOrig[p108] = t21
    end
    local GetChildren = p105.GetChildren
    for v578, v579 in ipairs(GetChildren(p105)) do

        local v580 = v579

        if v580:IsA("BasePart") then
            v574(v580, {
				"Color",
				"Material",
				"Transparency",
				"Reflectance"
			})
            pcall(function()
                v580.Material = Enum.Material.ForceField
                v580.Color = p107
                v580.Transparency = 0
                v580.Reflectance = 0
            end)
        elseif v580:IsA("Shirt") then
            v574(v580, { "ShirtTemplate" })
            pcall(function()
                v580.ShirtTemplate = ""
            end)
        elseif v580:IsA("Pants") then
            v574(v580, { "PantsTemplate" })
            pcall(function()
                v580.PantsTemplate = ""
            end)
        elseif v580:IsA("ShirtGraphic") then
            v574(v580, { "Graphic" })
            pcall(function()
                v580.Graphic = ""
            end)
        elseif v580:IsA("Accessory") then
            local Handle = v580:FindFirstChild("Handle")

            if Handle and Handle:IsA("BasePart") then
                v574(Handle, {
					"Transparency",
					"LocalTransparencyModifier"
				})
                pcall(function()
                    Handle.Transparency = 1
                    Handle.LocalTransparencyModifier = 1
                end)
            end
        end
    end
    local GetDescendants = p105.GetDescendants
    for _, v in ipairs(GetDescendants(p105)) do
        local v585 = v

        if v585:IsA("BasePart") and p105 ~= v585.Parent then
            if v585.Name ~= "Handle" and not chamsOrig[v585] then
                v574(v585, {
					"Color",
					"Material",
					"Transparency",
					"Reflectance"
				})
                pcall(function()
                    v585.Material = Enum.Material.ForceField
                    v585.Color = p107
                    v585.Transparency = 0
                    v585.Reflectance = 0
                end)
            end
        elseif (v585:IsA("Decal") or v585:IsA("Texture")) and not chamsOrig[v585] then
            v574(v585, { "Transparency" })
            pcall(function()
                v585.Transparency = 1
            end)
        end
    end
    p106.chamsChar = p105
    p106.chamsColor = p107
end
t9.value143 = t1.value3
t9.value144 = nil
function t1.value1(p110)
    if not t9.value10.highlights then
        return
    end

    task.spawn(function()
        local v884 = p110.Character or p110.CharacterAdded:Wait()

        if v884:FindFirstChildOfClass("Humanoid") or (v884:WaitForChild("Humanoid", 3) and v884:FindFirstChild("Head") or v884:WaitForChild("Head", 3)) then
            local v885 = p110

            t9.value144(v885)
        end
    end)
end
function t9.value144(p111)
    local Character = p111.Character

    if not Character then
        return
    end

    if t9.value10.espRangeOn and t9.value64(p111) > (t9.value10.espMaxRange or 1000) then
        local v588 = t9.value12[p111]

        if v588 then
            t9.value142(v588)

            if v588.Highlight then
                v588.Highlight:Destroy()
            end

            if v588.Billboard then
                v588.Billboard:Destroy()
            end

            t9.value12[p111] = nil
        end

        return
    end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Head = Character:FindFirstChild("Head")
    local v591 = not Humanoid
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

    if not v591 then
        v591 = not Head
    end

    if v591 then
        return
    end

    local v593 = t9.value12[p111] or {}

    t9.value12[p111] = v593

    if v593.Highlight and Character ~= v593.Highlight.Parent then
        v593.Highlight:Destroy()
        v593.Highlight = nil
    end

    if v593.Billboard and Character ~= v593.Billboard.Parent then
        v593.Billboard:Destroy()
        v593.Billboard = nil
    end

    local v594 = t9.value68(p111)
    local Highlight = v593.Highlight

    if t9.value10.espChams then
        if not Highlight or not Highlight.Parent then
            Highlight = Instance.new("Highlight")
            Highlight.DepthMode = t9.value2
            Highlight.Parent = Character
            v593.Highlight = Highlight
        end

        Highlight.FillColor = v594
        Highlight.OutlineColor = v594
        Highlight.FillTransparency = 0.15
        Highlight.OutlineTransparency = 0
        Highlight.Enabled = true

        if Character ~= v593.chamsChar or not v593.chamsOrig then
            v62(p111, Character, v593, v594)
        else
            t9.value143(v593, v594)
        end
    else
        if Highlight then
            Highlight.Enabled = false
        end

        if v593.chamsOrig then
            t9.value142(v593)
        end
    end

    if t9.value10.espNames or t9.value10.espDistance then
        local Billboard = v593.Billboard

        if not Billboard or not Billboard.Parent then
            local BillboardGui = Instance.new("BillboardGui")

            BillboardGui.AlwaysOnTop = true
            BillboardGui.Size = UDim2.new(0, 140, 0, 36)
            BillboardGui.StudsOffset = Vector3.new(0, 3.2, 0)
            BillboardGui.Adornee = Head
            BillboardGui.Parent = Character
            v593.Billboard = BillboardGui

            local TextLabel = Instance.new("TextLabel")

            TextLabel.Name = "NameLabel"
            TextLabel.Size = UDim2.new(1, 0, 0, 16)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextStrokeTransparency = 0.25
            TextLabel.Font = Enum.Font.GothamBold
            TextLabel.TextSize = 13
            TextLabel.Text = p111.Name
            TextLabel.Parent = BillboardGui

            local TextLabel2 = Instance.new("TextLabel")

            TextLabel2.Name = "DistLabel"
            TextLabel2.Size = UDim2.new(1, 0, 0, 14)
            TextLabel2.Position = UDim2.new(0, 0, 0, 16)
            TextLabel2.BackgroundTransparency = 1
            TextLabel2.TextStrokeTransparency = 0.3
            TextLabel2.Font = Enum.Font.Code
            TextLabel2.TextSize = 11
            TextLabel2.TextColor3 = Color3.fromRGB(200, 200, 210)
            TextLabel2.Parent = BillboardGui
        else
            Billboard.Adornee = Head
        end

        local NameLabel = v593.Billboard:FindFirstChild("NameLabel")
        local DistLabel = v593.Billboard:FindFirstChild("DistLabel")

        if NameLabel then
            NameLabel.Visible = t9.value10.espNames
            NameLabel.Text = p111.Name
            NameLabel.TextColor3 = v594
        end

        if DistLabel then
            DistLabel.Visible = t9.value10.espDistance

            if t9.value10.espDistance then
                local v602 = t2.value8.Character and t2.value8.Character:FindFirstChild("HumanoidRootPart")

                DistLabel.Text = v602 and (not not HumanoidRootPart and math.floor((HumanoidRootPart.Position - v602.Position).Magnitude) .. " studs") or "? studs"

                return
            end
        end
    elseif v593.Billboard then
        v593.Billboard:Destroy()
        v593.Billboard = nil
    end
end
function t1.value2()
    for _, v in pairs(t9.value12) do
        t9.value142(v)

        if v.Highlight then
            v.Highlight:Destroy()
        end

        if v.Billboard then
            v.Billboard:Destroy()
        end
    end

    table.clear(t9.value12)
    t9.value137()
end
local function v63()
    if not t9.value10.highlights or not t9.value21 then
        t9.value137()

        return
    end
    local ViewportSize = t2.value9.ViewportSize
    local vector2_2 = Vector2.new(ViewportSize.X * 0.5, ViewportSize.Y - 2)
    local t22 = {}
    for v613, v614 in ipairs(t2.value1:GetPlayers()) do

        if v614 ~= t2.value8 and (v614.Character and t9.value58(v614)) and (not t9.value10.espRangeOn or not (t9.value64(v614) > (t9.value10.espMaxRange or 1000))) then
            local Character = v614.Character
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local v617, v618, v619, v620 = t9.value141(Character)

            if v617 then
                t22[v614] = true

                local v621 = t9.value139(v614)
                local v622 = t9.value68(v614)

                if t9.value10.espBoxes then
                    v621.box = v621.box or {}

                    for i = 1, 4 do
                        local v624 = i

                        v621.box[v624] = v621.box[v624] or t9.value138("Line")
                    end

                    local vector2_3 = Vector2.new(v617, v618)
                    local vector2_4 = Vector2.new(v619, v618)
                    local vector2_5 = Vector2.new(v617, v620)
                    local vector2_6 = Vector2.new(v619, v620)

                    t9.value140(v621.box[1], vector2_3, vector2_4, v622, 1.6)
                    t9.value140(v621.box[2], vector2_4, vector2_6, v622, 1.6)
                    t9.value140(v621.box[3], vector2_6, vector2_5, v622, 1.6)
                    t9.value140(v621.box[4], vector2_5, vector2_3, v622, 1.6)
                elseif v621.box then
                    for _, v in pairs(v621.box) do
                        if v then
                            v.Visible = false
                        end
                    end
                end

                if t9.value10.espHealth and Humanoid then
                    local v631 = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 1), 0, 1)
                    local v632 = v617 - 6
                    local vector2_7 = Vector2.new(v632, v618)
                    local vector2_8 = Vector2.new(v632, v620)
                    local v635 = v620 - (v620 - v618) * v631

                    v621.hpBg = v621.hpBg or t9.value138("Line")
                    v621.hpFg = v621.hpFg or t9.value138("Line")
                    t9.value140(v621.hpBg, vector2_7, vector2_8, Color3.fromRGB(30, 30, 30), 3)

                    local v636 = v631 > 0.5 and Color3.fromRGB(80, 255, 120) or (v631 > 0.25 and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(255, 70, 70))

                    t9.value140(v621.hpFg, Vector2.new(v632, v635), vector2_8, v636, 3)
                else
                    if v621.hpBg then
                        v621.hpBg.Visible = false
                    end

                    if v621.hpFg then
                        v621.hpFg.Visible = false
                    end
                end

                if t9.value10.espTracers then
                    local vector2_9 = Vector2.new((v617 + v619) * 0.5, v620)

                    v621.tracer = v621.tracer or t9.value138("Line")
                    t9.value140(v621.tracer, vector2_2, vector2_9, v622, 1.4)
                elseif v621.tracer then
                    v621.tracer.Visible = false
                end
            end
        end
    end
    for k, v in pairs(t9.value13) do
        local v640 = k

        if not t22[v640] then
            t9.value135(v)
            t9.value13[v640] = nil
        end
    end
end
function t9.value145()
    v63()
end
function t9.value146(p112)
    local v605 = t9.value12[p112]

    if v605 then
        t9.value142(v605)

        if v605.Highlight then
            v605.Highlight:Destroy()
        end

        if v605.Billboard then
            v605.Billboard:Destroy()
        end

        t9.value12[p112] = nil
    end

    t9.value136(p112)

    if p112 == t9.value10.silentTarget then
        t9.value117()
    end

    t9.value69(p112)
end
t9.value147 = t1.value1
t9.value148 = t1.value2;
(function()
    local t23 = {}
    local t24 = {
		value1 = Instance.new("ScreenGui")
	}

    t24.value1.Name = "NexusV2"
    t24.value1.ResetOnSpawn = false
    t24.value1.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    t24.value1.IgnoreGuiInset = true
    t24.value1.DisplayOrder = 100
    t24.value1.Parent = t2.value10
    t9.value22.ScreenGui = t24.value1
    t24.value2 = Instance.new("Frame")
    t24.value2.AnchorPoint = Vector2.new(0.5, 0.5)
    t24.value2.Size = UDim2.fromOffset(t9.value10.fovRadius * 2, t9.value10.fovRadius * 2)
    t24.value2.BackgroundTransparency = 1
    t24.value2.Visible = false
    t24.value2.ZIndex = 50
    t24.value2.Parent = t24.value1
    t24.value3 = Instance.new("UIStroke")
    t24.value3.Color = t9.value9.Accent
    t24.value3.Thickness = 1.5
    t24.value3.Transparency = 0.25
    t24.value3.Parent = t24.value2
    Instance.new("UICorner", t24.value2).CornerRadius = UDim.new(1, 0)
    t9.value22.FovCircle = t24.value2
    t9.value22.FovStroke = t24.value3

    function t24.value4()
        t24.value2.Size = UDim2.fromOffset(t9.value10.fovRadius * 2, t9.value10.fovRadius * 2)
        t24.value2.Visible = t9.value10.fovCircle
        t24.value3.Color = t9.value9.Accent

        if t9.value10.fovCircle then
            local v886 = t9.value49()

            t24.value2.Position = UDim2.fromOffset(v886.X, v886.Y)
        end
    end

    t9.value22.updateFovCircle = t24.value4
    t24.value5 = Instance.new("Frame")
    t24.value5.Name = "Dim"
    t24.value5.Size = UDim2.new(1, 0, 1, 0)
    t24.value5.BackgroundColor3 = Color3.new(0, 0, 0)
    t24.value5.BackgroundTransparency = 1
    t24.value5.BorderSizePixel = 0
    t24.value5.ZIndex = 1
    t24.value5.Active = true
    t24.value5.Parent = t24.value1
    t9.value22.Dim = t24.value5
    t24.value6 = Instance.new("Frame")
    t24.value6.Name = "MainFrame"
    t24.value6.AnchorPoint = Vector2.new(0.5, 0.5)

    if t9.value1 then
        t24.value6.Size = UDim2.new(0, 600, 0, 360)
    else
        t24.value6.Size = UDim2.new(0, 980, 0, 600)
    end

    t24.value6.Position = UDim2.new(0.5, 0, 0.5, 0)
    t24.value6.BackgroundTransparency = 1
    t24.value6.BorderSizePixel = 0
    t24.value6.Active = true
    t24.value6.ClipsDescendants = false
    t24.value6.ZIndex = 10
    t24.value6.Parent = t24.value1
    t9.value22.MainFrame = t24.value6

    if t9.value1 then
        local UIScale = Instance.new("UIScale")
        local v_vp = (t2.value9 and t2.value9.ViewportSize) or Vector2.new(800, 600)
        local v_isTablet = math.min(v_vp.X, v_vp.Y) >= 700 -- iPad / large tablets
        local v_maxScale = v_isTablet and 1.35 or 1
        local v_fit = math.min((v_vp.X * 0.9) / 600, (v_vp.Y * 0.9) / 360)

        UIScale.Scale = math.clamp(v_fit, 0.6, v_maxScale)
        UIScale.Parent = t24.value6

        local value22 = t9.value22

        t23.value1 = "UIScale"
        value22[t23.value1] = UIScale
    end

    t24.value7 = Instance.new("CanvasGroup")
    t24.value7.Name = "Shell"
    t24.value7.Size = UDim2.new(1, 0, 1, 0)
    t24.value7.BackgroundColor3 = t9.value9.Background
    t24.value7.BorderSizePixel = 0
    t24.value7.GroupTransparency = 0
    t24.value7.Parent = t24.value6
    t9.value22.Shell = t24.value7
    t24.value8 = Instance.new("UICorner")
    t24.value8.CornerRadius = UDim.new(0, 14)
    t24.value8.Parent = t24.value7
    t24.value9 = Instance.new("UIStroke")
    t24.value9.Color = Color3.fromRGB(40, 40, 40)
    t24.value9.Thickness = 1
    t24.value9.Transparency = 0.35
    t24.value9.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    t24.value9.LineJoinMode = Enum.LineJoinMode.Round
    t24.value9.Parent = t24.value7

    function t24.value10(p113)
        t24.value5.Visible = true

        local v888 = not p113 and 1 or 0.55
        local v889 = t2.value4:Create(t24.value5, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = v888
		})

        v889:Play()

        if not p113 then
            v889.Completed:Connect(function()
                if t24.value5.BackgroundTransparency >= 0.99 then
                    t24.value5.Visible = false
                end
            end)
        end
    end

    t9.value22.fadeDim = t24.value10
    task.defer(function()
        t24.value10(true)
    end)
    t24.value11 = Instance.new("Frame")
    t24.value11.Size = UDim2.new(1, 0, 0, 48)
    t24.value11.Position = UDim2.new(0, 0, 0, 0)
    t24.value11.BackgroundColor3 = t9.value9.Background
    t24.value11.BorderSizePixel = 0
    t24.value11.ZIndex = 10
    t24.value11.Parent = t24.value7

    local Frame = Instance.new("Frame")

    Frame.Size = UDim2.new(1, 0, 0, 1)
    Frame.Position = UDim2.new(0, 0, 1, -1)
    Frame.BackgroundColor3 = t9.value9.Stroke
    Frame.BorderSizePixel = 0
    Frame.Parent = t24.value11
    t23.value2 = Color3.fromRGB(255, 95, 87)
    t24.value12 = t23.value2
    t23.value2 = Color3.fromRGB(255, 189, 46)
    t24.value13 = t23.value2
    t23.value2 = Color3.fromRGB(40, 200, 64)
    t24.value14 = t23.value2

    function t23.value2(p114, p115)
        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(0, 26, 0, 26)
        TextButton.Position = UDim2.new(0, p114, 0.5, -13)
        TextButton.BackgroundTransparency = 1
        TextButton.Text = ""
        TextButton.BorderSizePixel = 0
        TextButton.AutoButtonColor = false
        TextButton.ZIndex = 20
        TextButton.Parent = t24.value11

        local Frame2 = Instance.new("Frame")

        Frame2.Name = "Dot"
        Frame2.Size = UDim2.new(0, 16, 0, 16)
        Frame2.Position = UDim2.new(0.5, -8, 0.5, -8)
        Frame2.BackgroundColor3 = p115
        Frame2.BorderSizePixel = 0
        Frame2.ZIndex = 21
        Frame2.Parent = TextButton
        Instance.new("UICorner", Frame2).CornerRadius = UDim.new(1, 0)
        TextButton.MouseEnter:Connect(function()
            Frame2.Size = UDim2.new(0, 18, 0, 18)
            Frame2.Position = UDim2.new(0.5, -9, 0.5, -9)
        end)
        TextButton.MouseLeave:Connect(function()
            Frame2.Size = UDim2.new(0, 16, 0, 16)
            Frame2.Position = UDim2.new(0.5, -8, 0.5, -8)
            Frame2.BackgroundColor3 = p115
        end)

        return TextButton, Frame2
    end

    local v646, v647 = t23.value2(12, t24.value12)

    t23.value3 = v647
    t24.value15 = t23.value3

    local v648, v649 = t23.value2(32, t24.value13)

    t23.value3 = v649
    t24.value16 = t23.value3

    local v650, v651 = t23.value2(52, t24.value14)

    t23.value3 = v651
    t24.value17 = t23.value3
    t23.value3 = Instance.new("TextLabel")
    t24.value18 = t23.value3

    local value18 = t24.value18

    t23.value3 = "Size"
    value18[t23.value3] = UDim2.new(1, -140, 1, 0)

    local value18_2 = t24.value18

    t23.value3 = "Position"
    value18_2[t23.value3] = UDim2.new(0, 90, 0, 0)

    local value18_3 = t24.value18

    t23.value3 = "BackgroundTransparency"
    value18_3[t23.value3] = 1

    local value18_4 = t24.value18

    t23.value3 = "Text"
    value18_4[t23.value3] = "NEXUS"

    local value18_5 = t24.value18

    t23.value3 = "TextColor3"
    value18_5[t23.value3] = Color3.fromRGB(255, 255, 255)

    local value18_6 = t24.value18

    t23.value3 = "Font"
    value18_6[t23.value3] = Enum.Font.GothamBold

    local value18_7 = t24.value18

    t23.value3 = "TextSize"
    value18_7[t23.value3] = 15

    local value18_8 = t24.value18

    t23.value3 = "TextXAlignment"
    value18_8[t23.value3] = Enum.TextXAlignment.Center

    local value18_9 = t24.value18

    t23.value3 = "ZIndex"
    value18_9[t23.value3] = 11

    local value18_10 = t24.value18

    t23.value3 = "Active"
    value18_10[t23.value3] = false

    local value18_11 = t24.value18

    t23.value3 = "Parent"
    value18_11[t23.value3] = t24.value11
    t24.value19 = false
    t24.value20 = t9.value1 and UDim2.new(0, 600, 0, 360) or UDim2.new(0, 980, 0, 600)
    v650.MouseButton1Click:Connect(function()
        t24.value19 = not t24.value19

        if t24.value19 then
            t24.value6.Size = UDim2.new(0.98, 0, 0.94, 0)
        else
            t24.value6.Size = t24.value20
        end

        t24.value6.AnchorPoint = Vector2.new(0.5, 0.5)
        t24.value6.Position = UDim2.new(0.5, 0, 0.5, 0)
    end)

    -- Draggable window: drag the title bar (works with touch and mouse)
    do
        local dragHandle = t24.value11
        local dragging = false
        local dragStart
        local startPos

        dragHandle.Active = true

        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = t24.value6.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        t2.value3.InputChanged:Connect(function(input)
            if not dragging then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart

                t24.value6.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    t24.value21 = Instance.new("Frame")
    t24.value21.Size = UDim2.new(1, 0, 1, 0)
    t24.value21.BackgroundColor3 = Color3.new(0, 0, 0)
    t24.value21.BackgroundTransparency = 0.45
    t24.value21.BorderSizePixel = 0
    t24.value21.Visible = false
    t24.value21.ZIndex = 400
    t24.value21.Parent = t24.value1
    t24.value22 = Instance.new("Frame")
    t24.value22.Size = UDim2.new(0, 260, 0, 120)
    t24.value22.Position = UDim2.new(0.5, -130, 0.5, -60)
    t24.value22.BackgroundColor3 = t9.value9.Card
    t24.value22.BorderSizePixel = 0
    t24.value22.Visible = false
    t24.value22.ZIndex = 401
    t24.value22.Parent = t24.value1
    t24.value23 = Instance.new("UIStroke")
    t24.value23.Color = t9.value9.Stroke
    t24.value23.Parent = t24.value22
    t24.value24 = Instance.new("Frame")
    t24.value24.Size = UDim2.new(1, 0, 0, 2)
    t24.value24.BackgroundColor3 = t9.value9.Accent
    t24.value24.BorderSizePixel = 0
    t24.value24.ZIndex = 402
    t24.value24.Parent = t24.value22
    t24.value25 = Instance.new("TextLabel")
    t24.value25.Size = UDim2.new(1, -20, 0, 20)
    t24.value25.Position = UDim2.new(0, 10, 0, 16)
    t24.value25.BackgroundTransparency = 1
    t24.value25.Text = "Close Nexus V2?"
    t24.value25.TextColor3 = t9.value9.Text
    t24.value25.Font = Enum.Font.Code
    t24.value25.TextSize = 14
    t24.value25.TextXAlignment = Enum.TextXAlignment.Left
    t24.value25.ZIndex = 402
    t24.value25.Parent = t24.value22
    t24.value26 = Instance.new("TextLabel")
    t24.value26.Size = UDim2.new(1, -20, 0, 16)
    t24.value26.Position = UDim2.new(0, 10, 0, 40)
    t24.value26.BackgroundTransparency = 1
    t24.value26.Text = "UI will be destroyed until you re-run."
    t24.value26.TextColor3 = t9.value9.TextDark
    t24.value26.Font = Enum.Font.Code
    t24.value26.TextSize = 10
    t24.value26.TextXAlignment = Enum.TextXAlignment.Left
    t24.value26.ZIndex = 402
    t24.value26.Parent = t24.value22

    local function v663(p116, p117, p118, p119)
        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(0, 110, 0, 28)
        TextButton.Position = UDim2.new(0, p117, 1, -40)
        TextButton.BackgroundColor3 = p118
        TextButton.Text = p116
        TextButton.TextColor3 = p119
        TextButton.Font = Enum.Font.Gotham
        TextButton.TextSize = 12
        TextButton.BorderSizePixel = 0
        TextButton.ZIndex = 402
        TextButton.Parent = t24.value22

        return TextButton
    end

    t24.value27 = v663("Cancel", 16, t9.value9.Element, t9.value9.Text)

    local v664 = v663("Close", 134, t9.value9.Danger, Color3.new(1, 1, 1))

    v646.MouseButton1Click:Connect(function()
        local value21 = t24.value21
        local value22 = t24.value22

        value21.Visible = true
        value22.Visible = true
    end)
    t24.value27.MouseButton1Click:Connect(function()
        local value21 = t24.value21
        local value22 = t24.value22

        value21.Visible = false
        value22.Visible = false
    end)
    v664.MouseButton1Click:Connect(function()
        t24.value22.Visible = false
        t24.value21.Visible = false

        if t9.value22.closeColorPicker then
            t9.value22.closeColorPicker()
        end

        t24.value6.Visible = false
        t24.value10(false)
        task.delay(0.45, function()
            if t24.value1 then
                t24.value1:Destroy()
            end
        end)
    end)
    t24.value21.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local value21 = t24.value21
            local value22 = t24.value22

            value21.Visible = false
            value22.Visible = false
        end
    end)
    t24.value28 = Instance.new("Folder")
    t24.value28.Parent = t24.value1
    t24.value29 = {}

    local function v665()
        for i, v in ipairs(t24.value29) do
            t2.value4:Create(v.frame, TweenInfo.new(0.15), {
				Position = UDim2.new(1, -212, 0, 10 + (i - 1) * 44)
			}):Play()
        end
    end
    local function v666(p120, p121, p122)
        local v911 = typeof(p121) == "boolean"
        local v912 = (not v911 or not p121) and "OFF" or "ON"

        if v911 then
            v911 = p121 and t9.value9.Accent or t9.value9.Danger
        end

        local v913 = v911 or t9.value9.Accent
        local v914 = typeof(p122) == "number" and (p122 > 0 and p122) or 3
        local Frame3 = Instance.new("Frame")

        Frame3.Size = UDim2.new(0, 220, 0, 42)
        Frame3.Position = UDim2.new(1, 16, 0, 10)
        Frame3.BackgroundColor3 = t9.value9.Card
        Frame3.BorderSizePixel = 0
        Frame3.ZIndex = 200
        Frame3.Parent = t24.value28

        local UIStroke = Instance.new("UIStroke")

        UIStroke.Color = t9.value9.Stroke
        UIStroke.Parent = Frame3

        local Frame4 = Instance.new("Frame")

        Frame4.Size = UDim2.new(0, 3, 1, 0)
        Frame4.BackgroundColor3 = v913
        Frame4.BorderSizePixel = 0
        Frame4.ZIndex = 201
        Frame4.Parent = Frame3

        local TextLabel = Instance.new("TextLabel")

        TextLabel.Size = UDim2.new(1, -16, 0, 16)
        TextLabel.Position = UDim2.new(0, 12, 0, 4)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = p120
        TextLabel.TextColor3 = t9.value9.Text
        TextLabel.Font = Enum.Font.Code
        TextLabel.TextSize = 12
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
        TextLabel.ZIndex = 201
        TextLabel.Parent = Frame3

        local TextLabel3 = Instance.new("TextLabel")

        TextLabel3.Size = UDim2.new(1, -16, 0, 16)
        TextLabel3.Position = UDim2.new(0, 12, 0, 20)
        TextLabel3.BackgroundTransparency = 1
        TextLabel3.Text = v912
        TextLabel3.TextColor3 = v913
        TextLabel3.Font = Enum.Font.Code
        TextLabel3.TextSize = 11
        TextLabel3.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel3.TextWrapped = true
        TextLabel3.TextTruncate = Enum.TextTruncate.AtEnd
        TextLabel3.ZIndex = 201
        TextLabel3.Parent = Frame3
        table.insert(t24.value29, 1, {
			frame = Frame3
		})
        v665()
        task.delay(v914, function()
            if not Frame3.Parent then
                return
            end

            local tweenInfo = TweenInfo.new(0.3)

            t2.value4:Create(Frame3, tweenInfo, {
				BackgroundTransparency = 1
			}):Play()
            t2.value4:Create(UIStroke, tweenInfo, {
				Transparency = 1
			}):Play()
            t2.value4:Create(Frame4, tweenInfo, {
				BackgroundTransparency = 1
			}):Play()
            t2.value4:Create(TextLabel, tweenInfo, {
				TextTransparency = 1
			}):Play()
            t2.value4:Create(TextLabel3, tweenInfo, {
				TextTransparency = 1
			}):Play()
            task.delay(0.35, function()
                for i, v in ipairs(t24.value29) do
                    if v.frame == Frame3 then
                        table.remove(t24.value29, i)

                        break
                    end
                end

                Frame3:Destroy()
                v665()
            end)
        end)
    end

    t9.value22.notify = v666

    local v667 = not t9.value1 and 168 or 88
    local _Instance = Instance
    local v669 = not t9.value1 and 200 or 0

    t24.value30 = _Instance.new("Frame")
    t24.value30.Size = UDim2.new(0, v667, 1, -48)
    t24.value30.Position = UDim2.new(0, 0, 0, 48)
    t24.value30.BackgroundColor3 = t9.value9.Sidebar
    t24.value30.BorderSizePixel = 0
    t24.value30.ZIndex = 5
    t24.value30.Parent = t24.value7
    t24.value31 = Instance.new("Frame")
    t24.value31.Size = UDim2.new(0, 1, 1, 0)
    t24.value31.Position = UDim2.new(1, -1, 0, 0)
    t24.value31.BackgroundColor3 = t9.value9.Stroke
    t24.value31.BorderSizePixel = 0
    t24.value31.Parent = t24.value30
    t24.value32 = {}

    local function v670(p123, p124, p125)
        if not p123 then
            return
        end

        local insert = table.insert
        local value32 = t24.value32
        local v925 = string.lower(tostring(p124 or ""))

        insert(value32, {
			obj = p123,
			text = v925,
			tab = p125
		})
    end
    local function v671(p126)
        local lower = string.lower
        if not p126 then
            p126 = ""
        end
        local v928 = lower(p126:gsub("^%s+", ""):gsub("%s+$", ""))
        local t25 = {
			Home = 0,
			Commands = 0,
			ESP = 0,
			Settings = 0,
			Tutorial = 0
		}
        local t26 = table.create(#t24.value32)
        for v933, v934 in ipairs(t24.value32) do

            local v935 = v928 == ""

            if not v935 then
                v935 = v934.text ~= ""

                if v935 then
                    v935 = string.find(v934.text, v928, 1, true) ~= nil
                end
            end

            t26[v933] = v935
        end
        for v938, v939 in ipairs(t24.value32) do

            local v940 = v939
            local v941 = not t26[v938]

            if v941 then
                v941 = v940.obj
            end

            if v941 then
                for i, v in ipairs(t24.value32) do
                    if not (t26[i] and (v.obj and v.obj ~= v940.obj)) then
                        continue
                    end

                    local ok16, result17 = pcall(function()
                        return v.obj:IsDescendantOf(v940.obj)
                    end)

                    if ok16 and result17 then
                        t26[v938] = true

                        break
                    end
                end
            end
        end
        for v948, v949 in ipairs(t24.value32) do

            if v949.obj and v949.obj.Parent then
                v949.obj.Visible = not not t26[v948]

                if t26[v948] and (v949.tab and t25[v949.tab] ~= nil) then
                    t25[v949.tab] = t25[v949.tab] + 1
                end
            end
        end
        if v928 ~= "" then
            local n6 = 0
            local v951
            for v954, v955 in pairs(t25) do

                if n6 < v955 then
                    v951 = v954
                    n6 = v955
                end
            end
            if v951 and (n6 > 0 and t9.value22.setActiveTab) then
                t9.value22.setActiveTab(v951)
            end
        end
    end

    local Frame5 = Instance.new("Frame")

    Frame5.Name = "ProfileCard"
    Frame5.Size = UDim2.new(1, -20, 0, not t9.value1 and 58 or 52)
    Frame5.Position = UDim2.new(0, 10, 0, 10)
    Frame5.BackgroundColor3 = t9.value9.Element
    Frame5.BackgroundTransparency = 0.15
    Frame5.BorderSizePixel = 0
    Frame5.Parent = t24.value30
    Instance.new("UICorner", Frame5).CornerRadius = UDim.new(0, 12)

    local UIStroke = Instance.new("UIStroke")

    UIStroke.Color = t9.value9.Stroke
    UIStroke.Transparency = 0.35
    UIStroke.Thickness = 1
    UIStroke.Parent = Frame5
    t24.value33 = Instance.new("ImageLabel")
    t24.value33.Name = "Avatar"
    t24.value33.Size = UDim2.new(0, not t9.value1 and 36 or 32, 0, not t9.value1 and 36 or 32)
    t24.value33.Position = UDim2.new(0, 10, 0.5, not t9.value1 and -18 or -16)
    t24.value33.BackgroundColor3 = t9.value9.Track
    t24.value33.BorderSizePixel = 0
    t24.value33.Image = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png", t2.value8.UserId)
    pcall(function()
        t24.value33.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", t2.value8.UserId)
    end)
    t24.value33.Parent = Frame5
    Instance.new("UICorner", t24.value33).CornerRadius = UDim.new(1, 0)

    local UIStroke2 = Instance.new("UIStroke")

    UIStroke2.Color = t9.value9.Stroke
    UIStroke2.Transparency = 0.3
    UIStroke2.Parent = t24.value33

    local DisplayName = t2.value8.DisplayName

    if not DisplayName or DisplayName == "" then
        DisplayName = t2.value8.Name
    end

    local TextLabel = Instance.new("TextLabel")

    TextLabel.Size = UDim2.new(1, not t9.value1 and -56 or -50, 0, 16)
    TextLabel.Position = UDim2.new(0, not t9.value1 and 54 or 48, 0.5, -16)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = DisplayName
    TextLabel.TextColor3 = t9.value9.Text
    TextLabel.Font = Enum.Font.GothamMedium
    TextLabel.TextSize = not t9.value1 and 13 or 11
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TextLabel.Parent = Frame5

    local TextLabel4 = Instance.new("TextLabel")

    TextLabel4.Size = UDim2.new(1, t9.value1 and -50 or -56, 0, 14)
    TextLabel4.Position = UDim2.new(0, not t9.value1 and 54 or 48, 0.5, 2)
    TextLabel4.BackgroundTransparency = 1
    TextLabel4.Text = "Free user"
    TextLabel4.TextColor3 = t9.value9.TextDark
    TextLabel4.Font = Enum.Font.Gotham
    TextLabel4.TextSize = not t9.value1 and 11 or 9
    TextLabel4.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel4.Parent = Frame5
    table.insert(t9.value17, {
		obj = Frame5,
		prop = "BackgroundColor3",
		key = "Element"
	})
    table.insert(t9.value17, {
		obj = UIStroke,
		prop = "Color",
		key = "Stroke"
	})
    table.insert(t9.value17, {
		obj = TextLabel,
		prop = "TextColor3",
		key = "Text"
	})
    table.insert(t9.value17, {
		obj = TextLabel4,
		prop = "TextColor3",
		key = "TextDark"
	})
    t24.value34 = Instance.new("TextBox")
    t24.value34.Size = UDim2.new(1, -20, 0, 28)
    t24.value34.Position = UDim2.new(0, 10, 0, 76)
    t24.value34.BackgroundColor3 = t9.value9.Element
    t24.value34.PlaceholderText = "Search..."
    t24.value34.Text = ""
    t24.value34.TextColor3 = t9.value9.Text
    t24.value34.PlaceholderColor3 = t9.value9.TextDark
    t24.value34.Font = Enum.Font.Gotham
    t24.value34.TextSize = 12
    t24.value34.TextXAlignment = Enum.TextXAlignment.Center
    t24.value34.ClearTextOnFocus = false
    t24.value34.Parent = t24.value30
    Instance.new("UICorner", t24.value34).CornerRadius = UDim.new(0, 8)
    t24.value34:GetPropertyChangedSignal("Text"):Connect(function()
        v671(t24.value34.Text)
    end)
    t24.value34.FocusLost:Connect(function()
        v671(t24.value34.Text)
    end)

    local function v678(p127, p128, p129)
        local TextButton = Instance.new("TextButton")

        TextButton.Name = p128
        TextButton.Size = UDim2.new(1, -20, 0, 32)
        TextButton.Position = UDim2.new(0, 10, 0, 114 + (p129 - 1) * 38)
        TextButton.BackgroundColor3 = t9.value9.Sidebar
        TextButton.Text = "  " .. p127
        TextButton.TextColor3 = t9.value9.TextDark
        TextButton.Font = Enum.Font.GothamMedium
        TextButton.TextSize = 13
        TextButton.TextXAlignment = Enum.TextXAlignment.Left
        TextButton.BorderSizePixel = 0
        TextButton.AutoButtonColor = false
        TextButton.Parent = t24.value30
        Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 8)

        local Frame6 = Instance.new("Frame")

        Frame6.Name = "Ind"
        Frame6.Size = UDim2.new(0, 0, 0, 0)
        Frame6.Visible = false
        Frame6.Parent = TextButton

        return TextButton
    end

    t24.value35 = v678("Combat", "Commands", 1)
    t24.value36 = v678("Home", "Home", 2)
    t24.value37 = v678("ESP", "ESP", 3)
    t24.value38 = v678("Settings", "Settings", 4)
    t24.value39 = v678("Tutorial", "Tutorial", 5)
    t24.value40 = Instance.new("Frame")
    t24.value40.Size = UDim2.new(1, -(v667 + v669), 1, -48)
    t24.value40.Position = UDim2.new(0, v667, 0, 48)
    t24.value40.BackgroundTransparency = 1
    t24.value40.ClipsDescendants = true
    t24.value40.Parent = t24.value7

    local Frame7 = Instance.new("Frame")

    Frame7.Size = UDim2.new(0, v669, 1, -48)
    Frame7.Position = UDim2.new(1, -v669, 0, 48)
    Frame7.BackgroundTransparency = 1
    Frame7.Visible = not t9.value1
    Frame7.Parent = t24.value7

    if not t9.value1 then
        local Frame8 = Instance.new("Frame")
        t23.value4 = UDim2.new(1, -16, 0, 110)
        Frame8.Size = t23.value4
        t23.value4 = UDim2.new(0, 8, 0, 12)
        Frame8.Position = t23.value4
        Frame8.BackgroundColor3 = t9.value9.Card
        Frame8.BorderSizePixel = 0
        Frame8.Parent = Frame7
        local UICorner = Instance.new("UICorner", Frame8)
        t23.value5 = UDim.new(0, 10)
        UICorner.CornerRadius = t23.value5
        local UIStroke3 = Instance.new("UIStroke")
        t23.value4 = t9.value9.Stroke
        UIStroke3.Color = t23.value4
        UIStroke3.Parent = Frame8
        t23.value4 = Instance.new("TextLabel")
        t23.value6 = UDim2.new(1, -16, 0, 16)
        t23.value4.Size = t23.value6
        t23.value6 = UDim2.new(0, 10, 0, 8)
        t23.value4.Position = t23.value6
        t23.value4.BackgroundTransparency = 1
        t23.value4.Text = "QUICK STATS"
        t23.value5 = t9.value9.TextDark
        t23.value4.TextColor3 = t23.value5
        t23.value5 = Enum.Font.GothamMedium
        t23.value4.Font = t23.value5
        t23.value4.TextSize = 10
        t23.value5 = Enum.TextXAlignment.Left
        t23.value4.TextXAlignment = t23.value5
        t23.value4.Parent = Frame8
        t23.value5 = Instance.new("TextLabel")
        local value5 = t23.value5
        t23.value5 = value5
        t23.value6 = "Size"
        t23.value8 = UDim2.new(1, -20, 0, 18)
        t23.value5[t23.value6] = t23.value8
        t23.value5 = value5
        t23.value6 = "Position"
        t23.value8 = UDim2.new(0, 10, 0, 32)
        t23.value5[t23.value6] = t23.value8
        t23.value5 = value5
        t23.value6 = "BackgroundTransparency"
        t23.value5[t23.value6] = 1
        t23.value5 = value5
        t23.value6 = "Text"
        t23.value5[t23.value6] = "FPS                          -"
        t23.value5 = value5
        t23.value6 = "TextColor3"
        t23.value7 = t9.value9.Text
        t23.value5[t23.value6] = t23.value7
        t23.value5 = value5
        t23.value6 = "Font"
        t23.value7 = Enum.Font.Gotham
        t23.value5[t23.value6] = t23.value7
        t23.value5 = value5
        t23.value6 = "TextSize"
        t23.value5[t23.value6] = 12
        t23.value5 = value5
        t23.value6 = "TextXAlignment"
        t23.value7 = Enum.TextXAlignment.Left
        t23.value5[t23.value6] = t23.value7
        t23.value5 = value5
        t23.value6 = "Parent"
        t23.value5[t23.value6] = Frame8
        t23.value6 = Instance.new("TextLabel")
        local value6 = t23.value6
        t23.value6 = value6
        t23.value7 = "Size"
        t23.value9 = UDim2.new(1, -20, 0, 18)
        t23.value6[t23.value7] = t23.value9
        t23.value6 = value6
        t23.value7 = "Position"
        t23.value9 = UDim2.new(0, 10, 0, 52)
        t23.value6[t23.value7] = t23.value9
        t23.value6 = value6
        t23.value7 = "BackgroundTransparency"
        t23.value6[t23.value7] = 1
        t23.value6 = value6
        t23.value7 = "Text"
        t23.value6[t23.value7] = "PING                       -"
        t23.value6 = value6
        t23.value7 = "TextColor3"
        t23.value8 = t9.value9.Text
        t23.value6[t23.value7] = t23.value8
        t23.value6 = value6
        t23.value7 = "Font"
        t23.value8 = Enum.Font.Gotham
        t23.value6[t23.value7] = t23.value8
        t23.value6 = value6
        t23.value7 = "TextSize"
        t23.value6[t23.value7] = 12
        t23.value6 = value6
        t23.value7 = "TextXAlignment"
        t23.value8 = Enum.TextXAlignment.Left
        t23.value6[t23.value7] = t23.value8
        t23.value6 = value6
        t23.value7 = "Parent"
        t23.value6[t23.value7] = Frame8
        t23.value7 = Instance.new("TextLabel")
        t23.value6 = "Size"
        t23.value9 = UDim2.new(1, -20, 0, 18)
        t23.value7[t23.value6] = t23.value9
        t23.value6 = "Position"
        t23.value9 = UDim2.new(0, 10, 0, 72)
        t23.value7[t23.value6] = t23.value9
        t23.value6 = "BackgroundTransparency"
        t23.value7[t23.value6] = 1
        t23.value6 = "Text"
        t23.value7[t23.value6] = "STATUS              ACTIVE"
        t23.value6 = "TextColor3"
        t23.value8 = t9.value9.Text
        t23.value7[t23.value6] = t23.value8
        t23.value6 = "Font"
        t23.value8 = Enum.Font.Gotham
        t23.value7[t23.value6] = t23.value8
        t23.value6 = "TextSize"
        t23.value7[t23.value6] = 12
        t23.value6 = "TextXAlignment"
        t23.value8 = Enum.TextXAlignment.Left
        t23.value7[t23.value6] = t23.value8
        t23.value6 = "Parent"
        t23.value7[t23.value6] = Frame8
        t23.value8 = Instance.new("TextLabel")
        t23.value6 = "Size"
        local uDim2 = UDim2.new(0, 70, 0, 22)
        t23.value8[t23.value6] = uDim2
        t23.value6 = "Position"
        local uDim2_2 = UDim2.new(1, -86, 0, 12)
        t23.value8[t23.value6] = uDim2_2
        t23.value6 = "BackgroundColor3"
        t23.value9 = t9.value9.Element
        t23.value8[t23.value6] = t23.value9
        t23.value6 = "Text"
        t23.value8[t23.value6] = "● ACTIVE"
        t23.value6 = "TextColor3"
        local color3_14 = Color3.fromRGB(80, 220, 120)
        t23.value8[t23.value6] = color3_14
        t23.value6 = "Font"
        t23.value9 = Enum.Font.GothamMedium
        t23.value8[t23.value6] = t23.value9
        t23.value6 = "TextSize"
        t23.value8[t23.value6] = 10
        t23.value6 = "Parent"
        t23.value8[t23.value6] = Frame7
        t23.value9 = Instance.new("UICorner", t23.value8)
        t23.value6 = "CornerRadius"
        local uDim = UDim.new(1, 0)
        t23.value9[t23.value6] = uDim
        task.spawn(function()
            local timestamp = tick()
            local n7 = 0

            t2.value2.RenderStepped:Connect(function()
                n7 += 1

                local timestamp2 = tick()

                if timestamp2 - timestamp >= 0.5 then
                    local floor = math.floor
                    local v1265 = timestamp2 - timestamp
                    local v1266 = n7 / v1265
                    local v1268 = floor(v1266)
                    local n8 = 0
                    pcall(function()
                        n8 = math.floor(t2.value8:GetNetworkPing() * 1000)
                    end)
                    if value5.Parent then
                        value5.Text = string.format("FPS%28d", v1268)
                        value6.Text = string.format("PING%25dms", n8)
                    end
                end
            end)
        end)
        t23.value9 = Instance.new("Frame")
        t23.value6 = "Name"
        t23.value9[t23.value6] = "ESPPreview"
        t23.value6 = "Size"
        local uDim2_3 = UDim2.new(1, -16, 0, 168)
        t23.value9[t23.value6] = uDim2_3
        t23.value6 = "Position"
        local uDim2_4 = UDim2.new(0, 8, 0, 132)
        t23.value9[t23.value6] = uDim2_4
        t23.value6 = "BackgroundColor3"
        local Card = t9.value9.Card
        t23.value9[t23.value6] = Card
        t23.value6 = "BorderSizePixel"
        t23.value9[t23.value6] = 0
        t23.value6 = "ClipsDescendants"
        t23.value9[t23.value6] = true
        t23.value6 = "Parent"
        t23.value9[t23.value6] = Frame7
        local UICorner2 = Instance.new("UICorner", t23.value9)
        t23.value6 = "CornerRadius"
        local uDim3 = UDim.new(0, 10)
        UICorner2[t23.value6] = uDim3
        local UIStroke4 = Instance.new("UIStroke")
        t23.value6 = "Color"
        local Stroke = t9.value9.Stroke
        UIStroke4[t23.value6] = Stroke
        t23.value6 = "Parent"
        UIStroke4[t23.value6] = t23.value9
        local TextLabel5 = Instance.new("TextLabel")
        t23.value6 = "Size"
        local uDim2_5 = UDim2.new(1, -16, 0, 16)
        TextLabel5[t23.value6] = uDim2_5
        t23.value6 = "Position"
        local uDim2_6 = UDim2.new(0, 10, 0, 8)
        TextLabel5[t23.value6] = uDim2_6
        t23.value6 = "BackgroundTransparency"
        TextLabel5[t23.value6] = 1
        t23.value6 = "Text"
        TextLabel5[t23.value6] = "ESP PREVIEW"
        t23.value6 = "TextColor3"
        local TextDark = t9.value9.TextDark
        TextLabel5[t23.value6] = TextDark
        t23.value6 = "Font"
        local GothamMedium = Enum.Font.GothamMedium
        TextLabel5[t23.value6] = GothamMedium
        t23.value6 = "TextSize"
        TextLabel5[t23.value6] = 10
        t23.value6 = "TextXAlignment"
        local Left = Enum.TextXAlignment.Left
        TextLabel5[t23.value6] = Left
        t23.value6 = "Parent"
        TextLabel5[t23.value6] = t23.value9
        local Frame9 = Instance.new("Frame")
        Frame9.Size = UDim2.new(1, -16, 1, -32)
        Frame9.Position = UDim2.new(0, 8, 0, 28)
        Frame9.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
        Frame9.BorderSizePixel = 0
        Frame9.ClipsDescendants = true
        Frame9.Parent = t23.value9
        Instance.new("UICorner", Frame9).CornerRadius = UDim.new(0, 8)
        local TextLabel6 = Instance.new("TextLabel")
        TextLabel6.Name = "PrevName"
        TextLabel6.Size = UDim2.new(1, 0, 0, 14)
        TextLabel6.Position = UDim2.new(0, 0, 0, 4)
        TextLabel6.BackgroundTransparency = 1
        TextLabel6.Text = "Player"
        TextLabel6.Font = Enum.Font.GothamBold
        TextLabel6.TextSize = 11
        TextLabel6.ZIndex = 3
        TextLabel6.Parent = Frame9
        local TextLabel7 = Instance.new("TextLabel")
        TextLabel7.Name = "PrevDist"
        TextLabel7.Size = UDim2.new(1, 0, 0, 12)
        TextLabel7.Position = UDim2.new(0, 0, 0, 16)
        TextLabel7.BackgroundTransparency = 1
        TextLabel7.Text = "48 studs"
        TextLabel7.Font = Enum.Font.Code
        TextLabel7.TextSize = 9
        TextLabel7.TextColor3 = t9.value9.TextDark
        TextLabel7.ZIndex = 3
        TextLabel7.Parent = Frame9
        local ViewportFrame = Instance.new("ViewportFrame")
        ViewportFrame.Name = "R6Preview"
        ViewportFrame.Size = UDim2.new(1, -8, 1, -36)
        ViewportFrame.Position = UDim2.new(0, 4, 0, 30)
        ViewportFrame.BackgroundTransparency = 1
        ViewportFrame.BorderSizePixel = 0
        ViewportFrame.Parent = Frame9
        local WorldModel = Instance.new("WorldModel")
        WorldModel.Parent = ViewportFrame
        local Camera = Instance.new("Camera")
        Camera.Parent = ViewportFrame
        ViewportFrame.CurrentCamera = Camera
        local Model = Instance.new("Model")
        Model.Name = "R6Dummy"
        Model.Parent = WorldModel
        local function v709(p130, p131, p132, p133)
            local Part = Instance.new("Part")

            Part.Name = p130
            Part.Size = p131
            Part.CFrame = p132
            Part.Anchored = true
            Part.CanCollide = false
            Part.Material = Enum.Material.SmoothPlastic
            Part.Color = Color3.fromRGB(180, 180, 185)
            Part.TopSurface = Enum.SurfaceType.Smooth
            Part.BottomSurface = Enum.SurfaceType.Smooth

            if not p133 then
                p133 = Model
            end

            Part.Parent = p133

            return Part
        end
        local t27 = {
			v709("Torso", Vector3.new(2, 2, 1), CFrame.new(0, 1, 0)),
			v709("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 2.6, 0)),
			v709("Left Arm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 1, 0)),
			v709("Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 1, 0)),
			v709("Left Leg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -1, 0)),
			(v709("Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -1, 0)))
		}
        local function v711()
            local vector3 = Vector3.new(0, 1, 0)
            local v969 = CFrame.new(vector3) * CFrame.Angles(0, 0.55, 0) * CFrame.Angles(0.15, 0, 0) * CFrame.new(0, 0, 7.5)

            Camera.CFrame = CFrame.lookAt(v969.Position, vector3)
        end
        v711()
        local u712 = false
        local inputPosition
        ViewportFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                u712 = true
                inputPosition = input.Position
            end
        end)
        local InputEnded = t2.value3.InputEnded
        function t23.value11(p134)
            if p134.UserInputType == Enum.UserInputType.MouseButton1 or p134.UserInputType == Enum.UserInputType.Touch then
                u712 = false
                inputPosition = nil
            end
        end
        InputEnded:Connect(t23.value11)
        t2.value3.InputChanged:Connect(function(input)
            if not u712 then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local inputPosition2 = input.Position

                if inputPosition then
                    local v974 = inputPosition2.X - inputPosition.X
                    local v975 = inputPosition2.Y - inputPosition.Y
                    local _ = 0.55 - v974 * 0.01

                    math.clamp(0.15 - v975 * 0.01, -0.6, 0.6)
                    v711()
                end
            end
        end)
        t23.value10 = Instance.new("Frame")
        local value10 = t23.value10
        t23.value10 = value10
        t23.value11 = "Name"
        t23.value10[t23.value11] = "PrevBox"
        t23.value10 = value10
        t23.value11 = "AnchorPoint"
        t23.value13 = Vector2.new(0.5, 0.5)
        t23.value10[t23.value11] = t23.value13
        t23.value10 = value10
        t23.value11 = "Size"
        t23.value13 = UDim2.new(0, 52, 0, 90)
        t23.value10[t23.value11] = t23.value13
        t23.value10 = value10
        t23.value11 = "Position"
        t23.value13 = UDim2.new(0.5, 0, 0.55, 0)
        t23.value10[t23.value11] = t23.value13
        t23.value10 = value10
        t23.value11 = "BackgroundTransparency"
        t23.value10[t23.value11] = 1
        t23.value10 = value10
        t23.value11 = "BorderSizePixel"
        t23.value10[t23.value11] = 0
        t23.value10 = value10
        t23.value11 = "ZIndex"
        t23.value10[t23.value11] = 2
        t23.value10 = value10
        t23.value11 = "Parent"
        t23.value10[t23.value11] = Frame9
        t23.value11 = Instance.new("UIStroke")
        local value11 = t23.value11
        t23.value11 = value11
        t23.value12 = "Name"
        t23.value11[t23.value12] = "PrevBoxStroke"
        t23.value11 = value11
        t23.value12 = "Thickness"
        t23.value11[t23.value12] = 1.5
        t23.value11 = value11
        t23.value12 = "Parent"
        t23.value11[t23.value12] = value10
        t23.value12 = Instance.new("Frame")
        local value12 = t23.value12
        t23.value12 = value12
        t23.value13 = "Name"
        t23.value12[t23.value13] = "PrevHpTrack"
        t23.value12 = value12
        t23.value13 = "AnchorPoint"
        t23.value15 = Vector2.new(1, 0.5)
        t23.value12[t23.value13] = t23.value15
        t23.value12 = value12
        t23.value13 = "Size"
        t23.value15 = UDim2.new(0, 4, 0, 90)
        t23.value12[t23.value13] = t23.value15
        t23.value12 = value12
        t23.value13 = "Position"
        t23.value15 = UDim2.new(0.5, -32, 0.55, 0)
        t23.value12[t23.value13] = t23.value15
        t23.value12 = value12
        t23.value13 = "BackgroundColor3"
        t23.value15 = Color3.fromRGB(30, 30, 30)
        t23.value12[t23.value13] = t23.value15
        t23.value12 = value12
        t23.value13 = "BorderSizePixel"
        t23.value12[t23.value13] = 0
        t23.value12 = value12
        t23.value13 = "ZIndex"
        t23.value12[t23.value13] = 2
        t23.value12 = value12
        t23.value13 = "Parent"
        t23.value12[t23.value13] = Frame9
        t23.value13 = Instance.new("UICorner", value12)
        t23.value12 = "CornerRadius"
        t23.value15 = UDim.new(1, 0)
        t23.value13[t23.value12] = t23.value15
        t23.value13 = Instance.new("Frame")
        t23.value12 = "Name"
        t23.value13[t23.value12] = "PrevHpFill"
        t23.value12 = "Size"
        t23.value15 = UDim2.new(1, 0, 0.72, 0)
        t23.value13[t23.value12] = t23.value15
        t23.value12 = "Position"
        t23.value15 = UDim2.new(0, 0, 0.28, 0)
        t23.value13[t23.value12] = t23.value15
        t23.value12 = "BackgroundColor3"
        t23.value15 = Color3.fromRGB(80, 255, 120)
        t23.value13[t23.value12] = t23.value15
        t23.value12 = "BorderSizePixel"
        t23.value13[t23.value12] = 0
        t23.value12 = "Parent"
        t23.value13[t23.value12] = value12
        t23.value14 = Instance.new("UICorner", t23.value13)
        t23.value12 = "CornerRadius"
        t23.value16 = UDim.new(1, 0)
        t23.value14[t23.value12] = t23.value16
        t23.value14 = Instance.new("Frame")
        local value14 = t23.value14
        t23.value14 = value14
        t23.value15 = "Name"
        t23.value14[t23.value15] = "PrevTracer"
        t23.value14 = value14
        t23.value15 = "AnchorPoint"
        t23.value17 = Vector2.new(0.5, 1)
        t23.value14[t23.value15] = t23.value17
        t23.value14 = value14
        t23.value15 = "BorderSizePixel"
        t23.value14[t23.value15] = 0
        t23.value14 = value14
        t23.value15 = "ZIndex"
        t23.value14[t23.value15] = 2
        t23.value14 = value14
        t23.value15 = "Parent"
        t23.value14[t23.value15] = Frame9
        function t23.value15(p135)
            local AbsoluteSize = Frame9.AbsoluteSize

            if AbsoluteSize.X < 4 or AbsoluteSize.Y < 4 then
                return
            end

            local vector2_10 = Vector2.new(AbsoluteSize.X * 0.5, AbsoluteSize.Y - 4)
            local v980 = Vector2.new(AbsoluteSize.X * 0.5, AbsoluteSize.Y * 0.55 + 45) - vector2_10
            local Magnitude = v980.Magnitude
            local v982 = math.deg((math.atan2(v980.Y, v980.X))) - 90

            value14.Size = UDim2.new(0, 2, 0, (math.max(Magnitude, 2)))
            value14.Position = UDim2.new(0, vector2_10.X, 0, vector2_10.Y)
            value14.Rotation = v982
            value14.BackgroundColor3 = p135
        end
        local value15 = t23.value15
        local function v720()
            local Accent = t9.value9.Accent

            if t9.value10.espTeamColors then
                Accent = Color3.fromRGB(50, 120, 255)
            end

            TextLabel6.TextColor3 = Accent
            TextLabel6.Visible = t9.value10.espNames ~= false
            TextLabel7.Visible = t9.value10.espDistance ~= false
            value10.Visible = t9.value10.espBoxes ~= false
            value11.Color = Accent
            value11.Enabled = t9.value10.espBoxes ~= false

            if t9.value10.espChams then
                for _, v in ipairs(t27) do
                    v.Color = Accent
                    v.Material = Enum.Material.ForceField
                end
            else
                for _, v in ipairs(t27) do
                    v.Color = Color3.fromRGB(180, 180, 185)
                    v.Material = Enum.Material.SmoothPlastic
                end
            end

            value12.Visible = t9.value10.espHealth ~= false
            value14.Visible = t9.value10.espTracers ~= false

            if t9.value10.espTracers ~= false then
                value15(Accent)
            end

            TextLabel6.Text = not t9.value10.espTeamColors and "Player" or "Guard"
        end
        t23.value16 = t9.value22
        t23.value17 = "refreshESPPreview"
        t23.value16[t23.value17] = v720
        Frame9:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            task.defer(v720)
        end)
        task.defer(v720)
        t23.value17 = Instance.new("Frame")
        local value17 = t23.value17
        t23.value17 = value17
        t23.value18 = "Size"
        t23.value20 = UDim2.new(1, -8, 0, 12)
        t23.value17[t23.value18] = t23.value20
        t23.value17 = value17
        t23.value18 = "Position"
        t23.value20 = UDim2.new(0, 4, 1, -16)
        t23.value17[t23.value18] = t23.value20
        t23.value17 = value17
        t23.value18 = "BackgroundTransparency"
        t23.value17[t23.value18] = 1
        t23.value17 = value17
        t23.value18 = "Parent"
        t23.value17[t23.value18] = Frame9
        function t23.value17(p136, p137, p138)
            local Frame10 = Instance.new("Frame")

            Frame10.Size = UDim2.new(0, 8, 0, 8)
            Frame10.Position = UDim2.new(0, p136, 0.5, -4)
            Frame10.BackgroundColor3 = p137
            Frame10.BorderSizePixel = 0
            Frame10.Parent = value17
            Instance.new("UICorner", Frame10).CornerRadius = UDim.new(1, 0)

            local TextLabel8 = Instance.new("TextLabel")

            TextLabel8.Size = UDim2.new(0, 36, 1, 0)
            TextLabel8.Position = UDim2.new(0, p136 + 10, 0, 0)
            TextLabel8.BackgroundTransparency = 1
            TextLabel8.Text = p138
            TextLabel8.TextColor3 = t9.value9.TextDark
            TextLabel8.Font = Enum.Font.Gotham
            TextLabel8.TextSize = 8
            TextLabel8.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel8.Parent = value17
        end
        t23.value17(4, Color3.fromRGB(50, 120, 255), "Guard")
        t23.value17(58, Color3.fromRGB(255, 140, 40), "Inmate")
        t23.value17(112, Color3.fromRGB(255, 60, 60), "Crime")
        t23.value19 = Instance.new("Frame")
        t23.value18 = "Size"
        t23.value21 = UDim2.new(1, -16, 0, 72)
        t23.value19[t23.value18] = t23.value21
        t23.value18 = "Position"
        t23.value21 = UDim2.new(0, 8, 0, 308)
        t23.value19[t23.value18] = t23.value21
        t23.value18 = "BackgroundColor3"
        t23.value20 = t9.value9.Card
        t23.value19[t23.value18] = t23.value20
        t23.value18 = "BorderSizePixel"
        t23.value19[t23.value18] = 0
        t23.value18 = "Parent"
        t23.value19[t23.value18] = Frame7
        t23.value20 = Instance.new("UICorner", t23.value19)
        t23.value18 = "CornerRadius"
        t23.value22 = UDim.new(0, 10)
        t23.value20[t23.value18] = t23.value22
        t23.value20 = Instance.new("UIStroke")
        t23.value18 = "Color"
        t23.value21 = t9.value9.Stroke
        t23.value20[t23.value18] = t23.value21
        t23.value18 = "Parent"
        t23.value20[t23.value18] = t23.value19
        t23.value21 = Instance.new("TextLabel")
        t23.value18 = "Size"
        t23.value23 = UDim2.new(1, -16, 1, -12)
        t23.value21[t23.value18] = t23.value23
        t23.value18 = "Position"
        t23.value23 = UDim2.new(0, 8, 0, 6)
        t23.value21[t23.value18] = t23.value23
        t23.value18 = "BackgroundTransparency"
        t23.value21[t23.value18] = 1
        t23.value18 = "Text"
        t23.value21[t23.value18] = "[nexus] loaded successfully\n[nexus] hooks ready\n[nexus] ui theme: hub"
        t23.value18 = "TextColor3"
        t23.value22 = t9.value9.TextDark
        t23.value21[t23.value18] = t23.value22
        t23.value18 = "Font"
        t23.value22 = Enum.Font.Code
        t23.value21[t23.value18] = t23.value22
        t23.value18 = "TextSize"
        t23.value21[t23.value18] = 10
        t23.value18 = "TextXAlignment"
        t23.value22 = Enum.TextXAlignment.Left
        t23.value21[t23.value18] = t23.value22
        t23.value18 = "TextYAlignment"
        t23.value22 = Enum.TextYAlignment.Top
        t23.value21[t23.value18] = t23.value22
        t23.value18 = "Parent"
        t23.value21[t23.value18] = t23.value19
    end

    local function v722()
        local ScrollingFrame = Instance.new("ScrollingFrame")

        ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
        ScrollingFrame.BackgroundTransparency = 1
        ScrollingFrame.BorderSizePixel = 0
        ScrollingFrame.ScrollBarThickness = 2
        ScrollingFrame.ScrollBarImageColor3 = t9.value9.Accent
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        ScrollingFrame.ClipsDescendants = true
        ScrollingFrame.Visible = false
        ScrollingFrame.Parent = t24.value40

        local UIPadding = Instance.new("UIPadding")

        UIPadding.PaddingTop = UDim.new(0, 6)
        UIPadding.PaddingBottom = UDim.new(0, 12)
        UIPadding.PaddingLeft = UDim.new(0, 8)
        UIPadding.PaddingRight = UDim.new(0, 8)
        UIPadding.Parent = ScrollingFrame

        local UIListLayout = Instance.new("UIListLayout")

        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 4)
        UIListLayout.Parent = ScrollingFrame
        UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 16)
        end)

        return ScrollingFrame
    end

    local v723 = v722()
    local v724 = v722()

    t23.value4 = v722()
    t23.value5 = v722()
    t23.value6 = v722()
    t24.value41 = v723
    t24.value42 = v724
    t24.value43 = t23.value4
    t24.value44 = t23.value5
    t24.value45 = t23.value6
    t23.value6 = t24.value41
    t23.value8 = "Visible"
    t23.value6[t23.value8] = true

    local function v725(p139)
        t9.value10.tab = p139
        t24.value41.Visible = p139 == "Home"
        t24.value42.Visible = p139 == "Commands"
        t24.value43.Visible = p139 == "ESP"
        t24.value44.Visible = p139 == "Settings"
        t24.value45.Visible = p139 == "Tutorial"

        local function v997(p140, p141)
            p140.TextColor3 = p141 and t9.value9.Text or t9.value9.TextDark
            p140.BackgroundColor3 = p141 and t9.value9.Element or t9.value9.Sidebar
            p140.Font = p141 and Enum.Font.GothamMedium or Enum.Font.Gotham
        end

        v997(t24.value36, p139 == "Home")
        v997(t24.value35, p139 == "Commands")
        v997(t24.value37, p139 == "ESP")
        v997(t24.value38, p139 == "Settings")
        v997(t24.value39, p139 == "Tutorial")
    end

    t23.value8 = t9.value22
    t23.value9 = "setActiveTab"
    t23.value8[t23.value9] = v725
    t23.value8 = t24.value36.MouseButton1Click
    t23.value8:Connect(function()
        v725("Home")
    end)
    t23.value8 = t24.value35.MouseButton1Click
    t23.value8:Connect(function()
        v725("Commands")
    end)
    t23.value8 = t24.value37.MouseButton1Click
    t23.value8:Connect(function()
        v725("ESP")
    end)
    t23.value8 = t24.value38.MouseButton1Click
    t23.value8:Connect(function()
        v725("Settings")
    end)
    t24.value39.MouseButton1Click:Connect(function()
        v725("Tutorial")
    end)
    v725("Home")
    t23.value8 = t24.value6
    t23.value9 = "AnchorPoint"
    t23.value8[t23.value9] = Vector2.new(0.5, 0.5)
    t23.value8 = t24.value6
    t23.value9 = "Position"
    t23.value8[t23.value9] = UDim2.new(0.5, 0, 0.5, 0)
    t23.value9 = Instance.new("TextButton")
    t23.value8 = "Name"
    t23.value9[t23.value8] = "MobileOpen"
    t23.value8 = "AnchorPoint"
    t23.value9[t23.value8] = Vector2.new(1, 0)
    t23.value8 = "Position"
    t23.value9[t23.value8] = UDim2.new(1, -12, 0, 48)
    t23.value8 = "Size"
    t23.value9[t23.value8] = t9.value1 and UDim2.new(0, 48, 0, 48) or UDim2.new(0, 44, 0, 44)
    t23.value8 = "BackgroundColor3"
    t23.value9[t23.value8] = t9.value9.Accent
    t23.value8 = "Text"
    t23.value9[t23.value8] = "N"
    t23.value8 = "TextColor3"
    t23.value9[t23.value8] = Color3.new(1, 1, 1)
    t23.value8 = "Font"
    t23.value9[t23.value8] = Enum.Font.GothamBold
    t23.value8 = "TextSize"
    t23.value9[t23.value8] = not t9.value1 and 16 or 18
    t23.value8 = "Visible"
    t23.value9[t23.value8] = false
    t23.value8 = "ZIndex"
    t23.value9[t23.value8] = 200
    t23.value8 = "Parent"
    t23.value9[t23.value8] = t24.value1

    local UICorner = Instance.new("UICorner", t23.value9)

    t23.value8 = "CornerRadius"
    UICorner[t23.value8] = UDim.new(0, 0)
    table.insert(t9.value17, {
		obj = t23.value9,
		prop = "BackgroundColor3",
		key = "Accent"
	})
    t23.value8 = t9.value22
    t23.value8.MobileOpenBtn = t23.value9

    local function v727(p142)
        t9.value10.minimized = not p142
        t24.value6.Visible = p142

        if t9.value22.MobileOpenBtn then
            t9.value22.MobileOpenBtn.Visible = not p142
        end

        if p142 then
            t24.value6.AnchorPoint = Vector2.new(0.5, 0.5)
            t24.value6.Position = UDim2.new(0.5, 0, 0.5, 0)

            if t9.value1 then
                t24.value6.Size = UDim2.new(0.96, 0, 0.9, 0)
            else
                t24.value6.Size = UDim2.new(0, 980, 0, 600)
            end

            t24.value40.Visible = true
            t24.value30.Visible = true
            t24.value10(true)
        else
            if t9.value22.closeColorPicker then
                t9.value22.closeColorPicker()
            end

            t24.value10(false)
        end

        if t9.value10.freecam then
            t9.value52()
        end
    end

    t9.value22.setMenuVisible = v727
    t23.value9.MouseButton1Click:Connect(function()
        v727(true)
    end)
    v648.MouseButton1Click:Connect(function()
        t9.value10.minimized = true
        t24.value6.Visible = false

        if t9.value22.MobileOpenBtn then
            t9.value22.MobileOpenBtn.Visible = true
        end

        if t9.value22.closeColorPicker then
            t9.value22.closeColorPicker()
        end

        t24.value10(false)

        if t9.value10.freecam then
            t9.value52()
        end

        if t9.value22.notify then
            t9.value22.notify("Minimized", not t9.value1 and "press Z or tap Nexus to reopen" or "tap Nexus to reopen")
        end
    end)

    if t9.value1 then
        local Frame11 = Instance.new("Frame")

        Frame11.Name = "FlyPad"
        Frame11.AnchorPoint = Vector2.new(1, 1)
        Frame11.Position = UDim2.new(1, -16, 1, -24)
        Frame11.Size = UDim2.new(0, 168, 0, 168)
        Frame11.BackgroundTransparency = 1
        Frame11.Visible = false
        Frame11.ZIndex = 180
        Frame11.Parent = t24.value1
        t9.value22.FlyPad = Frame11

        local function v729(p143, p144, p145, p146)
            local TextButton = Instance.new("TextButton")

            if not p146 then
                p146 = UDim2.new(0, 48, 0, 48)
            end

            TextButton.Size = p146
            TextButton.Position = p145
            TextButton.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
            TextButton.BackgroundTransparency = 0.25
            TextButton.Text = p143
            TextButton.TextColor3 = Color3.new(1, 1, 1)
            TextButton.Font = Enum.Font.GothamBold
            TextButton.TextSize = 16
            TextButton.ZIndex = 181
            TextButton.Parent = Frame11
            Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 10)
            TextButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    t9.value10.mobileKeys[p144] = true
                end
            end)
            TextButton.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    t9.value10.mobileKeys[p144] = false
                end
            end)

            return TextButton
        end

        v729("W", "W", UDim2.new(0, 56, 0, 8))
        v729("A", "A", UDim2.new(0, 8, 0, 56))
        v729("S", "S", UDim2.new(0, 56, 0, 104))
        v729("D", "D", UDim2.new(0, 104, 0, 56))
        v729("↑", "Up", UDim2.new(0, 120, 0, 8), UDim2.new(0, 40, 0, 40))
        v729("↓", "Down", UDim2.new(0, 120, 0, 112), UDim2.new(0, 40, 0, 40))

        function t9.value22.setFlyPadVisible(p147)
            if t9.value22.FlyPad then
                t9.value22.FlyPad.Visible = not not p147
            end
        end
    end

    function t24.value46()
        for _, v in pairs(t9.value19) do
            v()
        end
    end

    for _, v in ipairs({
		t24.value41,
		t24.value42,
		t24.value43,
		t24.value44,
		t24.value45
	}) do
        v:GetPropertyChangedSignal("CanvasPosition"):Connect(t24.value46)
    end

    local function v732(p148, p149, p150)
        local TextBox = Instance.new("TextBox")

        TextBox.Size = UDim2.new(1, 0, 0, 26)
        TextBox.BackgroundColor3 = t9.value9.Element
        TextBox.PlaceholderText = p149
        TextBox.PlaceholderColor3 = t9.value9.TextDark
        TextBox.Text = ""
        TextBox.TextColor3 = t9.value9.Text
        TextBox.Font = Enum.Font.Code
        TextBox.TextSize = 11
        TextBox.ClearTextOnFocus = false
        TextBox.BorderSizePixel = 0
        TextBox.TextXAlignment = Enum.TextXAlignment.Left
        TextBox.Parent = p148

        local UIPadding = Instance.new("UIPadding")

        UIPadding.PaddingLeft = UDim.new(0, 8)
        UIPadding.PaddingRight = UDim.new(0, 8)
        UIPadding.Parent = TextBox
        table.insert(t9.value17, {
			obj = TextBox,
			prop = "BackgroundColor3",
			key = "Element"
		})
        TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            p150(TextBox.Text)
        end)
        TextBox.FocusLost:Connect(function()
            p150(TextBox.Text)
        end)

        return TextBox
    end

    function t24.value47(p151)
        while p151 do
            if p151 == t24.value41 then
                return "Home"
            end

            if p151 == t24.value42 then
                return "Commands"
            end

            if p151 == t24.value43 then
                return "ESP"
            end

            if p151 == t24.value44 then
                return "Settings"
            end

            if p151 == t24.value45 then
                return "Tutorial"
            end

            p151 = p151.Parent
        end

        return nil
    end

    local function v733(p152, p153, p154, p155, p156, p157)
        local Frame12 = Instance.new("Frame")

        Frame12.Size = UDim2.new(1, 0, 0, 30)
        Frame12.BackgroundTransparency = 1
        Frame12.Parent = p152
        v670(Frame12, p153, t24.value47(Frame12))

        local TextLabel9 = Instance.new("TextLabel")

        TextLabel9.Size = UDim2.new(0.55, 0, 0, 12)
        TextLabel9.BackgroundTransparency = 1
        TextLabel9.Text = p153
        TextLabel9.TextColor3 = t9.value9.Text
        TextLabel9.Font = Enum.Font.Gotham
        TextLabel9.TextSize = 11
        TextLabel9.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel9.Parent = Frame12

        local TextLabel10 = Instance.new("TextLabel")

        TextLabel10.Size = UDim2.new(0.4, 0, 0, 12)
        TextLabel10.Position = UDim2.new(0.6, 0, 0, 0)
        TextLabel10.BackgroundTransparency = 1
        TextLabel10.Text = tostring(p156)
        TextLabel10.TextColor3 = t9.value9.Accent
        TextLabel10.Font = Enum.Font.Code
        TextLabel10.TextSize = 11
        TextLabel10.TextXAlignment = Enum.TextXAlignment.Right
        TextLabel10.Parent = Frame12
        table.insert(t9.value17, {
			obj = TextLabel10,
			prop = "TextColor3",
			key = "Accent"
		})

        local Frame13 = Instance.new("Frame")

        Frame13.Size = UDim2.new(1, 0, 0, 3)
        Frame13.Position = UDim2.new(0, 0, 0, 18)
        Frame13.BackgroundColor3 = t9.value9.Track
        Frame13.BorderSizePixel = 0
        Frame13.Parent = Frame12
        table.insert(t9.value17, {
			obj = Frame13,
			prop = "BackgroundColor3",
			key = "Track"
		})

        local _Instance2 = Instance
        local v1032 = (p156 - p154) / (p155 - p154)
        local v1033 = _Instance2.new("Frame")

        v1033.Size = UDim2.new(v1032, 0, 1, 0)
        v1033.BackgroundColor3 = t9.value9.Accent
        v1033.BorderSizePixel = 0
        v1033.Parent = Frame13
        table.insert(t9.value17, {
			obj = v1033,
			prop = "BackgroundColor3",
			key = "Accent"
		})

        local Frame14 = Instance.new("Frame")

        Frame14.Size = UDim2.new(0, 8, 0, 8)
        Frame14.Position = UDim2.new(v1032, -4, 0.5, -4)
        Frame14.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
        Frame14.BorderSizePixel = 0
        Frame14.ZIndex = 2
        Frame14.Parent = Frame13

        local u1035 = false

        local function v1036(p158)
            local v1275 = math.clamp(math.floor(p158 + 0.5), p154, p155)
            local v1276 = (v1275 - p154) / (p155 - p154)
            local v1277 = v1033
            local v1278 = Frame14
            local v1279 = TextLabel10
            local uDim2 = UDim2.new(v1276, 0, 1, 0)
            local uDim2_7 = UDim2.new(v1276, -4, 0.5, -4)
            local str3 = tostring(v1275)

            v1277.Size = uDim2
            v1278.Position = uDim2_7
            v1279.Text = str3
            p157(v1275)
        end

        Frame13.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                u1035 = true
                v1036(p154 + math.clamp((input.Position.X - Frame13.AbsolutePosition.X) / Frame13.AbsoluteSize.X, 0, 1) * (p155 - p154))
            end
        end)
        t2.value3.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                u1035 = false
            end
        end)
        t2.value3.InputChanged:Connect(function(input)
            if u1035 and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                v1036(p154 + math.clamp((input.Position.X - Frame13.AbsolutePosition.X) / Frame13.AbsoluteSize.X, 0, 1) * (p155 - p154))
            end
        end)
    end

    function t24.value48(p159, p160)
        local Frame15 = Instance.new("Frame")

        Frame15.Size = UDim2.new(1, 0, 0, 0)
        Frame15.AutomaticSize = Enum.AutomaticSize.Y
        Frame15.BackgroundColor3 = t9.value9.Card
        Frame15.BorderSizePixel = 0
        Frame15.Parent = p159
        Instance.new("UICorner", Frame15).CornerRadius = UDim.new(0, 10)

        local UIStroke5 = Instance.new("UIStroke")

        UIStroke5.Color = t9.value9.Stroke
        UIStroke5.Thickness = 1
        UIStroke5.Parent = Frame15

        local Frame16 = Instance.new("Frame")

        Frame16.Size = UDim2.new(1, 0, 0, 0)
        Frame16.AutomaticSize = Enum.AutomaticSize.Y
        Frame16.BackgroundTransparency = 1
        Frame16.ZIndex = 2
        Frame16.Parent = Frame15

        local UIPadding = Instance.new("UIPadding")

        UIPadding.PaddingTop = UDim.new(0, 10)
        UIPadding.PaddingBottom = UDim.new(0, 10)
        UIPadding.PaddingLeft = UDim.new(0, 12)
        UIPadding.PaddingRight = UDim.new(0, 12)
        UIPadding.Parent = Frame16

        local UIListLayout = Instance.new("UIListLayout")

        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 2)
        UIListLayout.Parent = Frame16

        if p160 then
            local TextLabel11 = Instance.new("TextLabel")

            TextLabel11.Size = UDim2.new(1, 0, 0, 16)
            TextLabel11.BackgroundTransparency = 1
            TextLabel11.Text = string.upper(p160)
            TextLabel11.TextColor3 = t9.value9.TextDark
            TextLabel11.Font = Enum.Font.GothamMedium
            TextLabel11.TextSize = 10
            TextLabel11.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel11.Parent = Frame16
            v670(Frame15, p160, t24.value47(Frame15))
        end

        table.insert(t9.value17, {
			obj = Frame15,
			prop = "BackgroundColor3",
			key = "Card"
		})
        table.insert(t9.value17, {
			obj = UIStroke5,
			prop = "Color",
			key = "Stroke"
		})

        return Frame16, Frame15
    end

    local function v734(p161, p162, p163)
        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(1, 0, 0, 28)
        TextButton.BackgroundColor3 = t9.value9.Element
        TextButton.Text = p162
        TextButton.TextColor3 = t9.value9.Text
        TextButton.Font = Enum.Font.Gotham
        TextButton.TextSize = 12
        TextButton.BorderSizePixel = 0
        TextButton.Parent = p161
        Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 6)
        v670(TextButton, p162, t24.value47(TextButton))
        TextButton.MouseEnter:Connect(function()
            TextButton.BackgroundColor3 = t9.value9.ElementHover
        end)
        TextButton.MouseLeave:Connect(function()
            TextButton.BackgroundColor3 = t9.value9.Element
        end)
        TextButton.MouseButton1Click:Connect(p163)
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "BackgroundColor3",
			key = "Element"
		})

        return TextButton
    end
    local function v735(p164, p165, p166, p167, p168)
        local _Instance3 = Instance
        local v1068 = not t9.value1 and 40 or 44
        local v1069 = _Instance3.new("Frame")
        v1069.Size = UDim2.new(1, 0, 0, v1068)
        v1069.BackgroundTransparency = 1
        v1069.Parent = p164
        local v1070 = v670
        if not p166 then
            p166 = ""
        end
        v1070(v1069, p165 .. " " .. p166, t24.value47(v1069))
        local TextLabel12 = Instance.new("TextLabel")
        TextLabel12.Size = UDim2.new(1, -56, 0, 18)
        TextLabel12.Position = UDim2.new(0, 4, 0.5, -9)
        TextLabel12.BackgroundTransparency = 1
        TextLabel12.Text = p165
        TextLabel12.TextColor3 = t9.value9.Text
        TextLabel12.Font = Enum.Font.Gotham
        TextLabel12.TextSize = 13
        TextLabel12.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel12.Parent = v1069
        local Frame17 = Instance.new("Frame")
        Frame17.Size = UDim2.new(0, 42, 0, 24)
        Frame17.Position = UDim2.new(1, -46, 0.5, -12)
        Frame17.BackgroundColor3 = p167 and t9.value9.Toggle or t9.value9.Track
        Frame17.BorderSizePixel = 0
        Frame17.Parent = v1069
        Instance.new("UICorner", Frame17).CornerRadius = UDim.new(1, 0)
        local Frame18 = Instance.new("Frame")
        Frame18.Size = UDim2.new(0, 18, 0, 18)
        Frame18.Position = p167 and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        Frame18.BackgroundColor3 = p167 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(200, 200, 200)
        Frame18.BorderSizePixel = 0
        Frame18.Parent = Frame17
        Instance.new("UICorner", Frame18).CornerRadius = UDim.new(1, 0)
        local u1074 = p167
        local function v1075(p169)
            u1074 = p169

            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            t2.value4:Create(Frame17, tweenInfo, {
				BackgroundColor3 = u1074 and t9.value9.Toggle or t9.value9.Track
			}):Play()

            local value4 = t2.value4
            local v1290 = Frame18
            local v1291 = u1074 and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            local v1292 = u1074 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(200, 200, 200)

            value4:Create(v1290, tweenInfo, {
				Position = v1291,
				BackgroundColor3 = v1292
			}):Play()
            p168(u1074)
        end
        table.insert(t9.value18, function()
            if Frame17.Parent then
                Frame17.BackgroundColor3 = u1074 and t9.value9.Toggle or t9.value9.Track
                Frame18.BackgroundColor3 = u1074 and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(200, 200, 200)
            end
        end)
        local TextButton = Instance.new("TextButton")
        TextButton.Size = UDim2.new(1, 0, 1, 0)
        TextButton.BackgroundTransparency = 1
        TextButton.Text = ""
        TextButton.Parent = v1069
        TextButton.MouseButton1Click:Connect(function()
            v1075(not u1074)
        end)

        return v1075
    end

    function t24.value49(p170)
        return p170 and tostring(p170):gsub("Enum.KeyCode.", "") or "None"
    end

    t24.value50 = {}

    function t24.value51()
        t24.value7.BackgroundColor3 = t9.value9.Background
        t24.value11.BackgroundColor3 = t9.value9.Background
        t24.value30.BackgroundColor3 = t9.value9.Sidebar
        t24.value40.BackgroundColor3 = t9.value9.Background
        t24.value9.Color = Color3.fromRGB(40, 40, 40)
        t24.value9.Thickness = 1
        t24.value9.Transparency = 0.35
        t24.value8.CornerRadius = UDim.new(0, 14)
        t24.value18.TextColor3 = Color3.fromRGB(255, 255, 255)
        if t24.value16 then
            t24.value16.BackgroundColor3 = t24.value13
        end
        if t24.value15 then
            t24.value15.BackgroundColor3 = t24.value12
        end
        if t24.value17 then
            t24.value17.BackgroundColor3 = t24.value14
        end
        t24.value41.ScrollBarImageColor3 = t9.value9.Accent
        t24.value42.ScrollBarImageColor3 = t9.value9.Accent
        t24.value43.ScrollBarImageColor3 = t9.value9.Accent
        t24.value44.ScrollBarImageColor3 = t9.value9.Accent
        t24.value45.ScrollBarImageColor3 = t9.value9.Accent
        t24.value3.Color = t9.value9.Accent
        t24.value31.BackgroundColor3 = t9.value9.Stroke
        t24.value22.BackgroundColor3 = t9.value9.Card
        t24.value23.Color = t9.value9.Stroke
        t24.value24.BackgroundColor3 = t9.value9.Accent
        t24.value25.TextColor3 = t9.value9.Text
        t24.value26.TextColor3 = t9.value9.TextDark
        t24.value27.BackgroundColor3 = t9.value9.Element
        t24.value27.TextColor3 = t9.value9.Text
        for v1057, v1058 in ipairs(t9.value17) do

            local v1059 = v1058

            if v1059.obj and v1059.obj.Parent then
                pcall(function()
                    v1059.obj[v1059.prop] = v1059.key == "Accent" and t9.value9.Accent or t9.value9[v1059.key]
                end)
            end
        end
        for _, v in ipairs(t9.value18) do
            pcall(v)
        end
        v725(t9.value10.tab)
        if t9.value10.silentHL and t9.value10.silentHL.Parent then
            t9.value10.silentHL.FillColor = t9.value9.Accent
            t9.value10.silentHL.OutlineColor = t9.value9.Accent
        end
        if t9.value22.refreshESPPreview then
            pcall(t9.value22.refreshESPPreview)
        end
    end

    local function v736(p171, p172, p173)
        local Frame19 = Instance.new("Frame")

        Frame19.Size = UDim2.new(1, 0, 0, 24)
        Frame19.BackgroundTransparency = 1
        Frame19.Parent = p171

        local TextLabel13 = Instance.new("TextLabel")

        TextLabel13.Size = UDim2.new(0.5, 0, 1, 0)
        TextLabel13.BackgroundTransparency = 1
        TextLabel13.Text = p172
        TextLabel13.TextColor3 = t9.value9.Text
        TextLabel13.Font = Enum.Font.Gotham
        TextLabel13.TextSize = 12
        TextLabel13.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel13.Parent = Frame19

        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(0, 68, 0, 20)
        TextButton.Position = UDim2.new(1, -68, 0.5, -10)
        TextButton.BackgroundColor3 = t9.value9.Element

        local v1091 = t9.value15[p173]

        TextButton.Text = t24.value49(v1091)
        TextButton.TextColor3 = t9.value9.Accent
        TextButton.Font = Enum.Font.Code
        TextButton.TextSize = 11
        TextButton.BorderSizePixel = 0
        TextButton.Parent = Frame19
        t24.value50[p173] = TextButton
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "TextColor3",
			key = "Accent"
		})
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "BackgroundColor3",
			key = "Element"
		})
        TextButton.MouseButton1Click:Connect(function()
            if t9.value10.listening == p173 then
                t9.value10.listening = nil

                local v1293 = TextButton
                local v1294 = t9.value15[p173]

                v1293.Text = t24.value49(v1294)
                TextButton.BackgroundColor3 = t9.value9.Element
                TextButton.TextColor3 = t9.value9.Accent

                return
            end

            t9.value10.listening = p173
            TextButton.Text = "..."
            TextButton.BackgroundColor3 = t9.value9.Accent
            TextButton.TextColor3 = Color3.new(1, 1, 1)
        end)
    end

    t9.value22.applyTheme = t24.value51

    function t24.value52()
        local v1094 = tonumber(os.date("%H")) or 0

        if v1094 <= 10 then
            return "Good Morning"
        end

        if v1094 < 16 then
            return "Good Evening"
        end

        return "Good Afternoon"
    end
    function t24.value53(p174)
        local u1093 = false

        pcall(function()
            if setclipboard then
                setclipboard(p174)
                u1093 = true

                return
            end

            if toclipboard then
                toclipboard(p174)
                u1093 = true

                return
            end

            if Clipboard and Clipboard.set then
                Clipboard.set(p174)
                u1093 = true
            end
        end)

        return u1093
    end

    local v737 = t24.value48(t24.value41, nil)
    local Frame20 = Instance.new("Frame")

    Frame20.Size = UDim2.new(1, 0, 0, 100)
    Frame20.BackgroundTransparency = 1
    Frame20.Parent = v737
    t24.value54 = Instance.new("ImageLabel")
    t24.value54.Size = UDim2.new(0, 72, 0, 72)
    t24.value54.Position = UDim2.new(0, 6, 0, 8)
    t24.value54.BackgroundColor3 = t9.value9.Element
    t24.value54.BorderSizePixel = 0
    t24.value54.Image = ""
    t24.value54.Parent = Frame20
    Instance.new("UICorner", t24.value54).CornerRadius = UDim.new(0, 10)
    table.insert(t9.value17, {
		obj = t24.value54,
		prop = "BackgroundColor3",
		key = "Element"
	})

    local UIStroke6 = Instance.new("UIStroke")

    UIStroke6.Color = t9.value9.Accent
    UIStroke6.Thickness = 1.2
    UIStroke6.Transparency = 0.35
    UIStroke6.Parent = t24.value54
    table.insert(t9.value17, {
		obj = UIStroke6,
		prop = "Color",
		key = "Accent"
	})
    t23.value10 = Instance.new("TextLabel")
    t24.value55 = t23.value10
    t23.value10 = t24.value55
    t23.value11 = "Size"
    t23.value10[t23.value11] = UDim2.new(1, -96, 0, 24)
    t23.value10 = t24.value55
    t23.value11 = "Position"
    t23.value10[t23.value11] = UDim2.new(0, 92, 0, 8)
    t23.value10 = t24.value55
    t23.value11 = "BackgroundTransparency"
    t23.value10[t23.value11] = 1
    t23.value10 = t24.value55
    t23.value11 = "Text"
    t23.value14 = t24.value52()
    t23.value13 = ", @" .. t2.value8.Name .. "!"
    t23.value10[t23.value11] = t23.value14 .. t23.value13
    t23.value10 = t24.value55
    t23.value11 = "TextColor3"
    t23.value10[t23.value11] = t9.value9.Text
    t23.value10 = t24.value55
    t23.value11 = "Font"
    t23.value10[t23.value11] = Enum.Font.GothamMedium
    t23.value10 = t24.value55
    t23.value11 = "TextSize"
    t23.value10[t23.value11] = 16
    t23.value10 = t24.value55
    t23.value11 = "TextXAlignment"
    t23.value10[t23.value11] = Enum.TextXAlignment.Left
    t23.value10 = t24.value55
    t23.value11 = "TextTruncate"
    t23.value10[t23.value11] = Enum.TextTruncate.AtEnd
    t23.value10 = t24.value55
    t23.value11 = "Parent"
    t23.value10[t23.value11] = Frame20
    table.insert(t9.value17, {
		obj = t24.value55,
		prop = "TextColor3",
		key = "Text"
	})
    t23.value11 = Instance.new("Frame")
    t24.value56 = t23.value11
    t23.value11 = t24.value56
    t23.value12 = "Size"
    t23.value11[t23.value12] = UDim2.new(1, -96, 0, 60)
    t23.value11 = t24.value56
    t23.value12 = "Position"
    t23.value11[t23.value12] = UDim2.new(0, 92, 0, 34)
    t23.value11 = t24.value56
    t23.value12 = "BackgroundTransparency"
    t23.value11[t23.value12] = 1
    t23.value11 = t24.value56
    t23.value12 = "Parent"
    t23.value11[t23.value12] = Frame20
    t23.value12 = Instance.new("UIListLayout")
    t23.value11 = "SortOrder"
    t23.value12[t23.value11] = Enum.SortOrder.LayoutOrder
    t23.value11 = "Padding"
    t23.value12[t23.value11] = UDim.new(0, 2)
    t23.value11 = "Parent"
    t23.value13 = t24.value56
    t23.value12[t23.value11] = t23.value13

    function t23.value14(p175)
        local TextLabel14 = Instance.new("TextLabel")

        TextLabel14.Size = UDim2.new(1, 0, 0, 16)
        TextLabel14.BackgroundTransparency = 1
        TextLabel14.Text = "•  " .. p175
        TextLabel14.TextColor3 = t9.value9.TextDark
        TextLabel14.Font = Enum.Font.Gotham
        TextLabel14.TextSize = 12
        TextLabel14.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel14.Parent = t24.value56
        table.insert(t9.value17, {
			obj = TextLabel14,
			prop = "TextColor3",
			key = "TextDark"
		})

        return TextLabel14
    end

    t23.value14("Executor: " .. (function()
        local ok17, result18 = pcall(function()
            if identifyexecutor then
                return identifyexecutor()
            end

            if getexecutorname then
                return getexecutorname()
            end

            return nil
        end)

        if ok17 then
            ok17 = result18 and result18 ~= ""
        end

        if ok17 then
            return tostring(result18)
        end

        if syn then
            return "Synapse"
        end

        if fluxus then
            return "Fluxus"
        end

        if KRNL_LOADED then
            return "KRNL"
        end

        if is_sirhurt_closure then
            return "Sirhurt"
        end

        if pebc_execute then
            return "ProtoSmasher"
        end

        return "Unknown"
    end)())
    t23.value14("Maps: " .. (function()
        return "Prison Life"
    end)())
    t24.value57 = t23.value14("Time: " .. os.date("%I:%M %p"))
    task.spawn(function()
        local ok18, result19 = pcall(function()
            return t2.value1:GetUserThumbnailAsync(t2.value8.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)

        if ok18 then
            ok18 = result19 and t24.value54.Parent
        end

        if ok18 then
            t24.value54.Image = result19
        end
    end)
    task.spawn(function()
        while t24.value41 and t24.value41.Parent do
            t24.value55.Text = t24.value52() .. ", @" .. t2.value8.Name .. "!"
            t24.value57.Text = "•  Time: " .. os.date("%I:%M %p")
            task.wait(30)
        end
    end)

    function t23.value19(p176, p177, p178, p179)
        local v1105 = t24.value48(p176, nil)
        local u1106 = p179 ~= false
        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(1, 0, 0, 28)
        TextButton.BackgroundTransparency = 1
        TextButton.Text = ""
        TextButton.Parent = v1105

        local TextLabel15 = Instance.new("TextLabel")

        TextLabel15.Size = UDim2.new(1, -28, 0, not p178 and 28 or 16)
        TextLabel15.Position = UDim2.new(0, 0, 0, 0)
        TextLabel15.BackgroundTransparency = 1
        TextLabel15.Text = p177
        TextLabel15.TextColor3 = t9.value9.Text
        TextLabel15.Font = Enum.Font.GothamMedium
        TextLabel15.TextSize = 13
        TextLabel15.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel15.Parent = TextButton
        table.insert(t9.value17, {
			obj = TextLabel15,
			prop = "TextColor3",
			key = "Text"
		})

        if p178 then
            local TextLabel16 = Instance.new("TextLabel")

            TextLabel16.Size = UDim2.new(1, -28, 0, 12)
            TextLabel16.Position = UDim2.new(0, 0, 0, 16)
            TextLabel16.BackgroundTransparency = 1
            TextLabel16.Text = p178
            TextLabel16.TextColor3 = t9.value9.TextDark
            TextLabel16.Font = Enum.Font.Gotham
            TextLabel16.TextSize = 10
            TextLabel16.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel16.Parent = TextButton
            table.insert(t9.value17, {
				obj = TextLabel16,
				prop = "TextColor3",
				key = "TextDark"
			})
            TextButton.Size = UDim2.new(1, 0, 0, 32)
        end

        local TextLabel17 = Instance.new("TextLabel")

        TextLabel17.Size = UDim2.new(0, 20, 1, 0)
        TextLabel17.Position = UDim2.new(1, -20, 0, 0)
        TextLabel17.BackgroundTransparency = 1
        TextLabel17.Text = not u1106 and "▸" or "▾"
        TextLabel17.TextColor3 = t9.value9.TextDark
        TextLabel17.Font = Enum.Font.Gotham
        TextLabel17.TextSize = 14
        TextLabel17.Parent = TextButton

        local Frame21 = Instance.new("Frame")

        Frame21.Size = UDim2.new(1, 0, 0, 0)
        Frame21.AutomaticSize = Enum.AutomaticSize.Y
        Frame21.BackgroundTransparency = 1
        Frame21.Visible = u1106
        Frame21.Parent = v1105

        local UIListLayout = Instance.new("UIListLayout")

        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Padding = UDim.new(0, 6)
        UIListLayout.Parent = Frame21
        TextButton.MouseButton1Click:Connect(function()
            u1106 = not u1106
            Frame21.Visible = u1106
            TextLabel17.Text = not u1106 and "▸" or "▾"
        end)

        return Frame21, v1105
    end

    t23.value20 = t23.value19(t24.value41, "Updates", nil, true)
    t23.value22 = Instance.new("TextLabel")
    t23.value21 = "Size"
    t23.value22[t23.value21] = UDim2.new(1, 0, 0, 18)
    t23.value21 = "BackgroundTransparency"
    t23.value22[t23.value21] = 1
    t23.value21 = "Text"
    t23.value22[t23.value21] = "Prison Life"
    t23.value21 = "TextColor3"
    t23.value22[t23.value21] = t9.value9.Accent
    t23.value21 = "Font"
    t23.value22[t23.value21] = Enum.Font.GothamMedium
    t23.value21 = "TextSize"
    t23.value22[t23.value21] = 13
    t23.value21 = "TextXAlignment"
    t23.value22[t23.value21] = Enum.TextXAlignment.Left
    t23.value21 = "Parent"
    t23.value22[t23.value21] = t23.value20
    table.insert(t9.value17, {
		obj = t23.value22,
		prop = "TextColor3",
		key = "Accent"
	})
    t23.value23 = Instance.new("TextLabel")
    t23.value21 = "Size"
    t23.value23[t23.value21] = UDim2.new(1, 0, 0, 14)
    t23.value21 = "BackgroundTransparency"
    t23.value23[t23.value21] = 1
    t23.value21 = "Text"
    t23.value23[t23.value21] = "8/13/26"
    t23.value21 = "TextColor3"
    t23.value23[t23.value21] = t9.value9.TextDark
    t23.value21 = "Font"
    t23.value23[t23.value21] = Enum.Font.Gotham
    t23.value21 = "TextSize"
    t23.value23[t23.value21] = 11
    t23.value21 = "TextXAlignment"
    t23.value23[t23.value21] = Enum.TextXAlignment.Left
    t23.value21 = "Parent"
    t23.value23[t23.value21] = t23.value20
    t23.value21 = table.insert

    local value17 = t9.value17

    t23.value21(value17, {
		obj = t23.value23,
		prop = "TextColor3",
		key = "TextDark"
	})
    t23.value21 = {
		"Added mobile support",
		"Small UI changes"
	}

    for _, v in ipairs(t23.value21) do
        t23.value25 = Instance.new("TextLabel")
        t23.value24 = "Size"
        t23.value27 = UDim2.new(1, 0, 0, 16)
        t23.value25[t23.value24] = t23.value27
        t23.value24 = "BackgroundTransparency"
        t23.value25[t23.value24] = 1
        t23.value24 = "Text"
        t23.value25[t23.value24] = "-  " .. v
        t23.value24 = "TextColor3"
        t23.value26 = t9.value9.TextDark
        t23.value25[t23.value24] = t23.value26
        t23.value24 = "Font"
        t23.value26 = Enum.Font.Gotham
        t23.value25[t23.value24] = t23.value26
        t23.value24 = "TextSize"
        t23.value25[t23.value24] = 12
        t23.value24 = "TextXAlignment"
        t23.value26 = Enum.TextXAlignment.Left
        t23.value25[t23.value24] = t23.value26
        t23.value24 = "Parent"
        t23.value25[t23.value24] = t23.value20
        table.insert(t9.value17, {
			obj = t23.value25,
			prop = "TextColor3",
			key = "TextDark"
		})
    end

    local v743 = t23.value19(t24.value41, "Info", nil, true)

    t24.value58 = Instance.new("Frame")
    t24.value58.Size = UDim2.new(1, 0, 0, 30)
    t24.value58.BackgroundTransparency = 1
    t24.value58.Parent = v743

    local UIListLayout = Instance.new("UIListLayout")

    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = t24.value58

    local function v745(p180, p181)
        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(0.5, -4, 0, 30)
        TextButton.BackgroundColor3 = t9.value9.Element
        TextButton.Text = p180
        TextButton.TextColor3 = t9.value9.Text
        TextButton.Font = Enum.Font.GothamMedium
        TextButton.TextSize = 12
        TextButton.BorderSizePixel = 0
        TextButton.Parent = t24.value58
        Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 6)
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "BackgroundColor3",
			key = "Element"
		})
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "TextColor3",
			key = "Text"
		})
        TextButton.MouseButton1Click:Connect(function()
            local v1295 = t24.value53(p181)

            if t9.value22.notify then
                t9.value22.notify(p180, if not v1295 then p181 else "Link copied")
            end
        end)

        return TextButton
    end

    v745("Youtube", "https://www.youtube.com/@85ryderr")
    v745("Discord", "https://discord.gg/MwUST7zEt")
    t24.value59 = t23.value19(t24.value41, "Server Status", nil, true)

    local function v746(p182)
        local TextLabel18 = Instance.new("TextLabel")

        TextLabel18.Size = UDim2.new(1, 0, 0, 16)
        TextLabel18.BackgroundTransparency = 1
        TextLabel18.Text = p182
        TextLabel18.TextColor3 = t9.value9.TextDark
        TextLabel18.Font = Enum.Font.Gotham
        TextLabel18.TextSize = 12
        TextLabel18.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel18.Parent = t24.value59
        table.insert(t9.value17, {
			obj = TextLabel18,
			prop = "TextColor3",
			key = "TextDark"
		})

        return TextLabel18
    end

    t23.value25 = v746("Players: " .. #t2.value1:GetPlayers() .. " / " .. tostring(t2.value1.MaxPlayers))
    t24.value60 = t23.value25
    t23.value25 = v746("Inmates: 0")
    t24.value61 = t23.value25
    t23.value25 = v746("Criminals: 0")
    t24.value62 = t23.value25
    t23.value25 = v746("Guards: 0")
    t24.value63 = t23.value25
    t23.value25 = v746("Ping: ...")
    t24.value64 = t23.value25
    t23.value25 = v746("Country: ...")
    t24.value65 = t23.value25

    function t24.value66()
        local n9 = 0
        local n10 = 0
        local n11 = 0

        for _, player in ipairs(t2.value1:GetPlayers()) do
            local v1123 = player.Team and player.Team.Name or ""

            if v1123 == "Inmates" then
                n10 += 1
            elseif v1123 == "Criminals" then
                n11 += 1
            elseif v1123 == "Guards" then
                n9 += 1
            end
        end

        return n10, n11, n9
    end

    task.spawn(function()
        while t24.value59 and t24.value59.Parent do
            t24.value60.Text = "Players: " .. #t2.value1:GetPlayers() .. " / " .. tostring(t2.value1.MaxPlayers)
            local v1124, v1125, v1126 = t24.value66()
            t24.value61.Text = "Inmates: " .. tostring(v1124)
            t24.value62.Text = "Criminals: " .. tostring(v1125)
            t24.value63.Text = "Guards: " .. tostring(v1126)
            local u1127
            pcall(function()
                local Network = game:GetService("Stats"):FindFirstChild("Network")
                local v1297 = Network and Network:FindFirstChild("ServerStatsItem")
                local v1298 = v1297 and v1297:FindFirstChild("Data Ping")

                if v1298 then
                    u1127 = math.floor((v1298:GetValue()))
                end
            end)
            if not u1127 then
                pcall(function()
                    u1127 = math.floor(t2.value8:GetNetworkPing() * 1000)
                end)
            end
            t24.value64.Text = "Ping: " .. (u1127 and tostring(u1127) .. " ms" or "...")
            task.wait(2)
        end
    end)
    task.spawn(function()
        -- Country stat: no external IP-geolocation lookup (privacy).
        if t24.value65 and t24.value65.Parent then
            t24.value65.Text = "Country: Unknown"
        end
    end)

    local v747, v748 = t24.value48(t24.value42, nil)

    t24.value67 = v748
    t24.value68 = Instance.new("TextLabel")
    t24.value68.Size = UDim2.new(1, 0, 0, 14)
    t24.value68.BackgroundTransparency = 1
    t24.value68.Text = "not spectating"
    t24.value68.TextColor3 = t9.value9.TextDark
    t24.value68.Font = Enum.Font.Code
    t24.value68.TextSize = 11
    t24.value68.Parent = v747
    t9.value22.SpectateLabel = t24.value68
    t9.value22.SpectateCard = t24.value67

    function t24.value69()
        if t9.value10.cameraLock and (#t9.value11 > 0 and t9.value11[t9.value10.targetIndex]) then
            t24.value68.Text = "spectating: " .. t9.value11[t9.value10.targetIndex].Name
            t24.value68.TextColor3 = t9.value9.Accent

            return
        end

        t24.value68.Text = "not spectating"
        t24.value68.TextColor3 = t9.value9.TextDark
    end

    t9.value22.updateSpectateLabel = t24.value69

    local v749 = t24.value48(t24.value42, "hitboxes")

    v735(v749, "Hitbox Expander", "expand other players HRP", false, function(p183)
        t9.value99(p183)
        v666("Hitbox Expander", p183)
    end)
    v733(v749, "Hitbox Size", 5, 50, 15, function(p184)
        t9.value10.hbeSize = p184
    end)
    v735(t24.value48(t24.value42, "gun mods"), "MP5 Mods", "buff MP5 ToolProperties", false, function(p185)
        v58(p185)
        v666("MP5 Mods", p185)
    end)

    local v750 = t24.value48(t24.value42, "combat")

    v735(v750, "Spectate", "lock cam on players", false, function(p186)
        t9.value10.cameraLock = p186

        if p186 then
            t9.value66()

            local v1133 = t9.value65(false, false)

            if v1133 then
                for i, v in ipairs(t9.value11) do
                    if v == v1133 then
                        t9.value10.targetIndex = i

                        break
                    end
                end
            else
                t9.value10.targetIndex = 1
            end
        else
            t9.value51()
        end

        t24.value69()
    end)
    t9.value16.Aimlock = v735(v750, "Aimlock", "snap cam to targets", false, function(p187)
        t9.value10.aimlock = p187

        if not p187 and not t9.value10.cameraLock then
            t9.value51()
        end
    end)
    v735(v750, "Silent Aim", "redirect only when a player is targeted", false, function(p188)
        t9.value10.silentAim = p188

        if not p188 then
            t9.value117()
        end

        v666("Silent Aim", p188)
    end)
    v735(v750, "Triggerbot", "auto click when target in FOV", false, function(p189)
        t9.value10.triggerbot = p189
        v666("Triggerbot", p189)
    end)
    v735(v750, "Legit", "body parts every 0.08s", false, function(p190)
        t9.value10.legit = p190
        t9.value10.lastLegit = 0
    end)
    v735(v750, "FOV Circle", "cursor circle + aim limit", false, function(p191)
        t9.value10.fovCircle = p191
        t24.value4()
    end)
    v735(v750, "Damage Markers", "show dmg numbers above players", false, function(p192)
        t9.value10.dmgMarkers = p192

        if not p192 then
            for k in pairs(t9.value46) do
                t9.value70(k)
            end
        end
    end)
    v735(v750, "Stack Damage", "add hits into one growing number", false, function(p193)
        t9.value10.dmgStack = p193

        for k in pairs(t9.value46) do
            t9.value70(k)
        end
    end)
    v735(v750, "Spinbot", "spin character fast", false, function(p194)
        t9.value92(p194)
        v666("Spinbot", p194)
    end)
    v735(v750, "Long Arrest", "handcuffs arrest up to 100 studs", false, function(p195)
        t9.value10.longArrest = p195
        v666("Long Arrest", p195)
    end)
    v733(v750, "FOV Radius", 40, 400, 120, function(p196)
        t9.value10.fovRadius = p196
        t24.value4()
    end)
    v733(v750, "Aim Smoothness", 1, 50, 8, function(p197)
        t9.value10.aimSmooth = p197
    end)
    v735(v750, "Silent Aim Range Limit", "ignore targets past max studs", false, function(p198)
        t9.value10.silentRangeOn = p198
    end)
    v733(v750, "Silent Aim Distance", 50, 2000, 1000, function(p199)
        t9.value10.silentMaxRange = p199
    end)
    t24.value70 = Instance.new("TextLabel")
    t24.value70.Size = UDim2.new(1, 0, 0, 12)
    t24.value70.BackgroundTransparency = 1
    t24.value70.Text = "aim targets: Everybody"
    t24.value70.TextColor3 = t9.value9.TextDark
    t24.value70.Font = Enum.Font.Code
    t24.value70.TextSize = 10
    t24.value70.TextXAlignment = Enum.TextXAlignment.Left
    t24.value70.Parent = v750

    function t24.value71()
        local v1151 = (t9.value10.aimName or ""):gsub("^%s+", ""):gsub("%s+$", "")

        if v1151 ~= "" then
            t24.value70.Text = "aim: only \"" .. v1151 .. "\""
            t24.value70.TextColor3 = t9.value9.Accent

            return
        end

        local t28 = {}

        if t9.value10.aimTeams.Prisoners then
            table.insert(t28, "Prisoners")
        end

        if t9.value10.aimTeams.Criminals then
            table.insert(t28, "Criminals")
        end

        if t9.value10.aimTeams.Police then
            table.insert(t28, "Police")
        end

        if #t28 == 0 then
            t24.value70.Text = "aim targets: Everybody"
        else
            t24.value70.Text = "aim targets: " .. table.concat(t28, " + ")
        end

        t24.value70.TextColor3 = t9.value9.TextDark
    end

    local TextLabel19 = Instance.new("TextLabel")

    TextLabel19.Size = UDim2.new(1, 0, 0, 11)
    TextLabel19.BackgroundTransparency = 1
    TextLabel19.Text = "target teams (multi-select · none = everybody)"
    TextLabel19.TextColor3 = t9.value9.TextDark
    TextLabel19.Font = Enum.Font.Code
    TextLabel19.TextSize = 9
    TextLabel19.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel19.Parent = v750
    v735(v750, "Target Prisoners", "Inmates team", false, function(p200)
        t9.value10.aimTeams.Prisoners = p200
        t24.value71()
    end)
    v735(v750, "Target Criminals", "Criminals team", false, function(p201)
        t9.value10.aimTeams.Criminals = p201
        t24.value71()
    end)
    v735(v750, "Target Police", "Guards team", false, function(p202)
        t9.value10.aimTeams.Police = p202
        t24.value71()
    end)
    t23.value10 = Instance.new("TextLabel")
    t23.value10.Size = UDim2.new(1, 0, 0, 11)
    t23.value10.BackgroundTransparency = 1
    t23.value10.Text = "player name (empty = use teams above)"
    t23.value10.TextColor3 = t9.value9.TextDark
    t23.value10.Font = Enum.Font.Code
    t23.value10.TextSize = 9
    t23.value10.TextXAlignment = Enum.TextXAlignment.Left
    t23.value10.Parent = v750
    v732(v750, "username...", function(p203)
        local value10 = t9.value10

        if not p203 then
            p203 = ""
        end

        value10.aimName = p203
        t24.value71()
    end)
    t23.value11 = t24.value48(t24.value42, "movement")
    v735(t23.value11, "WalkSpeed", "override speed", false, function(p204)
        t9.value10.walkSpeedOn = p204

        if p204 then
            t9.value79()
            t9.value77()
            t9.value78()

            return
        end

        t9.value80()

        local v1159 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

        if v1159 then
            v1159.WalkSpeed = 16
            v1159.JumpHeight = 7.2
        end
    end)
    t24.value72 = nil
    t24.value72 = v735(t23.value11, "Fly", "noclip flight", false, function(p205)
        if p205 and t9.value10.freecam then
            if t9.value22.notify then
                t9.value22.notify("Fly", "turn off Freecam first")
            end

            task.defer(function()
                if t24.value72 then
                    t24.value72(false)
                end
            end)

            return
        end

        t9.value10.fly = p205

        if p205 then
            t9.value87()

            return
        end

        t9.value88()
    end)
    t23.value13 = t9.value16
    t23.value14 = "Fly"
    t23.value13[t23.value14] = t24.value72
    v735(t23.value11, "Freecam", "free camera WASD / joystick", false, function(p206)
        t9.value57(p206)
        v666("Freecam", p206)
    end)
    t23.value13 = t9.value16
    t23.value14 = "Doors"
    t23.value13[t23.value14] = v735(t23.value11, "Doors", "strip cell/doors", false, function(p207)
        t9.value86(p207)
    end)
    v735(t23.value11, "Noclip", "walk through walls (clip to other side)", false, function(p208)
        t9.value85(p208)
        v666("Noclip", p208)
    end)
    t23.value14 = t24.value48(t24.value42, "actions")
    v734(t23.value14, "Next Target", function()
        if not t9.value10.cameraLock or #t9.value11 == 0 then
            return
        end

        t9.value10.targetIndex = t9.value10.targetIndex % #t9.value11 + 1
        t24.value69()
    end)
    v734(t23.value14, "Previous Target", function()
        if not t9.value10.cameraLock or #t9.value11 == 0 then
            return
        end

        t9.value10.targetIndex = t9.value10.targetIndex - 1

        if t9.value10.targetIndex < 1 then
            t9.value10.targetIndex = #t9.value11
        end

        t24.value69()
    end)
    v734(t23.value14, "Teleport to Target", t9.value115)
    t23.value15 = t24.value48(t24.value42, "teleports")
    t23.value19 = "Get Gun"

    local vector3 = Vector3.new(813.699, 97.85, 2229.396)

    t23.value21 = {
		label = "MP5",
		name = "MP5",
		fixedPos = vector3
	}
    t23.value24 = Vector3.new(-931.793, 91.278, 2039.255)
    t23.value22 = {
		label = "AK-47",
		name = "AK-47",
		fixedPos = t23.value24
	}
    t23.value25 = Vector3.new(820.299, 97.85, 2229.396);
    (function(p209, p210, p211, p212)
        local Frame22 = Instance.new("Frame")
        Frame22.Size = UDim2.new(1, 0, 0, 24)
        Frame22.BackgroundTransparency = 1
        Frame22.Parent = p209
        local TextButton = Instance.new("TextButton")
        TextButton.Size = UDim2.new(1, 0, 0, 24)
        TextButton.BackgroundColor3 = t9.value9.Element
        TextButton.Text = "  " .. p210 .. "  ▼"
        TextButton.TextColor3 = t9.value9.Text
        TextButton.Font = Enum.Font.Gotham
        TextButton.TextSize = 12
        TextButton.TextXAlignment = Enum.TextXAlignment.Left
        TextButton.BorderSizePixel = 0
        TextButton.Parent = Frame22
        table.insert(t9.value17, {
			obj = TextButton,
			prop = "BackgroundColor3",
			key = "Element"
		})
        local Frame23 = Instance.new("Frame")
        Frame23.BackgroundColor3 = t9.value9.Card
        Frame23.BorderSizePixel = 0
        Frame23.Visible = false
        Frame23.ZIndex = 300
        Frame23.Parent = t24.value1
        table.insert(t9.value17, {
			obj = Frame23,
			prop = "BackgroundColor3",
			key = "Card"
		})
        local UIStroke7 = Instance.new("UIStroke")
        UIStroke7.Color = t9.value9.Stroke
        UIStroke7.Parent = Frame23
        table.insert(t9.value17, {
			obj = UIStroke7,
			prop = "Color",
			key = "Stroke"
		})
        Instance.new("UIListLayout", Frame23).SortOrder = Enum.SortOrder.LayoutOrder
        local u1046 = false
        t9.value19[Frame22] = function()
            u1046 = false
            Frame23.Visible = false
        end
        for i, v in ipairs(p211) do
            local v1049 = v
            local TextButton2 = Instance.new("TextButton")

            TextButton2.Size = UDim2.new(1, 0, 0, 22)
            TextButton2.BackgroundColor3 = t9.value9.Element
            TextButton2.Text = "  " .. (v1049.label or tostring(v1049))
            TextButton2.TextColor3 = t9.value9.Text
            TextButton2.Font = Enum.Font.Gotham
            TextButton2.TextSize = 12
            TextButton2.TextXAlignment = Enum.TextXAlignment.Left
            TextButton2.BorderSizePixel = 0
            TextButton2.LayoutOrder = i
            TextButton2.ZIndex = 301
            TextButton2.Parent = Frame23
            table.insert(t9.value17, {
				obj = TextButton2,
				prop = "BackgroundColor3",
				key = "Element"
			})
            TextButton2.MouseEnter:Connect(function()
                TextButton2.BackgroundColor3 = t9.value9.ElementHover
            end)
            TextButton2.MouseLeave:Connect(function()
                TextButton2.BackgroundColor3 = t9.value9.Element
            end)
            TextButton2.MouseButton1Click:Connect(function()
                TextButton.Text = "  " .. p210 .. "  ▼"
                u1046 = false

                if u1046 then
                    t24.value46()
                    u1046 = true
                    Frame23.Position = UDim2.fromOffset(TextButton.AbsolutePosition.X, TextButton.AbsolutePosition.Y + TextButton.AbsoluteSize.Y + 2)
                    Frame23.Size = UDim2.fromOffset(TextButton.AbsoluteSize.X, #p211 * 22)
                    Frame23.Visible = true
                else
                    Frame23.Visible = false
                end

                p212(v1049)
            end)
        end
        TextButton.MouseButton1Click:Connect(function()
            u1046 = not u1046

            if u1046 then
                t24.value46()
                u1046 = true
                Frame23.Position = UDim2.fromOffset(TextButton.AbsolutePosition.X, TextButton.AbsolutePosition.Y + TextButton.AbsoluteSize.Y + 2)
                Frame23.Size = UDim2.fromOffset(TextButton.AbsoluteSize.X, #p211 * 22)
                Frame23.Visible = true

                return
            end

            Frame23.Visible = false
        end)
        t24.value6:GetPropertyChangedSignal("Position"):Connect(function()
            if u1046 then
                Frame23.Position = UDim2.fromOffset(TextButton.AbsolutePosition.X, TextButton.AbsolutePosition.Y + TextButton.AbsoluteSize.Y + 2)
                Frame23.Size = UDim2.fromOffset(TextButton.AbsoluteSize.X, #p211 * 22)
            end
        end)
    end)(t23.value15, t23.value19, {
		t23.value21,
		t23.value22,
		{
			label = "Remington 870",
			name = "Remington 870",
			fixedPos = t23.value25
		}
	}, function(p213)
        task.spawn(function()
            t9.value116(p213.name, p213.offset, p213.fixedPos)
        end)
    end)
    v734(t23.value15, "Criminals Spawn", function()
        t9.value113("Criminals Spawn")
    end)
    v734(t23.value15, "criminalTree", function()
        t9.value114(Vector3.new(463.397, 94.822, 2380.598))
    end)
    v734(t23.value15, "Prison Spawn", function()
        t9.value114(Vector3.new(916, 97.49, 2306))
    end)
    t23.value19 = t24.value48(t24.value42, "values")
    v733(t23.value19, "WalkSpeed", 0, 100, 16, function(p214)
        t9.value10.walkSpeed = p214

        local v1166 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

        if t9.value10.walkSpeedOn and v1166 then
            v1166.WalkSpeed = p214
        end
    end)
    v733(t23.value19, "JumpHeight", 0, 100, 7, function(p215)
        t9.value10.jumpHeight = p215

        local v1168 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

        if v1168 then
            v1168.JumpHeight = p215
        end
    end)
    v733(t23.value19, "Fly Speed", 10, 500, 50, function(p216)
        t9.value10.flySpeed = p216
    end)
    v735(t24.value48(t24.value43, "master"), "ESP Enabled", "highlight outlines", false, function(p217)
        t9.value10.highlights = p217

        if not p217 then
            t9.value148()

            return
        end

        for _, player in ipairs(t2.value1:GetPlayers()) do
            t9.value147(player)
        end
    end)

    local v753 = t24.value48(t24.value43, "features")

    v735(v753, "Boxes", "2D boxes around players", true, function(p218)
        t9.value10.espBoxes = p218

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Chams", "body fill through walls", false, function(p219)
        t9.value10.espChams = p219

        for _, player in ipairs(t2.value1:GetPlayers()) do
            if player ~= t2.value8 then
                t9.value147(player)
            end
        end

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Team Colors", "color by team (guards/inmates/criminals)", false, function(p220)
        t9.value10.espTeamColors = p220

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Names", "show names", true, function(p221)
        t9.value10.espNames = p221

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Health", "side health bar", true, function(p222)
        t9.value10.espHealth = p222

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Distance", "show studs", true, function(p223)
        t9.value10.espDistance = p223

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "Tracers", not t9.value21 and "needs Drawing API" or "lines from bottom", true, function(p224)
        t9.value10.espTracers = p224

        if not p224 then
            t9.value137()
        end

        if t9.value22.refreshESPPreview then
            t9.value22.refreshESPPreview()
        end
    end)
    v735(v753, "ESP Range Limit", "hide ESP past max studs", false, function(p225)
        t9.value10.espRangeOn = p225
    end)
    v733(v753, "ESP Max Distance", 50, 2000, 1000, function(p226)
        t9.value10.espMaxRange = p226
    end)

    local v754 = t24.value48(t24.value44, "keybinds")
    local TextLabel20 = Instance.new("TextLabel")

    TextLabel20.Size = UDim2.new(1, 0, 0, 11)
    TextLabel20.BackgroundTransparency = 1
    TextLabel20.Text = "click bind, press key"
    TextLabel20.TextColor3 = t9.value9.TextDark
    TextLabel20.Font = Enum.Font.Code
    TextLabel20.TextSize = 9
    TextLabel20.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel20.Parent = v754
    v736(v754, "Fly", "Fly")
    v736(v754, "Aimlock", "Aimlock")
    v736(v754, "Silent Aim", "SilentAim")
    v736(v754, "Doors", "Doors")
    v734(v754, "Clear Binds", function()
        local value15 = t9.value15
        local value15_2 = t9.value15
        local value15_3 = t9.value15
        local value15_4 = t9.value15
        local value10 = t9.value10

        value15.Fly = nil
        value15_2.Aimlock = nil
        value15_3.SilentAim = nil
        value15_4.Doors = nil
        value10.listening = nil

        for _, v in pairs(t24.value50) do
            v.Text = "None"
            v.BackgroundColor3 = t9.value9.Element
            v.TextColor3 = t9.value9.Accent
        end
    end)
    v735(t24.value48(t24.value44, "killfeed"), "Killfeed UI", "custom killfeed (max 5, team colors)", false, function(p227)
        t9.value10.killfeedUI = p227

        if not p227 then
            t9.value47()
        end

        if t9.value22.notify then
            t9.value22.notify("Killfeed UI", p227)
        end
    end)
    t23.value10 = t24.value48(t24.value44, "sounds")
    t23.value11 = Instance.new("TextLabel")
    t23.value11.Size = UDim2.new(1, 0, 0, 12)
    t23.value11.BackgroundTransparency = 1
    t23.value11.Text = "kill sound (killfeed - first word = you)"
    t23.value11.TextColor3 = t9.value9.TextDark
    t23.value11.Font = Enum.Font.Code
    t23.value11.TextSize = 9
    t23.value11.TextXAlignment = Enum.TextXAlignment.Left
    t23.value11.Parent = t23.value10
    v732(t23.value10, "kill sound id...", t9.value28)
    v733(t23.value10, "Kill Volume", 0, 100, 50, function(p228)
        t9.value10.killVol = p228 / 100
        t9.value26.Volume = t9.value10.killVol
    end)
    v734(t23.value10, "Test Kill Sound", t9.value30)
    t23.value12 = Instance.new("TextLabel")
    t23.value12.Size = UDim2.new(1, 0, 0, 12)
    t23.value12.BackgroundTransparency = 1
    t23.value12.Text = "headshot sound (when a head hit deals damage)"
    t23.value12.TextColor3 = t9.value9.TextDark
    t23.value12.Font = Enum.Font.Code
    t23.value12.TextSize = 9
    t23.value12.TextXAlignment = Enum.TextXAlignment.Left
    t23.value12.Parent = t23.value10
    v732(t23.value10, "headshot sound id...", t9.value29)
    v733(t23.value10, "Headshot Volume", 0, 100, 50, function(p229)
        t9.value10.headVol = p229 / 100
        t9.value27.Volume = t9.value10.headVol
    end)
    v734(t23.value10, "Test Headshot Sound", t9.value31)
    t23.value13 = t24.value48(t24.value44, "colors")
    t24.value73 = t23.value13
    t24.value74 = nil
    t24.value75 = {}

    local function v756()
        for _, v in ipairs(t24.value75) do
            local v1196 = v

            pcall(function()
                v1196:Disconnect()
            end)
        end

        table.clear(t24.value75)

        if t24.value74 then
            pcall(function()
                t24.value74:Destroy()
            end)
            t24.value74 = nil
        end
    end

    t23.value19 = t9.value22
    t23.value20 = "closeColorPicker"
    t23.value19[t23.value20] = v756

    function t23.value20(p230, p231, p232)
        v756()
        local v1200, v1201, v1202 = Color3.toHSV(p231)
        local u1203 = v1200
        local v1204 = v1201
        local v1205 = v1202
        if u1203 ~= u1203 then
            u1203 = 0
        end
        local Frame24 = Instance.new("Frame")
        Frame24.Name = "NexusColorPicker"
        Frame24.Size = UDim2.new(0, 210, 0, 190)
        Frame24.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
        Frame24.BorderSizePixel = 0
        Frame24.ZIndex = 600
        Frame24.Active = true
        Frame24.Parent = t24.value1
        Instance.new("UICorner", Frame24).CornerRadius = UDim.new(0, 8)
        local UIStroke8 = Instance.new("UIStroke")
        UIStroke8.Color = t9.value9.Accent
        UIStroke8.Thickness = 1
        UIStroke8.Transparency = 0.35
        UIStroke8.Parent = Frame24;
        (function()
            local AbsolutePosition = p230.AbsolutePosition
            local AbsoluteSize = p230.AbsoluteSize
            local v1304 = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local v1305 = AbsolutePosition.X + AbsoluteSize.X + 10
            local AbsolutePositionY = AbsolutePosition.Y

            if v1305 + 210 > v1304.X then
                v1305 = AbsolutePosition.X - 220
            end

            if v1305 < 8 then
                v1305 = 8
            end

            if AbsolutePositionY + 190 > v1304.Y then
                AbsolutePositionY = v1304.Y - 200
            end

            if AbsolutePositionY < 8 then
                AbsolutePositionY = 8
            end

            Frame24.Position = UDim2.fromOffset(v1305, AbsolutePositionY)
        end)()
        local TextButton = Instance.new("TextButton")
        TextButton.Size = UDim2.new(0, 150, 0, 140)
        TextButton.Position = UDim2.new(0, 12, 0, 12)
        TextButton.Text = ""
        TextButton.AutoButtonColor = false
        TextButton.BorderSizePixel = 0
        TextButton.BackgroundColor3 = Color3.fromHSV(u1203, 1, 1)
        TextButton.ZIndex = 601
        TextButton.Parent = Frame24
        Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 4)
        local Frame25 = Instance.new("Frame")
        Frame25.Size = UDim2.new(1, 0, 1, 0)
        Frame25.BackgroundColor3 = Color3.new(1, 1, 1)
        Frame25.BorderSizePixel = 0
        Frame25.Active = false
        Frame25.ZIndex = 602
        Frame25.Parent = TextButton
        local UIGradient = Instance.new("UIGradient")
        UIGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
        UIGradient.Parent = Frame25
        local Frame26 = Instance.new("Frame")
        Frame26.Size = UDim2.new(1, 0, 1, 0)
        Frame26.BackgroundColor3 = Color3.new(0, 0, 0)
        Frame26.BorderSizePixel = 0
        Frame26.Active = false
        Frame26.ZIndex = 603
        Frame26.Parent = TextButton
        local UIGradient2 = Instance.new("UIGradient")
        UIGradient2.Rotation = 90
        UIGradient2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
        UIGradient2.Parent = Frame26
        local Frame27 = Instance.new("Frame")
        Frame27.Size = UDim2.new(0, 12, 0, 12)
        Frame27.AnchorPoint = Vector2.new(0.5, 0.5)
        Frame27.BackgroundTransparency = 1
        Frame27.Active = false
        Frame27.ZIndex = 605
        Frame27.Parent = TextButton
        local UIStroke9 = Instance.new("UIStroke")
        UIStroke9.Color = Color3.new(1, 1, 1)
        UIStroke9.Thickness = 2
        UIStroke9.Parent = Frame27
        Instance.new("UICorner", Frame27).CornerRadius = UDim.new(1, 0)
        local TextButton3 = Instance.new("TextButton")
        TextButton3.Size = UDim2.new(0, 20, 0, 140)
        TextButton3.Position = UDim2.new(0, 172, 0, 12)
        TextButton3.Text = ""
        TextButton3.AutoButtonColor = false
        TextButton3.BorderSizePixel = 0
        TextButton3.BackgroundColor3 = Color3.new(1, 1, 1)
        TextButton3.ZIndex = 601
        TextButton3.Parent = Frame24
        Instance.new("UICorner", TextButton3).CornerRadius = UDim.new(0, 4)
        local UIGradient3 = Instance.new("UIGradient")
        UIGradient3.Rotation = 90
        UIGradient3.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
			ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16, 1, 1)),
			ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
			ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66, 1, 1)),
			ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
		})
        UIGradient3.Parent = TextButton3
        local Frame28 = Instance.new("Frame")
        Frame28.Size = UDim2.new(1, 6, 0, 4)
        Frame28.Position = UDim2.new(0, -3, u1203, 0)
        Frame28.AnchorPoint = Vector2.new(0, 0.5)
        Frame28.BackgroundColor3 = Color3.new(1, 1, 1)
        Frame28.BorderSizePixel = 0
        Frame28.Active = false
        Frame28.ZIndex = 602
        Frame28.Parent = TextButton3
        local TextLabel21 = Instance.new("TextLabel")
        TextLabel21.Size = UDim2.new(1, -24, 0, 20)
        TextLabel21.Position = UDim2.new(0, 12, 1, -28)
        TextLabel21.BackgroundTransparency = 1
        TextLabel21.TextColor3 = Color3.fromRGB(220, 220, 225)
        TextLabel21.Font = Enum.Font.Code
        TextLabel21.TextSize = 12
        TextLabel21.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel21.ZIndex = 601
        TextLabel21.Parent = Frame24
        local function v1219(p233)
            return string.format("#%02X%02X%02X", math.floor(p233.R * 255 + 0.5), math.floor(p233.G * 255 + 0.5), (math.floor(p233.B * 255 + 0.5)))
        end
        local function u1220()
            local color3_15 = Color3.fromHSV(u1203, v1204, v1205)

            TextLabel21.Text = v1219(color3_15)
            Frame27.Position = UDim2.new(v1204, 0, 1 - v1205, 0)
            Frame28.Position = UDim2.new(0, -3, u1203, 0)
            TextButton.BackgroundColor3 = Color3.fromHSV(u1203, 1, 1)
            pcall(p232, color3_15)
        end
        u1220()
        local s2
        local function v1222()
            local MouseLocation = t2.value3:GetMouseLocation()
            local AbsolutePosition = TextButton.AbsolutePosition
            local AbsoluteSize = TextButton.AbsoluteSize

            if AbsoluteSize.X < 1 or AbsoluteSize.Y < 1 then
                return
            end

            math.clamp((MouseLocation.X - AbsolutePosition.X) / AbsoluteSize.X, 0, 1)

            local _ = 1 - math.clamp((MouseLocation.Y - AbsolutePosition.Y) / AbsoluteSize.Y, 0, 1)

            u1220()
        end
        local function v1223()
            local MouseLocation = t2.value3:GetMouseLocation()
            local AbsolutePosition = TextButton3.AbsolutePosition
            local AbsoluteSize = TextButton3.AbsoluteSize

            if AbsoluteSize.Y < 1 then
                return
            end

            math.clamp((MouseLocation.Y - AbsolutePosition.Y) / AbsoluteSize.Y, 0, 1)
            u1220()
        end
        table.insert(t24.value75, TextButton.MouseButton1Down:Connect(function()
            s2 = "sv"
            v1222()
        end))
        table.insert(t24.value75, TextButton3.MouseButton1Down:Connect(function()
            s2 = "h"
            v1223()
        end))
        table.insert(t24.value75, t2.value3.InputChanged:Connect(function(input)
            if not Frame24.Parent or not s2 then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if s2 == "sv" then
                    v1222()

                    return
                end

                if s2 == "h" then
                    v1223()
                end
            end
        end))
        table.insert(t24.value75, t2.value3.InputEnded:Connect(function(input)
            if not (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            end
        end))
        local TextButton4 = Instance.new("TextButton")
        TextButton4.Size = UDim2.new(0, 24, 0, 20)
        TextButton4.Position = UDim2.new(1, -28, 0, 4)
        TextButton4.BackgroundTransparency = 1
        TextButton4.Text = "×"
        TextButton4.TextColor3 = Color3.fromRGB(160, 160, 160)
        TextButton4.Font = Enum.Font.Gotham
        TextButton4.TextSize = 16
        TextButton4.ZIndex = 610
        TextButton4.Parent = Frame24
        table.insert(t24.value75, TextButton4.MouseButton1Click:Connect(v756))
    end

    t24.value76 = t23.value20

    function t23.value20(p234, p235, p236)
        local Frame29 = Instance.new("Frame")

        Frame29.Size = UDim2.new(1, 0, 0, 32)
        Frame29.BackgroundTransparency = 1
        Frame29.Parent = t24.value73

        local TextLabel22 = Instance.new("TextLabel")

        TextLabel22.Size = UDim2.new(0.5, 0, 1, 0)
        TextLabel22.BackgroundTransparency = 1
        TextLabel22.Text = p234
        TextLabel22.TextColor3 = t9.value9.Text
        TextLabel22.Font = Enum.Font.Gotham
        TextLabel22.TextSize = 12
        TextLabel22.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel22.Parent = Frame29

        local TextButton = Instance.new("TextButton")

        TextButton.Size = UDim2.new(0, 72, 0, 24)
        TextButton.Position = UDim2.new(1, -72, 0.5, -12)
        TextButton.BackgroundColor3 = p235()
        TextButton.Text = ""
        TextButton.BorderSizePixel = 0
        TextButton.Parent = Frame29
        Instance.new("UICorner", TextButton).CornerRadius = UDim.new(0, 6)

        local UIStroke10 = Instance.new("UIStroke")

        UIStroke10.Color = Color3.fromRGB(60, 60, 65)
        UIStroke10.Thickness = 1
        UIStroke10.Parent = TextButton
        TextButton.MouseButton1Click:Connect(function()
            t24.value76(TextButton, p235(), function(p237)
                TextButton.BackgroundColor3 = p237
                p236(p237)
            end)
        end)

        return TextButton
    end

    t23.value20("Accent", function()
        return t9.value9.Accent
    end, function(p238)
        t9.value9.Accent = p238
        t9.value9.Toggle = p238
        t24.value51()
    end)
    t23.value22 = "Surface"
    t23.value20(t23.value22, function()
        return t9.value9.Card
    end, function(p239)
        t9.value9.Card = p239
        t9.value9.Element = Color3.new(math.clamp(p239.R + 0.04, 0, 1), math.clamp(p239.G + 0.04, 0, 1), (math.clamp(p239.B + 0.04, 0, 1)))
        t9.value9.ElementHover = Color3.new(math.clamp(p239.R + 0.08, 0, 1), math.clamp(p239.G + 0.08, 0, 1), (math.clamp(p239.B + 0.08, 0, 1)))
        t9.value9.Background = Color3.new(math.clamp(p239.R - 0.03, 0, 1), math.clamp(p239.G - 0.03, 0, 1), (math.clamp(p239.B - 0.03, 0, 1)))
        t9.value9.Sidebar = t9.value9.Background
        t9.value9.Track = Color3.new(math.clamp(p239.R + 0.06, 0, 1), math.clamp(p239.G + 0.06, 0, 1), (math.clamp(p239.B + 0.06, 0, 1)))
        t24.value51()
    end)
    v734(t24.value73, "Reset Colors", function()
        t9.value9.Background = Color3.fromRGB(18, 18, 20)
        t9.value9.Sidebar = Color3.fromRGB(14, 14, 16)
        t9.value9.Card = Color3.fromRGB(24, 24, 27)
        t9.value9.Element = Color3.fromRGB(32, 32, 36)
        t9.value9.ElementHover = Color3.fromRGB(42, 42, 48)
        t9.value9.Accent = Color3.fromRGB(90, 160, 255)
        t9.value9.Toggle = t9.value9.Accent
        t9.value9.Stroke = Color3.fromRGB(45, 45, 52)
        t9.value9.Track = Color3.fromRGB(40, 40, 46)
        v756()
        t24.value51()
    end)
    t23.value22 = t24.value48(t24.value44, "world")
    v735(t23.value22, "Clock Override", "client time lock", false, function(p240)
        t9.value10.clockOn = p240

        if p240 then
            t2.value6.ClockTime = t9.value10.clockTime
        end
    end)
    v733(t23.value22, "Clock Time", 0, 24, math.clamp(math.floor(t9.value10.clockTime + 0.5), 0, 24), function(p241)
        t9.value10.clockTime = p241

        if t9.value10.clockOn then
            t2.value6.ClockTime = p241
        end
    end)
    v735(t23.value22, "X-Ray", "map parts 40% transparent", false, function(p242)
        v56(p242)
    end)
    v735(t23.value22, "Fullbright", "no shadows / fog", false, function(p243)
        t9.value10.fullbright = p243

        if p243 then
            t2.value6.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            t2.value6.GlobalShadows = false
            t2.value6.FogStart = 0
            t2.value6.FogEnd = 100000000
        end
    end)
    v735(t24.value48(t24.value44, "general"), "Spectate Label", "show status", true, function(p244)
        t24.value67.Visible = p244
    end)

    local v757 = t24.value48(t24.value44, "stats")

    t24.value77 = Instance.new("TextLabel")
    t24.value77.Size = UDim2.new(1, 0, 0, 16)
    t24.value77.BackgroundTransparency = 1
    t24.value77.Text = "global runs: loading..."
    t24.value77.TextColor3 = t9.value9.TextDark
    t24.value77.Font = Enum.Font.Code
    t24.value77.TextSize = 11
    t24.value77.TextXAlignment = Enum.TextXAlignment.Left
    t24.value77.Parent = v757
    task.spawn(function()
        local v1239 = t9.value25()

        t24.value77.Text = v1239 and "global runs: " .. tostring(v1239) or "global runs: unavailable"

        if v1239 then
            t24.value77.TextColor3 = t9.value9.Accent
        end
    end)

    local function v758(p245, p246)
        local TextLabel23 = Instance.new("TextLabel")

        TextLabel23.Size = UDim2.new(1, 0, 0, 0)
        TextLabel23.AutomaticSize = Enum.AutomaticSize.Y
        TextLabel23.BackgroundTransparency = 1
        TextLabel23.Text = p246
        TextLabel23.TextColor3 = t9.value9.TextDark
        TextLabel23.Font = Enum.Font.Gotham
        TextLabel23.TextSize = 12
        TextLabel23.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel23.TextYAlignment = Enum.TextYAlignment.Top
        TextLabel23.TextWrapped = true
        TextLabel23.RichText = false
        TextLabel23.Parent = p245
        table.insert(t9.value17, {
			obj = TextLabel23,
			prop = "TextColor3",
			key = "TextDark"
		})

        return TextLabel23
    end

    v758(t24.value48(t24.value45, "Welcome"), table.concat({ "Welcome to Nexus this script is both mobile and PC. Updates come about every 5-7 days. If the script is buggy simply leave and rejoin then run it again." }, "\n"))
    v758(t24.value48(t24.value45, "How to use ESP"), table.concat({
		"ESP allows you to see players through walls",
		"",
		"You will need to enable the \"Enable ESP\" button to use ESP, sounds stupid but people have asked me that before",
		"",
		"Boxes is the classic ESP, it creates a box around the player as the name states.",
		"Chams highlights the players helps with spotting players through walls.",
		"Team Colors just changes the white boxes and chams to whatever color the player is on, prisoners = orange, criminals = red, guards = blue",
		"Names just shows the name of the player above their head",
		"Health shows the health bar of the player on the side of them",
		"Distance shows how far away the player is from you",
		"Tracers makes lines leading to every player.",
		"",
		"Not everything is needed for the ESP is good, all I use is boxes, chams, and health"
	}, "\n"))
    v758(t24.value48(t24.value45, "How to use the Combat features"), table.concat({
		"This includes how to use the aimlock, silent aim, and the teleports",
		"",
		"Aimlock makes your camera always look at the player your targeting",
		"Silent Aim is a lot better than aimlock could bug out on rare occasions you will need the FOV Circle on for this though",
		"FOV Circle whatever is in this circle is what the silent aim or aimlock targets you will know who is targeted by if they're highlighted in your accent color",
		"FOV Radius Slider this slider controls how big your FOV circle is",
		"Aim Smoothness is for the aimlock more smooth makes your gameplay look more legit kind of like aim assist",
		"Legit makes your gameplay look as if you weren't cheating",
		"Target teams makes it so only the teams selected is what you target"
	}, "\n"))
    t2.value3.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if t9.value10.listening then
            local KeyCode = input.KeyCode

            if KeyCode == Enum.KeyCode.Escape then
                local v1246 = t24.value50[t9.value10.listening]

                if v1246 then
                    v1246.Text = t24.value49(t9.value15[t9.value10.listening])
                    v1246.BackgroundColor3 = t9.value9.Element
                    v1246.TextColor3 = t9.value9.Accent
                end

                t9.value10.listening = nil

                return
            end

            t9.value15[t9.value10.listening] = KeyCode

            local v1247 = t24.value50[t9.value10.listening]

            if v1247 then
                v1247.Text = t24.value49(KeyCode)
                v1247.BackgroundColor3 = t9.value9.Element
                v1247.TextColor3 = t9.value9.Accent
            end

            t9.value10.listening = nil

            return
        end

        if input.KeyCode == Enum.KeyCode.Z and t9.value10.minimized then
            v727(true)

            return
        end

        if gameProcessed then
            return
        end

        if t9.value15.Fly and input.KeyCode == t9.value15.Fly then
            local v1248 = not t9.value10.fly

            if t9.value16.Fly then
                t9.value16.Fly(v1248)
            end

            v666("Fly", v1248)

            return
        end

        if t9.value15.Aimlock and input.KeyCode == t9.value15.Aimlock then
            local v1249 = not t9.value10.aimlock

            if t9.value16.Aimlock then
                t9.value16.Aimlock(v1249)
            end

            v666("Aimlock", v1249)

            return
        end

        if t9.value15.SilentAim and input.KeyCode == t9.value15.SilentAim then
            local v1250 = not t9.value10.silentAim

            t9.value10.silentAim = v1250

            if not v1250 then
                t9.value117()
            end

            v666("Silent Aim", v1250)

            return
        end

        if t9.value15.Doors and input.KeyCode == t9.value15.Doors then
            local v1251 = not t9.value10.doors

            if t9.value16.Doors then
                t9.value16.Doors(v1251)
            end

            v666("Doors", v1251)
        end
    end)
    t2.value3.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            t9.value111()
        end
    end)
end)()
function t1.value1(p247)
    if not p247 or (p247 == t2.value8 or t9.value20[p247.UserId]) then
        return
    end

    t9.value20[p247.UserId] = true

    if t9.value22.notify then
        t9.value22.notify("Nexus User", p247.Name .. " is using Nexus V2")
    end
end
function t9.value149(p248)
    if p248 then
        pcall(function()
            p248:SetAttribute(t9.value5, true)
        end)
    end
end
t9.value150 = t1.value1
t9.value151 = nil
function t9.value151(p249)
    if not p249 then
        return false
    end

    local ok19, result20 = pcall(function()
        return p249:GetAttribute(t9.value5)
    end)

    if ok19 then
        ok19 = result20 == true
    end

    return ok19
end
function t9.value152(p250, p251)
    if not p251 or p250 == t2.value8 then
        return
    end

    if t9.value151(p251) then
        t9.value150(p250)
    end

    pcall(function()
        p251:GetAttributeChangedSignal(t9.value5):Connect(function()
            if t9.value151(p251) then
                t9.value150(p250)
            end
        end)
    end)
end
local function v64(p252)
    if p252 == t2.value8 then
        return
    end

    p252.CharacterAdded:Connect(function(character)
        task.defer(function()
            t9.value152(p252, character)
        end)
    end)

    if p252.Character then
        t9.value152(p252, p252.Character)
    end
end
t9.value149(t2.value8.Character)
t2.value8.CharacterAdded:Connect(function(character)
    task.wait(0.15)
    t9.value149(character)

    if t9.value10.fly then
        t9.value88()
        t9.value87()
    end

    if t9.value10.spinbot then
        t9.value90()
        t9.value91()
    end

    if t9.value10.walkSpeedOn then
        t9.value77()
        t9.value78()
    end
end)
task.spawn(function()
    while t9.value22.ScreenGui and t9.value22.ScreenGui.Parent do
        t9.value149(t2.value8.Character)
        task.wait(5)
    end
end)

local v65, v66, v67 = ipairs(t2.value1:GetPlayers())

t1.value1 = v67
while true do
    local v68, v69 = v65(v66, t1.value1)

    t1.value1 = v68

    if not t1.value1 then
        break
    end

    v64(v69)
end
t2.value1.PlayerAdded:Connect(function(player)
    v64(player)
    task.delay(2, function()
        if player.Parent and (player.Character and t9.value151(player.Character)) then
            local v1255 = player

            t9.value150(v1255)
        end
    end)
end)
t2.value1.PlayerRemoving:Connect(function(player)
    t9.value20[player.UserId] = nil
end)
task.spawn(function()
    while t9.value22.ScreenGui and t9.value22.ScreenGui.Parent do
        for _, player in ipairs(t2.value1:GetPlayers()) do
            if player ~= t2.value8 and (player.Character and t9.value151(player.Character)) then
                t9.value150(player)
            end
        end

        task.wait(3)
    end
end)

local function v70(p253)
    p253:GetPropertyChangedSignal("Team"):Connect(function()
        t9.value147(p253)
    end)
    p253:GetPropertyChangedSignal("TeamColor"):Connect(function()
        t9.value147(p253)
    end)
    p253.CharacterAdded:Connect(function()
        t9.value147(p253)
        task.defer(function()
            t9.value72(p253)
        end)
    end)
    p253.CharacterRemoving:Connect(function()
        t9.value146(p253)
    end)

    if p253.Character then
        t9.value147(p253)
        t9.value72(p253)
    end
end
for _, player in ipairs(t2.value1:GetPlayers()) do
    if player ~= t2.value8 then
        v70(player)
    end
end
local PlayerAdded = t2.value1.PlayerAdded
function t1.value1(p254)
    if p254 ~= t2.value8 then
        v70(p254)
        t9.value147(p254)
    end
end
PlayerAdded:Connect(t1.value1)

local RenderStepped = t2.value2.RenderStepped
function t1.value1()
    if t9.value10.fovCircle and t9.value22.FovCircle then
        local v770 = t9.value49()

        t9.value22.FovCircle.Position = UDim2.fromOffset(v770.X, v770.Y)
    end

    if not t9.value10.freecam then
        if t9.value10.cameraLock then
            t9.value66()

            if t9.value22.updateSpectateLabel then
                t9.value22.updateSpectateLabel()
            end
        end

        if t9.value10.cameraLock and #t9.value11 > 0 then
            local v771 = t9.value11[t9.value10.targetIndex]

            if v771 and (v771.Character and v771.Character:FindFirstChild("HumanoidRootPart")) then
                t2.value9.CameraType = Enum.CameraType.Scriptable

                local HumanoidRootPartPosition = v771.Character.HumanoidRootPart.Position

                t2.value9.CFrame = CFrame.lookAt(HumanoidRootPartPosition + Vector3.new(0, 4, 12), HumanoidRootPartPosition + Vector3.new(0, 1.5, 0))
            else
                t9.value66()
            end
        elseif t9.value10.aimlock then
            t2.value9.CameraType = Enum.CameraType.Custom

            local v773 = t2.value8.Character and t2.value8.Character:FindFirstChildOfClass("Humanoid")

            if v773 then
                t2.value9.CameraSubject = v773
            end

            local v774 = t9.value65(true, t9.value10.fovCircle)

            if v774 and v774.Character then
                local v775 = t9.value67(v774.Character)

                if v775 then
                    t2.value9.CFrame = t2.value9.CFrame:Lerp(CFrame.lookAt(t2.value9.CFrame.Position, v775.Position), 1 / math.max(t9.value10.aimSmooth, 1))
                end
            end
        else
            t9.value51()
        end
    end

    t9.value118()
    t9.value124()

    if t9.value10.highlights then

        for v778, v779 in ipairs(t2.value1:GetPlayers()) do

            if v779 ~= t2.value8 and (v779.Character and v779.Character:FindFirstChild("HumanoidRootPart")) then
                t9.value144(v779)
            end
        end
        for k in pairs(t9.value12) do
            local v781 = k
            local v782 = v781 == t2.value8

            if not v782 then
                v782 = not v781.Parent or (not v781.Character or not v781.Character:FindFirstChild("HumanoidRootPart"))
            end

            if v782 then
                t9.value146(v781)
            end
        end
        t9.value145()

        return
    end

    t9.value137()
end
RenderStepped:Connect(t1.value1)

local Heartbeat = t2.value2.Heartbeat
function t1.value1()
    if t9.value10.clockOn then
        t2.value6.ClockTime = t9.value10.clockTime
    end

    if t9.value10.fullbright then
        t2.value6.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        t2.value6.GlobalShadows = false
        t2.value6.FogStart = 0
        t2.value6.FogEnd = 100000000
    end
end
Heartbeat:Connect(t1.value1)

local CharacterAdded = t2.value8.CharacterAdded
function t1.value1(p255)
    task.wait(0.1)
    t9.value149(p255)

    if t9.value10.walkSpeedOn then
        t9.value77()
        t9.value78()
    end

    if t9.value10.fly then
        t9.value88()
        t9.value87()
    end

    if t9.value10.spinbot then
        t9.value90()
        t9.value91()
    end
end
CharacterAdded:Connect(t1.value1)

local PlayerRemoving = t2.value1.PlayerRemoving
t1.value1 = t9.value146
PlayerRemoving:Connect(t1.value1)
print(not ("[Nexus V2] Successfully Loaded - " .. t9.value1) and "PC" or "Mobile")
