--[[
    ============================================================================
      video2lua  |  Premium in-game video player for Roblox
    ============================================================================
    This file is GENERATED. Do not edit the __VIDEO2LUA_*__ markers by hand -
    they are replaced by video2lua.py with the encoded video data.

    Rendering : full-resolution frames drawn with AssetService EditableImage
    Decoding  : base64 -> per-frame RLE -> RGBA pixel buffer (pre-decoded at load)
    Audio     : optional Roblox Sound asset, kept in sync with the timeline
    UI        : draggable premium window with play/pause, scrubber, volume,
                loop and fullscreen controls
    ============================================================================
]]

--// ====================== GENERATED METADATA ============================ //--
local META = {
    title      = "__VIDEO2LUA_TITLE__",
    width      = __VIDEO2LUA_WIDTH__,
    height     = __VIDEO2LUA_HEIGHT__,
    fps        = __VIDEO2LUA_FPS__,
    frameCount = __VIDEO2LUA_FRAMECOUNT__,
    audioId    = "__VIDEO2LUA_AUDIOID__",   -- rbxassetid string or "" if none
    duration   = __VIDEO2LUA_DURATION__,
}

--  FRAMES is a flat array of base64 strings, one per frame, each holding an
--  RLE-compressed RGB stream (tokens of [count][r][g][b]).
local FRAMES = __VIDEO2LUA_FRAMES__
--// ====================================================================== //--


--============================ SERVICES ==================================--
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local AssetService       = game:GetService("AssetService")
local TweenService       = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

--======================== SMALL UTILITIES ===============================--
local WIDTH, HEIGHT   = META.width, META.height
local SIZE            = Vector2.new(WIDTH, HEIGHT)
local FRAME_TIME      = 1 / math.max(META.fps, 1)
local PIXELS          = WIDTH * HEIGHT

local ACCENT_A = Color3.fromRGB(124, 92, 255)   -- violet
local ACCENT_B = Color3.fromRGB(64, 196, 255)   -- cyan
local BG_DARK  = Color3.fromRGB(16, 16, 22)
local BG_PANEL = Color3.fromRGB(24, 24, 33)

local function fmtTime(t)
    t = math.max(0, math.floor(t))
    local m = math.floor(t / 60)
    local s = t % 60
    return string.format("%d:%02d", m, s)
end

--============================ BASE64 ====================================--
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64LUT = {}
for i = 1, #B64 do
    B64LUT[string.byte(B64, i)] = i - 1
end

