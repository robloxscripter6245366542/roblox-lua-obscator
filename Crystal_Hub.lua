-- ================================================================
--   CRYSTAL HUB  ·  v3.1  ·  by void.
--   Frosted glass · Sidebar + Top tab bar · Rayfield-compatible API
-- ================================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local LP               = Players.LocalPlayer
local PGui             = LP:WaitForChild("PlayerGui")

-- ================================================================
-- PERSISTENCE
-- ================================================================
local saved = { themeIdx=1, notif=true, notifDur=4, opacity=5,
                particles=true, toggleKey="RightShift", anims=true,
                execMode="loadstring", autoClear=false, partCount=14 }
pcall(function()
    local DS = game:GetService("DataStoreService"):GetDataStore("CrystalHub_v31")
    local ok,dat = pcall(function() return DS:GetAsync(tostring(LP.UserId)) end)
    if ok and type(dat)=="table" then for k,v in pairs(dat) do saved[k]=v end end
    _G._CHSave = function() pcall(function() DS:SetAsync(tostring(LP.UserId),saved) end) end
end)
local function save() if _G._CHSave then _G._CHSave() end end

-- ================================================================
-- THEMES
-- ================================================================
local THEMES = {
    { name="Ocean",    A=Color3.fromRGB(56,149,255),  BG=Color3.fromRGB(9,12,22),   CD=Color3.fromRGB(16,20,36),  IP=Color3.fromRGB(12,16,30),  T1=Color3.fromRGB(225,238,255), T2=Color3.fromRGB(140,175,230), T3=Color3.fromRGB(80,115,170)  },
    { name="Violet",   A=Color3.fromRGB(150,90,255),  BG=Color3.fromRGB(10,8,20),   CD=Color3.fromRGB(18,14,38),  IP=Color3.fromRGB(12,9,24),   T1=Color3.fromRGB(238,228,255), T2=Color3.fromRGB(175,145,235), T3=Color3.fromRGB(115,90,175)  },
    { name="Rose",     A=Color3.fromRGB(255,90,140),  BG=Color3.fromRGB(20,8,14),   CD=Color3.fromRGB(36,14,26),  IP=Color3.fromRGB(22,8,16),   T1=Color3.fromRGB(255,228,238), T2=Color3.fromRGB(230,160,190), T3=Color3.fromRGB(170,90,125)  },
    { name="Emerald",  A=Color3.fromRGB(50,210,140),  BG=Color3.fromRGB(7,16,14),   CD=Color3.fromRGB(13,28,24),  IP=Color3.fromRGB(8,16,14),   T1=Color3.fromRGB(220,250,240), T2=Color3.fromRGB(130,210,180), T3=Color3.fromRGB(75,155,125)  },
    { name="Amber",    A=Color3.fromRGB(255,185,50),  BG=Color3.fromRGB(18,14,6),   CD=Color3.fromRGB(30,24,10),  IP=Color3.fromRGB(20,15,6),   T1=Color3.fromRGB(255,248,225), T2=Color3.fromRGB(230,195,120), T3=Color3.fromRGB(165,130,65)  },
    { name="Ice",      A=Color3.fromRGB(80,215,255),  BG=Color3.fromRGB(8,14,20),   CD=Color3.fromRGB(14,22,34),  IP=Color3.fromRGB(9,14,21),   T1=Color3.fromRGB(215,245,255), T2=Color3.fromRGB(120,200,230), T3=Color3.fromRGB(70,145,175)  },
    { name="Sunset",   A=Color3.fromRGB(255,120,70),  BG=Color3.fromRGB(18,8,4),    CD=Color3.fromRGB(32,14,8),   IP=Color3.fromRGB(20,8,4),    T1=Color3.fromRGB(255,235,225), T2=Color3.fromRGB(235,170,140), T3=Color3.fromRGB(175,100,75)  },
    { name="Graphite", A=Color3.fromRGB(160,170,195), BG=Color3.fromRGB(14,14,16),  CD=Color3.fromRGB(24,24,28),  IP=Color3.fromRGB(16,16,18),  T1=Color3.fromRGB(235,235,245), T2=Color3.fromRGB(165,165,185), T3=Color3.fromRGB(105,105,125) },
}

