--[[
╔══════════════════════════════════════════════════════════════════════════╗
║  WindHub  v5.0  |  Ultimate Blade Ball  |  PC + Mobile                 ║
║  Tabbed UI · TweenService anims · Bug-free · 1500+ lines               ║
╚══════════════════════════════════════════════════════════════════════════╝
  TABS: Parry | Visuals | Combat | Stats | Config
  HOTKEYS (PC): P=parry O=spam I=animfix U=dodge Y=esp H=hitbox
                G=arc F=stats T=cycle-mode R=reset-window
  MOBILE: all features via UI — no keyboard needed
--]]

-- ═══ SERVICES ══════════════════════════════════════════════════
local RS      = game:GetService("RunService")
local Plrs    = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RepStor = game:GetService("ReplicatedStorage")
local WS      = workspace
local lp      = Plrs.LocalPlayer
local cam     = WS.CurrentCamera

if _G.WindHubActive then _G.WindHubActive = false task.wait(0.1) end
_G.WindHubActive    = true
_G.WindHub_Standoff = false
_G.WindHub_ReplionTargeted = nil
_G.WindHub_ExplodedBalls   = {}

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ═══ SIGNAL (OOP · closures · events) ═════════════════════════
local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({ _c = {}, _id = 0 }, Signal)
end
function Signal:Connect(fn)
    self._id += 1
    local id = self._id
    self._c[id] = fn
    return setmetatable({}, {
        __index = { Disconnect = function() self._c[id] = nil end }
    })
end
function Signal:Fire(...)
    for _, fn in pairs(self._c) do task.spawn(fn, ...) end
end
function Signal:Wait()
    local co = coroutine.running()
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        task.spawn(co, ...)
    end)
    return coroutine.yield()
end
function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...) conn:Disconnect() fn(...) end)
    return conn
end

-- ═══ CONFIG (__index defaults · __newindex validation) ══════════
local DEFAULTS = {
    autoParry      = true,
    parryMode      = "Predictive",
    parryWindow    = 0.52,
    minWindow      = 0.15,
    maxWindow      = 1.20,
    adaptAlpha     = 0.12,
    humanizeMin    = 0.010,
    humanizeMax    = 0.045,
    manualSpam     = false,
    spamRate       = 0.07,
    autoDodge      = false,
    dodgeDist      = 22,
    animFix        = true,
    espBalls       = true,
    espPlayers     = false,
    predArc        = true,
    arcSegments    = 18,
    arcDuration    = 0.5,
    hitboxExpand   = false,
    hitboxSize     = Vector3.new(6, 6, 6),
    pingComp       = true,
    printStats     = false,
}
local Config = {}
Config.Changed = Signal.new()
setmetatable(Config, {
    __index    = DEFAULTS,
    __newindex = function(t, k, v)
        if DEFAULTS[k] == nil then return end
        local old = rawget(t, k) or DEFAULTS[k]
        rawset(t, k, v)
        if old ~= v then Config.Changed:Fire(k, v, old) end
    end,
})

-- ═══ EXEC PROBE (reflection · env) ════════════════════════════
local Exec = {}
do
    local genv = (type(getfenv) == "function" and pcall(getfenv, 0) and getfenv(0)) or _G
    local function has(n) return type(genv[n]) == "function" end
    pcall(function()
        local fn = genv.identifyexecutor or genv.getexecutorname
        if type(fn) == "function" then Exec.name = tostring(fn()):lower() end
    end)
    Exec.name = Exec.name or "unknown"
    Exec.isMobile = isMobile
    Exec.isPC     = not isMobile
    Exec.UNC = {
        hookfunction      = has "hookfunction",
        newcclosure       = has "newcclosure",
        getrawmetatable   = has "getrawmetatable",
        setreadonly       = has "setreadonly",
        getupvalues       = has "getupvalues",
        getconstants      = has "getconstants",
        getprotos         = has "getprotos",
        getnamecallmethod = has "getnamecallmethod",
        dbg_up    = type(debug)=="table" and type(debug.getupvalues)=="function",
        dbg_const = type(debug)=="table" and type(debug.getconstants)=="function",
    }
end

-- ═══ REFLECT (debug extensions · introspection) ════════════════
local Reflect = {}
function Reflect.upvalues(fn)
    if Exec.UNC.getupvalues then local ok,t=pcall(getupvalues,fn) if ok then return t end end
    if Exec.UNC.dbg_up then local ok,t=pcall(debug.getupvalues,fn) if ok then return t end end
    return {}
end
function Reflect.constants(fn)
    if Exec.UNC.getconstants then local ok,t=pcall(getconstants,fn) if ok then return t end end
    if Exec.UNC.dbg_const then local ok,t=pcall(debug.getconstants,fn) if ok then return t end end
    return {}
end
function Reflect.protos(fn)
    if Exec.UNC.getprotos then local ok,t=pcall(getprotos,fn) if ok then return t end end
    return {}
end

-- ═══ PING COMPENSATION ═════════════════════════════════════════
local PingComp = { pingMs=0, avg=0, hist={} }
task.spawn(function()
    local stats = game:GetService("Stats")
    while _G.WindHubActive do
        pcall(function()
            local p = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            PingComp.pingMs = p
            table.insert(PingComp.hist, p)
            if #PingComp.hist > 30 then table.remove(PingComp.hist,1) end
            local s=0 for _,v in ipairs(PingComp.hist) do s+=v end
            PingComp.avg = s/#PingComp.hist
        end)
        task.wait(1)
    end
end)
function PingComp:effectiveWindow()
    return Config.parryWindow + (Config.pingComp and self.pingMs*0.0005 or 0)
end

-- ═══ VIRTUAL INPUT (PC + Mobile) ════════════════════════════════
local VIM = (function()
    local ok,s = pcall(function() return game:GetService("VirtualInputManager") end)
    return ok and s or nil
end)()

local function clickParry()
    task.wait(Config.humanizeMin + math.random()*(Config.humanizeMax-Config.humanizeMin))
    if isMobile and VIM and VIM.SendTouchEvent then
        local cx = cam.ViewportSize.X*0.5
        local cy = cam.ViewportSize.Y*0.5
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), true,  game) end)
        task.wait(0.035)
        pcall(function() VIM:SendTouchEvent(0, Vector2.new(cx,cy), false, game) end)
    elseif VIM then
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,true, game,0) end)
        task.wait(0.035)
        pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end)
    end
end

-- ═══ __NAMECALL HOOK ════════════════════════════════════════════
local NamecallSignal = Signal.new()
local namecallHooked = false
do
    local U = Exec.UNC
    if U.hookfunction and U.newcclosure and U.getrawmetatable and U.getnamecallmethod then
        local mt = getrawmetatable(game)
        if U.setreadonly then pcall(setreadonly,mt,false) end
        local orig = rawget(mt,"__namecall")
        if orig then
            namecallHooked = pcall(function()
                hookfunction(orig, newcclosure(function(self,...)
                    local m = getnamecallmethod()
                    if typeof(self)=="Instance" then NamecallSignal:Fire(self,m,...) end
                    return orig(self,...)
                end))
            end)
        end
        if U.setreadonly then pcall(setreadonly,mt,true) end
    end
end

