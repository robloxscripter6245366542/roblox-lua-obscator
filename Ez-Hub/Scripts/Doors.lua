--[==[
	EZ HUB — DOORS  (PlaceId 6839171747)
	One self-contained script. UI = the embedded Acrylic UI v3.5.
	Built from a full remote/code dump of DOORS: every practical client-side
	feature, grouped into Visuals / Player / Automation / Misc tabs.

	loadstring(game:HttpGet(".../Ez-Hub/Scripts/Doors.lua"))()

	Notes: DOORS is heavily server-authoritative. Visuals, ESP, movement, fly,
	noclip, prompt-firing automation and lighting are client-side and reliable;
	anything the server validates (marked "experimental") may be patched.
]==]

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║          A C R Y L I C   U I   L I B R A R Y   v3.5                 ║
-- ║     World-class modern design · buttery smooth · pristine polish     ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local ts = game:GetService("TweenService")
local ui = game:GetService("UserInputService")
local plr = game:GetService("Players")
local lg = game:GetService("Lighting")
local rs = game:GetService("RunService")
local hs = game:GetService("HttpService")

local THEMES = {
    Dark = { Base = Color3.fromRGB(10,10,12), Background = Color3.fromRGB(14,14,16), Surface = Color3.fromRGB(20,20,23), SurfaceHover = Color3.fromRGB(26,26,30), SurfaceActive = Color3.fromRGB(32,32,36), SurfaceElevated = Color3.fromRGB(24,24,28), Border = Color3.fromRGB(40,40,45), BorderSubtle = Color3.fromRGB(30,30,35), BorderFocus = Color3.fromRGB(80,80,90), BorderAccent = Color3.fromRGB(100,100,110), Text = Color3.fromRGB(235,235,240), TextDim = Color3.fromRGB(165,165,175), TextSubtle = Color3.fromRGB(110,110,120), TextMuted = Color3.fromRGB(70,70,80), TextFade = Color3.fromRGB(14,14,16), Accent = Color3.fromRGB(255,255,255), AccentDim = Color3.fromRGB(180,180,190), AccentGlow = Color3.fromRGB(255,255,255), Danger = Color3.fromRGB(255,80,80), DangerSurface = Color3.fromRGB(50,20,20), Success = Color3.fromRGB(60,210,130), SuccessSurface = Color3.fromRGB(18,45,30), Warning = Color3.fromRGB(255,190,60), Ripple = Color3.fromRGB(255,255,255), RippleDark = Color3.fromRGB(0,0,0), Toggle = { On = Color3.fromRGB(255,255,255), Off = Color3.fromRGB(35,35,40), Thumb = Color3.fromRGB(15,15,18), ThumbOn = Color3.fromRGB(10,10,12) }, Notif = { Bg = Color3.fromRGB(18,18,21), Border = Color3.fromRGB(35,35,40), Ok = Color3.fromRGB(255,255,255), Error = Color3.fromRGB(255,80,80) } },
    Light = { Base = Color3.fromRGB(250,250,252), Background = Color3.fromRGB(246,246,248), Surface = Color3.fromRGB(255,255,255), SurfaceHover = Color3.fromRGB(248,248,250), SurfaceActive = Color3.fromRGB(242,242,245), SurfaceElevated = Color3.fromRGB(255,255,255), Border = Color3.fromRGB(225,225,230), BorderSubtle = Color3.fromRGB(238,238,242), BorderFocus = Color3.fromRGB(180,180,190), BorderAccent = Color3.fromRGB(150,150,160), Text = Color3.fromRGB(15,15,20), TextDim = Color3.fromRGB(85,85,95), TextSubtle = Color3.fromRGB(140,140,150), TextMuted = Color3.fromRGB(185,185,195), TextFade = Color3.fromRGB(250,250,252), Accent = Color3.fromRGB(0,0,0), AccentDim = Color3.fromRGB(100,100,110), AccentGlow = Color3.fromRGB(0,0,0), Danger = Color3.fromRGB(220,40,40), DangerSurface = Color3.fromRGB(250,230,230), Success = Color3.fromRGB(30,180,100), SuccessSurface = Color3.fromRGB(230,248,238), Warning = Color3.fromRGB(210,140,20), Ripple = Color3.fromRGB(0,0,0), RippleDark = Color3.fromRGB(255,255,255), Toggle = { On = Color3.fromRGB(0,0,0), Off = Color3.fromRGB(220,220,225), Thumb = Color3.fromRGB(255,255,255), ThumbOn = Color3.fromRGB(255,255,255) }, Notif = { Bg = Color3.fromRGB(255,255,255), Border = Color3.fromRGB(225,225,230), Ok = Color3.fromRGB(0,0,0), Error = Color3.fromRGB(220,40,40) } },
    Midnight = { Base = Color3.fromRGB(6,6,14), Background = Color3.fromRGB(10,10,20), Surface = Color3.fromRGB(16,16,28), SurfaceHover = Color3.fromRGB(22,22,36), SurfaceActive = Color3.fromRGB(28,28,44), SurfaceElevated = Color3.fromRGB(20,20,32), Border = Color3.fromRGB(35,35,55), BorderSubtle = Color3.fromRGB(26,26,42), BorderFocus = Color3.fromRGB(70,70,110), BorderAccent = Color3.fromRGB(90,90,130), Text = Color3.fromRGB(230,235,255), TextDim = Color3.fromRGB(160,170,200), TextSubtle = Color3.fromRGB(100,110,140), TextMuted = Color3.fromRGB(60,65,85), TextFade = Color3.fromRGB(10,10,20), Accent = Color3.fromRGB(210,220,255), AccentDim = Color3.fromRGB(150,160,190), AccentGlow = Color3.fromRGB(180,190,230), Danger = Color3.fromRGB(255,80,100), DangerSurface = Color3.fromRGB(45,15,20), Success = Color3.fromRGB(60,220,140), SuccessSurface = Color3.fromRGB(15,40,30), Warning = Color3.fromRGB(255,180,80), Ripple = Color3.fromRGB(210,220,255), RippleDark = Color3.fromRGB(0,0,0), Toggle = { On = Color3.fromRGB(210,220,255), Off = Color3.fromRGB(30,30,50), Thumb = Color3.fromRGB(10,10,20), ThumbOn = Color3.fromRGB(6,6,14) }, Notif = { Bg = Color3.fromRGB(12,12,24), Border = Color3.fromRGB(30,30,50), Ok = Color3.fromRGB(210,220,255), Error = Color3.fromRGB(255,80,100) } },
    Rose = { Base = Color3.fromRGB(16,8,12), Background = Color3.fromRGB(22,12,18), Surface = Color3.fromRGB(30,18,24), SurfaceHover = Color3.fromRGB(38,24,30), SurfaceActive = Color3.fromRGB(46,30,36), SurfaceElevated = Color3.fromRGB(34,22,28), Border = Color3.fromRGB(55,35,45), BorderSubtle = Color3.fromRGB(42,28,34), BorderFocus = Color3.fromRGB(90,60,70), BorderAccent = Color3.fromRGB(115,80,90), Text = Color3.fromRGB(250,235,240), TextDim = Color3.fromRGB(190,150,165), TextSubtle = Color3.fromRGB(130,100,110), TextMuted = Color3.fromRGB(75,55,65), TextFade = Color3.fromRGB(22,12,18), Accent = Color3.fromRGB(255,210,220), AccentDim = Color3.fromRGB(190,130,145), AccentGlow = Color3.fromRGB(230,170,185), Danger = Color3.fromRGB(255,90,110), DangerSurface = Color3.fromRGB(55,18,25), Success = Color3.fromRGB(80,210,150), SuccessSurface = Color3.fromRGB(20,40,30), Warning = Color3.fromRGB(255,170,90), Ripple = Color3.fromRGB(255,210,220), RippleDark = Color3.fromRGB(0,0,0), Toggle = { On = Color3.fromRGB(255,210,220), Off = Color3.fromRGB(38,24,30), Thumb = Color3.fromRGB(16,8,12), ThumbOn = Color3.fromRGB(12,6,10) }, Notif = { Bg = Color3.fromRGB(18,10,14), Border = Color3.fromRGB(38,24,30), Ok = Color3.fromRGB(255,210,220), Error = Color3.fromRGB(255,90,110) } },
    Ocean = { Base = Color3.fromRGB(8,14,22), Background = Color3.fromRGB(12,20,32), Surface = Color3.fromRGB(18,28,42), SurfaceHover = Color3.fromRGB(24,36,52), SurfaceActive = Color3.fromRGB(30,44,62), SurfaceElevated = Color3.fromRGB(22,32,46), Border = Color3.fromRGB(40,55,75), BorderSubtle = Color3.fromRGB(30,42,58), BorderFocus = Color3.fromRGB(75,95,120), BorderAccent = Color3.fromRGB(100,120,145), Text = Color3.fromRGB(225,240,255), TextDim = Color3.fromRGB(165,185,215), TextSubtle = Color3.fromRGB(110,135,170), TextMuted = Color3.fromRGB(65,80,100), TextFade = Color3.fromRGB(12,20,32), Accent = Color3.fromRGB(110,210,255), AccentDim = Color3.fromRGB(150,175,205), AccentGlow = Color3.fromRGB(180,220,250), Danger = Color3.fromRGB(255,90,90), DangerSurface = Color3.fromRGB(50,22,22), Success = Color3.fromRGB(70,230,150), SuccessSurface = Color3.fromRGB(18,50,38), Warning = Color3.fromRGB(255,200,90), Ripple = Color3.fromRGB(110,210,255), RippleDark = Color3.fromRGB(0,0,0), Toggle = { On = Color3.fromRGB(110,210,255), Off = Color3.fromRGB(32,42,58), Thumb = Color3.fromRGB(12,20,32), ThumbOn = Color3.fromRGB(8,14,22) }, Notif = { Bg = Color3.fromRGB(14,22,34), Border = Color3.fromRGB(32,44,60), Ok = Color3.fromRGB(110,210,255), Error = Color3.fromRGB(255,90,90) } },
    Forest = { Base = Color3.fromRGB(10,16,12), Background = Color3.fromRGB(14,22,16), Surface = Color3.fromRGB(20,30,22), SurfaceHover = Color3.fromRGB(26,38,28), SurfaceActive = Color3.fromRGB(32,46,34), SurfaceElevated = Color3.fromRGB(24,34,26), Border = Color3.fromRGB(42,58,46), BorderSubtle = Color3.fromRGB(32,46,36), BorderFocus = Color3.fromRGB(80,100,85), BorderAccent = Color3.fromRGB(105,125,110), Text = Color3.fromRGB(235,250,235), TextDim = Color3.fromRGB(175,200,175), TextSubtle = Color3.fromRGB(120,150,120), TextMuted = Color3.fromRGB(70,90,70), TextFade = Color3.fromRGB(14,22,16), Accent = Color3.fromRGB(130,230,140), AccentDim = Color3.fromRGB(160,185,160), AccentGlow = Color3.fromRGB(190,240,190), Danger = Color3.fromRGB(255,100,100), DangerSurface = Color3.fromRGB(50,24,24), Success = Color3.fromRGB(90,240,130), SuccessSurface = Color3.fromRGB(22,55,32), Warning = Color3.fromRGB(255,210,100), Ripple = Color3.fromRGB(130,230,140), RippleDark = Color3.fromRGB(0,0,0), Toggle = { On = Color3.fromRGB(130,230,140), Off = Color3.fromRGB(34,44,36), Thumb = Color3.fromRGB(14,22,16), ThumbOn = Color3.fromRGB(10,16,12) }, Notif = { Bg = Color3.fromRGB(16,24,18), Border = Color3.fromRGB(34,46,36), Ok = Color3.fromRGB(130,230,140), Error = Color3.fromRGB(255,100,100) } }
}

local currentThemeName = "Dark"
local c = THEMES[currentThemeName]