local function calcWinTr() return 0.30 + (10-(saved.opacity or 5))*0.055 end
local TR = { win=calcWinTr(), card=0.52, inp=0.40, btn=0.16, sbOn=0.28 }
local T  = THEMES[math.clamp(saved.themeIdx or 1,1,#THEMES)]

-- ================================================================
-- TWEEN INFOS
-- ================================================================
local TF  = TweenInfo.new(0.13, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TM  = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TS  = TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TSP = TweenInfo.new(0.32, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TBN = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local function tw(i,t,p) TweenService:Create(i,t,p):Play() end

-- ================================================================
-- RECOLOR REGISTRY
-- ================================================================
local bgReg, txReg = {}, {}
local allScrolls   = {}
local function rBg(i,k) if i and k then table.insert(bgReg,{i=i,k=k}) end end
local function rTx(i,k) if i and k then table.insert(txReg,{i=i,k=k}) end end
local function applyTheme(th,anim)
    for _,e in ipairs(bgReg) do
        if e.i and e.i.Parent and th[e.k] then
            if anim then tw(e.i,TM,{BackgroundColor3=th[e.k]}) else e.i.BackgroundColor3=th[e.k] end
        end
    end
    for _,e in ipairs(txReg) do
        if e.i and e.i.Parent and th[e.k] then e.i.TextColor3=th[e.k] end
    end
    for _,s in ipairs(allScrolls) do if s and s.Parent then s.ScrollBarImageColor3=th.A end end
end

-- ================================================================
-- PRIMITIVES
-- ================================================================
local function corner(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=p;return c end
local function stroke(p,col,tr,t2) local s=Instance.new("UIStroke");s.Color=col;s.Transparency=tr or 0.80;s.Thickness=t2 or 1;s.Parent=p;return s end
local function mkF(par,sz,pos,col,tr)
    local f=Instance.new("Frame");f.Size=sz;f.Position=pos;f.BackgroundColor3=col;f.BackgroundTransparency=tr or 0;f.BorderSizePixel=0;f.Parent=par;return f
end
local function mkL(par,txt,fnt,fsz,col,pos,sz,xa,wrap)
    local l=Instance.new("TextLabel");l.Text=txt;l.Font=fnt or Enum.Font.Gotham;l.TextSize=fsz or 13;l.TextColor3=col;l.BackgroundTransparency=1;l.Position=pos;l.Size=sz;l.TextXAlignment=xa or Enum.TextXAlignment.Left;l.TextWrapped=wrap or false;l.BorderSizePixel=0;l.Parent=par;return l
end
local function mkB(par,sz,pos,col,tr)
    local b=Instance.new("TextButton");b.Text="";b.Size=sz;b.Position=pos;b.BackgroundColor3=col;b.BackgroundTransparency=tr or 0;b.BorderSizePixel=0;b.AutoButtonColor=false;b.Parent=par;return b
end
local function shine(p,h) return mkF(p,UDim2.new(1,0,0,h or 1),UDim2.new(0,0,0,0),Color3.new(1,1,1),0.82) end
local function glassCard(par,sz,pos)
    local f=mkF(par,sz,pos,T.CD,TR.card);rBg(f,"CD");corner(f,10);stroke(f,Color3.new(1,1,1),0.88);shine(f);return f
end

-- draw 2×2 icon grid inside a frame (like the reference app icon)
local function drawGridIcon(par, sz, pos, col, tr)
    local host = mkF(par, sz, pos, col, 1)
    local d = sz.X.Offset or 22; local s = math.floor(d*0.32); local g = math.floor(d*0.10)
    local offsets = {{0,0},{s+g,0},{0,s+g},{s+g,s+g}}
    for _,o in ipairs(offsets) do
        local dot = mkF(host, UDim2.new(0,s,0,s), UDim2.new(0,o[1]+math.floor((d-2*s-g)/2),0,o[2]+math.floor((d-2*s-g)/2)), col, tr or 0.25)
        corner(dot, 3); rBg(dot, "A")
    end
    return host
end

-- ================================================================
-- NOTIFICATION SYSTEM
-- ================================================================
local notifStack = {}
local NW,NH,NGAP,NR,NB = 268,62,7,16,22
local SG

local function pushNotif(title,body,dur)
    if not saved.notif then return end
    dur = dur or saved.notifDur or 4
    for _,n in ipairs(notifStack) do
        n._y=n._y-(NH+NGAP); tw(n.f,TM,{Position=UDim2.new(1,-(NW+NR),1,n._y)})
    end
    local y0=-(NH+NB)
    local nf=mkF(SG,UDim2.new(0,NW,0,NH),UDim2.new(1,NW+NR,1,y0),T.CD,TR.card)
    nf.ZIndex=50;corner(nf,11);stroke(nf,T.A,0.70,1.5);shine(nf);rBg(nf,"CD")
    local strip=mkF(nf,UDim2.new(0,3,0,NH-12),UDim2.new(0,0,0,6),T.A,0);corner(strip,2);rBg(strip,"A")
    local ico=mkF(nf,UDim2.new(0,30,0,30),UDim2.new(0,9,0.5,-15),T.A,0.68);corner(ico,8);rBg(ico,"A")
    mkL(ico,"◆",Enum.Font.GothamBold,14,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center).ZIndex=51
    local tl=mkL(nf,title,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,48,0,7),UDim2.new(1,-66,0,17));tl.ZIndex=51;rTx(tl,"T1")
    local bl=mkL(nf,body,Enum.Font.Gotham,11,T.T2,UDim2.new(0,48,0,25),UDim2.new(1,-58,0,26),Enum.TextXAlignment.Left,true);bl.ZIndex=51;rTx(bl,"T2")
    local xb=mkB(nf,UDim2.new(0,20,0,20),UDim2.new(1,-24,0,4),T.CD,1);xb.ZIndex=52
    mkL(xb,"✕",Enum.Font.GothamBold,10,T.T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center).ZIndex=52
    local entry={f=nf,_y=y0}; table.insert(notifStack,1,entry)
    tw(nf,TweenInfo.new(0.26,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(1,-(NW+NR),1,y0)})
    local function dismiss()
        for i,n in ipairs(notifStack) do if n==entry then table.remove(notifStack,i);break end end
        for idx,n in ipairs(notifStack) do
            n._y=-(NH+NB)-(idx-1)*(NH+NGAP); tw(n.f,TM,{Position=UDim2.new(1,-(NW+NR),1,n._y)})
        end
        tw(nf,TM,{Position=UDim2.new(1,NW+NR,1,y0)})
        task.delay(0.26,function() if nf.Parent then nf:Destroy() end end)
    end
    xb.MouseButton1Click:Connect(dismiss)
    task.delay(dur,function() if nf and nf.Parent then dismiss() end end)
end

-- ================================================================
-- SCREEN GUI + WINDOW
-- ================================================================
local old=PGui:FindFirstChild("CrystalHub"); if old then old:Destroy() end
SG=Instance.new("ScreenGui")
SG.Name="CrystalHub";SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset=true;SG.Parent=PGui

local WIN_W,WIN_H = 640,490
-- outer glow rings (behind window)
local GLOW1=mkF(SG,UDim2.new(0,WIN_W+48,0,WIN_H+48),UDim2.new(0.5,-(WIN_W+48)/2,0.5,-(WIN_H+48)/2),T.A,0.968)
rBg(GLOW1,"A");corner(GLOW1,24)
local GLOW2=mkF(SG,UDim2.new(0,WIN_W+22,0,WIN_H+22),UDim2.new(0.5,-(WIN_W+22)/2,0.5,-(WIN_H+22)/2),T.A,0.952)
rBg(GLOW2,"A");corner(GLOW2,19)

local Window=mkF(SG,UDim2.new(0,WIN_W,0,WIN_H),UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2),T.BG,TR.win)
rBg(Window,"BG");corner(Window,14);stroke(Window,T.A,0.55,1.5)
Window.ClipsDescendants=true
shine(Window,1)
local bGlow=mkF(Window,UDim2.new(1,0,0,60),UDim2.new(0,0,1,-60),T.A,0.966);rBg(bGlow,"A")
-- sync glow rings to window position
RunService.Heartbeat:Connect(function()
    if not GLOW1.Parent then return end
    local ap=Window.AbsolutePosition
    GLOW1.Position=UDim2.new(0,ap.X-24,0,ap.Y-24)
    GLOW2.Position=UDim2.new(0,ap.X-11,0,ap.Y-11)
end)

-- ================================================================
-- PARTICLES
-- ================================================================
local particles,PART_COUNT = {},saved.partCount or 14
for i=1,PART_COUNT do
    local sz=math.random(3,9)
    local p=mkF(Window,UDim2.new(0,sz,0,sz),UDim2.new(math.random()*0.92,0,math.random()*0.92,0),T.A,0.72+math.random()*0.22)
    p.ZIndex=1;corner(p,sz);rBg(p,"A")
    table.insert(particles,{f=p,speed=0.11+math.random()*0.18,phase=math.random()*math.pi*2,ox=p.Position.X.Scale,oy=p.Position.Y.Scale})
end
local ptTime=0
RunService.Heartbeat:Connect(function(dt)
    if not saved.particles then return end
    ptTime=ptTime+dt
    for _,pt in ipairs(particles) do
        if pt.f and pt.f.Parent then
            pt.f.Position=UDim2.new(math.clamp(pt.ox+math.sin(ptTime*pt.speed+pt.phase)*0.04,0,0.95),0,math.clamp(pt.oy+math.cos(ptTime*pt.speed*0.7+pt.phase)*0.03,0,0.94),0)
        end
    end
end)

local function loopTween(inst,t,props,back)
    local fwd=TweenService:Create(inst,t,props);fwd:Play()
    fwd.Completed:Connect(function()
        if not inst.Parent then return end
        if back then
            local bk=TweenService:Create(inst,t,back);bk:Play()
            bk.Completed:Connect(function() if inst.Parent then loopTween(inst,t,props,back) end end)
        else loopTween(inst,t,props,back) end
    end)
end

-- ================================================================
-- TITLEBAR  — fully transparent, "App Hub" style
-- ================================================================
local TB=mkF(Window,UDim2.new(1,0,0,46),UDim2.new(0,0,0,0),T.BG,1)
mkF(TB,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)

-- gem logo
local gemRing=mkF(TB,UDim2.new(0,28,0,28),UDim2.new(0,13,0.5,-14),T.A,0.82);rBg(gemRing,"A");corner(gemRing,8)
local gem=mkF(TB,UDim2.new(0,22,0,22),UDim2.new(0,16,0.5,-11),T.A,0.22);rBg(gem,"A");corner(gem,7);stroke(gem,T.A,0.45)
mkL(gem,"◆",Enum.Font.GothamBold,12,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center)
loopTween(gemRing,TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.55},{BackgroundTransparency=0.86})

local tTitle=mkL(TB,"Crystal Hub",Enum.Font.GothamBold,15,T.T1,UDim2.new(0,48,0,0),UDim2.new(0,110,1,0));rTx(tTitle,"T1")
local tVer  =mkL(TB,"v3.1",Enum.Font.Gotham,10,T.T3,UDim2.new(0,162,0,0),UDim2.new(0,30,1,0));rTx(tVer,"T3")
local tBy   =mkL(TB,"by void.",Enum.Font.GothamBold,10,T.T3,UDim2.new(0,195,0,0),UDim2.new(0,60,1,0));rTx(tBy,"T3")

-- macOS-style window controls
local function winBtn(xOff,col,cb)
    local b=mkB(TB,UDim2.new(0,13,0,13),UDim2.new(1,xOff,0.5,-6),col,0);corner(b,7)
    b.MouseEnter:Connect(function() tw(b,TF,{BackgroundTransparency=0.30}) end)
    b.MouseLeave:Connect(function() tw(b,TF,{BackgroundTransparency=0}) end)
    b.MouseButton1Click:Connect(cb);return b
end
winBtn(-34,Color3.fromRGB(255,90,90),function()
    tw(Window,TM,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)})
    task.delay(0.25,function() SG:Destroy() end)
end)
local minimized=false
winBtn(-52,Color3.fromRGB(255,190,55),function()
    minimized=not minimized
    tw(Window,TM,{Size=minimized and UDim2.new(0,WIN_W,0,46) or UDim2.new(0,WIN_W,0,WIN_H)})
end)
winBtn(-70,Color3.fromRGB(50,205,115),function() end)

-- ================================================================
-- SIDEBAR  — fully transparent, icon-grid + full name buttons
-- ================================================================
local SBW=204
local Sidebar=mkF(Window,UDim2.new(0,SBW,1,-46),UDim2.new(0,0,0,46),T.BG,1)
mkF(Sidebar,UDim2.new(0,1,1,0),UDim2.new(1,-1,0,0),Color3.new(1,1,1),0.88)