-- ═══ REPLION INTEGRATION ════════════════════════════════════════
local Replion = { onTargetChanged=Signal.new(), onStateChanged=Signal.new(), log={} }
task.spawn(function()
    task.wait(2)
    local remote
    pcall(function()
        remote = RepStor.Packages._Index["ytrev_replion@2.0.0-rc.1"].replion.Remotes.Update
    end)
    if not (remote and remote:IsA("RemoteEvent")) then
        pcall(function()
            local pkgs = RepStor:FindFirstChild("Packages")
            if pkgs then
                for _,d in ipairs(pkgs:GetDescendants()) do
                    if d:IsA("RemoteEvent") and d.Name=="Update" then remote=d break end
                end
            end
        end)
    end
    if not remote then return end
    remote.OnClientEvent:Connect(function(channel, path, value)
        local e={channel=tostring(channel),path=path,value=value,t=os.clock()}
        table.insert(Replion.log,e)
        if #Replion.log>60 then table.remove(Replion.log,1) end
        Replion.onStateChanged:Fire(path,value)
        local ps = tostring(path)
        if ps:lower():find("target") or ps:lower():find("ball") then
            if type(value)=="string" then Replion.onTargetChanged:Fire(channel,value) end
        end
        if type(value)=="table" then
            local tgt = value.target or value.Target or value.targetPlayer
            if tgt then Replion.onTargetChanged:Fire(channel,tgt) end
        end
    end)
end)
Replion.onTargetChanged:Connect(function(_,newTarget)
    if newTarget==lp.Name then _G.WindHub_ReplionTargeted=os.clock() end
end)

-- ═══ GAME REMOTE HOOKS ══════════════════════════════════════════
local GameRemotes = {
    onParryAttempt=Signal.new(), onParrySuccess=Signal.new(),
    onBallExplode=Signal.new(),  onStandoffStart=Signal.new(),
    onCooldownEnd=Signal.new(),  onDisableReaper=Signal.new(),
    connected={},
}
local REMOTE_HANDLERS = {
    ParryAttemptAll = function(...) GameRemotes.onParryAttempt:Fire(...) end,
    ParrySuccessAll = function(player,...)
        GameRemotes.onParrySuccess:Fire(player,...)
        if typeof(player)=="Instance" and player==lp then
            _G.WindHub_LastSuccessAt=os.clock()
        end
    end,
    BallExplode = function(ball,...)
        GameRemotes.onBallExplode:Fire(ball,...)
        if typeof(ball)=="Instance" then _G.WindHub_ExplodedBalls[ball]=true end
    end,
    StandoffStart = function(...)
        GameRemotes.onStandoffStart:Fire(...)
        _G.WindHub_Standoff=true
        task.delay(30, function()
            if _G.WindHubActive then _G.WindHub_Standoff=false end
        end)
    end,
    SecondaryEndCD = function(...) GameRemotes.onCooldownEnd:Fire(...) _G.WindHub_SecondaryReady=true end,
    DisableReaper  = function(...) GameRemotes.onDisableReaper:Fire(...) end,
    BallAdded      = function(ball,...) if typeof(ball)=="Instance" then _G.WindHub_LatestBall=ball end end,
}
task.spawn(function()
    local remotes = RepStor:WaitForChild("Remotes",15)
    if not remotes then return end
    for name,handler in pairs(REMOTE_HANDLERS) do
        local ok,remote = pcall(function() return remotes:WaitForChild(name,10) end)
        if ok and remote and remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(handler)
            GameRemotes.connected[name]=true
        end
    end
end)
RS.Heartbeat:Connect(function()
    if _G.WindHub_Standoff and Config.parryMode~="Ultra" then Config.parryMode="Ultra" end
end)

-- ═══ REMOTE SPY ═════════════════════════════════════════════════
local RemoteSpy = { onFired=Signal.new(), log={} }
local function watchRemote(obj)
    if obj:IsA("RemoteEvent") then
        obj.OnClientEvent:Connect(function(...)
            local e={name=obj.Name,args={...},t=os.clock()}
            table.insert(RemoteSpy.log,e)
            if #RemoteSpy.log>80 then table.remove(RemoteSpy.log,1) end
            RemoteSpy.onFired:Fire(e)
        end)
    end
end
task.spawn(function() for _,o in ipairs(WS:GetDescendants()) do watchRemote(o) end end)
task.spawn(function() for _,o in ipairs(RepStor:GetDescendants()) do watchRemote(o) end end)
WS.DescendantAdded:Connect(watchRemote)
RepStor.DescendantAdded:Connect(watchRemote)

-- ═══ PHYSICS ENGINE ════════════════════════════════════════════
local Physics = {}
Physics.__index = Physics
local GRAV = Vector3.new(0,-WS.Gravity*0.04,0)
function Physics.new()
    return setmetatable({samples={},speedHist={}},Physics)
end
function Physics:push(pos,vel,t)
    table.insert(self.samples,{pos=pos,vel=vel,t=t})
    if #self.samples>12 then table.remove(self.samples,1) end
    table.insert(self.speedHist,vel.Magnitude)
    if #self.speedHist>12 then table.remove(self.speedHist,1) end
end
function Physics:derivedVel()
    local n=#self.samples
    if n<2 then return Vector3.zero end
    local a,b=self.samples[n-1],self.samples[n]
    local dt=b.t-a.t
    if dt<=1e-4 then return Vector3.zero end
    return (b.pos-a.pos)/dt
end
function Physics:eta(bPos,bVel,pPos)
    local delta=pPos-bPos
    local dist=delta.Magnitude
    if dist<0.01 then return 0 end
    local closing=bVel:Dot(delta.Unit)
    if closing<=1e-6 then return math.huge end
    return dist/closing
end
function Physics:predict(bPos,bVel,dt)
    return bPos+bVel*dt+0.5*GRAV*dt*dt
end
function Physics:arc(bPos,bVel,totalTime,segs)
    local pts={}
    for i=0,segs do pts[i+1]=self:predict(bPos,bVel,totalTime*(i/segs)) end
    return pts
end
function Physics:adaptWindow(current,successETA)
    return math.clamp(
        current*(1-Config.adaptAlpha)+(successETA+0.03)*Config.adaptAlpha,
        Config.minWindow, Config.maxWindow
    )
end

-- ═══ BALL STATE (__index · __newindex) ══════════════════════════
local BallState = {}
BallState.__index = BallState
BallState.onParried = Signal.new()
function BallState.new(ball)
    local raw={ball=ball,fired=false,eta=math.huge,speed=0,dist=math.huge,
               closing=false,threat=false,physics=Physics.new(),spawnAt=os.clock(),
               connections={}}
    return setmetatable({},{
        __index=function(_,k)
            if k=="alive" then return raw.ball and raw.ball.Parent~=nil end
            if k=="age"   then return os.clock()-raw.spawnAt end
            if k=="connections" then return raw.connections end
            return raw[k]
        end,
        __newindex=function(_,k,v)
            local old=raw[k]
            raw[k]=v
            if k=="fired" and v==true and old~=true then
                BallState.onParried:Fire(raw.ball,raw.eta)
            end
        end,
    })
end

-- ═══ PRIORITY QUEUE ════════════════════════════════════════════
local PQ={}; PQ.__index=PQ
function PQ.new() return setmetatable({_h={}},PQ) end
function PQ:push(item,p) table.insert(self._h,{item=item,p=p}) table.sort(self._h,function(a,b)return a.p<b.p end) end
function PQ:peek() return self._h[1] end
function PQ:clear() self._h={} end
function PQ:size() return #self._h end