local sz = { Window = { W = 740, H = 500 }, WindowMin = { W = 520, H = 320 }, WindowMax = { W = 1360, H = 920 }, Sidebar = 180, TopBar = 52, Row = 44, SliderH = 56, Tab = { W = 160, H = 40 }, Toggle = { W = 44, H = 26, Thumb = 18 }, Dropdown = { H = 44, OptionH = 36 }, ColorPrev = { W = 44, H = 24 }, Notif = { W = 260, H = 80 }, Radius = 8, RadiusMd = 12, RadiusLg = 16, Pill = 999, AccentBar = { W = 3, VPad = 0.2 } }
local font = { Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular), Medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium), SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold), Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold) }
local fs = { Display = 16, Title = 14, Body = 13, Small = 12, Tiny = 11 }

local ease = {
    Snap = { 0.08, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out },
    Swift = { 0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out },
    Smooth = { 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
    Fluid = { 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out },
    Spring = { 0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0 },
    Pop = { 0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0 },
    Linear = { 0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out } -- FIXED: Added missing Linear
}

local function Tween(obj, props, preset, dur)
    if not obj or not obj.Parent then return end
    local p = preset or ease.Smooth
    local t = ts:Create(obj, TweenInfo.new(dur or p[1], p[2], p[3], p[4] or 0, p[5] or false, p[6] or 0), props)
    t:Play(); return t
end

local function Make(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do if k ~= "Parent" then inst[k] = v end end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Corner(p, r) return Make("UICorner", { CornerRadius = UDim.new(0, r or sz.Radius), Parent = p }) end
local function Stroke(p, col, thick, trans) return Make("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = col or c.Border, Thickness = thick or 1, Transparency = trans or 0.2, Parent = p }) end
local function Pad(p, t, b, l, r) return Make("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), Parent = p }) end
local function List(p, gap, sort, dir) return Make("UIListLayout", { Padding = UDim.new(0, gap or 0), SortOrder = sort or Enum.SortOrder.LayoutOrder, FillDirection = dir or Enum.FillDirection.Vertical, Parent = p }) end
local function Label(props)
    local inst = Make("TextLabel", { BackgroundTransparency = 1, RichText = false, TextTruncate = Enum.TextTruncate.None })
    for k, v in pairs(props) do if k ~= "Parent" then inst[k] = v end end
    if props.Parent then inst.Parent = props.Parent end; return inst
end

local function IsMobile() return ui.TouchEnabled and not ui.KeyboardEnabled end

local function Ripple(parent, inputPos, col, maxSz)
    local pPos, pSz = parent.AbsolutePosition, parent.AbsoluteSize
    local rx, ry = math.clamp(inputPos.X - pPos.X, 0, pSz.X), math.clamp(inputPos.Y - pPos.Y, 0, pSz.Y)
    maxSz = maxSz or math.max(pSz.X, pSz.Y) * 2.2
    local circle = Make("Frame", { BackgroundColor3 = col or c.Ripple, BackgroundTransparency = 0.7, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, rx, 0, ry), Size = UDim2.new(0, 0, 0, 0), ZIndex = (parent.ZIndex or 1) + 60, Parent = parent })
    Corner(circle, sz.Pill)
    Tween(circle, { Size = UDim2.new(0, maxSz, 0, maxSz), BackgroundTransparency = 1 }, ease.Fluid)
    task.delay(ease.Fluid[1] + 0.05, function() if circle and circle.Parent then circle:Destroy() end end)
end

local function MakeDraggable(frame, handle, conns)
    local dragging, dragStart, startPos, mConn, eConn
    local c1 = (handle or frame).InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging, dragStart, startPos = true, input.Position, frame.Position
        mConn = ui.InputChanged:Connect(function(mi)
            if not dragging or (mi.UserInputType ~= Enum.UserInputType.MouseMovement and mi.UserInputType ~= Enum.UserInputType.Touch) then return end
            local d = mi.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end)
        eConn = ui.InputEnded:Connect(function(ei)
            if ei.UserInputType ~= Enum.UserInputType.MouseButton1 and ei.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = false; if mConn then mConn:Disconnect(); mConn = nil end; if eConn then eConn:Disconnect(); eConn = nil end
        end)
    end)
    if conns then table.insert(conns, c1) end
end

local function EnsureFolder(folder) if isfolder and not isfolder(folder) then makefolder(folder) end end
local function GetConfigs(folder)
    local list = {}
    if isfolder and listfiles then
        EnsureFolder(folder)
        for _, f in ipairs(listfiles(folder)) do
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(list, n) end
        end
    end; return list
end

-- ACRYLIC BLUR
local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur
function AcrylicBlur.new(obj)
    local self = setmetatable({ _obj = obj, _folder = nil, _root = nil, _mesh = nil, _frame = nil, _dof = nil, _enabled = true, _conns = {} }, AcrylicBlur)
    self:_Init(); return self
end
function AcrylicBlur:_Init()
    local existDOF = lg:FindFirstChild("AcrylicBlur")
    if existDOF then existDOF:Destroy() end
    self._dof = Make("DepthOfFieldEffect", { Name = "AcrylicBlur", FarIntensity = 0, FocusDistance = 0.2, InFocusRadius = 0.1, NearIntensity = 0.85, Parent = lg })
    local cam = workspace:WaitForChild("CurrentCamera", 5) -- FIXED: Safe camera wait
    if not cam then return end
    local ef = cam:FindFirstChild("AcrylicBlur")
    if ef then ef:Destroy() end
    self._folder = Make("Folder", { Name = "AcrylicBlur", Parent = cam })
    local part = Make("Part", { Name = "Root", Color = Color3.new(0,0,0), Material = Enum.Material.Glass, Size = Vector3.new(1,1,0), Anchored = true, CanCollide = false, CanQuery = false, Locked = true, CastShadow = false, Transparency = 0.96, Parent = self._folder })
    self._mesh = Make("SpecialMesh", { MeshType = Enum.MeshType.Brick, Parent = part })
    self._root = part
    self._frame = Make("Frame", { Size = UDim2.new(1,0,1,0), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), BackgroundTransparency = 1, Parent = self._obj })
    self:_Render(0.2)
end
function AcrylicBlur:_Render(dist)
    dist = dist or 0.2
    local positions = {}
    local function V2W(loc, d)
        local cam = workspace.CurrentCamera
        if not cam then return Vector3.zero end
        local ray = cam:ScreenPointToRay(loc.X, loc.Y)
        return ray.Origin + ray.Direction * d
    end
    local function Offset()
        local cam = workspace.CurrentCamera
        local vy = cam and cam.ViewportSize.Y or 1080
        return (vy / 2560) * 24 + 4
    end
    local function Update()
        if not self._root or not self._mesh or not self._enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local tl = V2W(positions.tl or Vector2.zero, dist)
        local tr = V2W(positions.tr or Vector2.zero, dist)
        local br = V2W(positions.br or Vector2.zero, dist)
        local w, h = (tr - tl).Magnitude, (tr - br).Magnitude
        self._root.CFrame = CFrame.fromMatrix((tl + br) / 2, cam.CFrame.XVector, cam.CFrame.YVector, cam.CFrame.ZVector)
        self._mesh.Scale = Vector3.new(w, h, 0)
    end
    local function OnChange()
        if not self._enabled or not self._frame then return end
        local off = Offset()
        local size = self._frame.AbsoluteSize - Vector2.new(off, off)
        local pos = self._frame.AbsolutePosition + Vector2.new(off/2, off/2)
        positions.tl, positions.tr, positions.br = pos, pos + Vector2.new(size.X, 0), pos + size
        task.spawn(Update)
    end
    local cam = workspace.CurrentCamera
    if cam then
        table.insert(self._conns, cam:GetPropertyChangedSignal("CFrame"):Connect(Update))
        table.insert(self._conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(Update))
        table.insert(self._conns, cam:GetPropertyChangedSignal("FieldOfView"):Connect(Update))
    end
    table.insert(self._conns, self._frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(OnChange))
    table.insert(self._conns, self._frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(OnChange))
    table.insert(self._conns, rs.RenderStepped:Connect(Update))
    task.spawn(OnChange)
end
function AcrylicBlur:SetEnabled(v)
    self._enabled = v
    if self._root then self._root.Transparency = v and 0.96 or 1 end
    if self._dof then self._dof.Enabled = v end
end
function AcrylicBlur:Destroy()
    for _, cn in ipairs(self._conns) do if typeof(cn) == "RBXScriptConnection" then cn:Disconnect() end end
    self._conns = {}
    if self._folder then self._folder:Destroy() end
    if self._dof then self._dof:Destroy() end
end

local function CreateNotifContainer(gui)
    local cont = Make("Frame", { Name = "NotifContainer", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.new(0, sz.Notif.W, 1, -40), Parent = gui })
    List(cont, 8); return cont
end

-- LIBRARY
local Library = {}
Library.__index = Library
Library.ActivePicker = nil

function Library.new(title, configFolder)
    local self = setmetatable({}, Library)
    self.title, self.configFolder = title or "Acrylic", configFolder or title or "Acrylic"
    self.sections, self.currentTab, self.minimized = {}, nil, false
    self._blur, self._keybinds, self._conns = nil, {}, {}
    self._toggleKey, self._visible, self._origH = Enum.KeyCode.RightControl, true, sz.Window.H
    self._minSz, self._maxSz = Vector2.new(sz.WindowMin.W, sz.WindowMin.H), Vector2.new(sz.WindowMax.W, sz.WindowMax.H)
    self._mobileBtn, self._cfgElements, self._autoSave, self._autoSaveLoop = nil, {}, false, false
    self._currentCfg, self._notifCont, self._currentTheme, self._themeDropdown = "default", nil, currentThemeName, nil
    self:_Build(); self:_ListenKeys(); self:_MobileSetup()
    self._notifCont = CreateNotifContainer(self.gui)
    return self
end

function Library:Notify(cfg)
    local title, desc, dur, icon, isErr = cfg.Title or "Notification", cfg.Description or "", cfg.Duration or 3.5, cfg.Icon or "rbxassetid://10709775704", cfg.Error or false
    local cont = self._notifCont
    if not cont or not cont.Parent then return end
    local holder = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, sz.Notif.H + 8), ClipsDescendants = false, Parent = cont })
    local card = Make("Frame", { BackgroundColor3 = c.Notif.Bg, BackgroundTransparency = 0.05, Position = UDim2.new(1, sz.Notif.W + 40, 0, 0), Size = UDim2.new(1, 0, 0, sz.Notif.H), ClipsDescendants = true, Parent = holder })
    Corner(card, sz.RadiusMd); local cardStroke = Stroke(card, c.Notif.Border, 1, 0.15)
    Label({ FontFace = font.SemiBold, TextColor3 = c.Text, Text = title, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 14), TextSize = fs.Body, Size = UDim2.new(1, -60, 0, 18), Parent = card })
    Label({ FontFace = font.Regular, TextColor3 = c.TextDim, Text = desc, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 34), TextSize = fs.Small, Size = UDim2.new(1, -60, 0, 18), Parent = card })
    Make("ImageLabel", { BackgroundTransparency = 1, Image = icon, ImageColor3 = isErr and c.Danger or c.TextDim, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -28, 0.5, 0), Size = UDim2.new(0, 18, 0, 18), Parent = card })
    local bar = Make("Frame", { BackgroundColor3 = isErr and c.Notif.Error or c.Notif.Ok, BackgroundTransparency = 0.5, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), Parent = card })
    Corner(bar, sz.Pill)
    local glow = Make("Frame", { BackgroundColor3 = isErr and c.Danger or c.Accent, BackgroundTransparency = 0.7, Position = UDim2.new(0, 0, 0.15, 0), Size = UDim2.new(0, 3, 0.7, 0), Parent = card })
    Corner(glow, sz.Pill)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, ease.Spring)
    Tween(cardStroke, { Transparency = 0.15 }, ease.Smooth)
    Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, ease.Linear, dur)
    local closeBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = card.ZIndex + 5, Parent = card })
    local function Dismiss()
        Tween(card, { Position = UDim2.new(1, sz.Notif.W + 40, 0, 0), BackgroundTransparency = 1 }, ease.Smooth)
        task.delay(ease.Smooth[1] + 0.05, function() if holder and holder.Parent then holder:Destroy() end end)
    end
    closeBtn.MouseButton1Click:Connect(Dismiss)
    task.delay(dur, function() if card and card.Parent then Dismiss() end end)
    return Dismiss