local sbScroll=Instance.new("ScrollingFrame")
sbScroll.Size=UDim2.new(1,0,1,-56);sbScroll.Position=UDim2.new(0,0,0,6)
sbScroll.BackgroundTransparency=1;sbScroll.BorderSizePixel=0
sbScroll.ScrollBarThickness=0;sbScroll.CanvasSize=UDim2.new(0,0,0,0)
sbScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;sbScroll.Parent=Sidebar
Instance.new("UIListLayout",sbScroll).Padding=UDim.new(0,3)
local _sbPad=Instance.new("UIPadding",sbScroll)
_sbPad.PaddingLeft=UDim.new(0,8);_sbPad.PaddingRight=UDim.new(0,8);_sbPad.PaddingTop=UDim.new(0,6)

-- user card
local uCard=glassCard(Sidebar,UDim2.new(1,-16,0,44),UDim2.new(0,8,1,-52))
local uAv=mkF(uCard,UDim2.new(0,30,0,30),UDim2.new(0,7,0.5,-15),T.A,0.62);corner(uAv,8);rBg(uAv,"A")
mkL(uAv,string.sub(LP.Name,1,1):upper(),Enum.Font.GothamBold,14,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center)
local uNameL=mkL(uCard,LP.Name,Enum.Font.GothamBold,11,T.T1,UDim2.new(0,44,0,5),UDim2.new(1,-54,0,16));rTx(uNameL,"T1")
uNameL.TextTruncate=Enum.TextTruncate.AtEnd
-- online status dot
local onDot=mkF(uCard,UDim2.new(0,7,0,7),UDim2.new(0,44,0,24),Color3.fromRGB(80,230,120),0)
corner(onDot,4)
mkL(uCard," online",Enum.Font.Gotham,9,Color3.fromRGB(80,230,120),UDim2.new(0,55,0,22),UDim2.new(1,-66,0,14))

-- ================================================================
-- TOP TAB BAR  (horizontal, above content pages)
-- ================================================================
local TABY = 46  -- starts right below titlebar
local TABH = 38
local TABBAR=mkF(Window,UDim2.new(1,-SBW-3,0,TABH),UDim2.new(0,SBW+1,0,TABY),T.BG,1)
mkF(TABBAR,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),Color3.new(1,1,1),0.88)  -- bottom divider
local tbLL=Instance.new("UIListLayout",TABBAR)
tbLL.FillDirection=Enum.FillDirection.Horizontal;tbLL.Padding=UDim.new(0,0)
tbLL.VerticalAlignment=Enum.VerticalAlignment.Bottom
local tbPad=Instance.new("UIPadding",TABBAR);tbPad.PaddingLeft=UDim.new(0,12)

-- ================================================================
-- CONTENT AREA  (below tab bar)
-- ================================================================
local Content=mkF(Window,UDim2.new(1,-SBW-3,1,-(46+TABH+6)),UDim2.new(0,SBW+1,0,46+TABH+1),T.BG,1)
rBg(Content,"BG");Content.ClipsDescendants=true

-- ================================================================
-- TAB SYSTEM  — sidebar pill + top tab bar + directional slide
-- ================================================================
local pages,navBtns,tabBarBtns={},{},{}
local activeTab,tabCount=1,0

-- icon types for tabs (cycles through some defaults)
local TAB_ICONS = {"grid","list","play","gear","star","code","search","flag"}

local function switchTab(idx)
    if idx==activeTab and tabCount>0 then return end
    local prev=activeTab; activeTab=idx
    for i,pg in ipairs(pages) do
        if i==idx then
            pg.Position=UDim2.new(idx>prev and -0.06 or 0.06,0,0,0);pg.Visible=true
            tw(pg,TweenInfo.new(0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)})
        elseif i==prev then
            local cp=pg;local out=idx>prev and 0.06 or -0.06
            tw(cp,TweenInfo.new(0.18,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(out,0,0,0)})
            task.delay(0.19,function() cp.Visible=false;cp.Position=UDim2.new(0,0,0,0) end)
        else pg.Visible=false;pg.Position=UDim2.new(0,0,0,0) end
    end
    for i,nb in ipairs(navBtns) do
        local on=(i==idx)
        tw(nb.bg,TM,{BackgroundTransparency=on and TR.sbOn or 1})
        nb.bar.Visible=on
        nb.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        nb.lbl.TextColor3=on and T.T1 or T.T2
        tw(nb.dot,TM,{BackgroundTransparency=on and 0.18 or 0.72})
        if nb.iconDots then
            for _,d in ipairs(nb.iconDots) do tw(d,TM,{BackgroundTransparency=on and 0.18 or 0.60}) end
        end
    end
    for i,tb in ipairs(tabBarBtns) do
        local on=(i==idx)
        tb.lbl.Font=on and Enum.Font.GothamBold or Enum.Font.Gotham
        tb.lbl.TextColor3=on and T.T1 or T.T3
        tw(tb.line,TM,{BackgroundTransparency=on and 0 or 1})
    end
end

local function newPage(name)
    tabCount+=1;local idx=tabCount

    -- ── sidebar button (52px, icon grid + full name) ──────────────
    local sbBtn=mkF(sbScroll,UDim2.new(1,0,0,50),UDim2.new(0,0,0,0),T.A,1)
    rBg(sbBtn,"A");corner(sbBtn,10)

    -- left accent bar (visible when active)
    local bar=mkF(sbBtn,UDim2.new(0,3,0,24),UDim2.new(0,0,0.5,-12),T.A,0)
    bar.Visible=(idx==1);corner(bar,2);rBg(bar,"A")

    -- icon: 2×2 dot grid
    local icoHost=mkF(sbBtn,UDim2.new(0,32,0,32),UDim2.new(0,8,0.5,-16),T.A,1)
    local iconDots={}
    local ds,dg=8,3
    for r=0,1 do for c=0,1 do
        local d=mkF(icoHost,UDim2.new(0,ds,0,ds),UDim2.new(0,c*(ds+dg)+4,0,r*(ds+dg)+4),T.A,idx==1 and 0.18 or 0.60)
        corner(d,2);rBg(d,"A");table.insert(iconDots,d)
    end end

    -- name label
    local nl=mkL(sbBtn,name,idx==1 and Enum.Font.GothamBold or Enum.Font.Gotham,13,
        idx==1 and T.T1 or T.T2,UDim2.new(0,46,0,0),UDim2.new(1,-52,1,0))
    rTx(nl,idx==1 and "T1" or "T2")

    -- small accent dot (right side indicator)
    local dot=mkF(sbBtn,UDim2.new(0,6,0,6),UDim2.new(1,-16,0.5,-3),T.A,idx==1 and 0.18 or 0.72)
    corner(dot,3);rBg(dot,"A")

    -- hit area
    local hit=mkB(sbBtn,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)
    hit.MouseEnter:Connect(function()
        if activeTab~=idx then tw(sbBtn,TF,{BackgroundTransparency=0.82}) end
    end)
    hit.MouseLeave:Connect(function()
        if activeTab~=idx then tw(sbBtn,TF,{BackgroundTransparency=1}) end
    end)
    hit.MouseButton1Click:Connect(function() switchTab(idx) end)
    table.insert(navBtns,{bg=sbBtn,bar=bar,lbl=nl,dot=dot,iconDots=iconDots})

    -- ── top tab bar entry ─────────────────────────────────────────
    local tbBtn=mkB(TABBAR,UDim2.new(0,0,1,-2),UDim2.new(0,0,0,0),T.BG,1)
    tbBtn.AutomaticSize=Enum.AutomaticSize.X
    local tbPd=Instance.new("UIPadding",tbBtn)
    tbPd.PaddingLeft=UDim.new(0,14);tbPd.PaddingRight=UDim.new(0,14)
    local tbLbl=mkL(tbBtn,name,idx==1 and Enum.Font.GothamBold or Enum.Font.Gotham,13,
        idx==1 and T.T1 or T.T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center)
    rTx(tbLbl,idx==1 and "T1" or "T3")
    local tbLine=mkF(tbBtn,UDim2.new(1,0,0,2),UDim2.new(0,0,1,0),T.A,idx==1 and 0 or 1)
    rBg(tbLine,"A")
    tbBtn.MouseButton1Click:Connect(function() switchTab(idx) end)
    tbBtn.MouseEnter:Connect(function() if activeTab~=idx then tbLbl.TextColor3=T.T2 end end)
    tbBtn.MouseLeave:Connect(function() if activeTab~=idx then tbLbl.TextColor3=T.T3 end end)
    table.insert(tabBarBtns,{btn=tbBtn,lbl=tbLbl,line=tbLine})

    -- ── page frame ────────────────────────────────────────────────
    local page=mkF(Content,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.BG,1)
    page.Visible=(idx==1);page.ClipsDescendants=true

    -- scroll (fills entire page — ZIndex 1 so custom page content added after sits on top)
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,1,0);scroll.Position=UDim2.new(0,0,0,0)
    scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=3;scroll.ScrollBarImageColor3=T.A
    scroll.CanvasSize=UDim2.new(0,0,0,0);scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.ScrollingDirection=Enum.ScrollingDirection.Y;scroll.Parent=page
    scroll.ZIndex=1
    table.insert(allScrolls,scroll)
    local ll=Instance.new("UIListLayout",scroll);ll.Padding=UDim.new(0,5)
    local lp=Instance.new("UIPadding",scroll)
    lp.PaddingLeft=UDim.new(0,8);lp.PaddingRight=UDim.new(0,8)
    lp.PaddingTop=UDim.new(0,10);lp.PaddingBottom=UDim.new(0,10)

    table.insert(pages,page)
    return page,scroll
