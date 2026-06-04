-- 🤖 CLAUDE HUB LITE — self-contained, paste & run (Delta iPad friendly)
local ok,err=pcall(function()
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local SG=game:GetService("StarterGui")
local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui",10)
local GUIP=(gethui and gethui()) or PG

local C={BG=Color3.fromRGB(15,13,20),SIDE=Color3.fromRGB(10,9,14),CARD=Color3.fromRGB(32,28,42),
DARK=Color3.fromRGB(7,6,10),BORDER=Color3.fromRGB(46,40,60),ACC=Color3.fromRGB(217,119,66),
ACC2=Color3.fromRGB(235,150,100),WHITE=Color3.fromRGB(245,242,236),TEXT=Color3.fromRGB(196,190,200),
MUTED=Color3.fromRGB(108,100,120),GREEN=Color3.fromRGB(52,211,153),RED=Color3.fromRGB(244,63,94)}
local FB,FN=Enum.Font.GothamBold,Enum.Font.Gotham
local function tw(i,p,t) TS:Create(i,TweenInfo.new(t or .16),p):Play() end
local function cor(i,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=i end
local function str(i,c) local s=Instance.new("UIStroke");s.Color=c or C.BORDER;s.Parent=i;return s end
local function F(p,sz,po,c) local f=Instance.new("Frame");f.Size=sz;f.Position=po or UDim2.new();f.BackgroundColor3=c or C.CARD;f.BorderSizePixel=0;f.Parent=p;return f end
local function L(p,t,sz,po,c,fs,ft) local l=Instance.new("TextLabel");l.Size=sz;l.Position=po or UDim2.new();l.BackgroundTransparency=1;l.Text=t;l.TextColor3=c or C.TEXT;l.TextSize=fs or 13;l.Font=ft or FN;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=p;return l end
local function notify(t,m,d) pcall(function() SG:SetCore("SendNotification",{Title=t,Text=m,Duration=d or 3}) end) end
local function B(p,txt,sz,po,col,cb)
 local f=F(p,sz,po,col or C.ACC);cor(f,8)
 local l=Instance.new("TextLabel");l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=C.WHITE;l.TextSize=13;l.Font=FB;l.Parent=f
 local b=Instance.new("TextButton");b.Size=UDim2.new(1,0,1,0);b.BackgroundTransparency=1;b.Text="";b.Parent=f
 b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
 b.MouseEnter:Connect(function() tw(f,{BackgroundColor3=C.ACC2}) end)
 b.MouseLeave:Connect(function() tw(f,{BackgroundColor3=col or C.ACC}) end)
 return f
end

local old=GUIP:FindFirstChild("__CLAUDE_LITE__"); if old then old:Destroy() end
local G=Instance.new("ScreenGui");G.Name="__CLAUDE_LITE__";G.ResetOnSpawn=false;G.IgnoreGuiInset=true;G.Parent=GUIP

local W=F(G,UDim2.new(0,560,0,400),UDim2.new(0.5,-280,0.5,-200),C.BG);cor(W,14);str(W,C.BORDER);W.ClipsDescendants=true
-- title bar + Claude logo
local T=F(W,UDim2.new(1,0,0,46),nil,C.SIDE)
local logo=F(T,UDim2.new(0,28,0,28),UDim2.new(0,12,0.5,-14),Color3.fromRGB(240,236,228));cor(logo,8)
local logoL=L(logo,"✳",UDim2.new(1,0,1,0),nil,C.ACC,20,FB);logoL.TextXAlignment=Enum.TextXAlignment.Center
task.spawn(function() while logo.Parent do logoL.Rotation=(logoL.Rotation+2)%360;task.wait(.03) end end)
L(T,"Claude Hub Lite",UDim2.new(0,200,1,0),UDim2.new(0,48,0,0),C.WHITE,15,FB)
local closeB=F(T,UDim2.new(0,28,0,28),UDim2.new(1,-38,0.5,-14),C.CARD);cor(closeB,8)
L(closeB,"✕",UDim2.new(1,0,1,0),nil,C.TEXT,14,FB).TextXAlignment=Enum.TextXAlignment.Center
local cbtn=Instance.new("TextButton");cbtn.Size=UDim2.new(1,0,1,0);cbtn.BackgroundTransparency=1;cbtn.Text="";cbtn.Parent=closeB
cbtn.MouseButton1Click:Connect(function() G:Destroy() end)
-- drag (mouse + touch)
do local drag,sp,wp
 T.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;sp=i.Position;wp=W.Position end end)
 UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-sp;W.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y) end end)
 UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
end

