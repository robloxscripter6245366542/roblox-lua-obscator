-- Ball Hit Logger check: a rally between me and an opponent with a KNOWN speed
-- rule, then the logger's report (getgenv().AnimeBallHubHitLog()) must read
-- that rule back. Two rules: each hit multiplies the speed (x1.06) or adds to
-- it (+15 studs/s), and the ball also speeds up 18 studs/s every second in
-- flight. As in the game, the ball on screen is half a ping + 0.12s old and
-- the Target attribute half a ping. Run: lua hitlog_test.lua [script]
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function rally(ping, rule, gap, spd0, hitsWanted, showReport)
  -- hits = every time the ball is sent at the other player, the opponent's
  -- serve included
  local w = assert(build(SRC, ping, {yieldTransport=true}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local foe=Instance.new("Player"); foe.Name="Foe"
  local ch=Instance.new("Model"); ch.Name="Foe"
  local fpos=v3(0,5,gap)
  local fh=Instance.new("Part"); fh.Name="HumanoidRootPart"; fh.Position=fpos; fh.AssemblyLinearVelocity=v3(0,0,0); fh.Parent=ch
  foe.Character=ch; foe.CharacterAdded=R.newSignal(); foe.CharacterRemoving=R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  local b=Instance.new("Part"); b.Name="LogBall"; b.Parent=w.Balls
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local me=w.hrp.Position
  local hist={}; local t=0; local dt=1/60
  local pos=v3(0,5,gap-6)
  b:SetAttribute("Target","Foe"); w.ballCtl.Server.ChangeBallColor("LogBall","Foe")
  for _=1,30 do   -- the serve hovers by the opponent
    t=t+dt; hist[#hist+1]={t=t,p=pos,v=v3(0,0,0)}
    b.Position=pos; b.AssemblyLinearVelocity=v3(0,0,0)
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  local spd=spd0; local tgtName="Hero"; local tgtPos=me; target("Hero")
  local dirv=(me-pos).Unit
  local outs={}   -- the speed each hit sent it off at
  outs[1]=spd
  local hits=1
  for _=1,60*40 do
    t=t+dt
    spd=spd+18*dt
    local want=(tgtPos-pos).Unit
    local dot=math.max(-1,math.min(1,dirv:Dot(want)))
    local cross=dirv.X*want.Z - dirv.Z*want.X
    local tr=math.min(math.acos(dot), spd/30*dt); if cross<0 then tr=-tr end
    local c,s=math.cos(tr),math.sin(tr)
    dirv=v3(dirv.X*c - dirv.Z*s, 0, dirv.X*s + dirv.Z*c)
    pos=pos+dirv*(spd*dt)
    if (pos-tgtPos).Magnitude<=8 then
      -- hit back (whoever it was aimed at), off the line so it curves in
      spd = rule=="mult" and spd*1.06 or spd+15
      hits=hits+1; outs[hits]=spd
      -- the server's hit effect reaches the client half a ping later
      local who, pitch = tgtName, 1 + hits/20
      w.R.task.delay(w.oneway, function() w.ballCtl.Server.HitEffect(who, "Katana", "LogBall", pitch, nil) end)
      if tgtName=="Hero" then tgtName="Foe"; tgtPos=fpos; target("Foe") else tgtName="Hero"; tgtPos=me; target("Hero") end
      local d=(tgtPos-pos).Unit; local a=math.rad(hits%2==0 and 40 or -40)
      dirv=v3(d.X*math.cos(a)-d.Z*math.sin(a),0,d.X*math.sin(a)+d.Z*math.cos(a))
      if hits>=hitsWanted then break end
    end
    hist[#hist+1]={t=t,p=pos,v=dirv*spd}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-(w.oneway+0.12) then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("LogBall",n)
    end
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  -- let the last hits be measured
  for _=1,60 do
    t=t+dt; pos=pos+dirv*(spd*dt); hist[#hist+1]={t=t,p=pos,v=dirv*spd}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-(w.oneway+0.12) then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor("LogBall",n)
    end
    w.RunService.Heartbeat:Fire(); R.advance(dt)
  end
  local fn=w.genv.AnimeBallHubHitLog
  if type(fn)~="function" then return nil, "AnimeBallHubHitLog not exposed" end
  local ok,rep=pcall(fn)
  if not ok then return nil, "build error: "..tostring(rep) end
  if showReport then print(rep) end
  return rep, hits, outs
end

local function num(rep, pat) return tonumber(rep:match(pat)) end

print("=== Ball Hit Logger: does the log read back the game's speed rule? ===")
local good,total=0,0
for _,c in ipairs({
    {"mult", 90, 60, 120}, {"mult", 150, 60, 120}, {"mult", 200, 45, 150},
    {"add", 90, 60, 120}, {"add", 150, 60, 120}, {"add", 200, 45, 150}}) do
  local rule,ping,gap,spd0=c[1],c[2],c[3],c[4]
  local rep,hits,outs=rally(ping, rule, gap, spd0, 16, tonumber(os.getenv("SHOW") or "") == total+1)   -- SHOW=n prints case n's log
  total=total+1
  if not rep then
    print(string.format("  %-4s ping %3d -> FAIL: %s", rule, ping, tostring(hits)))
  else
    local logged=num(rep, "| (%d+) hits in")
    local avgP=num(rep, "avg ([%+%-][%d%.]+)%% %(median")
    local avgA=num(rep, "= avg ([%+%-][%d%.]+) studs/s")
    local acc=num(rep, "median speed%-up ([%+%-][%d%.]+) studs/s per second")
    local rulePick = rep:match("looks like the same (%u+)")
    -- the true per-hit change: x1.06 -> +6%; +15 studs/s
    local okRule = (rule=="mult" and rulePick=="PERCENT") or (rule=="add" and rulePick=="STUDS")
    local okNum = rule=="mult" and avgP and math.abs(avgP-6)<=1.0 or rule=="add" and avgA and math.abs(avgA-15)<=2.0
    local okHits = logged == hits   -- the serve (the opponent's first hit) counts too
    -- (flights under 0.15s are too short to time the speed-up: the log leaves
    -- it out then, as in the 45-stud rallies)
    local longest=num(rep, "longest ([%d%.]+)s")
    local okAcc = acc and math.abs(acc-18)<=4 or (not acc and longest and longest < 0.3)
    local fxN=num(rep, "game HitEffect calls seen: (%d+)")
    local _, fxRows=rep:gsub("| [%w]+, Katana, LogBall", "")
    local okFx = fxN==hits-1 and fxRows>=hits-2   -- every hit after the serve, matched to its row
    local ok = okRule and okNum and okHits and okAcc and okFx
    if ok then good=good+1 end
    print(string.format("  %-4s ping %3d gap %2d -> logged %s/%d hits, avg %s%% / %s studs/s per hit, flight %s studs/s/s, rule %s, game hit effects %s (%d matched) -> %s",
      rule, ping, gap, tostring(logged), hits, tostring(avgP), tostring(avgA), tostring(acc), tostring(rulePick),
      tostring(fxN), fxRows, ok and "OK" or "WRONG"))
  end
end
print(string.format("\n=== %d/%d read back correctly ===", good, total))
