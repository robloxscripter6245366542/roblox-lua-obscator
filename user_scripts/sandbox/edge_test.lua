-- Edge-case suite: the cases the other suites never exercised.
--   * MULTIPLE simultaneous balls (2/3/5 converging, staggered and same-instant,
--     from opposite sides) - does every incoming ball get parried when a real
--     fight throws more than one at you at once?
--   * GLITCH / crash physics: NaN & infinite position/velocity, a ball that
--     spawns already inside you, a ball sitting on you at zero speed, garbage
--     Target attributes, and a zero / negative ping - the script must never
--     error, and must still parry anything that is physically blockable.
--   * You DYING mid-flight: the HumanoidRootPart disappears (death/respawn) for
--     a stretch, then comes back - the script must survive and resume parrying.
-- Multi-ball is scored (each ball parried?); crash cases assert no error escapes.
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local pass, fail, notes = 0, 0, {}
local function ok(name) pass=pass+1; print(string.format("  ok   %s", name)) end
local function bad(name, why) fail=fail+1; notes[#notes+1]=name..": "..why
  print(string.format("  FAIL %s  (%s)", name, why)) end

-- spawn a ball at pos heading toward the hero with the given speed; returns a
-- table {ball, upd(dt)->truePos} that the driver steps and stales for the client.
local function mkBall(w, spawnPos, speed, target)
  local v3,Instance,Enum = w.v3,w.Instance,w.Enum
  local ball=Instance.new("Part"); ball.Name="Ball"
  local lv=Instance.new("LinearVelocity"); lv.Enabled=true; lv.RelativeTo=Enum.ActuatorRelativeTo.World
  lv.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector; lv.Parent=ball
  ball:SetAttribute("Target", target or "Hero")
  ball.Parent=w.Balls
  local truePos=spawnPos
  local hist={}
  return {
    ball=ball, truePos=function() return truePos end, hit=false, parried=nil,
    upd=function(dt, t)
      local to=w.hrp.Position - truePos; local d=to.Magnitude
      local vel = d>1e-3 and v3(to.X/d*speed,to.Y/d*speed,to.Z/d*speed) or v3(0,0,0)
      truePos = truePos + v3(vel.X*dt,vel.Y*dt,vel.Z*dt)
      hist[#hist+1]={t=t,pos=truePos,vel=vel}
      -- stale view (client sees it ~one-way behind)
      local tgt=t-w.oneway; local sp,sv=truePos,vel
      for i=#hist,1,-1 do if hist[i].t<=tgt then sp=hist[i].pos; sv=hist[i].vel; break end end
      ball.Position=sp; ball.AssemblyLinearVelocity=sv; lv.VectorVelocity=sv
      return truePos, (w.hrp.Position - truePos).Magnitude
    end,
  }
end

-- ---- MULTI-BALL: many balls at once, each scored ----
-- azimuths around the player; spawnDist and per-ball launch delay control stagger.
local function multiBall(name, ping, specs)
  local w = build(SRC, ping); if not w then return bad(name,"LOADERR") end
  local v3 = w.v3
  local balls, launched = {}, {}
  for i=1,#specs do launched[i]=false end
  local dt=1/60; local t=0
  for f=1,60*10 do
    t=t+dt
    for i,s in ipairs(specs) do
      if not launched[i] and t>=s.at then
        local az=math.rad(s.az)
        local p=v3(math.sin(az)*s.dist, 5, math.cos(az)*s.dist)
        balls[i]=mkBall(w, p, s.speed, "Hero"); launched[i]=true
      end
    end
    for i,b in ipairs(balls) do
      if b and not b.hit then
        local _,d=b.upd(dt,t)
        if d<=8 then b.hit=true; b.parried=w.shieldAt(w.R.VTIME())
          if b.parried then w.server.parryReset() end
          b.ball.Parent=nil
        end
      end
    end
    w.RunService.Heartbeat:Fire(); w.R.advance(dt)
    local allHit=true; for i=1,#specs do if not (balls[i] and balls[i].hit) then allHit=false break end end
    if allHit and #specs>0 then break end
  end
  local hitN,parN=0,0
  for _,b in ipairs(balls) do if b and b.hit then hitN=hitN+1; if b.parried then parN=parN+1 end end end
  if parN==hitN and hitN==#specs then ok(string.format("%s  [%d/%d parried]",name,parN,#specs))
  else bad(name, string.format("%d/%d parried (%d hit)",parN,#specs,hitN)) end
end

-- ---- CRASH / GLITCH: run frames feeding garbage; assert no error escapes ----
local function crashCase(name, ping, drive)
  local w = build(SRC, ping); if not w then return bad(name,"LOADERR") end
  local okrun,err = pcall(function()
    local dt=1/60; local t=0
    for f=1,60*6 do t=t+dt; drive(w,t,f); w.RunService.Heartbeat:Fire(); w.R.advance(dt) end
  end)
  if okrun then ok(name) else bad(name, "ERROR "..tostring(err)) end
end

print("=== MULTI-BALL: several incoming balls at once, each must be parried ===")
for _,pg in ipairs({30,120,220}) do
  -- 2 balls, opposite sides, near-simultaneous (one shield can cover both)
  multiBall(string.format("2 balls opposite  @ping%d",pg), pg,
    { {at=0.0,az=0,dist=120,speed=150}, {at=0.0,az=180,dist=120,speed=150} })
  -- 3 balls, staggered ~0.6s apart (cooldown resets on each parry)
  multiBall(string.format("3 balls staggered  @ping%d",pg), pg,
    { {at=0.0,az=0,dist=140,speed=160}, {at=0.7,az=120,dist=150,speed=160}, {at=1.4,az=240,dist=150,speed=160} })
  -- 5 balls from a fan, staggered ~0.5s
  multiBall(string.format("5 balls fan        @ping%d",pg), pg,
    { {at=0.0,az=20,dist=150,speed=170}, {at=0.6,az=70,dist=150,speed=170}, {at=1.2,az=120,dist=150,speed=170},
      {at=1.8,az=170,dist=150,speed=170}, {at=2.4,az=220,dist=150,speed=170} })
  -- 2 balls same instant, different speeds (converge on same frame-ish)
  multiBall(string.format("2 balls diff speed @ping%d",pg), pg,
    { {at=0.0,az=45,dist=90,speed=120}, {at=0.0,az=225,dist=180,speed=240} })
end

print("=== GLITCH / CRASH: script must never error on garbage physics ===")
local NAN=0/0; local INF=1/0
crashCase("NaN position ball", 90, function(w,t)
  local v3=w.v3
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero"); b.Parent=w.Balls; w._nanb=b end
  if w._nanb then w._nanb.Position=v3(NAN,NAN,NAN); w._nanb.AssemblyLinearVelocity=v3(NAN,0,NAN) end
end)
crashCase("infinite velocity ball", 90, function(w,t)
  local v3=w.v3
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero"); b.Parent=w.Balls; w._ib=b; w._ip=v3(0,5,100) end
  if w._ib then w._ip=w._ip; w._ib.Position=v3(0,5,80); w._ib.AssemblyLinearVelocity=v3(0,0,-INF) end
end)
crashCase("ball spawns inside you (d=3)", 90, function(w,t)
  local v3=w.v3
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero")
    b.Position=v3(0,5,3); b.AssemblyLinearVelocity=v3(0,0,-200); b.Parent=w.Balls end
end)
crashCase("ball sitting on you, zero speed", 90, function(w,t)
  local v3=w.v3
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero")
    b.Position=v3(0,5,0); b.AssemblyLinearVelocity=v3(0,0,0); b.Parent=w.Balls end
end)
crashCase("garbage Target attribute", 90, function(w,t)
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b.Position=w.v3(0,5,60)
    b.AssemblyLinearVelocity=w.v3(0,0,-150); b.Parent=w.Balls; w._gb=b end
  if w._gb then w._gb:SetAttribute("Target", (math.floor(t*30)%3==0) and 12345 or nil) end
end)
crashCase("zero ping", 0, function(w,t)
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero")
    b.Position=w.v3(0,5,90); b.AssemblyLinearVelocity=w.v3(0,0,-150); b.Parent=w.Balls end
end)
crashCase("you die mid-flight (HRP removed then restored)", 120, function(w,t)
  local v3=w.v3
  if t<0.1 then local b=w.Instance.new("Part"); b.Name="Ball"; b:SetAttribute("Target","Hero")
    b.Position=v3(0,5,150); b.AssemblyLinearVelocity=v3(0,0,-120); b.Parent=w.Balls; w._db=b end
  -- die: detach HRP from the character for a window, then respawn a fresh HRP
  if math.abs(t-1.0)<0.02 then w.hrp.Parent=nil end
  if math.abs(t-2.0)<0.02 then
    local nh=w.Instance.new("Part"); nh.Name="HumanoidRootPart"; nh.Position=v3(0,5,0)
    nh.AssemblyLinearVelocity=v3(0,0,0); nh.Parent=w.char_ref; w.hrp=nh
  end
  if w._db and w.hrp and w.hrp.Parent then
    local p=w._db.Position; w._db.Position=v3(p.X,p.Y,p.Z-120*(1/60))
  end
end)

print(string.format("\n=== %d passed, %d failed ===", pass, fail))
if fail>0 then for _,n in ipairs(notes) do print("  * "..n) end os.exit(1) end
print("ALL EDGE CASES OK")