end

function Library:_ListenKeys()
    local conn = ui.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self._toggleKey then self:Toggle() end
        for _, kb in pairs(self._keybinds) do
            local match = (input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == kb.key) or input.UserInputType == kb.key
            if match and kb.callback then kb.callback() end
        end
    end)
    table.insert(self._conns, conn)
end

function Library:Toggle()
    self._visible = not self._visible
    if self._visible then
        self.container.Visible = true
        Tween(self.container, { BackgroundTransparency = 0.03 }, ease.Spring)
    else
        Tween(self.container, { BackgroundTransparency = 1, Position = UDim2.new(self.container.Position.X.Scale, self.container.Position.X.Offset, self.container.Position.Y.Scale, self.container.Position.Y.Offset + 16) }, ease.Fluid)
        task.delay(ease.Fluid[1], function() if self.container then self.container.Visible = false end end)
    end
    if self._blur then self._blur:SetEnabled(self._visible) end
    if self._mobileBtn then self._mobileBtn.Visible = not self._visible end
end

function Library:SetToggleKey(k) self._toggleKey = k end

function Library:_MobileSetup()
    local btn = Make("ImageButton", { Name = "MobileToggle", Image = "rbxassetid://112235310154264", ImageColor3 = c.Text, BackgroundColor3 = c.Surface, BackgroundTransparency = 0.05, Position = UDim2.new(0, 16, 0.5, -28), Size = UDim2.new(0, 56, 0, 56), AnchorPoint = Vector2.new(0, 0.5), Visible = false, ZIndex = 999, Parent = self.gui })
    Corner(btn, sz.RadiusMd); Stroke(btn, c.Border, 1, 0.2)
    btn.MouseEnter:Connect(function() Tween(btn, { BackgroundTransparency = 0, ImageColor3 = c.Accent }, ease.Swift) end)
    btn.MouseLeave:Connect(function() Tween(btn, { BackgroundTransparency = 0.05, ImageColor3 = c.Text }, ease.Swift) end)
    MakeDraggable(btn, btn, self._conns)
    table.insert(self._conns, btn.MouseButton1Click:Connect(function() Ripple(btn, ui:GetMouseLocation(), c.Accent, 100); self:Toggle() end))
    self._mobileBtn = btn
    if IsMobile() then btn.Visible = not self._visible end
end

function Library:_Build()
    self.gui = Make("ScreenGui", { Name = "Acrylic", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false, IgnoreGuiInset = true })
    self.container = Make("Frame", { Name = "Container", BackgroundColor3 = c.Background, BackgroundTransparency = 1, Position = UDim2.new(0.5, -sz.Window.W/2, 0.5, -sz.Window.H/2 + 24), Size = UDim2.new(0, sz.Window.W, 0, sz.Window.H), ClipsDescendants = false, Parent = self.gui })
    Corner(self.container, sz.RadiusLg); self._windowStroke = Stroke(self.container, c.Border, 1, 0.15)
    task.delay(0, function() Tween(self.container, { BackgroundTransparency = 0.03, Position = UDim2.new(0.5, -sz.Window.W/2, 0.5, -sz.Window.H/2) }, ease.Spring) end)
    self.topBar = Make("Frame", { Name = "TopBar", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, sz.TopBar), Parent = self.container })
    Label({ Name = "Title", FontFace = font.SemiBold, TextColor3 = c.Text, Text = self.title, BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0.5, -10), TextXAlignment = Enum.TextXAlignment.Left, TextSize = fs.Title, Size = UDim2.new(0, 240, 0, 20), Parent = self.topBar })
    self:_BuildControls()
    Make("Frame", { BackgroundColor3 = c.BorderSubtle, Position = UDim2.new(0, 0, 0, sz.TopBar), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = self.container })
    self:_BuildContent()
    MakeDraggable(self.container, self.topBar, self._conns)
    local lp = plr.LocalPlayer
    self.gui.Parent = lp:WaitForChild("PlayerGui")
    self._blur = AcrylicBlur.new(self.container)
end

function Library:_BuildControls()
    local function ControlBtn(xOffset, normalCol, hoverCol, iconImg, iconSize)
        local frame = Make("Frame", { BackgroundColor3 = normalCol, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOffset, 0.5, 0), Size = UDim2.new(0, 28, 0, 28), Parent = self.topBar })
        Corner(frame, sz.Radius)
        local icon = Make("ImageLabel", { Image = iconImg, ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, iconSize or 12, 0, iconSize or 12), Parent = frame })
        local btn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
        btn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0, BackgroundColor3 = hoverCol }, ease.Swift); Tween(icon, { ImageColor3 = c.Text, Size = UDim2.new(0, (iconSize or 12) + 1, 0, (iconSize or 12) + 1) }, ease.Swift) end)
        btn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 1, BackgroundColor3 = normalCol }, ease.Swift); Tween(icon, { ImageColor3 = c.TextMuted, Size = UDim2.new(0, iconSize or 12, 0, iconSize or 12) }, ease.Smooth) end)
        btn.MouseButton1Down:Connect(function() Tween(frame, { Size = UDim2.new(0, 26, 0, 26) }, ease.Snap) end)
        btn.MouseButton1Up:Connect(function() Tween(frame, { Size = UDim2.new(0, 28, 0, 28) }, ease.Snap) end)
        return frame, icon, btn
    end
    local closeFrame, closeIcon, closeBtn = ControlBtn(-14, c.Surface, c.DangerSurface, "rbxassetid://119943770201674", 12)
    closeBtn.MouseEnter:Connect(function() Tween(closeIcon, { ImageColor3 = c.Danger }, ease.Swift) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeIcon, { ImageColor3 = c.TextMuted }, ease.Swift) end)
    closeBtn.MouseButton1Click:Connect(function() Ripple(closeFrame, ui:GetMouseLocation(), c.Danger, 50); task.delay(0.10, function() self:Destroy() end) end)
    local minFrame, minIcon, minBtn = ControlBtn(-48, c.Surface, c.SurfaceHover, "rbxassetid://82603981310445", 12)
    minBtn.MouseButton1Click:Connect(function() Ripple(minFrame, ui:GetMouseLocation(), c.Accent, 50); self:_ToggleMinimize() end)
    local resize = Make("ImageButton", { Name = "Resize", Image = "rbxassetid://120997033468887", ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), Size = UDim2.new(0, 24, 0, 24), Parent = self.container })
    resize.MouseEnter:Connect(function() Tween(resize, { ImageColor3 = c.Text }, ease.Swift) end)
    resize.MouseLeave:Connect(function() Tween(resize, { ImageColor3 = c.TextMuted }, ease.Swift) end)
    self.resizeBtn = resize; self:_SetupResize(resize)
end

function Library:_BuildContent()
    self.mainContent = Make("Frame", { Name = "MainContent", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, sz.TopBar + 1), Size = UDim2.new(1, 0, 1, -(sz.TopBar + 1)), ClipsDescendants = true, Parent = self.container })
    self.sideScroll = Make("ScrollingFrame", { Name = "Sidebar", ScrollBarThickness = 0, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, sz.Sidebar, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self.mainContent })
    List(self.sideScroll, 0); Pad(self.sideScroll, 10, 10, 8, 8)
    Make("Frame", { BackgroundColor3 = c.BorderSubtle, Position = UDim2.new(0, sz.Sidebar, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 1, 1, 0), Parent = self.mainContent })
    self.contentScroll = Make("ScrollingFrame", { Name = "ContentScroll", ScrollBarThickness = 4, ScrollBarImageColor3 = c.Border, BackgroundTransparency = 1, Position = UDim2.new(0, sz.Sidebar + 1, 0, 0), Size = UDim2.new(1, -(sz.Sidebar + 1), 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self.mainContent })
    List(self.contentScroll, 10); Pad(self.contentScroll, 16, 16, 16, 16)
end

function Library:_SetupResize(handle)
    local resizing, rStart, sStart, mConn, eConn
    table.insert(self._conns, handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        resizing, rStart, sStart = true, input.Position, self.container.AbsoluteSize
        mConn = ui.InputChanged:Connect(function(mi)
            if not resizing or (mi.UserInputType ~= Enum.UserInputType.MouseMovement and mi.UserInputType ~= Enum.UserInputType.Touch) then return end
            local d = mi.Position - rStart
            local nw = math.clamp(sStart.X + d.X, self._minSz.X, self._maxSz.X)
            local nh = math.clamp(sStart.Y + d.Y, self._minSz.Y, self._maxSz.Y)
            self.container.Size = UDim2.new(0, nw, 0, nh); self._origH = nh
        end)
        eConn = ui.InputEnded:Connect(function(ei)
            if ei.UserInputType ~= Enum.UserInputType.MouseButton1 and ei.UserInputType ~= Enum.UserInputType.Touch then return end
            resizing = false; Tween(handle, { ImageColor3 = c.TextMuted }, ease.Swift)
            if mConn then mConn:Disconnect(); mConn = nil end; if eConn then eConn:Disconnect(); eConn = nil end
        end)
    end))
end

function Library:_ToggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then
        if self._blur then self._blur:SetEnabled(false) end
        Tween(self.mainContent, { Size = UDim2.new(1, 0, 0, 0) }, ease.Fluid)
        task.delay(0.05, function() Tween(self.container, { Size = UDim2.new(0, self.container.AbsoluteSize.X, 0, sz.TopBar + 1) }, ease.Fluid) end)
        if self.resizeBtn then self.resizeBtn.Visible = false end
    else
        if self._blur then self._blur:SetEnabled(true) end
        Tween(self.container, { Size = UDim2.new(0, self.container.AbsoluteSize.X, 0, self._origH) }, ease.Fluid)
        task.delay(ease.Fluid[1], function() if self.mainContent and self.mainContent.Parent then Tween(self.mainContent, { Size = UDim2.new(1, 0, 1, -(sz.TopBar + 1)) }, ease.Smooth) end end)
        if self.resizeBtn then self.resizeBtn.Visible = true end
    end
end

function Library:Destroy()
    if not self.gui or not self.gui.Parent then return end -- FIXED: Safe destroy
    if self._autoSave then self:SaveConfig(self._currentCfg) end
    for _, cn in ipairs(self._conns) do if typeof(cn) == "RBXScriptConnection" then cn:Disconnect() end end
    self._conns = {}
    if self._blur then self._blur:Destroy() end
    if self.container and self.container.Parent then
        Tween(self.container, { BackgroundTransparency = 1, Position = UDim2.new(self.container.Position.X.Scale, self.container.Position.X.Offset, self.container.Position.Y.Scale, self.container.Position.Y.Offset + 24) }, ease.Fluid)
    end
    task.delay(ease.Fluid[1] + 0.05, function() if self.gui and self.gui.Parent then self.gui:Destroy() end end)
end

function Library:_RegisterCfg(id, kind, get, set) self._cfgElements[id] = { kind = kind, getValue = get, setValue = set } end

function Library:SaveConfig(name)
    if not writefile then self:Notify({ Title = "Unsupported", Description = "Executor lacks writefile", Error = true }); return false end
    EnsureFolder(self.configFolder)
    local data = { _theme = self._currentTheme }
    for id, el in pairs(self._cfgElements) do
        local v = el.getValue()
        if typeof(v) == "Color3" then v = { R = v.R, G = v.G, B = v.B, _t = "c3" }
        elseif typeof(v) == "EnumItem" then v = { _t = "enum", _e = tostring(v.EnumType), _v = v.Name } end
        data[id] = v
    end
    local ok = pcall(function() writefile(self.configFolder .. "/" .. name .. ".json", hs:JSONEncode(data)) end)
    if ok then self._currentCfg = name; self:Notify({ Title = "Saved", Description = name, Icon = "rbxassetid://10723356507" }); return true end
    self:Notify({ Title = "Save Failed", Description = "Check permissions", Error = true }); return false
