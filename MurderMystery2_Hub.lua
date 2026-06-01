-- ════════════════════════════════════════════════════════════════════════
--  Murder Mystery 2  |  Script Hub  |  v2.0  |  Delta Full Power
--  Uses: hookmetamethod, newcclosure, getnamecallmethod, Drawing, gethui
-- ════════════════════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local TW          = game:GetService("TweenService")
local RunService  = game:GetService("RunService")
local StarterGui  = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")
local Camera      = WS.CurrentCamera
local LP          = Players.LocalPlayer
local PGui        = LP:WaitForChild("PlayerGui")

local function notify(t,m,d)
    pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4}) end)
end

-- ── Character helpers ─────────────────────────────────────────────────────
local function getChar() return LP.Character end
local function getHRP()  local c=getChar();return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar();return c and c:FindFirstChildOfClass("Humanoid") end

-- ── Delta capability flags ────────────────────────────────────────────────
local HAS_HOOK    = (hookmetamethod ~= nil)
local HAS_DRAWING = (Drawing ~= nil)
local HAS_GETHUI  = (gethui ~= nil)
local HAS_CLIP    = (setclipboard ~= nil)

-- ── Colors ────────────────────────────────────────────────────────────────
local C = {
    BG     = Color3.fromRGB(22,  22,  32),
    SIDE   = Color3.fromRGB(16,  16,  24),
    PANEL  = Color3.fromRGB(30,  30,  42),
    CARD   = Color3.fromRGB(38,  38,  52),
    BLUE   = Color3.fromRGB(64,  156, 255),
    BLUE2  = Color3.fromRGB(100, 180, 255),
    WHITE  = Color3.fromRGB(255, 255, 255),
    OFFWH  = Color3.fromRGB(200, 205, 220),
    MUTED  = Color3.fromRGB(110, 115, 140),
    GREEN  = Color3.fromRGB(52,  211, 153),
    RED    = Color3.fromRGB(239, 68,  68),
    YELLOW = Color3.fromRGB(255, 200, 50),
    ORANGE = Color3.fromRGB(251, 146, 60),
    PURPLE = Color3.fromRGB(167, 105, 255),
    GRAY   = Color3.fromRGB(55,  58,  75),
    BORDER = Color3.fromRGB(46,  48,  66),
    DARK   = Color3.fromRGB(12,  12,  18),
}

local ROLE_COLOR = {
    Murderer = C.RED,
    Sheriff  = C.YELLOW,
    Innocent = C.GREEN,
    Unknown  = C.MUTED,
}

-- Drawing color helpers
local function rgb(c3) return {c3.R, c3.G, c3.B} end
local function toDrawColor(c3) return Color3.new(c3.R, c3.G, c3.B) end

-- ════════════════════════════════════════════════════════════════════════
--  ROLE ENGINE  (tool-check + __namecall sniff)
-- ════════════════════════════════════════════════════════════════════════
local snoopedRoles = {}   -- [player] = "Murderer"/"Sheriff" — from remote sniff
local myRole = "Unknown"

local function getRole(player)
    if snoopedRoles[player] then return snoopedRoles[player] end
    local char = player.Character
    local bp   = player:FindFirstChildOfClass("Backpack")
    local function has(root,...)
        if not root then return false end
        for _,n in ipairs({...}) do if root:FindFirstChild(n) then return true end end
        return false
    end
    if char and has(char,"Knife","MM2Knife","ClassicKnife","Knife_SE","VIPKnife") then return "Murderer" end
    if bp   and has(bp,  "Knife","MM2Knife","ClassicKnife","Knife_SE","VIPKnife") then return "Murderer" end
    if char and has(char,"Sheriff Gun","Revolver","ClassicRevolver","Gun","SheriffGun") then return "Sheriff" end
    if bp   and has(bp,  "Sheriff Gun","Revolver","ClassicRevolver","Gun","SheriffGun") then return "Sheriff" end
    if char then return "Innocent" end
    return "Unknown"
end

-- ── __namecall hook (Delta full power) ────────────────────────────────────
local remoteLog = {}      -- recent remote traffic for the log tab
local MAX_LOG = 60

local function logRemote(name, args)
    if #remoteLog >= MAX_LOG then table.remove(remoteLog, 1) end
    local argStr = ""
    for i,v in ipairs(args) do
        argStr = argStr .. (i>1 and ", " or "") .. tostring(v):sub(1,24)
    end
    table.insert(remoteLog, {name=name, args=argStr, time=os.clock()})
end

local function sniffArgs(args)
    for _,v in ipairs(args) do
        if type(v)=="string" then
            local low=v:lower()
            if low=="murderer" then return "Murderer"
            elseif low=="sheriff" then return "Sheriff"
            elseif low=="innocent" then return "Innocent"
            end
        end
        if type(v)=="number" then
            if v==1 then return "Murderer"
            elseif v==2 then return "Sheriff"
            elseif v==3 then return "Innocent"
            end
        end
    end
end

local _namecallHook = nil
if HAS_HOOK then
    pcall(function()
        local _old; _old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if m == "FireServer" or m == "InvokeServer" then
                local ok, isRE = pcall(function() return self:IsA("RemoteEvent") end)
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if ok and (isRE or isRF) then
                    local name = tostring(self.Name)
                    local args = {...}
                    logRemote(name, args)
                    -- sniff role assignments
                    local low = name:lower()
                    if low:find("role") or low:find("assign") or low:find("setplayer") or low:find("character") then
                        local r = sniffArgs(args)
                        if r then snoopedRoles[LP] = r; myRole = r end
                    end
                end
            elseif m == "FireClient" or m == "InvokeClient" then
                local ok, isRE = pcall(function() return self:IsA("RemoteEvent") end)
                local ok2, isRF = pcall(function() return self:IsA("RemoteFunction") end)
                if (ok and isRE) or (ok2 and isRF) then
                    local name = tostring(self.Name)
                    local args = {...}
                    logRemote("[S→C] "..name, args)
                    local low = name:lower()
                    if low:find("role") or low:find("assign") or low:find("murder") or low:find("sheriff") then
                        -- server telling us roles
                        for i,v in ipairs(args) do
                            if type(v)=="Instance" then
                                pcall(function()
                                    if v:IsA("Player") then
                                        local r = sniffArgs({args[i+1], args[i+2]})
                                        if r then snoopedRoles[v] = r end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            return _old(self, ...)
        end))
        _namecallHook = true
    end)
end