end

-- ================================================================
-- ELEMENT BUILDERS
-- ================================================================
local function addSection(scroll,txt)
    local f=mkF(scroll,UDim2.new(1,0,0,22),UDim2.new(0,0,0,0),T.BG,1)
    local lbl=mkL(f,txt:upper(),Enum.Font.GothamBold,9,T.T3,UDim2.new(0,2,0,3),UDim2.new(1,0,0,16))
    rTx(lbl,"T3")
    local tick=mkF(f,UDim2.new(0,20,0,1),UDim2.new(0,0,1,0),T.A,0.40);rBg(tick,"A")
    return f
end

local function addLabel(scroll,txt)
    local f=glassCard(scroll,UDim2.new(1,0,0,0),UDim2.new(0,0,0,0))
    f.AutomaticSize=Enum.AutomaticSize.Y
    local p=Instance.new("UIPadding",f)
    p.PaddingLeft=UDim.new(0,12);p.PaddingRight=UDim.new(0,12);p.PaddingTop=UDim.new(0,9);p.PaddingBottom=UDim.new(0,9)
    local l=mkL(f,txt,Enum.Font.Gotham,12,T.T2,UDim2.new(0,0,0,0),UDim2.new(1,0,0,0),Enum.TextXAlignment.Left,true)
    l.AutomaticSize=Enum.AutomaticSize.Y;rTx(l,"T2");return f
end

local function addButton(scroll,label,desc,callback)
    local f=glassCard(scroll,UDim2.new(1,0,0,60),UDim2.new(0,0,0,0))
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,11),UDim2.new(1,-90,0,16)).TextTruncate=Enum.TextTruncate.AtEnd
    if desc and desc~="" then
        local d=mkL(f,desc,Enum.Font.Gotham,11,T.T3,UDim2.new(0,12,0,28),UDim2.new(1,-90,0,20),Enum.TextXAlignment.Left,true);rTx(d,"T3")
    end
    local btn=mkF(f,UDim2.new(0,62,0,28),UDim2.new(1,-72,0.5,-14),T.A,TR.btn);corner(btn,8);rBg(btn,"A");stroke(btn,T.A,0.50);shine(btn)
    local bl=mkL(btn,"Run",Enum.Font.GothamBold,12,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(bl,"T1")
    local hit=mkB(f,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.CD,1)
    hit.MouseEnter:Connect(function() tw(f,TF,{BackgroundTransparency=TR.card-0.09});tw(btn,TF,{BackgroundTransparency=TR.btn-0.12}) end)
    hit.MouseLeave:Connect(function() tw(f,TF,{BackgroundTransparency=TR.card});tw(btn,TF,{BackgroundTransparency=TR.btn}) end)
    hit.MouseButton1Click:Connect(function()
        pcall(callback);bl.Text="✓";tw(btn,TF,{BackgroundTransparency=0})
        task.delay(1.4,function() bl.Text="Run";tw(btn,TM,{BackgroundTransparency=TR.btn}) end)
    end)
    return f
end

local function addToggle(scroll,label,desc,default,callback)
    local state=default or false
    local f=glassCard(scroll,UDim2.new(1,0,0,60),UDim2.new(0,0,0,0))
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,11),UDim2.new(1,-78,0,16)).TextTruncate=Enum.TextTruncate.AtEnd
    if desc and desc~="" then local d=mkL(f,desc,Enum.Font.Gotham,11,T.T3,UDim2.new(0,12,0,28),UDim2.new(1,-78,0,20),Enum.TextXAlignment.Left,true);rTx(d,"T3") end
    local track=mkF(f,UDim2.new(0,44,0,24),UDim2.new(1,-56,0.5,-12),state and T.A or T.IP,state and 0.10 or TR.inp)
    rBg(track,state and "A" or "IP");corner(track,12)
    local knob=mkF(track,UDim2.new(0,18,0,18),UDim2.new(0,state and 23 or 3,0.5,-9),Color3.new(1,1,1),0.05)
    corner(knob,9);stroke(knob,Color3.new(0,0,0),0.68)
    local hit=mkB(f,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.CD,1)
    hit.MouseEnter:Connect(function() tw(f,TF,{BackgroundTransparency=TR.card-0.09}) end)
    hit.MouseLeave:Connect(function() tw(f,TF,{BackgroundTransparency=TR.card}) end)
    hit.MouseButton1Click:Connect(function()
        state=not state;pcall(callback,state)
        tw(track,TM,{BackgroundColor3=state and T.A or T.IP,BackgroundTransparency=state and 0.10 or TR.inp})
        tw(knob,TSP,{Position=state and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9)})
    end)
    local function setVal(v) state=v;track.BackgroundColor3=v and T.A or T.IP;track.BackgroundTransparency=v and 0.10 or TR.inp;knob.Position=v and UDim2.new(0,23,0.5,-9) or UDim2.new(0,3,0.5,-9) end
    return f,function() return state end,setVal
end

local function addSlider(scroll,label,desc,min,max,default,callback)
    local val=default or min
    local f=glassCard(scroll,UDim2.new(1,0,0,66),UDim2.new(0,0,0,0))
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,10),UDim2.new(1,-66,0,15)).TextTruncate=Enum.TextTruncate.AtEnd
    local vl=mkL(f,tostring(val),Enum.Font.GothamBold,12,T.A,UDim2.new(1,-58,0,10),UDim2.new(0,50,0,15),Enum.TextXAlignment.Right);rTx(vl,"A")
    if desc and desc~="" then local d=mkL(f,desc,Enum.Font.Gotham,10,T.T3,UDim2.new(0,12,0,26),UDim2.new(1,-16,0,14),Enum.TextXAlignment.Left,true);rTx(d,"T3") end
    local trk=mkF(f,UDim2.new(1,-20,0,4),UDim2.new(0,10,0,50),T.IP,TR.inp);rBg(trk,"IP");corner(trk,2)
    local pct=(val-min)/math.max(max-min,1)
    local fill=mkF(trk,UDim2.new(pct,0,1,0),UDim2.new(0,0,0,0),T.A,0.05);rBg(fill,"A");corner(fill,2)
    local thumb=mkF(trk,UDim2.new(0,14,0,14),UDim2.new(pct,-7,0.5,-7),Color3.new(1,1,1),0.05);corner(thumb,7);stroke(thumb,T.A,0.50)
    local dragging=false
    local hitA=mkB(f,UDim2.new(1,-20,0,20),UDim2.new(0,10,0,42),T.CD,1)
    local function setSlider(px)
        local rel=math.clamp((px-trk.AbsolutePosition.X)/math.max(trk.AbsoluteSize.X,1),0,1)
        val=math.floor(min+rel*(max-min)+0.5);pct=(val-min)/math.max(max-min,1)
        vl.Text=tostring(val);tw(fill,TF,{Size=UDim2.new(pct,0,1,0)});tw(thumb,TF,{Position=UDim2.new(pct,-7,0.5,-7)})
        pcall(callback,val)
    end
    hitA.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=true;setSlider(inp.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then setSlider(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    return f,function() return val end
end

local function addDropdown(scroll,label,opts,default,callback)
    local sel=default or opts[1];local open=false
    local f=glassCard(scroll,UDim2.new(1,0,0,60),UDim2.new(0,0,0,0));f.ClipsDescendants=false
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,11),UDim2.new(1,-16,0,16)).TextTruncate=Enum.TextTruncate.AtEnd
    local selF=mkF(f,UDim2.new(1,-20,0,26),UDim2.new(0,10,1,-34),T.IP,TR.inp);rBg(selF,"IP");corner(selF,7);stroke(selF,Color3.new(1,1,1),0.86)
    local selLbl=mkL(selF,sel,Enum.Font.Gotham,12,T.T1,UDim2.new(0,9,0,0),UDim2.new(1,-26,1,0));rTx(selLbl,"T1")
    mkL(selF,"▾",Enum.Font.GothamBold,10,T.T3,UDim2.new(1,-18,0,0),UDim2.new(0,14,1,0),Enum.TextXAlignment.Center)
    local ddH=#opts*28+8
    local dd=mkF(f,UDim2.new(1,-20,0,0),UDim2.new(0,10,1,-34+28),T.CD,TR.card-0.04)
    rBg(dd,"CD");corner(dd,9);stroke(dd,Color3.new(1,1,1),0.80);dd.Visible=false;dd.ZIndex=40
    local ddL=Instance.new("UIListLayout",dd);ddL.Padding=UDim.new(0,2)
    local ddP=Instance.new("UIPadding",dd);ddP.PaddingLeft=UDim.new(0,4);ddP.PaddingRight=UDim.new(0,4);ddP.PaddingTop=UDim.new(0,4)
    for _,opt in ipairs(opts) do
        local ob=mkF(dd,UDim2.new(1,0,0,24),UDim2.new(0,0,0,0),T.IP,opt==sel and 0.50 or 1);corner(ob,6);ob.ZIndex=41
        local ol=mkL(ob,opt,Enum.Font.Gotham,12,opt==sel and T.T1 or T.T2,UDim2.new(0,9,0,0),UDim2.new(1,-9,1,0));ol.ZIndex=41;rTx(ol,"T2")
        local oh=mkB(ob,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.IP,1);oh.ZIndex=42
        oh.MouseEnter:Connect(function() tw(ob,TF,{BackgroundTransparency=0.60}) end)
        oh.MouseLeave:Connect(function() tw(ob,TF,{BackgroundTransparency=opt==sel and 0.50 or 1}) end)
        oh.MouseButton1Click:Connect(function()
            sel=opt;selLbl.Text=opt;pcall(callback,opt)
            open=false;tw(dd,TM,{Size=UDim2.new(1,-20,0,0)});task.delay(0.24,function() dd.Visible=false end)
        end)
    end
    local sh=mkB(selF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.IP,1);sh.ZIndex=5
    sh.MouseButton1Click:Connect(function()
        open=not open;dd.Visible=true;tw(dd,TM,{Size=UDim2.new(1,-20,0,open and ddH or 0)})
        if not open then task.delay(0.25,function() dd.Visible=false end) end
    end)
    return f,function() return sel end
