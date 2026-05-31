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
    if #s<2 or #s>100 then return false end
    if not s:match("^%a+$") then return false end
    return not UI_BL[s:lower()]
end

local function extractWord(args)
    for _,v in ipairs(args) do
        if looksLikeWord(v) then return v end
        if type(v)=="table" then for _,tv in pairs(v) do if looksLikeWord(tv) then return tv end end end
        if type(v)=="string" then local w=v:match("([%a][%a]+)") if w and looksLikeWord(w) then return w end end
    end
end

local SCAN_ROOTS={RS,WS,game:GetService("ReplicatedFirst"),PGui,LP}
pcall(function()table.insert(SCAN_ROOTS,LP.Backpack)end)
pcall(function()table.insert(SCAN_ROOTS,LP.Character)end)

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

local CHAR_MS=0.040
local function humanTypeBox(box,word)
    box.Text="";box:CaptureFocus();task.wait(0.035)
    for i=1,#word do box.Text=word:sub(1,i);task.wait(CHAR_MS) end
    task.wait(0.035);box:ReleaseFocus(true)
end

local function fireAnswer(word)
    task.wait(#word*CHAR_MS)
    local r=findAnswerRemote()
    if r then pcall(function()r:FireServer(word)end);return true end
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
    for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible and obj.Text~="" then
            local t=obj.Text:match("^%s*(.-)%s*$") or ""
            if looksLikeWord(t) then
                local s=#t+(obj.TextSize>=20 and 50 or 0)
                if s>score then best=t;score=s end
            end
        end
    end
    return best
end

local function getHumanoid()
    local c=LP.Character;return c and c:FindFirstChildOfClass("Humanoid")
end

hookIncoming()
for _,root in ipairs(SCAN_ROOTS) do pcall(function()hookSVs(root)end) end
local _h2ok=installNamecallHook()
startLiveWatch()

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
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

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local h=char:FindFirstChildOfClass("Humanoid");if not h then return end
    pcall(function()h.WalkSpeed=16;h.JumpPower=50;h.JumpHeight=18 end)
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
--  PREPPY HUB GUI
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

-- colour palette
local C={
    BG    =Color3.fromRGB(13, 13, 20),
    PANEL =Color3.fromRGB(22, 22, 34),
    CARD  =Color3.fromRGB(30, 30, 46),
    CARD2 =Color3.fromRGB(38, 38, 58),
    PINK  =Color3.fromRGB(236, 72, 153),
    PINK2 =Color3.fromRGB(251,113,180),
    PINK3 =Color3.fromRGB(253,164,202),
    WHITE =Color3.fromRGB(255,255,255),
    OFFWH =Color3.fromRGB(220,215,235),
    MUTED =Color3.fromRGB(148,140,170),
    GREEN =Color3.fromRGB(52, 211,153),
    RED   =Color3.fromRGB(239, 68, 68),
    GOLD  =Color3.fromRGB(251,191, 36),
    GRAY  =Color3.fromRGB(55,  55, 78),
    STROKE=Color3.fromRGB(60,  45, 80),
}

local W=isMobile and 318 or 340
local TI15=TweenInfo.new(0.15)
local TI3 =TweenInfo.new(0.3,Enum.EasingStyle.Quart)

local function corner(p,r)Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 10)end
local function stroke(p,col,t)local s=Instance.new("UIStroke",p);s.Color=col;s.Thickness=t or 1;return s end
local function pad(p,x,y)local d=Instance.new("UIPadding",p);d.PaddingLeft=UDim.new(0,x);d.PaddingRight=UDim.new(0,x);d.PaddingTop=UDim.new(0,y);d.PaddingBottom=UDim.new(0,y)end

-- ── main window ────────────────────────────────────────────────────────
local WIN=Instance.new("Frame")
WIN.Name="Win";WIN.Size=UDim2.new(0,W,0,0)
WIN.AutomaticSize=Enum.AutomaticSize.Y
WIN.Position=isMobile and UDim2.new(0.5,-W/2,0,44) or UDim2.new(0.5,-W/2,0.5,-260)
WIN.BackgroundColor3=C.BG;WIN.BorderSizePixel=0;WIN.Active=true;WIN.Parent=SG
corner(WIN,16);stroke(WIN,C.STROKE,1.5)

