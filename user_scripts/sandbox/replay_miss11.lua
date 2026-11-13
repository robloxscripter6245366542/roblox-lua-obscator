-- Replay of REAL miss report #11 (123 ms): a SLOW clash with an opponent
-- ~24 studs away. In the report the ball circled them for ~0.4s (it stayed
-- 23-29 studs from me while aimed at them) before they hit it back, and I
-- dashed away from the return, so it took ~0.9s from my parry. A block sent
-- in the clash stream landed right after my parry, started a fresh 1s
-- cooldown with a 0.6s shield, and the return came after that shield.
-- Here the opponent HOLDS the ball (it circles them at radius 7) for
-- `hold` seconds before each return, I may dash away for 0.35s after each of
-- their hits, and the server may call it a clash (StartClash) at the serve,
-- after my 2nd parry, or never - under the three server rules. The ball on
-- screen trails the real one by half a ping + Roblox's interpolation, its
-- Target attribute by half a ping. The serve starts slow (~30 studs/s, like the
-- real logs); the ball speeds up ~16 studs/s every second and +1.5 a hit.
-- Run: lua replay_miss11.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local DUR = 10
local function run(ping, gap, offDeg, radius, interp, spd0, rule, hold, clashAt, dash)
  local w = assert(build(SRC, ping, {shieldLock=rule=="lock", consume=rule=="consume", yieldTransport=true, liveDispatch=true}))
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
  -- The server may call this exchange a clash (match-wide StartClash): at
  -- the serve (clashAt 0), after my clashAt-th parry, or never (false).
  if clashAt == 0 then w.serverCall("ClashController", "StartClash") end
  -- Then the opponent hits it at me.
  local tgtPos=me; local tgtName="Hero"; target("Hero")
  local spd=spd0
  local dirv=headingToward(pos,tgtPos,offDeg)
  local parries, lastP, periods, fastN = 0, nil, 0, 0
  local delay=w.oneway+interp
  local holdLeft, orbitA = nil, 0
  local held = 0   -- their held returns so far
  local home, dashLeft = me, 0
  local function moveHero()
    local v = v3(0,0,0)
    if dashLeft > 0 then
      dashLeft = dashLeft - dt; v = v3(0,0,-dash)
    elseif (me-home).Magnitude > 0.5 then
      v = (home-me).Unit*20
    end
    me = me + v*dt; w.hrp.Position = me; w.hrp.AssemblyLinearVelocity = v
    if tgtName == "Hero" then tgtPos = me end
  end
  for _=1,60*DUR do
    t=t+dt
    if dash and dash > 0 then moveHero() end
    spd=spd+16*dt
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
    if holdLeft then
      -- the foe holds it: it circles them, still aimed at them
      orbitA=orbitA+spd/7*dt
      local np=fpos+v3(math.cos(orbitA)*7,0,math.sin(orbitA)*7)
      dirv=(np-pos).Magnitude>1e-3 and (np-pos).Unit or dirv
      pos=np
      holdLeft=holdLeft-dt
      if holdLeft<=0 then
        holdLeft=nil; held=held+1
        spd=spd+1.5; tgtName="Hero"; tgtPos=me; target("Hero"); dirv=headingToward(pos,me,-offDeg); dashLeft=0.35
      end
    else
      pos=pos+v3(dirv.X*spd*dt,0,dirv.Z*spd*dt)
    end
    if tgtName=="Hero" and (pos-me).Magnitude<=8 then
      if not w.shieldAt(R.VTIME()) then return false, parries, spd, fastN>0 and periods/fastN or 0, atGap(R.VTIME()), hold > 0 and held == 1 end
      w.server.parried()
      parries=parries+1
      if clashAt and clashAt > 0 and parries == clashAt then w.serverCall("ClashController", "StartClash") end
      if lastP and spd>=360 then periods=periods+(t-lastP); fastN=fastN+1 end
      lastP=t
      spd=spd+1.5; tgtName="Foe"; tgtPos=fpos; target("Foe"); dirv=headingToward(pos,fpos,offDeg)
    elseif tgtName=="Foe" and not holdLeft and (pos-fpos).Magnitude<=8 then
      if hold > 0 then
        holdLeft=hold; orbitA=math.atan2(pos.Z-fpos.Z, pos.X-fpos.X)
      else
        spd=spd+1.5; tgtName="Hero"; tgtPos=me; target("Hero"); dirv=headingToward(pos,me,-offDeg); dashLeft=0.35
      end
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

print("=== Replay: real miss report #11 (a slow clash, the opponent holds the ball) ===")
-- Their FIRST hold can't be known in advance: until they have held the ball
-- once, a block timed for an instant return is the right call (a return from
-- 24 studs lands before you could react to it), and its shield runs out
-- during the hold. From then on the script knows how long they hold it.
local good,total,gapN,firstN,bad=0,0,0,0,0
-- {gap, angle off the line, turning radius, view lag, start speed, hold,
--  StartClash (0 = at the serve, n = after my n-th parry, false = never),
--  my dash away (studs/s) for 0.35s after each of their hits}
local CASES = {
  {24, 20, 25, 0.12, 30, 0.4,  2,     0},   -- they hold it, the server calls a clash mid-rally
  {24, 20, 25, 0.12, 30, 0.4,  2,     45},  -- ...and I dash away from each return (the report)
  {24, 20, 25, 0.12, 30, 0,    2,     45},  -- straight returns, I dash away
  {23, 25, 25, 0.10, 30, 0.45, 0,     40},  -- a clash from the serve
  {25, 15, 25, 0.12, 30, 0.35, false, 0},   -- no StartClash at all
}
local function clashName(c) return c == 0 and "clash at serve" or (c and "clash after "..c) or "no StartClash" end
for _,rule in ipairs({"default","lock","consume"}) do
  print("-- server rule: "..rule)
  for _,ping in ipairs({100,123,180}) do
    for _,c in ipairs(CASES) do
      local ok,p,spd,per,gap,first=run(ping,c[1],c[2],c[3],c[4],c[5],rule,c[6],c[7],c[8]); total=total+1
      local verdict = ok and ("SURVIVED "..DUR.."s") or (gap and "DIED at the shield gap")
        or (first and "DIED on their first hold") or "DIED"
      if ok and p < 3 then ok=false; gap=false; first=false; verdict="INVALID (ball barely came back)" end
      if ok then good=good+1 elseif gap then gapN=gapN+1 elseif first then firstN=firstN+1 else bad=bad+1 end
      print(string.format("  ping %3d gap %2d hold %.2f dash %2d %-14s -> %s after %d parries (top %3.0f studs/s)",
        ping, c[1], c[6], c[8], clashName(c[7]), verdict, p, spd))
    end
  end
end
print(string.format("\n=== %d/%d survived, %d at the shield gap, %d on their first hold ===", good, total, gapN, firstN))
print(bad == 0 and "OK: every death was at the shield gap (the game allows no shield there) or on their first hold"
  or string.format("FAIL: %d death(s) the script could have blocked", bad))
