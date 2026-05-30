-- TAB: Script Library  (powered by ScriptBlox API)
local SS = _G._SS
local C,tw,corner,stroke,pad,listH,listV=SS.C,SS.tw,SS.corner,SS.stroke,SS.pad,SS.listH,SS.listV
local F,L,B,IN,OUT,SCR,hov=SS.F,SS.L,SS.B,SS.IN,SS.OUT,SS.SCR,SS.hov
local HTTP=SS.HTTP

local P = SS.registerTab("📚", "Scripts")

-- ── Layout ─────────────────────────────────────────────────
-- Search bar row
local SearchRow = F(P,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),Color3.fromRGB(0,0,0))
SearchRow.BackgroundTransparency=1; listH(SearchRow,5)

local SearchBox = Instance.new("TextBox")
SearchBox.Size=UDim2.new(1,-90,1,0); SearchBox.Position=UDim2.new(0,0,0,0)
SearchBox.BackgroundColor3=C.EDITOR; SearchBox.BorderSizePixel=0
SearchBox.Text=""; SearchBox.PlaceholderText="Search ScriptBlox... (e.g. Da Hood, Pet Sim)"
SearchBox.TextColor3=C.TXT; SearchBox.PlaceholderColor3=C.TXTS
SearchBox.Font=SS.FN; SearchBox.TextSize=13; SearchBox.ClearTextOnFocus=false
SearchBox.MultiLine=false; SearchBox.TextXAlignment=Enum.TextXAlignment.Left
SearchBox.LayoutOrder=1; SearchBox.Parent=SearchRow
corner(SearchBox,7); stroke(SearchBox,C.BORDER,1); pad(SearchBox,0,10)

local BSearch = B(SearchRow,"Search",UDim2.new(0,82,1,0),nil,C.ACC)
BSearch.LayoutOrder=2
hov(BSearch,C.ACC,C.ACCHV)

-- Results scroll
local RESULTS = SCR(P,UDim2.new(1,0,1,-68),UDim2.new(0,0,0,36))
listV(RESULTS,4)

-- Status label
local STATUS = L(P,"Type a game name above and press Search",
    UDim2.new(1,0,0,22),UDim2.new(0,0,1,-28),C.TXTS,SS.FN,12,Enum.TextXAlignment.Center)

-- Script viewer (hidden until a script is selected)
local VIEWER_BG = F(P,UDim2.new(1,0,1,-36),UDim2.new(0,0,0,34),Color3.fromRGB(0,0,0))
VIEWER_BG.BackgroundTransparency=1; VIEWER_BG.Visible=false

local VIEWER_BACK = B(VIEWER_BG,"← Back",UDim2.new(0,80,0,24),UDim2.new(0,0,0,0),C.GREY)
local VIEWER_EXEC = B(VIEWER_BG,"▶ Execute",UDim2.new(0,110,0,24),UDim2.new(0,86,0,0),C.ACC)
local VIEWER_COPY = B(VIEWER_BG,"Copy",UDim2.new(0,74,0,24),UDim2.new(0,202,0,0),C.GREY)
hov(VIEWER_BACK,C.GREY,C.GREYHV); hov(VIEWER_EXEC,C.ACC,C.ACCHV); hov(VIEWER_COPY,C.GREY,C.GREYHV)

local VIEWER_TITLE = L(VIEWER_BG,"Script",UDim2.new(1,-290,0,20),UDim2.new(0,282,0,2),C.TXT,SS.FB,13)

local VIEWER_CODE = Instance.new("TextBox")
VIEWER_CODE.Size=UDim2.new(1,0,1,-30); VIEWER_CODE.Position=UDim2.new(0,0,0,28)
VIEWER_CODE.BackgroundColor3=C.CONSOLE; VIEWER_CODE.BorderSizePixel=0
VIEWER_CODE.Text=""; VIEWER_CODE.PlaceholderText=""
VIEWER_CODE.TextColor3=C.TXT; VIEWER_CODE.Font=SS.FC; VIEWER_CODE.TextSize=12
VIEWER_CODE.TextXAlignment=Enum.TextXAlignment.Left; VIEWER_CODE.TextYAlignment=Enum.TextYAlignment.Top
VIEWER_CODE.ClearTextOnFocus=false; VIEWER_CODE.MultiLine=true; VIEWER_CODE.TextWrapped=true
VIEWER_CODE.TextEditable=false; VIEWER_CODE.ClipsDescendants=true; VIEWER_CODE.Parent=VIEWER_BG
corner(VIEWER_CODE,7); stroke(VIEWER_CODE,C.BORDER,1); pad(VIEWER_CODE,8,10)

-- ── Script card builder ────────────────────────────────────
local function clearResults()
    for _, ch in RESULTS:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
end

local function showViewer(title, code)
    RESULTS.Visible  = false
    SearchRow.Visible= false
    STATUS.Visible   = false
    VIEWER_BG.Visible= true
    VIEWER_TITLE.Text= title
    VIEWER_CODE.Text = code
end

local function hideViewer()
    VIEWER_BG.Visible= false
    RESULTS.Visible  = true
    SearchRow.Visible= true
    STATUS.Visible   = true
end

VIEWER_BACK.MouseButton1Click:Connect(hideViewer)

VIEWER_EXEC.MouseButton1Click:Connect(function()
    local code=VIEWER_CODE.Text; if code=="" then return end
    local fn,ce=loadstring(code)
    if not fn then
        STATUS.Text="✗ Compile error: "..tostring(ce)
        STATUS.TextColor3=C.RED
        hideViewer(); return
    end
    local ok,re=pcall(fn)
    STATUS.Text = ok and "✓ Script executed." or "✗ "..tostring(re)
    STATUS.TextColor3 = ok and C.GREEN or C.RED
    hideViewer()
end)