-- sidebar + body
local SIDE=F(W,UDim2.new(0,130,1,-46),UDim2.new(0,0,0,46),C.SIDE)
local sl=Instance.new("UIListLayout");sl.Padding=UDim.new(0,4);sl.Parent=SIDE
local sp2=Instance.new("UIPadding");sp2.PaddingTop=UDim.new(0,8);sp2.PaddingLeft=UDim.new(0,8);sp2.PaddingRight=UDim.new(0,6);sp2.Parent=SIDE
local BODY=F(W,UDim2.new(1,-130,1,-46),UDim2.new(0,130,0,46),C.BG)
local pages,btns,cur={}, {},1
local function show(n) for i,p in pairs(pages) do p.Visible=i==n end for i,b in pairs(btns) do tw(b,{BackgroundColor3=i==n and C.CARD or C.SIDE}) end cur=n end
local function tab(name)
 local n=#pages+1
 local b=F(SIDE,UDim2.new(1,0,0,36),nil,C.SIDE);cor(b,8)
 L(b,name,UDim2.new(1,-10,1,0),UDim2.new(0,10,0,0),C.TEXT,12,FB)
 local tb=Instance.new("TextButton");tb.Size=UDim2.new(1,0,1,0);tb.BackgroundTransparency=1;tb.Text="";tb.Parent=b
 tb.MouseButton1Click:Connect(function() show(n) end)
 btns[n]=b
 local pg=F(BODY,UDim2.new(1,0,1,0),nil,C.BG);pg.Visible=false;pages[n]=pg
 local sf=Instance.new("ScrollingFrame");sf.Size=UDim2.new(1,-12,1,-10);sf.Position=UDim2.new(0,8,0,5);sf.BackgroundTransparency=1;sf.BorderSizePixel=0;sf.ScrollBarThickness=3;sf.ScrollBarImageColor3=C.ACC;sf.CanvasSize=UDim2.new();sf.AutomaticCanvasSize=Enum.AutomaticSize.Y;sf.Parent=pg
 local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,6);ll.Parent=sf
 return sf
end

-- helper: run a require entry
local function runReq(id,method,arg2)
 notify("Claude Hub","Loading…",2)
 task.spawn(function()
  local o,e=pcall(function()
   local m=require(id)
   if method then if arg2 then return m[method](LP.Name,arg2) else return m[method](LP.Name) end
   else return m(LP.Name) end
  end)
  if o then notify("Claude Hub","Loaded ✓",2) else notify("Failed",tostring(e):sub(1,50),4) end
 end)
end

-- MORPHS TAB
local mp=tab("Morphs")
local _,sb=pcall(function() end)
local searchF=F(mp,UDim2.new(1,0,0,34),nil,C.CARD);cor(searchF,8);str(searchF)
local spad=Instance.new("UIPadding");spad.PaddingLeft=UDim.new(0,10);spad.PaddingRight=UDim.new(0,8);spad.Parent=searchF
local sbox=Instance.new("TextBox");sbox.Size=UDim2.new(1,0,1,0);sbox.BackgroundTransparency=1;sbox.PlaceholderText="🔍 Search the morph you want…";sbox.PlaceholderColor3=C.MUTED;sbox.Text="";sbox.TextColor3=C.WHITE;sbox.TextSize=13;sbox.Font=FN;sbox.TextXAlignment=Enum.TextXAlignment.Left;sbox.ClearTextOnFocus=false;sbox.Parent=searchF

local MORPHS={
 {"Locust",75834950186546,"locust"},{"Siren Head",75834950186546,"sirenhead"},{"Siren Head 2",75834950186546,"sirenhead2"},
 {"Cartoon Cat",75834950186546,"cartoon cat"},{"Phen",75834950186546,"phen"},{"Guilt",75834950186546,"guilt"},
 {"Country Road Creature",75834950186546,"country road creature"},{"Dark Siren Head",75834950186546,"dark siren head"},
 {"Shin Sonic",77055143496081,"shin sonic"},{"Small Shin",77055143496081,"small shin"},{"Sonic.EYX",77055143496081,"sonic.eyx"},
 {"Cartoon Cat 2",125056408682835,"cartoon cat"},{"Cartoon Mouse",125056408682835,"cartoon mouse"},{"Cartoon Dog",125056408682835,"cartoon dog"},
 {"Anxious Dog",83656983108761,"anxious dog"},{"Bridge Worm",83656983108761,"bridgeworm"},
 {"Hush",135567062529977,"hush"},{"Long Horse",135567062529977,"long horse"},
 {"Organator",119819780800418,"organator"},{"Death Angel",88521859208314,"death angel"},{"Horror",88521859208314,"horror"},
 {"Aka Manto",88521859208314,"aka manto"},{"Bon the Rabbit",87513953915554,"bontherabbit"},{"Pumpkin Rabbit",87513953915554,"pumpkinrabbit"},
 {"Prototype",73755486018996,"Prototype"},{"CatNap",92610899059557,"catnap"},{"Huggy Wuggy",138108464845575,"huggy wuggy"},
 {"Spider Queen",81801397159119,"spider queen"},{"SCP-096",109044049581210,"scp096reskin"},{"Phen 2",122588279096344,"phen"},
 {"The Extra Slide",95084162409898,"the extra slide"},{"Traffic Light Head",71349190736743,"trafficlight head"},
 {"Siren Head 3",87137179673747,"sirenhead"},{"Suitborn",120865255781665,"suitborn"},
 {"Richard Boderman",125375466492613,"richard boderman"},{"Adult Mimic",130962958730541,"adultmimic"},
}
local cards={}
for _,m in ipairs(MORPHS) do
 local c=F(mp,UDim2.new(1,0,0,38),nil,C.CARD);cor(c,8);str(c)
 local cp=Instance.new("UIPadding");cp.PaddingLeft=UDim.new(0,10);cp.PaddingRight=UDim.new(0,8);cp.Parent=c
 L(c,m[1],UDim2.new(1,-80,1,0),nil,C.WHITE,12,FB)
 B(c,"Morph",UDim2.new(0,70,0,26),UDim2.new(1,-72,0.5,-13),C.ACC,function() runReq(m[2],"MorphMonster",m[3]) end)
 table.insert(cards,{c=c,t=(m[1].." "..m[3]):lower()})