-- ════════════════════════════════════════════════════════════════════════
--  ESP  (Drawing-based when available, Highlight fallback)
-- ════════════════════════════════════════════════════════════════════════
local espEnabled  = false
local espBoxes    = false   -- 2D box ESP via Drawing
local espNames    = true    -- name labels
local espDist     = true    -- distance
local espTracers  = false   -- tracers to feet

local espHL = {}            -- Highlight instances (fallback)
local drawObjects = {}      -- [player] = {box={}, name, dist, tracer}

local coinEspEnabled = false
local coinHL = {}

local function worldToViewport(pos)
    local vp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vp.X, vp.Y), onScreen, vp.Z
end

local function removeDrawESP(p)
    if drawObjects[p] then
        for _, obj in pairs(drawObjects[p]) do
            pcall(function() obj.Visible = false; obj:Remove() end)
        end
        drawObjects[p] = nil
    end
end

local function removeHL(p)
    if espHL[p] then pcall(function() espHL[p]:Destroy() end); espHL[p]=nil end
end

local function removeAllESP(p)
    removeDrawESP(p); removeHL(p)
end

local function applyHL(p)
    if not espEnabled or p==LP then return end
    local char = p.Character; if not char then return end
    removeHL(p)
    local hl = Instance.new("Highlight")
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    local col = ROLE_COLOR[getRole(p)]
    hl.FillColor = col; hl.OutlineColor = col
    hl.Adornee = char; hl.Parent = char
    espHL[p] = hl
end

local function initDrawESP(p)
    if not HAS_DRAWING then return end
    removeDrawESP(p)
    local d = {}
    -- box (4 lines)
    d.box = {}
    for i=1,4 do
        local l = Drawing.new("Line")
        l.Thickness = 1.5; l.Visible = false
        d.box[i] = l
    end
    -- name
    d.name = Drawing.new("Text")
    d.name.Size = 13; d.name.Center = true
    d.name.Outline = true; d.name.Visible = false
    d.name.Font = Drawing.Fonts.UI
    -- dist
    d.dist = Drawing.new("Text")
    d.dist.Size = 11; d.dist.Center = true
    d.dist.Outline = true; d.dist.Visible = false
    d.dist.Font = Drawing.Fonts.UI
    -- tracer
    d.tracer = Drawing.new("Line")
    d.tracer.Thickness = 1; d.tracer.Visible = false
    drawObjects[p] = d
end

local function updateDrawESP()
    if not HAS_DRAWING then return end
    local vsx = Camera.ViewportSize.X
    local vsy = Camera.ViewportSize.Y

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then
            if drawObjects[p] then removeDrawESP(p) end
        else
            local d = drawObjects[p]
            if not d then
                if espEnabled then initDrawESP(p); d = drawObjects[p] end
            end
            if not d then
                -- skip this player
            else
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if not espEnabled or not char or not hrp then
                for _,obj in pairs(d) do
                    if type(obj)=="table" then for _,l in ipairs(obj) do pcall(function() l.Visible=false end) end
                    else pcall(function() obj.Visible=false end) end
                end
            else
                local role  = getRole(p)
                local col   = ROLE_COLOR[role]
                local drawCol = toDrawColor(col)

                local rootPos = hrp.Position
                local screen, onScreen, depth = worldToViewport(rootPos)
                local headPos = head and head.Position or (rootPos + Vector3.new(0,2.5,0))
                local topScreen = worldToViewport(headPos + Vector3.new(0,0.6,0))
                local botScreen = worldToViewport(rootPos - Vector3.new(0,3,0))

                local dist = math.floor((getHRP() and (getHRP().Position - rootPos).Magnitude) or 0)

                if onScreen and depth > 0 then
                    -- box
                    if espBoxes then
                        local h = math.abs(topScreen.Y - botScreen.Y)
                        local w = h * 0.45
                        local cx = screen.X
                        local top_y = topScreen.Y
                        local bot_y = botScreen.Y
                        local x1,y1 = cx-w, top_y
                        local x2,y2 = cx+w, bot_y
                        local pts = {
                            {Vector2.new(x1,y1), Vector2.new(x2,y1)},
                            {Vector2.new(x2,y1), Vector2.new(x2,y2)},
                            {Vector2.new(x2,y2), Vector2.new(x1,y2)},
                            {Vector2.new(x1,y2), Vector2.new(x1,y1)},
                        }
                        for i,ln in ipairs(d.box) do
                            ln.From  = pts[i][1]; ln.To = pts[i][2]
                            ln.Color = drawCol;   ln.Visible = true
                        end
                    else
                        for _,l in ipairs(d.box) do l.Visible=false end
                    end
                    -- name
                    if espNames then
                        d.name.Text     = p.Name .. (role~="Unknown" and " ["..role:sub(1,3).."]" or "")
                        d.name.Color    = drawCol
                        d.name.Position = Vector2.new(screen.X, topScreen.Y - 16)
                        d.name.Visible  = true
                    else d.name.Visible = false end
                    -- dist
                    if espDist then
                        d.dist.Text     = dist.."m"
                        d.dist.Color    = Color3.new(1,1,1)
                        d.dist.Position = Vector2.new(screen.X, botScreen.Y + 2)
                        d.dist.Visible  = true
                    else d.dist.Visible = false end
                    -- tracer
                    if espTracers then
                        d.tracer.From   = Vector2.new(vsx/2, vsy)
                        d.tracer.To     = Vector2.new(screen.X, botScreen.Y)
                        d.tracer.Color  = drawCol
                        d.tracer.Visible = true
                    else d.tracer.Visible = false end
                else
                    for _,obj in pairs(d) do
                        if type(obj)=="table" then for _,l in ipairs(obj) do pcall(function() l.Visible=false end) end
                        else pcall(function() obj.Visible=false end) end
                    end
                end
            end
            end -- if not d else
        end
    end
end

local function refreshHL()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP then
            if espEnabled and not HAS_DRAWING then applyHL(p) else removeHL(p) end
        end
    end
end

local function refreshCoinESP()
    for _,hl in pairs(coinHL) do pcall(function() hl:Destroy() end) end; coinHL={}
    if not coinEspEnabled then return end
    for _,obj in ipairs(WS:GetDescendants()) do
        local n=obj.Name:lower()
        if obj:IsA("BasePart") and (n=="coin" or n=="goldcoin" or n=="mm2coin") then
            local hl=Instance.new("Highlight")
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillColor=C.YELLOW; hl.OutlineColor=Color3.fromRGB(255,230,80)
            hl.FillTransparency=0.25; hl.Adornee=obj; hl.Parent=obj
            coinHL[obj]=hl
        end
    end
end

