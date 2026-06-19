local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local VirtualUser=game:GetService("VirtualUser")
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local TW=game:GetService("TweenService")
local StarterGui=game:GetService("StarterGui")
local LP=Players.LocalPlayer
local PGui=LP:WaitForChild("PlayerGui")
local isMobile=UIS.TouchEnabled

local KNOWN_GAMES={
    [74779072921656]="NerdZone Spelling Bee",
    [17590362521]="Spelling Bee",
    [83091000527113]="Spelling Bee",
    [17707569217]="Spelling Bee",
    [91692552632068]="Scary Spelling Bee",
    [133419989757748]="Bean Cans Spelling Bee",
    [70718852079605]="Spelling Bee",
    [115840692772844]="Spelling Bee",
    [135159688166294]="Spelling Bee",
}
local GAME_NAME=KNOWN_GAMES[game.PlaceId] or "Spelling Bee"
local IS_KNOWN=KNOWN_GAMES[game.PlaceId]~=nil

local function notify(t,m,d)
    pcall(function()StarterGui:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 4})end)
end
notify("Preppy Hub | "..GAME_NAME,IS_KNOWN and "Game detected!" or "Universal mode",3)

-- ── state ──────────────────────────────────────────────────────────────
local botEnabled=true
local submitDelay=0.05
local currentWord=""
local answerRemote=nil
local knownAnswerRemotes={} -- confirmed FireServer remotes
local antiAFK=false
local infJump=false
local sessionStart=os.clock()
local wordsTyped=0
local bestWPM=0
local mistakes=0

local function getWPM()
    local m=(os.clock()-sessionStart)/60
    return m<0.01 and 0 or math.floor(wordsTyped/m)
end

local nWord,nWords,nWpm,nBest,nMist,nAcc,statusDot,statusLbl

local function updateStats()
    if not nWords then return end
    local wpm=getWPM()
    if wpm>bestWPM then bestWPM=wpm end
    local acc=wordsTyped==0 and 100 or math.floor(((wordsTyped-mistakes)/wordsTyped)*100)
    nWords.Text=tostring(wordsTyped)
    nWpm.Text=tostring(wpm)
    nBest.Text=tostring(bestWPM)
    nMist.Text=tostring(mistakes)
    nAcc.Text=acc.."%"
end

-- ── word detection ──────────────────────────────────────────────────────
local UI_BL={spellingbee=1,nerdzone=1,preppyhub=1,preppy=1,hub=1,submit=1,answer=1,play=1,reset=1,start=1,continue=1,back=1,close=1,menu=1,quit=1,exit=1,enabled=1,disabled=1,loading=1,loaded=1,waiting=1,ready=1,error=1,failed=1,roblox=1,studio=1,player=1,server=1,client=1,remote=1}

local function looksLikeWord(s)
    if type(s)~="string" then return false end
    local trimmed=s:match("^%s*(.-)%s*$") or s
    if #trimmed<2 or #trimmed>50 then return false end
    if trimmed:match("[%d%p%s]") then return false end
    if #trimmed==0 then return false end
    return not UI_BL[trimmed:lower()]
end

local function extractWord(args)
    for _,v in ipairs(args) do
        if looksLikeWord(v) then return v end
        if type(v)=="table" then
            for _,tv in pairs(v) do
                if looksLikeWord(tv) then return tv end
                if type(tv)=="string" then
                    local w=tv:match("([%a][%a]+)")
                    if w and looksLikeWord(w) then return w end
                end
            end
        end
        if type(v)=="string" then
            local trimmed=v:match("^%s*(.-)%s*$")
            if looksLikeWord(trimmed) then return trimmed end
            local w=v:match("([%a][%a]+)")
            if w and looksLikeWord(w) then return w end
        end
        if type(v)=="userdata" then
            pcall(function()
                if v:IsA("StringValue") and looksLikeWord(v.Value) then
                    return v.Value
                end
            end)
        end
    end
end

-- ── specific RS.Events / RS.Modules paths ───────────────────────────────
local RS_EVENTS   = RS:FindFirstChild("Events")
local RS_MODULES  = RS:FindFirstChild("Modules")

local SCAN_ROOTS={RS,WS,game:GetService("ReplicatedFirst"),PGui,LP}
pcall(function()table.insert(SCAN_ROOTS,LP.Backpack)end)
pcall(function()table.insert(SCAN_ROOTS,LP.Character)end)
if RS_EVENTS  then table.insert(SCAN_ROOTS,RS_EVENTS) end
if RS_MODULES then table.insert(SCAN_ROOTS,RS_MODULES) end

local ANSWER_KEYS={"submit","answer","spell","type","guess","check","input","word","attempt","confirm","enter","send","fire","respond","bean","can","scary","horror","spook","round","solve"}
local function isAnswerRemote(name)
    local n=name:lower()
    for _,k in ipairs(ANSWER_KEYS) do if n:find(k,1,true) then return true end end
    return false