end

function Library:LoadConfig(name)
    if not readfile or not isfile then self:Notify({ Title = "Unsupported", Description = "Executor lacks readfile", Error = true }); return false end
    local path = self.configFolder .. "/" .. name .. ".json"
    if not isfile(path) then self:Notify({ Title = "Not Found", Description = name, Error = true }); return false end
    local ok, data = pcall(function() return hs:JSONDecode(readfile(path)) end)
    if not ok or not data then self:Notify({ Title = "Parse Error", Description = "Corrupted config", Error = true }); return false end
    if data._theme and THEMES[data._theme] then self:SetTheme(data._theme); data._theme = nil end
    for id, v in pairs(data) do
        if self._cfgElements[id] then
            if type(v) == "table" and v._t == "c3" then v = Color3.new(v.R, v.G, v.B)
            elseif type(v) == "table" and v._t == "enum" then v = Enum[v._e][v._v] end
            pcall(function() self._cfgElements[id].setValue(v) end)
        end
    end
    self._currentCfg = name; self:Notify({ Title = "Loaded", Description = name, Icon = "rbxassetid://10723356507" }); return true
end

function Library:DeleteConfig(name)
    if not delfile or not isfile then return false end
    local path = self.configFolder .. "/" .. name .. ".json"
    if isfile(path) then delfile(path); self:Notify({ Title = "Deleted", Description = name }); return true end
    return false
end

function Library:GetConfigs() return GetConfigs(self.configFolder) end

function Library:SetAutoSave(v)
    self._autoSave = v
    if v and not self._autoSaveLoop then
        self._autoSaveLoop = true
        task.spawn(function()
            while self._autoSave and self.gui and self.gui:IsDescendantOf(game) do
                task.wait(30)
                if self._autoSave then self:SaveConfig(self._currentCfg) end
            end; self._autoSaveLoop = false
        end)
    end
end

function Library:SetTheme(themeName)
    if not THEMES[themeName] then return false end
    local oldTheme = self._currentThemeData or c -- FIXED: Proper old theme reference
    currentThemeName = themeName; c = THEMES[themeName]; self._currentTheme = themeName; self._currentThemeData = c
    local function updateRecursive(instance)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("ImageLabel") or child:IsA("UIStroke") then
                if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextBox") then
                    if child.BackgroundColor3 == oldTheme.Base then child.BackgroundColor3 = c.Base
                    elseif child.BackgroundColor3 == oldTheme.Background then child.BackgroundColor3 = c.Background
                    elseif child.BackgroundColor3 == oldTheme.Surface then child.BackgroundColor3 = c.Surface
                    elseif child.BackgroundColor3 == oldTheme.SurfaceHover then child.BackgroundColor3 = c.SurfaceHover
                    elseif child.BackgroundColor3 == oldTheme.SurfaceActive then child.BackgroundColor3 = c.SurfaceActive
                    elseif child.BackgroundColor3 == oldTheme.SurfaceElevated then child.BackgroundColor3 = c.SurfaceElevated
                    elseif child.BackgroundColor3 == oldTheme.DangerSurface then child.BackgroundColor3 = c.DangerSurface
                    elseif child.BackgroundColor3 == oldTheme.SuccessSurface then child.BackgroundColor3 = c.SuccessSurface
                    elseif child.BackgroundColor3 == oldTheme.Notif.Bg then child.BackgroundColor3 = c.Notif.Bg
                    elseif child.BackgroundColor3 == oldTheme.Toggle.On then child.BackgroundColor3 = c.Toggle.On
                    elseif child.BackgroundColor3 == oldTheme.Toggle.Off then child.BackgroundColor3 = c.Toggle.Off
                    elseif child.BackgroundColor3 == oldTheme.Toggle.Thumb then child.BackgroundColor3 = c.Toggle.Thumb
                    elseif child.BackgroundColor3 == oldTheme.Toggle.ThumbOn then child.BackgroundColor3 = c.Toggle.ThumbOn
                    elseif child.BackgroundColor3 == oldTheme.Accent then child.BackgroundColor3 = c.Accent
                    elseif child.BackgroundColor3 == oldTheme.Danger then child.BackgroundColor3 = c.Danger
                    elseif child.BackgroundColor3 == oldTheme.Notif.Ok then child.BackgroundColor3 = c.Notif.Ok
                    elseif child.BackgroundColor3 == oldTheme.Notif.Error then child.BackgroundColor3 = c.Notif.Error
                    end
                end
                if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("ImageLabel") then
                    local isText = child:IsA("TextLabel") or child:IsA("TextBox")
                    local prop = isText and "TextColor3" or "ImageColor3"
                    local val = isText and child.TextColor3 or child.ImageColor3
                    if val == oldTheme.Text then child[prop] = c.Text
                    elseif val == oldTheme.TextDim then child[prop] = c.TextDim
                    elseif val == oldTheme.TextSubtle then child[prop] = c.TextSubtle
                    elseif val == oldTheme.TextMuted then child[prop] = c.TextMuted
                    elseif val == oldTheme.Accent then child[prop] = c.Accent
                    elseif val == oldTheme.Danger then child[prop] = c.Danger
                    elseif val == oldTheme.Success then child[prop] = c.Success
                    end
                end
                if child:IsA("UIStroke") then
                    if child.Color == oldTheme.Border then child.Color = c.Border
                    elseif child.Color == oldTheme.BorderSubtle then child.Color = c.BorderSubtle
                    elseif child.Color == oldTheme.BorderFocus then child.Color = c.BorderFocus
                    elseif child.Color == oldTheme.BorderAccent then child.Color = c.BorderAccent
                    end
                end
            end; updateRecursive(child)
        end
    end
    if self.gui then updateRecursive(self.gui) end
    if self._themeDropdown then self._themeDropdown._suppressCb = true; self._themeDropdown:SetValue(themeName); self._themeDropdown._suppressCb = false end
    return true
end

function Library:CreateSection(name)
    local sec = { name = name, tabs = {}, expanded = true, _lib = self }
    local secFrame = Make("Frame", { Name = "Sec_" .. name, BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = self.sideScroll })
    List(secFrame, 4)
    local hdr = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, Parent = secFrame })
    local hdrBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = hdr })
    Label({ FontFace = font.SemiBold, TextColor3 = c.TextSubtle, Text = string.upper(name), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), TextSize = fs.Tiny, Size = UDim2.new(1, -24, 1, 0), Parent = hdr })
    local arrow = Make("ImageLabel", { Image = "rbxassetid://105558791071013", ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 10, 0, 10), Rotation = 0, Parent = hdr })
    local tabsFrame = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = false, LayoutOrder = 1, Parent = secFrame })
    List(tabsFrame, 4); Pad(tabsFrame, 0, 6, 0, 0)
    local function ToggleSec()
        sec.expanded = not sec.expanded
        Tween(arrow, { Rotation = sec.expanded and 0 or -90 }, ease.Smooth)
        if sec.expanded then tabsFrame.Visible = true else task.delay(ease.Smooth[1], function() if not sec.expanded then tabsFrame.Visible = false end end) end
    end
    hdrBtn.MouseButton1Click:Connect(ToggleSec)
    sec.frame, sec.tabsFrame = secFrame, tabsFrame; table.insert(self.sections, sec)
    local methods = setmetatable({}, { __index = sec })
    function methods:CreateTab(tabName, icon) return Library._CreateTab(self, tabName, icon) end
    return methods
end

function Library._CreateTab(sec, name, icon)
    local tab = { name = name, elements = {}, _lib = sec._lib }
    local btn = Make("Frame", { Name = "Tab_" .. name, BackgroundColor3 = c.SurfaceHover, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, sz.Tab.H), ClipsDescendants = true, Parent = sec.tabsFrame })
    Corner(btn, sz.Radius); local btnStroke = Stroke(btn, c.Border, 1, 1)
    local accentBar = Make("Frame", { BackgroundColor3 = c.Accent, BackgroundTransparency = 1, Position = UDim2.new(0, 0, sz.AccentBar.VPad, 0), Size = UDim2.new(0, sz.AccentBar.W, 1 - sz.AccentBar.VPad * 2, 0), Parent = btn })
    Corner(accentBar, sz.Pill)
    local iconLbl = Make("ImageLabel", { Image = icon or "rbxassetid://112235310154264", ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.new(0, 16, 0, 16), Parent = btn })
    local txtLbl = Label({ FontFace = font.Medium, TextColor3 = c.TextSubtle, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -50, 1, 0), TextSize = fs.Small, Parent = btn })
    Pad(txtLbl, 0, 0, 0, 8)
    local txtGrad = Make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c.TextSubtle), ColorSequenceKeypoint.new(0.72, c.TextSubtle), ColorSequenceKeypoint.new(1, c.TextFade) }), Parent = txtLbl })
    local clickBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = btn })
    tab.content = Make("Frame", { Name = name .. "_Content", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = sec._lib.contentScroll })
    List(tab.content, 10)
    tab.button, tab.stroke, tab.accentBar, tab.iconLbl, tab.txtLbl, tab.txtGrad, tab._lib = btn, btnStroke, accentBar, iconLbl, txtLbl, txtGrad, sec._lib
    clickBtn.MouseEnter:Connect(function() if sec._lib.currentTab ~= tab then Tween(btn, { BackgroundTransparency = 0.6 }, ease.Swift) end end)
    clickBtn.MouseLeave:Connect(function() if sec._lib.currentTab ~= tab then Tween(btn, { BackgroundTransparency = 1 }, ease.Swift) end end)
    clickBtn.MouseButton1Down:Connect(function() Tween(btn, { Size = UDim2.new(1, 0, 0, sz.Tab.H - 2) }, ease.Snap) end)
    clickBtn.MouseButton1Up:Connect(function() Tween(btn, { Size = UDim2.new(1, 0, 0, sz.Tab.H) }, ease.Snap) end)
    clickBtn.MouseButton1Click:Connect(function() Ripple(btn, ui:GetMouseLocation(), c.Accent, sz.Tab.H * 2.5); Library._SelectTab(sec._lib, tab) end)
    table.insert(sec.tabs, tab)
    if not sec._lib.currentTab then Library._SelectTab(sec._lib, tab) end
    local m = setmetatable({}, { __index = tab })
    function m:CreateSection(n) return Library._ContentSection(self, n) end
    function m:CreateParagraph(cfg) return Library._Paragraph(self, cfg) end
    function m:CreateSlider(cfg) return Library._Slider(self, cfg) end
    function m:CreateButton(cfg) return Library._Button(self, cfg) end
    function m:CreateToggle(cfg) return Library._Toggle(self, cfg) end
    function m:CreateDropdown(cfg) return Library._Dropdown(self, cfg) end
    function m:CreateKeybind(cfg) return Library._Keybind(self, cfg, sec._lib) end
    function m:CreateColorPicker(cfg) return Library._ColorPicker(self, cfg) end
    function m:CreateTextBox(cfg) return Library._TextBox(self, cfg) end
    function m:CreateConfigSection() return Library._ConfigSection(self) end
    return m
end

function Library._SelectTab(lib, tab)
    if lib.currentTab then
        local old = lib.currentTab
        Tween(old.button, { BackgroundTransparency = 1 }, ease.Smooth)
        Tween(old.iconLbl, { ImageColor3 = c.TextMuted }, ease.Smooth)
        Tween(old.accentBar, { BackgroundTransparency = 1 }, ease.Smooth)
        old.stroke.Transparency = 1; old.txtLbl.TextColor3 = c.TextSubtle; old.txtGrad.Enabled = true; old.content.Visible = false
    end
    lib.currentTab = tab
    Tween(tab.button, { BackgroundTransparency = 0.45 }, ease.Smooth)
    Tween(tab.iconLbl, { ImageColor3 = c.Text }, ease.Smooth)
    tab.stroke.Transparency = 0.15; Tween(tab.accentBar, { BackgroundTransparency = 0 }, ease.Spring)
    tab.txtGrad.Enabled = false; tab.txtLbl.TextColor3 = c.Text; tab.content.Visible = true
