-- Replay of REAL miss report #2 (108 ms): a LONG-RANGE rally. You and an
-- opponent ~60 studs apart hit the ball back and forth at ~100-125 studs/s
-- (the server has StartClash'ed, and the ball reverses each exchange, so the
-- script is in clash mode). In the report the script fired at clash speed the
-- whole time; right after each successful parry (which resets the cooldown)
-- the next clash block was ACCEPTED on nothing and started a fresh 1s cooldown,
-- so the next return (~0.5-1s later) found every block rejected.
-- You survive only if every return to you is parried. Run: lua replay_miss2.lua
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function run(ping, gap, speed)
  local w = assert(build(SRC, ping))
  local v3,Instance,R = w.v3,w.Instance,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local foe=Instance.new("Player"); foe.Name="Foe"
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=v3(0,5,gap); fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=fchar
  foe.Character=fchar; foe.CharacterAdded=R.newSignal(); foe.CharacterRemoving=R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  local b=Instance.new("Part"); b.Name="Rally"; b.Parent=w.Balls
  local function target(n) b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("Rally",n) end
  w.clashCtl.Server.StartClash()
  local z=gap-10; local dir=-1; target("Hero")
  local hist={}; local dt=1/60; local t=0; local parries=0; local spd=speed
  for _=1,60*6 do
    t=t+dt
    z=z+dir*spd*dt
    if dir<0 and z<=8 then                  -- reaches me
      if not w.shieldAt(R.VTIME()) then return false, parries end
      w.server.parryReset(); w.swordCtl.Server.BlockSuccess(1)
      parries=parries+1; dir=1; spd=spd+5; target("Foe")
    elseif dir>0 and z>=gap-8 then          -- reaches the opponent, they hit it back
      dir=-1; spd=spd+5; target("Hero")
    end
    hist[#hist+1]={t=t,z=z,v=dir*spd}
    local sz,sv=z,dir*spd
    for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sz=hist[i].z; sv=hist[i].v break end end
    b.Position=v3(0,5,sz); b.AssemblyLinearVelocity=v3(0,0,sv)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  return true, parries
end

print("=== Replay: real miss report #2 (long-range rally, ~60 studs) ===")
local good,total=0,0
for _,ping in ipairs({60,108,180}) do
  for _,c in ipairs({{60,100},{45,110},{70,120}}) do
    local ok,p=run(ping,c[1],c[2]); total=total+1; if ok then good=good+1 end
    print(string.format("  ping %3d gap %2d speed %3d -> %s after %d parries", ping, c[1], c[2], ok and "SURVIVED 6s" or "DIED", p))
  end
end
print(string.format("\n=== %d/%d survived ===", good, total))
