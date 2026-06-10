-- ================================================================
--   Chat Control — FE Remote Spoof  (Mic Up & others)
--   Mode 1 "As Me"    — TextChatService, server-replicated ✓
--   Mode 2 "Spoof All"— fires ALL remotes, detects which respond
--   Mode 3 "Targeted" — fires only selected remote
--
--   Detection: listens for OnClientEvent callbacks, Player.Chatted,
--   TextChatService messages, and bubble-chat after each fire.
--   If any signal matches our msg/target, that remote is TRUSTED.
-- ================================================================
local RS         = game:GetService("ReplicatedStorage")
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local TweenSvc   = game:GetService("TweenService")
local TCS        = game:GetService("TextChatService")
local ChatSvc    = game:GetService("Chat")
local StarterGui = game:GetService("StarterGui")
local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

-- SS Bridge (SS_Executor.lua must be running as a server Script)
-- When available, "Server" mode executes Chat:Chat + FireAllClients server-side
-- which is 100% visible to all players with no FE limitations.
local Bridge = RS:FindFirstChild("SS_ExecBridge")
if not Bridge then
    -- wait briefly in case executor is still loading
    task.spawn(function()
        Bridge = RS:WaitForChild("SS_ExecBridge", 5)
    end)
end

local function callBridge(action, payload)
    if not Bridge then return nil end
    local ok, res = pcall(function()
        return Bridge:InvokeServer(action, payload)
    end)
    if ok then return res end
    return nil
end

-- ── Remote scanner ────────────────────────────────────────────────
local CHAT_KW     = {"chat","say","speak","voice","bubble","message","talk","text","mic","post","send","submit","input"}
local allRemotes  = {}
local chatRemotes = {}
local trustedRemotes = {}   -- [remote] = method string

local function scanAll()
    local found, seen = {}, {}
    local function check(v)
        if seen[v] then return end; seen[v]=true
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(found,v)
        end
    end
    -- scan every common container
    pcall(function() for _,v in ipairs(RS:GetDescendants()) do check(v) end end)
    pcall(function() for _,v in ipairs(workspace:GetDescendants()) do check(v) end end)
    pcall(function()
        for _,v in ipairs(LP.PlayerScripts:GetDescendants()) do check(v) end
    end)
    allRemotes  = found
    chatRemotes = {}
    for _,v in ipairs(found) do
        local n=v.Name:lower()
        for _,kw in ipairs(CHAT_KW) do
            if n:find(kw) then table.insert(chatRemotes,v);break end
        end
    end
    return found
end

-- Fire one remote with every plausible arg pattern
local function firePatterns(remote, uname, display, msg)
    -- string patterns
    pcall(function() remote:FireServer(msg) end)
    pcall(function() remote:FireServer(display, msg) end)
    pcall(function() remote:FireServer(uname, msg) end)
    pcall(function() remote:FireServer(msg, display) end)
    pcall(function() remote:FireServer(uname, msg, display) end)
    pcall(function() remote:FireServer(display, msg, uname) end)
    pcall(function() remote:FireServer(uname, display, msg) end)
    -- table/dict patterns (some games pass {Message=..., Type=...})
    pcall(function() remote:FireServer({Message=msg}) end)
    pcall(function() remote:FireServer({Text=msg}) end)
    pcall(function() remote:FireServer({message=msg}) end)
    pcall(function() remote:FireServer({Message=msg, Type="Say"}) end)
    pcall(function() remote:FireServer({Message=msg, DisplayName=display}) end)
    pcall(function() remote:FireServer({name=uname, text=msg}) end)
end

-- ── Advanced spoof hooks (executor-dependent) ────────────────────
-- These hook the game's own RemoteEvent fires so even calls made by
-- the game's LocalScripts carry the fake display name.
-- Falls back silently if the executor doesn't expose the needed APIs.

-- Hook __namecall on `game` to intercept every :FireServer call made
-- by the game's own LocalScripts and replace the real display/name args.
-- Returns unhook function (or nil if not supported).
local namecallHook = nil
local function hookNamecall(fakeDisplay, fakeName)
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" then
                local args = {...}
                for i,v in ipairs(args) do
                    if type(v)=="string" then
                        if v==LP.DisplayName then args[i]=fakeDisplay
                        elseif v==LP.Name     then args[i]=fakeName end
                    end
                end
                return old(self, table.unpack(args))
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        namecallHook = function()
            pcall(function()
                setreadonly(mt,false); mt.__namecall=old; setreadonly(mt,true)
            end)
            namecallHook=nil
        end
    end)
    return ok
