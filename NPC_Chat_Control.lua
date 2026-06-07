-- ================================================================
--   NPC / Bubble Chat Control  ·  by void.
--   MODE A — TextChatService bubble chat (local player)
--   MODE B — ChatEvent NPC spoof (any player DisplayName)
-- ================================================================
local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local TCS       = game:GetService("TextChatService")
local ChatSvc   = game:GetService("Chat")
local LP        = Players.LocalPlayer
local PGui      = LP:WaitForChild("PlayerGui")

-- optional ChatEvent (NPC mode only — won't block load if absent)
local ChatEvent = RS:FindFirstChild("ChatEvent")
if not ChatEvent then
    -- try waiting briefly
    ChatEvent = RS:WaitForChild("ChatEvent", 3)
end

-- ── helpers ──────────────────────────────────────────────────────
local function tw(i,t,p) TweenSvc:Create(i,t,p):Play() end
local TF  = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TM  = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TSP = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local AC  = Color3.fromRGB(64,156,255)
local BG  = Color3.fromRGB(9,11,22)
local CD  = Color3.fromRGB(14,19,36)
local T1  = Color3.fromRGB(228,240,255)
local T2  = Color3.fromRGB(140,178,235)
local T3  = Color3.fromRGB(68,105,162)
local GRN = Color3.fromRGB(68,224,114)
local RED = Color3.fromRGB(255,88,88)

local function mkF(par,sz,pos,col,tr)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos;f.BackgroundColor3=col
    f.BackgroundTransparency=tr or 0;f.BorderSizePixel=0;f.Parent=par;return f
end
local function mkL(par,txt,fsz,col,pos,sz,xa,bold,wrap)
    local l=Instance.new("TextLabel");l.Text=txt
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fsz;l.TextColor3=col;l.BackgroundTransparency=1
    l.Position=pos;l.Size=sz;l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextWrapped=wrap or false;l.TextTruncate=Enum.TextTruncate.AtEnd
    l.BorderSizePixel=0;l.Parent=par;return l
end
local function mkB(par,sz,pos,col,tr)
    local b=Instance.new("TextButton");b.Text="";b.Size=sz;b.Position=pos
    b.BackgroundColor3=col;b.BackgroundTransparency=tr or 0
    b.BorderSizePixel=0;b.AutoButtonColor=false;b.Parent=par;return b
end
local function corner(p,r)
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p
end
local function stroke(p,col,tr,th)
    local s=Instance.new("UIStroke");s.Color=col;s.Transparency=tr or 0.7
    s.Thickness=th or 1;s.Parent=p
end
local function card(par,sz,pos)
    local f=mkF(par,sz,pos,CD,0.44);corner(f,10);f.ClipsDescendants=true
    stroke(f,Color3.new(1,1,1),0.82,1)
    mkF(f,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80) -- shimmer
    return f
end

-- ── NPC helpers ──────────────────────────────────────────────────
local function getNPCs()
    local map=workspace:FindFirstChild("map"); if not map then return {} end
    local tg=map:FindFirstChild("text_generation"); if not tg then return {} end
    local lst=tg:FindFirstChild("list"); if not lst then return {} end
    local out={}
    for _,v in pairs(lst:GetChildren()) do
        if v:IsA("Model") then table.insert(out,v) end
    end
    return out
end

-- ── send functions ────────────────────────────────────────────────
-- Mode A: TextChatService — local player says it (shows bubble chat)
local function sendTextChat(message)
    -- try RBXGeneral channel first, then any available channel
    local channels = TCS:FindFirstChild("TextChannels")
    if not channels then return false,"TextChannels not found" end
    local ch = channels:FindFirstChild("RBXGeneral")
        or channels:GetChildren()[1]
    if not ch or not ch:IsA("TextChannel") then return false,"No TextChannel found" end
    local ok,err = pcall(function() ch:SendAsync(message) end)
    if ok then return true,"Sent via TextChatService ✓"
    else  return false,"TextChat error: "..tostring(err):sub(1,60) end
end

-- Mode B: BubbleChat — fires Chat:Chat() on selected player's character
-- (shows bubble above head; works client-side in some executors)
local function sendBubble(character, message)
    if not character then return false,"No character" end
    local ok,err = pcall(function()
        ChatSvc:Chat(character, message, Enum.ChatColor.White)
    end)
    if ok then return true,"Bubble sent ✓"
    else  return false,"Bubble error: "..tostring(err):sub(1,60) end
end

-- Mode C: ChatEvent NPC spoof — fires as selected player's DisplayName
local function sendNPCSpoof(displayName, message)
    if not ChatEvent then return false,"ChatEvent not found in RS" end
    local npcs=getNPCs()
    if #npcs==0 then return false,"No NPCs in map.text_generation.list" end
    local clean=message:match("^%s*(.-)%s*$")
    if clean=="" then return false,"Empty message" end
    for _,npc in ipairs(npcs) do
        ChatEvent:FireServer(npc.Name, clean, displayName)
    end
    return true,"Sent to "..#npcs.." NPC(s) as \""..displayName.."\" ✓"
end

-- ── GUI ──────────────────────────────────────────────────────────
local old=PGui:FindFirstChild("NPCChatControl"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="NPCChatControl";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.Parent=PGui

local W,H=500,420
local WIN=mkF(SG,UDim2.new(0,W,0,H),UDim2.new(0.5,-W/2,0.5,-H/2),BG,0.18)
corner(WIN,14);WIN.ClipsDescendants=true
stroke(WIN,AC,0.46,1.5)
mkF(WIN,UDim2.new(1,0,0,2),UDim2.new(0,0,0,0),AC,0.80) -- top accent line

-- titlebar
local TB=mkF(WIN,UDim2.new(1,0,0,46),UDim2.new(0,0,0,0),BG,1)
mkF(TB,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)

local gemF=mkF(TB,UDim2.new(0,24,0,24),UDim2.new(0,12,0.5,-12),AC,0.16);corner(gemF,7)
stroke(gemF,AC,0.38,1)
mkL(gemF,"◆",12,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)

mkL(TB,"Chat Control",14,T1,UDim2.new(0,44,0,0),UDim2.new(0,120,1,0),Enum.TextXAlignment.Left,true)
mkL(TB,"bubble · npc · spoof",9,T3,UDim2.new(0,44,0,0),UDim2.new(0,200,1,0),Enum.TextXAlignment.Left,false)

local function winBtn(xOff,col,cb)
    local b=mkB(TB,UDim2.new(0,13,0,13),UDim2.new(1,xOff,0.5,-6),col,0.10);corner(b,7)
    b.MouseEnter:Connect(function() tw(b,TF,{BackgroundTransparency=0}) end)
    b.MouseLeave:Connect(function() tw(b,TF,{BackgroundTransparency=0.10}) end)
    b.MouseButton1Click:Connect(cb)
end
winBtn(-30,RED,function()
    tw(WIN,TweenInfo.new(0.20,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
        {BackgroundTransparency=1,Size=UDim2.new(0,W*0.90,0,H*0.90)})
    task.delay(0.22,function() SG:Destroy() end)
end)
local minimized=false
winBtn(-48,Color3.fromRGB(255,190,55),function()
    minimized=not minimized
    tw(WIN,TM,{Size=minimized and UDim2.new(0,W,0,46) or UDim2.new(0,W,0,H)})
end)

-- drag
do
    local drag,ds,sp=false,nil,nil;local last=nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true;ds=i.Position;sp=WIN.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    TB.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then last=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==last and drag and ds then
            local d=i.Position-ds
            WIN.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- BODY
local BODY=mkF(WIN,UDim2.new(1,0,1,-46),UDim2.new(0,0,0,46),BG,1)

-- ── LEFT: player list ────────────────────────────────────────────
local LEFT=mkF(BODY,UDim2.new(0,196,1,0),UDim2.new(0,0,0,0),BG,1)
mkF(LEFT,UDim2.new(0,1,1,0),UDim2.new(1,-1,0,0),Color3.new(1,1,1),0.90)

mkL(LEFT,"PLAYERS",9,T3,UDim2.new(0,10,0,7),UDim2.new(1,-10,0,14),Enum.TextXAlignment.Left,true)
mkF(LEFT,UDim2.new(1,-12,0,1),UDim2.new(0,6,0,22),AC,0.68)

local plScroll=Instance.new("ScrollingFrame")
plScroll.Size=UDim2.new(1,0,1,-26);plScroll.Position=UDim2.new(0,0,0,26)
plScroll.BackgroundTransparency=1;plScroll.BorderSizePixel=0
plScroll.ScrollBarThickness=3;plScroll.ScrollBarImageColor3=AC
plScroll.CanvasSize=UDim2.new(0,0,0,0);plScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
plScroll.ScrollingDirection=Enum.ScrollingDirection.Y;plScroll.Parent=LEFT
local plLL=Instance.new("UIListLayout",plScroll);plLL.Padding=UDim.new(0,3)
local plPad=Instance.new("UIPadding",plScroll)
plPad.PaddingLeft=UDim.new(0,6);plPad.PaddingRight=UDim.new(0,6);plPad.PaddingTop=UDim.new(0,5)

-- ── RIGHT: controls ───────────────────────────────────────────────
local RIGHT=mkF(BODY,UDim2.new(1,-196,1,0),UDim2.new(0,196,0,0),BG,1)

-- selected player row
local selCard=card(RIGHT,UDim2.new(1,-14,0,42),UDim2.new(0,7,0,8))
mkL(selCard,"SELECTED",8,T3,UDim2.new(0,10,0,4),UDim2.new(1,-10,0,11),Enum.TextXAlignment.Left,true)
local selL=mkL(selCard,"— tap a player —",12,T2,UDim2.new(0,10,0,17),UDim2.new(1,-12,0,16),Enum.TextXAlignment.Left,false)

-- mode toggle (3 pills: TextChat / Bubble / NPC Spoof)
mkL(RIGHT,"SEND MODE",8,T3,UDim2.new(0,10,0,58),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,70),AC,0.70)

local MODES={"TextChat","Bubble","NPC Spoof"}
local modeIdx=1
local modeBtns={}
local modeRow=mkF(RIGHT,UDim2.new(1,-14,0,30),UDim2.new(0,7,0,74),CD,0.50)
corner(modeRow,8);modeRow.ClipsDescendants=true
local mLL=Instance.new("UIListLayout",modeRow)
mLL.FillDirection=Enum.FillDirection.Horizontal;mLL.Padding=UDim.new(0,0)

for i,name in ipairs(MODES) do
    local mb=mkF(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new(0,0,0,0),AC,i==1 and 0.72 or 1)
    if i==1 then corner(mb,8)
    elseif i==#MODES then corner(mb,8) end
    local ml=mkL(mb,name,10,i==1 and T1 or T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,i==1)
    local mh=mkB(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new((i-1)/#MODES,0,0,0),AC,1)
    mh.ZIndex=2
    local ci=i
    mh.MouseButton1Click:Connect(function()
        modeIdx=ci
        for j,bt in ipairs(modeBtns) do
            tw(bt.bg,TF,{BackgroundTransparency=j==ci and 0.72 or 1})
            bt.lbl.Font=j==ci and Enum.Font.GothamBold or Enum.Font.Gotham
            bt.lbl.TextColor3=j==ci and T1 or T3
        end
    end)
    table.insert(modeBtns,{bg=mb,lbl=ml})
end

-- NPC status (shown only in NPC Spoof mode context)
local npcCard=card(RIGHT,UDim2.new(1,-14,0,30),UDim2.new(0,7,0,110))
mkL(npcCard,"NPCs:",8,T3,UDim2.new(0,8,0,0),UDim2.new(0,38,1,0),Enum.TextXAlignment.Left,true)
local npcL=mkL(npcCard,"scanning…",10,T2,UDim2.new(0,48,0,0),UDim2.new(1,-52,1,0),Enum.TextXAlignment.Left,false)

-- message box
mkL(RIGHT,"MESSAGE",8,T3,UDim2.new(0,10,0,148),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,160),AC,0.70)

local msgCard=mkF(RIGHT,UDim2.new(1,-14,1,-232),UDim2.new(0,7,0,166),CD,0.40)
corner(msgCard,10);msgCard.ClipsDescendants=true;stroke(msgCard,Color3.new(1,1,1),0.82,1)
local mPad=Instance.new("UIPadding",msgCard)
mPad.PaddingLeft=UDim.new(0,10);mPad.PaddingRight=UDim.new(0,8)
mPad.PaddingTop=UDim.new(0,7);mPad.PaddingBottom=UDim.new(0,7)
local msgBox=Instance.new("TextBox")
msgBox.PlaceholderText="Type message…";msgBox.Text=""
msgBox.Font=Enum.Font.Gotham;msgBox.TextSize=13
msgBox.TextColor3=T1;msgBox.PlaceholderColor3=T3
msgBox.BackgroundTransparency=1;msgBox.BorderSizePixel=0
msgBox.Size=UDim2.new(1,0,1,0);msgBox.ClearTextOnFocus=false
msgBox.MultiLine=true;msgBox.TextXAlignment=Enum.TextXAlignment.Left
msgBox.TextYAlignment=Enum.TextYAlignment.Top;msgBox.TextWrapped=true
msgBox.Parent=msgCard
msgBox.Focused:Connect(function()  tw(msgCard,TF,{BackgroundTransparency=0.24}) end)
msgBox.FocusLost:Connect(function() tw(msgCard,TM,{BackgroundTransparency=0.40}) end)

-- status label
local statusL=mkL(RIGHT,"",10,T3,UDim2.new(0,10,1,-66),UDim2.new(1,-14,0,20),Enum.TextXAlignment.Left,false,true)

-- button row
local clrCard=mkF(RIGHT,UDim2.new(0,62,0,34),UDim2.new(0,7,1,-42),CD,0.50)
corner(clrCard,9);stroke(clrCard,Color3.new(1,1,1),0.84,1)
mkL(clrCard,"⌫ Clear",11,T2,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,false)
local clrHit=mkB(clrCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
clrHit.MouseEnter:Connect(function() tw(clrCard,TF,{BackgroundTransparency=0.28}) end)
clrHit.MouseLeave:Connect(function() tw(clrCard,TM,{BackgroundTransparency=0.50}) end)
clrHit.MouseButton1Click:Connect(function()
    msgBox.Text="";statusL.Text="";statusL.TextColor3=T3
end)

local sendCard=mkF(RIGHT,UDim2.new(1,-80,0,34),UDim2.new(0,74,1,-42),AC,0.12)
corner(sendCard,9);stroke(sendCard,AC,0.44,1.5)
mkF(sendCard,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80)
local sendLbl=mkL(sendCard,"▶  Send",13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local sendHit=mkB(sendCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),AC,1)
sendHit.MouseEnter:Connect(function() tw(sendCard,TF,{BackgroundTransparency=0}) end)
sendHit.MouseLeave:Connect(function() tw(sendCard,TM,{BackgroundTransparency=0.12}) end)

-- ── player list ───────────────────────────────────────────────────
local selectedPlayer=nil
local playerBtns={}

local function setStatus(msg,ok)
    statusL.Text=msg;statusL.TextColor3=ok and GRN or RED
    task.delay(3.5,function()
        if statusL.Text==msg then statusL.Text="";statusL.TextColor3=T3 end
    end)
end

local function selectPlayer(plr)
    selectedPlayer=plr
    if plr then
        selL.Text=plr.DisplayName.." · @"..plr.Name
        selL.TextColor3=T1
    else
        selL.Text="— tap a player —";selL.TextColor3=T2
    end
    for p,r in pairs(playerBtns) do
        local on=(p==plr)
        tw(r.bg,TF,{BackgroundTransparency=on and 0.16 or 0.68})
        r.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        r.lbl.TextColor3=on and T1 or T2
        r.dot.BackgroundTransparency=on and 0 or 0.80
    end
end

local function buildRow(plr)
    if playerBtns[plr] then return end
    local row=mkF(plScroll,UDim2.new(1,0,0,42),UDim2.new(0,0,0,0),CD,0.68)
    row.ClipsDescendants=true;corner(row,9);stroke(row,Color3.new(1,1,1),0.86,1)
    -- left bar
    local bar=mkF(row,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),AC,0);corner(bar,2)
    -- avatar
    local av=mkF(row,UDim2.new(0,28,0,28),UDim2.new(0,8,0.5,-14),AC,0.52);corner(av,14)
    mkL(av,plr.Name:sub(1,1):upper(),13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
    -- labels
    local nl=mkL(row,plr.DisplayName,12,T2,UDim2.new(0,42,0,5),UDim2.new(1,-50,0,14),Enum.TextXAlignment.Left,false)
    mkL(row,"@"..plr.Name,9,T3,UDim2.new(0,42,0,22),UDim2.new(1,-50,0,13),Enum.TextXAlignment.Left,false)
    -- dot
    local dot=mkF(row,UDim2.new(0,6,0,6),UDim2.new(1,-12,0.5,-3),AC,0.80);corner(dot,3)
    -- hit
    local hit=mkB(row,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
    hit.MouseEnter:Connect(function() if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.48}) end end)
    hit.MouseLeave:Connect(function() if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.68}) end end)
    hit.MouseButton1Click:Connect(function()
        if selectedPlayer==plr then selectPlayer(nil) else selectPlayer(plr) end
    end)
    playerBtns[plr]={bg=row,lbl=nl,dot=dot,bar=bar}
    if selectedPlayer==plr then
        row.BackgroundTransparency=0.16;nl.Font=Enum.Font.GothamBold;nl.TextColor3=T1;dot.BackgroundTransparency=0
    end
end

local function removeRow(plr)
    if playerBtns[plr] then playerBtns[plr].bg:Destroy();playerBtns[plr]=nil end
    if selectedPlayer==plr then selectPlayer(nil) end
end

for _,p in ipairs(Players:GetPlayers()) do buildRow(p) end
Players.PlayerAdded:Connect(buildRow)
Players.PlayerRemoving:Connect(removeRow)

-- ── NPC scanner ───────────────────────────────────────────────────
task.spawn(function()
    while SG.Parent do
        local npcs=getNPCs()
        if #npcs==0 then
            npcL.Text="none found";npcL.TextColor3=RED
        else
            local ns={}; for _,n in ipairs(npcs) do table.insert(ns,n.Name) end
            npcL.Text=#npcs.." — "..table.concat(ns,", ");npcL.TextColor3=GRN
        end
        task.wait(1)
    end
end)

-- ── send logic ────────────────────────────────────────────────────
local function doSend()
    local msg=msgBox.Text:match("^%s*(.-)%s*$")
    if msg=="" then setStatus("Type a message first.",false);return end

    if modeIdx==1 then
        -- TextChatService: sends as local player (bubble chat above your head)
        local ok,info=sendTextChat(msg)
        setStatus(info,ok)

    elseif modeIdx==2 then
        -- Bubble: Chat:Chat() on selected player's character
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local char=selectedPlayer.Character
        if not char then setStatus("Player has no character.",false);return end
        local ok,info=sendBubble(char,msg)
        setStatus(info,ok)

    elseif modeIdx==3 then
        -- NPC Spoof: fire ChatEvent with selected player's DisplayName
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local ok,info=sendNPCSpoof(selectedPlayer.DisplayName, msg)
        setStatus(info,ok)
    end

    sendLbl.Text="✓  Sent";tw(sendCard,TF,{BackgroundTransparency=0})
    task.delay(1.6,function() sendLbl.Text="▶  Send";tw(sendCard,TM,{BackgroundTransparency=0.12}) end)
end

sendHit.MouseButton1Click:Connect(doSend)
msgBox.FocusLost:Connect(function(enter) if enter then doSend() end end)

-- ── open animation ────────────────────────────────────────────────
WIN.Size=UDim2.new(0,W*0.86,0,H*0.86);WIN.BackgroundTransparency=1
tw(WIN,TweenInfo.new(0.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,W,0,H),BackgroundTransparency=0.18
})