end

local function Card(tab, name, height, autoSize)
    local f = Make("Frame", { Name = name, BackgroundColor3 = c.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, Size = autoSize and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, height or sz.Row), AutomaticSize = autoSize and Enum.AutomaticSize.Y or Enum.AutomaticSize.None, Parent = tab.content })
    Corner(f, sz.Radius); local stk = Stroke(f, c.Border, 1, 0.15)
    task.delay(0, function() if f and f.Parent then Tween(f, { BackgroundTransparency = 0.65 }, ease.Spring) end end)
    return f, stk
end

function Library._ContentSection(tab, name)
    local lbl = Label({ Name = "SecHdr_" .. name, FontFace = font.SemiBold, TextColor3 = c.TextSubtle, Text = string.upper(name), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), TextSize = fs.Tiny, Parent = tab.content })
    return { SetText = function(_, t) lbl.Text = string.upper(t) end, SetVisible = function(_, v) lbl.Visible = v end }
end

function Library._Paragraph(tab, cfg)
    local title, content = cfg.Title or "Info", cfg.Content or ""
    local frame, stk = Card(tab, "Para_" .. title, 0, true)
    List(frame, 6); Pad(frame, 14, 14, 16, 16)
    local titleLbl = Label({ FontFace = font.SemiBold, TextColor3 = c.Text, Text = title, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextSize = fs.Body, Size = UDim2.new(1, 0, 0, 18), Parent = frame })
    local bodyLbl = Label({ FontFace = font.Regular, TextColor3 = c.TextDim, Text = content, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, TextSize = fs.Small, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = frame })
    return { SetTitle = function(_, t) titleLbl.Text = t end, SetContent = function(_, t) bodyLbl.Text = t end }
end

function Library._Button(tab, cfg)
    local name, cb = cfg.Name or "Button", cfg.Callback or function() end
    local frame, stk = Card(tab, "Btn_" .. name, sz.Row)
    local lbl = Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(1, -48, 0, 18), Parent = frame })
    local chevron = Make("ImageLabel", { Image = "rbxassetid://105558791071013", ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), Rotation = -90, Parent = frame })
    local btn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0.4 }, ease.Swift); Tween(stk, { Color = c.BorderFocus, Transparency = 0.1 }, ease.Swift); Tween(chevron, { ImageColor3 = c.Text, Position = UDim2.new(1, -12, 0.5, 0) }, ease.Smooth) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 0.65 }, ease.Swift); Tween(stk, { Color = c.Border, Transparency = 0.15 }, ease.Swift); Tween(chevron, { ImageColor3 = c.TextMuted, Position = UDim2.new(1, -16, 0.5, 0) }, ease.Smooth) end)
    btn.MouseButton1Down:Connect(function() Tween(frame, { BackgroundTransparency = 0.2, Size = UDim2.new(1, 0, 0, sz.Row - 2) }, ease.Snap); Tween(lbl, { TextColor3 = c.AccentDim }, ease.Snap) end)
    btn.MouseButton1Up:Connect(function() Tween(frame, { Size = UDim2.new(1, 0, 0, sz.Row) }, ease.Snap) end)
    btn.MouseButton1Click:Connect(function() Ripple(frame, ui:GetMouseLocation(), c.Accent); task.delay(0.08, function() Tween(frame, { BackgroundTransparency = 0.65 }, ease.Smooth); Tween(lbl, { TextColor3 = c.Text }, ease.Smooth) end); task.delay(0.04, cb) end)
    return { SetText = function(_, t) lbl.Text = t end, SetVisible = function(_, v) frame.Visible = v end }
end

function Library._Toggle(tab, cfg)
    local name, default, cb, flag = cfg.Name or "Toggle", cfg.Default ~= nil and cfg.Default or false, cfg.Callback or function() end, cfg.Flag
    local enabled = default
    local frame, stk = Card(tab, "Tgl_" .. name, sz.Row)
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(1, -80, 0, 18), Parent = frame })
    local track = Make("Frame", { BackgroundColor3 = enabled and c.Toggle.On or c.Toggle.Off, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, sz.Toggle.W, 0, sz.Toggle.H), Parent = frame })
    Corner(track, sz.Pill); Stroke(track, c.BorderSubtle, 1, 0.3)
    local thumbOff, thumbOn = 4, sz.Toggle.W - sz.Toggle.Thumb - 4
    local thumb = Make("Frame", { BackgroundColor3 = enabled and c.Toggle.ThumbOn or c.Toggle.Thumb, AnchorPoint = Vector2.new(0, 0.5), Position = enabled and UDim2.new(0, thumbOn, 0.5, 0) or UDim2.new(0, thumbOff, 0.5, 0), Size = UDim2.new(0, sz.Toggle.Thumb, 0, sz.Toggle.Thumb), Parent = track })
    Corner(thumb, sz.Pill); Stroke(thumb, Color3.fromRGB(0,0,0), 1, 0.5)
    local btn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
    local function Refresh(skipCb)
        if enabled then
            Tween(track, { BackgroundColor3 = c.Toggle.On }, ease.Smooth)
            Tween(thumb, { Position = UDim2.new(0, thumbOn, 0.5, 0), BackgroundColor3 = c.Toggle.ThumbOn, Size = UDim2.new(0, sz.Toggle.Thumb, 0, sz.Toggle.Thumb) }, ease.Spring)
            Tween(stk, { Color = c.BorderAccent, Transparency = 0.1 }, ease.Swift)
        else
            Tween(track, { BackgroundColor3 = c.Toggle.Off }, ease.Smooth)
            Tween(thumb, { Position = UDim2.new(0, thumbOff, 0.5, 0), BackgroundColor3 = c.Toggle.Thumb, Size = UDim2.new(0, sz.Toggle.Thumb, 0, sz.Toggle.Thumb) }, ease.Spring)
            Tween(stk, { Color = c.Border, Transparency = 0.15 }, ease.Swift)
        end
        if not skipCb then cb(enabled) end
    end
    btn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0.45 }, ease.Swift); Tween(thumb, { Size = UDim2.new(0, sz.Toggle.Thumb + 2, 0, sz.Toggle.Thumb) }, ease.Swift) end)
    btn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 0.65 }, ease.Swift); Tween(thumb, { Size = UDim2.new(0, sz.Toggle.Thumb, 0, sz.Toggle.Thumb) }, ease.Smooth) end)
    btn.MouseButton1Down:Connect(function() Tween(frame, { Size = UDim2.new(1, 0, 0, sz.Row - 2) }, ease.Snap) end)
    btn.MouseButton1Up:Connect(function() Tween(frame, { Size = UDim2.new(1, 0, 0, sz.Row) }, ease.Snap) end)
    btn.MouseButton1Click:Connect(function() enabled = not enabled; Ripple(frame, ui:GetMouseLocation(), enabled and c.Accent or c.RippleDark); Refresh(false) end)
    local methods = { SetValue = function(_, v) enabled = v; Refresh(false) end, GetValue = function() return enabled end }
    if flag and tab._lib then tab._lib:_RegisterCfg(flag, "Toggle", function() return enabled end, function(v) methods:SetValue(v) end) end
    return methods
end

function Library._Slider(tab, cfg)
    local name, min, max, step, default, cb, flag, suffix = cfg.Name or "Slider", cfg.Min or 0, cfg.Max or 100, cfg.Step or 1, math.clamp(cfg.Default or (cfg.Min or 0), cfg.Min or 0, cfg.Max or 100), cfg.Callback or function() end, cfg.Flag, cfg.Suffix or ""
    local cur = default
    local frame, stk = Card(tab, "Sld_" .. name, sz.SliderH)
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 10), TextSize = fs.Body, Size = UDim2.new(0, 240, 0, 18), Parent = frame })
    local valLbl = Label({ FontFace = font.SemiBold, TextColor3 = c.TextSubtle, Text = tostring(cur) .. suffix, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Position = UDim2.new(1, -64, 0, 10), TextSize = fs.Body, Size = UDim2.new(0, 56, 0, 18), Parent = frame })
    local track = Make("Frame", { BackgroundColor3 = Color3.fromRGB(12, 12, 15), Position = UDim2.new(0, 16, 0, 36), Size = UDim2.new(1, -32, 0, 6), Parent = frame })
    Corner(track, sz.Pill); Stroke(track, Color3.fromRGB(30, 30, 35), 1)
    local fill = Make("Frame", { BackgroundColor3 = c.Accent, Size = UDim2.new((cur - min) / (max - min), 0, 1, 0), Parent = track }); Corner(fill, sz.Pill)
    local dimFill = Make("Frame", { BackgroundColor3 = c.BorderSubtle, BackgroundTransparency = 0.5, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(1 - (cur - min) / (max - min), 0, 1, 0), Parent = track }); Corner(dimFill, sz.Pill)
    local knob = Make("Frame", { BackgroundColor3 = c.Text, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((cur - min) / (max - min), 0, 0.5, 0), Size = UDim2.new(0, 16, 0, 16), ZIndex = frame.ZIndex + 3, Parent = track })
    Corner(knob, sz.Pill); Stroke(knob, Color3.fromRGB(0, 0, 0), 1, 0.4)
    local dragging, mConn, eConn = false, nil, nil
    local function SnapVal(v) if step and step > 0 then v = math.round((v - min) / step) * step + min end; return math.clamp(v, min, max) end
    local function SetPct(pct)
        pct = math.clamp(pct, 0, 1); cur = SnapVal(min + (max - min) * pct)
        local truePct = (cur - min) / (max - min)
        Tween(fill, { Size = UDim2.new(truePct, 0, 1, 0) }, ease.Snap)
        Tween(dimFill, { Size = UDim2.new(1 - truePct, 0, 1, 0) }, ease.Snap)
        Tween(knob, { Position = UDim2.new(truePct, 0, 0.5, 0) }, ease.Snap)
        valLbl.Text = tostring(cur) .. suffix
    end
    local function OnInput(input)
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        SetPct(pct); cb(cur)
    end
    track.MouseEnter:Connect(function() Tween(stk, { Color = c.BorderFocus, Transparency = 0.1 }, ease.Swift); Tween(knob, { Size = UDim2.new(0, 20, 0, 20) }, ease.Spring); Tween(valLbl, { TextColor3 = c.Text }, ease.Swift) end)
    track.MouseLeave:Connect(function() if not dragging then Tween(stk, { Color = c.Border, Transparency = 0.15 }, ease.Swift); Tween(knob, { Size = UDim2.new(0, 16, 0, 16) }, ease.Smooth); Tween(valLbl, { TextColor3 = c.TextSubtle }, ease.Swift) end end)
    table.insert(tab._lib._conns, track.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; Tween(knob, { Size = UDim2.new(0, 22, 0, 22) }, ease.Spring); OnInput(input)
        mConn = ui.InputChanged:Connect(function(mi) if not dragging or (mi.UserInputType ~= Enum.UserInputType.MouseMovement and mi.UserInputType ~= Enum.UserInputType.Touch) then return end; OnInput(mi) end)
        eConn = ui.InputEnded:Connect(function(ei)
            if ei.UserInputType ~= Enum.UserInputType.MouseButton1 and ei.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = false; Tween(knob, { Size = UDim2.new(0, 16, 0, 16) }, ease.Spring); Tween(valLbl, { TextColor3 = c.TextSubtle }, ease.Smooth)
            if mConn then mConn:Disconnect(); mConn = nil end; if eConn then eConn:Disconnect(); eConn = nil end
        end)
    end))
    local methods = { SetValue = function(_, v) cur = math.clamp(v, min, max); SetPct((cur - min) / (max - min)); cb(cur) end, GetValue = function() return cur end }
    if flag and tab._lib then tab._lib:_RegisterCfg(flag, "Slider", function() return cur end, function(v) methods:SetValue(v) end) end
    return methods
