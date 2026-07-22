-- Comprehensive scenario suite for the autoparry. Fresh mocked world + fresh
-- script load per scenario. Each scenario defines a ball trajectory (stepper),
-- optional player motion, target/invisible attributes, ping and fps. We score
-- whether the ball that WOULD hit you is actually parried (0.6s shield model).
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local MOCK = HERE.."mock_roblox.lua"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")

local function build(pingMs)
  local R = dofile(MOCK)
  local v3,CFrame,Enum,Instance,task = R.v3,R.CFrame,R.Enum,R.Instance,R.task
  local oneway = pingMs/1000/2
  local server = { cooldownUntil=0, shields={}, blocks=0 }
  function server.block() server.blocks=server.blocks+1
    local reg=R.VTIME()+oneway
    if reg<server.cooldownUntil then return false end
    server.shields[#server.shields+1]={reg,reg+0.6}; server.cooldownUntil=reg+1.0; return true end
  local function shieldAt(t) for _,s in ipairs(server.shields) do if t>=s[1] and t<=s[2] then return true end end return false end
  function server.parryReset() server.cooldownUntil = R.VTIME() end

  local Players=Instance.new("Players"); local RunService=Instance.new("RunService"); RunService.Heartbeat=R.newSignal()
  local RS=Instance.new("ReplicatedStorage"); local Stats=Instance.new("Stats"); local WS=Instance.new("Workspace"); WS.Gravity=196.2
  local cam=Instance.new("Camera"); cam.CFrame=CFrame.new(0,0,0); cam.CFrame.LookVector=v3(0,0,-1); WS.CurrentCamera=cam
  local LP=Instance.new("Player"); LP.Name="Hero"; LP.GetNetworkPing=function() return pingMs/1000 end
  local char=Instance.new("Model"); char.Name="Hero"
  local hrp=Instance.new("Part"); hrp.Name="HumanoidRootPart"; hrp.Position=v3(0,5,0); hrp.AssemblyLinearVelocity=v3(0,0,0); hrp.Parent=char
  local hum=Instance.new("Humanoid"); hum.WalkSpeed=16; hum.FloorMaterial=Enum.Material.Plastic; hum.Parent=char
  LP.Character=char; LP.CharacterAdded=R.newSignal(); LP.CharacterRemoving=R.newSignal()
  Players.PlayerAdded=R.newSignal(); Players.PlayerRemoving=R.newSignal(); Players.LocalPlayer=LP
  Players.GetPlayers=function() return {LP} end
  local netf=Instance.new("Folder"); netf.Name="Network"; netf.Parent=Stats
  netf.ServerStatsItem=setmetatable({},{__index=function() return {GetValue=function() return pingMs end} end})
  local Balls=Instance.new("Folder"); Balls.Name="Balls"; Balls.Parent=WS
  local heroF=Instance.new("Folder"); heroF.Name="Hero"; heroF.Parent=WS
  local Eff=Instance.new("Folder"); Eff.Name="Effects"; Eff.Parent=WS
  local FW=Instance.new("ModuleScript"); FW.Name="Framework"; FW.Parent=RS
  local RF=Instance.new("RemoteFunction"); RF.Name="RemoteFunction"; RF.Parent=FW
  RF.InvokeServer=function(_,svc,m,a) if svc=="SwordService" and m=="Block" then return server.block() end end
  local Storage=Instance.new("Folder"); Storage.Name="Storage"; Storage.Parent=RS
  local swordProxy={Block={Invoke=function() return server.block() end}}
  FW._moduleValue={ Fetch=function(_,n) if n=="SwordService" then return swordProxy end return {} end,
                    Get=function(_,n) if n=="BallController" then return {Server={ChangeBallColor=function() end}} end
                                        if n=="MovementController" then return {Dashing=false} end return nil end }
  local realmath,realtable=math,table
  local envmath=setmetatable({clamp=function(x,l,h) return realmath.max(l,realmath.min(h,x)) end,
    round=function(x) return realmath.floor(x+0.5) end, sign=function(x) return x>0 and 1 or (x<0 and -1 or 0) end},{__index=realmath})
  local envtable=setmetatable({pack=function(...) local t={...}; t.n=select("#",...); return t end, unpack=unpack,
    find=function(t,val) for i,x in ipairs(t) do if x==val then return i end end end, clear=function(t) for k in pairs(t) do t[k]=nil end end},{__index=realtable})
  local env={}
  local function typeof(x) if type(x)~="table" then return type(x) end if rawget(x,"_children")~=nil then return "Instance" end
    local mt=getmetatable(x) if mt==R.Vector3 then return "Vector3" end if mt==R.CFrame then return "CFrame" end return "table" end
  local WINDUI=[[local W={} local function chain() local t={} setmetatable(t,{__index=function() return function() return chain() end end}) t.SetDesc=function() end return t end
    W.AddTheme=function() end W.SetTheme=function() end W.Notify=function() end
    W.CreateWindow=function() local w=chain() w.Tab=function() return chain() end w.SetBackgroundTransparency=function() end
    w.ConfigManager={Config=function() return {Save=function() return true end,Load=function() return true end} end, CreateConfig=function() return {Save=function() return true end,Load=function() return true end} end}
    w.Destroy=function() end return w end return W]]
  local game={ GetService=function(_,n)
      if n=="Players" then return Players elseif n=="ReplicatedStorage" then return RS elseif n=="RunService" then return RunService
      elseif n=="Stats" then return Stats elseif n=="Workspace" then return WS elseif n=="Debris" then return {AddItem=function() end}
      elseif n=="TweenService" then return {Create=function() return {Play=function() end,Completed=R.newSignal()} end} else return Instance.new(n) end end,
    HttpGet=function() return WINDUI end }
  env.game=game; env.workspace=WS; env.Workspace=WS; env.Instance=Instance; env.Vector3=R.Vector3; env.CFrame=R.CFrame
  env.Color3=R.Color3; env.ColorSequence=R.ColorSequence; env.UDim2=R.UDim2; env.UDim=R.UDim; env.Enum=Enum; env.task=task
  env.tick=function() return R.VTIME() end; env.time=env.tick; env.wait=function(t) return task.wait(t) end
  env.spawn=function(f) return task.spawn(f) end; env.delay=function(t,f) return task.delay(t,f) end
  env.typeof=typeof; env.warn=function() end; env.print=print; env.error=error; env.assert=assert; env.pcall=pcall; env.xpcall=xpcall
  env.select=select; env.pairs=pairs; env.ipairs=ipairs; env.next=next; env.type=type; env.tostring=tostring; env.tonumber=tonumber
  env.setmetatable=setmetatable; env.getmetatable=getmetatable; env.rawget=rawget; env.rawset=rawset; env.rawequal=rawequal
  env.unpack=unpack; env.math=envmath; env.table=envtable; env.string=string; env.coroutine=coroutine
  env.os={clock=function() return R.VTIME() end, time=function() return R.VTIME() end}
  env.require=function(x) if type(x)=="table" and x._moduleValue then return x._moduleValue end error("require unknown") end
  env.getgenv=function() return env._genv end; env._genv={}; env.setclipboard=function() end; env.toclipboard=function() end
  env.loadstring=function(s,n) local f,e=loadstring(s,n) if not f then return nil,e end setfenv(f,env) return f end
  env._G=env; setmetatable(env,{__index=function() return nil end})
  local chunk=assert(loadstring(SRC,"@autoparry")); setfenv(chunk,env)
  local ok,e=pcall(chunk); if not ok then return nil,"LOAD ERROR: "..tostring(e) end
  for i=1,6 do R.advance(0.1) end
  return { R=R,v3=v3,Instance=Instance,Enum=Enum,RunService=RunService,Balls=Balls,heroF=heroF,Eff=Eff,
           hrp=hrp,server=server,shieldAt=shieldAt,oneway=oneway }
end

-- run a scenario spec -> "PARRIED" / "MISS" / "no-hit" / error
local function run(spec)
  local w = build(spec.ping)
  if not w then return "LOADERR" end
  local R,v3,Instance,Enum = w.R,w.v3,w.Instance,w.Enum
  local hl=Instance.new("Highlight"); hl.Name="Highlight"
  if spec.target ~= false then hl.Parent=w.heroF end   -- targeted highlight unless invisible/unassigned
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  if spec.target ~= false and spec.target ~= nil then ball:SetAttribute("Target", spec.target) end
  if spec.invisible then ball:SetAttribute("Invisible", true) end
  ball.Parent=w.Balls
  local fps = spec.fps or 60
  local hist = {}   -- history of {t,pos,vel} for staleness
  local function stale(field, t)
    local target=t-w.oneway
    if target<=0 or #hist==0 then return hist[1] and hist[1][field] end
    for i=#hist,1,-1 do if hist[i].t<=target then return hist[i][field] end end
    return hist[1][field]
  end
  local dt0=1/fps
  local parried, hit = nil, false
  local st = spec.step()   -- stepper instance
  local t=0
  local lastUncommittedT = 0   -- last time the ball was NOT heading (mostly) at you
  for f=1,fps*8 do
    -- jitter frames if requested
    local dt = dt0
    if spec.jitter and (f%20==0) then dt = dt0 + spec.jitter end
    t = t + dt
    local tpos,tvel = st(dt, w.hrp.Position)
    hist[#hist+1]={t=t,pos=tpos,vel=tvel}
    -- player motion
    if spec.playerStep then local pp,pv=spec.playerStep(t); w.hrp.Position=pp; w.hrp.AssemblyLinearVelocity=pv end
    -- commit tracking: true closing speed toward you vs the ball's raw speed.
    local to=(w.hrp.Position - tpos); local dd=to.Magnitude; local sp=tvel.Magnitude
    local closing = (dd>1e-3 and sp>1e-3) and (tvel.X*to.X+tvel.Y*to.Y+tvel.Z*to.Z)/dd or 0
    if sp<1e-3 or closing < 0.8*sp then lastUncommittedT = t end   -- not yet committed at you
    -- show stale pos/vel to the client
    local spos=stale("pos",t) or tpos; local svel=stale("vel",t) or tvel
    ball.Position=spos; ball.AssemblyLinearVelocity=svel; lv.VectorVelocity=svel
    w.RunService.Heartbeat:Fire(); R.advance(dt)
    -- true impact
    local d=(w.hrp.Position - tpos).Magnitude
    if d<=8 then hit=true; parried=w.shieldAt(R.VTIME())
      if parried then w.server.parryReset() end
      -- physically blockable only if warning from commit >= round-trip
      -- (you see the ball ~one-way late AND the block registers ~one-way late).
      local warning = t - lastUncommittedT   -- relative sim time (both in `t`)
      if not parried and warning < 2*w.oneway then return "UNBLOCKABLE" end
      break end
    if tpos.Z < -30 then break end
  end
  if not hit then return "no-hit" end
  return parried and "PARRIED" or "MISS"
end

-- ---- stepper factories (return a function(dt, heroPos)->pos,vel) ----
local V=dofile(MOCK).v3
local function straight(speed, startZ, startX)
  local x=startX or 0; local z=startZ or 120
  return function(dt) z=z-speed*dt; return V(x,5,z), V(0,0,-speed) end
end
local function homing(speed, turnRate, startZ, startX)
  local pos=V(startX or 30,5,startZ or 120)
  local vel=V(-(startX or 30),0,-(startZ or 120)); local m=vel.Magnitude; vel=V(vel.X/m*speed,0,vel.Z/m*speed)
  return function(dt, hero)
    local desired=(hero-pos); local dm=desired.Magnitude; if dm>1e-3 then desired=V(desired.X/dm,0,desired.Z/dm) else desired=vel end
    -- rotate vel toward desired by up to turnRate*dt
    local vdir=vel; local vm=vdir.Magnitude; vdir=V(vdir.X/vm,0,vdir.Z/vm)
    local dot=math.max(-1,math.min(1, vdir.X*desired.X+vdir.Z*desired.Z))
    local ang=math.acos(dot); local step=math.min(ang, turnRate*dt)
    -- rotate vdir by step toward desired (2D)
    local cross = vdir.X*desired.Z - vdir.Z*desired.X
    local s = (cross<0) and 1 or -1
    local c=math.cos(step*s); local sn=math.sin(step*s)
    local nx=vdir.X*c - vdir.Z*sn; local nz=vdir.X*sn + vdir.Z*c
    vel=V(nx*speed,0,nz*speed); pos=pos+V(vel.X*dt,0,vel.Z*dt)
    return pos, vel
  end
end
local function sideThenIn(speed, startX)
  -- flies sideways across, then curves in at the end (Wind-Shuriken-ish)
  local pos=V(startX or 60,5,40); local phase=0
  return function(dt,hero)
    phase=phase+dt
    local vel
    if phase<0.6 then vel=V(-speed,0,0) else vel=(hero-pos); local m=vel.Magnitude; vel=V(vel.X/m*speed,0,vel.Z/m*speed) end
    pos=pos+V(vel.X*dt,vel.Y and 0 or 0,vel.Z*dt)
    return pos, vel
  end
end
local function accel(startSpeed, a, startZ)
  local z=startZ or 130; local sp=startSpeed
  return function(dt) sp=sp+a*dt; z=z-sp*dt; return V(0,5,z), V(0,0,-sp) end
end

-- ---- build scenario list ----
local scn = {}
local pings={20,90,180,300}
local function add(name, mk) scn[#scn+1]={name=name, mk=mk} end

for _,sp in ipairs({20,60,120,200,320}) do add("straight s"..sp, function(pg) return {ping=pg, step=function() return straight(sp) end, target="Hero"} end) end
for _,sp in ipairs({40,120,220}) do add("homing s"..sp, function(pg) return {ping=pg, step=function() return homing(sp,6) end, target="Hero"} end) end
for _,sp in ipairs({120,220}) do add("sideThenIn s"..sp, function(pg) return {ping=pg, step=function() return sideThenIn(sp) end, target="Hero"} end) end
add("accel 30->300", function(pg) return {ping=pg, step=function() return accel(30,120) end, target="Hero"} end)
for _,sp in ipairs({60,160}) do add("closeSpawn40 s"..sp, function(pg) return {ping=pg, step=function() return straight(sp,40) end, target="Hero"} end) end
for _,sp in ipairs({80,180}) do add("invisible s"..sp, function(pg) return {ping=pg, step=function() return straight(sp) end, target=false, invisible=true} end) end
for _,sp in ipairs({80,180}) do add("unassigned s"..sp, function(pg) return {ping=pg, step=function() return straight(sp) end, target=false} end) end
for _,fps in ipairs({30,144}) do add("straight s160 @"..fps.."fps", function(pg) return {ping=pg, fps=fps, step=function() return straight(160) end, target="Hero"} end) end
add("jitter s160", function(pg) return {ping=pg, jitter=0.12, step=function() return straight(160) end, target="Hero"} end)
add("playerDashIn s120", function(pg) return {ping=pg, step=function() return straight(120) end, target="Hero",
  playerStep=function(t) local z = (t<0.5) and 0 or math.min(0, -90*(t-0.5)); return V(0,5,z), V(0,0, (t>=0.5 and -90 or 0)) end} end)

local pass,total,unblk,misses,unblkList=0,0,0,{},{}
for _,s in ipairs(scn) do
  for _,pg in ipairs(pings) do
    total=total+1
    local spec=s.mk(pg)
    local ok,res=pcall(run, spec)
    res = ok and res or ("ERR:"..tostring(res))
    if res=="PARRIED" or res=="no-hit" then pass=pass+1
    elseif res=="UNBLOCKABLE" then unblk=unblk+1; unblkList[#unblkList+1]=string.format("%s @ping%d", s.name, pg)
    else misses[#misses+1]=string.format("%s @ping%d -> %s", s.name, pg, res) end
  end
end
local blockable = total - unblk
print(string.format("=== %d/%d BLOCKABLE balls parried  (+%d physically unblockable = arrive faster than ping round-trip) ===",
  pass, blockable, unblk))
if #unblkList>0 then print("Unblockable (latency-bound, not script failures):"); for _,m in ipairs(unblkList) do print("  "..m) end end
if #misses>0 then print("REAL MISSES:"); for _,m in ipairs(misses) do print("  "..m) end else print("NO REAL MISSES") end
