--[[
    Draw Me! — Auto-Draw (reference the on-stage player, full-accuracy)
    ==================================================================

    Pipeline, in the order requested:
      1. LOOK      — read the player the round put on the stage (the subject to draw).
      2. REFERENCE — load that player's avatar into a pixel buffer.
      3. DRAW      — write those exact pixels into the drawing canvas, so the submitted
                     drawing is a 1:1 copy of the reference — no missed strokes.

    How it hooks the real game (place 80898524797320, module `Gold`):
      The canvas is a `Gold.Shared.DrawingCanvas3` instance. Each layer is a Luau
      EditableImage. On submit the game does:
          ReadPixelsBuffer(Canvas.Internal.RenderEditableImage)  -> networked to server.
      RenderEditableImage is recomposited from the visible layers by
      Canvas:UpdateRenderImage(). So the accurate path is:
          write our reference buffer into the ACTIVE LAYER's EditableImage,
          then Canvas:UpdateRenderImage(true)  (synchronous recomposite).
      After that, hitting the game's own Submit button sends our exact image.

      The on-stage subject is authoritative in the client context:
          require(game.ReplicatedFirst.Gold).Shared.Mana().get("ClientContext"):Get().PlayerToDrawUserId

    Requirements: an executor exposing `getgc(true)` (Synapse/Script-Ware/etc.) and the
    Luau `buffer` library (standard). Everything else uses in-game APIs.

    Load it:
      loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/user_scripts/drawme_autodraw.lua"))()
--]]

-- ============================================================================
--  CONFIG
-- ============================================================================
local CONFIG = {
    -- Who to draw. "auto" = the player the round put on the stage.
    -- Or a username, or a numeric UserId.
    Target = "auto",

    -- Reference source.
    ThumbnailType = "bust",  -- "bust" | "headshot" | "fullbody"
    ThumbnailSize = 420,     -- 100 | 150 | 180 | 352 | 420 (avatar render resolution)

    -- Framing: crop to the avatar's non-transparent bounding box and scale it to fill
    -- the canvas, so "draw them" fills the sheet instead of leaving huge margins.
    AutoCrop = true,
    AlphaThreshold = 20,     -- 0..255; source pixels below this count as background.
    Background = Color3.fromRGB(255, 255, 255), -- what transparent areas become.

    -- After drawing, automatically press the game's Submit button.
    AutoSubmit = false,

    Keybind = Enum.KeyCode.F,   -- press to run the whole pipeline.
}

-- ============================================================================
--  SERVICES / HELPERS
-- ============================================================================
local Players          = game:GetService("Players")
local AssetService     = game:GetService("AssetService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local statusSink -- set by the UI; receives every status message.
local function notify(msg)
    print("[DrawMe] " .. tostring(msg))
    if statusSink then pcall(statusSink, tostring(msg)) end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Draw Me! Auto-Draw", Text = tostring(msg), Duration = 4,
        })
    end)
end

-- Lazy handle to the game's Gold framework (required once).
local Gold
local function getGold()
    if Gold == nil then
        local ok, mod = pcall(function() return require(game.ReplicatedFirst.Gold) end)
        Gold = ok and mod or false
    end
    return Gold or nil
end

-- ============================================================================
--  STEP 1 : LOOK — resolve the player on the stage
-- ============================================================================
local function subjectFromClientContext()
    local g = getGold()
    if not g then return nil end
    local ok, ctx = pcall(function() return g.Shared.Mana().get("ClientContext"):Get() end)
    if not ok or type(ctx) ~= "table" then return nil end
    if ctx.PlayerToDrawUserId then
        return ctx.PlayerToDrawUserId, ctx.PlayerToDrawName or ("user " .. tostring(ctx.PlayerToDrawUserId))
    end
    if typeof(ctx.PlayerToDraw) == "Instance" and ctx.PlayerToDraw:IsA("Player") then
        return ctx.PlayerToDraw.UserId, ctx.PlayerToDraw.Name
    end
    return nil
end