end

function Library._Dropdown(tab, cfg)
    local name, options, multi, cb, flag = cfg.Name or "Dropdown", cfg.Options or {}, cfg.MultiSelect or false, cfg.Callback or function() end, cfg.Flag
    local selected = multi and (type(cfg.Default) == "table" and cfg.Default or {}) or (cfg.Default or (options[1] or ""))
    local open = false
    local frame, stk = Card(tab, "DD_" .. name, sz.Dropdown.H); frame.ClipsDescendants = false
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(0, 220, 0, 18), Parent = frame })
    local chip = Make("Frame", { BackgroundColor3 = c.SurfaceActive, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 140, 0, 30), ZIndex = frame.ZIndex + 1, Parent = frame })
    Corner(chip, sz.Radius); local chipStroke = Stroke(chip, c.Border, 1, 0.15)
    local function DisplayText() return multi and (#selected > 0 and table.concat(selected, ", ") or "None") or ((selected ~= nil and selected ~= "") and tostring(selected) or "None") end
    local selLbl = Label({ FontFace = font.Regular, TextColor3 = c.Text, Text = DisplayText(), TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), TextSize = fs.Small, Size = UDim2.new(1, -30, 1, 0), ZIndex = chip.ZIndex + 1, Parent = chip })
    local chevron = Make("ImageLabel", { Image = "rbxassetid://105558791071013", ImageColor3 = c.TextMuted, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), Rotation = 0, ZIndex = chip.ZIndex + 1, Parent = chip })
    local maxV, panH = 6, math.min(#options, 6) * sz.Dropdown.OptionH
    local panel = Make("Frame", { BackgroundColor3 = c.SurfaceElevated, BackgroundTransparency = 0.04, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, 6), Size = UDim2.new(0, 140, 0, 0), ClipsDescendants = true, Visible = false, ZIndex = 500, Parent = frame })
    Corner(panel, sz.Radius); Stroke(panel, c.Border, 1, 0.1)
    local scroll = Make("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, #options * sz.Dropdown.OptionH), ScrollBarThickness = 4, ScrollBarImageColor3 = c.Border, ZIndex = 501, Parent = panel })
    List(scroll, 0)
    local function UpdateText() selLbl.Text = DisplayText() end
    local function BuildOption(opt)
        local row = Make("TextButton", { Name = opt, FontFace = font.Regular, TextColor3 = c.TextDim, Text = opt, BackgroundColor3 = c.SurfaceHover, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextSize = fs.Small, Size = UDim2.new(1, 0, 0, sz.Dropdown.OptionH), ZIndex = 502, Parent = scroll })
        Pad(row, 0, 0, 14, 0)
        row.MouseEnter:Connect(function() Tween(row, { BackgroundTransparency = 0.5, TextColor3 = c.Text }, ease.Swift) end)
        row.MouseLeave:Connect(function() Tween(row, { BackgroundTransparency = 1, TextColor3 = c.TextDim }, ease.Swift) end)
        row.MouseButton1Down:Connect(function() Tween(row, { BackgroundTransparency = 0.3 }, ease.Snap) end)
        row.MouseButton1Up:Connect(function() Tween(row, { BackgroundTransparency = 0.5 }, ease.Snap) end)
        row.MouseButton1Click:Connect(function()
            Ripple(panel, ui:GetMouseLocation(), c.Accent, 80)
            if multi then
                local idx = table.find(selected, opt)
                if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                UpdateText(); cb(selected)
            else
                selected = opt; UpdateText(); cb(selected); open = false
                Tween(panel, { Size = UDim2.new(0, 140, 0, 0) }, ease.Smooth); Tween(chevron, { Rotation = 0 }, ease.Smooth)
                task.delay(ease.Smooth[1], function() panel.Visible = false end); frame.ZIndex = 1
            end
        end)
    end
    for _, o in ipairs(options) do BuildOption(o) end
    local toggleBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = chip.ZIndex + 2, Parent = chip })
    toggleBtn.MouseEnter:Connect(function() Tween(chip, { BackgroundTransparency = 0 }, ease.Swift); Tween(chipStroke, { Color = c.BorderFocus, Transparency = 0.1 }, ease.Swift) end)
    toggleBtn.MouseLeave:Connect(function() Tween(chip, { BackgroundTransparency = 0.02 }, ease.Swift); Tween(chipStroke, { Color = c.Border, Transparency = 0.15 }, ease.Swift) end)
    toggleBtn.MouseButton1Down:Connect(function() Tween(chip, { Size = UDim2.new(0, 140, 0, 28) }, ease.Snap) end)
    toggleBtn.MouseButton1Up:Connect(function() Tween(chip, { Size = UDim2.new(0, 140, 0, 30) }, ease.Snap) end)
    toggleBtn.MouseButton1Click:Connect(function()
        open = not open; Tween(chevron, { Rotation = open and 180 or 0 }, ease.Smooth)
        if open then panel.Visible = true; panel.Size = UDim2.new(0, 140, 0, 0); frame.ZIndex = 200; Tween(panel, { Size = UDim2.new(0, 140, 0, panH) }, ease.Spring)
        else Tween(panel, { Size = UDim2.new(0, 140, 0, 0) }, ease.Smooth); task.delay(ease.Smooth[1], function() panel.Visible = false end); frame.ZIndex = 1 end
    end)
    local methods = { _suppressCb = false }
    methods.SetValue = function(_, v)
        if multi and type(v) == "table" then selected = v elseif not multi then selected = v end
        UpdateText(); if not methods._suppressCb then cb(selected) end
    end
    methods.GetValue = function() return selected end
    methods.Refresh = function(_, newOpts)
        options = newOpts
        for _, ch in ipairs(scroll:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for _, o in ipairs(options) do BuildOption(o) end
        scroll.CanvasSize = UDim2.new(0, 0, 0, #options * sz.Dropdown.OptionH)
        panH = math.min(#options, maxV) * sz.Dropdown.OptionH; panel.Size = UDim2.new(0, 140, 0, panH)
        if not multi then
            local found = false
            for _, o in ipairs(options) do if o == selected then found = true; break end end
            if not found then selected = options[1] or ""; UpdateText() end
        end
    end
    if flag and tab._lib then tab._lib:_RegisterCfg(flag, "Dropdown", function() return selected end, function(v) methods:SetValue(v) end) end
    return methods
end

function Library._Keybind(tab, cfg, lib)
    local name, dflt, cb, flag = cfg.Name or "Keybind", cfg.Default or Enum.KeyCode.F, cfg.Callback or function() end, cfg.Flag
    local cur, lstng = dflt, false
    local frame, stk = Card(tab, "KB_" .. name, sz.Row)
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(1, -90, 0, 18), Parent = frame })
    local kbBox = Make("Frame", { BackgroundColor3 = c.SurfaceActive, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 32, 0, 28), Parent = frame })
    Corner(kbBox, sz.Radius); local kbStroke = Stroke(kbBox, c.Border, 1, 0.15)
    local kbLbl = Label({ FontFace = font.SemiBold, TextColor3 = c.Text, Text = typeof(cur) == "EnumItem" and cur.Name or tostring(cur), BackgroundTransparency = 1, TextSize = fs.Tiny, Size = UDim2.new(1, 0, 1, 0), Parent = kbBox })
    local clickBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = kbBox })
    local id = name .. "_" .. tostring(tick())
    lib._keybinds[id] = { key = cur, callback = cb }
    local function Refresh()
        if lstng then
            kbLbl.Text, kbBox.Size = "...", UDim2.new(0, 44, 0, 28)
            Tween(kbStroke, { Color = c.Accent, Transparency = 0.1 }, ease.Swift); Tween(kbBox, { BackgroundColor3 = c.SurfaceHover }, ease.Swift)
        else
            local kn = typeof(cur) == "EnumItem" and cur.Name or tostring(cur)
            kbBox.Size, kbLbl.Text = UDim2.new(0, math.max(#kn * 8 + 20, 32), 0, 28), kn
            Tween(kbStroke, { Color = c.Border, Transparency = 0.15 }, ease.Swift); Tween(kbBox, { BackgroundColor3 = c.SurfaceActive }, ease.Swift)
        end
    end
    clickBtn.MouseEnter:Connect(function() Tween(frame, { BackgroundTransparency = 0.45 }, ease.Swift); Tween(kbStroke, { Color = c.BorderFocus, Transparency = 0.1 }, ease.Swift) end)
    clickBtn.MouseLeave:Connect(function() Tween(frame, { BackgroundTransparency = 0.65 }, ease.Swift); if not lstng then Tween(kbStroke, { Color = c.Border, Transparency = 0.15 }, ease.Swift) end end)
    clickBtn.MouseButton1Down:Connect(function() Tween(kbBox, { Size = UDim2.new(0, kbBox.Size.X.Offset - 2, 0, 26) }, ease.Snap) end)
    clickBtn.MouseButton1Up:Connect(function() Tween(kbBox, { Size = UDim2.new(0, kbBox.Size.X.Offset + 2, 0, 28) }, ease.Snap) end)
    clickBtn.MouseButton1Click:Connect(function() lstng = true; Ripple(kbBox, ui:GetMouseLocation(), c.Accent, 60); Refresh() end)
    table.insert(lib._conns, ui.InputBegan:Connect(function(input)
        if not lstng then return end
        if input.KeyCode == Enum.KeyCode.Escape then lstng = false; Refresh(); return end
        if input.UserInputType == Enum.UserInputType.Keyboard then cur = input.KeyCode
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then cur = input.UserInputType
        else return end
        lstng = false; lib._keybinds[id].key = cur; Refresh()
    end))
    Refresh()
    local methods = { SetKey = function(_, k) cur = k; lib._keybinds[id].key = k; Refresh() end, GetKey = function() return cur end }
    if flag and lib then lib:_RegisterCfg(flag, "Keybind", function() return cur end, function(v) methods:SetKey(v) end) end
    return methods
end

function Library._ColorPicker(tab, cfg)
    local name, default, cb, flag = cfg.Name or "Color", cfg.Default or Color3.fromRGB(255, 255, 255), cfg.Callback or function() end, cfg.Flag
    local cur, h, s, v, pickerOpen = default, default:ToHSV()
    local frame, stk = Card(tab, "CP_" .. name, sz.Row)
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(1, -64, 0, 18), Parent = frame })
    local preview = Make("Frame", { BackgroundColor3 = cur, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, sz.ColorPrev.W, 0, sz.ColorPrev.H), ZIndex = frame.ZIndex + 1, Parent = frame })
    Corner(preview, sz.Radius); local prevStroke = Stroke(preview, c.Border, 1, 0.15)
    local prevBtn = Make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = preview.ZIndex + 1, Parent = preview })
    prevBtn.MouseEnter:Connect(function() Tween(prevStroke, { Color = c.BorderFocus, Transparency = 0.1 }, ease.Swift); Tween(preview, { Size = UDim2.new(0, sz.ColorPrev.W + 2, 0, sz.ColorPrev.H + 2) }, ease.Swift) end)
    prevBtn.MouseLeave:Connect(function() Tween(prevStroke, { Color = c.Border, Transparency = 0.15 }, ease.Swift); Tween(preview, { Size = UDim2.new(0, sz.ColorPrev.W, 0, sz.ColorPrev.H) }, ease.Smooth) end)
    local screen = tab.content:FindFirstAncestorOfClass("ScreenGui") or tab.content
    local picker = Make("Frame", { BackgroundColor3 = Color3.fromRGB(16, 16, 20), BackgroundTransparency = 0.04, Size = UDim2.new(0, 180, 0, 132), Visible = false, ZIndex = 3000, Parent = screen })
    Corner(picker, sz.RadiusMd); Stroke(picker, Color3.fromRGB(40, 40, 50), 1, 0.15)
    local sv = Make("Frame", { BackgroundColor3 = Color3.fromHSV(h, 1, 1), Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(1, -20, 0, 96), ZIndex = 3001, Parent = picker }); Corner(sv, sz.Radius)
    local wLayer = Make("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), ZIndex = 3002, Parent = sv }); Corner(wLayer, sz.Radius)
    Make("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = wLayer })
    local bLayer = Make("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), ZIndex = 3003, Parent = sv }); Corner(bLayer, sz.Radius)
    Make("UIGradient", { Color = ColorSequence.new(Color3.new(0,0,0)), Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = bLayer })
    local svCursor = Make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1-v, 0), Size = UDim2.new(0, 14, 0, 14), ZIndex = 3006, Parent = sv })
    Stroke(svCursor, Color3.new(1,1,1), 2, 0); Corner(svCursor, sz.Pill)
    local innerDot = Make("Frame", { BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.4, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0, 5, 0, 5), ZIndex = 3007, Parent = svCursor }) -- FIXED: Stored reference
    Corner(innerDot, sz.Pill)
    local hueBar = Make("Frame", { Position = UDim2.new(0, 10, 0, 114), Size = UDim2.new(1, -20, 0, 10), ZIndex = 3001, Parent = picker }); Corner(hueBar, sz.Pill)
    Make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)), ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)), ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)), ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)) }), Parent = hueBar })
    local hueCursor = Make("Frame", { BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), Size = UDim2.new(0, 15, 0, 15), ZIndex = 3005, Parent = hueBar })
    Corner(hueCursor, sz.Pill); Stroke(hueCursor, Color3.fromRGB(20, 20, 25), 1, 0.2)
    local function UpdateColor()
        cur = Color3.fromHSV(h, s, v)
        Tween(preview, { BackgroundColor3 = cur }, ease.Swift)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position, hueCursor.Position = UDim2.new(s, 0, 1-v, 0), UDim2.new(h, 0, 0.5, 0)
        cb(cur)
    end
    local svDrag, hueDrag, mConn, eConn = false, false, nil, nil
    local function HandleDrag(input)
        if svDrag then
            local sz2, p = sv.AbsoluteSize, sv.AbsolutePosition
            s, v = math.clamp((input.Position.X - p.X) / sz2.X, 0, 1), 1 - math.clamp((input.Position.Y - p.Y) / sz2.Y, 0, 1)
            UpdateColor()
        elseif hueDrag then
            local sz2, p = hueBar.AbsoluteSize, hueBar.AbsolutePosition
            h = math.clamp((input.Position.X - p.X) / sz2.X, 0, 1)
            UpdateColor()
        end
    end
    local function StartListen()
        if mConn or eConn then return end
        mConn = ui.InputChanged:Connect(function(mi) if not (svDrag or hueDrag) or (mi.UserInputType ~= Enum.UserInputType.MouseMovement and mi.UserInputType ~= Enum.UserInputType.Touch) then return end; HandleDrag(mi) end)
        eConn = ui.InputEnded:Connect(function(ei) if ei.UserInputType ~= Enum.UserInputType.MouseButton1 and ei.UserInputType ~= Enum.UserInputType.Touch then return end; svDrag, hueDrag = false, false; if mConn then mConn:Disconnect(); mConn = nil end; if eConn then eConn:Disconnect(); eConn = nil end end)
    end
    sv.InputBegan:Connect(function(i) if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end; svDrag = true; HandleDrag(i); StartListen() end)
    hueBar.InputBegan:Connect(function(i) if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end; hueDrag = true; HandleDrag(i); StartListen() end)
    local function ClosePicker()
        Tween(picker, { Size = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1 }, ease.Smooth)
        task.delay(ease.Smooth[1], function() picker.Visible = false end)
        pickerOpen = false
        if Library.ActivePicker == ClosePicker then Library.ActivePicker = nil end
    end
    local function OpenPicker()
        if Library.ActivePicker then Library.ActivePicker() end
        Library.ActivePicker = ClosePicker
        local btnPos, cam, vp = preview.AbsolutePosition, workspace.CurrentCamera, workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local tx, ty = btnPos.X - 190, btnPos.Y
        if ty + 140 > vp.Y then ty = vp.Y - 148 end
        if tx < 0 then tx = btnPos.X + sz.ColorPrev.W + 8 end
        picker.Position, picker.Size, picker.BackgroundTransparency, picker.Visible = UDim2.new(0, tx, 0, ty), UDim2.new(0, 180, 0, 0), 0.96, true
        Tween(picker, { Size = UDim2.new(0, 180, 0, 132), BackgroundTransparency = 0.04 }, ease.Spring)
        pickerOpen = true
    end
    prevBtn.MouseButton1Click:Connect(function() Ripple(preview, ui:GetMouseLocation(), c.Accent, 70); if pickerOpen then ClosePicker() else OpenPicker() end end)
    table.insert(tab._lib._conns, ui.InputBegan:Connect(function(input)
        if not pickerOpen or (input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch) then return end
        local pos, pPos, pSz, bPos, bSz = input.Position, picker.AbsolutePosition, picker.AbsoluteSize, preview.AbsolutePosition, preview.AbsoluteSize
        local inP = pos.X >= pPos.X and pos.X <= pPos.X + pSz.X and pos.Y >= pPos.Y and pos.Y <= pPos.Y + pSz.Y
        local inB = pos.X >= bPos.X and pos.X <= bPos.X + bSz.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSz.Y
        if not inP and not inB then ClosePicker() end
    end))
    local methods = { SetColor = function(_, color) cur = color; h, s, v = color:ToHSV(); UpdateColor() end, GetColor = function() return cur end }
    if flag and tab._lib then tab._lib:_RegisterCfg(flag, "ColorPicker", function() return cur end, function(val) methods:SetColor(val) end) end
    return methods
