-- Clash simulator: a ball ping-pongs between you and an opponent who DASHES
-- INSIDE you, reversing many times per second at point-blank range. Models the
-- real clash rule from the dump: a SUCCESSFUL parry RESETS the block cooldown,
-- so continuous fire can hold a clash indefinitely - IF the script keeps a 0.6s
-- shield up every time the ball returns. We score whether YOU hold (never eat an
-- unshielded return) as the opponent closes to point-blank and the exchange
-- speeds up. Run: lua clash_test.lua [path-to-autoparry]
local HERE=(arg[0] or ""):match("^(.*[/\\])") or "./"
local MOCK=HERE.."mock_roblox.lua"
local SCRIPT=arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC=assert(io.open(SCRIPT,"r")):read("*a")

local function run(S, Dstart, Dend, dashT, ping, fps)
  local R=dofile(MOCK); local v3,CFrame,Enum,Instance,task=R.v3,R.CFrame,R.Enum,R.Instance,R.task
  local oneway=ping/1000/2
  -- server: our block -> 0.6s shield (registers ~half-ping late), 1s cooldown,
  -- reset on a successful parry.
  local server={cooldownUntil=0,shields={},blocks=0}
  function server.block() server.blocks=server.blocks+1
    local reg=R.VTIME()+oneway; if reg<server.cooldownUntil then return false end
    server.shields[#server.shields+1]={reg,reg+0.6}; server.cooldownUntil=reg+1.0; return true end
  local function shieldAt(t) for _,s in ipairs(server.shields) do if t>=s[1] and t<=s[2] then return true end end return false end
  function server.parryReset() server.cooldownUntil=R.VTIME() end

  local Players=Instance.new("Players"); local RunService=Instance.new("RunService"); RunService.Heartbeat=R.newSignal()
  local RS=Instance.new("ReplicatedStorage"); local Stats=Instance.new("Stats"); local WS=Instance.new("Workspace"); WS.Gravity=196.2
  local cam=Instance.new("Camera"); cam.CFrame=CFrame.new(0,0,0); cam.CFrame.LookVector=v3(0,0,-1); WS.CurrentCamera=cam
  local LP=Instance.new("Player"); LP.Name="Hero"; LP.GetNetworkPing=function() return ping/1000 end
  local char=Instance.new("Model"); char.Name="Hero"
  local hrp=Instance.new("Part"); hrp.Name="HumanoidRootPart"; hrp.Position=v3(0,5,0); hrp.AssemblyLinearVelocity=v3(0,0,0); hrp.Parent=char
  local hum=Instance.new("Humanoid"); hum.WalkSpeed=16; hum.FloorMaterial=Enum.Material.Plastic; hum.Parent=char
  LP.Character=char; LP.CharacterAdded=R.newSignal(); LP.CharacterRemoving=R.newSignal()
  -- opponent
  local FOE=Instance.new("Player"); FOE.Name="Foe"; FOE.GetNetworkPing=function() return ping/1000 end
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,Dstart); fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=fchar
  local fhum=Instance.new("Humanoid"); fhum.WalkSpeed=16; fhum.FloorMaterial=Enum.Material.Plastic; fhum.Parent=fchar
  FOE.Character=fchar; FOE.CharacterAdded=R.newSignal(); FOE.CharacterRemoving=R.newSignal()
  Players.PlayerAdded=R.newSignal(); Players.PlayerRemoving=R.newSignal(); Players.LocalPlayer=LP
  Players.GetPlayers=function() return {LP,FOE} end
  local netf=Instance.new("Folder"); netf.Name="Network"; netf.Parent=Stats
  netf.ServerStatsItem=setmetatable({},{__index=function() return {GetValue=function() return ping end} end})
  local Balls=Instance.new("Folder"); Balls.Name="Balls"; Balls.Parent=WS
  local heroF=Instance.new("Folder"); heroF.Name="Hero"; heroF.Parent=WS
  local Eff=Instance.new("Folder"); Eff.Name="Effects"; Eff.Parent=WS
  local FW=Instance.new("ModuleScript"); FW.Name="Framework"; FW.Parent=RS
  local RFn=Instance.new("RemoteFunction"); RFn.Name="RemoteFunction"; RFn.Parent=FW
  RFn.InvokeServer=function(_,svc,m) if svc=="SwordService" and m=="Block" then return server.block() end end
  Instance.new("Folder").Parent=RS
  local swordProxy={Block={Invoke=function() return server.block() end}}
  FW._moduleValue={Fetch=function(_,n) if n=="SwordService" then return swordProxy end return {} end,
                   Get=function(_,n) if n=="BallController" then return {Server={ChangeBallColor=function() end}} end
                                       if n=="MovementController" then return {Dashing=false} end return nil end}
  local rm,rt=math,table
  local envmath=setmetatable({clamp=function(x,l,h) return rm.max(l,rm.min(h,x)) end,round=function(x) return rm.floor(x+0.5) end,sign=function(x) return x>0 and 1 or (x<0 and -1 or 0) end},{__index=rm})
  local envtable=setmetatable({pack=function(...) local t={...}; t.n=select("#",...); return t end,unpack=unpack,find=function(t,val) for i,x in ipairs(t) do if x==val then return i end end end,clear=function(t) for k in pairs(t) do t[k]=nil end end},{__index=rt})
  local env={}
  local function typeof(x) if type(x)~="table" then return type(x) end if rawget(x,"_children")~=nil then return "Instance" end local mt=getmetatable(x) if mt==R.Vector3 then return "Vector3" end if mt==R.CFrame then return "CFrame" end return "table" end
  local WINDUI=[[local W={} local function chain() local t={} setmetatable(t,{__index=function() return function() return chain() end end}) t.SetDesc=function() end return t end
    W.AddTheme=function() end W.SetTheme=function() end W.Notify=function() end W.CreateWindow=function() local w=chain() w.Tab=function() return chain() end w.SetBackgroundTransparency=function() end w.ConfigManager={Config=function() return {Save=function() return true end,Load=function() return true end} end,CreateConfig=function() return {Save=function() return true end,Load=function() return true end} end} w.Destroy=function() end return w end return W]]
  local game={GetService=function(_,n) if n=="Players" then return Players elseif n=="ReplicatedStorage" then return RS elseif n=="RunService" then return RunService elseif n=="Stats" then return Stats elseif n=="Workspace" then return WS elseif n=="Debris" then return {AddItem=function() end} elseif n=="TweenService" then return {Create=function() return {Play=function() end,Completed=R.newSignal()} end} else return Instance.new(n) end end, HttpGet=function() return WINDUI end}
  env.game=game; env.workspace=WS; env.Workspace=WS; env.Instance=Instance; env.Vector3=R.Vector3; env.CFrame=R.CFrame
  env.Color3=R.Color3; env.ColorSequence=R.ColorSequence; env.UDim2=R.UDim2; env.UDim=R.UDim; env.Enum=Enum; env.task=task
  env.tick=function() return R.VTIME() end; env.time=env.tick; env.wait=function(t) return task.wait(t) end
  env.spawn=function(f) return task.spawn(f) end; env.delay=function(t,f) return task.delay(t,f) end
  env.typeof=typeof; env.warn=function() end; env.print=print; env.error=error; env.assert=assert; env.pcall=pcall; env.xpcall=xpcall
  env.select=select; env.pairs=pairs; env.ipairs=ipairs; env.next=next; env.type=type; env.tostring=tostring; env.tonumber=tonumber
  env.setmetatable=setmetatable; env.getmetatable=getmetatable; env.rawget=rawget; env.rawset=rawset; env.rawequal=rawequal
  env.unpack=unpack; env.math=envmath; env.table=envtable; env.string=string; env.coroutine=coroutine
  env.os={clock=function() return R.VTIME() end,time=function() return R.VTIME() end}
  env.require=function(x) if type(x)=="table" and x._moduleValue then return x._moduleValue end error("require") end
  env.getgenv=function() return env._genv end; env._genv={}; env.setclipboard=function() end; env.toclipboard=function() end
  env.loadstring=function(s,n) local f,e=loadstring(s,n) if not f then return nil,e end setfenv(f,env) return f end
  env._G=env; setmetatable(env,{__index=function() return nil end})
  local chunk=assert(loadstring(SRC,"@autoparry")); setfenv(chunk,env)
  local ok,e=pcall(chunk); if not ok then return nil,"LOAD:"..tostring(e) end
  for i=1,6 do R.advance(0.1) end

  -- ball ping-ponging between us (z=0) and Foe (z=D)
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World; lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball.Parent=Balls
  Eff:SetAttribute("ClashEffect", true); ball:SetAttribute("ClashEffect", true)
  local dt=1/fps
  local warmup=0.8
  local z=Dstart; local dir=-1   -- start on the opponent side, heading toward us
  local histP={}; local histV={}
  local function pushStale(p,vv,t) histP[#histP+1]={t=t,v=p}; histV[#histV+1]={t=t,v=vv} end
  local function stalev(h,t) local tt=t-oneway; for i=#h,1,-1 do if h[i].t<=tt then return h[i].v end end return h[1] and h[1].v end
  local parries, dropped, t = 0, false, 0
  for f=1,fps*5 do
    t=t+dt
    -- opponent holds at Dstart during warm-up, THEN dashes inside to Dend
    local D = (t<warmup) and Dstart or (Dstart + (Dend-Dstart)*math.min(1,(t-warmup)/dashT))
    fhrp.Position=v3(0,5,D)
    z = z + dir*S*dt
    if dir>0 and z>=D then z=D; dir=-1; ball:SetAttribute("Target","Hero") end
    if dir<0 and z<=0 then
      -- ball reached US. Seed the FIRST exchange as established (you started the
      -- clash by parrying), then require a live shield on every RETURN - that is
      -- the "can you sustain it as they dash inside" test the user is asking about.
      if parries==0 then
        -- being mid-clash means you JUST parried, so a 0.6s shield is live now
        parries=1; server.shields[#server.shields+1]={R.VTIME(), R.VTIME()+0.6}; server.parryReset()
        z=0; dir=1; ball:SetAttribute("Target","Foe")
      elseif shieldAt(R.VTIME()) then parries=parries+1; server.parryReset(); z=0; dir=1; ball:SetAttribute("Target","Foe")
      else dropped=true; break end
    end
    -- present the (stale) ball to the client, keep clash attributes live
    local truePos=v3(0,5,z); local trueVel=v3(0,0,dir*S)
    pushStale(truePos, trueVel, t)
    local sp=stalev(histP,t) or truePos; local sv=stalev(histV,t) or trueVel
    ball.Position=sp; ball.AssemblyLinearVelocity=sv; lv.VectorVelocity=sv
    Eff:SetAttribute("ClashEffect", true)   -- game holds ClashEffect during a clash
    RunService.Heartbeat:Fire(); R.advance(dt)
  end
  return (not dropped), parries
end

local cases = {
  {name="normal clash            S150 D30->10", S=150, Ds=30, De=10, dash=1.5},
  {name="fast clash              S250 D20->6",  S=250, Ds=20, De=6,  dash=1.2},
  {name="dash INSIDE point-blank  S250 D25->3", S=250, Ds=25, De=3,  dash=0.8},
  {name="super-fast inside        S400 D15->2", S=400, Ds=15, De=2,  dash=0.6},
  {name="instant inside           S600 D8->2",  S=600, Ds=8,  De=2,  dash=0.4},
}
local pings={30,120,250}
print("Clash HOLD test - opponent dashes INSIDE you, ball ping-pongs point-blank.")
print("HELD = shield stayed up on every return (clash sustained); (n) = parries.\n")
local allHeld=true
for _,c in ipairs(cases) do
  local line=c.name
  for _,pg in ipairs(pings) do
    local held,parries = run(c.S,c.Ds,c.De,c.dash,pg,60)
    if not held then allHeld=false end
    line=line..string.format("  | p%d: %s(%d)", pg, held and "HELD" or "DROPPED", parries or 0)
  end
  print(line)
end
print("\n"..(allHeld and "=== ALL CLASHES HELD (no drop) ===" or "=== SOME CLASHES DROPPED ==="))
