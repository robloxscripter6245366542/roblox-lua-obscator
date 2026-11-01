-- Replay of a REAL in-game miss (miss report #1, 153 ms ping):
--  1. a slow ball (~52 -> 60 studs/s) comes at you from 35 studs; you parry it,
--     the target switches away, and the ball keeps drifting in to ~7 studs,
--     then moves away to ~15 studs (aimed at someone else);
--  2. ~0.5s after the parry it comes back at you (target = you again) at 70
--     studs/s and lands ~0.2s later - far less than a reaction at 153 ms.
-- In the real report the script kept spamming blocks at clash speed the whole
-- time the parried ball sat within 22 studs ("point-blank"), one landed on
-- nothing after the parry reset the cooldown, and every block for the return
-- was rejected. You survive only if a block is still available for the return.
-- Run: lua replay_miss1.lua [path-to-autoparry]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function run(ping, backDelay)
  local w = assert(build(SRC, ping))
  local v3,Instance,Enum,R = w.v3,w.Instance,w.Enum,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local b=Instance.new("Part"); b.Name="Replay"
  b:SetAttribute("Target","Hero"); b.Parent=w.Balls
  local z=35; local vz=-52; local phase=1; local tSwitch=0; local hist={}; local dt=1/60; local t=0
  local wasted0
  for _=1,60*5 do
    t=t+dt
    if phase==1 then
      vz=vz-6*dt
      if z<=11 then
        if not w.shieldAt(R.VTIME()) then return false,"first ball not parried" end
        w.server.parryReset()                   -- successful parry resets the cooldown
        w.swordCtl.Server.BlockSuccess(1)
        phase=2; tSwitch=t; b:SetAttribute("Target","Other"); w.ballCtl.Server.ChangeBallColor("Replay","Other")
        wasted0=w.server.landed
      end
    elseif phase==2 then
      -- parried ball drifts in a little more, then away (aimed at someone else)
      if t-tSwitch<0.2 then vz=-20 else vz=40 end
      if t-tSwitch>=backDelay then
        phase=3; vz=-70; b:SetAttribute("Target","Hero"); w.ballCtl.Server.ChangeBallColor("Replay","Hero")
      end
    else
      vz=-70
      if z<=8 then
        local ok=w.shieldAt(R.VTIME())
        return ok, string.format("blocks accepted while the parried ball was leaving: %d", w.server.landed-wasted0)
      end
    end
    z=z+vz*dt
    hist[#hist+1]={t=t,z=z,v=vz}
    local sz,sv=z,vz
    for i=#hist,1,-1 do if hist[i].t<=t-w.oneway then sz=hist[i].z; sv=hist[i].v break end end
    b.Position=v3(0,5,sz); b.AssemblyLinearVelocity=v3(0,0,sv)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  return false,"never resolved"
end

print("=== Replay: real miss report #1 (parry, ball leaves, comes back fast) ===")
local good,total=0,0
for _,ping in ipairs({60,153,200}) do
  for _,back in ipairs({0.45,0.6,0.8}) do
    local ok,why=run(ping,back); total=total+1; if ok then good=good+1 end
    print(string.format("  ping %3d  comes back after %.2fs -> %s  (%s)", ping, back, ok and "SURVIVED" or "DIED", why))
  end
end
print(string.format("\n=== %d/%d survived ===", good, total))