end

local function findAnswerRemote()
    if answerRemote and answerRemote.Parent then return answerRemote end
    answerRemote=nil
    for _,root in ipairs(SCAN_ROOTS) do
        local ok,r=pcall(function()
            for _,obj in ipairs(root:GetDescendants()) do
                if obj:IsA("RemoteEvent") and isAnswerRemote(obj.Name) then return obj end
            end
        end)
        if ok and r then answerRemote=r;return r end
    end
end

local function fireAllRemotes(word)
    local fired=false
    local function blast(root)
        for _,r in ipairs(root:GetDescendants()) do
            if r:IsA("RemoteEvent") then pcall(function()r:FireServer(word)end);fired=true end
        end
    end
    blast(RS);blast(WS);return fired
end

local CHAR_MS_BASE=0.037
local function humanTypeBox(box,word)
    box.Text="";box:CaptureFocus();task.wait(0.02+math.random()*0.015)
    for i=1,#word do
        box.Text=word:sub(1,i)
        task.wait(CHAR_MS_BASE+(math.random()-0.5)*0.016)
    end
    task.wait(0.02+math.random()*0.015);box:ReleaseFocus(true)
end

local function fireAnswer(word)
    task.wait(math.min(#word*CHAR_MS_BASE,3))
    local r=findAnswerRemote()
    if r then pcall(function()r:FireServer(word)end);return true end
    -- try confirmed FireServer remotes (GameEvent, MusicEvent)
    for _,kr in ipairs(knownAnswerRemotes) do
        if kr and kr.Parent then pcall(function()kr:FireServer(word)end);return true end
    end
    return fireAllRemotes(word)
end

local function boxSubmit(word)
    local function tryBoxes(root)
        for _,obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextBox") and obj.TextEditable and obj.Visible then humanTypeBox(obj,word);return true end
        end
    end
    return tryBoxes(PGui) or tryBoxes(WS) or false
end

local submitAnswer
local function onWordFound(w)
    w=w:lower()
    if w==currentWord then return end
    currentWord=w
    if nWord then nWord.Text=w:upper() end
    if botEnabled then task.delay(submitDelay,function()submitAnswer(w)end) end
end

submitAnswer=function(word)
    if word=="" then return end
    if fireAnswer(word) or boxSubmit(word) then
        wordsTyped=wordsTyped+1;updateStats()
    end
end

-- ── hooks ───────────────────────────────────────────────────────────────
local _hooked={}
local function hookOne(remote)
    if _hooked[remote] then return end;_hooked[remote]=true
    remote.OnClientEvent:Connect(function(...)
        local w=extractWord({...});if w then task.spawn(onWordFound,w) end
    end)
end

local _hookedRF={}
local function hookOneRF(rf)
    if _hookedRF[rf] then return end;_hookedRF[rf]=true
    rf.OnClientInvoke=function(...)
        local w=extractWord({...});if w then task.spawn(onWordFound,w) end
    end
end

local function hookIncoming()
    for _,root in ipairs(SCAN_ROOTS) do
        pcall(function()
            for _,r in ipairs(root:GetDescendants()) do
                if r:IsA("RemoteEvent") then hookOne(r)
                elseif r:IsA("RemoteFunction") then hookOneRF(r) end
            end
        end)
    end
end

local function installNamecallHook()
    if not hookmetamethod or not newcclosure or not getnamecallmethod then return false end
    local ok=pcall(function()
        local _old;_old=hookmetamethod(game,"__namecall",newcclosure(function(self,...)
            local m=getnamecallmethod()
            if m=="FireServer" or m=="InvokeServer" then
                local isRE=pcall(function()return self:IsA("RemoteEvent")end)
                local isRF=pcall(function()return self:IsA("RemoteFunction")end)
                if isRE or isRF then
                    local rname=tostring(self):match("^(.+) %(") or tostring(self)
                    local lw=extractWord({...})
                    if lw and self:IsA("RemoteEvent") then answerRemote=self end
                    if isAnswerRemote(rname) and botEnabled and currentWord~="" then
                        if self:IsA("RemoteEvent") then answerRemote=self;return _old(self,currentWord) end
                    end
                end
            end
            return _old(self,...)
        end))
    end)
    return ok
end

local SV_KEYS={"word","spell","current","target","prompt","letter","round","question","answer","display","show","text","challenge","bean","scary"}
local function isSVKey(name)
    local n=name:lower()
    for _,k in ipairs(SV_KEYS) do if n:find(k,1,true) then return true end end
    return false
end

local _watchedSV={}
local function watchSV(sv)
    if _watchedSV[sv] then return end;_watchedSV[sv]=true
    sv.Changed:Connect(function(v)if looksLikeWord(v) then onWordFound(v) end end)
    if looksLikeWord(sv.Value) then onWordFound(sv.Value) end
end

local function hookSVs(root)
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("StringValue") and isSVKey(obj.Name) then watchSV(obj) end
    end
end

local function startLiveWatch()
    for _,root in ipairs(SCAN_ROOTS) do
        pcall(function()
            root.ChildAdded:Connect(function(ch)
                if ch:IsA("RemoteEvent") then task.wait();hookOne(ch)
                elseif ch:IsA("RemoteFunction") then task.wait();hookOneRF(ch) end
            end)
        end)
    end
    game.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then task.wait();hookOne(obj)
        elseif obj:IsA("RemoteFunction") then task.wait();hookOneRF(obj)
        elseif obj:IsA("StringValue") and isSVKey(obj.Name) then watchSV(obj) end
    end)
end

local function scanLabels(root)
    local best,score=nil,-1
    local letters={}
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text~="" then
            local t=obj.Text:match("^%s*(.-)%s*$") or ""
            if looksLikeWord(t) then
                local s=#t+(obj.TextSize>=18 and 50 or 0)
                if s>score then best=t;score=s end
            end
            if t:match("^%a$") then
                letters[#letters+1]={char=t,x=obj.AbsolutePosition.X}
            end
        end
    end
    if #letters>=2 then
        table.sort(letters,function(a,b)return a.x<b.x end)
        local combined=""
        for _,l in ipairs(letters) do combined=combined..l.char end
        if looksLikeWord(combined) and #combined>score then best=combined end
    end
    return best
end

local function getHumanoid()
    local c=LP.Character;return c and c:FindFirstChildOfClass("Humanoid")
end

-- ── RS.Events.GameEvent dedicated hook (Cobalt-style) ───────────────────
local function hookGameEvent()
    local evFolder = RS:FindFirstChild("Events") or RS:WaitForChild("Events",5)
    if not evFolder then return end
    local GameEvent = evFolder:FindFirstChild("GameEvent") or evFolder:WaitForChild("GameEvent",5)
    if not GameEvent then return end

    -- confirmed: GameEvent:FireServer() is used for answer submission
    answerRemote = GameEvent
    table.insert(knownAnswerRemotes, GameEvent)
    evFolder.ChildAdded:Connect(function(ch)
        if ch:IsA("RemoteEvent") and isAnswerRemote(ch.Name) then answerRemote=ch end
    end)

    -- Cobalt-style: wrap every existing connection so we can read the payload
    if getconnections and hookfunction and newcclosure then
        pcall(function()
            for _,conn in ipairs(getconnections(GameEvent.OnClientEvent)) do
                local orig; orig = hookfunction(conn.Function, newcclosure(function(...)
                    local w = extractWord({...})
                    if w then task.spawn(onWordFound, w) end
                    return orig(...)
                end))
            end
        end)
    end

    -- always add our own listener as a fallback / for executors without hookfunction
    hookOne(GameEvent)
end

-- ── RS.Events.MusicEvent dedicated hook (Cobalt-style) ──────────────────
-- MusicEvent carries round-start/stop signals; intercepting it lets us
-- trigger a re-scan for the current word the moment a new round begins.
local function hookMusicEvent()
    local evFolder = RS:FindFirstChild("Events") or RS:WaitForChild("Events",5)
    if not evFolder then return end
    local MusicEvent = evFolder:FindFirstChild("MusicEvent") or evFolder:WaitForChild("MusicEvent",5)
    if not MusicEvent then return end

    local function onMusicPayload(...)
        -- extract any word carried in the payload
        local w = extractWord({...})
        if w then task.spawn(onWordFound, w) end
        -- regardless, re-scan GUI/workspace for the new word
        task.delay(0.15, function()
            if not botEnabled then return end
            local found = scanLabels(PGui) or scanLabels(WS)
            if found then onWordFound(found) end
        end)
    end

    -- Cobalt-style: wrap every existing connection
    if getconnections and hookfunction and newcclosure then
        pcall(function()
            for _,conn in ipairs(getconnections(MusicEvent.OnClientEvent)) do
                local orig; orig = hookfunction(conn.Function, newcclosure(function(...)
                    onMusicPayload(...)
                    return orig(...)
                end))
            end
        end)
    end

    -- confirmed: MusicEvent:FireServer() is also used — register as fallback answer remote
    table.insert(knownAnswerRemotes, MusicEvent)

    -- plain listener fallback
    MusicEvent.OnClientEvent:Connect(onMusicPayload)
end

-- ── RS.Events.UIEvent dedicated hook (Cobalt-style) ─────────────────────
-- UIEvent pushes display updates to the client; the word to spell is
-- almost always embedded here as a plain string argument.
local function hookUIEvent()
    local evFolder = RS:FindFirstChild("Events") or RS:WaitForChild("Events",5)
    if not evFolder then return end
    local UIEvent = evFolder:FindFirstChild("UIEvent") or evFolder:WaitForChild("UIEvent",5)
    if not UIEvent then return end

    local function onUIPayload(...)
        local w = extractWord({...})
        if w then task.spawn(onWordFound, w) end
    end

    -- Cobalt-style: wrap every existing connection
    if getconnections and hookfunction and newcclosure then
        pcall(function()
            for _,conn in ipairs(getconnections(UIEvent.OnClientEvent)) do
                local orig; orig = hookfunction(conn.Function, newcclosure(function(...)
                    onUIPayload(...)
                    return orig(...)
                end))
            end
        end)
    end

    -- plain listener fallback
    UIEvent.OnClientEvent:Connect(onUIPayload)
end

task.spawn(hookGameEvent)
task.spawn(hookMusicEvent)
task.spawn(hookUIEvent)

hookIncoming()
for _,root in ipairs(SCAN_ROOTS) do pcall(function()hookSVs(root)end) end
local _h2ok=installNamecallHook()
startLiveWatch()

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h=char:FindFirstChildOfClass("Humanoid");if not h then return end
    pcall(function()h.WalkSpeed=16;h.JumpPower=50;h.JumpHeight=18 end)
    task.wait(0.5)
    for _,r in ipairs(char:GetDescendants()) do
        if r:IsA("RemoteEvent") then hookOne(r)
        elseif r:IsA("RemoteFunction") then hookOneRF(r) end
    end
end)

UIS.JumpRequest:Connect(function()
    if infJump then
        local h=getHumanoid()
        if h then pcall(function()h:ChangeState(Enum.HumanoidStateType.Jumping)end) end
    end
end)

local _afkT=0
RunService.Heartbeat:Connect(function()
    if antiAFK then
        _afkT=_afkT+1
        if _afkT>=3600 then _afkT=0;pcall(function()VirtualUser:CaptureController()end) end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if botEnabled then
            local w=scanLabels(PGui) or scanLabels(WS)
            if w then onWordFound(w) end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════
--  RAYFIELD-STYLE GUI
-- ═══════════════════════════════════════════════════════════════════════

local old=PGui:FindFirstChild("__PrepSpellHub__")
if old then old:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="__PrepSpellHub__";SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true;SG.DisplayOrder=999
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local guiParent=PGui
pcall(function()if gethui then guiParent=gethui() end end)
SG.Parent=guiParent

local R={
    BG    =Color3.fromRGB(25,  25,  35),
    SIDE  =Color3.fromRGB(20,  20,  28),
    PANEL =Color3.fromRGB(32,  32,  44),
    CARD  =Color3.fromRGB(38,  38,  52),
    BLUE  =Color3.fromRGB(64, 156, 255),
    BLUE2 =Color3.fromRGB(100,180,255),
    WHITE =Color3.fromRGB(255,255,255),
    OFFWH =Color3.fromRGB(200,205,220),
    MUTED =Color3.fromRGB(110,115,140),
    GREEN =Color3.fromRGB(52, 211,153),
    RED   =Color3.fromRGB(239, 68, 68),
    GRAY  =Color3.fromRGB(55,  58, 75),
    BORDER=Color3.fromRGB(48,  50, 68),
}

local TI15=TweenInfo.new(0.15,Enum.EasingStyle.Quad)
local TI25=TweenInfo.new(0.25,Enum.EasingStyle.Quart)

local function corner(p,r)local c=Instance.new("UICorner",p);c.CornerRadius=UDim.new(0,r or 8);return c end
local function stroke(p,col,t)local s=Instance.new("UIStroke",p);s.Color=col;s.Thickness=t or 1;return s end
local function pad(p,x,y)local d=Instance.new("UIPadding",p);d.PaddingLeft=UDim.new(0,x);d.PaddingRight=UDim.new(0,x);d.PaddingTop=UDim.new(0,y or x);d.PaddingBottom=UDim.new(0,y or x) end

local WIN=Instance.new("Frame",SG)
WIN.Name="Win";WIN.Size=UDim2.new(0,520,0,400)
WIN.Position=UDim2.new(0.5,-260,0.5,-200)
WIN.BackgroundColor3=R.BG;WIN.BorderSizePixel=0;WIN.Active=true
WIN.ClipsDescendants=true
corner(WIN,12);stroke(WIN,R.BORDER,1.5)

local TOP=Instance.new("Frame",WIN)
TOP.Size=UDim2.new(1,0,0,50);TOP.BackgroundColor3=R.SIDE;TOP.BorderSizePixel=0

local accent=Instance.new("Frame",TOP)
accent.Size=UDim2.new(0,3,0,28);accent.Position=UDim2.new(0,14,0.5,-14)
accent.BackgroundColor3=R.BLUE;accent.BorderSizePixel=0;corner(accent,2)

local hubLbl=Instance.new("TextLabel",TOP)
hubLbl.Size=UDim2.new(0,200,0,20);hubLbl.Position=UDim2.new(0,24,0.5,-16)
hubLbl.BackgroundTransparency=1;hubLbl.Text="Spelling Bee Hub"
hubLbl.TextColor3=R.WHITE;hubLbl.Font=Enum.Font.GothamBold;hubLbl.TextSize=14
hubLbl.TextXAlignment=Enum.TextXAlignment.Left

local subLbl=Instance.new("TextLabel",TOP)
subLbl.Size=UDim2.new(0,220,0,14);subLbl.Position=UDim2.new(0,24,0.5,4)
subLbl.BackgroundTransparency=1;subLbl.Text=GAME_NAME.."  •  v2.3"
subLbl.TextColor3=R.MUTED;subLbl.Font=Enum.Font.Gotham;subLbl.TextSize=10
subLbl.TextXAlignment=Enum.TextXAlignment.Left

local closeBtn=Instance.new("TextButton",TOP)
closeBtn.Size=UDim2.new(0,24,0,24);closeBtn.Position=UDim2.new(1,-36,0.5,-12)
closeBtn.BackgroundColor3=Color3.fromRGB(200,60,60);closeBtn.Text="✕"
closeBtn.TextColor3=R.WHITE;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=11
closeBtn.BorderSizePixel=0;corner(closeBtn,6)
closeBtn.MouseButton1Click:Connect(function()SG:Destroy()end)

local minBtn=Instance.new("TextButton",TOP)
minBtn.Size=UDim2.new(0,24,0,24);minBtn.Position=UDim2.new(1,-66,0.5,-12)
minBtn.BackgroundColor3=R.PANEL;minBtn.Text="─"
minBtn.TextColor3=R.MUTED;minBtn.Font=Enum.Font.GothamBold;minBtn.TextSize=11
minBtn.BorderSizePixel=0;corner(minBtn,6)

local _d,_dx,_dy,_wx,_wy=false,0,0,0,0
TOP.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        _d=true;_dx=i.Position.X;_dy=i.Position.Y
        _wx=WIN.AbsolutePosition.X;_wy=WIN.AbsolutePosition.Y
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

local MAIN=Instance.new("Frame",WIN)
MAIN.Size=UDim2.new(1,0,1,-50);MAIN.Position=UDim2.new(0,0,0,50)
MAIN.BackgroundTransparency=1;MAIN.BorderSizePixel=0

local _minimised=false
minBtn.MouseButton1Click:Connect(function()
    _minimised=not _minimised
    MAIN.Visible=not _minimised
    WIN.Size=_minimised and UDim2.new(0,520,0,50) or UDim2.new(0,520,0,400)
end)

local SIDE=Instance.new("Frame",MAIN)
SIDE.Size=UDim2.new(0,130,1,0);SIDE.BackgroundColor3=R.SIDE;SIDE.BorderSizePixel=0
local sideList=Instance.new("UIListLayout",SIDE)
sideList.Padding=UDim.new(0,4);sideList.SortOrder=Enum.SortOrder.LayoutOrder
pad(SIDE,8,10)

local CONT=Instance.new("ScrollingFrame",MAIN)
CONT.Size=UDim2.new(1,-130,1,0);CONT.Position=UDim2.new(0,130,0,0)
CONT.BackgroundColor3=R.BG;CONT.BorderSizePixel=0
CONT.ScrollBarThickness=3;CONT.ScrollBarImageColor3=R.BLUE
CONT.CanvasSize=UDim2.new(0,0,0,0);CONT.AutomaticCanvasSize=Enum.AutomaticSize.Y
local contList=Instance.new("UIListLayout",CONT)
contList.Padding=UDim.new(0,8);contList.SortOrder=Enum.SortOrder.LayoutOrder
pad(CONT,12,12)

local tabs={}
local activeTab=nil

local function makeTab(name,icon)
    local btn=Instance.new("TextButton",SIDE)
    btn.Size=UDim2.new(1,0,0,36);btn.BackgroundColor3=R.SIDE
    btn.Text="";btn.BorderSizePixel=0;corner(btn,8)

    local icL=Instance.new("TextLabel",btn)
    icL.Size=UDim2.new(0,20,1,0);icL.Position=UDim2.new(0,10,0,0)
    icL.BackgroundTransparency=1;icL.Text=icon
    icL.TextColor3=R.MUTED;icL.Font=Enum.Font.Gotham;icL.TextSize=14

    local nmL=Instance.new("TextLabel",btn)
    nmL.Size=UDim2.new(1,-36,1,0);nmL.Position=UDim2.new(0,34,0,0)
    nmL.BackgroundTransparency=1;nmL.Text=name
    nmL.TextColor3=R.MUTED;nmL.Font=Enum.Font.GothamBold;nmL.TextSize=12
    nmL.TextXAlignment=Enum.TextXAlignment.Left

    local bar=Instance.new("Frame",btn)
    bar.Size=UDim2.new(0,3,0,20);bar.Position=UDim2.new(0,0,0.5,-10)
    bar.BackgroundColor3=R.BLUE;bar.BorderSizePixel=0;corner(bar,2)
    bar.Visible=false

    local frame=Instance.new("Frame",CONT)
    frame.Size=UDim2.new(1,0,0,0);frame.AutomaticSize=Enum.AutomaticSize.Y
    frame.BackgroundTransparency=1;frame.BorderSizePixel=0;frame.Visible=false
    local fl=Instance.new("UIListLayout",frame)
    fl.Padding=UDim.new(0,8);fl.SortOrder=Enum.SortOrder.LayoutOrder

    local tabData={btn=btn,frame=frame,bar=bar,icL=icL,nmL=nmL}
    tabs[name]=tabData

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            local a=tabs[activeTab]
            a.frame.Visible=false;a.bar.Visible=false
            TW:Create(a.btn,TI15,{BackgroundColor3=R.SIDE}):Play()
            TW:Create(a.icL,TI15,{TextColor3=R.MUTED}):Play()
            TW:Create(a.nmL,TI15,{TextColor3=R.MUTED}):Play()
        end
        activeTab=name
        frame.Visible=true;bar.Visible=true
        TW:Create(btn,TI15,{BackgroundColor3=R.PANEL}):Play()
        TW:Create(icL,TI15,{TextColor3=R.BLUE}):Play()
        TW:Create(nmL,TI15,{TextColor3=R.WHITE}):Play()
        CONT.CanvasPosition=Vector2.new(0,0)
    end)
    return frame
end

local tabBot   =makeTab("Bot",   "⌨")
local tabStats =makeTab("Stats", "📊")
local tabPlayer=makeTab("Player","👤")

local function secLabel(parent,txt)
    local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,0,0,20);f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1;l.Text=txt:upper()
    l.TextColor3=R.BLUE;l.Font=Enum.Font.GothamBold;l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left
