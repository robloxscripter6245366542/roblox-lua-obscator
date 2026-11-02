-- Replay of REAL miss report #4 (119 ms): a very FAST long-range rally. You and
-- an opponent ~55 studs apart, the ball speeding up to 370-400 studs/s. After
-- each hit the ball leaves well off the line and HOMES onto its target, so it
-- loops: in the report each round trip took ~0.55-0.65s at ~390 studs/s.
-- What the report showed, and this test models:
--  * the ball you SEE trails the real one by half a ping PLUS Roblox's
--    interpolation (~0.13s) - you died with it still ~49 studs away on screen;
--  * its Target attribute only trails by half a ping (it flipped ~0.14s before
--    the ball visibly turned);
--  * outside a game clash the server REFUSES a block while your shield is up,
--    even after a parry reset the cooldown (shieldLock) - every block for 0.6s
--    after one went up was rejected, the first to land as it ended was accepted.
-- The miss: a shield parried the ball, the stale view still showed it coming,
-- Auto Spam kept firing, the block that landed as that shield ended started a
-- fresh 1s cooldown on a ball already flying away, and its shield ran out
-- 0.03s before the opponent's return. Also seen: the parry range stuck at ~30
-- studs (W=0 at 46 studs, 400 studs/s) and the arc calling the homing ball a
-- miss (arr=inf). Run: lua replay_miss4.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
SRC = SRC:gsub('setting%("ClashSpeed", 85%)', 'setting("ClashSpeed", 95)')
local build = dofile(HERE.."world.lua").build

