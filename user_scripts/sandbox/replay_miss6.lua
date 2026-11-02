-- Replay of REAL miss report #6 (158 ms): an ABILITY launch. Another player
-- uses an ability: the ball (aimed at someone else, ~125-145 studs from you)
-- is HELD still - it reads speed 0 - then its target switches to you
-- and it is launched at ~475 studs/s, starting ~75 deg off the line and
-- curving in hard (closing speed 120 -> 470 in 0.1s).
-- The ball already REPORTED its launch velocity (474 studs/s, closing ~440)
-- while the ability kept it in place for ~0.2s more (its distance barely
-- changed). The curved-arc prediction, fed a 0 -> 474 velocity jump, called it
-- a miss (arr=inf) the whole way, so the block window only opened at -0.10s -
-- one block, 0.06s too late.
-- Run: lua replay_miss6.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function run(ping, dist, offDeg, radius, speed, interp, holdT, armT, walk)
  local w = assert(build(SRC, ping, {yieldTransport=true}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  -- the ability user, ~dist studs away, and a third player the ball was aimed at
  local function addPlayer(name, pos)
    local pl=Instance.new("Player"); pl.Name=name
    local ch=Instance.new("Model"); ch.Name=name
    local h=Instance.new("Part"); h.Name="HumanoidRootPart"; h.Position=pos; h.AssemblyLinearVelocity=v3(0,0,0); h.Parent=ch
    pl.Character=ch; pl.CharacterAdded=R.newSignal(); pl.CharacterRemoving=R.newSignal()
    w.players[#w.players+1]=pl; w.Players.PlayerAdded:Fire(pl)
    return pos
  end
  local userPos = addPlayer("Caster", v3(0,5,dist+6))
  local otherPos = addPlayer("Other", v3(-120,5,dist+120))   -- far side of the arena
  local b=Instance.new("Part"); b.Name="Ab"; b.Parent=w.Balls
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local function deliver()
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("Ab",n)
    end
  end
  local me=w.hrp.Position
  local hist={}; local t=0; local dt=1/60; local frame=0
  -- The ball's velocity replicates at 30 Hz (it changes every OTHER frame in
  -- the report), and you may be walking/dashing at the ball (`walk` studs/s
  -- toward it - in the report its distance shrank ~50 studs/s while it was
  -- held still).
  local shownVel=v3(0,0,0)
  local function show(pos, vel)
    frame=frame+1
    if walk > 0 then
      local d=pos-me; local m=d.Magnitude
      if m>20 then me=me+d/m*walk*dt; w.hrp.Position=me; w.hrp.AssemblyLinearVelocity=d/m*walk end
    end
    hist[#hist+1]={t=t,p=pos,v=vel}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-(w.oneway+interp) then sp=hist[i].p; sv=hist[i].v break end end
    if frame%2==0 then shownVel=sv end
    b.Position=sp; b.AssemblyLinearVelocity=shownVel
    deliver()
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  -- 1) a fast rally between two other players, far from me (0.6s)
  b:SetAttribute("Target","Other"); w.ballCtl.Server.ChangeBallColor("Ab","Other")
  local pos=v3(-30,5,dist+20)
  local start=pos
  for _=1,36 do
    t=t+dt; local d=(otherPos-pos); local u=d/d.Magnitude
    local vel=v3(u.X*330,0,u.Z*330); pos=pos+vel*dt
    if (otherPos-pos).Magnitude<8 then pos=start end
    show(pos, vel)
  end
  pos=start   -- the caster's ability grabs it back near them
  -- 2) the ability holds it still (speed 0) with its target cleared. In the
  -- report its distance still shrank ~55 studs/s - that was you moving.
  target(nil)
  for _=1,math.floor(holdT*60) do
    t=t+dt
    show(pos, v3(0,0,0))
  end
  -- 3) aimed at me: the target switches and the ball already reports its
  -- launch velocity, but the ability keeps it in place for armT more (in the
  -- report it read 474 studs/s for 0.2s while barely moving)...
  target("Hero")
  local d=(me-pos); local m=d.Magnitude; local ux,uz=d.X/m,d.Z/m
  local a=math.rad(offDeg); local c,s=math.cos(a),math.sin(a)
  local dirv=v3(ux*c - uz*s, 0, ux*s + uz*c)
  local function steer()   -- homing: turn the heading toward me at speed/radius rad/s
    local want=(me-pos); local wm=want.Magnitude
    local wx,wz=want.X/wm,want.Z/wm
    local cross=dirv.X*wz - dirv.Z*wx
    local dot=math.max(-1,math.min(1,dirv.X*wx+dirv.Z*wz))
    local tr=math.min(math.acos(dot), speed/radius*dt)
    if cross<0 then tr=-tr end
    local cc,ss=math.cos(tr),math.sin(tr)
    dirv=v3(dirv.X*cc - dirv.Z*ss, 0, dirv.X*ss + dirv.Z*cc)
  end
  -- (its reported heading already swings toward me while it is held: in the
  -- report the closing speed went 120 -> 470 with the distance barely moving)
  for _=1,math.floor(armT*60) do
    t=t+dt
    steer()
    show(pos, v3(dirv.X*speed,0,dirv.Z*speed))
  end
  -- ...then it flies, offDeg off the line, homing with a fixed turning radius
  for _=1,120 do
    t=t+dt
    steer()
    pos=pos+v3(dirv.X*speed*dt,0,dirv.Z*speed*dt)
    if (pos-me).Magnitude<=8 then return w.shieldAt(R.VTIME()) end
    show(pos, v3(dirv.X*speed,0,dirv.Z*speed))
  end
  return true   -- it never reached me (not a valid run; counted as survived)
end

print("=== Replay: real miss report #6 (ability: held ball launched at you) ===")
local good,total=0,0
for _,ping in ipairs({90,158,220}) do
  -- {distance, launch angle off the line, turning radius, speed, view lag,
  --  hold time, time it already reports the launch velocity while still held,
  --  your speed toward the ball}
  for _,c in ipairs({{125,75,40,475,0.12,0.33,0.2,50},{140,60,50,475,0.10,0.4,0.15,0},{110,80,35,450,0.13,0.3,0.2,50},
                     {130,30,80,500,0.12,0.35,0.1,30},{125,75,40,475,0.12,0.33,0,0}}) do
    local ok=run(ping,c[1],c[2],c[3],c[4],c[5],c[6],c[7],c[8]); total=total+1
    if ok then good=good+1 end
    print(string.format("  ping %3d from %3d studs, %2d deg off, radius %2d, %3d studs/s, held %.2fs at speed, you %2d studs/s -> %s",
      ping, c[1], c[2], c[3], c[4], c[7], c[8], ok and "PARRIED" or "MISSED"))
  end
end
print(string.format("\n=== %d/%d parried ===", good, total))