-- ── header ─────────────────────────────────────────────────────────────
local HDR=Instance.new("Frame",WIN)
HDR.Size=UDim2.new(1,0,0,64);HDR.BackgroundColor3=C.PANEL;HDR.BorderSizePixel=0
corner(HDR,16)
-- bottom cover so only top corners round
local hfix=Instance.new("Frame",HDR);hfix.Size=UDim2.new(1,0,0,16)
hfix.Position=UDim2.new(0,0,1,-16);hfix.BackgroundColor3=C.PANEL;hfix.BorderSizePixel=0

-- pink left accent bar
local acc=Instance.new("Frame",HDR)
acc.Size=UDim2.new(0,3,0,34);acc.Position=UDim2.new(0,14,0.5,-17)
acc.BackgroundColor3=C.PINK;acc.BorderSizePixel=0;corner(acc,4)

-- logo / title block
local logoF=Instance.new("Frame",HDR)
logoF.Size=UDim2.new(0,26,0,26);logoF.Position=UDim2.new(0,24,0.5,-13)
logoF.BackgroundColor3=C.PINK;logoF.BorderSizePixel=0;corner(logoF,7)
local logoTxt=Instance.new("TextLabel",logoF)
logoTxt.Size=UDim2.new(1,0,1,0);logoTxt.BackgroundTransparency=1
logoTxt.Text="P";logoTxt.TextColor3=C.WHITE
logoTxt.Font=Enum.Font.GothamBold;logoTxt.TextSize=14

local hubName=Instance.new("TextLabel",HDR)
hubName.Size=UDim2.new(0,160,0,18);hubName.Position=UDim2.new(0,56,0,13)
hubName.BackgroundTransparency=1;hubName.Text="Preppy Hub"
hubName.TextColor3=C.WHITE;hubName.Font=Enum.Font.GothamBold
hubName.TextSize=15;hubName.TextXAlignment=Enum.TextXAlignment.Left

local gameLbl=Instance.new("TextLabel",HDR)
gameLbl.Size=UDim2.new(0,200,0,13);gameLbl.Position=UDim2.new(0,56,0,33)
gameLbl.BackgroundTransparency=1;gameLbl.Text=GAME_NAME.."  •  v2.3"
gameLbl.TextColor3=C.MUTED;gameLbl.Font=Enum.Font.Gotham
gameLbl.TextSize=10;gameLbl.TextXAlignment=Enum.TextXAlignment.Left

-- version badge
local badgeF=Instance.new("Frame",HDR)
badgeF.Size=UDim2.new(0,44,0,18);badgeF.Position=UDim2.new(1,-86,0.5,-9)
badgeF.BackgroundColor3=Color3.fromRGB(80,20,60);badgeF.BorderSizePixel=0;corner(badgeF,5)
local badgeTxt=Instance.new("TextLabel",badgeF)
badgeTxt.Size=UDim2.new(1,0,1,0);badgeTxt.BackgroundTransparency=1
badgeTxt.Text=isMobile and "iPad" or "PC"
badgeTxt.TextColor3=C.PINK3;badgeTxt.Font=Enum.Font.GothamBold;badgeTxt.TextSize=9

-- close button
local closeBtn=Instance.new("TextButton",HDR)
closeBtn.Size=UDim2.new(0,28,0,28);closeBtn.Position=UDim2.new(1,-40,0.5,-14)
closeBtn.BackgroundColor3=C.RED;closeBtn.Text="✕"
closeBtn.TextColor3=C.WHITE;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=12
closeBtn.BorderSizePixel=0;corner(closeBtn,8)
closeBtn.MouseButton1Click:Connect(function()SG:Destroy()end)

-- drag
local _d,_dx,_dy,_wx,_wy=false,0,0,0,0
HDR.InputBegan:Connect(function(i)
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then
        if _d and t==Enum.UserInputType.Touch then return end
        _d=true;_dx=i.Position.X;_dy=i.Position.Y
        _wx=WIN.AbsolutePosition.X;_wy=WIN.AbsolutePosition.Y
    end
end)
UIS.InputChanged:Connect(function(i)
    if not _d then return end
    local t=i.UserInputType
    if t==Enum.UserInputType.MouseMovement or t==Enum.UserInputType.Touch then
        WIN.Position=UDim2.new(0,_wx+i.Position.X-_dx,0,_wy+i.Position.Y-_dy)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then _d=false end
end)

