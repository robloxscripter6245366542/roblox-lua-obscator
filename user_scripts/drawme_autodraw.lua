--[[
    Draw Me! - Auto-Draw (Reference-from-Stage-Player)
    ==================================================

    What it does, in the order you asked for:
      1. LOOK    - finds the player currently on the stage (the round's subject/model).
      2. REFERENCE - fetches that player's avatar as a real PNG and decodes it to pixels.
      3. DRAW    - reproduces the reference on the drawing canvas, pixel by pixel,
                   snapping each pixel to the closest colour the canvas palette allows.

    Why this is a standalone script instead of an edit of the pastebin one:
      The public "DRAW ME AUTO DRAW SCRIPT" is fully obfuscated with Luraph v14.7, so
      its internals cannot be modified. This file re-implements the auto-draw loop from
      scratch and adds the "reference the on-stage player" behaviour on top.

    IMPORTANT - one thing you must confirm against the live game:
      Every drawing game exposes its canvas differently (a grid of Frames, a set of
      buttons, or a RemoteEvent that takes an x,y,colour). This script auto-detects the
      most common layouts, but if auto-detect fails, fill in the CONFIG.Canvas section
      below. Use the RemoteDumper.lua / GameCodeDumper.lua tools in this repo to find the
      exact draw remote or GUI path for the current version of the game.

    Load it with:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/user_scripts/drawme_autodraw.lua"))()
--]]

-- ============================================================================
--  CONFIG
-- ============================================================================
local CONFIG = {
    -- Which player to reference. "auto" = detect the on-stage subject automatically.
    -- Or put an exact username here to force a specific target.
    Target = "auto",

    -- Reference image.
    ThumbnailType = "bust",   -- "bust" | "headshot" | "fullbody"
    SourceSize    = 180,      -- px of the avatar image we download before downscaling.

    -- How finely we redraw. The reference is downscaled to this many pixels across.
    -- Higher = more detail but slower and more strokes.
    DrawResolution = 48,

    -- Skip near-transparent / background pixels so we don't paint the whole square.
    AlphaThreshold = 40,      -- 0..255; pixels below this alpha are left blank.

    -- Pacing. Executors get kicked if they fire the canvas too fast.
    PixelsPerBatch = 24,      -- strokes sent before yielding.
    BatchDelay     = 0.03,    -- seconds between batches.

    -- Canvas description. Leave as nil to auto-detect. Fill in if auto-detect fails.
    Canvas = {
        -- MODE 1 (grid GUI): a ScreenGui full of Frames, one per pixel.
        --   gridContainer = <Instance path to the frame that holds the pixel cells>
        --   The cells are read left->right, top->bottom by AbsolutePosition.
        gridContainer = nil,

        -- MODE 2 (remote): a RemoteEvent the game fires to paint one cell.
        --   remote = <RemoteEvent>, and drawArgs(x,y,color3) returns the arg list.
        remote = nil,
        drawArgs = nil,

        -- Colour palette the canvas supports (Color3 list). nil = full colour, no snap.
        palette = nil,
    },

    Keybind = Enum.KeyCode.F,  -- press to (re)start an auto-draw pass.
}

-- ============================================================================
--  SERVICES
-- ============================================================================
local Players         = game:GetService("Players")
local Workspace       = game:GetService("Workspace")
local UserInputService= game:GetService("UserInputService")
local LocalPlayer     = Players.LocalPlayer

local function notify(msg)
    print("[DrawMe] " .. tostring(msg))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Draw Me! Auto-Draw", Text = tostring(msg), Duration = 4,
        })
    end)
end

-- ============================================================================
--  STEP 1 : LOOK — find the player currently on the stage
-- ============================================================================
-- Draw Me! puts the round's subject on a stage/podium and usually names them in the
-- round UI ("Draw <name>!"). We try, in order:
--   a) an explicit CONFIG.Target username,
--   b) a name pulled out of the round GUI text,
--   c) the player standing closest to a part called "Stage"/"Podium"/"Pedestal",
--   d) fallback: nearest OTHER player to us.
local STAGE_KEYWORDS = { "stage", "podium", "pedestal", "spotlight", "model", "subject" }

local function findStagePart()
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            local n = inst.Name:lower()
            for _, kw in ipairs(STAGE_KEYWORDS) do
                if n:find(kw) then return inst end
            end
        end
    end
    return nil
end

