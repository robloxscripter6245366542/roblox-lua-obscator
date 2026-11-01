-- Point-blank clash HOLD at real ping, with a REAL (yielding) Block transport.
-- Each Block:Invoke takes a full round-trip to return, and the client caps how
-- many can be in flight, so at high ping the number of blocks that reach the
-- server per second is limited. If the server uses up the shield on each parry,
-- every return needs its OWN fresh block to have arrived - so the block arrival
-- rate decides whether a point-blank clash is held. Both players overlap; the
-- ball comes back to you every RET seconds; a return is held if an unused block
-- arrived within the last 0.6s.  Run: lua pointblank_hold.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function run(ping, RET)
  local w = assert(build(SRC, ping, {yieldTransport=true}))
  local v3,Instance,Enum,R = w.v3,w.Instance,w.Enum,w.R
  local oneway = ping/1000/2
  local arrivals, used = {}, {}
  -- per-parry model: a block arrives at the server half a ping after it's fired;
  -- the Invoke itself returns a full round-trip later.
  w.server.block = function()
    local t0 = R.VTIME(); arrivals[#arrivals+1] = t0 + oneway
    w.server.blocks = w.server.blocks + 1
    R.task.wait(oneway*2)
    return false
  end
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target","Hero"); ball.Parent=w.Balls
  w.clashCtl.Server.StartClash(); w.Eff:SetAttribute("ClashEffect", true)
  local dt=1/60; local nextRet=1.0; local held,total=0,0; local dir=1; local t=0
  for f=1,60*4 do
    t=t+dt
    dir=-dir
    ball:SetAttribute("Target", dir>0 and "Hero" or "Foe")
    ball.Position=v3(0,5,2.5); ball.AssemblyLinearVelocity=v3(0,0,dir*300); lv.VectorVelocity=v3(0,0,dir*300)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
    local now=R.VTIME()
    while now >= nextRet do   -- a return reaches me
      total=total+1
      local ok=false
      for i,a in ipairs(arrivals) do
        if not used[i] and a <= nextRet and a > nextRet-0.6 then used[i]=true; ok=true; break end
      end
      if ok then held=held+1 end
      nextRet=nextRet+RET
    end
  end
  return held,total,w.server.blocks
end

print("=== Point-blank clash hold (yielding Block, shield used up per parry) ===")
local allHeld=true
for _,ping in ipairs({60,130,200}) do
  for _,RET in ipairs({0.1,0.06}) do
    local h,tot,b=run(ping,RET)
    if h<tot then allHeld=false end
    print(string.format("  ping %3d  return every %.2fs -> held %3d/%3d returns  (%d blocks sent in 4s)",ping,RET,h,tot,b))
  end
end
print(allHeld and "\nALL RETURNS HELD" or "\nSOME RETURNS DROPPED")
