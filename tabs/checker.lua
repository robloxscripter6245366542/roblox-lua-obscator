local SS = _G._SS
local C  = SS.C
local Frm,Lbl,Btn,Scr,hov,tw = SS.Frm,SS.Lbl,SS.Btn,SS.Scr,SS.hov,SS.tw
local corner,stroke,listH,listV,pad = SS.corner,SS.stroke,SS.listH,SS.listV,SS.pad
local FB,FN,FC = SS.FB,SS.FN,SS.FC

local P = SS.newTab("✓","Checker")

-- Load data files from GitHub
local function loadData(path)
    local ok, src = pcall(game.HttpGet, game, path, true)
    if not ok then warn("[SS] Data fail: "..tostring(src)); return end
    local fn, ce = loadstring(src)
    if not fn then warn("[SS] Data compile: "..tostring(ce)); return end
    pcall(fn)
end
loadData(SS.RAW.."data/unc.lua")
loadData(SS.RAW.."data/sunc.lua")
loadData(SS.RAW.."data/myriad.lua")

-- Sub-tab row
local subRow = Frm(P, UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), C.EDIT, "SubRow")
corner(subRow, 6); listH(subRow, 2); pad(subRow, 2, 2)

local ChkScr    = Scr(P, UDim2.new(1,0,1,-30), UDim2.new(0,0,0,28)); listV(ChkScr, 2)
local subBtns   = {}; local curSub = 0

local function switchSub(i)
    curSub = i
    for j,b in subBtns do
        tw(b, {BackgroundColor3=j==i and C.ACC or C.PANEL})
        b.TextColor3 = j==i and C.TXT or C.TXTS
    end
end

local function addSub(name, order)
    local b = Btn(subRow, name, UDim2.new(0,156,1,0), nil, C.PANEL, C.TXTS)
    b.LayoutOrder = order; b.TextSize = 12
    hov(b, C.PANEL, Color3.fromRGB(28,28,40))
    b.MouseButton1Click:Connect(function()
        switchSub(order)
        buildList(order)
    end)
    subBtns[order] = b
end

addSub("UNC (100)",   1)
addSub("SUNC (100)",  2)
addSub("Myriad (250)",3)

local LISTS = {
    function() return SS.UNC_LIST    or {} end,
    function() return SS.SUNC_LIST   or {} end,
    function() return SS.MYRIAD_LIST or {} end,
}
local LCOLS = {C.ACC, C.BLUE, C.YELL}

local function hasFunc(name)
    local root = name:match("^([^%.]+)%.")
    if root then
        local tbl = (getfenv and getfenv()[root]) or _G[root]
        if type(tbl) == "table" then
            local sub = name:match("%.(.+)$"); return tbl[sub] ~= nil
        end
        return false
    end
    if getfenv and getfenv()[name] ~= nil then return true end
    return _G[name] ~= nil
end

function buildList(li)
    for _, ch in ChkScr:GetChildren() do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local list = LISTS[li]()
    local col  = LCOLS[li]
    local pass, fail = 0, 0
    for _, name in list do
        local ok2 = hasFunc(name)
        if ok2 then pass += 1 else fail += 1 end
        local Row = Frm(ChkScr, UDim2.new(1,-4,0,22), nil, Color3.fromRGB(0,0,0))
        Row.BackgroundTransparency = 1
        local dot = Frm(Row, UDim2.new(0,6,0,6), UDim2.new(0,1,0,8), ok2 and C.GREEN or C.RED)
        corner(dot, 3)
        Lbl(Row, name, UDim2.new(1,-50,1,0), UDim2.new(0,11,0,0), ok2 and C.TXT or C.TXTS, FC, 12)
        Lbl(Row, ok2 and "✓" or "✗", UDim2.new(0,28,1,0), UDim2.new(1,-30,0,0),
            ok2 and col or C.RED, FB, 13, Enum.TextXAlignment.Right)
    end
    if pass + fail > 0 then
        local SR = Frm(ChkScr, UDim2.new(1,-4,0,24), nil, C.PANEL); corner(SR, 5)
        Lbl(SR, string.format("  %d/%d supported  (%d missing)", pass, pass+fail, fail),
            UDim2.new(1,0,1,0), nil, C.YELL, FB, 12, Enum.TextXAlignment.Center)
    end
end

-- initChecker is called from the bootstrap after all tabs load
SS.initChecker = function()
    switchSub(1); buildList(1)
end