-- ESP heartbeat
RunService.RenderStepped:Connect(function()
    if espEnabled and HAS_DRAWING then
        updateDrawESP()
    end
end)

-- ════════════════════════════════════════════════════════════════════════
--  COIN FARM
-- ════════════════════════════════════════════════════════════════════════
local coinFarm=false
task.spawn(function()
    while true do
        task.wait(0.08)
        if coinFarm then
            local hrp=getHRP()
            if hrp then
                local best,bd=nil,math.huge
                for _,obj in ipairs(WS:GetDescendants()) do
                    local n=obj.Name:lower()
                    if obj:IsA("BasePart") and (n=="coin" or n=="goldcoin" or n=="mm2coin") then
                        local d=(hrp.Position-obj.Position).Magnitude
                        if d<bd then bd=d;best=obj end
                    end
                end
                if best and bd>3 then hrp.CFrame=CFrame.new(best.Position+Vector3.new(0,3.5,0)) end
            else task.wait(1) end
        else task.wait(0.5) end
    end
end)

-- ════════════════════════════════════════════════════════════════════════
--  MOVEMENT
-- ════════════════════════════════════════════════════════════════════════
local speedVal=16; local jumpVal=50
local function applyMove()
    local h=getHum(); if h then h.WalkSpeed=speedVal; h.JumpPower=jumpVal end
end

-- ── Fly ────────────────────────────────────────────────────────────────────
local flyEnabled=false; local flyConn=nil
local function toggleFly(v)
    flyEnabled=v
    if flyConn then flyConn:Disconnect();flyConn=nil end
    local hrp=getHRP()
    if not v then
        if hrp then
            local bv=hrp:FindFirstChild("_FlyBV"); if bv then bv:Destroy() end
            local bg=hrp:FindFirstChild("_FlyBG"); if bg then bg:Destroy() end
        end
        local h=getHum(); if h then pcall(function()h:ChangeState(Enum.HumanoidStateType.GettingUp)end) end
        return
    end
    if not hrp then return end
    local bv=Instance.new("BodyVelocity",hrp); bv.Name="_FlyBV"
    bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.P=9e3
    local bg=Instance.new("BodyGyro",hrp); bg.Name="_FlyBG"
    bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=9e3
    local h=getHum(); if h then pcall(function()h:ChangeState(Enum.HumanoidStateType.Flying)end) end
    flyConn=RunService.Heartbeat:Connect(function()
        local h2=getHRP()
        local bv2=h2 and h2:FindFirstChild("_FlyBV")
        local bg2=h2 and h2:FindFirstChild("_FlyBG")
        if not bv2 or not bg2 then flyConn:Disconnect();flyConn=nil;return end
        local cam=WS.CurrentCamera; local dir=Vector3.zero
        local spd=UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 100 or 50
        if UIS:IsKeyDown(Enum.KeyCode.W)     then dir=dir+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S)     then dir=dir-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A)     then dir=dir-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)     then dir=dir+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.E)     then dir=dir-Vector3.new(0,1,0) end
        bv2.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero
        bg2.CFrame=cam.CFrame
    end)
end

-- ── Noclip ─────────────────────────────────────────────────────────────────
local noclipEnabled=false; local noclipConn=nil
local function toggleNoclip(v)
    noclipEnabled=v
    if noclipConn then noclipConn:Disconnect();noclipConn=nil end
    if not v then
        local c=getChar()
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
        return
    end
    noclipConn=RunService.Stepped:Connect(function()
        local c=getChar()
        if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    end)
end

-- ── Inf jump ───────────────────────────────────────────────────────────────
local infJump=false
UIS.JumpRequest:Connect(function()
    if infJump then local h=getHum(); if h then pcall(function()h:ChangeState(Enum.HumanoidStateType.Jumping)end) end end
end)

-- ── Anti-AFK ──────────────────────────────────────────────────────────────
local antiAFK=false; local afkT=0
RunService.Heartbeat:Connect(function()
    if antiAFK then afkT=afkT+1; if afkT>=3600 then afkT=0;pcall(function()VirtualUser:CaptureController()end) end end
end)

-- ── Kill Aura ─────────────────────────────────────────────────────────────
local killAura=false; local kaConn=nil
local function toggleKillAura(v)
    killAura=v
    if kaConn then kaConn:Disconnect();kaConn=nil end
    if not v then return end
    kaConn=RunService.Heartbeat:Connect(function()
        if getRole(LP)~="Murderer" then return end
        local hrp=getHRP(); if not hrp then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then
                local pHRP=p.Character:FindFirstChild("HumanoidRootPart")
                if pHRP and (hrp.Position-pHRP.Position).Magnitude<7 then
                    for _,r in ipairs(RS:GetDescendants()) do
                        if r:IsA("RemoteEvent") then
                            local n=r.Name:lower()
                            if n:find("kill") or n:find("stab") or n:find("hit") or n:find("attack") then
                                pcall(function()r:FireServer(p)end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5); applyMove()
    if flyEnabled then task.wait(0.5); toggleFly(true) end
    -- re-init drawing ESP for existing players
    if espEnabled and HAS_DRAWING then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP then initDrawESP(p) end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            if HAS_DRAWING then initDrawESP(p) else applyHL(p) end
        end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    removeAllESP(p); snoopedRoles[p]=nil
end)

-- ════════════════════════════════════════════════════════════════════════
--  GUI  ──  Rayfield-style
-- ════════════════════════════════════════════════════════════════════════
local old=PGui:FindFirstChild("__MM2Hub__"); if old then old:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="__MM2Hub__"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.DisplayOrder=999
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local guiParent=PGui
pcall(function() if HAS_GETHUI then guiParent=gethui() end end)
SG.Parent=guiParent

local TI15=TweenInfo.new(0.15,Enum.EasingStyle.Quad)
local TI25=TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)

local function corner(p,r) local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c end
local function stroke(p,col,t) local s=Instance.new("UIStroke",p);s.Color=col;s.Thickness=t or 1;return s end
local function pad(p,x,y) local d=Instance.new("UIPadding",p);d.PaddingLeft=UDim.new(0,x);d.PaddingRight=UDim.new(0,x);d.PaddingTop=UDim.new(0,y or x);d.PaddingBottom=UDim.new(0,y or x) end

-- Main window
local WIN=Instance.new("Frame",SG)
WIN.Name="Win"; WIN.Size=UDim2.new(0,590,0,450)
WIN.Position=UDim2.new(0.5,-295,0.5,-225)
WIN.BackgroundColor3=C.BG; WIN.BorderSizePixel=0; WIN.Active=true
WIN.ClipsDescendants=true
corner(WIN,14); stroke(WIN,C.BORDER,1.5)