-- ═══ BALL TRACKER (fixed: no table mod during iteration) ════════
local BallTracker={}; BallTracker.__index=BallTracker
function BallTracker.new()
    local self=setmetatable({states={},window=Config.parryWindow,
        parryCount=0,etaHistory={},queue=PQ.new(),
        onParry=Signal.new(),onDodge=Signal.new()},BallTracker)
    self.onParry:Connect(function(_,eta)
        self.parryCount+=1
        table.insert(self.etaHistory,eta)
        if #self.etaHistory>60 then table.remove(self.etaHistory,1) end
    end)
    return self
end
function BallTracker:track(ball)
    if self.states[ball] then return end
    local s=BallState.new(ball)
    self.states[ball]=s
    -- store connections so we can disconnect on untrack (fixes memory leak)
    local conn1=pcall(function()
        return ball:GetAttributeChangedSignal("target"):Connect(function()
            local st=self.states[ball]
            if st then st.fired=false end
        end)
    end)
    if namecallHooked then
        local c=NamecallSignal:Connect(function(inst,method)
            if inst~=ball then return end
            if method=="SetAttribute" or method=="GetAttributeChangedSignal" then
                local st=self.states[ball]
                if st then st.fired=false end
            end
        end)
        table.insert(s.connections,c)
    end
