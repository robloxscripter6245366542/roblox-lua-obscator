-- ================================================================
--   NPC Chat Control  ·  by void.
--   Select any player → type message → fire ChatEvent as them
-- ================================================================
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local RunSvc  = game:GetService("RunService")
local TweenSvc= game:GetService("TweenService")
local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui")

local ChatEvent = RS:WaitForChild("ChatEvent", 10)
if not ChatEvent then warn("[NPC Chat] ChatEvent not found"); return end

-- ── helpers ──────────────────────────────────────────────────────
local function tw(i,t,p) TweenSvc:Create(i,t,p):Play() end
local TF = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TM = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function mkF(par,sz,pos,col,tr)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos;f.BackgroundColor3=col
    f.BackgroundTransparency=tr or 0;f.BorderSizePixel=0;f.Parent=par;return f
end
local function mkL(par,txt,fsz,col,pos,sz,xa,bold)
    local l=Instance.new("TextLabel");l.Text=txt
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fsz;l.TextColor3=col;l.BackgroundTransparency=1
    l.Position=pos;l.Size=sz;l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd
    l.BorderSizePixel=0;l.Parent=par;return l
end
local function mkB(par,sz,pos,col,tr)
    local b=Instance.new("TextButton");b.Text="";b.Size=sz;b.Position=pos
    b.BackgroundColor3=col;b.BackgroundTransparency=tr or 0
    b.BorderSizePixel=0;b.AutoButtonColor=false;b.Parent=par;return b
end
local function corner(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p end
local function stroke(p,col,tr,th)
    local s=Instance.new("UIStroke");s.Color=col;s.Transparency=tr or 0.7;s.Thickness=th or 1;s.Parent=p
end

-- ── find nearby NPCs in workspace.map.text_generation.list ───────
local function getNPCs()
    local map = workspace:FindFirstChild("map")
    if not map then return {} end
    local tg = map:FindFirstChild("text_generation")
    if not tg then return {} end
    local list = tg:FindFirstChild("list")
    if not list then return {} end
    local out = {}
    for _, v in pairs(list:GetChildren()) do
        if v:IsA("Model") then table.insert(out, v) end
    end
    return out
end

local function sendToNPCs(displayName, message)
    local npcs = getNPCs()
    if #npcs == 0 then return false, "No NPCs found in workspace.map.text_generation.list" end
    local clean = message:gsub("%s+", " "):match("^%s*(.-)%s*$")
    if clean == "" then return false, "Empty message" end
    for _, npc in ipairs(npcs) do
        ChatEvent:FireServer(npc.Name, clean, displayName)
    end
    return true, "Sent to "..#npcs.." NPC(s)"
end

-- ── GUI ──────────────────────────────────────────────────────────
local old = PGui:FindFirstChild("NPCChatControl"); if old then old:Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name="NPCChatControl";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.Parent=PGui

local W,H = 480,380
local WIN = mkF(SG, UDim2.new(0,W,0,H), UDim2.new(0.5,-W/2,0.5,-H/2),
    Color3.fromRGB(9,11,22), 0.18)
corner(WIN,14); stroke(WIN, Color3.fromRGB(64,156,255), 0.48, 1.5)
WIN.ClipsDescendants=true

-- top accent line
mkF(WIN, UDim2.new(1,0,0,2), UDim2.new(0,0,0,0), Color3.fromRGB(64,156,255), 0.78)

-- ── titlebar ────────────────────────────────────────────────────
local TB = mkF(WIN, UDim2.new(1,0,0,44), UDim2.new(0,0,0,0), Color3.fromRGB(9,11,22), 1)
mkF(TB, UDim2.new(1,0,0,1), UDim2.new(0,0,1,-1), Color3.new(1,1,1), 0.90)

local titleDot = mkF(TB, UDim2.new(0,10,0,10), UDim2.new(0,12,0.5,-5), Color3.fromRGB(64,156,255), 0)
corner(titleDot,5)
mkL(TB,"NPC Chat Control",14,Color3.fromRGB(228,240,255),UDim2.new(0,28,0,0),UDim2.new(1,-110,1,0),Enum.TextXAlignment.Left,true)
mkL(TB,"by void.",10,Color3.fromRGB(68,105,162),UDim2.new(0,28,0,0),UDim2.new(0,200,1,0),Enum.TextXAlignment.Left,false)

-- close button
local closeBtn = mkB(TB, UDim2.new(0,13,0,13), UDim2.new(1,-28,0.5,-6), Color3.fromRGB(255,88,88), 0.10)
corner(closeBtn, 7)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,TF,{BackgroundTransparency=0}) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,TF,{BackgroundTransparency=0.10}) end)
closeBtn.MouseButton1Click:Connect(function()
    tw(WIN,TM,{BackgroundTransparency=1,Size=UDim2.new(0,W*0.92,0,H*0.92)})
    task.delay(0.24,function() SG:Destroy() end)
end)