-- shadow
local sh=Instance.new("ImageLabel",WIN)
sh.Size=UDim2.new(1,50,1,50); sh.Position=UDim2.new(0,-25,0,-25)
sh.BackgroundTransparency=1; sh.ZIndex=0
sh.Image="rbxassetid://5554236805"
sh.ImageColor3=C.DARK; sh.ImageTransparency=0.5
sh.ScaleType=Enum.ScaleType.Slice; sh.SliceCenter=Rect.new(23,23,277,277)

-- Top bar
local TOP=Instance.new("Frame",WIN)
TOP.Size=UDim2.new(1,0,0,54); TOP.BackgroundColor3=C.SIDE; TOP.BorderSizePixel=0

local accentBar=Instance.new("Frame",TOP)
accentBar.Size=UDim2.new(0,4,0,30); accentBar.Position=UDim2.new(0,16,0.5,-15)
accentBar.BackgroundColor3=C.BLUE; accentBar.BorderSizePixel=0; corner(accentBar,2)

local titleLbl=Instance.new("TextLabel",TOP)
titleLbl.Size=UDim2.new(0,230,0,20); titleLbl.Position=UDim2.new(0,28,0.5,-18)
titleLbl.BackgroundTransparency=1; titleLbl.Text="Murder Mystery 2"
titleLbl.TextColor3=C.WHITE; titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextSize=15
titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local subLbl=Instance.new("TextLabel",TOP)
subLbl.Size=UDim2.new(0,280,0,13); subLbl.Position=UDim2.new(0,28,0.5,5)
subLbl.BackgroundTransparency=1
subLbl.Text="v2.0  •  Delta  •  "..(HAS_HOOK and "Hook ✓" or "Hook ✗").."  "..(HAS_DRAWING and "Draw ✓" or "Draw ✗")
subLbl.TextColor3=C.MUTED; subLbl.Font=Enum.Font.Gotham; subLbl.TextSize=10
subLbl.TextXAlignment=Enum.TextXAlignment.Left

-- role pill
local rolePill=Instance.new("Frame",TOP)
rolePill.Size=UDim2.new(0,108,0,28); rolePill.Position=UDim2.new(1,-182,0.5,-14)
rolePill.BackgroundColor3=C.PANEL; rolePill.BorderSizePixel=0; corner(rolePill,8); stroke(rolePill,C.BORDER,1)
local roleDot=Instance.new("Frame",rolePill)
roleDot.Size=UDim2.new(0,8,0,8); roleDot.Position=UDim2.new(0,9,0.5,-4)
roleDot.BackgroundColor3=C.MUTED; roleDot.BorderSizePixel=0; corner(roleDot,4)
local roleTxt=Instance.new("TextLabel",rolePill)
roleTxt.Size=UDim2.new(1,-24,1,0); roleTxt.Position=UDim2.new(0,22,0,0)
roleTxt.BackgroundTransparency=1; roleTxt.Text="Unknown"
roleTxt.TextColor3=C.MUTED; roleTxt.Font=Enum.Font.GothamBold; roleTxt.TextSize=10
roleTxt.TextXAlignment=Enum.TextXAlignment.Left

local minBtn=Instance.new("TextButton",TOP)
minBtn.Size=UDim2.new(0,26,0,26); minBtn.Position=UDim2.new(1,-66,0.5,-13)
minBtn.BackgroundColor3=C.CARD; minBtn.Text="─"; minBtn.TextColor3=C.MUTED
minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=12; minBtn.BorderSizePixel=0; corner(minBtn,7)

local closeBtn=Instance.new("TextButton",TOP)
closeBtn.Size=UDim2.new(0,26,0,26); closeBtn.Position=UDim2.new(1,-34,0.5,-13)
closeBtn.BackgroundColor3=Color3.fromRGB(200,55,55); closeBtn.Text="✕"
closeBtn.TextColor3=C.WHITE; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12
closeBtn.BorderSizePixel=0; corner(closeBtn,7)
closeBtn.MouseButton1Click:Connect(function()
    -- clean up Drawing objects
    for _,p in ipairs(Players:GetPlayers()) do removeAllESP(p) end
    SG:Destroy()
end)

-- drag
local _d,_dx,_dy,_wx,_wy=false,0,0,0,0
TOP.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        _d=true;_dx=i.Position.X;_dy=i.Position.Y;_wx=WIN.AbsolutePosition.X;_wy=WIN.AbsolutePosition.Y
    end
end)
UIS.InputChanged:Connect(function(i)
    if not _d then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        WIN.Position=UDim2.new(0,_wx+i.Position.X-_dx,0,_wy+i.Position.Y-_dy)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then _d=false end
end)

-- Body
local MAIN=Instance.new("Frame",WIN)
MAIN.Size=UDim2.new(1,0,1,-54); MAIN.Position=UDim2.new(0,0,0,54)
MAIN.BackgroundTransparency=1; MAIN.BorderSizePixel=0

local _mini=false
minBtn.MouseButton1Click:Connect(function()
    _mini=not _mini; MAIN.Visible=not _mini
    TW:Create(WIN,TI25,{Size=_mini and UDim2.new(0,590,0,54) or UDim2.new(0,590,0,450)}):Play()
end)

-- Sidebar
local SIDE=Instance.new("Frame",MAIN)
SIDE.Size=UDim2.new(0,148,1,0); SIDE.BackgroundColor3=C.SIDE; SIDE.BorderSizePixel=0
local sideList=Instance.new("UIListLayout",SIDE)
sideList.Padding=UDim.new(0,3); sideList.SortOrder=Enum.SortOrder.LayoutOrder
pad(SIDE,8,10)

-- Content
local CONT=Instance.new("ScrollingFrame",MAIN)
CONT.Size=UDim2.new(1,-148,1,0); CONT.Position=UDim2.new(0,148,0,0)
CONT.BackgroundColor3=C.BG; CONT.BorderSizePixel=0
CONT.ScrollBarThickness=3; CONT.ScrollBarImageColor3=C.BLUE
CONT.CanvasSize=UDim2.new(0,0,0,0); CONT.AutomaticCanvasSize=Enum.AutomaticSize.Y
local contList=Instance.new("UIListLayout",CONT)
contList.Padding=UDim.new(0,8); contList.SortOrder=Enum.SortOrder.LayoutOrder
pad(CONT,14,14)