local DUR = 8
local function run(ping, gap, offDeg, radius, interp, spd0)
  local w = assert(build(SRC, ping, {shieldLock=true, yieldTransport=true}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  local sends = {}
  do local ob=w.server.block; w.server.block=function(...)
    local sd={R.VTIME(), "pending"}; sends[#sends+1]=sd
    local r=ob(...); sd[2]=r; return r end end
  -- A death "at the shield gap": the script had sent the next block on the
  -- first frame the game allows one (0.6s after the accepted one), and either
  -- the ball came within 35 ms after my shield ended (that block lands a frame
  -- later) or the block landed in the very frame the shield ended and was
  -- refused (under shieldLock; the next try is a round trip away).
  local function atGap(t)
    local last
    for _,sh in ipairs(w.server.shields) do if sh[2] <= t and (not last or sh[2] > last[2]) then last = sh end end
    if not last then return false end
    local sentAt = last[1] - w.oneway
    for _,sd in ipairs(sends) do
      local st = sd[1]
      if st >= sentAt + 0.6 - 0.005 and st <= sentAt + 0.6 + 0.035 then
        -- sent on the first frame allowed: it lands a frame after the shield
        -- ends (the ball came in that frame), or in the very frame it ends
        -- and the game refused it (the next try is a round trip away)
        if t - last[2] <= 0.035 or sd[2] == nil then return true end
      end
    end
    return false
  end
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local foe=Instance.new("Player"); foe.Name="Foe"
  local fchar=Instance.new("Model"); fchar.Name="Foe"
  local fpos=v3(0,5,gap)
  local fhrp=Instance.new("Part"); fhrp.Name="HumanoidRootPart"; fhrp.Position=fpos; fhrp.AssemblyLinearVelocity=v3(0,0,0); fhrp.Parent=fchar
  foe.Character=fchar; foe.CharacterAdded=R.newSignal(); foe.CharacterRemoving=R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  local b=Instance.new("Part"); b.Name="Fast"; b.Parent=w.Balls
  -- Target changes reach the client half a ping after the server makes them.
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local function deliver()
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("Fast",n)
    end
  end
  local me=w.hrp.Position
  -- The serve: the ball hovers next to the opponent (aimed at them) for 0.5s -
  -- a slow ball near a player sets and freezes a small parry range.
  local pos=v3(0,5,gap-4)
  b:SetAttribute("Target","Foe"); w.ballCtl.Server.ChangeBallColor("Foe","Foe")
  local hist={}; local t=0; local dt=1/60
  for _=1,30 do
    t=t+dt; hist[#hist+1]={t=t,p=pos,v=v3(0,0,-3)}
    b.Position=pos; b.AssemblyLinearVelocity=v3(0,0,-3)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  local function headingToward(from, to, off)
    local d=to-from; local m=d.Magnitude; local ux,uz=d.X/m,d.Z/m
    local a=math.rad(off); local c,s=math.cos(a),math.sin(a)
    return v3(ux*c - uz*s, 0, ux*s + uz*c)
  end
  -- Then the opponent hits it at me. The first launch takes ~0.5s to arrive
  -- (a real rally starts slow enough to react to); each hit speeds it up 6%.
  local tgtPos=me; local tgtName="Hero"; target("Hero")
  local spd=spd0
  local dirv=headingToward(pos,tgtPos,offDeg)
  local parries, lastP, periods, fastN = 0, nil, 0, 0
  local delay=w.oneway+interp
  for _=1,60*DUR do
    t=t+dt
    local want=(tgtPos-pos); local wm=want.Magnitude
    if wm>1e-3 then
      local wx,wz=want.X/wm,want.Z/wm
      local cross=dirv.X*wz - dirv.Z*wx
      local dot=math.max(-1,math.min(1,dirv.X*wx+dirv.Z*wz))
      -- homing with a fixed turning RADIUS (turn rate = speed / radius), so the
      -- ball always reaches its target - a fixed rad/s let a 400 studs/s ball
      -- orbit forever - and the loop it flies keeps its shape at any speed.
      local tr=math.min(math.acos(dot), spd/radius*dt)
      if cross<0 then tr=-tr end
      local c,s=math.cos(tr),math.sin(tr)
      dirv=v3(dirv.X*c - dirv.Z*s, 0, dirv.X*s + dirv.Z*c)
    end
    pos=pos+v3(dirv.X*spd*dt,0,dirv.Z*spd*dt)
    if tgtName=="Hero" and (pos-me).Magnitude<=8 then
      if not w.shieldAt(R.VTIME()) then return false, parries, spd, fastN>0 and periods/fastN or 0, atGap(R.VTIME()) end
      w.server.parried()
      parries=parries+1
      if lastP and spd>=360 then periods=periods+(t-lastP); fastN=fastN+1 end
      lastP=t
      spd=math.min(spd*1.06, 420); tgtName="Foe"; tgtPos=fpos; target("Foe"); dirv=headingToward(pos,fpos,offDeg)
    elseif tgtName=="Foe" and (pos-fpos).Magnitude<=8 then
      spd=math.min(spd*1.06, 420); tgtName="Hero"; tgtPos=me; target("Hero"); dirv=headingToward(pos,me,-offDeg)
    end
    hist[#hist+1]={t=t,p=pos,v=v3(dirv.X*spd,0,dirv.Z*spd)}
    -- what the client sees: the ball as it was `delay` seconds ago
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-delay then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    deliver()
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  return true, parries, spd, fastN>0 and periods/fastN or 0
end

print("=== Replay: real miss report #4 (fast homing rally up to 420 studs/s) ===")
local good,total,gapN,bad=0,0,0,0
for _,ping in ipairs({80,119,160}) do
  -- {gap, launch angle off the line, turning radius, view lag, start speed}:
  -- round trips like the report's (~0.47-0.68s at 380-420 studs/s), plus a
  -- tight ~0.23s one. The wide loops start already fast (240-250 studs/s), so
  -- the very first pass is a fast looping serve too.
  for _,c in ipairs({{55,120,30,0.13,240},{60,150,25,0.10,240},{45,150,25,0.13,235},{55,150,20,0.10,200},
                     {55,150,28,0.13,250},{60,140,30,0.12,250},{50,160,28,0.13,240},{55,165,26,0.12,240},
                     {55,60,20,0.13,140}}) do
    local ok,p,spd,per,gap=run(ping,c[1],c[2],c[3],c[4],c[5]); total=total+1
    local verdict = ok and ("SURVIVED "..DUR.."s") or (gap and "DIED at the shield gap" or "DIED")
    if ok and spd < 360 then ok=false; verdict="INVALID (never got fast)" end
    if ok then good=good+1 elseif gap then gapN=gapN+1 else bad=bad+1 end
    print(string.format("  ping %3d gap %2d off %3d deg radius %2d view lag +%.2fs -> %s after %d parries (top %3.0f studs/s, fast round trip %.2fs)",
      ping, c[1], c[2], c[3], c[4], verdict, p, spd, per))
  end
end
print(string.format("\n=== %d/%d survived, %d at the shield gap ===", good, total, gapN))
print(bad == 0 and "OK: every death was at the shield gap (the game allows no shield there)"
  or string.format("FAIL: %d death(s) the script could have blocked", bad))