end
function BallTracker:untrack(ball)
    local s=self.states[ball]
    if s and s.connections then
        for _,conn in ipairs(s.connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    self.states[ball]=nil
end
function BallTracker:updateFrame(hrp,now)
    local ppos=hrp.Position
    local name=lp.Name
    self.queue:clear()
    -- collect balls to remove SEPARATELY to avoid modifying during iteration
    local toRemove={}
    for ball,state in pairs(self.states) do
        local exploded=_G.WindHub_ExplodedBalls[ball]
        if exploded or not(ball and ball.Parent) then
            table.insert(toRemove,ball)
        else
            local vp=ball:FindFirstChild("zoomies")
            if vp then
                local bvel=vp.VectorVelocity
                local bpos=ball.Position
                state.physics:push(bpos,bvel,now)
                local derived=state.physics:derivedVel()
                local vel=bvel.Magnitude>=derived.Magnitude and bvel or derived
                local eta=state.physics:eta(bpos,vel,ppos)
                state.speed=vel.Magnitude
                state.dist=(ppos-bpos).Magnitude
                state.eta=eta
                state.closing=vel:Dot((ppos-bpos).Unit)>0
                state.threat=(ball:GetAttribute("target")==name) and state.closing and not state.fired
                if state.threat then self.queue:push(ball,eta) end
            end
        end
    end
    for _,ball in ipairs(toRemove) do
        self:untrack(ball)
    end
end
function BallTracker:bestThreat()
    local top=self.queue:peek()
    if not top then return nil,math.huge end
    return top.item,top.p
end
function BallTracker:markParried(ball,eta)
    local s=self.states[ball]
    if not s then return end
    s.fired=true
    self.window=s.physics:adaptWindow(self.window,eta)
    Config.parryWindow=self.window
    self.onParry:Fire(ball,eta)
end
function BallTracker:avgETA()
    if #self.etaHistory==0 then return 0 end
    local sum=0 for _,v in ipairs(self.etaHistory) do sum+=v end
    return sum/#self.etaHistory
end

-- ═══ ANIMATION FIX ══════════════════════════════════════════════
local AnimFix={track=nil,lastAt=0}
task.defer(function()
    if not(Exec.UNC.hookfunction and Exec.UNC.newcclosure and Exec.UNC.getrawmetatable) then return end
    local dummy=Instance.new("Animation")
    local mt; pcall(function() mt=getrawmetatable(dummy) end)
    dummy:Destroy()
    if not mt then return end
    if Exec.UNC.setreadonly then pcall(setreadonly,mt,false) end
    local orig=rawget(mt,"__index")
    if type(orig)~="function" then
        if Exec.UNC.setreadonly then pcall(setreadonly,mt,true) end return
    end
    pcall(hookfunction,orig,newcclosure(function(self,k)
        local v=orig(self,k)
        if k=="Play" and type(v)=="function" then
            return newcclosure(function(track,...)
                pcall(function()
                    local id=track.Animation and track.Animation.AnimationId or ""
                    if id:find("parr") or id:find("block") or id:find("deflect") then
                        AnimFix.track=track; AnimFix.lastAt=os.clock()
                    end
                end)
                return v(track,...)
            end)
        end
        return v
    end))
    if Exec.UNC.setreadonly then pcall(setreadonly,mt,true) end
end)
local function doAnimFix()
    if not Config.animFix or not AnimFix.track then return end
    if os.clock()-AnimFix.lastAt>0.12 then return end
    pcall(function()
        if AnimFix.track.IsPlaying then AnimFix.track:Stop(0) end
        AnimFix.track:Play(0)
    end)
end

-- ═══ AUTO DODGE ═════════════════════════════════════════════════
local Dodge={lastAt=0,busy=false}
function Dodge.attempt(hrp,bPos,bVel)
    if not Config.autoDodge or Dodge.busy then return end
    if os.clock()-Dodge.lastAt<0.35 then return end
    Dodge.lastAt=os.clock(); Dodge.busy=true
    task.spawn(function()
        local perp=bVel.Unit:Cross(Vector3.yAxis).Unit
        if math.random()>0.5 then perp=-perp end
        TS:Create(hrp,TweenInfo.new(0.15,Enum.EasingStyle.Quad),
            {CFrame=hrp.CFrame*CFrame.new(perp*Config.dodgeDist)}):Play()
        task.wait(0.22); Dodge.busy=false
    end)
end

-- ═══ HITBOX EXPANDER ════════════════════════════════════════════
local HitboxExpand={_orig={}}
function HitboxExpand.apply(char)
    if not Config.hitboxExpand then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and not HitboxExpand._orig[p] then
            HitboxExpand._orig[p]=p.Size
            pcall(function() p.Size=Config.hitboxSize end)
        end
    end
end
function HitboxExpand.remove()
    for part,orig in pairs(HitboxExpand._orig) do
        pcall(function() part.Size=orig end)
    end
    HitboxExpand._orig={}
end

-- ═══ ARC ESP ════════════════════════════════════════════════════
local Arc={_dots={}}
local function makeDot()
    local p=Instance.new("Part")
    p.Size=Vector3.new(0.18,0.18,0.18); p.Anchored=true
    p.CanCollide=false; p.CastShadow=false
    p.Material=Enum.Material.Neon
    p.Color=Color3.fromRGB(255,70,70); p.Parent=cam
    return p
end
local function updateArc(ball,state)
    if not Config.predArc or not(ball and ball.Parent) then
        if Arc._dots[ball] then
            for _,d in ipairs(Arc._dots[ball]) do d:Destroy() end
            Arc._dots[ball]=nil
        end
        return
    end
    local vp=ball:FindFirstChild("zoomies"); if not vp then return end
    local n=Config.arcSegments
    if not Arc._dots[ball] or #Arc._dots[ball]~=n+1 then
        if Arc._dots[ball] then for _,d in ipairs(Arc._dots[ball]) do d:Destroy() end end
        Arc._dots[ball]={}
        for i=1,n+1 do Arc._dots[ball][i]=makeDot() end
    end
    local pts=state.physics:arc(ball.Position,vp.VectorVelocity,Config.arcDuration,n)
    for i,pt in ipairs(pts) do
        if Arc._dots[ball][i] then Arc._dots[ball][i].CFrame=CFrame.new(pt) end
    end
end
local function cleanArc(ball)
    if Arc._dots[ball] then
        for _,d in ipairs(Arc._dots[ball]) do d:Destroy() end
        Arc._dots[ball]=nil
    end
end

-- ═══ ESP SYSTEM ═════════════════════════════════════════════════
local ESP={_bb={},_lbl={},_plr={}}
local function ensureBallBox(ball)
    if not ESP._bb[ball] then
        local b=Instance.new("SelectionBox"); b.Adornee=ball
        b.LineThickness=0.06; b.SurfaceTransparency=0.82; b.Parent=cam
        ESP._bb[ball]=b
    end
    return ESP._bb[ball]
end
local function ensureBallLabel(ball)
    if not ESP._lbl[ball] then
        local bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true
        bb.Size=UDim2.fromOffset(130,40); bb.StudsOffset=Vector3.new(0,3,0)
        bb.Adornee=ball; bb.Parent=cam
        local tl=Instance.new("TextLabel",bb)
        tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
        tl.TextSize=12; tl.Font=Enum.Font.Code; tl.TextStrokeTransparency=0.3
        ESP._lbl[ball]={bb=bb,tl=tl}
    end
    return ESP._lbl[ball]
end
local function cleanBallESP(ball)
    if ESP._bb[ball]  then ESP._bb[ball]:Destroy();       ESP._bb[ball]=nil end
    if ESP._lbl[ball] then ESP._lbl[ball].bb:Destroy();   ESP._lbl[ball]=nil end
end
local function updateBallESP(ball,state)
    if not Config.espBalls or not(ball and ball.Parent) then cleanBallESP(ball) return end
    local col=state.threat and Color3.fromRGB(255,50,50) or Color3.fromRGB(80,200,255)
    local box=ensureBallBox(ball); box.Color3=col; box.SurfaceColor3=col
    local L=ensureBallLabel(ball)
    local etaStr=state.eta>=99 and "∞" or ("%.3fs"):format(state.eta)
    L.tl.Text=("⚡ %s\nETA %s | %.0f/s"):format(ball:GetAttribute("target") or "?",etaStr,state.speed)
    L.tl.TextColor3=state.threat and Color3.fromRGB(255,80,80) or Color3.fromRGB(140,220,255)
end
local function updatePlayerESP()
    if not Config.espPlayers then
        for p,b in pairs(ESP._plr) do b:Destroy(); ESP._plr[p]=nil end return
    end
    for _,p in ipairs(Plrs:GetPlayers()) do
        if p~=lp and p.Character and not ESP._plr[p] then
            local b=Instance.new("SelectionBox"); b.Adornee=p.Character
            b.Color3=Color3.fromRGB(100,60,255); b.SurfaceColor3=Color3.fromRGB(100,60,255)
            b.LineThickness=0.05; b.SurfaceTransparency=0.80; b.Parent=cam
            ESP._plr[p]=b
        end
    end
    for p,b in pairs(ESP._plr) do
        if not p.Character then b:Destroy(); ESP._plr[p]=nil end
    end
end
Plrs.PlayerRemoving:Connect(function(p)
    if ESP._plr[p] then ESP._plr[p]:Destroy(); ESP._plr[p]=nil end
end)

-- ═══ CLIENT STATE MONITOR ═══════════════════════════════════════
local ClientState={alive=false,onDied=Signal.new(),onSpawned=Signal.new()}
local function monitorChar(char)
    if not char then return end
    local hum=char:WaitForChild("Humanoid",5); if not hum then return end
    ClientState.alive=true
    hum.Died:Connect(function() ClientState.alive=false; ClientState.onDied:Fire() end)
    if Config.hitboxExpand then HitboxExpand.apply(char) end
end
lp.CharacterAdded:Connect(function(char) ClientState.onSpawned:Fire(char); task.spawn(monitorChar,char) end)
task.spawn(monitorChar,lp.Character)

-- ═══ COROUTINE SWEEP (fixed leak) ═══════════════════════════════
local function startSweep(tracker)
    task.spawn(function()
        while _G.WindHubActive do
            for _,obj in ipairs(WS:GetDescendants()) do
                if not tracker.states[obj] then
                    local ok,v=pcall(function() return obj:GetAttribute("realBall") end)
                    if ok and v~=nil then tracker:track(obj) end
                end
            end
            task.wait(2)
        end
    end)
end

-- ═══ MANUAL SPAM (fixed spamActive stuck) ═══════════════════════
local spamActive=false
Config.Changed:Connect(function(k,v)
    if k~="manualSpam" then return end
    if v and not spamActive then
        spamActive=true
        task.spawn(function()
            pcall(function()
                while Config.manualSpam and _G.WindHubActive do
                    task.spawn(clickParry)
                    task.wait(Config.spamRate)
                end
            end)
            spamActive=false
        end)
    end
end)

-- ═══ PROFILER ═══════════════════════════════════════════════════
local Prof={times={},last=os.clock()}
function Prof:tick()
    local now=os.clock()
    table.insert(self.times,now-self.last); self.last=now
    if #self.times>60 then table.remove(self.times,1) end
end
function Prof:fps()
    if #self.times==0 then return 0 end
    local s=0 for _,v in ipairs(self.times) do s+=v end
    return 1/(s/#self.times)
end

-- ══════════════════════════════════════════════════════════════════
--  UI  (best-in-class tabbed interface with animations)
-- ══════════════════════════════════════════════════════════════════
local UI = {}
-- Palette
local C={
    bg      = Color3.fromRGB(9,8,15),
    panel   = Color3.fromRGB(15,13,24),
    card    = Color3.fromRGB(20,18,32),
    cardHov = Color3.fromRGB(26,24,40),
    header  = Color3.fromRGB(13,11,22),
    bar     = Color3.fromRGB(18,15,30),
    accent  = Color3.fromRGB(124,58,237),
    accentB = Color3.fromRGB(99,40,210),
    green   = Color3.fromRGB(52,211,153),
    red     = Color3.fromRGB(239,68,68),
    yellow  = Color3.fromRGB(251,191,36),
    text    = Color3.fromRGB(220,216,240),
    dim     = Color3.fromRGB(130,125,155),
    white   = Color3.fromRGB(248,246,255),
    black   = Color3.fromRGB(0,0,0),
}
local TI={
    fast   = TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
    med    = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
    slow   = TweenInfo.new(0.4, Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    spring = TweenInfo.new(0.35,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out),
}

-- Root ScreenGui
local sg=Instance.new("ScreenGui")
sg.Name="WindHubUI"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset=true
sg.Parent=game:GetService("CoreGui")

-- Shadow
local shadow=Instance.new("Frame",sg)
shadow.Size=UDim2.fromOffset(332,518)
shadow.Position=UDim2.fromOffset(30,30)
shadow.BackgroundColor3=C.black
shadow.BackgroundTransparency=0.55
shadow.BorderSizePixel=0
Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,12)

-- Main window
local win=Instance.new("Frame",sg)
win.Size=UDim2.fromOffset(328,514)
win.Position=UDim2.fromOffset(28,28)
win.BackgroundColor3=C.bg
win.BorderSizePixel=0
Instance.new("UICorner",win).CornerRadius=UDim.new(0,12)
local winStroke=Instance.new("UIStroke",win)
winStroke.Color=C.accent; winStroke.Transparency=0.5; winStroke.Thickness=1.5

-- Animate window in on open
win.Size=UDim2.fromOffset(0,0)
win.Position=UDim2.fromOffset(192,270)
win.BackgroundTransparency=1
TS:Create(win,TI.bounce,{
    Size=UDim2.fromOffset(328,514),
    Position=UDim2.fromOffset(28,28),
    BackgroundTransparency=0,
}):Play()
TS:Create(shadow,TI.bounce,{
    Size=UDim2.fromOffset(332,518),
    Position=UDim2.fromOffset(30,30),
}):Play()

-- ── Header ────────────────────────────────────────────────────
local header=Instance.new("Frame",win)
header.Size=UDim2.new(1,0,0,52)
header.BackgroundColor3=C.header
header.BorderSizePixel=0
Instance.new("UICorner",header).CornerRadius=UDim.new(0,12)
-- bottom fill to square off bottom corners
local hFill=Instance.new("Frame",header)
hFill.Size=UDim2.new(1,0,0,12); hFill.Position=UDim2.new(0,0,1,-12)
hFill.BackgroundColor3=C.header; hFill.BorderSizePixel=0

-- Accent gradient stripe
local stripe=Instance.new("Frame",header)
stripe.Size=UDim2.new(1,0,0,2); stripe.Position=UDim2.new(0,0,1,-2)
stripe.BackgroundColor3=C.accent; stripe.BorderSizePixel=0
local stripeGrad=Instance.new("UIGradient",stripe)
stripeGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,C.accentB),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(167,139,250)),
    ColorSequenceKeypoint.new(1,C.accentB),
}
-- animate gradient rotation
task.spawn(function()
    local r=0
    while _G.WindHubActive do
        r=(r+0.5)%360
        stripeGrad.Rotation=r
        task.wait(0.03)
    end
end)