VIEWER_COPY.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(VIEWER_CODE.Text)
        STATUS.Text="✓ Copied to clipboard."
        STATUS.TextColor3=C.GREEN
    end
    hideViewer()
end)

local function makeCard(name, game_name, verified, scriptCode, idx)
    local CARD = F(RESULTS,UDim2.new(1,-6,0,60),nil,C.PANEL)
    corner(CARD,8)
    stroke(CARD, Color3.fromRGB(35,35,52),1)

    -- Game name tag
    local TAG = F(CARD,UDim2.new(0,0,0,20),UDim2.new(0,8,0,8),Color3.fromRGB(0,0,0))
    TAG.BackgroundTransparency=1

    local tag_bg = F(TAG,UDim2.new(0,0,0,18),UDim2.new(0,0,0,1),C.ACC)
    tag_bg.AutomaticSize=Enum.AutomaticSize.X; corner(tag_bg,4)
    pad(tag_bg,1,6)
    local tagLbl=L(tag_bg,game_name,UDim2.new(0,0,1,0),nil,C.TXT,SS.FM,11)
    tagLbl.AutomaticSize=Enum.AutomaticSize.X

    -- Verified badge
    if verified then
        local vbg=F(TAG,UDim2.new(0,0,0,18),UDim2.new(0,0,0,1),Color3.fromRGB(28,180,70))
        vbg.AutomaticSize=Enum.AutomaticSize.X; vbg.Position=UDim2.new(0,math.max(70,#game_name*7+16)+4,0,1)
        corner(vbg,4); pad(vbg,1,6)
        local vl=L(vbg,"✓ Verified",UDim2.new(0,0,1,0),nil,C.WHITE,SS.FM,10)
        vl.AutomaticSize=Enum.AutomaticSize.X
    end

    -- Script name
    L(CARD,name,UDim2.new(1,-110,0,20),UDim2.new(0,8,0,30),C.TXT,SS.FB,13)

    -- Execute and Copy buttons
    local CardRow=F(CARD,UDim2.new(0,0,0,22),UDim2.new(1,-104,0,32),Color3.fromRGB(0,0,0))
    CardRow.BackgroundTransparency=1; listH(CardRow,4)
    local CE=B(CardRow,"▶",UDim2.new(0,30,1,0),nil,C.ACC)
    local CV=B(CardRow,"View",UDim2.new(0,56,1,0),nil,C.GREY)
    local CC=B(CardRow,"Copy",UDim2.new(0,46,1,0),nil,C.GREY)
    CE.LayoutOrder=1; CV.LayoutOrder=2; CC.LayoutOrder=3
    CE.TextSize=14
    hov(CE,C.ACC,C.ACCHV); hov(CV,C.GREY,C.GREYHV); hov(CC,C.GREY,C.GREYHV)

    CE.MouseButton1Click:Connect(function()
        local fn,err2=loadstring(scriptCode)
        if not fn then
            STATUS.Text="✗ Compile error: "..tostring(err2); STATUS.TextColor3=C.RED; return
        end
        local ok,re=pcall(fn)
        STATUS.Text=ok and "✓ Executed: "..name or "✗ "..tostring(re)
        STATUS.TextColor3=ok and C.GREEN or C.RED
    end)

    CV.MouseButton1Click:Connect(function() showViewer(name, scriptCode) end)

    CC.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(scriptCode)
            STATUS.Text="✓ Copied: "..name; STATUS.TextColor3=C.GREEN
        end
    end)

    return CARD
end

-- ── ScriptBlox API fetch ───────────────────────────────────
local API_BASE = "https://scriptblox.com/api/script/fetch"

local function fetchScripts(query)
    clearResults()
    STATUS.Text="Searching ScriptBlox for: "..query.."..."
    STATUS.TextColor3=C.YELLOW

    task.spawn(function()
        local url = API_BASE.."?q="..HTTP:UrlEncode(query).."&max=20"
        local ok, raw = pcall(function() return HTTP:GetAsync(url, true) end)
        if not ok then
            STATUS.Text="✗ HTTP error: "..tostring(raw)
            STATUS.TextColor3=C.RED; return
        end

        local ok2, data = pcall(function() return HTTP:JSONDecode(raw) end)
        if not ok2 then
            STATUS.Text="✗ JSON error"
            STATUS.TextColor3=C.RED; return
        end

        -- ScriptBlox response: { result: { scripts: [...] } }
        local scripts = (data.result and data.result.scripts) or data.scripts or {}

        if #scripts == 0 then
            STATUS.Text="No results for: "..query
            STATUS.TextColor3=C.YELLOW; return
        end

        clearResults()
        for i, s in scripts do
            local sname    = tostring(s.title or s.name or "Untitled")
            local gameName = tostring((s.game and (s.game.name or s.game)) or "Universal")
            local verified = s.verified == true
            local code     = tostring(s.script or s.code or "")
            makeCard(sname, gameName, verified, code, i)
        end

        STATUS.Text=string.format("Found %d script(s) from ScriptBlox", #scripts)
        STATUS.TextColor3=C.GREEN
    end)
end

-- Search on button click or Enter key
BSearch.MouseButton1Click:Connect(function()
    local q=SearchBox.Text:match("^%s*(.-)%s*$")
    if q=="" then STATUS.Text="Enter a search term."; STATUS.TextColor3=C.YELLOW; return end
    fetchScripts(q)
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local q=SearchBox.Text:match("^%s*(.-)%s*$")
        if q~="" then fetchScripts(q) end
    end
end)

-- Load popular scripts on open
fetchScripts("Arsenal")
