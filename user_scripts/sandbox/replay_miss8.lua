-- Replay of REAL miss report #8 (159 ms): a FAST rally - the ball 255-285
-- studs/s, a return every ~0.45s, the opponent ~55-60 studs away.
-- What the report showed: a block went up and parried the ball; the script
-- still counted that shield as up for the rest of its 0.6s, so when the ball
-- came back 0.45s later it held fire ("my shield already covers it", H=1) and
-- the shield lock kept the next block back until too late. The ball hit me
-- inside the window that shield was said to cover: the parry had USED IT UP.
-- Every case runs under three server rules: the default (a parry resets the
-- cooldown, the shield lasts), shieldLock (no block while my shield is up) and
-- consume (a shield that parries is used up). Run: lua replay_miss8.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local DUR = 8
local INSTANT = 10   -- in the report the real ball was ~4-6 studs out as the block landed
local function run(ping, gap, offDeg, radius, interp, spd0, model)
  local w = assert(build(SRC, ping, {shieldLock=(model=="lock"), consume=(model=="consume"), yieldTransport=true}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  local realPos, aimedAtMe, instantHit = nil, false, false
  -- An instant parry hits the ball back right there (the test loop does it on
  -- its next step) and leaves no shield.
  w.server.instantNow = function()
    if aimedAtMe and realPos ~= nil and (realPos - w.hrp.Position).Magnitude <= INSTANT then
      instantHit = true; return true
    end
    return false
  end
  local sends = {}
  do local ob=w.server.block; w.server.block=function(...)
    local sd={R.VTIME(), "pending"}; sends[#sends+1]=sd
    local r=ob(...); sd[2]=r; return r end end
  -- A death "at the shield gap" (see replay_miss4.lua): the next block was
  -- sent on the first frame the shield lock allows, and the ball came within
  -- 35 ms after my shield ended, or that block landed in the very frame the
  -- shield ended and was refused.
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
  local b=Instance.new("Part"); b.Name="Slow"; b.Parent=w.Balls
  -- Target changes reach the client half a ping after the server makes them.
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local function deliver()
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("Slow",n)
    end
  end
  local me=w.hrp.Position
  local pos=v3(0,5,gap-4)
  b:SetAttribute("Target","Foe"); w.ballCtl.Server.ChangeBallColor("Slow","Foe")
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
  -- The opponent hits it at me; the ball speeds up ~18 studs/s every second.
  local tgtPos=me; local tgtName="Hero"; target("Hero")
  local spd=spd0
  local dirv=headingToward(pos,tgtPos,offDeg)
  local parries=0
  local delay=w.oneway+interp
  for _=1,60*DUR do
    t=t+dt
    spd=math.min(spd+22*dt, 290)
    local want=(tgtPos-pos); local wm=want.Magnitude
    if wm>1e-3 then
      local wx,wz=want.X/wm,want.Z/wm
      local cross=dirv.X*wz - dirv.Z*wx
      local dot=math.max(-1,math.min(1,dirv.X*wx+dirv.Z*wz))
      local tr=math.min(math.acos(dot), spd/radius*dt)
      if cross<0 then tr=-tr end
      local c,s=math.cos(tr),math.sin(tr)
      dirv=v3(dirv.X*c - dirv.Z*s, 0, dirv.X*s + dirv.Z*c)
    end
    pos=pos+v3(dirv.X*spd*dt,0,dirv.Z*spd*dt)
    realPos, aimedAtMe = pos, tgtName=="Hero"
    if tgtName=="Hero" and instantHit then
      instantHit = false
      w.server.parried()
      parries=parries+1
      tgtName="Foe"; tgtPos=fpos; target("Foe"); dirv=headingToward(pos,fpos,offDeg)
    elseif tgtName=="Hero" and (pos-me).Magnitude<=8 then
      if not w.shieldAt(R.VTIME()) then return false, parries, atGap(R.VTIME()) end
      w.server.parried()
      parries=parries+1
      tgtName="Foe"; tgtPos=fpos; target("Foe"); dirv=headingToward(pos,fpos,offDeg)
    elseif tgtName=="Foe" and (pos-fpos).Magnitude<=8 then
      tgtName="Hero"; tgtPos=me; target("Hero"); dirv=headingToward(pos,me,-offDeg)
    end
    hist[#hist+1]={t=t,p=pos,v=v3(dirv.X*spd,0,dirv.Z*spd)}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-delay then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    deliver()
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  return true, parries
end

print("=== Replay: real miss report #8 (fast rally, the parry uses the shield up) ===")
local good,total,gapN,bad=0,0,0,0
for _,model in ipairs({"reset","lock","consume"}) do
  print(({reset="-- server: a parry resets the cooldown, the shield lasts (default)",
          lock="-- server: no block while your shield is up (shieldLock)",
          consume="-- server: a shield that parries is used up (consume)"})[model])
  for _,ping in ipairs({90,159,200}) do
    -- {gap, launch angle off the line, turning radius, view lag, start speed}:
    -- round trips ~0.43-0.58s once the ball reaches 270-290 studs/s.
    for _,c in ipairs({{55,90,20,0.12,150},{60,90,20,0.10,150},{55,120,20,0.13,160}}) do
      local ok,p,gap=run(ping,c[1],c[2],c[3],c[4],c[5],model); total=total+1
      local verdict = ok and ("SURVIVED "..DUR.."s") or (gap and "DIED at the shield gap" or "DIED")
      if ok and p < 3 then ok=false; gap=false; verdict="INVALID (ball barely came back)" end
      if ok then good=good+1 elseif gap then gapN=gapN+1 else bad=bad+1 end
      print(string.format("  ping %3d gap %2d off %3d deg radius %2d view lag +%.2fs -> %s after %d parries",
        ping, c[1], c[2], c[3], c[4], verdict, p))
    end
  end
end
print(string.format("\n=== %d/%d survived, %d at the shield gap ===", good, total, gapN))
print(bad == 0 and "OK: every death was at the shield gap (the game allows no shield there)"
  or string.format("FAIL: %d death(s) the script could have blocked", bad))
