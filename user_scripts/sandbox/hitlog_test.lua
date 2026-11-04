-- Ball Hit Logger check. Part 1: a rally between me and an opponent with a
-- KNOWN speed rule; the logger's report (getgenv().AnimeBallHubHitLog()) must
-- read that rule back. Two rules: each hit multiplies the speed (x1.06) or adds
-- to it (+15 studs/s), and the ball also speeds up 18 studs/s every second in
-- flight. As in the game, the ball on screen is half a ping + 0.12s old and the
-- Target attribute half a ping. Part 2: ONE match is recorded - hits from the
-- lobby before it are dropped, every ball of the match is kept (a kill brings a
-- new one), and when the match ends it stops, saves and copies the whole match,
-- and records nothing after. Run: lua hitlog_test.lua [script]
-- (SHOW=n prints case n's log)
local HERE = (arg[0] or ""):match("^(.*[/\\])") or "./"
local SCRIPT = arg[1] or (HERE.."../anime_ball_autoparry.lua")
local SRC = assert(io.open(SCRIPT,"r")):read("*a")
local build = dofile(HERE.."world.lua").build

local function newWorld(ping, gap)
  local w = assert(build(SRC, ping, {yieldTransport=true}))
  local v3,Instance,R = w.v3,w.Instance,w.R
  for _=1,30 do w.RunService.Heartbeat:Fire(); R.advance(1/60) end
  local foe=Instance.new("Player"); foe.Name="Foe"
  local ch=Instance.new("Model"); ch.Name="Foe"
  local fh=Instance.new("Part"); fh.Name="HumanoidRootPart"; fh.Position=v3(0,5,gap); fh.AssemblyLinearVelocity=v3(0,0,0); fh.Parent=ch
  foe.Character=ch; foe.CharacterAdded=R.newSignal(); foe.CharacterRemoving=R.newSignal()
  w.players[#w.players+1]=foe; w.Players.PlayerAdded:Fire(foe)
  w.gap, w.fpos = gap, v3(0,5,gap)
  return w
end

local function idle(w, secs)
  for _=1,math.floor(secs*60) do w.RunService.Heartbeat:Fire(); w.R.advance(1/60) end
end

-- One rally on a fresh ball: the opponent serves, then it goes back and forth
-- `hitsWanted` times (the serve included). Returns the ball and the hit count.
local function playRally(w, name, rule, spd0, hitsWanted, keepBall)
  local v3,Instance,R = w.v3,w.Instance,w.R
  local b=Instance.new("Part"); b.Name=name; b.Parent=w.Balls
  local pending={}
  local function target(n) pending[#pending+1]={at=R.VTIME()+w.oneway, n=n} end
  local me=w.hrp.Position; local fpos=w.fpos
  local hist={}; local t=0; local dt=1/60
  local pos=v3(0,5,w.gap-6)
  local function frame(p, v)
    hist[#hist+1]={t=t,p=p,v=v}
    local sp,sv=hist[1].p,hist[1].v
    for i=#hist,1,-1 do if hist[i].t<=t-(w.oneway+0.12) then sp=hist[i].p; sv=hist[i].v break end end
    b.Position=sp; b.AssemblyLinearVelocity=sv
    while pending[1] and pending[1].at<=R.VTIME() do
      local n=table.remove(pending,1).n
      b:SetAttribute("Target",n); w.ballCtl.Server.ChangeBallColor(name,n)
    end
    w.RunService.Heartbeat:Fire(); R.advance(dt); t=t+dt
  end
  b:SetAttribute("Target","Foe"); w.ballCtl.Server.ChangeBallColor(name,"Foe")
  for _=1,30 do frame(pos, v3(0,0,0)) end   -- the serve hovers by the opponent
  local spd=spd0; local tgtName="Hero"; local tgtPos=me; target("Hero")
  local dirv=(me-pos).Unit
  local hits=1
  for _=1,60*600 do
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
      hits=hits+1
      if rule=="mult" then spd=spd*1.06
      elseif rule=="add" then spd=spd+15
      elseif rule=="real" then   -- like the real match log: +1.5 a hit, and a x0.457 slow now and then
        if hits%6==0 then spd=spd*0.457 else spd=spd+1.5 end
      else spd=spd+0.3 end
      -- the server's hit effect reaches the client half a ping later
      local who, pitch = tgtName, 1 + hits/20
      R.task.delay(w.oneway, function() w.ballCtl.Server.HitEffect(who, "Katana", name, pitch, nil) end)
      if tgtName=="Hero" then tgtName="Foe"; tgtPos=fpos; target("Foe") else tgtName="Hero"; tgtPos=me; target("Hero") end
      local d=(tgtPos-pos).Unit; local a=math.rad(hits%2==0 and 40 or -40)
      dirv=v3(d.X*math.cos(a)-d.Z*math.sin(a),0,d.X*math.sin(a)+d.Z*math.cos(a))
      if hits>=hitsWanted then break end
    end
    frame(pos, dirv*spd)
  end
  for _=1,60 do pos=pos+dirv*(spd*dt); frame(pos, dirv*spd) end   -- let the last hits be measured
  if not keepBall then b.Parent=nil end   -- a kill: the ball goes away
  return b, hits
end

local function num(rep, pat) return tonumber(rep:match(pat)) end
local function log(w)
  local fn=w.genv.AnimeBallHubHitLog
  if type(fn)~="function" then return nil, "AnimeBallHubHitLog not exposed" end
  local ok,rep=pcall(fn)
  if not ok then return nil, "build error: "..tostring(rep) end
  return rep
end

print("=== Ball Hit Logger: does the log read back the game's speed rule? ===")
local good,total=0,0
for _,c in ipairs({
    {"mult", 90, 60, 120}, {"mult", 150, 60, 120}, {"mult", 200, 45, 150},
    {"add", 90, 60, 120}, {"add", 150, 60, 120}, {"add", 200, 45, 150}}) do
  local rule,ping,gap,spd0=c[1],c[2],c[3],c[4]
  local w=newWorld(ping, gap)
  local _,hits=playRally(w, "LogBall", rule, spd0, 16, true)
  local rep,err=log(w)
  total=total+1
  if tonumber(os.getenv("SHOW") or "")==total and rep then print(rep) end
  if not rep then
    print(string.format("  %-4s ping %3d -> FAIL: %s", rule, ping, tostring(err)))
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

print("\n=== Ball Hit Logger: a real-match mix (+1.5 a hit, some x0.46 slows) ===")
for _,ping in ipairs({90, 180}) do
  local w=newWorld(ping, 60)
  local _,hits=playRally(w, "LogBall", "real", 120, 30, true)
  local rep=log(w) or ""
  total=total+1
  if tonumber(os.getenv("SHOW") or "")==total then print(rep) end
  local rulePick=rep:match("looks like the same (%u+)")
  local perHit=num(rep, "between those two frames: ~([%+%-][%d%.]+)")
  local slows=num(rep, "x0%.4%d x(%d+) %(by")
  local want=math.floor(hits/6)   -- every 6th hit
  local fake=rep:match("Set to ~")   -- the slows land on similar speeds, but from similar ones: not a "set to"
  local ok = rulePick=="STUDS" and perHit and math.abs(perHit-1.5)<=0.3 and slows==want and not fake
  if ok then good=good+1 end
  print(string.format("  ping %3d: %d hits -> rule %s, %s studs/s per normal hit, x0.46 slows found %s/%d -> %s",
    ping, hits, tostring(rulePick), tostring(perHit), tostring(slows), want, ok and "OK" or "WRONG"))
end

print("\n=== Ball Hit Logger: records ONE whole match, then stops and copies it ===")
for _,ping in ipairs({90, 180}) do
  local w=newWorld(ping, 60)
  -- lobby practice before the match: dropped when the match starts
  playRally(w, "Practice", "add", 120, 5)
  idle(w, 1)
  w.matchCtl.Server.StartMatch()
  -- the match: a long rally (more than the old 200-row limit), a kill, then a
  -- second ball
  local _,h1=playRally(w, "Ball", "slow", 120, 230)
  idle(w, 2)
  local _,h2=playRally(w, "Ball", "add", 120, 12)
  w.matchCtl.Server.EndMatch()
  local midRep=log(w) or ""
  local stillRec = midRep:match("still being recorded") ~= nil   -- not over until the balls are gone
  idle(w, 6)
  local file=w.files["AnimeBallHub/ball_hits.txt"] or ""
  local fileHits=num(file, "| (%d+) hits in")
  local rows=0
  for line in file:gmatch("[^\n]+") do if line:match("^%d+%s+%d+%s+%-?%d") then rows=rows+1 end end
  local stopped = file:match("stopped: the match ended") ~= nil
  -- copied in parts small enough to paste: part 1 (the summary) by itself
  -- at the match end, the rest one per Copy press; together the whole log
  local partsOk, nParts = false, 0
  do
    local first = w.clip.text or ""
    nParts = tonumber(first:match("^%[Ball hit log part 1 of (%d+)%]")) or 0
    local got, okSize = {}, true
    local cur = first
    for i = 1, nParts do
      if i > 1 then w.genv.AnimeBallHubCopyHitLog(); cur = w.clip.text or "" end
      local body = cur:gsub("^%[Ball hit log part %d+ of %d+%]\n", "")
      if #body > 15000 then okSize = false end
      got[#got+1] = body
    end
    partsOk = nParts >= 2 and okSize and table.concat(got, "\n") == file
      and first:find("== Summary ==", 1, true) ~= nil and first:find("== Big speed changes", 1, true) ~= nil
  end
  -- the on-screen viewer (for when pasting doesn't work) shows the same parts
  local viewOk = false
  do
    local okV, v = pcall(w.genv.AnimeBallHubShowHitLog)
    if okV and type(v)=="table" and v.box and #v.parts == nParts then
      local seen = { v.box.Text }
      for i = 2, nParts do v.go(i); seen[#seen+1] = v.box.Text end
      v.go(nParts + 5)   -- past the end stays on the last part
      viewOk = table.concat(seen, "\n") == file and v.i == nParts and v.gui.Parent ~= nil
    end
  end
  partsOk = partsOk and viewOk
  local practice = file:match("Practice") ~= nil
  -- a next match without Record Next Match: nothing more is recorded
  w.matchCtl.Server.StartMatch()
  playRally(w, "Ball", "add", 120, 8)
  local after=log(w) or ""
  local afterHits=num(after, "| (%d+) hits in")
  local ok = stillRec and fileHits==h1+h2 and rows==h1+h2 and stopped and not practice and afterHits==h1+h2 and partsOk
  total=total+1; if ok then good=good+1 end
  print(string.format("  ping %3d: match had %d + %d hits -> saved %s hits (%d table rows), stopped at the end: %s, practice dropped: %s, next match ignored: %s, copied in %d pasteable parts (and shown on screen): %s -> %s",
    ping, h1, h2, tostring(fileHits), rows, tostring(stopped), tostring(not practice), tostring(afterHits==h1+h2), nParts, tostring(partsOk), ok and "OK" or "WRONG"))
end
print(string.format("\n=== %d/%d correct ===", good, total))