end

-- Hook LP's __index so any game LocalScript reading LP.DisplayName / LP.Name
-- gets the fake value during the hook window.
local lpHook = nil
local function hookLPName(fakeDisplay, fakeName)
    local ok = pcall(function()
        local mt = getrawmetatable(LP)
        setreadonly(mt, false)
        local old = mt.__index
        mt.__index = newcclosure(function(t, k)
            if t==LP then
                if k=="DisplayName" then return fakeDisplay end
                if k=="Name"        then return fakeName end
            end
            return old(t, k)
        end)
        setreadonly(mt, true)
        lpHook = function()
            pcall(function()
                setreadonly(mt,false); mt.__index=old; setreadonly(mt,true)
            end)
            lpHook=nil
        end
    end)
    return ok
end

local function unhookAll()
    if namecallHook then pcall(namecallHook) end
    if lpHook       then pcall(lpHook) end
end

-- ── GUI simulation ────────────────────────────────────────────────
-- Finds the game's own speech/chat TextBox in PlayerGui and injects
-- text + fires its submit action — bypasses remote search entirely,
-- goes through the game's own code path, visible to ALL players.
local GUI_KW = {"speech","chat","say","type","input","message","talk","mic","voice","speak","submit","send"}
local function tryGUISimulate(message)
    local candidates = {}
    -- collect all TextBoxes, score each by keyword matches in name/placeholder/ancestors
    for _,v in ipairs(PGui:GetDescendants()) do
        if v:IsA("TextBox") then
            local score = 0
            local n  = v.Name:lower()
            local ph = v.PlaceholderText:lower()
            for _,kw in ipairs(GUI_KW) do
                if n:find(kw)  then score=score+3 end
                if ph:find(kw) then score=score+2 end
            end
            -- check ancestor names
            local par = v.Parent
            for _=1,4 do
                if not par or par==PGui then break end
                local pn = par.Name:lower()
                for _,kw in ipairs(GUI_KW) do
                    if pn:find(kw) then score=score+1 end
                end
                par=par.Parent
            end
            if score > 0 then
                table.insert(candidates,{box=v, score=score, name=v.Name})
            end
        end
    end
    -- sort highest score first
    table.sort(candidates, function(a,b) return a.score > b.score end)

    for _,c in ipairs(candidates) do
        local box = c.box
        box.Text = message
        -- simulate pressing Enter (FocusLost with enterPressed=true)
        pcall(function() box.FocusLost:Fire(true) end)
        task.wait(0.05)
        -- find any submit button in the same parent tree
        if box.Parent then
            for _,sib in ipairs(box.Parent:GetDescendants()) do
                if sib:IsA("TextButton") and sib ~= box then
                    local sn = sib.Text:lower()
                    if sn=="" or sn==">" or sn=="→" or sn:find("send") or sn:find("say") or sn:find("post") or sn:find("submit") then
                        pcall(function() sib.MouseButton1Click:Fire() end)
                        pcall(function() sib.Activated:Fire() end)
                    end
                end
            end
        end
        return true, "GUI("..c.name..")"
    end
    return false, "no speech box found in PlayerGui"
end

-- ── Helpers ───────────────────────────────────────────────────────
local function tw(i,t,p) TweenSvc:Create(i,t,p):Play() end
local TF = TweenInfo.new(0.14,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local TM = TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)

local AC  = Color3.fromRGB(64,156,255)
local BG  = Color3.fromRGB(9,11,22)
local CD  = Color3.fromRGB(14,19,36)
local T1  = Color3.fromRGB(228,240,255)
local T2  = Color3.fromRGB(140,178,235)
local T3  = Color3.fromRGB(68,105,162)
local GRN = Color3.fromRGB(68,224,114)
local RED = Color3.fromRGB(255,88,88)
local ORG = Color3.fromRGB(255,178,60)

local function mkF(par,sz,pos,col,tr)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos
    f.BackgroundColor3=col;f.BackgroundTransparency=tr or 0
    f.BorderSizePixel=0;f.Parent=par;return f