-- Logo icon (pulsing)
local logoFrame=Instance.new("Frame",header)
logoFrame.Size=UDim2.fromOffset(36,36)
logoFrame.Position=UDim2.fromOffset(10,8)
logoFrame.BackgroundColor3=C.accent
logoFrame.BorderSizePixel=0
Instance.new("UICorner",logoFrame).CornerRadius=UDim.new(0,8)
local logoLbl=Instance.new("TextLabel",logoFrame)
logoLbl.Size=UDim2.new(1,0,1,0); logoLbl.BackgroundTransparency=1
logoLbl.Text="⚡"; logoLbl.TextSize=20; logoLbl.Font=Enum.Font.GothamBold
logoLbl.TextColor3=C.white

-- Pulse logo
task.spawn(function()
    while _G.WindHubActive do
        TS:Create(logoFrame,TI.med,{BackgroundColor3=Color3.fromRGB(139,92,246)}):Play()
        task.wait(0.8)
        TS:Create(logoFrame,TI.med,{BackgroundColor3=C.accent}):Play()
        task.wait(0.8)
    end
end)

local titleLbl=Instance.new("TextLabel",header)
titleLbl.Size=UDim2.new(1,-120,1,0); titleLbl.Position=UDim2.fromOffset(54,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="WindHub  v5.0"
titleLbl.TextSize=15; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextColor3=C.white; titleLbl.TextXAlignment=Enum.TextXAlignment.Left

local subLbl=Instance.new("TextLabel",header)
subLbl.Size=UDim2.new(1,-120,0,14); subLbl.Position=UDim2.fromOffset(54,28)
subLbl.BackgroundTransparency=1; subLbl.Text="Blade Ball • Ultimate"
subLbl.TextSize=10; subLbl.Font=Enum.Font.Gotham
subLbl.TextColor3=C.dim; subLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Minimize button
local minBtn=Instance.new("TextButton",header)
minBtn.Size=UDim2.fromOffset(28,28)
minBtn.Position=UDim2.new(1,-36,0,12)
minBtn.BackgroundColor3=C.card; minBtn.Text="—"
minBtn.TextColor3=C.dim; minBtn.TextSize=14
minBtn.Font=Enum.Font.GothamBold; minBtn.BorderSizePixel=0
Instance.new("UICorner",minBtn).CornerRadius=UDim.new(0,6)
local minimized=false
minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    if minimized then
        TS:Create(win,TI.med,{Size=UDim2.fromOffset(328,52)}):Play()
        minBtn.Text="+"
    else
        TS:Create(win,TI.bounce,{Size=UDim2.fromOffset(328,514)}):Play()
        minBtn.Text="—"
    end
end)

-- ── Drag (PC + Mobile) ────────────────────────────────────────
do
    local dragging,dragInput,dragStart,startPos
    local function onMove(input)
        if dragging then
            local d=input.Position-dragStart
            local nx=math.clamp(startPos.X.Offset+d.X,0,cam.ViewportSize.X-win.AbsoluteSize.X)
            local ny=math.clamp(startPos.Y.Offset+d.Y,0,cam.ViewportSize.Y-win.AbsoluteSize.Y)
            win.Position=UDim2.fromOffset(nx,ny)
            shadow.Position=UDim2.fromOffset(nx+2,ny+2)
        end
    end
    header.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragInput=input
            dragStart=input.Position; startPos=win.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch) then onMove(input) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
end

-- ── Tab Bar ───────────────────────────────────────────────────
local TAB_NAMES={"Parry","Visuals","Combat","Stats","Config"}
local TAB_ICONS={"⚡","👁","⚔","📊","⚙"}
local tabFrames={}
local tabBtns={}
local activeTab=1

local tabBar=Instance.new("Frame",win)
tabBar.Size=UDim2.new(1,-16,0,44)
tabBar.Position=UDim2.fromOffset(8,56)
tabBar.BackgroundColor3=C.bar; tabBar.BorderSizePixel=0
Instance.new("UICorner",tabBar).CornerRadius=UDim.new(0,8)