-- minimize
local minBtn = mkB(TB, UDim2.new(0,13,0,13), UDim2.new(1,-46,0.5,-6), Color3.fromRGB(255,190,55), 0.10)
corner(minBtn,7)
local minimized=false
minBtn.MouseEnter:Connect(function() tw(minBtn,TF,{BackgroundTransparency=0}) end)
minBtn.MouseLeave:Connect(function() tw(minBtn,TF,{BackgroundTransparency=0.10}) end)
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    tw(WIN,TM,{Size=minimized and UDim2.new(0,W,0,44) or UDim2.new(0,W,0,H)})
end)

-- drag
do
    local drag,dragStart,startPos=false,nil,nil
    TB.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true;dragStart=inp.Position;startPos=WIN.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    local last=nil
    TB.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then last=inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp==last and drag and dragStart then
            local d=inp.Position-dragStart
            WIN.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- ── layout: two columns ─────────────────────────────────────────
-- Left: player list  |  Right: send panel
local BODY = mkF(WIN, UDim2.new(1,0,1,-44), UDim2.new(0,0,0,44), Color3.fromRGB(9,11,22), 1)

-- ── LEFT: player list ───────────────────────────────────────────
local LEFT = mkF(BODY, UDim2.new(0,190,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(9,11,22), 1)
mkF(LEFT, UDim2.new(0,1,1,0), UDim2.new(1,-1,0,0), Color3.new(1,1,1), 0.90) -- divider

mkL(LEFT,"PLAYERS",9,Color3.fromRGB(68,105,162),UDim2.new(0,10,0,6),UDim2.new(1,-10,0,16),Enum.TextXAlignment.Left,true)
mkF(LEFT, UDim2.new(1,-10,0,1), UDim2.new(0,5,0,22), Color3.fromRGB(64,156,255), 0.70)

local plScroll = Instance.new("ScrollingFrame")
plScroll.Size=UDim2.new(1,0,1,-28);plScroll.Position=UDim2.new(0,0,0,28)
plScroll.BackgroundTransparency=1;plScroll.BorderSizePixel=0
plScroll.ScrollBarThickness=3;plScroll.ScrollBarImageColor3=Color3.fromRGB(64,156,255)
plScroll.CanvasSize=UDim2.new(0,0,0,0);plScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
plScroll.ScrollingDirection=Enum.ScrollingDirection.Y;plScroll.Parent=LEFT
local plLL=Instance.new("UIListLayout",plScroll);plLL.Padding=UDim.new(0,3)
local plPad=Instance.new("UIPadding",plScroll)
plPad.PaddingLeft=UDim.new(0,6);plPad.PaddingRight=UDim.new(0,6);plPad.PaddingTop=UDim.new(0,4)

-- ── RIGHT: send panel ───────────────────────────────────────────
local RIGHT = mkF(BODY, UDim2.new(1,-190,1,0), UDim2.new(0,190,0,0), Color3.fromRGB(9,11,22), 1)

-- Selected player display
local selBg = mkF(RIGHT, UDim2.new(1,-16,0,40), UDim2.new(0,8,0,10),
    Color3.fromRGB(14,19,36), 0.44)
corner(selBg,10);stroke(selBg,Color3.new(1,1,1),0.84,1)
mkF(selBg,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.78) -- shimmer
mkL(selBg,"Target:",9,Color3.fromRGB(68,105,162),UDim2.new(0,10,0,4),UDim2.new(0,50,0,14),Enum.TextXAlignment.Left,true)
local selLabel = mkL(selBg,"— none selected —",12,Color3.fromRGB(140,178,235),
    UDim2.new(0,10,0,20),UDim2.new(1,-16,0,16),Enum.TextXAlignment.Left,false)

-- NPC status display
local npcBg = mkF(RIGHT, UDim2.new(1,-16,0,32), UDim2.new(0,8,0,58),
    Color3.fromRGB(14,19,36), 0.52)
corner(npcBg,8);stroke(npcBg,Color3.new(1,1,1),0.88,1)
mkL(npcBg,"NPCs:",9,Color3.fromRGB(68,105,162),UDim2.new(0,10,0,0),UDim2.new(0,40,1,0),Enum.TextXAlignment.Left,true)
local npcLabel = mkL(npcBg,"scanning…",11,Color3.fromRGB(140,178,235),
    UDim2.new(0,52,0,0),UDim2.new(1,-58,1,0),Enum.TextXAlignment.Left,false)

-- Message label
mkL(RIGHT,"MESSAGE",9,Color3.fromRGB(68,105,162),UDim2.new(0,10,0,100),UDim2.new(1,-10,0,14),Enum.TextXAlignment.Left,true)
mkF(RIGHT, UDim2.new(1,-16,0,1), UDim2.new(0,8,0,114), Color3.fromRGB(64,156,255), 0.70)

-- Message textbox
local msgBg = mkF(RIGHT, UDim2.new(1,-16,1,-196), UDim2.new(0,8,0,122),
    Color3.fromRGB(14,19,36), 0.40)
corner(msgBg,10);stroke(msgBg,Color3.new(1,1,1),0.84,1)
local msgPad = Instance.new("UIPadding",msgBg)
msgPad.PaddingLeft=UDim.new(0,10);msgPad.PaddingRight=UDim.new(0,8)
msgPad.PaddingTop=UDim.new(0,7);msgPad.PaddingBottom=UDim.new(0,7)
local msgBox = Instance.new("TextBox")
msgBox.PlaceholderText="Type message here…";msgBox.Text=""
msgBox.Font=Enum.Font.Gotham;msgBox.TextSize=13
msgBox.TextColor3=Color3.fromRGB(228,240,255);msgBox.PlaceholderColor3=Color3.fromRGB(68,105,162)
msgBox.BackgroundTransparency=1;msgBox.BorderSizePixel=0
msgBox.Size=UDim2.new(1,0,1,0);msgBox.ClearTextOnFocus=false
msgBox.MultiLine=true;msgBox.TextXAlignment=Enum.TextXAlignment.Left
msgBox.TextYAlignment=Enum.TextYAlignment.Top;msgBox.TextWrapped=true
msgBox.Parent=msgBg
msgBox.Focused:Connect(function() tw(msgBg,TF,{BackgroundTransparency=0.26}) end)
msgBox.FocusLost:Connect(function()  tw(msgBg,TM,{BackgroundTransparency=0.40}) end)

-- Status label
local statusL = mkL(RIGHT,"",10,Color3.fromRGB(68,105,162),
    UDim2.new(0,10,1,-68),UDim2.new(1,-16,0,26),Enum.TextXAlignment.Left,false)
statusL.TextWrapped=true

-- Send button
local sendBg = mkF(RIGHT, UDim2.new(1,-16,0,36), UDim2.new(0,8,1,-46),
    Color3.fromRGB(64,156,255), 0.12)
corner(sendBg,10);stroke(sendBg,Color3.fromRGB(64,156,255),0.46,1.5)
mkF(sendBg,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.78)
local sendLbl = mkL(sendBg,"▶  Send",13,Color3.fromRGB(228,240,255),
    UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local sendHit = mkB(sendBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(64,156,255),1)
sendHit.MouseEnter:Connect(function() tw(sendBg,TF,{BackgroundTransparency=0}) end)
sendHit.MouseLeave:Connect(function() tw(sendBg,TM,{BackgroundTransparency=0.12}) end)

-- clear button
local clrBg = mkF(RIGHT, UDim2.new(0,60,0,28), UDim2.new(1,-68,1,-38),
    Color3.fromRGB(14,19,36), 0.52)
corner(clrBg,8);stroke(clrBg,Color3.new(1,1,1),0.84,1)
mkL(clrBg,"Clear",11,Color3.fromRGB(140,178,235),UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,false)
local clrHit = mkB(clrBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(14,19,36),1)
clrHit.MouseEnter:Connect(function() tw(clrBg,TF,{BackgroundTransparency=0.28}) end)
clrHit.MouseLeave:Connect(function() tw(clrBg,TM,{BackgroundTransparency=0.52}) end)
clrHit.MouseButton1Click:Connect(function()
    msgBox.Text="";statusL.Text="";statusL.TextColor3=Color3.fromRGB(68,105,162)
end)

-- ── player list management ──────────────────────────────────────
local selectedPlayer = nil
local playerBtns = {}

local AC = Color3.fromRGB(64,156,255)

local function setStatus(msg, ok)
    statusL.Text = msg
    statusL.TextColor3 = ok and Color3.fromRGB(68,224,114) or Color3.fromRGB(255,88,88)
    task.delay(3, function()
        if statusL.Text==msg then
            statusL.Text=""
            statusL.TextColor3=Color3.fromRGB(68,105,162)
        end
    end)
end

local function selectPlayer(plr)
    selectedPlayer = plr
    if plr then
        selLabel.Text = plr.DisplayName.." (@"..plr.Name..")"
        selLabel.TextColor3 = Color3.fromRGB(228,240,255)
    else
        selLabel.Text = "— none selected —"
        selLabel.TextColor3 = Color3.fromRGB(140,178,235)
    end
    -- update button highlights
    for p, row in pairs(playerBtns) do
        local active = (p == plr)
        tw(row.bg, TF, {BackgroundTransparency=active and 0.18 or 0.70})
        row.name.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
        row.name.TextColor3 = active and Color3.fromRGB(228,240,255) or Color3.fromRGB(140,178,235)
        row.dot.BackgroundTransparency = active and 0 or 0.80
    end
end

local function buildPlayerRow(plr)
    if playerBtns[plr] then return end
    local row = mkF(plScroll, UDim2.new(1,0,0,40), UDim2.new(0,0,0,0),
        Color3.fromRGB(14,19,36), 0.70)
    row.ClipsDescendants=true;corner(row,9)
    stroke(row,Color3.new(1,1,1),0.88,1)

    -- accent left bar
    local bar = mkF(row,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),AC,0);corner(bar,2)

    -- avatar dot (first letter)
    local av = mkF(row,UDim2.new(0,26,0,26),UDim2.new(0,8,0.5,-13),AC,0.54);corner(av,13)
    mkL(av,plr.Name:sub(1,1):upper(),13,Color3.fromRGB(228,240,255),
        UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)

    -- name + display name
    local nameL = mkL(row,plr.DisplayName,12,Color3.fromRGB(140,178,235),
        UDim2.new(0,40,0,5),UDim2.new(1,-46,0,14),Enum.TextXAlignment.Left,false)
    local subL  = mkL(row,"@"..plr.Name,9,Color3.fromRGB(68,105,162),
        UDim2.new(0,40,0,22),UDim2.new(1,-46,0,13),Enum.TextXAlignment.Left,false)

    -- right accent dot
    local dot = mkF(row,UDim2.new(0,6,0,6),UDim2.new(1,-12,0.5,-3),AC,0.80);corner(dot,3)

    -- hit
    local hit = mkB(row,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(14,19,36),1)
    hit.MouseEnter:Connect(function()
        if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.50}) end
    end)
    hit.MouseLeave:Connect(function()
        if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.70}) end
    end)
    hit.MouseButton1Click:Connect(function()
        if selectedPlayer==plr then selectPlayer(nil) else selectPlayer(plr) end
    end)

    playerBtns[plr]={bg=row,name=nameL,sub=subL,dot=dot,bar=bar}

    -- mark active if already selected
    if selectedPlayer==plr then
        row.BackgroundTransparency=0.18;nameL.Font=Enum.Font.GothamBold
        nameL.TextColor3=Color3.fromRGB(228,240,255);dot.BackgroundTransparency=0
    end