-- ── Tab factory ────────────────────────────────────────────────────────────
local tabs={}; local activeTab=nil
local function makeTab(name,icon)
    local btn=Instance.new("TextButton",SIDE)
    btn.LayoutOrder=#tabs+1; btn.Size=UDim2.new(1,0,0,38)
    btn.BackgroundColor3=C.SIDE; btn.Text=""; btn.BorderSizePixel=0; corner(btn,8)
    local icL=Instance.new("TextLabel",btn)
    icL.Size=UDim2.new(0,22,1,0); icL.Position=UDim2.new(0,10,0,0)
    icL.BackgroundTransparency=1; icL.Text=icon; icL.TextColor3=C.MUTED
    icL.Font=Enum.Font.Gotham; icL.TextSize=15
    local nmL=Instance.new("TextLabel",btn)
    nmL.Size=UDim2.new(1,-38,1,0); nmL.Position=UDim2.new(0,36,0,0)
    nmL.BackgroundTransparency=1; nmL.Text=name; nmL.TextColor3=C.MUTED
    nmL.Font=Enum.Font.GothamBold; nmL.TextSize=12; nmL.TextXAlignment=Enum.TextXAlignment.Left
    local bar=Instance.new("Frame",btn)
    bar.Size=UDim2.new(0,3,0,22); bar.Position=UDim2.new(0,0,0.5,-11)
    bar.BackgroundColor3=C.BLUE; bar.BorderSizePixel=0; corner(bar,2); bar.Visible=false
    local frame=Instance.new("Frame",CONT)
    frame.Size=UDim2.new(1,0,0,0); frame.AutomaticSize=Enum.AutomaticSize.Y
    frame.BackgroundTransparency=1; frame.BorderSizePixel=0; frame.Visible=false
    local fl=Instance.new("UIListLayout",frame)
    fl.Padding=UDim.new(0,8); fl.SortOrder=Enum.SortOrder.LayoutOrder
    tabs[name]={btn=btn,frame=frame,bar=bar,icL=icL,nmL=nmL}
    btn.MouseButton1Click:Connect(function()
        if activeTab then
            local a=tabs[activeTab]
            a.frame.Visible=false; a.bar.Visible=false
            TW:Create(a.btn,TI15,{BackgroundColor3=C.SIDE}):Play()
            TW:Create(a.icL,TI15,{TextColor3=C.MUTED}):Play()
            TW:Create(a.nmL,TI15,{TextColor3=C.MUTED}):Play()
        end
        activeTab=name; frame.Visible=true; bar.Visible=true
        TW:Create(btn,TI15,{BackgroundColor3=C.CARD}):Play()
        TW:Create(icL,TI15,{TextColor3=C.BLUE}):Play()
        TW:Create(nmL,TI15,{TextColor3=C.WHITE}):Play()
        CONT.CanvasPosition=Vector2.new(0,0)
    end)
    return frame
end

local tabESP    = makeTab("ESP",     "👁")
local tabFarmT  = makeTab("Farm",    "🪙")
local tabPlayer = makeTab("Player",  "👤")
local tabRoles  = makeTab("Roles",   "🔪")
local tabRemote = makeTab("Remotes", "📡")
local tabMisc   = makeTab("Misc",    "⚙")

-- ── UI helpers ─────────────────────────────────────────────────────────────
local function secLabel(parent,txt)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,20); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.Text=txt:upper(); l.TextColor3=C.BLUE
    l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Left
end

local function makeToggle(parent,title,sub,default,cb)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,54); f.BackgroundColor3=C.PANEL; f.BorderSizePixel=0; corner(f,8); stroke(f,C.BORDER,1)
    local tL=Instance.new("TextLabel",f); tL.Size=UDim2.new(1,-72,0,18); tL.Position=UDim2.new(0,14,0,9)
    tL.BackgroundTransparency=1; tL.Text=title; tL.TextColor3=C.WHITE
    tL.Font=Enum.Font.GothamBold; tL.TextSize=13; tL.TextXAlignment=Enum.TextXAlignment.Left
    local sL=Instance.new("TextLabel",f); sL.Size=UDim2.new(1,-72,0,14); sL.Position=UDim2.new(0,14,0,30)
    sL.BackgroundTransparency=1; sL.Text=sub; sL.TextColor3=C.MUTED
    sL.Font=Enum.Font.Gotham; sL.TextSize=10; sL.TextXAlignment=Enum.TextXAlignment.Left
    local st=default
    local pill=Instance.new("TextButton",f); pill.Size=UDim2.new(0,46,0,26); pill.Position=UDim2.new(1,-60,0.5,-13)
    pill.BackgroundColor3=st and C.BLUE or C.GRAY; pill.Text=""; pill.BorderSizePixel=0; corner(pill,13)
    local kn=Instance.new("Frame",pill); kn.Size=UDim2.new(0,20,0,20)
    kn.Position=st and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
    kn.BackgroundColor3=C.WHITE; kn.BorderSizePixel=0; corner(kn,10)
    pill.MouseButton1Click:Connect(function()
        st=not st
        TW:Create(pill,TI15,{BackgroundColor3=st and C.BLUE or C.GRAY}):Play()
        TW:Create(kn,TI15,{Position=st and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)}):Play()
        cb(st)
    end)
    return f
end

local function makeBtn(parent,txt,col,cb)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,0,0,40); b.BackgroundColor3=col or C.BLUE
    b.Text=txt; b.TextColor3=C.WHITE; b.Font=Enum.Font.GothamBold; b.TextSize=13
    b.BorderSizePixel=0; corner(b,8)
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function() TW:Create(b,TI15,{BackgroundColor3=C.BLUE2}):Play() end)
    b.MouseLeave:Connect(function() TW:Create(b,TI15,{BackgroundColor3=col or C.BLUE}):Play() end)
    return b
end