-- ── body list ──────────────────────────────────────────────────────────
local BODY=Instance.new("Frame",WIN)
BODY.Size=UDim2.new(1,0,0,0);BODY.Position=UDim2.new(0,0,0,64)
BODY.AutomaticSize=Enum.AutomaticSize.Y
BODY.BackgroundTransparency=1;BODY.BorderSizePixel=0
local bList=Instance.new("UIListLayout",BODY)
bList.Padding=UDim.new(0,0);bList.SortOrder=Enum.SortOrder.LayoutOrder
pad(BODY,12,10)

local function divider()
    local f=Instance.new("Frame",BODY);f.Size=UDim2.new(1,0,0,1)
    f.BackgroundColor3=C.STROKE;f.BorderSizePixel=0
end

local function sectionLabel(txt)
    local f=Instance.new("Frame",BODY);f.Size=UDim2.new(1,0,0,26)
    f.BackgroundTransparency=1;f.BorderSizePixel=0
    local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1;l.Text=txt:upper()
    l.TextColor3=C.PINK;l.Font=Enum.Font.GothamBold;l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left
end

-- ── CURRENT WORD banner ────────────────────────────────────────────────
local wordBanner=Instance.new("Frame",BODY)
wordBanner.Size=UDim2.new(1,0,0,70);wordBanner.BackgroundColor3=C.PANEL
wordBanner.BorderSizePixel=0;corner(wordBanner,12)
stroke(wordBanner,C.STROKE,1)

-- gradient-like top pink line
local wTop=Instance.new("Frame",wordBanner)
wTop.Size=UDim2.new(1,0,0,3);wTop.BackgroundColor3=C.PINK;wTop.BorderSizePixel=0
local wTopGrad=Instance.new("UIGradient",wTop)
wTopGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,C.PINK),
    ColorSequenceKeypoint.new(1,C.PINK2)
}

local wordEyebrow=Instance.new("TextLabel",wordBanner)
wordEyebrow.Size=UDim2.new(1,-16,0,14);wordEyebrow.Position=UDim2.new(0,14,0,10)
wordEyebrow.BackgroundTransparency=1;wordEyebrow.Text="CURRENT WORD"
wordEyebrow.TextColor3=C.PINK;wordEyebrow.Font=Enum.Font.GothamBold
wordEyebrow.TextSize=8;wordEyebrow.TextXAlignment=Enum.TextXAlignment.Left

nWord=Instance.new("TextLabel",wordBanner)
nWord.Size=UDim2.new(1,-100,0,32);nWord.Position=UDim2.new(0,14,0,26)
nWord.BackgroundTransparency=1;nWord.Text="—"
nWord.TextColor3=C.WHITE;nWord.Font=Enum.Font.GothamBold
nWord.TextSize=26;nWord.TextXAlignment=Enum.TextXAlignment.Left

-- live status pill (top-right of word banner)
local stPill=Instance.new("Frame",wordBanner)
stPill.Size=UDim2.new(0,72,0,22);stPill.Position=UDim2.new(1,-82,0,10)
stPill.BackgroundColor3=Color3.fromRGB(20,55,35);stPill.BorderSizePixel=0;corner(stPill,6)

statusDot=Instance.new("Frame",stPill)
statusDot.Size=UDim2.new(0,7,0,7);statusDot.Position=UDim2.new(0,8,0.5,-3.5)
statusDot.BackgroundColor3=C.GREEN;statusDot.BorderSizePixel=0;corner(statusDot,4)

statusLbl=Instance.new("TextLabel",stPill)
statusLbl.Size=UDim2.new(1,-20,1,0);statusLbl.Position=UDim2.new(0,20,0,0)
statusLbl.BackgroundTransparency=1;statusLbl.Text="Active"
statusLbl.TextColor3=C.GREEN;statusLbl.Font=Enum.Font.GothamBold;statusLbl.TextSize=9
statusLbl.TextXAlignment=Enum.TextXAlignment.Left