end
sbox:GetPropertyChangedSignal("Text"):Connect(function()
 local q=sbox.Text:lower()
 for _,e in ipairs(cards) do e.c.Visible=(q=="") or (string.find(e.t,q,1,true)~=nil) end
end)

-- EXECUTE TAB
local ep=tab("Execute")
local edW=F(ep,UDim2.new(1,0,0,180),nil,C.DARK);cor(edW,10);str(edW)
local ePad=Instance.new("UIPadding");ePad.PaddingTop=UDim.new(0,8);ePad.PaddingBottom=UDim.new(0,8);ePad.PaddingLeft=UDim.new(0,10);ePad.PaddingRight=UDim.new(0,10);ePad.Parent=edW
local ed=Instance.new("TextBox");ed.Size=UDim2.new(1,0,1,0);ed.BackgroundTransparency=1;ed.MultiLine=true;ed.ClearTextOnFocus=false;ed.TextXAlignment=Enum.TextXAlignment.Left;ed.TextYAlignment=Enum.TextYAlignment.Top;ed.PlaceholderText='-- paste Lua here\nprint("hi")';ed.PlaceholderColor3=C.MUTED;ed.Text="";ed.TextColor3=C.WHITE;ed.TextSize=13;ed.Font=Enum.Font.RobotoMono;ed.Parent=edW
B(ep,"▶ Execute (loadstring)",UDim2.new(1,0,0,38),nil,C.ACC,function()
 if ed.Text=="" then notify("Claude","Empty",2);return end
 local fn,ce=loadstring(ed.Text)
 if not fn then notify("Compile error",tostring(ce):sub(1,50),4);return end
 local o,e=pcall(fn)
 notify("Claude",o and "Executed ✓" or ("Error: "..tostring(e):sub(1,40)),3)
end)
local _,idb=pcall(function() end)
local idW=F(ep,UDim2.new(1,0,0,34),nil,C.CARD);cor(idW,8);str(idW)
local iPad=Instance.new("UIPadding");iPad.PaddingLeft=UDim.new(0,10);iPad.PaddingRight=UDim.new(0,8);iPad.Parent=idW
local idbox=Instance.new("TextBox");idbox.Size=UDim2.new(1,0,1,0);idbox.BackgroundTransparency=1;idbox.PlaceholderText="require asset ID…";idbox.PlaceholderColor3=C.MUTED;idbox.Text="";idbox.TextColor3=C.WHITE;idbox.TextSize=13;idbox.Font=FN;idbox.TextXAlignment=Enum.TextXAlignment.Left;idbox.ClearTextOnFocus=false;idbox.Parent=idW
B(ep,"▶ require(ID)",UDim2.new(1,0,0,38),nil,C.CARD,function()
 local id=tonumber(idbox.Text); if not id then notify("Claude","Numeric ID",2);return end
 task.spawn(function() local o,e=pcall(require,id); notify("Claude",o and "Required ✓" or tostring(e):sub(1,40),3) end)
end)

-- INFO TAB
local ip=tab("Info")
L(ip,"🤖 Claude Hub Lite",UDim2.new(1,0,0,24),nil,C.WHITE,16,FB)
L(ip,"Executor: "..((identifyexecutor and select(1,identifyexecutor())) or "Unknown"),UDim2.new(1,0,0,20),UDim2.new(0,0,0,28),C.ACC2,12,FB)
L(ip,"Game: "..tostring(game.PlaceId),UDim2.new(1,0,0,18),UDim2.new(0,0,0,50),C.TEXT,12)
L(ip,"You: "..LP.Name,UDim2.new(1,0,0,18),UDim2.new(0,0,0,70),C.TEXT,12)
L(ip,"Toggle GUI: press  ]  key",UDim2.new(1,0,0,18),UDim2.new(0,0,0,92),C.MUTED,11)

UIS.InputBegan:Connect(function(i,g) if g then return end if i.KeyCode==Enum.KeyCode.RightBracket or i.KeyCode==Enum.KeyCode.Insert then G.Enabled=not G.Enabled end end)
show(1)
notify("🤖 Claude Hub Lite","Loaded ✓  ("..#MORPHS.." morphs)",4)
end)
if not ok then warn("[Claude Lite] "..tostring(err)); pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="Claude ERROR",Text=tostring(err):sub(1,70),Duration=6}) end) end