end

function Library._TextBox(tab, cfg)
    local name, default, ph, cb, clearOnFoc, numOnly, flag = cfg.Name or "TextBox", cfg.Default or "", cfg.Placeholder or "Type here...", cfg.Callback or function() end, cfg.ClearOnFocus or false, cfg.NumbersOnly or false, cfg.Flag
    local cur = default
    local frame, stk = Card(tab, "TB_" .. name, sz.Row)
    Label({ FontFace = font.Medium, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0.5, -9), TextSize = fs.Body, Size = UDim2.new(1, -180, 0, 18), Parent = frame })
    local inputFrame = Make("Frame", { BackgroundColor3 = c.SurfaceActive, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 160, 0, 28), Parent = frame })
    Corner(inputFrame, sz.Radius); local inputStroke = Stroke(inputFrame, c.Border, 1, 0.15)
    local tbox = Make("TextBox", { FontFace = font.Regular, TextColor3 = c.Text, PlaceholderText = ph, PlaceholderColor3 = c.TextMuted, Text = cur, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, TextSize = fs.Small, Size = UDim2.new(1, -18, 1, 0), Position = UDim2.new(0, 9, 0, 0), ClearTextOnFocus = clearOnFoc, Parent = inputFrame })
    tbox.Focused:Connect(function() Tween(inputFrame, { BackgroundTransparency = 0, BackgroundColor3 = c.Surface }, ease.Swift); Tween(inputStroke, { Color = c.BorderFocus, Transparency = 0.1, Thickness = 1.5 }, ease.Swift); Tween(frame, { BackgroundTransparency = 0.4 }, ease.Swift) end)
    tbox.FocusLost:Connect(function(enter)
        Tween(inputFrame, { BackgroundTransparency = 0.02, BackgroundColor3 = c.SurfaceActive }, ease.Swift); Tween(inputStroke, { Color = c.Border, Transparency = 0.15, Thickness = 1 }, ease.Swift); Tween(frame, { BackgroundTransparency = 0.65 }, ease.Swift)
        if numOnly then local n = tonumber(tbox.Text); cur = n and tostring(n) or cur; tbox.Text = cur else cur = tbox.Text end
        cb(cur, enter)
    end)
    if numOnly then table.insert(tab._lib._conns, tbox:GetPropertyChangedSignal("Text"):Connect(function() local t = tbox.Text; local f2 = t:gsub("[^%d%.%-]", ""); if t ~= f2 then tbox.Text = f2 end end)) end
    local methods = { SetText = function(_, t) cur = tostring(t); tbox.Text = cur end, GetText = function() return cur end, SetPlaceholder = function(_, p) tbox.PlaceholderText = p end, Focus = function() tbox:CaptureFocus() end }
    if flag and tab._lib then tab._lib:_RegisterCfg(flag, "TextBox", function() return cur end, function(t) methods:SetText(t) end) end
    return methods
end

function Library._ConfigSection(tab)
    local lib = tab._lib
    Library._ContentSection(tab, "Configuration")
    local themeDropdown = Library._Dropdown(tab, { Name = "UI Theme", Options = {"Dark", "Light", "Midnight", "Rose", "Ocean", "Forest"}, Default = lib._currentTheme, Flag = "ui_theme_selection", Callback = function(theme) lib:SetTheme(theme) end })
    lib._themeDropdown = themeDropdown
    local nameBox = Library._TextBox(tab, { Name = "Config Name", Default = "default", Placeholder = "config name...", Callback = function(t) lib._currentCfg = t end })
    local cfgs = lib:GetConfigs()
    local dropdown = Library._Dropdown(tab, { Name = "Select Config", Options = cfgs, Default = cfgs[1] or "", Callback = function(sel) if sel and sel ~= "" then nameBox:SetText(sel); lib._currentCfg = sel end end })
    Library._Button(tab, { Name = "Save Config", Callback = function() local n = nameBox:GetText(); if n ~= "" then lib:SaveConfig(n); dropdown:Refresh(lib:GetConfigs()) end end })
    Library._Button(tab, { Name = "Load Config", Callback = function() local n = nameBox:GetText(); if n ~= "" then lib:LoadConfig(n) end end })
    Library._Button(tab, { Name = "Delete Config", Callback = function() local n = nameBox:GetText(); if n ~= "" then lib:DeleteConfig(n); dropdown:Refresh(lib:GetConfigs()) end end })
    Library._Button(tab, { Name = "Refresh List", Callback = function() dropdown:Refresh(lib:GetConfigs()); lib:Notify({ Title = "Refreshed", Description = "Config list updated" }) end })
    Library._Toggle(tab, { Name = "Auto Save", Default = false, Callback = function(v) lib:SetAutoSave(v) end })
    return { Refresh = function() dropdown:Refresh(lib:GetConfigs()) end }
end

--==============================================================================
-- EZ HUB — DOORS features (built on the Acrylic library above)
--==============================================================================

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Lighting   = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TPS        = game:GetService("TeleportService")
local LP         = Players.LocalPlayer

local Remotes = RS:FindFirstChild("RemotesFolder")

-- DOORS entity + item names (from the dump).
local ENTITY_NAMES = {
	Rush=true, Ambush=true, Eyes=true, Screech=true, Halt=true, Seek=true,
	Figure=true, Snare=true, Timothy=true, Dupe=true, Glitch=true, Void=true,
	Giggle=true, Dread=true, Greed=true, Haste=true, Bob=true, Jack=true,
	["A-90"]=true, ["A-120"]=true, ["A-60"]=true,
}
local ITEM_NAMES = {
	Key=true, Lockpick=true, ["Skeleton Key"]=true, Vitamins=true, Bandage=true,
	Crucifix=true, Lighter=true, Candle=true, Flashlight=true, Gold=true,
	Knob=true, Lever=true,
}

local flags = { walkspeed = 22, jumppower = 60, flyspeed = 60 }

local function getChar() return LP.Character end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c=getChar(); return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart) end

-- ------------------------------------------------------------------ Window
local Window = Library.new("Ez Hub - DOORS", "EzHubDoors")
Window:SetToggleKey(Enum.KeyCode.RightShift)