-- last word small label
local lastLbl=Instance.new("TextLabel",wordBanner)
lastLbl.Size=UDim2.new(1,-16,0,12);lastLbl.Position=UDim2.new(0,14,1,-18)
lastLbl.BackgroundTransparency=1;lastLbl.Text="Waiting for word..."
lastLbl.TextColor3=C.MUTED;lastLbl.Font=Enum.Font.Gotham;lastLbl.TextSize=9
lastLbl.TextXAlignment=Enum.TextXAlignment.Left

-- update word display to also refresh lastLbl
local _origOnWord=onWordFound
onWordFound=function(w)
    w=w:lower()
    if w==currentWord then return end
    currentWord=w
    if nWord then
        nWord.Text=w:upper()
        lastLbl.Text="Last: "..w:upper().."  •  "..(botEnabled and "Submitting..." or "Bot off")
    end
    if botEnabled then task.delay(submitDelay,function()submitAnswer(w)end) end
end

-- spacer
local sp1=Instance.new("Frame",BODY);sp1.Size=UDim2.new(1,0,0,8);sp1.BackgroundTransparency=1

-- ── AUTO TYPE TOGGLE ───────────────────────────────────────────────────
sectionLabel("Bot Controls")

local togRow0=Instance.new("Frame",BODY)
togRow0.Size=UDim2.new(1,0,0,54);togRow0.BackgroundColor3=C.PANEL
togRow0.BorderSizePixel=0;corner(togRow0,12);stroke(togRow0,C.STROKE,1)

local togIcon=Instance.new("Frame",togRow0)
togIcon.Size=UDim2.new(0,34,0,34);togIcon.Position=UDim2.new(0,12,0.5,-17)
togIcon.BackgroundColor3=Color3.fromRGB(60,20,50);togIcon.BorderSizePixel=0;corner(togIcon,9)
local togIconL=Instance.new("TextLabel",togIcon)
togIconL.Size=UDim2.new(1,0,1,0);togIconL.BackgroundTransparency=1
togIconL.Text="⌨";togIconL.TextColor3=C.PINK;togIconL.Font=Enum.Font.Gotham;togIconL.TextSize=17

local togTitleL=Instance.new("TextLabel",togRow0)
togTitleL.Size=UDim2.new(0,120,0,18);togTitleL.Position=UDim2.new(0,54,0,9)
togTitleL.BackgroundTransparency=1;togTitleL.Text="Auto Type"
togTitleL.TextColor3=C.WHITE;togTitleL.Font=Enum.Font.GothamBold
togTitleL.TextSize=13;togTitleL.TextXAlignment=Enum.TextXAlignment.Left

local togSubL=Instance.new("TextLabel",togRow0)
togSubL.Size=UDim2.new(0,140,0,12);togSubL.Position=UDim2.new(0,54,0,29)
togSubL.BackgroundTransparency=1;togSubL.Text="Auto-answers each round"
togSubL.TextColor3=C.MUTED;togSubL.Font=Enum.Font.Gotham
togSubL.TextSize=9;togSubL.TextXAlignment=Enum.TextXAlignment.Left

local togSt=true
local togPill=Instance.new("TextButton",togRow0)
togPill.Size=UDim2.new(0,50,0,26);togPill.Position=UDim2.new(1,-62,0.5,-13)
togPill.BackgroundColor3=C.PINK;togPill.Text="";togPill.BorderSizePixel=0;corner(togPill,13)

local togKnob=Instance.new("Frame",togPill)
togKnob.Size=UDim2.new(0,20,0,20);togKnob.Position=UDim2.new(1,-22,0.5,-10)
togKnob.BackgroundColor3=C.WHITE;togKnob.BorderSizePixel=0;corner(togKnob,10)

togPill.MouseButton1Click:Connect(function()
    togSt=not togSt;botEnabled=togSt
    TW:Create(togPill,TI15,{BackgroundColor3=togSt and C.PINK or C.GRAY}):Play()
    TW:Create(togKnob,TI15,{Position=togSt and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)}):Play()
    if statusDot then
        TW:Create(statusDot,TI15,{BackgroundColor3=togSt and C.GREEN or C.GRAY}):Play()
        TW:Create(statusLbl,TI15,{TextColor3=togSt and C.GREEN or C.MUTED}):Play()
        statusLbl.Text=togSt and "Active" or "Paused"
        local pillBg=Color3.fromRGB(togSt and 20 or 40,togSt and 55 or 40,togSt and 35 or 40)
        TW:Create(stPill,TI15,{BackgroundColor3=pillBg}):Play()
    end