end

local function makeToggle(parent,title,sub,default,callback)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,0,0,50);f.BackgroundColor3=R.PANEL;f.BorderSizePixel=0;corner(f,8)
    stroke(f,R.BORDER,1)
    local tL=Instance.new("TextLabel",f);tL.Size=UDim2.new(1,-70,0,18);tL.Position=UDim2.new(0,14,0,9)
    tL.BackgroundTransparency=1;tL.Text=title
    tL.TextColor3=R.WHITE;tL.Font=Enum.Font.GothamBold;tL.TextSize=13;tL.TextXAlignment=Enum.TextXAlignment.Left
    local sL=Instance.new("TextLabel",f);sL.Size=UDim2.new(1,-70,0,13);sL.Position=UDim2.new(0,14,0,29)
    sL.BackgroundTransparency=1;sL.Text=sub
    sL.TextColor3=R.MUTED;sL.Font=Enum.Font.Gotham;sL.TextSize=10;sL.TextXAlignment=Enum.TextXAlignment.Left
    local st=default
    local pill=Instance.new("TextButton",f);pill.Size=UDim2.new(0,44,0,24);pill.Position=UDim2.new(1,-58,0.5,-12)
    pill.BackgroundColor3=st and R.BLUE or R.GRAY;pill.Text="";pill.BorderSizePixel=0;corner(pill,12)
    local kn=Instance.new("Frame",pill);kn.Size=UDim2.new(0,18,0,18)
    kn.Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    kn.BackgroundColor3=R.WHITE;kn.BorderSizePixel=0;corner(kn,9)
    pill.MouseButton1Click:Connect(function()
        st=not st
        TW:Create(pill,TI15,{BackgroundColor3=st and R.BLUE or R.GRAY}):Play()
        TW:Create(kn,TI15,{Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
        callback(st)
    end)
end

local function makeBtn(parent,txt,col,cb)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,0,0,38);b.BackgroundColor3=col or R.BLUE
    b.Text=txt;b.TextColor3=R.WHITE;b.Font=Enum.Font.GothamBold;b.TextSize=13
    b.BorderSizePixel=0;corner(b,8)
    b.MouseButton1Click:Connect(cb)
    b.MouseEnter:Connect(function()TW:Create(b,TI15,{BackgroundColor3=R.BLUE2}):Play()end)
    b.MouseLeave:Connect(function()TW:Create(b,TI15,{BackgroundColor3=col or R.BLUE}):Play()end)
    return b
end

-- ── Bot Tab ────────────────────────────────────────────────────────────
secLabel(tabBot,"Current Word")

local wordCard=Instance.new("Frame",tabBot)
wordCard.Size=UDim2.new(1,0,0,72);wordCard.BackgroundColor3=R.PANEL;wordCard.BorderSizePixel=0;corner(wordCard,8)
stroke(wordCard,R.BORDER,1)
local wLine=Instance.new("Frame",wordCard);wLine.Size=UDim2.new(1,0,0,2)
wLine.BackgroundColor3=R.BLUE;wLine.BorderSizePixel=0

nWord=Instance.new("TextLabel",wordCard)
nWord.Size=UDim2.new(1,-110,0,36);nWord.Position=UDim2.new(0,14,0,14)
nWord.BackgroundTransparency=1;nWord.Text="—"
nWord.TextColor3=R.WHITE;nWord.Font=Enum.Font.GothamBold;nWord.TextSize=28
nWord.TextXAlignment=Enum.TextXAlignment.Left

local stPill=Instance.new("Frame",wordCard)
stPill.Size=UDim2.new(0,80,0,24);stPill.Position=UDim2.new(1,-90,0,10)
stPill.BackgroundColor3=Color3.fromRGB(15,45,30);stPill.BorderSizePixel=0;corner(stPill,6)
statusDot=Instance.new("Frame",stPill)
statusDot.Size=UDim2.new(0,7,0,7);statusDot.Position=UDim2.new(0,8,0.5,-3.5)
statusDot.BackgroundColor3=R.GREEN;statusDot.BorderSizePixel=0;corner(statusDot,4)
statusLbl=Instance.new("TextLabel",stPill)
statusLbl.Size=UDim2.new(1,-20,1,0);statusLbl.Position=UDim2.new(0,20,0,0)
statusLbl.BackgroundTransparency=1;statusLbl.Text="Active"
statusLbl.TextColor3=R.GREEN;statusLbl.Font=Enum.Font.GothamBold;statusLbl.TextSize=9
statusLbl.TextXAlignment=Enum.TextXAlignment.Left

local lastLbl=Instance.new("TextLabel",wordCard)
lastLbl.Size=UDim2.new(1,-16,0,12);lastLbl.Position=UDim2.new(0,14,1,-16)
lastLbl.BackgroundTransparency=1;lastLbl.Text="Waiting for word..."
lastLbl.TextColor3=R.MUTED;lastLbl.Font=Enum.Font.Gotham;lastLbl.TextSize=9
lastLbl.TextXAlignment=Enum.TextXAlignment.Left

onWordFound=function(w)
    w=w:lower()
    if w==currentWord then return end
    currentWord=w
    if nWord then
        nWord.Text=w:upper()
        lastLbl.Text="["..( answerRemote and "remote" or "scan").."]  "..w:upper().."  •  "..(botEnabled and "Submitting..." or "Bot off")
    end
    if botEnabled then task.delay(submitDelay,function()submitAnswer(w)end) end
end

secLabel(tabBot,"Controls")

makeToggle(tabBot,"Auto Type","Automatically answers each round",true,function(v)
    botEnabled=v
    TW:Create(statusDot,TI15,{BackgroundColor3=v and R.GREEN or R.GRAY}):Play()
    TW:Create(statusLbl,TI15,{TextColor3=v and R.GREEN or R.MUTED}):Play()
    statusLbl.Text=v and "Active" or "Paused"
    TW:Create(stPill,TI15,{BackgroundColor3=v and Color3.fromRGB(15,45,30) or R.PANEL}):Play()
end)

local delCard=Instance.new("Frame",tabBot)
delCard.Size=UDim2.new(1,0,0,46);delCard.BackgroundColor3=R.PANEL;delCard.BorderSizePixel=0;corner(delCard,8)
stroke(delCard,R.BORDER,1)
local delTxt=Instance.new("TextLabel",delCard)
delTxt.Size=UDim2.new(0.5,0,1,0);delTxt.Position=UDim2.new(0,14,0,0)
delTxt.BackgroundTransparency=1;delTxt.Text="Submit Delay"
delTxt.TextColor3=R.OFFWH;delTxt.Font=Enum.Font.GothamBold;delTxt.TextSize=12;delTxt.TextXAlignment=Enum.TextXAlignment.Left
local dV=50
local delVal=Instance.new("TextLabel",delCard)
delVal.Size=UDim2.new(0,42,0,24);delVal.Position=UDim2.new(1,-128,0.5,-12)
delVal.BackgroundColor3=R.CARD;delVal.BorderSizePixel=0;corner(delVal,6)
delVal.Text="50ms";delVal.TextColor3=R.BLUE;delVal.Font=Enum.Font.GothamBold;delVal.TextSize=11
local function mkDB(sign,xp)
    local b=Instance.new("TextButton",delCard)
    b.Size=UDim2.new(0,28,0,28);b.Position=xp
    b.BackgroundColor3=R.CARD;b.Text=sign;b.TextColor3=R.WHITE
    b.Font=Enum.Font.GothamBold;b.TextSize=14;b.BorderSizePixel=0;corner(b,7)
    b.MouseButton1Click:Connect(function()
        dV=math.clamp(dV+(sign=="-" and -10 or 10),0,2000)
        delVal.Text=dV.."ms";submitDelay=dV/1000
    end)
end
mkDB("-",UDim2.new(1,-90,0.5,-14));mkDB("+",UDim2.new(1,-56,0.5,-14))

secLabel(tabBot,"Actions")
makeBtn(tabBot,"Submit Word Now",R.BLUE,function()
    if currentWord=="" then notify("No word","Nothing captured yet.",3);return end
    submitAnswer(currentWord);notify("Submitted!",currentWord:upper(),2)
end)
makeBtn(tabBot,"Re-scan Remotes",R.CARD,function()
    answerRemote=nil;hookIncoming()
    for _,root in ipairs(SCAN_ROOTS) do pcall(function()hookSVs(root)end) end
    notify("Done","Hooks refreshed.",2)
end)

-- ── Stats Tab ──────────────────────────────────────────────────────────
secLabel(tabStats,"Session Stats")

local statsGrid=Instance.new("Frame",tabStats)
statsGrid.Size=UDim2.new(1,0,0,0);statsGrid.AutomaticSize=Enum.AutomaticSize.Y
statsGrid.BackgroundTransparency=1;statsGrid.BorderSizePixel=0
local sg=Instance.new("UIGridLayout",statsGrid)
sg.CellSize=UDim2.new(0.5,-4,0,64);sg.CellPadding=UDim2.new(0,8,0,8)
sg.SortOrder=Enum.SortOrder.LayoutOrder

local SDEFS={
    {"Words","0",R.BLUE,"⌨"},
    {"Avg WPM","0",R.BLUE2,"⚡"},
    {"Best WPM","0",Color3.fromRGB(251,191,36),"🏆"},
    {"Mistakes","0",Color3.fromRGB(239,68,68),"✗"},
    {"Accuracy","100%",R.GREEN,"✓"},
}
local statRefs={}
for _,d in ipairs(SDEFS) do
    local lbl,init,col,icon=d[1],d[2],d[3],d[4]
    local f=Instance.new("Frame",statsGrid);f.BackgroundColor3=R.PANEL;f.BorderSizePixel=0;corner(f,8);stroke(f,R.BORDER,1)
    local strip=Instance.new("Frame",f);strip.Size=UDim2.new(1,0,0,2);strip.BackgroundColor3=col;strip.BorderSizePixel=0
    local ic=Instance.new("TextLabel",f);ic.Size=UDim2.new(0,16,0,14);ic.Position=UDim2.new(0,10,0,10)
    ic.BackgroundTransparency=1;ic.Text=icon;ic.TextColor3=col;ic.Font=Enum.Font.Gotham;ic.TextSize=12
    local vl=Instance.new("TextLabel",f);vl.Size=UDim2.new(1,-8,0,26);vl.Position=UDim2.new(0,10,0,24)
    vl.BackgroundTransparency=1;vl.Text=init;vl.TextColor3=R.WHITE;vl.Font=Enum.Font.GothamBold;vl.TextSize=22
    vl.TextXAlignment=Enum.TextXAlignment.Left
    local nl=Instance.new("TextLabel",f);nl.Size=UDim2.new(1,-8,0,12);nl.Position=UDim2.new(0,10,1,-14)
    nl.BackgroundTransparency=1;nl.Text=lbl:upper();nl.TextColor3=R.MUTED;nl.Font=Enum.Font.GothamBold;nl.TextSize=8
    nl.TextXAlignment=Enum.TextXAlignment.Left
    statRefs[#statRefs+1]=vl
end
nWords=statRefs[1];nWpm=statRefs[2];nBest=statRefs[3];nMist=statRefs[4];nAcc=statRefs[5]

updateStats=function()
    local wpm=getWPM();if wpm>bestWPM then bestWPM=wpm end
    local acc=wordsTyped==0 and 100 or math.floor(((wordsTyped-mistakes)/wordsTyped)*100)
    nWords.Text=tostring(wordsTyped);nWpm.Text=tostring(wpm)
    nBest.Text=tostring(bestWPM);nMist.Text=tostring(mistakes);nAcc.Text=acc.."%"
end

secLabel(tabStats,"Actions")
makeBtn(tabStats,"Reset Session Stats",R.CARD,function()
    sessionStart=os.clock();wordsTyped=0;bestWPM=0;mistakes=0;updateStats()
    notify("Reset","Stats cleared.",2)
end)

-- ── Player Tab ─────────────────────────────────────────────────────────
secLabel(tabPlayer,"Toggles")
makeToggle(tabPlayer,"Infinite Jump","Hold jump to keep flying",false,function(v)infJump=v end)
makeToggle(tabPlayer,"Anti-AFK","Prevents automatic kick",false,function(v)antiAFK=v end)

secLabel(tabPlayer,"Actions")
makeBtn(tabPlayer,"Reset Character",Color3.fromRGB(120,30,30),function()
    local h=getHumanoid();if h then pcall(function()h.Health=0 end) end
end)

-- activate Bot tab by default
tabs["Bot"].btn.MouseButton1Click:Fire()

notify("Spelling Bee Hub",GAME_NAME.." — Ready",4)
if not _h2ok then notify("Spelling Bee Hub","Event hooks only (no __namecall)",3) end