local function subjectFromCamera()
    -- During the drawing phase the game points CurrentCamera at the subject's character.
    local subj = workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject
    if subj then
        local model = subj:IsA("Humanoid") and subj.Parent or subj:FindFirstAncestorOfClass("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            if plr and plr ~= LocalPlayer then return plr.UserId, plr.Name end
        end
    end
    return nil
end

local function resolveTarget()
    -- explicit override
    if CONFIG.Target ~= "auto" then
        if tonumber(CONFIG.Target) then
            local id = tonumber(CONFIG.Target)
            local ok, nm = pcall(function() return Players:GetNameFromUserIdAsync(id) end)
            return id, ok and nm or ("user " .. id)
        end
        local p = Players:FindFirstChild(CONFIG.Target)
        if p then return p.UserId, p.Name end
        notify("Target '" .. tostring(CONFIG.Target) .. "' not in server; using auto.")
    end
    -- auto: client context first, then camera subject
    local id, nm = subjectFromClientContext()
    if id then return id, nm, "client-context" end
    id, nm = subjectFromCamera()
    if id then return id, nm, "camera-subject" end
    return nil
end

-- ============================================================================
--  STEP 2 : REFERENCE — load the avatar into a pixel source {w, h, data:buffer}
-- ============================================================================
-- Source pixels are RGBA, row-major, 4 bytes/pixel (matches EditableImage buffers).

local function thumbTypeEnum()
    if CONFIG.ThumbnailType == "headshot" then return Enum.ThumbnailType.HeadShot
    elseif CONFIG.ThumbnailType == "fullbody" then return Enum.ThumbnailType.AvatarThumbnail
    else return Enum.ThumbnailType.AvatarBust end
end

local function thumbSizeEnum()
    local m = {
        [100] = Enum.ThumbnailSize.Size100x100,
        [150] = Enum.ThumbnailSize.Size150x150,
        [180] = Enum.ThumbnailSize.Size180x180,
        [352] = Enum.ThumbnailSize.Size352x352,
        [420] = Enum.ThumbnailSize.Size420x420,
    }
    return m[CONFIG.ThumbnailSize] or Enum.ThumbnailSize.Size420x420
end

-- Path A: native — turn the avatar thumbnail into an EditableImage and read it.
local function referenceNative(userId)
    local content = select(1, Players:GetUserThumbnailAsync(userId, thumbTypeEnum(), thumbSizeEnum()))
    if not content then return nil end
    local img
    -- API has shifted over releases; try the known constructors.
    for _, attempt in ipairs({
        function() return AssetService:CreateEditableImageAsync(Content.fromUri(content)) end,
        function() return AssetService:CreateEditableImageAsync(content) end,
    }) do
        local ok, res = pcall(attempt)
        if ok and res then img = res; break end
    end
    if not img then return nil end
    local size = img.Size
    local okBuf, buf = pcall(function() return img:ReadPixelsBuffer(Vector2.zero, size) end)
    pcall(function() img:Destroy() end)
    if not okBuf or not buf then return nil end
    return { w = math.floor(size.X), h = math.floor(size.Y), data = buf }
end

-- Path B: fallback — download the avatar PNG and decode it in pure Lua.
--   (Self-contained DEFLATE + PNG reader; no external dependencies.)
local decodePNG do
    local function bitReader(data)
        local pos, bitbuf, bitcnt = 1, 0, 0
        return {
            bits = function(n)
                while bitcnt < n do
                    bitbuf = bitbuf + (string.byte(data, pos) or 0) * 2 ^ bitcnt
                    pos = pos + 1; bitcnt = bitcnt + 8
                end
                local v = bitbuf % (2 ^ n)
                bitbuf = math.floor(bitbuf / (2 ^ n)); bitcnt = bitcnt - n
                return v
            end,
            align = function() bitbuf, bitcnt = 0, 0 end,
            byte  = function() local b = string.byte(data, pos) or 0; pos = pos + 1; return b end,
        }
    end
    local function buildHuff(lengths)
        local maxbits = 0
        for _, l in ipairs(lengths) do if l > maxbits then maxbits = l end end
        local blCount = {}; for i = 0, maxbits do blCount[i] = 0 end
        for _, l in ipairs(lengths) do if l > 0 then blCount[l] = blCount[l] + 1 end end
        local nextCode, code = {}, 0
        for bits = 1, maxbits do code = (code + blCount[bits - 1]) * 2; nextCode[bits] = code end
        local codes = {}
        for sym = 1, #lengths do
            local l = lengths[sym]
            if l > 0 then codes[l .. ":" .. nextCode[l]] = sym - 1; nextCode[l] = nextCode[l] + 1 end
        end
        return { codes = codes, maxbits = maxbits }
    end
    local function decodeSym(br, huff)
        local code, len = 0, 0
        while len < huff.maxbits do
            code = code * 2 + br.bits(1); len = len + 1
            local sym = huff.codes[len .. ":" .. code]
            if sym then return sym end
        end
        error("bad huffman symbol")
    end
    local LB={3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}
    local LE={0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
    local DB={1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577}
    local DE={0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}
    local function inflate(data)
        local br = bitReader(data:sub(3)) -- skip zlib header
        local out = {}
        repeat
            local final = br.bits(1); local btype = br.bits(2)
            if btype == 0 then
                br.align()
                local len = br.byte() + br.byte() * 256; br.byte(); br.byte()
                for _ = 1, len do out[#out + 1] = string.char(br.byte()) end
            else
                local litHuff, distHuff
                if btype == 1 then
                    local ll = {}
                    for i=1,144 do ll[i]=8 end for i=145,256 do ll[i]=9 end
                    for i=257,280 do ll[i]=7 end for i=281,288 do ll[i]=8 end
                    litHuff = buildHuff(ll)
                    local dl = {}; for i=1,30 do dl[i]=5 end; distHuff = buildHuff(dl)
                else
                    local hlit=br.bits(5)+257; local hdist=br.bits(5)+1; local hclen=br.bits(4)+4
                    local order={17,18,19,1,9,8,10,7,11,6,12,5,13,4,14,3,15,2,16}
                    local clLen={}; for i=1,19 do clLen[i]=0 end
                    for i=1,hclen do clLen[order[i]]=br.bits(3) end
                    local clHuff=buildHuff(clLen); local all={}
                    while #all < hlit+hdist do
                        local sym=decodeSym(br,clHuff)
                        if sym<16 then all[#all+1]=sym
                        elseif sym==16 then local r=br.bits(2)+3; for _=1,r do all[#all+1]=all[#all] end
                        elseif sym==17 then local r=br.bits(3)+3; for _=1,r do all[#all+1]=0 end
                        else local r=br.bits(7)+11; for _=1,r do all[#all+1]=0 end end
                    end
                    local ll,dl={},{}
                    for i=1,hlit do ll[i]=all[i] end
                    for i=1,hdist do dl[i]=all[hlit+i] end
                    litHuff=buildHuff(ll); distHuff=buildHuff(dl)
                end
                while true do
                    local sym=decodeSym(br,litHuff)
                    if sym==256 then break
                    elseif sym<256 then out[#out+1]=string.char(sym)
                    else
                        local li=sym-256; local length=LB[li]+br.bits(LE[li])
                        local ds=decodeSym(br,distHuff); local dist=DB[ds+1]+br.bits(DE[ds+1])
                        local start=#out-dist+1
                        for i=0,length-1 do out[#out+1]=out[start+i] end
                    end
                end
            end
        until final == 1
        return table.concat(out)
    end
    function decodePNG(bytes)
        assert(bytes:sub(1,8) == "\137PNG\r\n\26\10", "not a PNG")
        local pos=9
        local function u32() local a,b,c,d=bytes:byte(pos,pos+3); pos=pos+4; return ((a*256+b)*256+c)*256+d end
        local width,height,colorType,palette,trns,idat=nil,nil,nil,nil,nil,{}
        while pos<=#bytes do
            local length=u32(); local ctype=bytes:sub(pos,pos+3); pos=pos+4
            local cdata=bytes:sub(pos,pos+length-1); pos=pos+length+4
            if ctype=="IHDR" then
                width =((cdata:byte(1)*256+cdata:byte(2))*256+cdata:byte(3))*256+cdata:byte(4)
                height=((cdata:byte(5)*256+cdata:byte(6))*256+cdata:byte(7))*256+cdata:byte(8)
                assert(cdata:byte(9)==8,"only 8-bit PNG supported")
                colorType=cdata:byte(10)
            elseif ctype=="PLTE" then palette=cdata
            elseif ctype=="tRNS" then trns=cdata
            elseif ctype=="IDAT" then idat[#idat+1]=cdata
            elseif ctype=="IEND" then break end
        end
        local channels=({[0]=1,[2]=3,[3]=1,[4]=2,[6]=4})[colorType]
        assert(channels,"unsupported colour type")
        local raw=inflate(table.concat(idat))
        local stride=width*channels
        local out=buffer.create(width*height*4)
        local prev={}; for i=1,stride do prev[i]=0 end
        local rp=1
        local function paeth(a,b,c) local p=a+b-c; local pa,pb,pc=math.abs(p-a),math.abs(p-b),math.abs(p-c)
            if pa<=pb and pa<=pc then return a elseif pb<=pc then return b else return c end end
        for y=0,height-1 do
            local filter=raw:byte(rp); rp=rp+1
            local cur={raw:byte(rp,rp+stride-1)}; rp=rp+stride
            for i=1,stride do
                local x=cur[i] or 0
                local a=(i>channels) and cur[i-channels] or 0
                local b=prev[i] or 0
                local c=(i>channels) and (prev[i-channels] or 0) or 0
                if filter==1 then x=(x+a)%256
                elseif filter==2 then x=(x+b)%256
                elseif filter==3 then x=(x+math.floor((a+b)/2))%256
                elseif filter==4 then x=(x+paeth(a,b,c))%256 end
                cur[i]=x
            end
            for xx=0,width-1 do
                local base=xx*channels; local o=(y*width+xx)*4
                local r,g,bl,al
                if colorType==2 then r,g,bl,al=cur[base+1],cur[base+2],cur[base+3],255
                elseif colorType==6 then r,g,bl,al=cur[base+1],cur[base+2],cur[base+3],cur[base+4]
                elseif colorType==0 then local gg=cur[base+1]; r,g,bl,al=gg,gg,gg,255
                elseif colorType==4 then local gg=cur[base+1]; r,g,bl,al=gg,gg,gg,cur[base+2]
                else local idx=cur[base+1]
                    r=palette:byte(idx*3+1) or 0; g=palette:byte(idx*3+2) or 0; bl=palette:byte(idx*3+3) or 0
                    al=trns and (trns:byte(idx+1) or 255) or 255 end
                buffer.writeu8(out,o,r); buffer.writeu8(out,o+1,g)
                buffer.writeu8(out,o+2,bl); buffer.writeu8(out,o+3,al)
            end
            prev=cur
        end
        return { w=width, h=height, data=out }
    end
end

local function referencePNG(userId)
    local sz = CONFIG.ThumbnailSize
    local kind = ({ headshot="headshot-thumbnail", fullbody="avatar-thumbnail" })[CONFIG.ThumbnailType] or "bust-thumbnail"
    local url = ("https://www.roblox.com/%s/image?userId=%d&width=%d&height=%d&format=png"):format(kind, userId, sz, sz)
    local ok, bytes = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not bytes or #bytes < 100 then return nil end
    local okDec, img = pcall(decodePNG, bytes)
    return okDec and img or nil
end

local function captureReference(userId)
    return referenceNative(userId) or referencePNG(userId)
        or error("could not load an avatar reference for userId " .. tostring(userId))
end

-- ============================================================================
--  STEP 3a : find the live DrawingCanvas3 instance
-- ============================================================================
local function findCanvas()
    if type(getgc) ~= "function" then
        error("this executor does not expose getgc(true); cannot reach the canvas.")
    end
    for _, o in ipairs(getgc(true)) do
        if type(o) == "table" then
            local internal = rawget(o, "Internal")
            local layers   = rawget(o, "Layers")
            if type(internal) == "table" and type(layers) == "table"
               and rawget(internal, "RenderEditableImage") ~= nil
               and type(rawget(layers, "List")) == "table" then
                return o
            end
        end
    end
    error("live drawing canvas not found — join a round and open the drawing screen first.")
end

-- ============================================================================
--  STEP 3b : sampling + scaling the reference into the canvas buffer
-- ============================================================================
local function alphaBBox(src)
    if not CONFIG.AutoCrop then return 0, 0, src.w - 1, src.h - 1 end
    local minx, miny, maxx, maxy = src.w, src.h, -1, -1
    for y = 0, src.h - 1 do
        for x = 0, src.w - 1 do
            local a = buffer.readu8(src.data, (y * src.w + x) * 4 + 3)
            if a >= CONFIG.AlphaThreshold then
                if x < minx then minx = x end
                if x > maxx then maxx = x end
                if y < miny then miny = y end
                if y > maxy then maxy = y end
            end
        end
    end
    if maxx < 0 then return 0, 0, src.w - 1, src.h - 1 end -- fully transparent; use whole image
    return minx, miny, maxx, maxy
end

-- Build a destination RGBA buffer of size (dw x dh), scaling the (cropped) source to
-- fill it while preserving aspect ratio; transparent source -> CONFIG.Background.
local function buildCanvasBuffer(src, dw, dh)
    local bx0, by0, bx1, by1 = alphaBBox(src)
    local bw, bh = (bx1 - bx0 + 1), (by1 - by0 + 1)
    local scale = math.min(dw / bw, dh / bh)             -- contain, keep aspect
    local offx = math.floor((dw - bw * scale) / 2)
    local offy = math.floor((dh - bh * scale) / 2)

    local bgR = math.floor(CONFIG.Background.R * 255 + 0.5)
    local bgG = math.floor(CONFIG.Background.G * 255 + 0.5)
    local bgB = math.floor(CONFIG.Background.B * 255 + 0.5)

    local dst = buffer.create(dw * dh * 4)
    for dy = 0, dh - 1 do
        for dx = 0, dw - 1 do
            local o = (dy * dw + dx) * 4
            local r, g, b = bgR, bgG, bgB
            -- inverse map dest -> source (nearest neighbour is exact and fast)
            local sxf = (dx - offx) / scale
            local syf = (dy - offy) / scale
            if sxf >= 0 and syf >= 0 and sxf < bw and syf < bh then
                local sx = bx0 + math.min(bw - 1, math.floor(sxf))
                local sy = by0 + math.min(bh - 1, math.floor(syf))
                local so = (sy * src.w + sx) * 4
                local a = buffer.readu8(src.data, so + 3)
                if a >= CONFIG.AlphaThreshold then
                    r = buffer.readu8(src.data, so)
                    g = buffer.readu8(src.data, so + 1)
                    b = buffer.readu8(src.data, so + 2)
                end
            end
            buffer.writeu8(dst, o, r); buffer.writeu8(dst, o + 1, g)
            buffer.writeu8(dst, o + 2, b); buffer.writeu8(dst, o + 3, 255)
        end
    end
    return dst
end

-- ============================================================================
--  STEP 3c : write into the active layer and recomposite
-- ============================================================================
local function drawOnCanvas(canvas, src)
    local layers = rawget(canvas, "Layers")
    local list   = rawget(layers, "List")
    local active = list[layers.ActiveLayerIndex or 1] or list[1]
    assert(active, "no active drawing layer")
    local layerImg = active.Internal.EditableImage
    local size = layerImg.Size
    local dw, dh = math.floor(size.X), math.floor(size.Y)

    notify(("Rendering %dx%d reference onto the canvas..."):format(dw, dh))
    local buf = buildCanvasBuffer(src, dw, dh)

    -- Write the whole layer in one call — every pixel, no missed strokes.
    layerImg:WritePixelsBuffer(Vector2.zero, size, buf)

    -- Force a synchronous recomposite so RenderEditableImage (what submit reads) updates.
    local ok = pcall(function() canvas:UpdateRenderImage(true) end)
    if not ok then pcall(function() canvas:UpdateRenderImage() end) end
end

-- ============================================================================
--  Optional: press the game's Submit button
-- ============================================================================
local function tryAutoSubmit()
    if not CONFIG.AutoSubmit then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, b in ipairs(pg:GetDescendants()) do
        if (b:IsA("TextButton") or b:IsA("ImageButton")) then
            local txt = (b:IsA("TextButton") and b.Text or "") .. " " .. b.Name
            if txt:lower():find("submit") and b.Visible then
                pcall(function() firesignal(b.Activated) end)
                pcall(function() firesignal(b.MouseButton1Click) end)
                notify("Auto-submit fired.")
                return
            end
        end
    end
    notify("Auto-submit: could not find the Submit button — submit manually.")
end

-- ============================================================================
--  ORCHESTRATION
-- ============================================================================
local busy = false
local function run()
    if busy then return end
    busy = true
    local ok, err = pcall(function()
        -- 1. LOOK
        local userId, name, how = resolveTarget()
        if not userId then error("no player is on the stage right now.") end
        notify(("Referencing %s (userId %d) via %s"):format(tostring(name), userId, how or "config"))

        -- 3a. locate canvas early so we fail fast if not in a drawing round
        local canvas = findCanvas()

        -- 2. REFERENCE
        local src = captureReference(userId)
        notify(("Reference loaded: %dx%d px."):format(src.w, src.h))

        -- 3. DRAW
        drawOnCanvas(canvas, src)
        notify("Done — canvas matches the reference. Hit Submit" ..
               (CONFIG.AutoSubmit and " (auto)." or " to send it."))
        tryAutoSubmit()
    end)
    if not ok then notify("Failed: " .. tostring(err)) end
    busy = false
end

-- ============================================================================
--  UI — mobile-first, touch control panel
-- ============================================================================
-- Built for phones/tablets: large touch targets, a collapsible floating button
-- so it never hogs a small screen, and touch dragging. Only shown on touch
-- devices (PC users have the keybind).
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function buildMobileUI()
    -- Mount to CoreGui/gethui when the executor allows it (survives respawns),
    -- otherwise fall back to PlayerGui.
    local parent = LocalPlayer:WaitForChild("PlayerGui")
    pcall(function()
        if gethui then parent = gethui() else parent = game:GetService("CoreGui") end
    end)

    local PINK  = Color3.fromRGB(255, 0, 81)
    local DARK  = Color3.fromRGB(24, 24, 30)
    local PANEL = Color3.fromRGB(40, 40, 50)
    local TEXT  = Color3.fromRGB(238, 238, 244)
    local MUTED = Color3.fromRGB(155, 155, 168)

    local function corner(inst, r)
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = inst
    end
    local function make(class, props, par)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        o.Parent = par
        return o
    end

    local gui = make("ScreenGui", {
        Name = "DrawMeAutoDraw", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999,
    }, parent)

    -- Floating open/close button (round, thumb-reachable, draggable).
    local fab = make("TextButton", {
        Name = "Fab", Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 18, 0.35, 0),
        BackgroundColor3 = PINK, BorderSizePixel = 0, AutoButtonColor = true,
        Text = "✏️", Font = Enum.Font.GothamBold, TextSize = 30, TextColor3 = Color3.new(1, 1, 1),
    }, gui)
    corner(fab, 32)
    make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0.6 }, fab)

    -- The panel window (hidden until the FAB is tapped).
    local win = make("Frame", {
        Name = "Window", Size = UDim2.fromOffset(300, 0), Position = UDim2.new(0, 18, 0.35, 74),
        BackgroundColor3 = DARK, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, gui)
    corner(win, 16)
    make("UIStroke", { Color = PINK, Thickness = 2, Transparency = 0.25 }, win)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
    }, win)
    make("UIListLayout", {
        Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, win)

    -- Title bar (drag handle) with a close "×".
    local titleBar = make("Frame", {
        Name = "TitleBar", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    }, win)
    make("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0), BackgroundTransparency = 1, Text = "✏️  Draw Me!",
        Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleBar)
    local closeBtn = make("TextButton", {
        Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -34, 0, 0),
        BackgroundColor3 = PANEL, BorderSizePixel = 0, AutoButtonColor = true,
        Text = "×", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = TEXT,
    }, titleBar)
    corner(closeBtn, 10)

    local function label(text, order)
        return make("TextLabel", {
            LayoutOrder = order, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
            Text = text, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, win)
    end

    -- Target input (large, touch-friendly).
    label("TARGET  (auto / username / userid)", 2)
    local box = make("TextBox", {
        LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = PANEL, BorderSizePixel = 0,
        Text = tostring(CONFIG.Target), PlaceholderText = "auto", ClearTextOnFocus = false,
        Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = TEXT,
    }, win)
    corner(box, 10)
    make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, box)
    box.FocusLost:Connect(function()
        local t = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        CONFIG.Target = (t == "") and "auto" or t
        box.Text = CONFIG.Target
    end)

    -- A big pill toggle button that cycles/flips a value.
    local function toggleButton(order, getLabel, onClick)
        local b = make("TextButton", {
            LayoutOrder = order, Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = PANEL,
            BorderSizePixel = 0, AutoButtonColor = true, Text = getLabel(),
            Font = Enum.Font.GothamMedium, TextSize = 15, TextColor3 = TEXT,
        }, win)
        corner(b, 10)
        b.Activated:Connect(function()
            onClick()
            b.Text = getLabel()
        end)
        return b
    end

    local thumbCycle = { "bust", "headshot", "fullbody" }
    toggleButton(4, function() return "Reference:  " .. CONFIG.ThumbnailType end, function()
        local i = (table.find(thumbCycle, CONFIG.ThumbnailType) or 1) % #thumbCycle + 1
        CONFIG.ThumbnailType = thumbCycle[i]
    end)
    toggleButton(5, function() return "Auto-crop:  " .. (CONFIG.AutoCrop and "ON" or "OFF") end, function()
        CONFIG.AutoCrop = not CONFIG.AutoCrop
    end)
    toggleButton(6, function() return "Auto-submit:  " .. (CONFIG.AutoSubmit and "ON" or "OFF") end, function()
        CONFIG.AutoSubmit = not CONFIG.AutoSubmit
    end)

    -- Big DRAW button.
    local draw = make("TextButton", {
        LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 58), BackgroundColor3 = PINK, BorderSizePixel = 0,
        AutoButtonColor = true, Text = "✎  DRAW", Font = Enum.Font.GothamBold, TextSize = 20,
        TextColor3 = Color3.new(1, 1, 1),
    }, win)
    corner(draw, 12)
    draw.Activated:Connect(function() task.spawn(run) end)

    -- Status line.
    local status = make("TextLabel", {
        Name = "Status", LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
        Text = "Ready. Join a drawing round.", Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = MUTED, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, win)
    statusSink = function(msg) status.Text = msg end

    -- Open/close.
    local function setOpen(open)
        win.Visible = open
        fab.Text = open and "▾" or "✏️"
    end
    closeBtn.Activated:Connect(function() setOpen(false) end)

    -- Touch drag for the FAB; a tap (no real movement) toggles the panel.
    do
        local dragging, moved, startPos, fabStart
        fab.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging, moved = true, false
                startPos, fabStart = input.Position, fab.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = input.Position - startPos
                if d.Magnitude > 6 then moved = true end
                fab.Position = UDim2.new(fabStart.X.Scale, fabStart.X.Offset + d.X,
                                         fabStart.Y.Scale, fabStart.Y.Offset + d.Y)
                win.Position = UDim2.new(fab.Position.X.Scale, fab.Position.X.Offset,
                                         fab.Position.Y.Scale, fab.Position.Y.Offset + 74)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1) then
                dragging = false
                if not moved then setOpen(not win.Visible) end -- tap = toggle
            end
        end)
    end

    return gui
end

if IS_MOBILE then
    pcall(buildMobileUI)
end

-- Keyboard shortcut (PC / devices with a keyboard).
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.Keybind then run() end
end)

if IS_MOBILE then
    notify("Loaded. Tap the ✏️ button to open the panel and draw the stage player.")
else
    notify(("Loaded (PC). Press %s during a drawing round to draw the stage player.")
        :format(CONFIG.Keybind.Name))
end