end)

local sp2=Instance.new("Frame",BODY);sp2.Size=UDim2.new(1,0,0,6);sp2.BackgroundTransparency=1

-- delay row
local delRow=Instance.new("Frame",BODY)
delRow.Size=UDim2.new(1,0,0,44);delRow.BackgroundColor3=C.PANEL
delRow.BorderSizePixel=0;corner(delRow,12);stroke(delRow,C.STROKE,1)

local delLblL=Instance.new("TextLabel",delRow)
delLblL.Size=UDim2.new(0.55,0,1,0);delLblL.Position=UDim2.new(0,14,0,0)
delLblL.BackgroundTransparency=1;delLblL.Text="Submit Delay"
delLblL.TextColor3=C.OFFWH;delLblL.Font=Enum.Font.GothamBold;delLblL.TextSize=12
delLblL.TextXAlignment=Enum.TextXAlignment.Left

local delVal=Instance.new("TextLabel",delRow)
delVal.Size=UDim2.new(0,36,0,22);delVal.Position=UDim2.new(1,-120,0.5,-11)
delVal.BackgroundColor3=C.CARD2;delVal.BorderSizePixel=0;corner(delVal,6)
delVal.Text="50ms";delVal.TextColor3=C.PINK2;delVal.Font=Enum.Font.GothamBold;delVal.TextSize=11

local dV=50
local function mkDelBtn(sign,xPos)
    local b=Instance.new("TextButton",delRow)
    b.Size=UDim2.new(0,28,0,26);b.Position=xPos
    b.BackgroundColor3=C.CARD2;b.Text=sign;b.TextColor3=C.WHITE
    b.Font=Enum.Font.GothamBold;b.TextSize=15;b.BorderSizePixel=0;corner(b,7)
    b.MouseButton1Click:Connect(function()
        dV=math.clamp(dV+(sign=="-" and -10 or 10),0,2000)
        delVal.Text=dV.."ms";submitDelay=dV/1000
    end)
end
mkDelBtn("-",UDim2.new(1,-86,0.5,-13))
mkDelBtn("+",UDim2.new(1,-52,0.5,-13))

local sp3=Instance.new("Frame",BODY);sp3.Size=UDim2.new(1,0,0,10);sp3.BackgroundTransparency=1
divider()
local sp4=Instance.new("Frame",BODY);sp4.Size=UDim2.new(1,0,0,10);sp4.BackgroundTransparency=1

-- ── STATS GRID ─────────────────────────────────────────────────────────
sectionLabel("Session Stats")
local sp5=Instance.new("Frame",BODY);sp5.Size=UDim2.new(1,0,0,4);sp5.BackgroundTransparency=1

local statsOuter=Instance.new("Frame",BODY)
statsOuter.Size=UDim2.new(1,0,0,0);statsOuter.AutomaticSize=Enum.AutomaticSize.Y
statsOuter.BackgroundTransparency=1;statsOuter.BorderSizePixel=0

local statsGrid=Instance.new("UIGridLayout",statsOuter)
statsGrid.CellSize=UDim2.new(0.5,-4,0,58);statsGrid.CellPadding=UDim2.new(0,8,0,8)
statsGrid.SortOrder=Enum.SortOrder.LayoutOrder

local STAT_DEFS={
    {"Words","0",C.PINK,   "⌨"},
    {"Avg WPM","0",C.PINK2, "⚡"},
    {"Best WPM","0",C.GOLD, "🏆"},
    {"Mistakes","0",C.RED,  "✗"},
    {"Accuracy","100%",C.GREEN,"✓"},
}

