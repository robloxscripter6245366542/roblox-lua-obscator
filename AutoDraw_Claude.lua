-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   AutoDraw Claude AI  —  4-Game Universal Auto Drawer               ║
-- ║   Supports: Draw.me · Gartic · Guess The Drawing · Drawing & Guess  ║
-- ║   Remote-first (fires game remotes directly, no canvas click needed) ║
-- ║   Falls back to VirtualInputManager if no remote is found.          ║
-- ║   Claude claude-opus-4-6 via Pollinations AI generates the strokes. ║
-- ╚══════════════════════════════════════════════════════════════════════╝

local Players  = game:GetService("Players")
local RS       = game:GetService("ReplicatedStorage")
local UIS      = game:GetService("UserInputService")
local TS       = game:GetService("TweenService")
local VIM      = game:GetService("VirtualInputManager")
local SG       = game:GetService("StarterGui")

local LP       = Players.LocalPlayer
local PGui     = LP:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════════
--  GAME DETECTION  (place IDs + GUI fingerprint for 4+ drawing games)
-- ═══════════════════════════════════════════════════════════════════
local GAME_DB = {
    -- Draw Me! (DuoBlock)
    [2263973400]  = "DrawMe",
    [6516141723]  = "DrawMe",
    [2787585773]  = "DrawMe",   -- known alt place IDs
    [7915175407]  = "DrawMe",
    -- Gartic on Roblox
    [6247699220]  = "Gartic",
    [8561474656]  = "Gartic",
    -- Guess The Drawing
    [3755647771]  = "GuessDrawing",
    [5625965495]  = "GuessDrawing",
    -- Drawing & Guessing
    [4850476046]  = "DrawGuess",
    [8757720590]  = "DrawGuess",
}
-- GUI fingerprints — reliable when PlaceId isn't in DB
local function detectByGui()
    -- Draw Me! by DuoBlock shows DrawingCanvasGuis in PlayerGui
    if PGui:FindFirstChild("DrawingCanvasGuis")
    or PGui:FindFirstChild("RoundPhaseGuis")
    or PGui:FindFirstChild("VotingGuis") then return "DrawMe" end
    -- Gartic-style lobby
    if PGui:FindFirstChild("GarticGui") then return "Gartic" end
    return nil
end
-- Try PlaceId first; GUI fingerprint needs a tick for GUIs to replicate
local GAME_ID = GAME_DB[game.PlaceId] or "Universal"
task.defer(function()
    local byGui = detectByGui()
    if byGui and GAME_ID == "Universal" then GAME_ID = byGui end
end)

-- ═══════════════════════════════════════════════════════════════════
--  HTTP POST  (works on every major executor)
-- ═══════════════════════════════════════════════════════════════════
local function httpPost(url, body, headers)
    headers = headers or {}
    headers["Content-Type"] = "application/json"
    local function try(fn)
        local ok, r = pcall(fn, {Url=url, Method="POST", Headers=headers, Body=body})
        if ok and r and r.Body then return r.Body end
    end
    if typeof(syn)    == "table" and syn.request    then local r=try(syn.request);    if r then return r end end
    if typeof(fluxus) == "table" and fluxus.request then local r=try(fluxus.request); if r then return r end end
    if type(request)  == "function"                 then local r=try(request);         if r then return r end end
    if typeof(http)   == "table" and http.request   then local r=try(http.request);    if r then return r end end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════