end
local function mkL(par,txt,fsz,col,pos,sz,xa,bold,wrap)
    local l=Instance.new("TextLabel");l.Text=txt
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fsz;l.TextColor3=col;l.BackgroundTransparency=1
    l.Position=pos;l.Size=sz
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextWrapped=wrap or false;l.TextTruncate=Enum.TextTruncate.AtEnd
    l.BorderSizePixel=0;l.Parent=par;return l
end
local function mkB(par,sz,pos,col,tr)
    local b=Instance.new("TextButton");b.Text=""
    b.Size=sz;b.Position=pos;b.BackgroundColor3=col
    b.BackgroundTransparency=tr or 0;b.BorderSizePixel=0
    b.AutoButtonColor=false;b.Parent=par;return b
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
    mkF(f,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80)
    return f
end
local function notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 5})
    end)
end

-- ── GUI ───────────────────────────────────────────────────────────
local old=PGui:FindFirstChild("NPCChatControl"); if old then old:Destroy() end
local SG=Instance.new("ScreenGui")
SG.Name="NPCChatControl";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.Parent=PGui

local W,H=540,480
local WIN=mkF(SG,UDim2.new(0,W,0,H),UDim2.new(0.5,-W/2,0.5,-H/2),BG,0.18)
corner(WIN,14);WIN.ClipsDescendants=true
stroke(WIN,AC,0.46,1.5)
mkF(WIN,UDim2.new(1,0,0,2),UDim2.new(0,0,0,0),AC,0.80)

-- titlebar
local TB=mkF(WIN,UDim2.new(1,0,0,46),UDim2.new(0,0,0,0),BG,1)
mkF(TB,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)
local gemF=mkF(TB,UDim2.new(0,24,0,24),UDim2.new(0,12,0.5,-12),AC,0.16);corner(gemF,7)
stroke(gemF,AC,0.38,1)
mkL(gemF,"◆",12,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
mkL(TB,"Chat Control",14,T1,UDim2.new(0,44,0,0),UDim2.new(0,120,1,0),Enum.TextXAlignment.Left,true)
mkL(TB,"FE spoof · trust detector",9,T3,UDim2.new(0,44,0,0),UDim2.new(0,180,1,0),Enum.TextXAlignment.Left,false)
-- bridge status pill
local bPill=mkF(TB,UDim2.new(0,72,0,18),UDim2.new(0,228,0.5,-9),CD,0.40);corner(bPill,9)
stroke(bPill,T3,0.60,1)
local bDot=mkF(bPill,UDim2.new(0,6,0,6),UDim2.new(0,6,0.5,-3),RED,0);corner(bDot,3)
local bLbl=mkL(bPill,"SS offline",9,RED,UDim2.new(0,16,0,0),UDim2.new(1,-18,1,0),Enum.TextXAlignment.Left,false)
-- poll bridge state and update pill
task.spawn(function()
    while SG and SG.Parent do
        local online = Bridge ~= nil and Bridge.Parent ~= nil
        bDot.BackgroundColor3 = online and GRN or RED
        bLbl.Text             = online and "SS online" or "SS offline"
        bLbl.TextColor3       = online and GRN or RED
        stroke(bPill, online and GRN or T3, online and 0.42 or 0.60, 1)
        task.wait(2)
    end
end)

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
    local drag,ds,sp,last=false,nil,nil,nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true;ds=i.Position;sp=WIN.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)
    TB.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then last=i end
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

-- ── LEFT: player list ─────────────────────────────────────────────
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

-- selected player card
local selCard=card(RIGHT,UDim2.new(1,-14,0,42),UDim2.new(0,7,0,8))
mkL(selCard,"SELECTED",8,T3,UDim2.new(0,10,0,4),UDim2.new(1,-10,0,11),Enum.TextXAlignment.Left,true)
local selL=mkL(selCard,"— tap a player —",12,T2,UDim2.new(0,10,0,17),UDim2.new(1,-12,0,16),Enum.TextXAlignment.Left,false)

-- mode pills
mkL(RIGHT,"SEND MODE",8,T3,UDim2.new(0,10,0,58),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,70),AC,0.70)

local MODES  = {"Server","As Me","Spoof All","Targeted"}
local MNOTES = {
    "SS Bridge — Chat:Chat + FireAllClients server-side ✓ 100%",
    "YOU say it — TextChatService, all see it ✓",
    "Fires every remote · auto-detects trusted ones",
    "Fires only the selected remote (use after Spoof All)",
}
local modeIdx  = 1
local modeBtns = {}
local modeNoteL= mkL(RIGHT,"",8,T3,UDim2.new(0,10,1,-14),UDim2.new(1,-14,0,12),Enum.TextXAlignment.Left,false,true)
local function setModeNote() modeNoteL.Text=MNOTES[modeIdx] or "" end