local function makeSlider(parent,title,min_v,max_v,default,cb)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,62); f.BackgroundColor3=C.PANEL; f.BorderSizePixel=0; corner(f,8); stroke(f,C.BORDER,1)
    local tL=Instance.new("TextLabel",f); tL.Size=UDim2.new(0.6,0,0,18); tL.Position=UDim2.new(0,14,0,8)
    tL.BackgroundTransparency=1; tL.Text=title; tL.TextColor3=C.WHITE
    tL.Font=Enum.Font.GothamBold; tL.TextSize=12; tL.TextXAlignment=Enum.TextXAlignment.Left
    local vLbl=Instance.new("TextLabel",f); vLbl.Size=UDim2.new(0.35,-14,0,18); vLbl.Position=UDim2.new(0.65,0,0,8)
    vLbl.BackgroundTransparency=1; vLbl.Text=tostring(default); vLbl.TextColor3=C.BLUE
    vLbl.Font=Enum.Font.GothamBold; vLbl.TextSize=12; vLbl.TextXAlignment=Enum.TextXAlignment.Right
    local track=Instance.new("Frame",f); track.Size=UDim2.new(1,-28,0,6); track.Position=UDim2.new(0,14,0,38)
    track.BackgroundColor3=C.GRAY; track.BorderSizePixel=0; corner(track,3)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((default-min_v)/(max_v-min_v),0,1,0)
    fill.BackgroundColor3=C.BLUE; fill.BorderSizePixel=0; corner(fill,3)
    local knob=Instance.new("TextButton",track)
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new((default-min_v)/(max_v-min_v),-8,0.5,-8)
    knob.BackgroundColor3=C.WHITE; knob.Text=""; knob.BorderSizePixel=0; corner(knob,8)
    local sliding=false
    knob.MouseButton1Down:Connect(function() sliding=true end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end end)
    UIS.InputChanged:Connect(function(i)
        if not sliding or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(min_v+rel*(max_v-min_v))
        fill.Size=UDim2.new(rel,0,1,0); knob.Position=UDim2.new(rel,-8,0.5,-8)
        vLbl.Text=tostring(val); cb(val)
    end)
    return f
end

-- ════════════════════════════════════════════════════════════════════════
--  TAB: ESP
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabESP,"Player ESP  "..(HAS_DRAWING and "(Drawing)" or "(Highlight)"))
makeToggle(tabESP,"Enable ESP","See all players with role color through walls",false,function(v)
    espEnabled=v
    if v then
        if HAS_DRAWING then
            for _,p in ipairs(Players:GetPlayers()) do if p~=LP then initDrawESP(p) end end
        else refreshHL() end
        notify("ESP","Player ESP ON",2)
    else
        for _,p in ipairs(Players:GetPlayers()) do removeAllESP(p) end
    end
end)

if HAS_DRAWING then
    makeToggle(tabESP,"Boxes","2D bounding boxes around players",false,function(v) espBoxes=v end)
    makeToggle(tabESP,"Names","Player name + role above head",true,function(v) espNames=v end)
    makeToggle(tabESP,"Distance","Show meters to each player",true,function(v) espDist=v end)
    makeToggle(tabESP,"Tracers","Line from bottom-center to each player",false,function(v) espTracers=v end)
end

secLabel(tabESP,"Coin ESP")
makeToggle(tabESP,"Coin Highlight","Gold highlight on every coin on the map",false,function(v)
    coinEspEnabled=v; refreshCoinESP()
end)
makeBtn(tabESP,"Refresh Coin ESP",C.CARD,function() refreshCoinESP(); notify("ESP","Coin ESP refreshed",2) end)

secLabel(tabESP,"Legend")
local function legendRow(parent,lbl,col)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(1,0,0,32)
    f.BackgroundColor3=C.PANEL; f.BorderSizePixel=0; corner(f,8); stroke(f,C.BORDER,1)
    local dot=Instance.new("Frame",f); dot.Size=UDim2.new(0,10,0,10); dot.Position=UDim2.new(0,12,0.5,-5)
    dot.BackgroundColor3=col; dot.BorderSizePixel=0; corner(dot,5)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-32,1,0); l.Position=UDim2.new(0,30,0,0)
    l.BackgroundTransparency=1; l.Text=lbl; l.TextColor3=C.OFFWH
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left
end
legendRow(tabESP,"Murderer  —  Red",    C.RED)
legendRow(tabESP,"Sheriff   —  Yellow", C.YELLOW)
legendRow(tabESP,"Innocent  —  Green",  C.GREEN)

-- ════════════════════════════════════════════════════════════════════════
--  TAB: FARM
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabFarmT,"Coin Farm")
makeToggle(tabFarmT,"Auto Collect Coins","Teleports to nearest coin continuously",false,function(v)
    coinFarm=v; if v then notify("Farm","Auto farm ON",2) end
end)
makeBtn(tabFarmT,"Collect ALL Now",C.BLUE,function()
    local hrp=getHRP(); if not hrp then notify("Error","No character",2);return end
    local count=0
    for _,obj in ipairs(WS:GetDescendants()) do
        local n=obj.Name:lower()
        if obj:IsA("BasePart") and (n=="coin" or n=="goldcoin" or n=="mm2coin") then
            hrp.CFrame=CFrame.new(obj.Position+Vector3.new(0,3.5,0)); task.wait(0.04); count=count+1
        end
    end
    notify("Farm","Collected "..count.." coins!",3)
end)
secLabel(tabFarmT,"Auto Grab")
makeToggle(tabFarmT,"Auto Pick Up Gun","TP to any dropped sheriff gun",false,function(v)
    if not v then return end
    game.DescendantAdded:Connect(function(obj)
        if not v or not obj:IsA("Tool") then return end
        local n=obj.Name:lower()
        if n:find("gun") or n:find("sheriff") or n:find("revolver") then
            if obj.Parent~=LP and obj.Parent~=LP:FindFirstChildOfClass("Backpack") then
                task.wait(0.1)
                local hrp=getHRP(); local h=obj:FindFirstChild("Handle")
                if hrp and h then hrp.CFrame=CFrame.new(h.Position+Vector3.new(0,3,0)) end
            end
        end
    end)
end)

-- ════════════════════════════════════════════════════════════════════════
--  TAB: PLAYER
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabPlayer,"Movement")
makeSlider(tabPlayer,"Walk Speed",16,120,16,function(v) speedVal=v;applyMove() end)
makeSlider(tabPlayer,"Jump Power",50,250,50,function(v) jumpVal=v;applyMove() end)
secLabel(tabPlayer,"Abilities")
makeToggle(tabPlayer,"Fly","WASD+Space+E • Shift = fast",false,function(v)
    toggleFly(v); if v then notify("Fly","ON — WASD+Space+E, Shift=fast",3) end
end)
makeToggle(tabPlayer,"Noclip","Walk through all objects",false,toggleNoclip)
makeToggle(tabPlayer,"Infinite Jump","Jump infinitely in mid-air",false,function(v) infJump=v end)
makeToggle(tabPlayer,"Anti-AFK","Prevents auto-kick",false,function(v) antiAFK=v end)
secLabel(tabPlayer,"Actions")
makeBtn(tabPlayer,"Reset Character",Color3.fromRGB(130,28,28),function()
    local h=getHum(); if h then pcall(function() h.Health=0 end) end
end)
makeBtn(tabPlayer,"TP to Spawn",C.CARD,function()
    local hrp=getHRP(); if not hrp then return end
    for _,obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            hrp.CFrame=CFrame.new(obj.Position+Vector3.new(0,4,0))
            notify("TP","Teleported to spawn",2);return
        end
    end
    notify("TP","No spawn found",2)
end)