--  MINIMAL JSON ENCODER
-- ═══════════════════════════════════════════════════════════════════
local function encodeJSON(v)
    local t = type(v)
    if t == "string"  then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"'
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return tostring(v)
    elseif t == "table"   then
        if #v > 0 then
            local p={}; for _,i in ipairs(v) do p[#p+1]=encodeJSON(i) end
            return "["..table.concat(p,",").."]"
        else
            local p={}; for k,val in pairs(v) do p[#p+1]='"'..tostring(k)..'":'..encodeJSON(val) end
            return "{"..table.concat(p,",").."}"
        end
    end
    return "null"
end

-- ═══════════════════════════════════════════════════════════════════
--  CLAUDE AI  via Pollinations  (claude-opus-4-6)
-- ═══════════════════════════════════════════════════════════════════
local MODEL = "claude-opus-4-6"
local SYS = [[You are a drawing assistant for Roblox drawing games (Draw.me, Gartic, etc.).
Respond ONLY with valid JSON — no markdown, no explanation.
Canvas is 1.0×1.0 (0,0=top-left, 1,1=bottom-right).
Colors (use EXACTLY one): red orange yellow green blue purple pink brown black white gray lightblue darkgreen darkblue
Format:
{"strokes":[{"color":"black","size":5,"points":[[0.1,0.1],[0.2,0.3]]}]}
Rules: ≤40 strokes, 2-20 pts each, size 2-10, draw simply and recognizably.]]

local function askClaude(prompt)
    local body = encodeJSON({
        model=MODEL, jsonMode=true, seed=42,
        messages={
            {role="system", content=SYS},
            {role="user",   content="Draw: "..prompt},
        },
    })
    return httpPost("https://text.pollinations.ai/", body)
end

-- ═══════════════════════════════════════════════════════════════════
--  JSON STROKE PARSER
-- ═══════════════════════════════════════════════════════════════════
local function parseStrokes(raw)
    local out = {}
    if not raw then return out end
    raw = raw:gsub("```json",""):gsub("```","")
    local inner = raw:match('"strokes"%s*:%s*%[(.+)%]%s*}?$')
                  or raw:match('%[(.+)%]')
    if not inner then return out end
    for obj in inner:gmatch("{([^{}]+)}") do
        local s = {
            color  = obj:match('"color"%s*:%s*"([^"]+)"') or "black",
            size   = tonumber(obj:match('"size"%s*:%s*(%d+)')) or 4,
            points = {},
        }
        local pts = obj:match('"points"%s*:%s*%[(.-)%]')
        if pts then
            for x,y in pts:gmatch('[%[%s]*([%d%.]+)%s*,%s*([%d%.]+)%s*%]') do
                s.points[#s.points+1] = {tonumber(x), tonumber(y)}
            end
        end
        if #s.points >= 2 then out[#out+1] = s end
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════
--  COLOR MAP  (name → Color3)
-- ═══════════════════════════════════════════════════════════════════
local PALETTE = {
    red=Color3.fromRGB(255,0,0),     orange=Color3.fromRGB(255,127,0),
    yellow=Color3.fromRGB(255,255,0),green=Color3.fromRGB(0,200,0),
    blue=Color3.fromRGB(0,0,255),    purple=Color3.fromRGB(128,0,128),
    pink=Color3.fromRGB(255,105,180),brown=Color3.fromRGB(139,69,19),
    black=Color3.fromRGB(0,0,0),     white=Color3.fromRGB(255,255,255),
    gray=Color3.fromRGB(128,128,128),lightblue=Color3.fromRGB(135,206,235),
    darkgreen=Color3.fromRGB(0,100,0),darkblue=Color3.fromRGB(0,0,139),
}

-- ═══════════════════════════════════════════════════════════════════
--  REMOTE DISCOVERY  —  scans ALL RemoteEvents across the whole game
--  Keywords that suggest a drawing remote:
-- ═══════════════════════════════════════════════════════════════════
local DRAW_KW = {
    "draw","stroke","paint","brush","canvas","pixel","ink",
    "pencil","mark","line","sketch","doodle","write","scribble",
}
local function looksLikeDrawRemote(name)
    local n = name:lower()
    for _, kw in ipairs(DRAW_KW) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

-- Collect every RemoteEvent in the game tree
local function collectAllRemotes()
    local found = {}
    local seen  = {}
    local function add(o)
        if not seen[o] and typeof(o)=="Instance" and o:IsA("RemoteEvent") then
            seen[o]=true; found[#found+1]=o
        end
    end
    for _, d in ipairs(game:GetDescendants()) do add(d) end
    -- nil-parented / hidden (executor-only)
    if getnilinstances then
        local ok,nils = pcall(getnilinstances)
        if ok and type(nils)=="table" then for _,o in ipairs(nils) do pcall(add,o) end end
    end
    if getgc then
        local ok,gc = pcall(getgc, true)
        if ok and type(gc)=="table" then for _,o in ipairs(gc) do pcall(add,o) end end
    end
    return found
end

-- Find the best drawing remote (keyword match first, then first RE in RS)
local function findDrawRemote()
    local all = collectAllRemotes()
    -- priority 1: name matches draw keywords
    for _, r in ipairs(all) do
        if looksLikeDrawRemote(r.Name) then return r, "keyword" end
    end
    -- priority 2: any RE under ReplicatedStorage (common for drawing games)
    for _, r in ipairs(all) do
        local ok, inRS = pcall(function() return r:IsDescendantOf(RS) end)
        if ok and inRS then return r, "rs-fallback" end
    end
    return nil, "none"
end

-- ═══════════════════════════════════════════════════════════════════
--  PASSIVE REMOTE SPY  —  __namecall hook to LEARN the draw remote
--  When the player draws manually the first time, we capture the
--  remote + argument shape so we can replay it with our coordinates.
-- ═══════════════════════════════════════════════════════════════════
local learnedRemote   = nil
local learnedArgShape = nil   -- "argShape" = list of arg types seen

local function installSpy()
    if not (hookmetamethod and getrawmetatable and getnamecallmethod and newcclosure) then
        return false
    end
    local mt = getrawmetatable(game)
    if setreadonly then pcall(setreadonly, mt, false) end
    local _old; _old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" then
            local ok, isRE = pcall(function() return self:IsA("RemoteEvent") end)
            if ok and isRE and looksLikeDrawRemote(self.Name) and not learnedRemote then
                learnedRemote   = self
                local args      = {...}
                learnedArgShape = {}
                for i, a in ipairs(args) do
                    learnedArgShape[i] = { t=typeof(a), v=a }
                end
                print(("[AutoDraw] Learned remote: %s  (%d args)"):format(self.Name, #args))
            end
        end
        return _old(self, ...)
    end))
    if setreadonly then pcall(setreadonly, mt, true) end
    return true
end
local spyInstalled = installSpy()

-- ═══════════════════════════════════════════════════════════════════
--  DRAW VIA REMOTE  —  fires the discovered remote with stroke data
--  Supports multiple argument shapes used by different drawing games:
--
--  Shape A — Draw.me style:
--    FireServer(x1, y1, x2, y2, colorR, colorG, colorB, size)
--
--  Shape B — Gartic / GuessDrawing style:
--    FireServer({x=, y=, color=Color3, size=, isDown=bool})
--
--  Shape C — Drawing & Guessing style:
--    FireServer("stroke", Color3, size, {Vector2,...})
--
--  Shape D — learned from spy (replays shape with new coordinates)
-- ═══════════════════════════════════════════════════════════════════
local function fireDrawRemote(remote, stroke, delay)
    local pts   = stroke.points
    local col   = PALETTE[stroke.color] or PALETTE.black
    local sz    = stroke.size or 4
    if #pts < 2 then return end

    -- If we learned the shape from the spy, try to replay it
    if learnedRemote == remote and learnedArgShape then
        local shape = learnedArgShape
        local first = shape[1]

        -- Shape D: learned — detect pattern from first arg type
        if first and first.t == "number" then
            -- likely Shape A: x1,y1,x2,y2,r,g,b,size
            for i = 2, #pts do
                if _G.__AutoDrawStop then return end
                local p0, p1 = pts[i-1], pts[i]
                pcall(function()
                    remote:FireServer(p0[1],p0[2],p1[1],p1[2], col.R,col.G,col.B, sz)
                end)
                task.wait(delay)
            end
            return

        elseif first and first.t == "table" then
            -- Shape B: table arg
            for _, pt in ipairs(pts) do
                if _G.__AutoDrawStop then return end
                pcall(function()
                    remote:FireServer({x=pt[1],y=pt[2],color=col,size=sz,isDown=true})
                end)
                task.wait(delay)
            end
            pcall(function()
                local last = pts[#pts]
                remote:FireServer({x=last[1],y=last[2],color=col,size=sz,isDown=false})
            end)
            return

        elseif first and first.t == "Color3" then
            -- Shape C: Color3,size,{Vector2,...}
            local vecs = {}
            for _, pt in ipairs(pts) do vecs[#vecs+1] = Vector2.new(pt[1], pt[2]) end
            pcall(function() remote:FireServer(col, sz, vecs) end)
            task.wait(delay * #pts)
            return
        end
    end

    -- No learned shape — try all 4 shapes in parallel and see which
    -- one the game responds to (silent errors for wrong shapes)

    -- Shape A
    task.spawn(function()
        for i = 2, #pts do
            if _G.__AutoDrawStop then return end
            local p0, p1 = pts[i-1], pts[i]
            pcall(function() remote:FireServer(p0[1],p0[2],p1[1],p1[2], col.R,col.G,col.B, sz) end)
            task.wait(delay)
        end
    end)

    -- Shape B
    task.spawn(function()
        for _, pt in ipairs(pts) do
            if _G.__AutoDrawStop then return end
            pcall(function() remote:FireServer({x=pt[1],y=pt[2],color=col,size=sz,isDown=true}) end)
            task.wait(delay)
        end
        local last = pts[#pts]
        pcall(function() remote:FireServer({x=last[1],y=last[2],color=col,size=sz,isDown=false}) end)
    end)

    -- Shape C
    task.spawn(function()
        local vecs = {}
        for _, pt in ipairs(pts) do vecs[#vecs+1] = Vector2.new(pt[1], pt[2]) end
        pcall(function() remote:FireServer(col, sz, vecs) end)
    end)

    -- Shape D — string-tagged variant used by some games
    task.spawn(function()
        local vecs = {}
        for _, pt in ipairs(pts) do vecs[#vecs+1] = Vector2.new(pt[1], pt[2]) end
        pcall(function() remote:FireServer("stroke", col, sz, vecs) end)
    end)

    task.wait(delay * #pts)
end

-- ═══════════════════════════════════════════════════════════════════
--  FALLBACK — VirtualInputManager canvas drawing
--  Used when no remote is found.
-- ═══════════════════════════════════════════════════════════════════
local CANVAS_KW = {
    "canvas","board","drawingboard","drawframe","sketchpad",
    "paintboard","draw","ink","paint","sketch",
}

local function findCanvas()
    -- Priority 1: Draw Me! (DuoBlock) — DrawingCanvasGuis ScreenGui
    -- This GUI only exists when the player's turn to draw starts.
    local dcg = PGui:FindFirstChild("DrawingCanvasGuis")
    if dcg then
        -- Look for the largest Frame inside it (that's the drawable area)
        local best, bestArea = nil, 0
        for _, d in ipairs(dcg:GetDescendants()) do
            if d:IsA("Frame") or d:IsA("ImageLabel") then
                local sz = d.AbsoluteSize
                local area = sz.X * sz.Y
                if area > bestArea and sz.X >= 150 and sz.Y >= 150 then
                    bestArea = area; best = d
                end
            end
        end
        if best then return best end
    end

    -- Priority 2: keyword-matched Frame across all GUIs
    for _, gui in ipairs(PGui:GetChildren()) do
        local n = gui.Name:lower()
        -- Skip GUIs that are clearly not drawing-related
        if not n:find("shop") and not n:find("inv") and not n:find("menu") then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("Frame") then
                    local sz = d.AbsoluteSize
                    if sz.X >= 280 and sz.Y >= 280 then
                        local dn = d.Name:lower()
                        for _, kw in ipairs(CANVAS_KW) do
                            if dn:find(kw,1,true) then return d end
                        end
                    end
                end
            end
        end
    end

    -- Priority 3: any large Frame anywhere in PlayerGui
    for _, gui in ipairs(PGui:GetChildren()) do
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("Frame") then
                local sz = d.AbsoluteSize
                if sz.X >= 280 and sz.Y >= 280 then return d end
            end
        end
    end
    return nil
end

local colorCache = {}
local function colorDist(a,b)
    return (a.R-b.R)^2+(a.G-b.G)^2+(a.B-b.B)^2
end
local function findColorBtn(colorName)
    if colorCache[colorName] and colorCache[colorName].Parent then return colorCache[colorName] end
    local target = PALETTE[colorName] or PALETTE.black
    local best, bd = nil, math.huge
    for _, gui in ipairs(PGui:GetChildren()) do
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("ImageButton") or d:IsA("Frame") then
                local sz = d.AbsoluteSize
                if sz.X>=10 and sz.X<=60 and sz.Y>=10 and sz.Y<=60 then
                    local dist = colorDist(d.BackgroundColor3, target)
                    if dist < bd then bd=dist; best=d end
                end
            end
        end
    end
    if bd < 0.15*3 then colorCache[colorName]=best; return best end
    return nil
end

local function vimStroke(canvas, stroke, delay)
    local ap = canvas.AbsolutePosition
    local sz = canvas.AbsoluteSize
    local col = stroke.color
    local btn = findColorBtn(col)
    if btn then
        local bp = btn.AbsolutePosition + btn.AbsoluteSize*0.5
        VIM:SendMouseButtonEvent(bp.X,bp.Y,0,true,game,1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(bp.X,bp.Y,0,false,game,1)
        task.wait(0.04)
    end
    local function abs(pt)
        return ap.X+pt[1]*sz.X, ap.Y+pt[2]*sz.Y
    end
    local pts = stroke.points
    if #pts < 2 then return end
    local x0,y0 = abs(pts[1])
    VIM:SendMouseMoveEvent(x0,y0,game)
    VIM:SendMouseButtonEvent(x0,y0,0,true,game,1)
    task.wait(delay)
    for i=2,#pts do
        if _G.__AutoDrawStop then VIM:SendMouseButtonEvent(x0,y0,0,false,game,1); return end
        local xi,yi = abs(pts[i])
        VIM:SendMouseMoveEvent(xi,yi,game)
        task.wait(delay)
        x0,y0=xi,yi
    end
    VIM:SendMouseButtonEvent(x0,y0,0,false,game,1)
    task.wait(0.02)
end

-- ═══════════════════════════════════════════════════════════════════
--  NOTIFICATION
-- ═══════════════════════════════════════════════════════════════════
local function notify(title, msg)
    pcall(function() SG:SetCore("SendNotification",{Title=title,Text=msg,Duration=4}) end)
end

-- ═══════════════════════════════════════════════════════════════════
--  GUI
-- ═══════════════════════════════════════════════════════════════════
local C = {
    BG=Color3.fromRGB(10,9,15),   PANEL=Color3.fromRGB(18,16,26),
    CARD=Color3.fromRGB(26,24,36),DARK=Color3.fromRGB(6,5,9),
    ACC=Color3.fromRGB(100,60,220),ACC2=Color3.fromRGB(140,95,255),
    GRN=Color3.fromRGB(46,196,110),RED=Color3.fromRGB(235,55,70),
    YLW=Color3.fromRGB(245,185,35),WHT=Color3.fromRGB(235,232,255),
    MUT=Color3.fromRGB(100,95,130),BDR=Color3.fromRGB(44,40,64),
}
local TF = TweenInfo.new(0.15,Enum.EasingStyle.Quad)
local function tw(i,p) TS:Create(i,TF,p):Play() end
local function corner(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 8) end
local function mkStroke(p,col,t) local s=Instance.new("UIStroke",p);s.Color=col or C.BDR;s.Thickness=t or 1 end

local _old2 = PGui:FindFirstChild("__AutoDrawClaude__")
if _old2 then _old2:Destroy() end
_G.__AutoDrawStop = false

local SGI = Instance.new("ScreenGui")
SGI.Name="__AutoDrawClaude__"; SGI.ResetOnSpawn=false
SGI.IgnoreGuiInset=true; SGI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SGI.DisplayOrder=999
pcall(function() SGI.Parent = gethui and gethui() or PGui end)
if not SGI.Parent then SGI.Parent=PGui end

local WIN = Instance.new("Frame",SGI)
WIN.Size=UDim2.new(0,380,0,0); WIN.AutomaticSize=Enum.AutomaticSize.Y
WIN.Position=UDim2.new(0.5,-190,0.5,-230)
WIN.BackgroundColor3=C.BG; WIN.BorderSizePixel=0; WIN.Active=true
corner(WIN,14); mkStroke(WIN,C.BDR,1.5)

-- title bar
local TBAR=Instance.new("Frame",WIN)
TBAR.Size=UDim2.new(1,0,0,50); TBAR.BackgroundColor3=C.PANEL; TBAR.BorderSizePixel=0; corner(TBAR,14)
local tfix=Instance.new("Frame",TBAR); tfix.Size=UDim2.new(1,0,0,14); tfix.Position=UDim2.new(0,0,1,-14); tfix.BackgroundColor3=C.PANEL; tfix.BorderSizePixel=0

local logoF=Instance.new("Frame",TBAR); logoF.Size=UDim2.new(0,30,0,30); logoF.Position=UDim2.new(0,12,0.5,-15); logoF.BackgroundColor3=C.ACC; logoF.BorderSizePixel=0; corner(logoF,9)
local logoL=Instance.new("TextLabel",logoF); logoL.Size=UDim2.new(1,0,1,0); logoL.BackgroundTransparency=1; logoL.Text="✏"; logoL.TextColor3=C.WHT; logoL.Font=Enum.Font.GothamBold; logoL.TextSize=16
task.spawn(function() while logoL and logoL.Parent do logoL.Rotation=(logoL.Rotation+1)%360; task.wait(0.05) end end)

local function tL(txt,yoff,col,fs,font)
    local l=Instance.new("TextLabel",TBAR); l.Size=UDim2.new(0,260,0,18); l.Position=UDim2.new(0,52,0,yoff); l.BackgroundTransparency=1; l.Text=txt; l.TextColor3=col or C.WHT; l.Font=font or Enum.Font.GothamBold; l.TextSize=fs or 14; l.TextXAlignment=Enum.TextXAlignment.Left
end
tL("AutoDraw  ·  Claude AI",8); tL("4 Games · Pollinations AI · "..MODEL,28,C.MUT,10,Enum.Font.Gotham)

-- game badge
local gbF=Instance.new("Frame",TBAR); gbF.Size=UDim2.new(0,90,0,20); gbF.Position=UDim2.new(1,-130,0.5,-10); gbF.BackgroundColor3=Color3.fromRGB(30,20,55); gbF.BorderSizePixel=0; corner(gbF,6)
local gbL=Instance.new("TextLabel",gbF); gbL.Size=UDim2.new(1,0,1,0); gbL.BackgroundTransparency=1; gbL.Text=GAME_ID; gbL.TextColor3=C.ACC2; gbL.Font=Enum.Font.GothamBold; gbL.TextSize=9

local closeBtn=Instance.new("TextButton",TBAR); closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.Position=UDim2.new(1,-40,0.5,-14); closeBtn.BackgroundColor3=C.RED; closeBtn.Text="✕"; closeBtn.TextColor3=C.WHT; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=12; closeBtn.BorderSizePixel=0; corner(closeBtn,8)
closeBtn.MouseButton1Click:Connect(function() SGI:Destroy() end)

-- drag
do
    local drag,st,wp
    TBAR.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;st=i.Position;wp=WIN.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-st; WIN.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
end

-- body
local BODY=Instance.new("Frame",WIN); BODY.Size=UDim2.new(1,0,0,0); BODY.Position=UDim2.new(0,0,0,50); BODY.AutomaticSize=Enum.AutomaticSize.Y; BODY.BackgroundTransparency=1; BODY.BorderSizePixel=0
local bll=Instance.new("UIListLayout",BODY); bll.SortOrder=Enum.SortOrder.LayoutOrder; bll.Padding=UDim.new(0,7)
local bp2=Instance.new("UIPadding",BODY); bp2.PaddingLeft=UDim.new(0,11); bp2.PaddingRight=UDim.new(0,11); bp2.PaddingTop=UDim.new(0,10); bp2.PaddingBottom=UDim.new(0,12)

local lo=0
local function LO() lo=lo+1; return lo end

local function secLbl(txt)
    local l=Instance.new("TextLabel",BODY); l.Size=UDim2.new(1,0,0,13); l.LayoutOrder=LO(); l.BackgroundTransparency=1; l.Text=txt:upper(); l.TextColor3=C.MUT; l.Font=Enum.Font.GothamBold; l.TextSize=9; l.TextXAlignment=Enum.TextXAlignment.Left
end
local function mkCard(h)
    local f=Instance.new("Frame",BODY); f.Size=UDim2.new(1,0,0,h); f.LayoutOrder=LO(); f.BackgroundColor3=C.CARD; f.BorderSizePixel=0; corner(f,9); mkStroke(f,C.BDR); return f
end

-- prompt
secLbl("Describe what to draw")
local pCard=mkCard(38)
local pp=Instance.new("UIPadding",pCard); pp.PaddingLeft=UDim.new(0,10); pp.PaddingRight=UDim.new(0,10)
local promptBox=Instance.new("TextBox",pCard); promptBox.Size=UDim2.new(1,0,1,0); promptBox.BackgroundTransparency=1; promptBox.PlaceholderText="cat, house, tree, sun…"; promptBox.PlaceholderColor3=C.MUT; promptBox.Text=""; promptBox.TextColor3=C.WHT; promptBox.Font=Enum.Font.Gotham; promptBox.TextSize=13; promptBox.ClearTextOnFocus=false; promptBox.TextXAlignment=Enum.TextXAlignment.Left

-- remote status
secLbl("Remote")
local remCard=mkCard(36)
local rp=Instance.new("UIPadding",remCard); rp.PaddingLeft=UDim.new(0,10); rp.PaddingTop=UDim.new(0,4)
local remoteLbl=Instance.new("TextLabel",remCard); remoteLbl.Size=UDim2.new(1,-10,1,0); remoteLbl.BackgroundTransparency=1; remoteLbl.Text="Scanning for draw remotes…"; remoteLbl.TextColor3=C.YLW; remoteLbl.Font=Enum.Font.Gotham; remoteLbl.TextSize=11; remoteLbl.TextXAlignment=Enum.TextXAlignment.Left; remoteLbl.TextWrapped=true

-- speed
secLbl("Speed")
local sRow=Instance.new("Frame",BODY); sRow.Size=UDim2.new(1,0,0,30); sRow.BackgroundTransparency=1; sRow.BorderSizePixel=0; sRow.LayoutOrder=LO()
local srh=Instance.new("UIListLayout",sRow); srh.FillDirection=Enum.FillDirection.Horizontal; srh.Padding=UDim.new(0,6)
local drawDelay=0.02
local speedDefs={{"Fast",0.008},{"Normal",0.020},{"Slow",0.050}}
local sBtns={}
for i,def in ipairs(speedDefs) do
    local b=Instance.new("TextButton",sRow); b.Size=UDim2.new(0,100,1,0); b.BackgroundColor3=i==2 and C.ACC or C.DARK; b.Text=def[1]; b.TextColor3=C.WHT; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0; corner(b,7); sBtns[i]=b
    local spd=def[2]
    b.MouseButton1Click:Connect(function()
        drawDelay=spd
        for j,sb in ipairs(sBtns) do tw(sb,{BackgroundColor3=j==i and C.ACC or C.DARK}) end
    end)
end

-- status
secLbl("Status")
local stCard=mkCard(52)
local sp3=Instance.new("UIPadding",stCard); sp3.PaddingLeft=UDim.new(0,10); sp3.PaddingRight=UDim.new(0,10); sp3.PaddingTop=UDim.new(0,6); sp3.PaddingBottom=UDim.new(0,6)
local statusLbl=Instance.new("TextLabel",stCard); statusLbl.Size=UDim2.new(1,0,1,0); statusLbl.BackgroundTransparency=1; statusLbl.Text="Type a prompt, then Generate & Draw."; statusLbl.TextColor3=C.MUT; statusLbl.Font=Enum.Font.Gotham; statusLbl.TextSize=11; statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.TextWrapped=true; statusLbl.TextYAlignment=Enum.TextYAlignment.Top
local function setStatus(txt,col) statusLbl.Text=txt; statusLbl.TextColor3=col or C.WHT end

-- progress
local pgBG=Instance.new("Frame",BODY); pgBG.Size=UDim2.new(1,0,0,6); pgBG.LayoutOrder=LO(); pgBG.BackgroundColor3=C.DARK; pgBG.BorderSizePixel=0; corner(pgBG,3)
local pgFill=Instance.new("Frame",pgBG); pgFill.Size=UDim2.new(0,0,1,0); pgFill.BackgroundColor3=C.ACC; pgFill.BorderSizePixel=0; corner(pgFill,3)
local function setProgress(p) tw(pgFill,{Size=UDim2.new(math.clamp(p,0,1),0,1,0)}) end

-- draw button
local drawBtn=Instance.new("TextButton",BODY); drawBtn.Size=UDim2.new(1,0,0,44); drawBtn.LayoutOrder=LO(); drawBtn.BackgroundColor3=C.ACC; drawBtn.BorderSizePixel=0; drawBtn.Text="✨  Generate & Draw"; drawBtn.TextColor3=C.WHT; drawBtn.Font=Enum.Font.GothamBold; drawBtn.TextSize=15; corner(drawBtn,10); mkStroke(drawBtn,Color3.fromRGB(80,40,160),1)
drawBtn.MouseEnter:Connect(function() tw(drawBtn,{BackgroundColor3=C.ACC2}) end)
drawBtn.MouseLeave:Connect(function() tw(drawBtn,{BackgroundColor3=C.ACC}) end)

-- spy button
local spyBtn=Instance.new("TextButton",BODY); spyBtn.Size=UDim2.new(1,0,0,32); spyBtn.LayoutOrder=LO(); spyBtn.BackgroundColor3=Color3.fromRGB(25,50,30); spyBtn.BorderSizePixel=0; spyBtn.Text="🔍  Draw Once Manually to Learn Remote"; spyBtn.TextColor3=C.GRN; spyBtn.Font=Enum.Font.GothamBold; spyBtn.TextSize=10; corner(spyBtn,8)
spyBtn.MouseButton1Click:Connect(function()
    learnedRemote=nil; learnedArgShape=nil
    setStatus("Draw ONE stroke manually in the game — spy is watching…", C.YLW)
    spyBtn.Text="👁  Watching for your stroke…"
    task.spawn(function()
        local t=0
        while not learnedRemote and t<15 do task.wait(0.5); t=t+0.5 end
        if learnedRemote then
            spyBtn.Text="✓  Learned: "..learnedRemote.Name
            remoteLbl.Text="✓ Learned remote: "..learnedRemote.Name
            remoteLbl.TextColor3=C.GRN
            setStatus("Remote learned! Now Generate & Draw.", C.GRN)
        else
            spyBtn.Text="✗  No remote caught — try drawing in-game"
            setStatus("No draw remote found. Try the Draw Once button, or it will use VIM fallback.", C.YLW)
        end
    end)
end)

-- stop button
local stopBtn=Instance.new("TextButton",BODY); stopBtn.Size=UDim2.new(1,0,0,32); stopBtn.LayoutOrder=LO(); stopBtn.BackgroundColor3=Color3.fromRGB(75,16,24); stopBtn.BorderSizePixel=0; stopBtn.Text="⏹  Stop"; stopBtn.TextColor3=C.WHT; stopBtn.Font=Enum.Font.GothamBold; stopBtn.TextSize=12; corner(stopBtn,8); stopBtn.Visible=false
stopBtn.MouseButton1Click:Connect(function() _G.__AutoDrawStop=true; setStatus("Stopping…",C.YLW) end)

-- footer
local fL=Instance.new("TextLabel",BODY); fL.Size=UDim2.new(1,0,0,12); fL.LayoutOrder=LO(); fL.BackgroundTransparency=1; fL.Text=MODEL.."  ·  Pollinations AI  ·  Remote + VIM  ·  4 Games"; fL.TextColor3=C.MUT; fL.Font=Enum.Font.Gotham; fL.TextSize=9; fL.TextXAlignment=Enum.TextXAlignment.Center

-- ═══════════════════════════════════════════════════════════════════
--  REMOTE WATCHER  — keeps the remote status label + game badge updated
-- ═══════════════════════════════════════════════════════════════════
task.spawn(function()
    while SGI and SGI.Parent do
        task.wait(3)
        -- Refresh game badge if we've now identified the game
        pcall(function() gbL.Text = GAME_ID end)

        if learnedRemote then
            remoteLbl.Text="✓ Learned: "..learnedRemote.Name
            remoteLbl.TextColor3=C.GRN
        else
            local r, how = findDrawRemote()
            if r then
                remoteLbl.Text="✓ Found: "..r.Name.." ("..how..")"
                remoteLbl.TextColor3=C.GRN
            else
                local canvas=findCanvas()
                if canvas then
                    remoteLbl.Text="No remote — VIM ready ("..math.floor(canvas.AbsoluteSize.X).."×"..math.floor(canvas.AbsoluteSize.Y)..")"
                    remoteLbl.TextColor3=C.YLW
                else
                    -- DrawingCanvasGuis might not exist yet (only appears on drawing turn)
                    local dcg = PGui:FindFirstChild("DrawingCanvasGuis")
                    if dcg then
                        remoteLbl.Text="DrawingCanvasGuis found — click Edit Drawing in-game to get canvas"
                        remoteLbl.TextColor3=C.YLW
                    else
                        remoteLbl.Text="Wait for your drawing turn, or use Spy button after drawing once"
                        remoteLbl.TextColor3=C.MUT
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
--  MAIN DRAW FLOW
-- ═══════════════════════════════════════════════════════════════════
local busy=false

drawBtn.MouseButton1Click:Connect(function()
    if busy then return end
    local prompt=promptBox.Text:match("^%s*(.-)%s*$")
    if prompt=="" then setStatus("Enter something to draw!",C.RED); return end

    busy=true; _G.__AutoDrawStop=false
    drawBtn.Text="⏳  Asking Claude…"; tw(drawBtn,{BackgroundColor3=C.MUT}); stopBtn.Visible=true
    setProgress(0)

    task.spawn(function()
        -- 1. Claude
        setStatus("Asking Claude claude-opus-4-6 via Pollinations AI…",C.YLW); setProgress(0.07)
        local resp=askClaude(prompt)
        if _G.__AutoDrawStop then goto done end
        if not resp or #resp<5 then
            setStatus("No response from Pollinations AI.\nMake sure your executor supports HTTP POST (syn.request / request()).",C.RED); goto done
        end
        setProgress(0.18); setStatus("Parsing strokes…",C.GRN)

        -- 2. Parse
        local strokes=parseStrokes(resp)
        if #strokes==0 then
            setStatus("Could not parse Claude response:\n"..resp:sub(1,100),C.RED); goto done
        end

        -- 3. Pick method
        local remote = learnedRemote or (findDrawRemote())
        local canvas = not remote and findCanvas()
        if not remote and not canvas then
            setStatus("No draw remote found and no canvas visible.\nWait for your turn to draw, or use the Spy button.",C.RED); goto done
        end

        drawBtn.Text="🎨  Drawing…"
        setStatus(
            (remote and ("Remote: "..remote.Name) or "VIM fallback")..
            "  —  "..#strokes.." strokes",
            C.GRN
        )

        -- 4. Draw each stroke
        for i,stk in ipairs(strokes) do
            if _G.__AutoDrawStop then break end
            setProgress(0.18+(i/#strokes)*0.82)
            setStatus("Stroke "..i.."/"..#strokes.."  ["..stk.color.."]  pts="..#stk.points, C.WHT)
            if remote then
                fireDrawRemote(remote, stk, drawDelay)
            else
                vimStroke(canvas, stk, drawDelay)
            end
        end

        setProgress(1)
        if _G.__AutoDrawStop then
            setStatus("Stopped.",C.YLW)
        else
            setStatus("✓ Done! '"..prompt.."' — "..#strokes.." strokes via "..(remote and remote.Name or "VIM"),C.GRN)
            notify("AutoDraw", "Done drawing: "..prompt)
        end

        ::done::
        busy=false; _G.__AutoDrawStop=false
        drawBtn.Text="✨  Generate & Draw"; tw(drawBtn,{BackgroundColor3=C.ACC}); stopBtn.Visible=false
    end)
end)

notify("AutoDraw Claude AI", GAME_ID.." detected  ·  "..(spyInstalled and "Spy ON" or "No spy")..
    "  ·  Draw manually to learn remote, or hit Generate & Draw!")