if game.PlaceId ~= 6839171747 then
	Window:Notify({ Title = "Heads up", Description = "This script is built for DOORS. Some features may not work here.", Duration = 5 })
end

-- ------------------------------------------------------------------ ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "EzHubDoorsESP"
pcall(function() espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not espFolder.Parent then pcall(function() espFolder.Parent = LP:WaitForChild("PlayerGui") end) end

local highlights = {}
local RED, GREEN, BLUE, GOLD = Color3.fromRGB(255,60,60), Color3.fromRGB(80,230,120), Color3.fromRGB(90,160,255), Color3.fromRGB(255,210,80)

local function ensureHL(inst, col)
	local h = highlights[inst]
	if not h or not h.Parent then
		h = Instance.new("Highlight")
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = 0.55
		h.OutlineTransparency = 0
		h.Adornee = inst
		h.Parent = espFolder
		highlights[inst] = h
	end
	h.FillColor = col
	h.OutlineColor = col
end
local function clearHL(inst) if highlights[inst] then highlights[inst]:Destroy(); highlights[inst]=nil end end
local function clearAllHL() for i,h in pairs(highlights) do h:Destroy(); highlights[i]=nil end end

local function espScan()
	if not (flags.entityESP or flags.itemESP or flags.doorESP) then
		if next(highlights) then clearAllHL() end
		return
	end
	local want = {}
	if flags.entityESP then
		for _, m in ipairs(workspace:GetChildren()) do
			if ENTITY_NAMES[m.Name] and m:IsA("Model") then want[m] = RED end
		end
	end
	local cr = workspace:FindFirstChild("CurrentRooms")
	if cr then
		for _, room in ipairs(cr:GetChildren()) do
			for _, d in ipairs(room:GetDescendants()) do
				if flags.entityESP and ENTITY_NAMES[d.Name] and d:IsA("Model") then
					want[d] = RED
				elseif flags.itemESP and ITEM_NAMES[d.Name] and (d:IsA("Model") or d:IsA("BasePart")) then
					want[d] = (d.Name == "Gold") and GOLD or GREEN
				elseif flags.doorESP and d.Name == "Door" and d:IsA("Model") then
					want[d] = BLUE
				end
			end
		end
	end
	for inst in pairs(highlights) do
		if not want[inst] or not inst.Parent then clearHL(inst) end
	end
	for inst, col in pairs(want) do ensureHL(inst, col) end
end

task.spawn(function()
	while espFolder.Parent do
		pcall(espScan)
		task.wait(0.4)
	end
end)

-- Entity notifier
local notifierConn
local function setNotifier(on)
	if on and not notifierConn then
		notifierConn = workspace.DescendantAdded:Connect(function(d)
			if flags.notifier and ENTITY_NAMES[d.Name] and d:IsA("Model") then
				Window:Notify({ Title = "Entity: " .. d.Name, Description = d.Name .. " has appeared!", Duration = 4 })
			end
		end)
	elseif not on and notifierConn then
		notifierConn:Disconnect(); notifierConn = nil
	end
end

-- ------------------------------------------------------------------ Maintainers
RunService.Heartbeat:Connect(function()
	if flags.fullbright then
		Lighting.Brightness = 2
		Lighting.ClockTime = 12
		Lighting.FogEnd = 1e9
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(180,180,180)
		Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
	end
	if flags.noFog then
		Lighting.FogStart = 0
		Lighting.FogEnd = 1e9
	end
	local h = getHum()
	if h then
		if flags.speed then h.WalkSpeed = flags.walkspeed end
		if flags.highjump then h.UseJumpPower = true; h.JumpPower = flags.jumppower end
		if flags.godmode then pcall(function() h.MaxHealth = math.huge; h.Health = math.huge end) end
	end
	if flags.noclip then
		local c = getChar()
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end
	end
end)

-- ------------------------------------------------------------------ Fly
local flyConn, flyBV, flyBG
local function stopFly()
	flags.fly = false
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if flyBV then flyBV:Destroy(); flyBV = nil end
	if flyBG then flyBG:Destroy(); flyBG = nil end
end
local function startFly()
	local root = getRoot()
	if not root then return end
	flags.fly = true
	flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1,1,1)*9e9; flyBV.Velocity = Vector3.zero; flyBV.Parent = root
	flyBG = Instance.new("BodyGyro");     flyBG.MaxTorque = Vector3.new(1,1,1)*9e9; flyBG.P = 9e4;                flyBG.Parent = root
	flyConn = RunService.RenderStepped:Connect(function()
		if not flags.fly or not root.Parent then return end
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
		flyBV.Velocity = dir * flags.flyspeed
		flyBG.CFrame = cam.CFrame
	end)
end

-- Re-attach fly to a freshly spawned character (the old body movers die with it).
LP.CharacterAdded:Connect(function()
	if flags.fly then
		task.wait(0.6)
		if flyConn then flyConn:Disconnect(); flyConn = nil end
		flyBV, flyBG = nil, nil
		startFly()
	end
end)

-- ------------------------------------------------------------------ Automation
local warnedNoPrompt = false
local function firePrompts(includeDoors)
	if not fireproximityprompt then
		if not warnedNoPrompt then
			warnedNoPrompt = true
			Window:Notify({ Title = "Unsupported", Description = "Your executor lacks fireproximityprompt.", Duration = 5 })
		end
		return 0
	end
	local cr = workspace:FindFirstChild("CurrentRooms")
	if not cr then return 0 end
	local n = 0
	for _, d in ipairs(cr:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local isDoor = (d.Parent and (d.Parent.Name == "Door" or (d.Parent.Parent and d.Parent.Parent.Name == "Door"))) and true or false
			if includeDoors == isDoor then
				pcall(function() fireproximityprompt(d) end)
				n = n + 1
			end
		end
	end
	return n
end

local function revealPadlock()
	local pad = workspace:FindFirstChild("Padlock", true)
	if not pad then
		Window:Notify({ Title = "Padlock", Description = "No padlock in this room.", Duration = 4 })
		return
	end
	local code
	for _, key in ipairs({ "Code", "Answer", "Combination", "code" }) do
		local a = pad:GetAttribute(key)
		if a ~= nil then code = tostring(a); break end
	end
	if not code then
		local digits = {}
		for _, d in ipairs(pad:GetDescendants()) do
			if d:IsA("IntValue") or d:IsA("NumberValue") then table.insert(digits, tostring(d.Value)) end
		end
		if #digits > 0 then code = table.concat(digits) end
	end
	Window:Notify({
		Title = code and "Padlock code" or "Padlock",
		Description = code or "Couldn't read the code on this version.",
		Duration = code and 8 or 5,
	})
end

-- Anti-AFK
local afkConn
local function setAntiAFK(on)
	if on and not afkConn then
		afkConn = LP.Idled:Connect(function()
			pcall(function()
				local V = game:GetService("VirtualUser")
				V:CaptureController()
				V:ClickButton2(Vector2.new())
			end)
		end)
	elseif not on and afkConn then
		afkConn:Disconnect(); afkConn = nil
	end
end

-- ------------------------------------------------------------------ Loop toggles (auto loot / doors)
task.spawn(function()
	while espFolder.Parent do
		if flags.autoLoot then pcall(function() firePrompts(false) end) end
		if flags.autoDoors then pcall(function() firePrompts(true) end) end
		task.wait(0.6)
	end
end)

-- ==============================================================================
-- UI
-- ==============================================================================
local section = Window:CreateSection("DOORS")

-- Visuals
local visuals = section:CreateTab("Visuals")
visuals:CreateToggle({ Name = "Fullbright",       Default = false, Flag = "fullbright", Callback = function(v) flags.fullbright = v end })
visuals:CreateToggle({ Name = "No Fog",           Default = false, Flag = "nofog",      Callback = function(v) flags.noFog = v end })
visuals:CreateToggle({ Name = "Entity ESP",       Default = false, Flag = "entityesp",  Callback = function(v) flags.entityESP = v end })
visuals:CreateToggle({ Name = "Item ESP",         Default = false, Flag = "itemesp",    Callback = function(v) flags.itemESP = v end })
visuals:CreateToggle({ Name = "Door ESP",         Default = false, Flag = "dooresp",    Callback = function(v) flags.doorESP = v end })
visuals:CreateToggle({ Name = "Entity Notifier",  Default = false, Flag = "notifier",   Callback = function(v) flags.notifier = v; setNotifier(v) end })

-- Player
local player = section:CreateTab("Player")
player:CreateToggle({ Name = "Speed",   Default = false, Flag = "speed",    Callback = function(v) flags.speed = v end })
player:CreateSlider({ Name = "WalkSpeed", Min = 16, Max = 120, Default = flags.walkspeed, Step = 1, Suffix = " sps", Flag = "walkspeed", Callback = function(v) flags.walkspeed = v end })
player:CreateToggle({ Name = "High Jump", Default = false, Flag = "highjump", Callback = function(v) flags.highjump = v end })
player:CreateSlider({ Name = "JumpPower", Min = 50, Max = 250, Default = flags.jumppower, Step = 1, Flag = "jumppower", Callback = function(v) flags.jumppower = v end })
player:CreateToggle({ Name = "Noclip",  Default = false, Flag = "noclip",   Callback = function(v)
	flags.noclip = v
	if not v then
		-- Restore collisions so the player stops falling through the world.
		local c = getChar()
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
			end
		end
	end
end })
player:CreateToggle({ Name = "Fly (WASD + Space/Ctrl)", Default = false, Flag = "fly", Callback = function(v) if v then startFly() else stopFly() end end })
player:CreateSlider({ Name = "Fly Speed", Min = 20, Max = 250, Default = flags.flyspeed, Step = 5, Flag = "flyspeed", Callback = function(v) flags.flyspeed = v end })

-- Automation
local auto = section:CreateTab("Automation")
auto:CreateToggle({ Name = "Auto Loot (drawers/items)", Default = false, Flag = "autoloot",  Callback = function(v) flags.autoLoot = v end })
auto:CreateToggle({ Name = "Auto Open Doors",           Default = false, Flag = "autodoors", Callback = function(v) flags.autoDoors = v end })
auto:CreateButton({ Name = "Loot This Room Now",   Callback = function() local n = firePrompts(false); Window:Notify({ Title = "Auto Loot", Description = "Fired " .. n .. " prompts.", Duration = 3 }) end })
auto:CreateButton({ Name = "Reveal Padlock Code",  Callback = revealPadlock })
auto:CreateToggle({ Name = "Anti-AFK", Default = false, Flag = "antiafk", Callback = function(v) setAntiAFK(v) end })

-- Misc
local misc = section:CreateTab("Misc")
misc:CreateParagraph({ Title = "About", Content = "DOORS is server-authoritative. Client features (ESP, visuals, movement, fly, noclip, prompt automation) are reliable; server-validated ones are experimental." })
misc:CreateToggle({ Name = "Infinite Health (experimental)", Default = false, Flag = "godmode", Callback = function(v) flags.godmode = v end })
misc:CreateDropdown({ Name = "UI Theme", Options = { "Dark", "Light", "Midnight", "Rose", "Ocean", "Forest" }, Default = "Dark", Callback = function(t) Window:SetTheme(t) end })
misc:CreateButton({ Name = "Reset Character", Callback = function() local h = getHum(); if h then h.Health = 0 end end })
misc:CreateButton({ Name = "Rejoin Server",   Callback = function() pcall(function() TPS:Teleport(game.PlaceId, LP) end) end })
misc:CreateButton({ Name = "Unload Ez Hub",   Callback = function()
	stopFly(); setNotifier(false); setAntiAFK(false); clearAllHL()
	pcall(function() espFolder:Destroy() end)
	Window:Destroy()
end })

-- Config tab
local configTab = section:CreateTab("Configuration")
configTab:CreateConfigSection()

Window:Notify({ Title = "Ez Hub - DOORS", Description = "Loaded. Press Right-Shift to toggle.", Duration = 4 })

return Window