-- ════════════════════════════════════════════════════════════════════════
--  TAB: ROLES
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabRoles,"Live Roles")

local rolesFrame=Instance.new("ScrollingFrame",tabRoles)
rolesFrame.Size=UDim2.new(1,0,0,200); rolesFrame.BackgroundColor3=C.PANEL
rolesFrame.BorderSizePixel=0; rolesFrame.ScrollBarThickness=3
rolesFrame.ScrollBarImageColor3=C.BLUE; rolesFrame.CanvasSize=UDim2.new(0,0,0,0)
rolesFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
corner(rolesFrame,8); stroke(rolesFrame,C.BORDER,1)
local rolesLayout=Instance.new("UIListLayout",rolesFrame)
rolesLayout.Padding=UDim.new(0,2); rolesLayout.SortOrder=Enum.SortOrder.LayoutOrder
pad(rolesFrame,7,6)

local playerRows={}
local function rebuildRoles()
    for _,row in pairs(playerRows) do row:Destroy() end; playerRows={}
    for _,p in ipairs(Players:GetPlayers()) do
        local role=getRole(p); local col=ROLE_COLOR[role]
        local row=Instance.new("Frame",rolesFrame)
        row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=C.CARD; row.BorderSizePixel=0; corner(row,7)
        local dot=Instance.new("Frame",row); dot.Size=UDim2.new(0,9,0,9); dot.Position=UDim2.new(0,9,0.5,-4.5)
        dot.BackgroundColor3=col; dot.BorderSizePixel=0; corner(dot,5)
        local nL=Instance.new("TextLabel",row); nL.Size=UDim2.new(0.44,0,1,0); nL.Position=UDim2.new(0,24,0,0)
        nL.BackgroundTransparency=1; nL.Text=p.Name; nL.Font=Enum.Font.GothamBold; nL.TextSize=11
        nL.TextColor3=p==LP and C.BLUE or C.WHITE; nL.TextXAlignment=Enum.TextXAlignment.Left
        local rL=Instance.new("TextLabel",row); rL.Size=UDim2.new(0.3,0,1,0); rL.Position=UDim2.new(0.46,0,0,0)
        rL.BackgroundTransparency=1; rL.Text=role; rL.Font=Enum.Font.GothamBold; rL.TextSize=10
        rL.TextColor3=col; rL.TextXAlignment=Enum.TextXAlignment.Left
        if p~=LP then
            local tpBtn=Instance.new("TextButton",row)
            tpBtn.Size=UDim2.new(0,28,0,22); tpBtn.Position=UDim2.new(1,-32,0.5,-11)
            tpBtn.BackgroundColor3=C.BLUE; tpBtn.Text="TP"; tpBtn.TextColor3=C.WHITE
            tpBtn.Font=Enum.Font.GothamBold; tpBtn.TextSize=9; tpBtn.BorderSizePixel=0; corner(tpBtn,5)
            tpBtn.MouseButton1Click:Connect(function()
                local hrp=getHRP(); local pHRP=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and pHRP then hrp.CFrame=pHRP.CFrame*CFrame.new(0,0,-3); notify("TP",p.Name,2) end
            end)
        end
        playerRows[p.Name]=row
    end
end
rebuildRoles()

makeBtn(tabRoles,"Refresh",C.CARD,function() rebuildRoles();notify("Roles","Updated",2) end)
makeBtn(tabRoles,"Clear Snooped Roles",C.GRAY,function()
    for k in pairs(snoopedRoles) do snoopedRoles[k]=nil end
    notify("Roles","Snooped roles cleared",2)
end)
secLabel(tabRoles,"Kill Aura")
makeToggle(tabRoles,"Kill Aura","Auto-fires kill remotes nearby (Murderer only)",false,function(v)
    toggleKillAura(v); if v then notify("Aura","Kill Aura ON",3) end
end)

-- ════════════════════════════════════════════════════════════════════════
--  TAB: REMOTES  (Delta __namecall log)
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabRemote,"Remote Spy  "..(HAS_HOOK and "(Live via hookmetamethod)" or "(hookmetamethod unavailable)"))

if not HAS_HOOK then
    local warn=Instance.new("Frame",tabRemote); warn.Size=UDim2.new(1,0,0,44)
    warn.BackgroundColor3=Color3.fromRGB(80,30,10); warn.BorderSizePixel=0; corner(warn,8)
    local wL=Instance.new("TextLabel",warn); wL.Size=UDim2.new(1,-16,1,0); wL.Position=UDim2.new(0,10,0,0)
    wL.BackgroundTransparency=1; wL.Text="hookmetamethod not available in this executor"
    wL.TextColor3=C.ORANGE; wL.Font=Enum.Font.GothamBold; wL.TextSize=11
    wL.TextXAlignment=Enum.TextXAlignment.Left; wL.TextWrapped=true
end

local logScroll=Instance.new("ScrollingFrame",tabRemote)
logScroll.Size=UDim2.new(1,0,0,240); logScroll.BackgroundColor3=C.DARK
logScroll.BorderSizePixel=0; logScroll.ScrollBarThickness=3
logScroll.ScrollBarImageColor3=C.BLUE; logScroll.CanvasSize=UDim2.new(0,0,0,0)
logScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
corner(logScroll,8); stroke(logScroll,C.BORDER,1)
local logList=Instance.new("UIListLayout",logScroll)
logList.Padding=UDim.new(0,1); logList.SortOrder=Enum.SortOrder.LayoutOrder
pad(logScroll,6,4)

local logRows={}
local function refreshLog()
    for _,r in ipairs(logRows) do r:Destroy() end; logRows={}
    for i=#remoteLog,math.max(1,#remoteLog-30),-1 do
        local entry=remoteLog[i]
        local row=Instance.new("Frame",logScroll)
        row.Size=UDim2.new(1,0,0,0); row.AutomaticSize=Enum.AutomaticSize.Y
        row.BackgroundColor3=i%2==0 and C.PANEL or C.CARD; row.BorderSizePixel=0; corner(row,4)
        pad(row,6,3)
        local fl=Instance.new("UIListLayout",row); fl.SortOrder=Enum.SortOrder.LayoutOrder
        local nL=Instance.new("TextLabel",row); nL.Size=UDim2.new(1,0,0,14)
        nL.BackgroundTransparency=1; nL.Text=entry.name
        nL.TextColor3=C.BLUE; nL.Font=Enum.Font.GothamBold; nL.TextSize=10
        nL.TextXAlignment=Enum.TextXAlignment.Left
        if entry.args~="" then
            local aL=Instance.new("TextLabel",row); aL.Size=UDim2.new(1,0,0,12)
            aL.BackgroundTransparency=1; aL.Text=entry.args
            aL.TextColor3=C.MUTED; aL.Font=Enum.Font.Gotham; aL.TextSize=9
            aL.TextXAlignment=Enum.TextXAlignment.Left
        end
        table.insert(logRows,row)
    end
