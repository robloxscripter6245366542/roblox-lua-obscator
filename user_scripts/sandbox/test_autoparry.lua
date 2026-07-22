-- Sandbox: fresh mocked-Roblox world + fresh script load per scenario (no state
-- bleed), driving the real autoparry through a speed x ping sweep and checking
-- whether each ball would actually be PARRIED under the game's block model
-- (0.6s shield + 1s cooldown, from the dump). See README.md.
-- Paths resolve relative to this file's directory, so run it from anywhere.
local HERE = (arg[0] or "test_autoparry.lua"):match("^(.*[/\\])") or "./"
local MOCK_PATH = HERE.."mock_roblox.lua"
local SCRIPT_PATH = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT_PATH,"r")):read("*a")

local function runOne(speed, pingMs)
  local R = dofile(MOCK_PATH)   -- fresh clock/scheduler each run
  local v3, CFrame, Enum, Instance, task = R.v3, R.CFrame, R.Enum, R.Instance, R.task
  local oneway = pingMs/1000/2

  -- server block model: 0.6s shield activating ~half-a-ping after fire, 1s cooldown
  local server = { cooldownUntil=0, shields={}, blocks=0, log={} }
  function server.block(lookY)
    server.blocks = server.blocks+1; server.log[#server.log+1]={t=R.VTIME()}
    local reg = R.VTIME()+oneway
    if reg < server.cooldownUntil then return false end
    server.shields[#server.shields+1]={reg, reg+0.6}
    server.cooldownUntil = reg+1.0
    return true
  end
  local function shieldAt(t) for _,s in ipairs(server.shields) do if t>=s[1] and t<=s[2] then return true end end return false end

  -- world
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
  RF.InvokeServer=function(_,svc,m,a) if svc=="SwordService" and m=="Block" then return server.block(a and a[1]) end end
  local Storage=Instance.new("Folder"); Storage.Name="Storage"; Storage.Parent=RS
  local swordProxy={Block={Invoke=function(_,y) return server.block(y) end}}
  FW._moduleValue={ Fetch=function(_,n) if n=="SwordService" then return swordProxy end return {} end,
                    Get=function(_,n) if n=="BallController" then return {Server={ChangeBallColor=function() end}} end
                                        if n=="MovementController" then return {Dashing=false} end return nil end }

  -- env
  local realmath, realtable = math, table
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
  local ok,e=pcall(chunk); if not ok then return nil, "LOAD ERROR: "..tostring(e) end
  for i=1,6 do R.advance(0.1) end  -- let hooks settle

  -- scenario
  local hl=Instance.new("Highlight"); hl.Name="Highlight"; hl.Parent=heroF
  local ball=Instance.new("Part"); ball.Name="Ball"; ball.Position=v3(0,5,120); ball.AssemblyLinearVelocity=v3(0,0,-speed)
  ball:SetAttribute("Target","Hero")
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.VectorVelocity=v3(0,0,-speed); lv.Parent=ball
  ball.Parent=Balls
  local dt=1/60; local trueZ=120; local firstT,impactT,parried
  local spawnT=R.VTIME()
  for f=1,60*10 do
    trueZ=trueZ-speed*dt
    ball.Position=v3(0,5,trueZ+speed*oneway)  -- stale (client sees ball ~half-a-ping behind)
    RunService.Heartbeat:Fire(); R.advance(dt)
    if server.blocks>0 and not firstT then firstT=server.log[1].t end
    if math.abs(trueZ)<=8 then impactT=R.VTIME(); parried=shieldAt(impactT); break end
    if trueZ<-20 then break end
  end
  local lead=(firstT and impactT) and (impactT-firstT) or nil
  -- A straight ball is committed from spawn, so it is physically blockable only
  -- if its whole travel time is at least the ping round-trip (you see the ball
  -- ~one-way late AND the block registers ~one-way late). Below that, no block -
  -- script or human - can reach the server before impact.
  local unblockable = (not parried) and impactT and ((impactT - spawnT) < 2*oneway)
  return parried, string.format("blk=%3d firstBlock=%s", server.blocks, lead and string.format("%.3fs",lead) or "never"), unblockable
end

local speeds={20,40,60,90,120,160,220,300,400}
local pings={30,100,250}
local pass,unblk,total=0,0,0
for _,pg in ipairs(pings) do
  print(string.format("--- ping %d ms ---", pg))
  for _,sp in ipairs(speeds) do
    total=total+1
    local ok,info,unb=runOne(sp,pg)
    if ok==nil then print(string.format("  s%-3d ERROR %s",sp,info))
    else
      if ok then pass=pass+1 elseif unb then unblk=unblk+1 end
      print(string.format("  s%-3d %s  %s", sp, ok and "PARRIED" or (unb and "UNBLOCKABLE" or "MISS   "), info)) end
  end
end
print(string.format("\n=== %d/%d BLOCKABLE parried  (+%d unblockable: arrive faster than the ping round-trip) ===", pass, total-unblk, unblk))