local statRefs={}
for _,d in ipairs(STAT_DEFS) do
    local label,init,col,icon=d[1],d[2],d[3],d[4]
    local f=Instance.new("Frame",statsOuter);f.BackgroundColor3=C.PANEL;f.BorderSizePixel=0;corner(f,12)
    stroke(f,C.STROKE,1)

    -- top colour strip
    local strip=Instance.new("Frame",f);strip.Size=UDim2.new(1,0,0,3)
    strip.BackgroundColor3=col;strip.BorderSizePixel=0;corner(strip,3)
    local stripFix=Instance.new("Frame",strip);stripFix.Size=UDim2.new(1,0,0.5,0);stripFix.Position=UDim2.new(0,0,0.5,0)
    stripFix.BackgroundColor3=col;stripFix.BorderSizePixel=0

    local iconL=Instance.new("TextLabel",f)
    iconL.Size=UDim2.new(0,18,0,14);iconL.Position=UDim2.new(0,10,0,10)
    iconL.BackgroundTransparency=1;iconL.Text=icon
    iconL.TextColor3=col;iconL.Font=Enum.Font.Gotham;iconL.TextSize=12

    local valL=Instance.new("TextLabel",f)
    valL.Size=UDim2.new(1,-10,0,24);valL.Position=UDim2.new(0,10,0,24)
    valL.BackgroundTransparency=1;valL.Text=init
    valL.TextColor3=C.WHITE;valL.Font=Enum.Font.GothamBold;valL.TextSize=20
    valL.TextXAlignment=Enum.TextXAlignment.Left

    local nameL=Instance.new("TextLabel",f)
    nameL.Size=UDim2.new(1,-10,0,12);nameL.Position=UDim2.new(0,10,1,-16)
    nameL.BackgroundTransparency=1;nameL.Text=label:upper()
    nameL.TextColor3=C.MUTED;nameL.Font=Enum.Font.GothamBold;nameL.TextSize=8
    nameL.TextXAlignment=Enum.TextXAlignment.Left

    statRefs[#statRefs+1]=valL
end

nWords=statRefs[1];nWpm=statRefs[2];nBest=statRefs[3];nMist=statRefs[4];nAcc=statRefs[5]

-- override updateStats to use raw value labels
local function updateStats2()
    local wpm=getWPM()
    if wpm>bestWPM then bestWPM=wpm end
    local acc=wordsTyped==0 and 100 or math.floor(((wordsTyped-mistakes)/wordsTyped)*100)
    nWords.Text=tostring(wordsTyped)
    nWpm.Text=tostring(wpm)
    nBest.Text=tostring(bestWPM)
    nMist.Text=tostring(mistakes)
    nAcc.Text=acc.."%"
end
updateStats=updateStats2

local sp6=Instance.new("Frame",BODY);sp6.Size=UDim2.new(1,0,0,10);sp6.BackgroundTransparency=1
divider()
local sp7=Instance.new("Frame",BODY);sp7.Size=UDim2.new(1,0,0,10);sp7.BackgroundTransparency=1

-- ── ACTION BUTTONS ─────────────────────────────────────────────────────
sectionLabel("Actions")
local sp8=Instance.new("Frame",BODY);sp8.Size=UDim2.new(1,0,0,4);sp8.BackgroundTransparency=1

local function actionBtn(txt,col,textCol,cb)
    local b=Instance.new("TextButton",BODY)
    b.Size=UDim2.new(1,0,0,42);b.BackgroundColor3=col
    b.Text=txt;b.TextColor3=textCol or C.WHITE
    b.Font=Enum.Font.GothamBold;b.TextSize=13;b.BorderSizePixel=0;corner(b,12)
    b.MouseButton1Click:Connect(cb)
    local sp=Instance.new("Frame",BODY);sp.Size=UDim2.new(1,0,0,6);sp.BackgroundTransparency=1
    return b
end

actionBtn("▶  Submit Word Now",C.PINK,C.WHITE,function()
    if currentWord=="" then notify("No word","Nothing captured yet.",3);return end
    submitAnswer(currentWord);notify("Submitted!",currentWord:upper(),2)
end)

actionBtn("🔄  Re-scan All Remotes",C.CARD2,C.OFFWH,function()
    answerRemote=nil;hookIncoming()
    for _,root in ipairs(SCAN_ROOTS) do pcall(function()hookSVs(root)end) end
    notify("Re-scanned","Hooks refreshed.",2)
end)

actionBtn("📊  Reset Session Stats",C.CARD2,C.OFFWH,function()
    sessionStart=os.clock();wordsTyped=0;bestWPM=0;mistakes=0;updateStats()
    notify("Reset","Stats cleared.",2)
end)

divider()
local sp9=Instance.new("Frame",BODY);sp9.Size=UDim2.new(1,0,0,10);sp9.BackgroundTransparency=1

-- ── PLAYER ─────────────────────────────────────────────────────────────
sectionLabel("Player")
local sp10=Instance.new("Frame",BODY);sp10.Size=UDim2.new(1,0,0,4);sp10.BackgroundTransparency=1

local function playerTog(txt,sub,icon,def,cb)
    local f=Instance.new("Frame",BODY)
    f.Size=UDim2.new(1,0,0,52);f.BackgroundColor3=C.PANEL;f.BorderSizePixel=0
    corner(f,12);stroke(f,C.STROKE,1)

    local ic=Instance.new("Frame",f);ic.Size=UDim2.new(0,32,0,32);ic.Position=UDim2.new(0,12,0.5,-16)
    ic.BackgroundColor3=C.CARD2;ic.BorderSizePixel=0;corner(ic,8)
    local icL=Instance.new("TextLabel",ic);icL.Size=UDim2.new(1,0,1,0);icL.BackgroundTransparency=1
    icL.Text=icon;icL.TextColor3=C.MUTED;icL.Font=Enum.Font.Gotham;icL.TextSize=16

    local tL=Instance.new("TextLabel",f);tL.Size=UDim2.new(0.55,0,0,18);tL.Position=UDim2.new(0,52,0,9)
    tL.BackgroundTransparency=1;tL.Text=txt
    tL.TextColor3=C.WHITE;tL.Font=Enum.Font.GothamBold;tL.TextSize=12;tL.TextXAlignment=Enum.TextXAlignment.Left
    local sL=Instance.new("TextLabel",f);sL.Size=UDim2.new(0.55,0,0,12);sL.Position=UDim2.new(0,52,0,29)
    sL.BackgroundTransparency=1;sL.Text=sub
    sL.TextColor3=C.MUTED;sL.Font=Enum.Font.Gotham;sL.TextSize=9;sL.TextXAlignment=Enum.TextXAlignment.Left

    local st=def
    local pill=Instance.new("TextButton",f);pill.Size=UDim2.new(0,44,0,24);pill.Position=UDim2.new(1,-56,0.5,-12)
    pill.BackgroundColor3=st and C.GREEN or C.GRAY;pill.Text="";pill.BorderSizePixel=0;corner(pill,12)
    local kn=Instance.new("Frame",pill);kn.Size=UDim2.new(0,18,0,18)
    kn.Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)
    kn.BackgroundColor3=C.WHITE;kn.BorderSizePixel=0;corner(kn,9)
    pill.MouseButton1Click:Connect(function()
        st=not st
        TW:Create(pill,TI15,{BackgroundColor3=st and C.GREEN or C.GRAY}):Play()
        TW:Create(kn,TI15,{Position=st and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        cb(st)
    end)

    local spf=Instance.new("Frame",BODY);spf.Size=UDim2.new(1,0,0,6);spf.BackgroundTransparency=1
end

playerTog("Infinite Jump","Hold jump to fly","↑",false,function(v)infJump=v end)
playerTog("Anti-AFK","Prevents auto-kick","⏱",false,function(v)antiAFK=v end)

actionBtn("💀  Reset Character",Color3.fromRGB(100,20,20),C.OFFWH,function()
    local h=getHumanoid();if h then pcall(function()h.Health=0 end) end
end)

-- footer
local footerF=Instance.new("Frame",BODY);footerF.Size=UDim2.new(1,0,0,28);footerF.BackgroundTransparency=1
local footerL=Instance.new("TextLabel",footerF)
footerL.Size=UDim2.new(1,0,1,0);footerL.BackgroundTransparency=1
footerL.Text="Preppy Hub  •  Spelling Bee  •  "..(IS_KNOWN and "Known game" or "Universal")
footerL.TextColor3=C.GRAY;footerL.Font=Enum.Font.Gotham;footerL.TextSize=9

local sp_end=Instance.new("Frame",BODY);sp_end.Size=UDim2.new(1,0,0,6);sp_end.BackgroundTransparency=1

notify("Preppy Hub | "..GAME_NAME,"Ready  •  Auto Type ON",4)
if not _h2ok then notify("Preppy Hub","__namecall unavailable — event hooks only",4) end