end

local function addTextInput(scroll,label,placeholder,callback)
    local f=glassCard(scroll,UDim2.new(1,0,0,62),UDim2.new(0,0,0,0))
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,10),UDim2.new(1,-16,0,15)).TextTruncate=Enum.TextTruncate.AtEnd
    local ibg=mkF(f,UDim2.new(1,-78,0,28),UDim2.new(0,10,1,-36),T.IP,TR.inp);rBg(ibg,"IP");corner(ibg,7);stroke(ibg,Color3.new(1,1,1),0.86);shine(ibg)
    local p2=Instance.new("UIPadding",ibg);p2.PaddingLeft=UDim.new(0,9)
    local box=Instance.new("TextBox");box.PlaceholderText=placeholder or "Type here...";box.Text=""
    box.Font=Enum.Font.Gotham;box.TextSize=12;box.TextColor3=T.T1;box.PlaceholderColor3=T.T3
    box.BackgroundTransparency=1;box.BorderSizePixel=0;box.Size=UDim2.new(1,0,1,0);box.ClearTextOnFocus=false;box.Parent=ibg;rTx(box,"T1")
    local goF=mkF(f,UDim2.new(0,58,0,28),UDim2.new(1,-68,1,-36),T.A,TR.btn);rBg(goF,"A");corner(goF,7);shine(goF)
    local gl=mkL(goF,"Go",Enum.Font.GothamBold,12,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(gl,"T1")
    local gh=mkB(goF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)
    local function fire() pcall(callback,box.Text);gl.Text="✓";tw(goF,TF,{BackgroundTransparency=0});task.delay(1.2,function() gl.Text="Go";tw(goF,TM,{BackgroundTransparency=TR.btn}) end) end
    gh.MouseButton1Click:Connect(fire);box.FocusLost:Connect(function(e) if e then fire() end end)
    box.Focused:Connect(function() tw(ibg,TF,{BackgroundTransparency=TR.inp-0.12}) end)
    box.FocusLost:Connect(function() tw(ibg,TM,{BackgroundTransparency=TR.inp}) end)
    return f,box
end

local function addKeybind(scroll,label,default,callback)
    local cur=default or "None";local listening=false
    local f=glassCard(scroll,UDim2.new(1,0,0,52),UDim2.new(0,0,0,0))
    mkL(f,label,Enum.Font.GothamBold,13,T.T1,UDim2.new(0,12,0,0),UDim2.new(1,-106,1,0)).TextTruncate=Enum.TextTruncate.AtEnd
    local kbF=mkF(f,UDim2.new(0,84,0,28),UDim2.new(1,-94,0.5,-14),T.IP,TR.inp);rBg(kbF,"IP");corner(kbF,7);stroke(kbF,Color3.new(1,1,1),0.84)
    local kbl=mkL(kbF,cur,Enum.Font.GothamBold,11,T.A,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(kbl,"A")
    local kbH=mkB(kbF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.IP,1)
    kbH.MouseButton1Click:Connect(function() listening=true;kbl.Text="...";tw(kbF,TF,{BackgroundTransparency=TR.inp-0.14}) end)
    UserInputService.InputBegan:Connect(function(inp,gp)
        if not listening or gp then return end
        local k=inp.KeyCode.Name;if k=="Unknown" then return end
        listening=false;cur=k;kbl.Text=k;tw(kbF,TM,{BackgroundTransparency=TR.inp});pcall(callback,k)
    end)
    return f,function() return cur end
end

-- ================================================================
--  YOUR TABS START HERE  — newPage("TabName") → returns page,scroll
--  local Tab = _G.CrystalHub:CreateTab("Combat")
--  Tab:CreateButton({Name="Noclip", Callback=function() end})
-- ================================================================

-- ──── HOME ────
local _,homeScroll=newPage("Home")
addSection(homeScroll,"Welcome")
addLabel(homeScroll,"Crystal Hub  v3.1  by void.\nAdd your own tabs using _G.CrystalHub:CreateTab(\"Name\").\nCompletely transparent — your game shows through.")
addSection(homeScroll,"Quick Actions")
addButton(homeScroll,"Reset Character","Reload your character.",function() LP:LoadCharacter() end)
addButton(homeScroll,"Rejoin Server","Reconnect to this place.",function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end)
addToggle(homeScroll,"Fullbright","Max ambient brightness.",false,function(on)
    local L=game:GetService("Lighting")
    L.Brightness=on and 10 or 1;L.FogEnd=on and 1e6 or 100000
    L.GlobalShadows=not on;L.Ambient=on and Color3.fromRGB(180,180,180) or Color3.fromRGB(127,127,127)
end)
addToggle(homeScroll,"Infinite Jump","Jump while in the air.",false,function(on)
    _G._CH_InfJump=on
    if on and not _G._CH_JumpConn then
        _G._CH_JumpConn=UserInputService.JumpRequest:Connect(function()
            if _G._CH_InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
                LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)
addToggle(homeScroll,"Noclip","Walk through walls.",false,function(on)
    _G._CH_Noclip=on
    if on and not _G._CH_NoclipConn then
        _G._CH_NoclipConn=RunService.Stepped:Connect(function()
            if not _G._CH_Noclip then return end
            local char=LP.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    elseif not on and LP.Character then
        for _,p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end)

-- ──── SCRIPTS (SCRIPTBLOX) ────
-- forward-declared so Scripts tab can load code into Execute tab
local execCodeBox

local _,sbxScroll=newPage("Scripts")
addSection(sbxScroll,"ScriptBlox Search")

local sCard=glassCard(sbxScroll,UDim2.new(1,0,0,50),UDim2.new(0,0,0,0))
local sIbg=mkF(sCard,UDim2.new(1,-80,0,28),UDim2.new(0,10,0.5,-14),T.IP,TR.inp)
rBg(sIbg,"IP");corner(sIbg,7);stroke(sIbg,Color3.new(1,1,1),0.86);shine(sIbg)
local sPad=Instance.new("UIPadding",sIbg);sPad.PaddingLeft=UDim.new(0,9)
local sBox=Instance.new("TextBox");sBox.PlaceholderText="Search scripts..."
sBox.Text="";sBox.Font=Enum.Font.Gotham;sBox.TextSize=12;sBox.TextColor3=T.T1
sBox.PlaceholderColor3=T.T3;sBox.BackgroundTransparency=1;sBox.BorderSizePixel=0
sBox.Size=UDim2.new(1,0,1,0);sBox.ClearTextOnFocus=false;sBox.Parent=sIbg;rTx(sBox,"T1")
local sBtnF=mkF(sCard,UDim2.new(0,62,0,28),UDim2.new(1,-70,0.5,-14),T.A,TR.btn)
rBg(sBtnF,"A");corner(sBtnF,7);shine(sBtnF)
local sBtnL=mkL(sBtnF,"Search",Enum.Font.GothamBold,11,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(sBtnL,"T1")
local sStatus=mkL(sbxScroll,"",Enum.Font.Gotham,11,T.T3,UDim2.new(0,0,0,0),UDim2.new(1,0,0,18),Enum.TextXAlignment.Center)
rTx(sStatus,"T3")
addSection(sbxScroll,"Results")

local function clearResults()
    for _,c in ipairs(sbxScroll:GetChildren()) do if c:GetAttribute("sbxResult") then c:Destroy() end end
end

local function addScriptCard(title,gameName,scriptCode,views,patched,imageUrl,verified,likes)
    local f=glassCard(sbxScroll,UDim2.new(1,0,0,84),UDim2.new(0,0,0,0))
    f:SetAttribute("sbxResult",true)
    -- thumbnail
    local thumb=Instance.new("ImageLabel")
    thumb.Size=UDim2.new(0,52,0,52);thumb.Position=UDim2.new(0,8,0.5,-26)
    thumb.BackgroundColor3=T.CD;thumb.BackgroundTransparency=0.30;thumb.BorderSizePixel=0
    thumb.ScaleType=Enum.ScaleType.Crop;thumb.Image="";thumb.Parent=f;corner(thumb,8);rBg(thumb,"CD")
    local tFall=mkL(thumb,(gameName or "?"):sub(1,1):upper(),Enum.Font.GothamBold,18,T.T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center)
    rTx(tFall,"T3")
    if imageUrl and imageUrl~="" then pcall(function() thumb.Image=imageUrl end) end
    -- patched / verified badge
    if patched then
        local pb=mkF(f,UDim2.new(0,0,0,14),UDim2.new(1,-6,0,6),Color3.fromRGB(220,60,60),0.60)
        pb.AutomaticSize=Enum.AutomaticSize.X;corner(pb,6)
        local pp=Instance.new("UIPadding",pb);pp.PaddingLeft=UDim.new(0,5);pp.PaddingRight=UDim.new(0,5)
        local pl=mkL(pb,"PATCHED",Enum.Font.GothamBold,8,Color3.new(1,1,1),UDim2.new(0,0,0,0),UDim2.new(0,0,1,0));pl.AutomaticSize=Enum.AutomaticSize.X
    elseif verified then
        local vb=mkF(f,UDim2.new(0,0,0,14),UDim2.new(1,-6,0,6),Color3.fromRGB(50,200,120),0.60)
        vb.AutomaticSize=Enum.AutomaticSize.X;corner(vb,6)
        local vp=Instance.new("UIPadding",vb);vp.PaddingLeft=UDim.new(0,5);vp.PaddingRight=UDim.new(0,5)
        local vl=mkL(vb,"✓ VERIFIED",Enum.Font.GothamBold,8,Color3.new(1,1,1),UDim2.new(0,0,0,0),UDim2.new(0,0,1,0));vl.AutomaticSize=Enum.AutomaticSize.X
    end
    local tl=mkL(f,title or "Untitled",Enum.Font.GothamBold,12,T.T1,UDim2.new(0,68,0,10),UDim2.new(1,-142,0,16))
    tl.TextTruncate=Enum.TextTruncate.AtEnd;rTx(tl,"T1")
    local gl=mkL(f,gameName or "Universal",Enum.Font.Gotham,10,T.T2,UDim2.new(0,68,0,27),UDim2.new(1,-148,0,14))
    gl.TextTruncate=Enum.TextTruncate.AtEnd;rTx(gl,"T2")
    mkL(f,"👁 "..tostring(views or 0).."  ♥ "..tostring(likes or 0),Enum.Font.Gotham,9,T.T3,UDim2.new(0,68,0,43),UDim2.new(1,-148,0,14))
    -- ▶ Run
    local eBg=mkF(f,UDim2.new(0,58,0,26),UDim2.new(1,-134,0.5,-13),T.A,TR.btn);rBg(eBg,"A");corner(eBg,7);shine(eBg)
    local eLbl=mkL(eBg,"▶ Run",Enum.Font.GothamBold,11,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(eLbl,"T1")
    local eHit=mkB(eBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)
    eHit.MouseEnter:Connect(function() tw(eBg,TF,{BackgroundTransparency=0}) end)
    eHit.MouseLeave:Connect(function() tw(eBg,TM,{BackgroundTransparency=TR.btn}) end)
    eHit.MouseButton1Click:Connect(function()
        if not scriptCode or scriptCode=="" then pushNotif("Scripts","No script code.",2);return end
        eLbl.Text="✓";tw(eBg,TF,{BackgroundTransparency=0});task.delay(1.4,function() eLbl.Text="▶ Run";tw(eBg,TM,{BackgroundTransparency=TR.btn}) end)
        local fn,ce=loadstring(scriptCode)
        if not fn then pushNotif("Execute Error",tostring(ce):sub(1,80),4);return end
        local ok,err=pcall(fn);if not ok then pushNotif("Execute Error",tostring(err):sub(1,80),4) end
    end)
    -- 📋 Editor
    local lBg=mkF(f,UDim2.new(0,62,0,26),UDim2.new(1,-70,0.5,-13),T.CD,TR.card);rBg(lBg,"CD");corner(lBg,7);stroke(lBg,Color3.new(1,1,1),0.84);shine(lBg)
    local lLbl=mkL(lBg,"📋 Editor",Enum.Font.GothamBold,10,T.T2,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(lLbl,"T2")
    local lHit=mkB(lBg,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.CD,1)
    lHit.MouseEnter:Connect(function() tw(lBg,TF,{BackgroundTransparency=TR.card-0.10}) end)
    lHit.MouseLeave:Connect(function() tw(lBg,TM,{BackgroundTransparency=TR.card}) end)
    lHit.MouseButton1Click:Connect(function()
        if execCodeBox then execCodeBox.Text=scriptCode or "" end
        pushNotif("Scripts","Loaded into Execute tab",2);switchTab(3)
    end)
    return f
end

-- HTTP fetch for Delta iOS (game:HttpGet only)
-- ScriptBlox blocks Roblox's user-agent, so we proxy through allorigins
local _HS2 = game:GetService("HttpService")
local function httpFetch(url)
    -- direct attempt first
    local ok,res = pcall(game.HttpGet, game, url, true)
    if ok and type(res)=="string" and #res>4 then return res end
    -- allorigins.win proxy — fetches on server side, bypasses UA block
    local proxied = "https://api.allorigins.win/raw?url=".._HS2:UrlEncode(url)
    ok,res = pcall(game.HttpGet, game, proxied, true)
    if ok and type(res)=="string" and #res>4 then return res end
    error("fetch failed for "..url)
end

local function fetchScripts(query)
    sStatus.Text="Searching...";clearResults()
    task.spawn(function()
        local HS=game:GetService("HttpService")
        local q=HS:UrlEncode(query or "")
        local url="https://scriptblox.com/api/script/fetch?q="..q.."&page=1&max=20&mode=free"
        local ok,res=pcall(httpFetch,url)
        if not ok then sStatus.Text="HTTP failed: "..tostring(res):sub(1,60);pushNotif("Scripts","Could not reach ScriptBlox",3);return end
        local ok2,data=pcall(function() return HS:JSONDecode(res) end)
        if not ok2 or not data then sStatus.Text="Response parse error.";return end
        local scripts=data.result and data.result.scripts
        if not scripts or #scripts==0 then sStatus.Text="No results for \""..query.."\"";return end
        sStatus.Text="Found "..#scripts.." script"..(#scripts~=1 and "s" or "")
        for _,s in ipairs(scripts) do
            addScriptCard(s.title or "Untitled",(s.game and s.game.name) or "Universal",
                s.script or s.rawscript or "",s.views or 0,s.isPatched or false,
                (s.game and s.game.imageUrl) or "",s.verified or false,s.likes or 0)
        end
    end)
end

local sBtnHit=mkB(sBtnF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)
sBtnHit.MouseButton1Click:Connect(function()
    local q=sBox.Text;if q:len()<1 then pushNotif("Scripts","Enter a search term",2);return end
    tw(sBtnF,TF,{BackgroundTransparency=0});fetchScripts(q)
    task.delay(0.4,function() tw(sBtnF,TM,{BackgroundTransparency=TR.btn}) end)
end)
sBox.FocusLost:Connect(function(enter) if enter and sBox.Text:len()>0 then fetchScripts(sBox.Text) end end)

-- ──── EXECUTE ────
local execPage,_=newPage("Execute")

-- execute elements use ZIndex=2 to sit above the page's scroll frame (ZIndex=1)
local execStatusF=mkF(execPage,UDim2.new(1,-12,0,32),UDim2.new(0,6,1,-40),T.CD,TR.card)
execStatusF.ZIndex=2
rBg(execStatusF,"CD");corner(execStatusF,8);stroke(execStatusF,Color3.new(1,1,1),0.88)
local _esPad=Instance.new("UIPadding",execStatusF);_esPad.PaddingLeft=UDim.new(0,10)
local execStatus=mkL(execStatusF,"Ready  ·  write code above or paste a URL below",Enum.Font.Gotham,10,T.T3,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0))
execStatus.TextTruncate=Enum.TextTruncate.AtEnd;rTx(execStatus,"T3")

local _urlRow=mkF(execPage,UDim2.new(1,-12,0,32),UDim2.new(0,6,1,-78),T.BG,1)
_urlRow.ZIndex=2
local _urlBg=mkF(_urlRow,UDim2.new(1,-76,0,28),UDim2.new(0,0,0,2),T.IP,TR.inp)
rBg(_urlBg,"IP");corner(_urlBg,8);stroke(_urlBg,Color3.new(1,1,1),0.86);shine(_urlBg)
local _urlPad=Instance.new("UIPadding",_urlBg);_urlPad.PaddingLeft=UDim.new(0,9)
local execUrlBox=Instance.new("TextBox");execUrlBox.PlaceholderText="https://raw.githubusercontent.com/... (URL to script)"
execUrlBox.Text="";execUrlBox.Font=Enum.Font.Gotham;execUrlBox.TextSize=11;execUrlBox.TextColor3=T.T1
execUrlBox.PlaceholderColor3=T.T3;execUrlBox.BackgroundTransparency=1;execUrlBox.BorderSizePixel=0
execUrlBox.Size=UDim2.new(1,0,1,0);execUrlBox.ClearTextOnFocus=false;execUrlBox.Parent=_urlBg;rTx(execUrlBox,"T1")
local _fetchF=mkF(_urlRow,UDim2.new(0,68,0,28),UDim2.new(1,-68,0,2),T.A,TR.btn)
rBg(_fetchF,"A");corner(_fetchF,8);shine(_fetchF)
local _fLbl=mkL(_fetchF,"↓ Fetch & Run",Enum.Font.GothamBold,10,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(_fLbl,"T1")
local _fHit=mkB(_fetchF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)

local _btnRow=mkF(execPage,UDim2.new(1,-12,0,34),UDim2.new(0,6,1,-118),T.BG,1)
_btnRow.ZIndex=2
local _runF=mkF(_btnRow,UDim2.new(0,120,0,30),UDim2.new(0,0,0,2),T.A,TR.btn)
rBg(_runF,"A");corner(_runF,8);stroke(_runF,T.A,0.45);shine(_runF)
local _runLbl=mkL(_runF,"▶  Execute",Enum.Font.GothamBold,13,T.T1,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(_runLbl,"T1")
local _runHit=mkB(_runF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.A,1)
local _clrF=mkF(_btnRow,UDim2.new(0,72,0,30),UDim2.new(0,126,0,2),T.CD,TR.card)
rBg(_clrF,"CD");corner(_clrF,8);stroke(_clrF,Color3.new(1,1,1),0.84);shine(_clrF)
local _clrLbl=mkL(_clrF,"⌫  Clear",Enum.Font.GothamBold,12,T.T2,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),Enum.TextXAlignment.Center);rTx(_clrLbl,"T2")
local _clrHit=mkB(_clrF,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.CD,1)

local _edCard=mkF(execPage,UDim2.new(1,-12,1,-130),UDim2.new(0,6,0,8),T.CD,TR.card)
_edCard.ZIndex=2
rBg(_edCard,"CD");corner(_edCard,10);stroke(_edCard,Color3.new(1,1,1),0.84)
local _edStrip=mkF(_edCard,UDim2.new(0,3,1,-12),UDim2.new(0,0,0,6),T.A,0.65);corner(_edStrip,2);rBg(_edStrip,"A")
local _edPad=Instance.new("UIPadding",_edCard)
_edPad.PaddingLeft=UDim.new(0,10);_edPad.PaddingRight=UDim.new(0,8)
_edPad.PaddingTop=UDim.new(0,8);_edPad.PaddingBottom=UDim.new(0,8)
execCodeBox=Instance.new("TextBox")
execCodeBox.PlaceholderText="-- write or paste your Lua script here\nprint(\"Hello from Crystal Hub!\")"
execCodeBox.Text="";execCodeBox.Font=Enum.Font.Code;execCodeBox.TextSize=12
execCodeBox.TextColor3=T.T1;execCodeBox.PlaceholderColor3=T.T3
execCodeBox.BackgroundTransparency=1;execCodeBox.BorderSizePixel=0
execCodeBox.Size=UDim2.new(1,0,1,0);execCodeBox.ClearTextOnFocus=false
execCodeBox.MultiLine=true;execCodeBox.TextXAlignment=Enum.TextXAlignment.Left
execCodeBox.TextYAlignment=Enum.TextYAlignment.Top;execCodeBox.Parent=_edCard;rTx(execCodeBox,"T1")
execCodeBox.Focused:Connect(function() tw(_edCard,TF,{BackgroundTransparency=TR.card-0.10}) end)
execCodeBox.FocusLost:Connect(function() tw(_edCard,TM,{BackgroundTransparency=TR.card}) end)

local function execRun(code)
    if not code or code=="" then execStatus.Text="No code to execute.";execStatus.TextColor3=T.T3;return end
    local fn,ce=loadstring(code)
    if not fn then execStatus.Text="✕  Compile: "..tostring(ce):sub(1,110);execStatus.TextColor3=Color3.fromRGB(255,90,90);return end
    local ok,err=pcall(fn)
    if ok then execStatus.Text="✓  Executed successfully";execStatus.TextColor3=Color3.fromRGB(80,230,120)
    else execStatus.Text="✕  Runtime: "..tostring(err):sub(1,110);execStatus.TextColor3=Color3.fromRGB(255,90,90) end
    if saved.autoClear then execCodeBox.Text="" end
end

_runHit.MouseEnter:Connect(function() tw(_runF,TF,{BackgroundTransparency=0}) end)
_runHit.MouseLeave:Connect(function() tw(_runF,TM,{BackgroundTransparency=TR.btn}) end)
_runHit.MouseButton1Click:Connect(function() tw(_runF,TF,{BackgroundTransparency=0});execRun(execCodeBox.Text);task.delay(0.3,function() tw(_runF,TM,{BackgroundTransparency=TR.btn}) end) end)
_clrHit.MouseEnter:Connect(function() tw(_clrF,TF,{BackgroundTransparency=TR.card-0.09}) end)
_clrHit.MouseLeave:Connect(function() tw(_clrF,TM,{BackgroundTransparency=TR.card}) end)
_clrHit.MouseButton1Click:Connect(function() execCodeBox.Text="";execStatus.Text="Cleared.";execStatus.TextColor3=T.T3 end)
_fHit.MouseEnter:Connect(function() tw(_fetchF,TF,{BackgroundTransparency=0}) end)
_fHit.MouseLeave:Connect(function() tw(_fetchF,TM,{BackgroundTransparency=TR.btn}) end)
_fHit.MouseButton1Click:Connect(function()
    local url=execUrlBox.Text
    if url=="" then execStatus.Text="Enter a URL first.";execStatus.TextColor3=T.T3;return end
    execStatus.Text="Fetching...";execStatus.TextColor3=T.T3;tw(_fetchF,TF,{BackgroundTransparency=0})
    task.spawn(function()
        local ok,src=pcall(httpFetch,url)
        if not ok then execStatus.Text="✕  HTTP: "..tostring(src):sub(1,80);execStatus.TextColor3=Color3.fromRGB(255,90,90);tw(_fetchF,TM,{BackgroundTransparency=TR.btn});return end
        execRun(src);tw(_fetchF,TM,{BackgroundTransparency=TR.btn})
    end)
end)

-- ──── SETTINGS ────
local _,settingsScroll=newPage("Settings")
addSection(settingsScroll,"Theme — saves automatically")

local themeGrid=mkF(settingsScroll,UDim2.new(1,0,0,0),UDim2.new(0,0,0,0),T.BG,1)
themeGrid.AutomaticSize=Enum.AutomaticSize.Y
local tgG=Instance.new("UIGridLayout",themeGrid);tgG.CellSize=UDim2.new(0.5,-4,0,72);tgG.CellPadding=UDim2.new(0,6,0,6)
local selDots={}
for i,th in ipairs(THEMES) do
    local tc=glassCard(themeGrid,UDim2.new(0,0,0,0),UDim2.new(0,0,0,0))
    local strip=mkF(tc,UDim2.new(1,-12,0,26),UDim2.new(0,6,0,6),th.A,0.18);corner(strip,6)
    for j=0,2 do local d=mkF(strip,UDim2.new(0,7,0,7),UDim2.new(0,5+j*11,0.5,-3),th.A,j*0.28);corner(d,4) end
    local nl=mkL(tc,th.name,Enum.Font.GothamBold,10,T.T1,UDim2.new(0,8,0,36),UDim2.new(1,-26,0,14));rTx(nl,"T1")
    local chk=mkL(tc,"✓",Enum.Font.GothamBold,11,th.A,UDim2.new(1,-20,0,36),UDim2.new(0,16,0,14),Enum.TextXAlignment.Center)
    chk.Visible=(i==saved.themeIdx);selDots[i]=chk
    local tH=mkB(tc,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),T.CD,1)
    tH.MouseEnter:Connect(function() tw(tc,TF,{BackgroundTransparency=TR.card-0.09}) end)
    tH.MouseLeave:Connect(function() tw(tc,TF,{BackgroundTransparency=TR.card}) end)
    local ci=i
    tH.MouseButton1Click:Connect(function()
        saved.themeIdx=ci;T=THEMES[ci];save();applyTheme(T,true)
        for _,pt in ipairs(particles) do if pt.f and pt.f.Parent then pt.f.BackgroundColor3=T.A end end
        for j,d in ipairs(selDots) do d.Visible=(j==ci) end
        switchTab(activeTab);pushNotif("Theme",T.name.." applied ✦",2.5)
    end)
end

addSection(settingsScroll,"Window")
addSlider(settingsScroll,"UI Opacity","0 = invisible · 10 = solid.",1,10,saved.opacity or 5,function(v)
    saved.opacity=v;TR.win=calcWinTr();tw(Window,TM,{BackgroundTransparency=TR.win});save()
end)
addToggle(settingsScroll,"Floating Particles","Animated accent dots.",saved.particles~=false,function(on)
    saved.particles=on;save()
    for _,pt in ipairs(particles) do if pt.f and pt.f.Parent then pt.f.Visible=on end end
end)

addSection(settingsScroll,"Notifications")
addToggle(settingsScroll,"Toast Notifications","Show action popups.",saved.notif~=false,function(on) saved.notif=on;save() end)
addSlider(settingsScroll,"Notification Duration","Seconds each toast stays.",1,8,saved.notifDur or 4,function(v) saved.notifDur=v;save() end)

addSection(settingsScroll,"Keybinds")
addKeybind(settingsScroll,"Toggle Visibility",saved.toggleKey or "RightShift",function(k) saved.toggleKey=k;save() end)

addSection(settingsScroll,"Executor")
addDropdown(settingsScroll,"Execute Mode",{"loadstring","pcall wrap","silent"},saved.execMode or "loadstring",function(v) saved.execMode=v;save() end)
addToggle(settingsScroll,"Auto-clear on Run","Clear editor after each execute.",saved.autoClear or false,function(on) saved.autoClear=on;save() end)

addSection(settingsScroll,"Actions")
addButton(settingsScroll,"Reset All Settings","Restore every setting to default.",function()
    saved={themeIdx=1,notif=true,notifDur=4,opacity=5,particles=true,partCount=14,toggleKey="RightShift",anims=true,execMode="loadstring",autoClear=false}
    save();pushNotif("Settings","Reset to defaults.",3)
end)
addButton(settingsScroll,"Close Crystal Hub","Destroy the GUI completely.",function()
    tw(Window,TM,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)})
    task.delay(0.25,function() SG:Destroy() end)
end)
addSection(settingsScroll,"Info")
addLabel(settingsScroll,"Crystal Hub  v3.1  ·  by void.\nPlayer: "..LP.Name.."  ·  Place: "..tostring(game.PlaceId).."\nTheme, opacity, keybinds auto-save.")

-- ================================================================
-- _G.CrystalHub  — Rayfield-compatible tab creation API
-- ================================================================
_G.CrystalHub={}
function _G.CrystalHub:CreateTab(name)
    local page,scroll=newPage(name)
    local tab={}
    function tab:CreateSection(title)  addSection(scroll,title);return self end
    function tab:CreateLabel(text)     addLabel(scroll,text);return self end
    function tab:CreateParagraph(cfg)  addLabel(scroll,(cfg.Title and cfg.Title..":\n" or "")..(cfg.Content or ""));return self end
    function tab:CreateButton(cfg)     addButton(scroll,cfg.Name or "Button",cfg.Description or "",cfg.Callback or function()end);return self end
    function tab:CreateToggle(cfg)
        local _,get,set=addToggle(scroll,cfg.Name or "Toggle",cfg.Description or "",cfg.CurrentValue or false,cfg.Callback or function()end)
        return {Get=get,Set=set}
    end
    function tab:CreateSlider(cfg)
        local r=cfg.Range or {0,100}
        local _,get=addSlider(scroll,cfg.Name or "Slider",cfg.Description or "",r[1],r[2],cfg.CurrentValue or r[1],cfg.Callback or function()end)
        return {Get=get}
    end
    function tab:CreateDropdown(cfg)
        local _,get=addDropdown(scroll,cfg.Name or "Dropdown",cfg.Options or {"Option 1"},cfg.CurrentOption or "",cfg.Callback or function()end)
        return {Get=get}
    end
    function tab:CreateInput(cfg)      addTextInput(scroll,cfg.Name or "Input",cfg.PlaceholderText or "Type here...",cfg.Callback or function()end);return self end
    function tab:CreateKeybind(cfg)    addKeybind(scroll,cfg.Name or "Keybind",cfg.CurrentKeybind or "None",cfg.Callback or function()end);return self end
    return tab
end
function _G.CrystalHub:Notify(cfg) pushNotif(cfg.Title or "Notification",cfg.Content or "",cfg.Duration or 3.5) end
function _G.CrystalHub:Destroy()
    tw(Window,TM,{Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)})
    task.delay(0.25,function() SG:Destroy() end)
end
function _G.CrystalHub:Toggle() Window.Visible=not Window.Visible end

-- ================================================================
-- DRAG
-- ================================================================
do
    local drag,dragStart,startPos,lastDragInput=false,nil,nil,nil
    TB.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true;dragStart=inp.Position;startPos=Window.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    TB.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then lastDragInput=inp end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if inp==lastDragInput and drag and dragStart then
            local d=inp.Position-dragStart
            Window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- ================================================================
-- KEYBOARD TOGGLE
-- ================================================================
UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    local k=inp.KeyCode.Name
    if k==(saved.toggleKey or "RightShift") or k=="Insert" then
        local vis=not Window.Visible
        if vis then
            Window.Visible=true
            tw(Window,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,WIN_W,0,WIN_H)})
        else
            tw(Window,TF,{Size=UDim2.new(0,WIN_W*0.93,0,WIN_H*0.93)})
            task.delay(0.14,function() Window.Visible=false;Window.Size=UDim2.new(0,WIN_W,0,WIN_H) end)
        end
    end
end)

-- ================================================================
-- INIT
-- ================================================================
applyTheme(T,false)
switchTab(1)
if saved.particles==false then for _,pt in ipairs(particles) do if pt.f then pt.f.Visible=false end end end

Window.Size=UDim2.new(0,WIN_W*0.88,0,WIN_H*0.88)
Window.BackgroundTransparency=1
tw(Window,TweenInfo.new(0.54,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
    Size=UDim2.new(0,WIN_W,0,WIN_H),
    BackgroundTransparency=TR.win,
})
task.delay(0.65,function()
    pushNotif("Crystal Hub","v3.1  ·  "..T.name.."  ✦",3.5)
end)
