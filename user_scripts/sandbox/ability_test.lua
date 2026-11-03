-- Ability ball tricks, from the game's own AbilityInfo descriptions (2026-10-31
-- dump). Each case aims the ball at me, then an ability changes what it does:
--  * Stasis              "Stop the ball in mid air for 4 seconds or until
--                         parried!" - it freezes mid-flight, then carries on.
--  * Time Shift          "Manipulates the ball in time, causing it to
--                         repeatedly shift" (double speed during a shift) - it
--                         teleports ~100 studs from me, at a new angle and 2x
--                         speed (much closer and nobody could react in time).
--  * Instant Transmission "teleports you to the player you hit the ball to" -
--                         the hitter appears next to me right after the hit,
--                         so my parry sends the ball into a point-blank return.
--  * Almighty Attraction "Force attract the ball" (2x faster) - the caster next
--                         to me pulls the ball in, then it is aimed at me.
-- What I see is half a ping + 0.12s behind the real ball; the Target attribute
-- half a ping behind. Expected: 22/24 - the two Time Shift misses at 200 ms
-- can't be blocked (it lands ~0.31s after the shift; I see it 0.22s after it
-- and a block takes 0.10s more to land). Run: lua ability_test.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function world(ping, consume)
  local w = assert(build(SRC, ping, {yieldTransport=true, consume=consume}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local function addPlayer(name, pos)
    local pl=Instance.new("Player"); pl.Name=name
    local ch=Instance.new("Model"); ch.Name=name
    local h=Instance.new("Part"); h.Name="HumanoidRootPart"; h.Position=pos; h.AssemblyLinearVelocity=v3(0,0,0); h.Parent=ch
    pl.Character=ch; pl.CharacterAdded=R.newSignal(); pl.CharacterRemoving=R.newSignal()
    w.players[#w.players+1]=pl; w.Players.PlayerAdded:Fire(pl)
    return h
  end
  local b=Instance.new("Part"); b.Name="AbBall"; b.Parent=w.Balls
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local hist={}; local t=0; local dt=1/60
  local function show(pos, vel)
    hist[#hist+1]={t=t,p=pos,v=vel}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-(w.oneway+0.12) then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("AbBall",n)
    end
    w.RunService.Heartbeat:Fire(); R.advance(dt); t=t+dt
  end
  return {w=w, v3=v3, R=R, addPlayer=addPlayer, target=target, show=show, me=w.hrp.Position, dt=dt}
end

local function home(pos, dirv, goal, speed, radius, dt, v3)
  local want=(goal-pos); local wm=want.Magnitude
  if wm>1e-3 then
    local wx,wz=want.X/wm,want.Z/wm
    local cross=dirv.X*wz - dirv.Z*wx
    local dot=math.max(-1,math.min(1,dirv.X*wx+dirv.Z*wz))
    local tr=math.min(math.acos(dot), speed/radius*dt)
    if cross<0 then tr=-tr end
    local c,s=math.cos(tr),math.sin(tr)
    dirv=v3(dirv.X*c - dirv.Z*s, 0, dirv.X*s + dirv.Z*c)
  end
  return dirv, pos+v3(dirv.X*speed*dt,0,dirv.Z*speed*dt)
end

-- Fly a ball aimed at me from `pos`; `step(t, pos, dirv, speed)` may change it
-- (return pos, dirv, speed, frozen). Returns true if a shield was up when it hit.
local function fly(e, pos, dirv, speed, step, maxT)
  local v3=e.v3
  for i=1,math.floor(maxT/e.dt) do
    local frozen
    pos, dirv, speed, frozen = step(i*e.dt, pos, dirv, speed)
    if not frozen then
      dirv, pos = home(pos, dirv, e.me, speed, 40, e.dt, v3)
    end
    if (pos-e.me).Magnitude<=8 then return e.w.shieldAt(e.R.VTIME()) end
    e.show(pos, frozen and v3(0,0,0) or v3(dirv.X*speed,0,dirv.Z*speed))
  end
  return nil   -- never reached me
end

local CASES = {}

CASES["Stasis: frozen 4s at 60 studs, then on at 300"] = function(ping, consume)
  local e=world(ping, consume); local v3=e.v3
  e.addPlayer("Caster", v3(0,5,120))
  e.target("Hero")
  local pos=v3(0,5,110); local dir=v3(0,0,-1); local t0
  return fly(e, pos, dir, 300, function(t, p, d, s)
    if p.Z <= 60 and not t0 then t0 = t end
    if t0 and t < t0 + 4 then return p, d, s, true end   -- frozen mid-air for 4s
    return p, d, s, false
  end, 6)
end

CASES["Time Shift: reappears 100 studs out, 2x speed"] = function(ping, consume)
  local e=world(ping, consume); local v3=e.v3
  e.addPlayer("Caster", v3(60,5,180))
  e.target("Hero")
  local shifted=false
  return fly(e, v3(40,5,170), v3(-0.3,0,-1).Unit, 150, function(t, p, d, s)
    if not shifted and t >= 0.4 then
      shifted=true
      -- reappears ~100 studs from me, off to the side, moving 2x faster and
      -- homing in (~0.33s to impact: closer than that nobody can react - the
      -- ball I see is ~0.17s old)
      return v3(-90,5,45), v3(1,0,-0.2).Unit, s*2, false
    end
    return p, d, s, false
  end, 4)
end

CASES["Instant Transmission: hitter appears beside me"] = function(ping, consume)
  local e=world(ping, consume); local v3=e.v3; local w=e.w
  local fh=e.addPlayer("Foe", v3(0,5,70))
  -- the foe hits it at me from 70 studs, then teleports next to me
  e.target("Hero")
  local pos=v3(0,5,62); local dir=v3(0,0,-1); local speed=220; local parries=0
  local goal=e.me; local tgt="Hero"
  for i=1,math.floor(5/e.dt) do
    local tt=i*e.dt
    if tt>=0.15 and fh.Position.Z>20 then fh.Position=v3(6,5,8) end   -- teleported
    dir, pos = home(pos, dir, goal, speed, 30, e.dt, v3)
    if tgt=="Hero" and (pos-e.me).Magnitude<=8 then
      if not w.shieldAt(e.R.VTIME()) then return false end
      w.server.parried(); parries=parries+1
      tgt="Foe"; e.target("Foe"); goal=fh.Position; dir=(goal-pos).Unit
      speed=speed*1.1
    elseif tgt=="Foe" and (pos-fh.Position).Magnitude<=8 then
      tgt="Hero"; e.target("Hero"); goal=e.me; dir=(goal-pos).Unit
      speed=speed*1.1
    end
    if parries>=6 then return true end
    e.show(pos, v3(dir.X*speed,0,dir.Z*speed))
  end
  return parries>=3
end

CASES["Almighty Attraction: pulled in beside me, then at me"] = function(ping, consume)
  local e=world(ping, consume); local v3=e.v3
  local ch=e.addPlayer("Caster", v3(10,5,4))
  e.target("Caster")
  local pos=v3(0,5,120); local dir=v3(0,0,-1); local speed=180; local aimed=false
  for i=1,math.floor(4/e.dt) do
    local tt=i*e.dt
    if not aimed then
      -- attracted 2x faster toward the caster next to me
      dir=(ch.Position-pos).Unit; pos=pos+v3(dir.X*speed*2*e.dt,0,dir.Z*speed*2*e.dt)
      if (ch.Position-pos).Magnitude<=10 then
        aimed=true; e.target("Hero"); speed=speed*2; dir=(e.me-pos).Unit
      end
      e.show(pos, v3(dir.X*speed*2,0,dir.Z*speed*2))
    else
      dir, pos = home(pos, dir, e.me, speed, 30, e.dt, v3)
      if (pos-e.me).Magnitude<=8 then return e.w.shieldAt(e.R.VTIME()) end
      e.show(pos, v3(dir.X*speed,0,dir.Z*speed))
    end
  end
  return nil
end

print("=== Ability ball tricks (from the game's AbilityInfo) ===")
local good,total=0,0
local names={} for k in pairs(CASES) do names[#names+1]=k end table.sort(names)
for _,name in ipairs(names) do
  for _,consume in ipairs({false,true}) do
    for _,ping in ipairs({90,150,200}) do
      local ok=CASES[name](ping, consume); total=total+1
      if ok then good=good+1 end
      print(string.format("  %-52s %s ping %3d -> %s", name, consume and "[used up]" or "[lasts]  ", ping,
        ok == nil and "NEVER ARRIVED (bad case)" or (ok and "PARRIED" or "MISSED")))
    end
  end
end
print(string.format("\n=== %d/%d parried ===", good, total))