end

local function removePlayerRow(plr)
    if playerBtns[plr] then
        playerBtns[plr].bg:Destroy()
        playerBtns[plr]=nil
    end
    if selectedPlayer==plr then selectPlayer(nil) end
end

-- populate existing players
for _,plr in ipairs(Players:GetPlayers()) do buildPlayerRow(plr) end

Players.PlayerAdded:Connect(function(plr)   buildPlayerRow(plr) end)
Players.PlayerRemoving:Connect(function(plr) removePlayerRow(plr) end)

-- ── NPC scanner (updates every second) ──────────────────────────
task.spawn(function()
    while SG.Parent do
        local npcs = getNPCs()
        if #npcs==0 then
            npcLabel.Text="none found in map.text_generation.list"
            npcLabel.TextColor3=Color3.fromRGB(255,88,88)
        else
            local names={}
            for _,n in ipairs(npcs) do table.insert(names,n.Name) end
            npcLabel.Text=#npcs.." found: "..table.concat(names,", ")
            npcLabel.TextColor3=Color3.fromRGB(68,224,114)
        end
        task.wait(1)
    end
end)

-- ── send logic ───────────────────────────────────────────────────
local function doSend()
    if not selectedPlayer then
        setStatus("Select a player first!",false);return
    end
    local msg = msgBox.Text:match("^%s*(.-)%s*$")
    if msg=="" then
        setStatus("Type a message first!",false);return
    end
    local ok,info = sendToNPCs(selectedPlayer.DisplayName, msg)
    setStatus(info, ok)
    if ok then
        sendLbl.Text="✓  Sent"
        tw(sendBg,TF,{BackgroundTransparency=0})
        task.delay(1.6,function()
            sendLbl.Text="▶  Send"
            tw(sendBg,TM,{BackgroundTransparency=0.12})
        end)
    end
end

sendHit.MouseButton1Click:Connect(doSend)
-- Enter key sends
msgBox.FocusLost:Connect(function(enter) if enter then doSend() end end)

-- ── open animation ───────────────────────────────────────────────
WIN.Size=UDim2.new(0,W*0.88,0,H*0.88)
WIN.BackgroundTransparency=1
tw(WIN,TweenInfo.new(0.46,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,W,0,H),BackgroundTransparency=0.18
})