end

makeBtn(tabRemote,"Refresh Log",C.CARD,function() refreshLog() end)
makeBtn(tabRemote,"Clear Log",C.GRAY,function()
    for k in ipairs(remoteLog) do remoteLog[k]=nil end
    remoteLog={}; refreshLog()
end)

-- ════════════════════════════════════════════════════════════════════════
--  TAB: MISC
-- ════════════════════════════════════════════════════════════════════════
secLabel(tabMisc,"Delta Capabilities")

local capsCard=Instance.new("Frame",tabMisc)
capsCard.Size=UDim2.new(1,0,0,0); capsCard.AutomaticSize=Enum.AutomaticSize.Y
capsCard.BackgroundColor3=C.PANEL; capsCard.BorderSizePixel=0; corner(capsCard,8); stroke(capsCard,C.BORDER,1)
pad(capsCard,12,8)
local capsList=Instance.new("UIListLayout",capsCard); capsList.Padding=UDim.new(0,2); capsList.SortOrder=Enum.SortOrder.LayoutOrder

local function capRow(lbl,ok)
    local r=Instance.new("Frame",capsCard); r.Size=UDim2.new(1,0,0,20); r.BackgroundTransparency=1
    local l=Instance.new("TextLabel",r); l.Size=UDim2.new(0.75,0,1,0)
    l.BackgroundTransparency=1; l.Text=lbl; l.TextColor3=C.OFFWH
    l.Font=Enum.Font.GothamBold; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left
    local v=Instance.new("TextLabel",r); v.Size=UDim2.new(0.25,0,1,0); v.Position=UDim2.new(0.75,0,0,0)
    v.BackgroundTransparency=1; v.Text=ok and "✓ YES" or "✗ NO"
    v.TextColor3=ok and C.GREEN or C.RED; v.Font=Enum.Font.GothamBold; v.TextSize=11
    v.TextXAlignment=Enum.TextXAlignment.Right
end
capRow("hookmetamethod",    HAS_HOOK)
capRow("Drawing API",       HAS_DRAWING)
capRow("gethui()",          HAS_GETHUI)
capRow("setclipboard()",    HAS_CLIP)
capRow("newcclosure()",     newcclosure~=nil)
capRow("getnamecallmethod", getnamecallmethod~=nil)

secLabel(tabMisc,"Game Info")
local infoCard=Instance.new("Frame",tabMisc)
infoCard.Size=UDim2.new(1,0,0,0); infoCard.AutomaticSize=Enum.AutomaticSize.Y
infoCard.BackgroundColor3=C.PANEL; infoCard.BorderSizePixel=0; corner(infoCard,8); stroke(infoCard,C.BORDER,1)
pad(infoCard,12,8)
local ifl=Instance.new("UIListLayout",infoCard); ifl.Padding=UDim.new(0,3); ifl.SortOrder=Enum.SortOrder.LayoutOrder

local myRoleInfoLbl; local playerCountLbl
local function infoRow(parent,lbl,val,col)
    local row=Instance.new("Frame",parent); row.Size=UDim2.new(1,0,0,22); row.BackgroundTransparency=1
    local lL=Instance.new("TextLabel",row); lL.Size=UDim2.new(0.5,0,1,0)
    lL.BackgroundTransparency=1; lL.Text=lbl; lL.TextColor3=C.MUTED
    lL.Font=Enum.Font.Gotham; lL.TextSize=11; lL.TextXAlignment=Enum.TextXAlignment.Left
    local vL=Instance.new("TextLabel",row); vL.Size=UDim2.new(0.5,0,1,0); vL.Position=UDim2.new(0.5,0,0,0)
    vL.BackgroundTransparency=1; vL.Text=val; vL.TextColor3=col or C.WHITE
    vL.Font=Enum.Font.GothamBold; vL.TextSize=11; vL.TextXAlignment=Enum.TextXAlignment.Right
    return vL
end
infoRow(infoCard,"Game","Murder Mystery 2",C.WHITE)
infoRow(infoCard,"Place ID",tostring(game.PlaceId),C.BLUE)
playerCountLbl = infoRow(infoCard,"Players",tostring(#Players:GetPlayers()),C.WHITE)
myRoleInfoLbl  = infoRow(infoCard,"Your Role","Unknown",C.MUTED)

secLabel(tabMisc,"Server")
makeBtn(tabMisc,"Rejoin Server",C.CARD,function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,LP) end)
end)
makeBtn(tabMisc,"Copy Server ID",C.CARD,function()
    local id=game.JobId
    if HAS_CLIP then pcall(function() setclipboard(id) end) end
    notify("Copied",id:sub(1,16).."...",3)
end)

-- ── Periodic updates ───────────────────────────────────────────────────────
task.spawn(function()
    while SG and SG.Parent do
        task.wait(1.5)
        local role=getRole(LP); local col=ROLE_COLOR[role]
        roleDot.BackgroundColor3=col; roleTxt.Text=role; roleTxt.TextColor3=col
        if myRoleInfoLbl then myRoleInfoLbl.Text=role; myRoleInfoLbl.TextColor3=col end
        if playerCountLbl then playerCountLbl.Text=tostring(#Players:GetPlayers()) end
        if not HAS_DRAWING and espEnabled then refreshHL() end
    end
end)

-- ── Keybind ────────────────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.Insert or i.KeyCode==Enum.KeyCode.RightBracket then
        WIN.Visible=not WIN.Visible
    end
end)

tabs["ESP"].btn.MouseButton1Click:Fire()

local caps={}
if HAS_HOOK    then table.insert(caps,"Hook") end
if HAS_DRAWING then table.insert(caps,"Draw") end
if HAS_GETHUI  then table.insert(caps,"GUI+") end
notify("MM2 Hub v2.0","Delta: "..(#caps>0 and table.concat(caps," | ") or "basic mode").." | ] to toggle",5)