-- sliding indicator
local tabIndicator=Instance.new("Frame",tabBar)
tabIndicator.Size=UDim2.new(1/#TAB_NAMES,-4,0,3)
tabIndicator.Position=UDim2.new(0,2,1,-3)
tabIndicator.BackgroundColor3=C.accent; tabIndicator.BorderSizePixel=0
Instance.new("UICorner",tabIndicator).CornerRadius=UDim.new(0,2)

-- tab buttons
for i,name in ipairs(TAB_NAMES) do
    local btn=Instance.new("TextButton",tabBar)
    btn.Size=UDim2.new(1/#TAB_NAMES,0,1,0)
    btn.Position=UDim2.new((i-1)/#TAB_NAMES,0,0,0)
    btn.BackgroundTransparency=1
    btn.Text=TAB_ICONS[i].."\n"..name
    btn.TextSize=9; btn.Font=Enum.Font.GothamBold
    btn.TextColor3=i==1 and C.white or C.dim
    btn.BorderSizePixel=0
    tabBtns[i]=btn
end

-- content area
local content=Instance.new("Frame",win)
content.Size=UDim2.new(1,-16,1,-120)
content.Position=UDim2.fromOffset(8,108)
content.BackgroundTransparency=1; content.BorderSizePixel=0
content.ClipsDescendants=true

-- build tab scroll frames
for i in ipairs(TAB_NAMES) do
    local sf=Instance.new("ScrollingFrame",content)
    sf.Size=UDim2.new(1,0,1,0)
    sf.Position=i==1 and UDim2.new(0,0,0,0) or UDim2.new(1,8,0,0)
    sf.BackgroundTransparency=1; sf.BorderSizePixel=0
    sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=C.accent
    sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local ul=Instance.new("UIListLayout",sf)
    ul.Padding=UDim.new(0,6); ul.SortOrder=Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding",sf).PaddingTop=UDim.new(0,4)
    tabFrames[i]=sf
end

-- tab switch function
local switching=false
local function switchTab(to)
    if to==activeTab or switching then return end
    switching=true
    local from=activeTab
    activeTab=to
    -- move indicator
    TS:Create(tabIndicator,TI.med,{
        Position=UDim2.new((to-1)/#TAB_NAMES,2,1,-3)
    }):Play()
    -- update text colors
    for i,btn in ipairs(tabBtns) do
        TS:Create(btn,TI.fast,{TextColor3=i==to and C.white or C.dim}):Play()
    end
    -- slide out old
    local dir = to>from and -1 or 1
    TS:Create(tabFrames[from],TI.med,{
        Position=UDim2.new(dir,dir*8,0,0)
    }):Play()
    -- slide in new
    tabFrames[to].Position=UDim2.new(-dir,dir*8,0,0)
    TS:Create(tabFrames[to],TI.med,{Position=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.28)
    switching=false
end

for i,btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
    -- mobile touch
    btn.TouchTap:Connect(function() switchTab(i) end)
end

-- ── Status bar ────────────────────────────────────────────────
local statusBar=Instance.new("Frame",win)
statusBar.Size=UDim2.new(1,-16,0,30)
statusBar.Position=UDim2.new(0,8,1,-38)
statusBar.BackgroundColor3=C.bar; statusBar.BorderSizePixel=0
Instance.new("UICorner",statusBar).CornerRadius=UDim.new(0,6)

local statusLbl=Instance.new("TextLabel",statusBar)
statusLbl.Size=UDim2.new(1,0,1,0); statusLbl.BackgroundTransparency=1
statusLbl.Text="Initializing..."; statusLbl.TextSize=10
statusLbl.Font=Enum.Font.Code; statusLbl.TextColor3=C.dim

-- ── UI Builder helpers ────────────────────────────────────────
local function makeSection(parent,title,order)
    local f=Instance.new("Frame",parent)
    f.Size=UDim2.new(1,-8,0,24); f.BackgroundTransparency=1
    f.LayoutOrder=order or 0
    local t=Instance.new("TextLabel",f)
    t.Size=UDim2.new(1,0,1,0); t.BackgroundTransparency=1
    t.Text=("  %s"):format(title:upper()); t.TextSize=10
    t.Font=Enum.Font.GothamBold; t.TextColor3=C.accent
    t.TextXAlignment=Enum.TextXAlignment.Left
    local ln=Instance.new("Frame",f)
    ln.Size=UDim2.new(1,-70,0,1); ln.Position=UDim2.new(0,66,1,-1)
    ln.BackgroundColor3=C.accent; ln.BackgroundTransparency=0.6; ln.BorderSizePixel=0
    return f
end

local function makeToggle(parent,label,hint,cfgKey,order,callback)
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,-8,0,isMobile and 52 or 46)
    row.BackgroundColor3=C.card; row.BorderSizePixel=0; row.LayoutOrder=order or 0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",row); stroke.Color=C.accent
    stroke.Transparency=0.85; stroke.Thickness=1

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-72,0,22); lbl.Position=UDim2.fromOffset(12,6)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextSize=13; lbl.Font=Enum.Font.GothamBold
    lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local sub=Instance.new("TextLabel",row)
    sub.Size=UDim2.new(1,-72,0,16); sub.Position=UDim2.fromOffset(12,26)
    sub.BackgroundTransparency=1; sub.Text=hint
    sub.TextSize=10; sub.Font=Enum.Font.Gotham
    sub.TextColor3=C.dim; sub.TextXAlignment=Enum.TextXAlignment.Left

    local pill=Instance.new("TextButton",row)
    pill.Size=UDim2.fromOffset(54,28); pill.Position=UDim2.new(1,-62,0.5,-14)
    pill.BorderSizePixel=0; pill.Font=Enum.Font.GothamBold
    pill.TextSize=11; pill.TextColor3=C.white
    Instance.new("UICorner",pill).CornerRadius=UDim.new(0,14)

    local function refresh(animate)
        local on=Config[cfgKey]
        local targetColor=on and C.green or Color3.fromRGB(55,50,75)
        pill.Text=on and "ON" or "OFF"
        if animate then
            TS:Create(pill,TI.fast,{BackgroundColor3=targetColor}):Play()
            -- pulse the card border
            stroke.Transparency=0.4
            TS:Create(stroke,TI.med,{Transparency=0.85}):Play()
        else
            pill.BackgroundColor3=targetColor
        end
    end
    refresh(false)

    local function toggle()
        Config[cfgKey]=not Config[cfgKey]
        refresh(true)
        if callback then callback(Config[cfgKey]) end
    end

    pill.MouseButton1Click:Connect(toggle)
    pill.TouchTap:Connect(toggle)
    -- tap anywhere on card too
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch then toggle() end
    end)

    Config.Changed:Connect(function(k)
        if k==cfgKey then refresh(true) end
    end)

    -- hover effect (PC)
    row.MouseEnter:Connect(function()
        TS:Create(row,TI.fast,{BackgroundColor3=C.cardHov}):Play()
    end)
    row.MouseLeave:Connect(function()
        TS:Create(row,TI.fast,{BackgroundColor3=C.card}):Play()
    end)

    return row,pill
end

local function makeLabel(parent,text,order)
    local f=Instance.new("TextLabel",parent)
    f.Size=UDim2.new(1,-8,0,28); f.BackgroundColor3=C.card
    f.BorderSizePixel=0; f.LayoutOrder=order or 0
    f.TextColor3=C.dim; f.TextSize=11; f.Font=Enum.Font.Code
    f.Text=text; f.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local pad=Instance.new("UIPadding",f); pad.PaddingLeft=UDim.new(0,10)
    return f
end

local function makeModeSelector(parent,label,modes,cfgKey,order)
    local card=Instance.new("Frame",parent)
    card.Size=UDim2.new(1,-8,0,isMobile and 88 or 78)
    card.BackgroundColor3=C.card; card.BorderSizePixel=0; card.LayoutOrder=order or 0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)

    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,0,0,24); lbl.Position=UDim2.fromOffset(12,6)
    lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextSize=12; lbl.Font=Enum.Font.GothamBold
    lbl.TextColor3=C.text; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local btnRow=Instance.new("Frame",card)
    btnRow.Size=UDim2.new(1,-16,0,36); btnRow.Position=UDim2.fromOffset(8,30)
    btnRow.BackgroundTransparency=1
    local ul=Instance.new("UIListLayout",btnRow)
    ul.FillDirection=Enum.FillDirection.Horizontal
    ul.Padding=UDim.new(0,4); ul.SortOrder=Enum.SortOrder.LayoutOrder

    local btns={}
    for i,mode in ipairs(modes) do
        local b=Instance.new("TextButton",btnRow)
        b.Size=UDim2.new(1/#modes,-4*(#modes-1)/#modes,1,0)
        b.BorderSizePixel=0; b.Text=mode
        b.TextSize=11; b.Font=Enum.Font.GothamBold; b.TextColor3=C.white
        b.BackgroundColor3=Config[cfgKey]==mode and C.accent or C.bar
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        b.LayoutOrder=i; btns[mode]=b

        local function press()
            Config[cfgKey]=mode
            for m,btn in pairs(btns) do
                TS:Create(btn,TI.fast,{BackgroundColor3=m==mode and C.accent or C.bar}):Play()
            end
        end
        b.MouseButton1Click:Connect(press)
        b.TouchTap:Connect(press)
    end

    Config.Changed:Connect(function(k,v)
        if k==cfgKey then
            for m,btn in pairs(btns) do
                TS:Create(btn,TI.fast,{BackgroundColor3=m==v and C.accent or C.bar}):Play()
            end
        end
    end)
    return card
end

-- ── Tab 1: Parry ─────────────────────────────────────────────
local p1=tabFrames[1]
makeSection(p1,"Auto Parry",1)
makeToggle(p1,"Auto Parry","Physics-based automatic parry","autoParry",2)
makeModeSelector(p1,"Parry Mode",{"Ultra","Predictive","Conservative"},"parryMode",3)
makeToggle(p1,"Manual Spam","Rapid-fire click spam","manualSpam",4)
makeToggle(p1,"Anim Fix","Reset parry animation on parry","animFix",5)
makeToggle(p1,"Ping Comp","Compensate for network latency","pingComp",6)
makeSection(p1,"Timing Info",7)
local windowInfo=makeLabel(p1,"Window: —  |  Ping: —ms  |  Mode: —",8)

-- ── Tab 2: Visuals ────────────────────────────────────────────
local p2=tabFrames[2]
makeSection(p2,"ESP",1)
makeToggle(p2,"Ball ESP","Highlight + label all balls","espBalls",2)
makeToggle(p2,"Player ESP","Highlight all players","espPlayers",3)
makeToggle(p2,"Prediction Arc","Show ball trajectory","predArc",4)
makeSection(p2,"Combat Visuals",5)
makeToggle(p2,"Hitbox Expand","Expand your hitbox size","hitboxExpand",6,function(on)
    local char=lp.Character
    if char then if on then HitboxExpand.apply(char) else HitboxExpand.remove() end end
end)

-- ── Tab 3: Combat ────────────────────────────────────────────
local p3=tabFrames[3]
makeSection(p3,"Evasion",1)
makeToggle(p3,"Auto-Dodge","Tween away from incoming balls","autoDodge",2)
makeSection(p3,"Detection",3)
local remoteInfo=makeLabel(p3,"Connected remotes: —",4)
local replionInfo=makeLabel(p3,"Replion: —",5)
local ballInfo=makeLabel(p3,"Balls tracked: —",6)

-- ── Tab 4: Stats ─────────────────────────────────────────────
local p4=tabFrames[4]
makeSection(p4,"Live Statistics",1)
local statCards={}
local statDefs={
    {"Parries",     "0",    "Total auto-parries fired"},
    {"Avg ETA",     "—",    "Average parry ETA (seconds)"},
    {"Window",      "—",    "Adaptive parry window"},
    {"Ping",        "—ms",  "Current network ping"},
    {"FPS",         "—",    "Frames per second"},
    {"Mode",        "—",    "Active parry mode"},
    {"Balls",       "0",    "Balls currently tracked"},
    {"Parry Rate",  "—%",   "Estimated success rate"},
}
for i,def in ipairs(statDefs) do
    local card=Instance.new("Frame",p4)
    card.Size=UDim2.new(1,-8,0,54); card.BackgroundColor3=C.card
    card.BorderSizePixel=0; card.LayoutOrder=i+1
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)

    local val=Instance.new("TextLabel",card)
    val.Size=UDim2.new(1,0,0,28); val.Position=UDim2.fromOffset(0,6)
    val.BackgroundTransparency=1; val.Text=def[2]
    val.TextSize=22; val.Font=Enum.Font.GothamBold
    val.TextColor3=C.accent

    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(1,0,0,14); lbl.Position=UDim2.fromOffset(0,32)
    lbl.BackgroundTransparency=1; lbl.Text=def[1]:upper()
    lbl.TextSize=9; lbl.Font=Enum.Font.GothamBold; lbl.TextColor3=C.dim

    statCards[def[1]]=val