local modeRow=mkF(RIGHT,UDim2.new(1,-14,0,30),UDim2.new(0,7,0,74),CD,0.50)
corner(modeRow,8);modeRow.ClipsDescendants=true

for i,name in ipairs(MODES) do
    local pct=(i-1)/#MODES
    local mb=mkF(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new(pct,0,0,0),AC,i==1 and 0.72 or 1)
    if i==1 then corner(mb,8) elseif i==#MODES then corner(mb,8) end
    local ml=mkL(mb,name,10,i==1 and T1 or T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,i==1)
    local mh=mkB(modeRow,UDim2.new(1/#MODES,0,1,0),UDim2.new(pct,0,0,0),AC,1)
    mh.ZIndex=2
    local ci=i
    mh.MouseButton1Click:Connect(function()
        modeIdx=ci;setModeNote()
        for j,bt in ipairs(modeBtns) do
            tw(bt.bg,TF,{BackgroundTransparency=j==ci and 0.72 or 1})
            bt.lbl.Font=j==ci and Enum.Font.GothamBold or Enum.Font.Gotham
            bt.lbl.TextColor3=j==ci and T1 or T3
        end
    end)
    table.insert(modeBtns,{bg=mb,lbl=ml})
end
setModeNote()

-- ── Remote list ───────────────────────────────────────────────────
mkL(RIGHT,"REMOTES",8,T3,UDim2.new(0,10,0,112),UDim2.new(1,-80,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,124),AC,0.70)

local rsBg=mkF(RIGHT,UDim2.new(0,58,0,18),UDim2.new(1,-65,0,110),AC,0.72);corner(rsBg,7)
mkL(rsBg,"⟳ Scan",9,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local rsHit=mkB(RIGHT,UDim2.new(0,58,0,18),UDim2.new(1,-65,0,110),AC,1);rsHit.ZIndex=2

local remScroll=Instance.new("ScrollingFrame")
remScroll.Size=UDim2.new(1,-14,0,80);remScroll.Position=UDim2.new(0,7,0,128)
remScroll.BackgroundTransparency=1;remScroll.BorderSizePixel=0
remScroll.ScrollBarThickness=3;remScroll.ScrollBarImageColor3=AC
remScroll.CanvasSize=UDim2.new(0,0,0,0);remScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
remScroll.ScrollingDirection=Enum.ScrollingDirection.Y;remScroll.Parent=RIGHT

local remLL=Instance.new("UIListLayout",remScroll);remLL.Padding=UDim.new(0,2)
local remEmptyL=mkL(remScroll,"Press ⟳ Scan to find remotes",10,T3,
    UDim2.new(0,0,0,0),UDim2.new(1,0,0,26),Enum.TextXAlignment.Center,false)

local selectedRemote=nil
local remoteBtns={}

local function selectRemote(re)
    selectedRemote=re
    for r,btn in pairs(remoteBtns) do
        local on=(r==re)
        local isTrusted=trustedRemotes[r]~=nil
        tw(btn.bg,TF,{BackgroundTransparency=on and 0.14 or (isTrusted and 0.20 or 0.60)})
        if not isTrusted then
            btn.lbl.TextColor3=on and T1 or T2
            btn.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        end
    end
end

-- Mark a remote as TRUSTED: update row UI, status, popup, auto-switch mode
local statusL  -- forward ref; defined below
local function markTrusted(remote, method)
    if trustedRemotes[remote] then return end
    trustedRemotes[remote]=method or "confirmed"

    -- Update remote list row
    if remoteBtns[remote] then
        local btn=remoteBtns[remote]
        btn.lbl.Text="✓ TRUSTED · "..remote.Name
        btn.lbl.TextColor3=GRN
        btn.lbl.Font=Enum.Font.GothamBold
        tw(btn.bg,TF,{BackgroundTransparency=0.10})
        -- green left dot
        if btn.dot then btn.dot.BackgroundColor3=GRN;btn.dot.BackgroundTransparency=0 end
        -- green stroke
        if btn.stroke then btn.stroke.Color=GRN;btn.stroke.Transparency=0.30 end
    end

    -- Status bar
    if statusL then
        statusL.Text="TRUSTED: "..remote.Name.." → "..tostring(method).." ✓"
        statusL.TextColor3=GRN
    end

    -- In-game notification popup
    notify("Trusted Remote Found!",remote.Name.." responded via "..tostring(method),7)

    -- Auto-switch to Targeted mode + select this remote
    modeIdx=3;setModeNote()
    for j,bt in ipairs(modeBtns) do
        tw(bt.bg,TF,{BackgroundTransparency=j==3 and 0.72 or 1})
        bt.lbl.Font=j==3 and Enum.Font.GothamBold or Enum.Font.Gotham
        bt.lbl.TextColor3=j==3 and T1 or T3
    end
    selectRemote(remote)
end

local function rebuildRemoteList(found)
    for _,btn in pairs(remoteBtns) do btn.bg:Destroy() end
    remoteBtns={}
    remEmptyL.Parent=nil
    if #found==0 then
        remEmptyL.Text="No remotes found in RS";remEmptyL.Parent=remScroll;return
    end
    for _,re in ipairs(found) do
        local isChatRem=false
        for _,v in ipairs(chatRemotes) do if v==re then isChatRem=true;break end end
        local isTrusted=trustedRemotes[re]~=nil
        local rowBg=mkF(remScroll,UDim2.new(1,0,0,22),UDim2.new(0,0,0,0),
            isTrusted and GRN or CD, isTrusted and 0.10 or 0.60)
        corner(rowBg,6);rowBg.ClipsDescendants=true
        local rowStroke=stroke(rowBg,
            isTrusted and GRN or (isChatRem and AC or Color3.new(1,1,1)),
            isTrusted and 0.28 or (isChatRem and 0.50 or 0.88), 1)
        local dot=mkF(rowBg,UDim2.new(0,5,0,5),UDim2.new(0,5,0.5,-2),
            isTrusted and GRN or (isChatRem and AC or T3), 0);corner(dot,3)
        local lbl
        if isTrusted then
            lbl=mkL(rowBg,"✓ TRUSTED · "..re.Name,9,GRN,UDim2.new(0,14,0,0),UDim2.new(1,-18,1,0),Enum.TextXAlignment.Left,true)
        else
            lbl=mkL(rowBg,re.Name,9,T2,UDim2.new(0,14,0,0),UDim2.new(1,-18,1,0),Enum.TextXAlignment.Left,false)
        end
        local hit=mkB(rowBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
        local r=re
        hit.MouseButton1Click:Connect(function() selectRemote(r) end)
        hit.MouseEnter:Connect(function()
            if selectedRemote~=r then tw(rowBg,TF,{BackgroundTransparency=0.36}) end
        end)
        hit.MouseLeave:Connect(function()
            if selectedRemote~=r then
                tw(rowBg,TM,{BackgroundTransparency=trustedRemotes[r] and 0.10 or 0.60})
            end
        end)
        remoteBtns[re]={bg=rowBg,lbl=lbl,dot=dot,stroke=rowStroke}
    end
    -- auto-select first trusted, else first chat remote
    if not selectedRemote then
        for r,_ in pairs(trustedRemotes) do selectRemote(r);break end
        if not selectedRemote and #chatRemotes>0 then selectRemote(chatRemotes[1]) end
    end
end

-- ── Trust detection ───────────────────────────────────────────────
-- Starts listeners BEFORE firing so we catch the server's response.
-- Signals watched (any one is enough to confirm):
--   1. remote.OnClientEvent  — server fired back (broadcast pattern)
--   2. targetPlayer.Chatted  — legacy chat system relayed the message
--   3. TextChannel.MessageReceived — TextChatService received it from target
--   4. target character Head.ChildAdded BillboardGui — bubble chat appeared
local function watchForTrust(remote, targetPlr, msg, onTrusted)
    if trustedRemotes[remote] then onTrusted(trustedRemotes[remote]);return end
    local done  = false
    local conns = {}
    local function succeed(method)
        if done then return end; done=true
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        onTrusted(method)
    end

    -- 1. Server fires OnClientEvent back (most reliable for custom chat)
    if remote:IsA("RemoteEvent") then
        local ok,c=pcall(function()
            return remote.OnClientEvent:Connect(function(...)
                local args={...}
                -- accept any callback; optionally check for our msg text
                local matched=true
                if #args>0 then
                    matched=false
                    for _,v in ipairs(args) do
                        if type(v)=="string" and v:find(msg,1,true) then matched=true;break end
                    end
                end
                if matched then succeed("OnClientEvent") end
            end)
        end)
        if ok then table.insert(conns,c) end
    end

    -- 2. Legacy Chatted event on target player
    if targetPlr then
        local ok,c=pcall(function()
            return targetPlr.Chatted:Connect(function(chatMsg)
                if chatMsg:find(msg,1,true) then succeed("Chatted") end
            end)
        end)
        if ok then table.insert(conns,c) end
    end

    -- 3. TextChatService channel — message appears attributed to target
    pcall(function()
        local channels=TCS:FindFirstChild("TextChannels")
        if not channels then return end
        for _,ch in ipairs(channels:GetChildren()) do
            if ch:IsA("TextChannel") then
                local ok,c=pcall(function()
                    return ch.MessageReceived:Connect(function(tcMsg)
                        local text=tcMsg.Text or ""
                        if not text:find(msg,1,true) then return end
                        local src=tcMsg.TextSource
                        if src and src.UserId~=LP.UserId then
                            succeed("TextChannel")
                        end
                    end)
                end)
                if ok then table.insert(conns,c) end
            end
        end
    end)

    -- 4. Bubble chat BillboardGui appears on target's Head
    if targetPlr then
        pcall(function()
            local char=targetPlr.Character
            if not char then return end
            local head=char:FindFirstChild("Head")
            if not head then return end
            local ok,c=pcall(function()
                return head.ChildAdded:Connect(function(child)
                    if child:IsA("BillboardGui") then succeed("BubbleChat") end
                end)
            end)
            if ok then table.insert(conns,c) end
        end)
    end

    -- Cleanup after 2 seconds regardless
    task.delay(2,function()
        for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    end)
end

local function doScan()
    remEmptyL.Text="scanning…";remEmptyL.Parent=remScroll
    for _,btn in pairs(remoteBtns) do btn.bg:Destroy() end;remoteBtns={}
    task.spawn(function()
        rebuildRemoteList(scanAll())
    end)
end
rsHit.MouseEnter:Connect(function() tw(rsBg,TF,{BackgroundTransparency=0.44}) end)
rsHit.MouseLeave:Connect(function() tw(rsBg,TM,{BackgroundTransparency=0.72}) end)
rsHit.MouseButton1Click:Connect(doScan)
task.spawn(doScan)

-- ── Message box ───────────────────────────────────────────────────
mkL(RIGHT,"MESSAGE",8,T3,UDim2.new(0,10,0,216),UDim2.new(1,-10,0,12),Enum.TextXAlignment.Left,true)
mkF(RIGHT,UDim2.new(1,-14,0,1),UDim2.new(0,7,0,228),AC,0.70)

local msgCard=mkF(RIGHT,UDim2.new(1,-14,1,-276),UDim2.new(0,7,0,234),CD,0.40)
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

statusL=mkL(RIGHT,"",10,T3,UDim2.new(0,10,1,-94),UDim2.new(1,-14,0,20),Enum.TextXAlignment.Left,false,true)

-- buttons
local clrCard=mkF(RIGHT,UDim2.new(0,62,0,34),UDim2.new(0,7,1,-68),CD,0.50)
corner(clrCard,9);stroke(clrCard,Color3.new(1,1,1),0.84,1)
mkL(clrCard,"⌫ Clear",11,T2,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,false)
local clrHit=mkB(clrCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
clrHit.MouseEnter:Connect(function() tw(clrCard,TF,{BackgroundTransparency=0.28}) end)
clrHit.MouseLeave:Connect(function() tw(clrCard,TM,{BackgroundTransparency=0.50}) end)
clrHit.MouseButton1Click:Connect(function()
    msgBox.Text="";statusL.Text="";statusL.TextColor3=T3
end)

local sendCard=mkF(RIGHT,UDim2.new(1,-80,0,34),UDim2.new(0,74,1,-68),AC,0.12)
corner(sendCard,9);stroke(sendCard,AC,0.44,1.5)
mkF(sendCard,UDim2.new(1,-2,0,1),UDim2.new(0,1,0,1),Color3.new(1,1,1),0.80)
local sendLbl=mkL(sendCard,"▶  Send",13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
local sendHit=mkB(sendCard,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),AC,1)
sendHit.MouseEnter:Connect(function() tw(sendCard,TF,{BackgroundTransparency=0}) end)
sendHit.MouseLeave:Connect(function() tw(sendCard,TM,{BackgroundTransparency=0.12}) end)

-- ── Player list ───────────────────────────────────────────────────
local selectedPlayer=nil
local playerBtns={}

local function setStatus(msg,ok)
    local col=ok==true and GRN or (ok==nil and ORG or RED)
    statusL.Text=msg;statusL.TextColor3=col
    task.delay(6,function()
        if statusL.Text==msg then statusL.Text="";statusL.TextColor3=T3 end
    end)
end

local function selectPlayer(plr)
    selectedPlayer=plr
    if plr then
        selL.Text=plr.DisplayName.." · @"..plr.Name;selL.TextColor3=T1
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
    local bar=mkF(row,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),AC,0);corner(bar,2)
    local av=mkF(row,UDim2.new(0,28,0,28),UDim2.new(0,8,0.5,-14),AC,0.52);corner(av,14)
    mkL(av,plr.Name:sub(1,1):upper(),13,T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center,true)
    local nl=mkL(row,plr.DisplayName,12,T2,UDim2.new(0,42,0,5),UDim2.new(1,-50,0,14),Enum.TextXAlignment.Left,false)
    mkL(row,"@"..plr.Name,9,T3,UDim2.new(0,42,0,22),UDim2.new(1,-50,0,13),Enum.TextXAlignment.Left,false)
    local dot=mkF(row,UDim2.new(0,6,0,6),UDim2.new(1,-12,0.5,-3),AC,0.80);corner(dot,3)
    local hit=mkB(row,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),CD,1)
    hit.MouseEnter:Connect(function()
        if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.48}) end
    end)
    hit.MouseLeave:Connect(function()
        if selectedPlayer~=plr then tw(row,TF,{BackgroundTransparency=0.68}) end
    end)
    hit.MouseButton1Click:Connect(function()
        if selectedPlayer==plr then selectPlayer(nil) else selectPlayer(plr) end
    end)
    playerBtns[plr]={bg=row,lbl=nl,dot=dot,bar=bar}
end

local function removeRow(plr)
    if playerBtns[plr] then playerBtns[plr].bg:Destroy();playerBtns[plr]=nil end
    if selectedPlayer==plr then selectPlayer(nil) end
end

for _,p in ipairs(Players:GetPlayers()) do buildRow(p) end
Players.PlayerAdded:Connect(buildRow)
Players.PlayerRemoving:Connect(removeRow)

-- ── Send logic ────────────────────────────────────────────────────
local function doSend()
    local msg=msgBox.Text:match("^%s*(.-)%s*$")
    if msg=="" then setStatus("Type a message first.",false);return end

    if modeIdx==1 then
        -- ── SERVER MODE: uses SS_ExecBridge (SS_Executor.lua on server) ──────
        -- Server-side Chat:Chat + FireAllClients → 100% visible to all, no FE
        if not Bridge then
            setStatus("SS Bridge offline — run SS_Executor.lua as a server Script first.",false)
            return
        end
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local display = selectedPlayer.DisplayName
        local uname   = selectedPlayer.Name
        local res = callBridge("chat", {target=uname, message=msg, display=display})
        if res and res.ok then
            setStatus("Server: "..res.msg,true)
            notify("SS Chat Sent",res.msg,4)
        else
            local errMsg = res and res.msg or "Bridge call failed"
            setStatus("SS error: "..errMsg,false)
        end

    elseif modeIdx==2 then
        -- Try every path. The game's own GUI simulate is tried first because
        -- it uses the game's real code path — guaranteed visible if successful.
        local sent, method = false, ""

        -- 1. GUI SIMULATE: inject text into game's speech/chat TextBox + fire submit
        --    This is the most reliable for custom-UI games like Mic Up where the
        --    default Roblox chat is hidden. Goes through the game's own RemoteEvent.
        if not sent then
            local ok, m = tryGUISimulate(msg)
            if ok then sent=true; method=m end
        end

        -- 2. TextChatService SendAsync (Roblox's own chat system — visible to all
        --    in games that show the default Roblox chat)
        if not sent then
            pcall(function()
                local channels = TCS:FindFirstChild("TextChannels")
                if not channels then return end
                local ch = channels:FindFirstChild("RBXGeneral")
                if not ch then
                    for _,v in ipairs(channels:GetChildren()) do
                        if v:IsA("TextChannel") then ch=v;break end
                    end
                end
                if not ch then return end
                ch:SendAsync(msg)
                sent=true; method="TextChatService"
            end)
        end

        -- 3. Old chat SayMessageRequest (legacy/hybrid games)
        if not sent then
            pcall(function()
                local dce = RS:FindFirstChild("DefaultChatSystemChatEvents")
                    or RS:FindFirstChild("ChatEvents")
                if not dce then return end
                local req = dce:FindFirstChild("SayMessageRequest")
                    or dce:FindFirstChild("SendMessage")
                if not req then return end
                req:FireServer({Message=msg, Type="Say"})
                sent=true; method="SayMessageRequest"
            end)
        end

        -- 4. Fire all chat-named remotes as self (catches game-specific chat REs)
        if not sent and #chatRemotes > 0 then
            for _,re in ipairs(chatRemotes) do
                pcall(function() re:FireServer(msg) end)
                pcall(function() re:FireServer(LP.Name, msg) end)
                pcall(function() re:FireServer({Message=msg, Type="Say"}) end)
            end
            sent=true; method="chat remotes ("..#chatRemotes..")"
        end

        if sent then
            setStatus("Sent via "..method.." ✓",true)
            notify("Sent!","via "..method,3)
        else
            setStatus("All methods failed — try Spoof All mode.",false)
        end

    elseif modeIdx==3 then
        -- ── SPOOF ALL ──────────────────────────────────────────────────────────
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        local display=selectedPlayer.DisplayName
        local uname=selectedPlayer.Name
        local hookMethods = {}

        if hookNamecall(display, uname) then table.insert(hookMethods,"__namecall") end
        if hookLPName(display, uname)   then table.insert(hookMethods,"LP.__index") end

        local guiOk, guiMethod = tryGUISimulate(msg)

        local fired = 0
        for _,remote in ipairs(allRemotes) do
            local r=remote
            watchForTrust(r, selectedPlayer, msg, function(m) markTrusted(r, m) end)
            firePatterns(r, uname, display, msg)
            fired=fired+1
        end

        local char=selectedPlayer.Character
        if char then pcall(function() ChatSvc:Chat(char,msg,Enum.ChatColor.White) end) end
        task.delay(1, unhookAll)

        local parts = {}
        if #hookMethods>0 then table.insert(parts,"hooks("..table.concat(hookMethods,"+")..") ✓") end
        if guiOk         then table.insert(parts,"GUI("..guiMethod..") ✓") end
        if fired>0       then table.insert(parts,fired.." remotes") end
        setStatus(table.concat(parts," · "),#parts>0 and nil or false)

    elseif modeIdx==4 then
        -- ── TARGETED ───────────────────────────────────────────────────────────
        if not selectedPlayer then setStatus("Select a player first.",false);return end
        if not selectedRemote then setStatus("Select a remote from the list.",false);return end
        local display=selectedPlayer.DisplayName
        local uname=selectedPlayer.Name
        local r=selectedRemote
        hookNamecall(display, uname)
        hookLPName(display, uname)
        watchForTrust(r, selectedPlayer, msg, function(m) markTrusted(r, m) end)
        firePatterns(r, uname, display, msg)
        tryGUISimulate(msg)
        local char=selectedPlayer.Character
        if char then pcall(function() ChatSvc:Chat(char,msg,Enum.ChatColor.White) end) end
        task.delay(1, unhookAll)
        setStatus("Fired \""..r.Name.."\" as \""..display.."\" + hooks",nil)
    end

    sendLbl.Text="✓  Sent";tw(sendCard,TF,{BackgroundTransparency=0})
    task.delay(1.6,function()
        sendLbl.Text="▶  Send";tw(sendCard,TM,{BackgroundTransparency=0.12})
    end)
end

sendHit.MouseButton1Click:Connect(doSend)
msgBox.FocusLost:Connect(function(enter) if enter then doSend() end end)

-- ── Open animation ────────────────────────────────────────────────
WIN.Size=UDim2.new(0,W*0.86,0,H*0.86);WIN.BackgroundTransparency=1
tw(WIN,TweenInfo.new(0.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,W,0,H),BackgroundTransparency=0.18
})