local function nameFromRoundGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, t in ipairs(pg:GetDescendants()) do
        if t:IsA("TextLabel") or t:IsA("TextButton") then
            local txt = t.Text or ""
            -- Match "Draw <Name>", "Drawing <Name>", "<Name>'s turn", etc.
            local cand = txt:match("[Dd]raw%s*i?n?g?%s*[:!]?%s*([%w_]+)")
                      or txt:match("([%w_]+)'?s?%s+turn")
            if cand and #cand >= 3 and Players:FindFirstChild(cand) then
                return cand
            end
        end
    end
    return nil
end

local function playerRoot(plr)
    local ch = plr.Character
    return ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
end

local function nearestPlayerTo(pos, excludeSelf)
    local best, bestD
    for _, plr in ipairs(Players:GetPlayers()) do
        if not (excludeSelf and plr == LocalPlayer) then
            local root = playerRoot(plr)
            if root then
                local d = (root.Position - pos).Magnitude
                if not bestD or d < bestD then best, bestD = plr, d end
            end
        end
    end
    return best
end

local function findStagePlayer()
    -- (a) explicit override
    if CONFIG.Target and CONFIG.Target ~= "auto" then
        local p = Players:FindFirstChild(CONFIG.Target)
        if p then return p, "config" end
        notify("Target '" .. CONFIG.Target .. "' not in server; falling back to auto.")
    end

    -- (b) round GUI text
    local nm = nameFromRoundGui()
    if nm then return Players[nm], "round-ui" end

    -- (c) closest player to a stage part
    local stage = findStagePart()
    if stage then
        local p = nearestPlayerTo(stage.Position, true)
        if p then return p, "stage-part" end
    end

    -- (d) fallback: nearest other player to us
    local myRoot = playerRoot(LocalPlayer)
    if myRoot then
        local p = nearestPlayerTo(myRoot.Position, true)
        if p then return p, "nearest" end
    end
    return nil
end

-- ============================================================================
--  STEP 2 : REFERENCE — download the avatar PNG and decode it to pixels
-- ============================================================================
-- Minimal, self-contained PNG reader: zlib/DEFLATE inflate + PNG chunk parse.
-- Supports 8-bit colour types 0 (grey), 2 (RGB), 3 (palette), 4 (grey+A), 6 (RGBA).