end

-- ── Tab 5: Config ────────────────────────────────────────────
local p5=tabFrames[5]
makeSection(p5,"About",1)
makeLabel(p5,"WindHub v5.0  |  Blade Ball Ultimate",2)
makeLabel(p5,"P=parry O=spam I=anim U=dodge Y=esp",3)
makeLabel(p5,"H=hitbox G=arc T=mode R=reset F=stats",4)
makeSection(p5,"Executor Info",5)
local execInfo=makeLabel(p5,"Exec: —",6)
local hookInfo=makeLabel(p5,"Namecall hook: —",7)
local platformInfo=makeLabel(p5,"Platform: "..(isMobile and "Mobile" or "PC"),8)
execInfo.Text="  Exec: "..Exec.name
hookInfo.Text="  Namecall hook: "..tostring(namecallHooked)

-- ── Notification System ──────────────────────────────────────
local notifStack={}
local function notify(msg,color)
    color=color or C.accent
    local n=Instance.new("Frame",sg)
    n.Size=UDim2.fromOffset(280,0)
    n.Position=UDim2.new(1,-296,0,16+#notifStack*52)
    n.BackgroundColor3=C.panel; n.BorderSizePixel=0
    n.AutomaticSize=Enum.AutomaticSize.Y
    Instance.new("UICorner",n).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",n); stroke.Color=color; stroke.Thickness=1.2
    local pad=Instance.new("UIPadding",n)
    pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
    pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)
    local dot=Instance.new("Frame",n); dot.Size=UDim2.fromOffset(6,6)
    dot.Position=UDim2.fromOffset(0,8); dot.BackgroundColor3=color
    dot.BorderSizePixel=0; Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local t=Instance.new("TextLabel",n)
    t.Size=UDim2.new(1,-14,0,0); t.Position=UDim2.fromOffset(14,0)
    t.AutomaticSize=Enum.AutomaticSize.Y; t.BackgroundTransparency=1
    t.Text=msg; t.TextSize=11; t.Font=Enum.Font.Gotham
    t.TextColor3=C.text; t.TextWrapped=true; t.TextXAlignment=Enum.TextXAlignment.Left

    table.insert(notifStack,n)
    -- slide in
    n.Position=UDim2.new(1,16,0,16+(#notifStack-1)*52)
    TS:Create(n,TI.med,{Position=UDim2.new(1,-296,0,16+(#notifStack-1)*52)}):Play()
    task.delay(3,function()
        TS:Create(n,TI.med,{Position=UDim2.new(1,16,0,n.Position.Y.Offset),BackgroundTransparency=1}):Play()
        task.wait(0.3); n:Destroy()
        for i,v in ipairs(notifStack) do if v==n then table.remove(notifStack,i) break end end
    end)
end
UI.notify=notify

-- ── Hotkeys ──────────────────────────────────────────────────
local MODES={"Ultra","Predictive","Conservative"}
local modeIdx=2
UIS.InputBegan:Connect(function(i,gp)
    if gp or isMobile then return end
    local k=i.KeyCode
    if     k==Enum.KeyCode.P then Config.autoParry=not Config.autoParry;    notify("Auto-Parry: "..(Config.autoParry and "ON" or "OFF"),Config.autoParry and C.green or C.red)
    elseif k==Enum.KeyCode.O then Config.manualSpam=not Config.manualSpam;  notify("Manual Spam: "..(Config.manualSpam and "ON" or "OFF"))
    elseif k==Enum.KeyCode.I then Config.animFix=not Config.animFix;        notify("Anim Fix: "..(Config.animFix and "ON" or "OFF"))
    elseif k==Enum.KeyCode.U then Config.autoDodge=not Config.autoDodge;    notify("Auto-Dodge: "..(Config.autoDodge and "ON" or "OFF"))
    elseif k==Enum.KeyCode.Y then Config.espBalls=not Config.espBalls;      notify("Ball ESP: "..(Config.espBalls and "ON" or "OFF"))
    elseif k==Enum.KeyCode.H then Config.hitboxExpand=not Config.hitboxExpand; notify("Hitbox: "..(Config.hitboxExpand and "ON" or "OFF"))
    elseif k==Enum.KeyCode.G then Config.predArc=not Config.predArc;        notify("Pred Arc: "..(Config.predArc and "ON" or "OFF"))
    elseif k==Enum.KeyCode.F then Config.printStats=not Config.printStats
    elseif k==Enum.KeyCode.T then
        modeIdx=(modeIdx%#MODES)+1; Config.parryMode=MODES[modeIdx]
        notify("Mode: "..Config.parryMode,C.yellow)
    elseif k==Enum.KeyCode.R then
        Config.parryWindow=DEFAULTS.parryWindow
        notify("Window reset → "..DEFAULTS.parryWindow,C.yellow)
    elseif k==Enum.KeyCode.RightControl then
        win.Visible=not win.Visible; shadow.Visible=win.Visible
    end
end)

-- ── UI Updater (coroutine) ───────────────────────────────────
local tracker  -- declared before, set in INIT
task.spawn(function()
    task.wait(2) -- let tracker init
    while _G.WindHubActive do
        task.wait(0.25)
        pcall(function()
            local t=tracker
            if not t then return end
            local ballCount=0
            for ball in pairs(t.states) do
                if ball and ball.Parent then ballCount+=1 end
            end
            local connCount=0
            for _ in pairs(GameRemotes.connected) do connCount+=1 end
            -- Stats tab
            if statCards["Parries"] then statCards["Parries"].Text=tostring(t.parryCount) end
            if statCards["Avg ETA"] then statCards["Avg ETA"].Text=("%.3fs"):format(t:avgETA()) end
            if statCards["Window"] then statCards["Window"].Text=("%.3fs"):format(t.window) end
            if statCards["Ping"] then statCards["Ping"].Text=tostring(PingComp.pingMs).."ms" end
            if statCards["FPS"] then statCards["FPS"].Text=("%.0f"):format(Prof:fps()) end
            if statCards["Mode"] then statCards["Mode"].Text=Config.parryMode end
            if statCards["Balls"] then statCards["Balls"].Text=tostring(ballCount) end
            -- Parry tab
            windowInfo.Text=("  Window: %.3fs  |  Ping: %dms  |  Mode: %s"):format(
                t.window, PingComp.pingMs, Config.parryMode)
            -- Combat tab
            remoteInfo.Text="  Connected remotes: "..connCount.."/"..#REMOTE_HANDLERS
            replionInfo.Text="  Replion: "..(#Replion.log>0 and "Active ✓" or "Waiting...")
            ballInfo.Text="  Balls tracked: "..ballCount
            -- Status bar
            local threat,eta=t:bestThreat()
            if threat and eta<math.huge then
                statusLbl.Text=("⚡ THREAT  ETA %.3fs  |  %s  |  %d parries"):format(
                    eta,Config.parryMode,t.parryCount)
                statusLbl.TextColor3=eta<0.3 and C.red or (eta<0.7 and C.yellow or C.green)
            else
                statusLbl.Text=("Safe  |  %s  |  %d parries  |  %.0f fps"):format(
                    Config.parryMode,t.parryCount,Prof:fps())
                statusLbl.TextColor3=C.dim
            end
            if Config.printStats then
                print(("[WindHub] parries:%d  window:%.3fs  eta:%.3fs  ping:%dms  fps:%.0f"):format(
                    t.parryCount,t.window,t:avgETA(),PingComp.pingMs,Prof:fps()))
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  INIT
-- ══════════════════════════════════════════════════════════════
tracker=BallTracker.new()

local function connectBallAdded()
    local ok,remote=pcall(function()
        return RepStor:WaitForChild("Remotes",10):WaitForChild("BallAdded",10)
    end)
    if ok and remote and remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(ball)
            if typeof(ball)=="Instance" then
                tracker:track(ball)
                local s=tracker.states[ball]
                if s then s.fired=false end
            end
        end)
    end
end
task.spawn(connectBallAdded)

local ballsFolder=WS:FindFirstChild("Balls") or WS:WaitForChild("Balls",30)
if ballsFolder then
    for _,b in ipairs(ballsFolder:GetChildren()) do tracker:track(b) end
    ballsFolder.ChildAdded:Connect(function(b) tracker:track(b) end)
    ballsFolder.ChildRemoved:Connect(function(b)
        tracker:untrack(b); cleanBallESP(b); cleanArc(b)
    end)
end

startSweep(tracker)

-- ══════════════════════════════════════════════════════════════
--  MAIN LOOP (RunService.PreSimulation — frame-by-frame)
-- ══════════════════════════════════════════════════════════════
local parryBusy=false
local frameCount=0

RS.PreSimulation:Connect(function()
    if not _G.WindHubActive then return end
    Prof:tick()
    local char=lp.Character
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp or not ClientState.alive then return end

    tracker:updateFrame(hrp,os.clock())

    frameCount+=1
    if frameCount%2==0 then
        for ball,state in pairs(tracker.states) do
            updateBallESP(ball,state)
            updateArc(ball,state)
        end
        updatePlayerESP()
    end

    if Config.autoParry and not parryBusy then
        local threat,eta=tracker:bestThreat()
        local replionRecent=(_G.WindHub_ReplionTargeted~=nil)
            and (os.clock()-_G.WindHub_ReplionTargeted)<0.15
        if threat then
            local win2=PingComp:effectiveWindow()
            local mode=Config.parryMode
            local fire=replionRecent
                or mode=="Ultra"
                or (mode=="Predictive"   and eta<=win2)
                or (mode=="Conservative" and eta<=win2*0.55)
            if fire then
                parryBusy=true
                tracker:markParried(threat,eta)
                doAnimFix()
                task.spawn(function()
                    clickParry()
                    task.wait(0.1)
                    parryBusy=false
                end)
            end
        end
    end

    if Config.autoDodge and not parryBusy then
        local threat,eta=tracker:bestThreat()
        if threat and eta<0.75 then
            local vp=threat:FindFirstChild("zoomies")
            if vp then Dodge.attempt(hrp,threat.Position,vp.VectorVelocity) end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    task.wait(1.5)
    notify("WindHub v5.0 loaded!",C.green)
    task.wait(0.3)
    notify("Platform: "..(isMobile and "Mobile" or "PC").."  |  "..Exec.name,C.accent)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("  WindHub v5.0  |  Blade Ball Ultimate")
    print(("  Platform: %s  |  Exec: %s"):format(isMobile and "Mobile" or "PC",Exec.name))
    print(("  Namecall hook: %s  |  Ping: %dms"):format(tostring(namecallHooked),PingComp.pingMs))
    print("  Hotkeys: P O I U Y H G T R F | RCtrl=hide")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end)
