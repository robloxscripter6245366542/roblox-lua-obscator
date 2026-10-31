-- Fast close RETURN: an opponent near you parries the ball straight back at
-- you, faster each hit. Once it turns toward you it lands in
-- (distance - hit radius) / speed seconds - often LESS than your ping, so a
-- block fired only after the ball turns can't reach the server in time. The
-- shield has to be up already. Scored like every other suite: a 0.6s shield
-- registering half-a-ping after it's fired, 1s cooldown, reset by a parry.
-- Run: lua return_test.lua [path-to-autoparry]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function run(ping, gap, speed)
  local w = assert(build(SRC, ping))
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  for _=1,30 do w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end
  local foe=Instance.new("Player"); foe.Name="Foe"
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,gap); fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=fchar
  foe.Character=fchar; foe.CharacterAdded=w.R.newSignal(); foe.CharacterRemoving=w.R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  local b=Instance.new("Part"); b.Name="RetBall"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=b
  -- the ball comes at the foe from the SIDE (never near me), then the foe
  -- hits it straight back at me 1.2x faster
  local truePos=v3(70,5,gap); local vel=v3(-speed,0,0); local tgt="Foe"
  b:SetAttribute("Target",tgt); b.Parent=w.Balls
  local hist={}; local dt=1/60; local t=0; local returned=false
  for _=1,60*4 do
    t=t+dt
    truePos=truePos+v3(vel.X*dt,vel.Y*dt,vel.Z*dt)
    if not returned and (truePos-fhrp.Position).Magnitude<=8 then
      returned=true; vel=v3(0,0,-speed*1.2); tgt="Hero"
      b:SetAttribute("Target",tgt); w.ballCtl.Server.ChangeBallColor("RetBall","Hero")
    end
    hist[#hist+1]={t=t,p=truePos,v=vel}
    local sp,sv=truePos,vel
    for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv; lv.VectorVelocity=sv
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    if returned and (w.hrp.Position-truePos).Magnitude<=8 then return w.shieldAt(w.R.VTIME()), w.server.blocks end
  end
  return nil, w.server.blocks
end

print("=== Fast close RETURN: opponent near you hits it straight back ===")
print("gap = studs between you; return speed = 1.2x incoming; window = time the return takes to reach you")
local held, lost = 0, 0
for _,ping in ipairs({60,120,200}) do
  for _,c in ipairs({{25,150},{20,200},{15,250},{25,300}}) do
    local gap,speed=c[1],c[2]
    local window=(gap-8)/(speed*1.2)
    local ok,blocks=run(ping,gap,speed)
    if ok then held=held+1 else lost=lost+1 end
    print(string.format("  ping %3d gap %2d speed %3d  return window %.3fs (ping %.3fs) -> %s  (%d blocks)",
      ping,gap,speed,window,ping/1000, ok and "PARRIED" or "MISSED", blocks))
  end
end
print(string.format("\n=== %d parried, %d missed ===", held, lost))