local Inflate = {}
do
    -- Bit reader over a byte string.
    local function bitReader(data)
        local pos, bitbuf, bitcnt = 1, 0, 0
        return {
            bits = function(n)
                while bitcnt < n do
                    bitbuf = bitbuf + (string.byte(data, pos) or 0) * 2 ^ bitcnt
                    pos = pos + 1
                    bitcnt = bitcnt + 8
                end
                local v = bitbuf % (2 ^ n)
                bitbuf = math.floor(bitbuf / (2 ^ n))
                bitcnt = bitcnt - n
                return v
            end,
            align = function() bitbuf, bitcnt = 0, 0 end,
            byte  = function() local b = string.byte(data, pos) or 0; pos = pos + 1; return b end,
            skip  = function(n) pos = pos + n end,
        }
    end

    -- Build a canonical Huffman decoder from a list of code lengths.
    local function buildHuff(lengths)
        local maxbits = 0
        for _, l in ipairs(lengths) do if l > maxbits then maxbits = l end end
        local blCount = {}
        for i = 0, maxbits do blCount[i] = 0 end
        for _, l in ipairs(lengths) do if l > 0 then blCount[l] = blCount[l] + 1 end end
        local nextCode, code = {}, 0
        for bits = 1, maxbits do
            code = (code + blCount[bits - 1]) * 2
            nextCode[bits] = code
        end
        local codes = {}
        for sym = 1, #lengths do
            local l = lengths[sym]
            if l > 0 then
                codes[l .. ":" .. nextCode[l]] = sym - 1
                nextCode[l] = nextCode[l] + 1
            end
        end
        return { codes = codes, maxbits = maxbits }
    end

    local function decodeSym(br, huff)
        local code, len = 0, 0
        while len < huff.maxbits do
            code = code * 2 + br.bits(1)
            len = len + 1
            local sym = huff.codes[len .. ":" .. code]
            if sym then return sym end
        end
        error("bad huffman symbol")
    end

    local LEN_BASE = {3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}
    local LEN_EXTRA= {0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
    local DIST_BASE= {1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577}
    local DIST_EXTRA={0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}

    function Inflate.decompress(data)
        -- Skip 2-byte zlib header.
        local br = bitReader(data:sub(3))
        local out = {}
        repeat
            local final = br.bits(1)
            local btype = br.bits(2)
            if btype == 0 then
                br.align()
                local len = br.byte() + br.byte() * 256
                br.byte(); br.byte() -- NLEN
                for _ = 1, len do out[#out + 1] = string.char(br.byte()) end
            else
                local litHuff, distHuff
                if btype == 1 then
                    local ll = {}
                    for i = 1, 144 do ll[i] = 8 end
                    for i = 145, 256 do ll[i] = 9 end
                    for i = 257, 280 do ll[i] = 7 end
                    for i = 281, 288 do ll[i] = 8 end
                    litHuff = buildHuff(ll)
                    local dl = {}; for i = 1, 30 do dl[i] = 5 end
                    distHuff = buildHuff(dl)
                else
                    local hlit  = br.bits(5) + 257
                    local hdist = br.bits(5) + 1
                    local hclen = br.bits(4) + 4
                    local order = {17,18,19,1,9,8,10,7,11,6,12,5,13,4,14,3,15,2,16}
                    local clLen = {}; for i = 1, 19 do clLen[i] = 0 end
                    for i = 1, hclen do clLen[order[i]] = br.bits(3) end
                    local clHuff = buildHuff(clLen)
                    local all = {}
                    while #all < hlit + hdist do
                        local sym = decodeSym(br, clHuff)
                        if sym < 16 then
                            all[#all + 1] = sym
                        elseif sym == 16 then
                            local r = br.bits(2) + 3
                            for _ = 1, r do all[#all + 1] = all[#all] end
                        elseif sym == 17 then
                            local r = br.bits(3) + 3
                            for _ = 1, r do all[#all + 1] = 0 end
                        else
                            local r = br.bits(7) + 11
                            for _ = 1, r do all[#all + 1] = 0 end
                        end
                    end
                    local ll, dl = {}, {}
                    for i = 1, hlit do ll[i] = all[i] end
                    for i = 1, hdist do dl[i] = all[hlit + i] end
                    litHuff = buildHuff(ll)
                    distHuff = buildHuff(dl)
                end

                while true do
                    local sym = decodeSym(br, litHuff)
                    if sym == 256 then break
                    elseif sym < 256 then
                        out[#out + 1] = string.char(sym)
                    else
                        local li = sym - 256
                        local length = LEN_BASE[li] + br.bits(LEN_EXTRA[li])
                        local dsym = decodeSym(br, distHuff)
                        local dist = DIST_BASE[dsym + 1] + br.bits(DIST_EXTRA[dsym + 1])
                        local start = #out - dist + 1
                        for i = 0, length - 1 do
                            out[#out + 1] = out[start + i]
                        end
                    end
                end
            end
        until final == 1
        return table.concat(out)
    end
end

-- Parse a PNG byte string into { w, h, get(x,y)->r,g,b,a }.
local function decodePNG(bytes)
    assert(bytes:sub(1, 8) == "\137PNG\r\n\26\10", "not a PNG (avatar host may have returned HTML/JPEG)")
    local pos = 9
    local function u32() local a,b,c,d = bytes:byte(pos, pos+3); pos = pos + 4; return ((a*256+b)*256+c)*256+d end

    local width, height, bitDepth, colorType
    local idat, palette, trns = {}, nil, nil
    while pos <= #bytes do
        local length = u32()
        local ctype = bytes:sub(pos, pos + 3); pos = pos + 4
        local cdata = bytes:sub(pos, pos + length - 1); pos = pos + length + 4 -- +4 skips CRC
        if ctype == "IHDR" then
            width  = ((cdata:byte(1)*256+cdata:byte(2))*256+cdata:byte(3))*256+cdata:byte(4)
            height = ((cdata:byte(5)*256+cdata:byte(6))*256+cdata:byte(7))*256+cdata:byte(8)
            bitDepth  = cdata:byte(9)
            colorType = cdata:byte(10)
        elseif ctype == "PLTE" then
            palette = cdata
        elseif ctype == "tRNS" then
            trns = cdata
        elseif ctype == "IDAT" then
            idat[#idat + 1] = cdata
        elseif ctype == "IEND" then
            break
        end
    end
    assert(bitDepth == 8, "unsupported PNG bit depth: " .. tostring(bitDepth))

    local channels = ({[0]=1,[2]=3,[3]=1,[4]=2,[6]=4})[colorType]
    assert(channels, "unsupported PNG colour type: " .. tostring(colorType))

    local raw = Inflate.decompress(table.concat(idat))
    local stride = width * channels
    local prev = string.rep("\0", stride)
    local rows, rp = {}, 1
    local function paeth(a, b, c)
        local p = a + b - c
        local pa, pb, pc = math.abs(p-a), math.abs(p-b), math.abs(p-c)
        if pa <= pb and pa <= pc then return a elseif pb <= pc then return b else return c end
    end
    for _ = 1, height do
        local filter = raw:byte(rp); rp = rp + 1
        local cur = { raw:byte(rp, rp + stride - 1) }; rp = rp + stride
        local pv = { prev:byte(1, stride) }
        for i = 1, stride do
            local x = cur[i]
            local a = (i > channels) and cur[i - channels] or 0
            local b = pv[i] or 0
            local c = (i > channels) and (pv[i - channels] or 0) or 0
            if filter == 1 then x = (x + a) % 256
            elseif filter == 2 then x = (x + b) % 256
            elseif filter == 3 then x = (x + math.floor((a + b) / 2)) % 256
            elseif filter == 4 then x = (x + paeth(a, b, c)) % 256 end
            cur[i] = x
        end
        rows[#rows + 1] = cur
        prev = string.char(unpack(cur))
    end

    local function get(x, y) -- 0-indexed
        local row = rows[y + 1]
        if not row then return 0,0,0,0 end
        local base = x * channels
        if colorType == 2 then       -- RGB
            return row[base+1], row[base+2], row[base+3], 255
        elseif colorType == 6 then   -- RGBA
            return row[base+1], row[base+2], row[base+3], row[base+4]
        elseif colorType == 0 then   -- grey
            local g = row[base+1]; return g, g, g, 255
        elseif colorType == 4 then   -- grey + alpha
            local g = row[base+1]; return g, g, g, row[base+2]
        elseif colorType == 3 then   -- palette
            local idx = row[base+1]
            local pr = palette:byte(idx*3+1) or 0
            local pg = palette:byte(idx*3+2) or 0
            local pb = palette:byte(idx*3+3) or 0
            local pa = trns and (trns:byte(idx+1) or 255) or 255
            return pr, pg, pb, pa
        end
        return 0,0,0,0
    end

    return { w = width, h = height, get = get }
end

local function avatarPngUrl(userId)
    -- Roblox thumbnail render endpoints return PNGs.
    local sz = CONFIG.SourceSize .. "x" .. CONFIG.SourceSize
    if CONFIG.ThumbnailType == "headshot" then
        return ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=%d&height=%d&format=png")
            :format(userId, CONFIG.SourceSize, CONFIG.SourceSize)
    elseif CONFIG.ThumbnailType == "fullbody" then
        return ("https://www.roblox.com/avatar-thumbnail/image?userId=%d&width=%d&height=%d&format=png")
            :format(userId, CONFIG.SourceSize, CONFIG.SourceSize)
    else -- bust
        return ("https://www.roblox.com/bust-thumbnail/image?userId=%d&width=%d&height=%d&format=png")
            :format(userId, CONFIG.SourceSize, CONFIG.SourceSize)
    end
end

local function captureReference(targetPlayer)
    local url = avatarPngUrl(targetPlayer.UserId)
    local ok, bytes = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not bytes or #bytes < 100 then
        error("could not download avatar image for " .. targetPlayer.Name)
    end
    return decodePNG(bytes)
end

-- ============================================================================
--  CANVAS DRIVER — auto-detect the game's drawing surface
-- ============================================================================
local Canvas = {}
do
    local cells        -- MODE 1: sorted list of {frame, x, y}
    local cols, rows_  -- grid dimensions
    local remote, argsFn

    local function autodetectGrid()
        -- Look for a container holding many equally-sized Frames (the pixel cells).
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return false end
        local bestContainer, bestCount
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("GuiObject") then
                local n = 0
                for _, ch in ipairs(gui:GetChildren()) do
                    if ch:IsA("Frame") or ch:IsA("ImageButton") or ch:IsA("TextButton") then n = n + 1 end
                end
                if n >= 64 and (not bestCount or n > bestCount) then
                    bestCount, bestContainer = n, gui
                end
            end
        end
        if not bestContainer then return false end

        cells = {}
        for _, ch in ipairs(bestContainer:GetChildren()) do
            if ch:IsA("GuiObject") then
                cells[#cells + 1] = ch
            end
        end
        table.sort(cells, function(a, b)
            local ay, by = a.AbsolutePosition.Y, b.AbsolutePosition.Y
            if math.abs(ay - by) > 4 then return ay < by end
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end)
        cols = 0
        local firstY = cells[1].AbsolutePosition.Y
        for _, c in ipairs(cells) do
            if math.abs(c.AbsolutePosition.Y - firstY) <= 4 then cols = cols + 1 else break end
        end
        rows_ = math.floor(#cells / math.max(cols, 1))
        return cols > 0
    end

    function Canvas.init()
        if CONFIG.Canvas.remote then
            remote = CONFIG.Canvas.remote
            argsFn = CONFIG.Canvas.drawArgs or function(x, y, c) return x, y, c end
            return true, "remote (config)"
        end
        if CONFIG.Canvas.gridContainer then
            cells = {}
            for _, ch in ipairs(CONFIG.Canvas.gridContainer:GetChildren()) do
                if ch:IsA("GuiObject") then cells[#cells + 1] = ch end
            end
            table.sort(cells, function(a, b)
                local ay, by = a.AbsolutePosition.Y, b.AbsolutePosition.Y
                if math.abs(ay - by) > 4 then return ay < by end
                return a.AbsolutePosition.X < b.AbsolutePosition.X
            end)
            local firstY = cells[1].AbsolutePosition.Y
            cols = 0
            for _, c in ipairs(cells) do
                if math.abs(c.AbsolutePosition.Y - firstY) <= 4 then cols = cols + 1 else break end
            end
            rows_ = math.floor(#cells / math.max(cols, 1))
            return true, "grid (config)"
        end
        if autodetectGrid() then
            return true, ("grid (auto: %dx%d cells)"):format(cols, rows_)
        end
        return false, "no canvas found"
    end

    function Canvas.size()
        if cols and rows_ then return cols, rows_ end
        return CONFIG.DrawResolution, CONFIG.DrawResolution
    end

    -- Paint one canvas cell (gx, gy are 0-indexed grid coords) with Color3 c.
    function Canvas.paint(gx, gy, c)
        if remote then
            remote:FireServer(argsFn(gx, gy, c))
        elseif cells then
            local idx = gy * cols + gx + 1
            local cell = cells[idx]
            if cell then
                cell.BackgroundColor3 = c
                pcall(function() cell.BackgroundTransparency = 0 end)
            end
        end
    end
end

-- ============================================================================
--  PALETTE SNAPPING
-- ============================================================================
local function snapColor(r, g, b)
    local pal = CONFIG.Canvas.palette
    if not pal then return Color3.fromRGB(r, g, b) end
    local best, bestD
    for _, col in ipairs(pal) do
        local dr, dg, db = col.R*255 - r, col.G*255 - g, col.B*255 - b
        local d = dr*dr + dg*dg + db*db
        if not bestD or d < bestD then bestD, best = d, col end
    end
    return best
end

-- ============================================================================
--  STEP 3 : DRAW — map reference -> canvas and paint it
-- ============================================================================
local drawing = false

local function drawReference(image)
    local cw, ch = Canvas.size()
    local res = math.min(CONFIG.DrawResolution, cw, ch)
    notify(("Drawing %dx%d onto %dx%d canvas..."):format(res, res, cw, ch))

    local painted = 0
    for gy = 0, res - 1 do
        for gx = 0, res - 1 do
            if not drawing then return end
            -- Nearest-neighbour sample from source image.
            local sx = math.floor((gx + 0.5) / res * image.w)
            local sy = math.floor((gy + 0.5) / res * image.h)
            local r, g, b, a = image.get(sx, sy)
            if a >= CONFIG.AlphaThreshold then
                Canvas.paint(gx, gy, snapColor(r, g, b))
                painted = painted + 1
                if painted % CONFIG.PixelsPerBatch == 0 then
                    task.wait(CONFIG.BatchDelay)
                end
            end
        end
    end
    notify(("Done — painted %d pixels."):format(painted))
end

-- ============================================================================
--  ORCHESTRATION
-- ============================================================================
local function run()
    if drawing then drawing = false; notify("Stopped."); return end
    drawing = true

    -- 1. LOOK
    local target, how = findStagePlayer()
    if not target then drawing = false; return notify("Could not find a player on stage.") end
    notify(("Referencing %s (via %s)"):format(target.Name, how))

    -- init canvas
    local ok, info = Canvas.init()
    if not ok then
        drawing = false
        return notify("Canvas not found (" .. info .. "). Fill CONFIG.Canvas — see RemoteDumper.lua.")
    end
    notify("Canvas: " .. info)

    -- 2. REFERENCE
    local okRef, image = pcall(captureReference, target)
    if not okRef then drawing = false; return notify("Reference failed: " .. tostring(image)) end
    notify(("Reference ready: %dx%d px."):format(image.w, image.h))

    -- 3. DRAW
    drawReference(image)
    drawing = false
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.Keybind then run() end
end)

notify(("Loaded. Press %s to look at the stage player, reference them, and draw.")
    :format(CONFIG.Keybind.Name))