-- Decode a base64 string into a Roblox `buffer` of raw bytes.
local function b64decode(s)
    local slen = #s
    local pad = 0
    if slen >= 1 and string.byte(s, slen) == 61 then pad += 1 end       -- '='
    if slen >= 2 and string.byte(s, slen - 1) == 61 then pad += 1 end
    local outlen = (slen // 4) * 3 - pad
    local out = buffer.create(outlen)
    local oi, i = 0, 1
    while i <= slen do
        local c1 = B64LUT[string.byte(s, i)]     or 0
        local c2 = B64LUT[string.byte(s, i + 1)] or 0
        local c3 = B64LUT[string.byte(s, i + 2)] or 0
        local c4 = B64LUT[string.byte(s, i + 3)] or 0
        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
        if oi < outlen then buffer.writeu8(out, oi, (n // 65536) % 256); oi += 1 end
        if oi < outlen then buffer.writeu8(out, oi, (n // 256) % 256);   oi += 1 end
        if oi < outlen then buffer.writeu8(out, oi, n % 256);            oi += 1 end
        i += 4
    end
    return out
end

-- Expand one RLE frame buffer ([count][r][g][b] tokens) into an RGBA buffer.
local function expandFrame(rle)
    local n = buffer.len(rle)
    local px = buffer.create(PIXELS * 4)
    local o, p = 0, 0
    while p < n do
        local count = buffer.readu8(rle, p)
        local r = buffer.readu8(rle, p + 1)
        local g = buffer.readu8(rle, p + 2)
        local b = buffer.readu8(rle, p + 3)
        p += 4
        for _ = 1, count do
            buffer.writeu8(px, o,     r)
            buffer.writeu8(px, o + 1, g)
            buffer.writeu8(px, o + 2, b)
            buffer.writeu8(px, o + 3, 255)
            o += 4
        end
    end
    return px
end

--======================= EDITABLE IMAGE SET-UP ==========================--
-- Roblox has shipped a few variants of this API. Try them all defensively.
local editableImage
do
    local attempts = {
        function() return AssetService:CreateEditableImage({ Size = SIZE }) end,
        function() return AssetService:CreateEditableImage(SIZE) end,
        function() return AssetService:CreateEditableImage() end,
    }
    for _, make in ipairs(attempts) do
        local ok, img = pcall(make)
        if ok and img then
            editableImage = img
            break
        end
    end
end

if not editableImage then
    warn("[video2lua] This executor / Studio build does not expose "
        .. "AssetService:CreateEditableImage. Full-quality playback is "
        .. "unavailable here.")
    return
end

local function writeFrame(px)
    if editableImage.WritePixelsBuffer then
        editableImage:WritePixelsBuffer(Vector2.zero, SIZE, px)
    else
        -- Legacy float-array signature.
        local floats = table.create(PIXELS * 4)
        for k = 0, PIXELS * 4 - 1 do
            floats[k + 1] = buffer.readu8(px, k) / 255
        end
        editableImage:WritePixels(Vector2.zero, SIZE, floats)
    end
end

--============================ GUI PARENT ================================--
local function guiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Tear down a previous instance if the script is re-run.
do
    local parent = guiParent()
    local old = parent:FindFirstChild("Video2Lua")
    if old then old:Destroy() end
end

--=============================== UI =====================================--
local function corner(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = inst
    return c
end

local function gradient(inst, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(ACCENT_A, ACCENT_B)
    g.Rotation = rot or 0
    g.Parent = inst
    return g
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Video2Lua"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 9999
screenGui.Parent = guiParent()

-- Window sizing keeps the source aspect ratio for the video surface.
local aspect = WIDTH / HEIGHT
local baseW = 560
local videoH = math.floor(baseW / aspect)

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(baseW, videoH + 96)
window.Position = UDim2.new(0.5, -baseW / 2, 0.5, -(videoH + 96) / 2)
window.BackgroundColor3 = BG_DARK
window.BorderSizePixel = 0
window.Parent = screenGui
corner(window, 14)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = ACCENT_A
stroke.Parent = window

-- Soft drop shadow.
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.4
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.Position = UDim2.new(0, -30, 0, -30)
shadow.ZIndex = 0
shadow.Parent = window

--------------------------------------------------------------------- title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = BG_PANEL
titleBar.BorderSizePixel = 0
titleBar.Parent = window
corner(titleBar, 14)

-- mask the lower corners of the title bar so only the top is rounded
local titleMask = Instance.new("Frame")
titleMask.Size = UDim2.new(1, 0, 0, 14)
titleMask.Position = UDim2.new(0, 0, 1, -14)
titleMask.BackgroundColor3 = BG_PANEL
titleMask.BorderSizePixel = 0
titleMask.Parent = titleBar

local accentDot = Instance.new("Frame")
accentDot.Size = UDim2.fromOffset(10, 10)
accentDot.Position = UDim2.new(0, 14, 0.5, -5)
accentDot.BackgroundColor3 = ACCENT_B
accentDot.BorderSizePixel = 0
accentDot.Parent = titleBar
corner(accentDot, 5)
gradient(accentDot, 45)

local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0, 34, 0, 0)
titleText.Size = UDim2.new(1, -110, 1, 0)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.TextColor3 = Color3.fromRGB(235, 235, 245)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Text = META.title
titleText.Parent = titleBar

local function titleButton(txt, xoff, col)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(26, 26)
    b.Position = UDim2.new(1, xoff, 0.5, -13)
    b.BackgroundColor3 = BG_DARK
    b.AutoButtonColor = true
    b.Text = txt
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = col or Color3.fromRGB(220, 220, 230)
    b.Parent = titleBar
    corner(b, 6)
    return b
end

local minimizeBtn = titleButton("–", -64)
local closeBtn    = titleButton("✕", -32, Color3.fromRGB(255, 120, 120))

------------------------------------------------------------------- video stage
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.Position = UDim2.new(0, 0, 0, 38)
stage.Size = UDim2.new(1, 0, 1, -38 - 58)
stage.BackgroundColor3 = Color3.new(0, 0, 0)
stage.BorderSizePixel = 0
stage.ClipsDescendants = true
stage.Parent = window

local display = Instance.new("ImageLabel")
display.Name = "Display"
display.BackgroundTransparency = 1
display.AnchorPoint = Vector2.new(0.5, 0.5)
display.Position = UDim2.new(0.5, 0, 0.5, 0)
display.Size = UDim2.new(1, 0, 1, 0)
display.ScaleType = Enum.ScaleType.Fit
display.ResampleMode = Enum.ResamplerMode.Default
display.Parent = stage

-- Bind the EditableImage to the ImageLabel across API variants.
do
    local bound = false
    if Content ~= nil then
        bound = pcall(function()
            display.ImageContent = Content.fromObject(editableImage)
        end)
    end
    if not bound then
        pcall(function() editableImage.Parent = display end)
    end
end

------------------------------------------------------------- loading overlay
local loader = Instance.new("Frame")
loader.Name = "Loader"
loader.Size = UDim2.new(1, 0, 1, 0)
loader.BackgroundColor3 = BG_DARK
loader.BackgroundTransparency = 0.05
loader.BorderSizePixel = 0
loader.ZIndex = 5
loader.Parent = stage

local loadLabel = Instance.new("TextLabel")
loadLabel.BackgroundTransparency = 1
loadLabel.Size = UDim2.new(1, 0, 0, 20)
loadLabel.Position = UDim2.new(0, 0, 0.5, -28)
loadLabel.Font = Enum.Font.GothamMedium
loadLabel.TextSize = 13
loadLabel.TextColor3 = Color3.fromRGB(210, 210, 225)
loadLabel.Text = "Decoding frames…"
loadLabel.ZIndex = 6
loadLabel.Parent = loader

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0, 260, 0, 6)
barBg.Position = UDim2.new(0.5, -130, 0.5, 0)
barBg.BackgroundColor3 = BG_PANEL
barBg.BorderSizePixel = 0
barBg.ZIndex = 6
barBg.Parent = loader
corner(barBg, 3)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = ACCENT_A
barFill.BorderSizePixel = 0
barFill.ZIndex = 7
barFill.Parent = barBg
corner(barFill, 3)
gradient(barFill, 0)

----------------------------------------------------------------- control bar
local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.Position = UDim2.new(0, 0, 1, -58)
controls.Size = UDim2.new(1, 0, 0, 58)
controls.BackgroundColor3 = BG_PANEL
controls.BorderSizePixel = 0
controls.Parent = window
corner(controls, 14)

local ctrlMask = Instance.new("Frame")
ctrlMask.Size = UDim2.new(1, 0, 0, 14)
ctrlMask.BackgroundColor3 = BG_PANEL
ctrlMask.BorderSizePixel = 0
ctrlMask.Parent = controls

-- scrubber / progress bar
local scrubBg = Instance.new("Frame")
scrubBg.Size = UDim2.new(1, -28, 0, 6)
scrubBg.Position = UDim2.new(0, 14, 0, 10)
scrubBg.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
scrubBg.BorderSizePixel = 0
scrubBg.Parent = controls
corner(scrubBg, 3)

local scrubFill = Instance.new("Frame")
scrubFill.Size = UDim2.new(0, 0, 1, 0)
scrubFill.BackgroundColor3 = ACCENT_A
scrubFill.BorderSizePixel = 0
scrubFill.Parent = scrubBg
corner(scrubFill, 3)
gradient(scrubFill, 0)

local scrubKnob = Instance.new("Frame")
scrubKnob.Size = UDim2.fromOffset(12, 12)
scrubKnob.AnchorPoint = Vector2.new(0.5, 0.5)
scrubKnob.Position = UDim2.new(0, 0, 0.5, 0)
scrubKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
scrubKnob.BorderSizePixel = 0
scrubKnob.ZIndex = 3
scrubKnob.Parent = scrubBg
corner(scrubKnob, 6)

-- lower row: play, time, spacer, loop, volume, fullscreen
local function ctrlButton(txt, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(30, 26)
    b.Position = UDim2.new(0, x, 0, 26)
    b.BackgroundColor3 = BG_DARK
    b.AutoButtonColor = true
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(230, 230, 240)
    b.Text = txt
    b.Parent = controls
    corner(b, 6)
    return b
end

local playBtn = ctrlButton("▶", 14)

local timeLabel = Instance.new("TextLabel")
timeLabel.BackgroundTransparency = 1
timeLabel.Position = UDim2.new(0, 52, 0, 26)
timeLabel.Size = UDim2.fromOffset(120, 26)
timeLabel.Font = Enum.Font.GothamMedium
timeLabel.TextSize = 12
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.TextColor3 = Color3.fromRGB(190, 190, 205)
timeLabel.Text = "0:00 / " .. fmtTime(META.duration)
timeLabel.Parent = controls

local fullscreenBtn = ctrlButton("⛶", 0)
fullscreenBtn.Position = UDim2.new(1, -44, 0, 26)

local loopBtn = ctrlButton("↻", 0)
loopBtn.Position = UDim2.new(1, -80, 0, 26)

local hasAudio = META.audioId ~= "" and META.audioId ~= nil
local volBtn = ctrlButton(hasAudio and "🔊" or "🔇", 0)
volBtn.Position = UDim2.new(1, -116, 0, 26)

--=============================== AUDIO ==================================--
local sound
if hasAudio then
    sound = Instance.new("Sound")
    sound.Name = "Video2LuaAudio"
    sound.SoundId = META.audioId
    sound.Volume = 0.75
    sound.Looped = false
    sound.Parent = screenGui
end

--=========================== DRAG SUPPORT ===============================--
do
    local dragging, dragStart, startPos
    local function begin(input)
        dragging = true
        dragStart = input.Position
        startPos = window.Position
    end
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            begin(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--======================= DECODE ALL FRAMES ==============================--
-- Pre-decode every frame into an RGBA buffer so playback never hitches.
local decoded = table.create(META.frameCount)
do
    for i = 1, META.frameCount do
        decoded[i] = expandFrame(b64decode(FRAMES[i]))
        if i % 3 == 0 or i == META.frameCount then
            local frac = i / META.frameCount
            barFill.Size = UDim2.new(frac, 0, 1, 0)
            loadLabel.Text = string.format("Decoding frames…  %d%%", math.floor(frac * 100))
            RunService.Heartbeat:Wait()
        end
    end
end
-- Free the encoded source once decoded.
FRAMES = nil

-- Reveal the first frame, then fade the loader out.
writeFrame(decoded[1])
TweenService:Create(loader, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
for _, d in ipairs(loader:GetDescendants()) do
    if d:IsA("TextLabel") then
        TweenService:Create(d, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    elseif d:IsA("Frame") then
        TweenService:Create(d, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
    end
end
task.delay(0.4, function() loader.Visible = false end)

--========================= PLAYBACK ENGINE ==============================--
local state = {
    playing   = true,
    looping   = true,
    muted     = not hasAudio,
    time      = 0,          -- seconds into the video
    scrubbing = false,
    lastFrame = 0,
}

local function currentFrameIndex()
    return math.clamp(math.floor(state.time / FRAME_TIME) + 1, 1, META.frameCount)
end

local function syncAudio()
    if not sound then return end
    if state.playing and not state.muted then
        sound.Volume = 0.75
        if not sound.IsPlaying then sound:Play() end
        -- Nudge audio back into sync if it drifts more than a frame.
        if math.abs(sound.TimePosition - state.time) > FRAME_TIME * 1.5 then
            sound.TimePosition = state.time
        end
    else
        if sound.IsPlaying then sound:Pause() end
    end
end

local function renderCurrent()
    local idx = currentFrameIndex()
    if idx ~= state.lastFrame then
        state.lastFrame = idx
        writeFrame(decoded[idx])
    end
end

local function setScrubUI()
    local frac = META.duration > 0 and math.clamp(state.time / META.duration, 0, 1) or 0
    scrubFill.Size = UDim2.new(frac, 0, 1, 0)
    scrubKnob.Position = UDim2.new(frac, 0, 0.5, 0)
    timeLabel.Text = fmtTime(state.time) .. " / " .. fmtTime(META.duration)
end

--------------------------------------------------------------- control wiring
local function setPlaying(v)
    state.playing = v
    playBtn.Text = v and "❚❚" or "▶"
    syncAudio()
end

playBtn.MouseButton1Click:Connect(function() setPlaying(not state.playing) end)

loopBtn.MouseButton1Click:Connect(function()
    state.looping = not state.looping
    loopBtn.TextColor3 = state.looping and ACCENT_B or Color3.fromRGB(120, 120, 135)
end)
loopBtn.TextColor3 = ACCENT_B

volBtn.MouseButton1Click:Connect(function()
    if not hasAudio then return end
    state.muted = not state.muted
    volBtn.Text = state.muted and "🔇" or "🔊"
    syncAudio()
end)

closeBtn.MouseButton1Click:Connect(function()
    if sound then sound:Stop() end
    screenGui:Destroy()
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local goal = minimized
        and UDim2.fromOffset(baseW, 38)
        or  UDim2.fromOffset(baseW, videoH + 96)
    TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
        { Size = goal }):Play()
end)

local expanded = false
fullscreenBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    local cam = workspace.CurrentCamera
    if expanded then
        local vp = cam.ViewportSize
        local w = math.min(vp.X * 0.9, 1280)
        local h = w / aspect + 96
        window.Size = UDim2.fromOffset(w, h)
        window.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
    else
        window.Size = UDim2.fromOffset(baseW, videoH + 96)
        window.Position = UDim2.new(0.5, -baseW / 2, 0.5, -(videoH + 96) / 2)
    end
end)

------------------------------------------------------------------- scrubbing
local function seekFromX(px)
    local rel = math.clamp((px - scrubBg.AbsolutePosition.X) / scrubBg.AbsoluteSize.X, 0, 1)
    state.time = rel * META.duration
    if sound then sound.TimePosition = math.min(state.time, math.max(0, sound.TimeLength - 0.05)) end
    setScrubUI()
    renderCurrent()
end

scrubBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        state.scrubbing = true
        seekFromX(input.Position.X)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if state.scrubbing and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        seekFromX(input.Position.X)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        state.scrubbing = false
    end
end)

--============================ MAIN LOOP =================================--
setPlaying(true)
setScrubUI()

RunService.Heartbeat:Connect(function(dt)
    if state.playing and not state.scrubbing then
        state.time += dt
        if state.time >= META.duration then
            if state.looping then
                state.time = 0
                if sound then sound.TimePosition = 0 end
            else
                state.time = META.duration
                setPlaying(false)
            end
        end
        renderCurrent()
        setScrubUI()
        syncAudio()
    end
end)
