-- Shared mocked-Roblox world builder for the sandbox test suites.
-- build(SRC, pingMs) loads the real autoparry SRC into a fresh mocked world
-- (own virtual clock, block server model, ping) and returns handles the tests
-- drive. Factored out of test_scenarios.lua so several suites reuse one world.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local MOCK = HERE.."mock_roblox.lua"

-- opts.yieldTransport: when true, a Block call behaves like a REAL Roblox
-- RemoteFunction - it YIELDS for a full round-trip (task.wait(ping)) before it
-- returns the server's verdict. That is only possible offline because we hand
-- the script a yieldable pcall below (Luau allows a yield to cross pcall; stock
-- Lua 5.1's C pcall does not, so we replace it). server.inflight /
-- server.peakInflight count how many Block calls are waiting on the server at
-- once, so a test can prove the client's in-flight guard holds it at 1 (no
-- backlog). Default (no opts) keeps the fast synchronous transport.
local function build(SRC, pingMs, opts)
  opts = opts or {}
  local R = dofile(MOCK)
  local v3,CFrame,Enum,Instance,task = R.v3,R.CFrame,R.Enum,R.Instance,R.task
  local oneway = pingMs/1000/2
  -- server block model: 0.6s shield registering ~half-a-ping after fire, 1s
  -- cooldown, and a successful parry resets the cooldown (the clash rule).
  -- blocks = SENT (every Invoke that reached the server), landed = accepted (a
  -- fresh shield), rejected = refused on cooldown. Mirrors the script's HUD
  -- Blocks Sent / Landed / Rejected counters.
  local server = { cooldownUntil=0, shields={}, blocks=0, landed=0, rejected=0, inflight=0, peakInflight=0 }
  function server.block() server.blocks=server.blocks+1
    server.inflight=server.inflight+1
    if server.inflight>server.peakInflight then server.peakInflight=server.inflight end
    if opts.yieldTransport then task.wait(oneway*2) end   -- real round-trip yield
    server.inflight=server.inflight-1
    local reg=R.VTIME()+oneway
    if reg<server.cooldownUntil then server.rejected=server.rejected+1; return false end
    server.shields[#server.shields+1]={reg,reg+0.6}; server.cooldownUntil=reg+1.0
    server.landed=server.landed+1; return true end
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
  local players={LP}
  Players.PlayerAdded=R.newSignal(); Players.PlayerRemoving=R.newSignal(); Players.LocalPlayer=LP
  Players.GetPlayers=function() return players end
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
  -- MovementController mock with a counting ForceDash (mirrors the game's dash:
  -- respects CanDash + cooldown). dashCount lets a test see the auto-dash-out fire.
  local movement={ Dashing=false, CanDash=true, dashCount=0 }
  function movement.ForceDash() if movement.CanDash==false then return end
    movement.dashCount=movement.dashCount+1; movement.CanDash=false
    task.delay(1.1, function() movement.CanDash=true end) end
  FW._moduleValue={ Fetch=function(_,n) if n=="SwordService" then return swordProxy end return {} end,
                    Get=function(_,n) if n=="BallController" then return {Server={ChangeBallColor=function() end}} end
                                        if n=="MovementController" then return movement end return nil end }
  local realmath,realtable=math,table
  local envmath=setmetatable({clamp=function(x,l,h) return realmath.max(l,realmath.min(h,x)) end,
    round=function(x) return realmath.floor(x+0.5) end, sign=function(x) return x>0 and 1 or (x<0 and -1 or 0) end},{__index=realmath})
  local envtable=setmetatable({pack=function(...) local t={...}; t.n=select("#",...); return t end, unpack=unpack,
    find=function(t,val) for i,x in ipairs(t) do if x==val then return i end end end, clear=function(t) for k in pairs(t) do t[k]=nil end end},{__index=realtable})
  local env={}
  -- Yieldable pcall / xpcall (Luau semantics on stock Lua 5.1). Luau lets a
  -- coroutine.yield cross a pcall; stock 5.1's C pcall does not ("attempt to
  -- yield across a C-call boundary"). The autoparry fires its block through a
  -- pcall around a *yielding* RemoteFunction, so to model that faithfully we run
  -- the protected call in a child coroutine and pump any yields (a task.wait
  -- inside the RemoteFunction) up to our own caller - suspending the whole chain
  -- exactly like a real Invoke - while still catching errors as (false, err).
  local function ypcall(f, ...)
    local co = coroutine.create(f)
    local r = {coroutine.resume(co, ...)}
    while coroutine.status(co) ~= "dead" do
      r = {coroutine.resume(co, coroutine.yield(unpack(r, 2)))}
    end
    return unpack(r)
  end
  local function yxpcall(f, handler, ...)
    local ok, a, b, c, d = ypcall(f, ...)
    if ok then return ok, a, b, c, d end
    return false, handler(a)
  end
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
  env.typeof=typeof; env.warn=function() end; env.print=print; env.error=error; env.assert=assert; env.pcall=ypcall; env.xpcall=yxpcall
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
           Players=Players,players=players,LP=LP,char=char,
           hrp=hrp,char_ref=char,server=server,shieldAt=shieldAt,oneway=oneway,movement=movement }
end

return { build=build }
