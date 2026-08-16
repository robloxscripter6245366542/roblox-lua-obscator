-- ============================================================================
--  Leviathan WindUI shim
--
--  Exposes a WindUI-compatible API backed by the Leviathan (NeverZen) UI, so a
--  script written against WindUI (e.g. anime_ball_autoparry) renders in OUR UI
--  instead of its own window. Drop-in: point the script's WindUI HttpGet at
--  this file and it returns a table shaped like WindUI.
--
--  Only the surface the Anime Ball script uses is mapped
--  (CreateWindow/Tab/Section/Toggle/Slider/Button/Paragraph/Notify/…). Anything
--  not mapped safely no-ops via a tolerant metatable, so an unexpected WindUI
--  call can never hard-error the host script.
-- ============================================================================

local UI_URL = "https://raw.githubusercontent.com/robloxscripter6245366542/roblox-lua-obscator/main/user_scripts/leviathan_ui.lua"

local NeverZen = loadstring(game:HttpGet(UI_URL))()
local Notifier = NeverZen:CreateNotifier()

-- Any table wrapped in `tolerant` answers unknown method calls with a chainable
-- no-op, so `handle:AnythingWeDidNotMap():More()` never errors.
local NOOP
local function noopfn() return NOOP end
local function tolerant(t)
    return setmetatable(t or {}, { __index = function() return noopfn end })
end
NOOP = tolerant({})

local function callback(fn)
    fn = fn or function() end
    return function(...)
        local args = { ... }
        task.spawn(function() pcall(fn, table.unpack(args)) end)
    end
end

-- ── Config auto-save ───────────────────────────────────────────────────────
-- Persist toggle/slider values and restore them on the next run, so options
-- survive a rejoin. Saves within ~0.5s of ANY change (flip a toggle -> saved).
-- Keyed by tab/section/control so keys are stable across runs. Every filesystem
-- call is existence-checked + pcall'd, so an executor without writefile just
-- silently runs without persistence instead of erroring.
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CONFIG_FOLDER = "Leviathan"
local CONFIG_FILE = "Leviathan/AnimeBall_config.json"

local savedValues = (function()
    if type(readfile) == "function" and type(isfile) == "function" then
        local ok, decoded = pcall(function()
            if isfile(CONFIG_FILE) then return HttpService:JSONDecode(readfile(CONFIG_FILE)) end
        end)
        if ok and type(decoded) == "table" then return decoded end
    end
    return {}
end)()

local liveValues = {}
local dirty = false

if type(writefile) == "function" then
    task.spawn(function()
        while true do
            task.wait(0.5)
            if dirty then
                dirty = false
                pcall(function()
                    if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(CONFIG_FOLDER) then
                        makefolder(CONFIG_FOLDER)
                    end
                    writefile(CONFIG_FILE, HttpService:JSONEncode(liveValues))
                end)
            end
        end
    end)
end

-- Seed a control from the saved config (falling back to the script's default),
-- and start tracking its live value.
local function trackValue(key, requested)
    local v = savedValues[key]
    if v == nil then v = requested end
    liveValues[key] = v
    return v
end
local function updateValue(key, v)
    liveValues[key] = v
    dirty = true
end

local WindUI = tolerant({})

function WindUI:Notify(o)
    o = o or {}
    pcall(function()
        Notifier.new(tostring(o.Title or "Leviathan"), tostring(o.Content or o.Desc or ""), tonumber(o.Duration) or 5)
    end)
end
function WindUI:SetTheme() end
function WindUI:AddTheme() return NOOP end
function WindUI:Image() return "" end

function WindUI:CreateWindow(o)
    o = o or {}
    local win = NeverZen.new({
        Name = "Leviathan",
        SubTitle = "Anime Ball",
        Keybind = (typeof(o.ToggleKey) == "EnumItem" and o.ToggleKey) or Enum.KeyCode.RightShift,
        Scale = UDim2.new(0, 611, 0, 396),
        Resizable = true,
        Shadow = false,
        Acrylic = false,
        ShowProfile = false,
    })

    local windowWrap
    windowWrap = tolerant({
        ConfigManager = tolerant({
            Config = function() return tolerant({ Load = function() end, Save = function() end }) end,
            CreateConfig = function() return tolerant({ Load = function() end, Save = function() end }) end,
        }),
        SetBackgroundTransparency = function() end,
        SetTheme = function() end,
        AddTheme = function() return NOOP end,
        Notify = function(_, n) WindUI:Notify(n) end,
        Destroy = function() pcall(function() NeverZen:Unload() end) end,
    })

    function windowWrap:Tab(t)
        t = t or {}
        local tabTitle = t.Title or "Tab"
        local tab = win:AddTab({ Name = tabTitle, Icon = t.Icon })
        local tabWrap = tolerant({})

        -- Alternate this tab's sections between the two Leviathan columns,
        -- starting fresh at the left column for EACH tab (a shared counter made
        -- some tabs start on the right, leaving a lopsided/empty column).
        local tabSectionCount = 0

        function tabWrap:Section(s)
            s = s or {}
            local secTitle = s.Title or "Section"
            tabSectionCount += 1
            local pos = (tabSectionCount % 2 == 1) and "left" or "right"
            local sec = tab:AddSection({ Name = secTitle, Position = pos })
            local secWrap = tolerant({})

            local function keyFor(title) return tabTitle .. "\0" .. secTitle .. "\0" .. tostring(title) end

            function secWrap:Toggle(c)
                c = c or {}
                -- Pick the requested default without the `a and b or c` idiom,
                -- which would drop an explicit `Value = false`.
                local requested = c.Value
                if requested == nil then requested = c.Default end
                if requested == nil then requested = false end
                -- Restore the saved value (if any) and start tracking it.
                local key = keyFor(c.Title or "Toggle")
                local default = trackValue(key, requested)
                if type(default) ~= "boolean" then default = default and true or false end
                sec:AddToggle({
                    Name = c.Title or "Toggle",
                    Default = default,
                    Callback = function(v)
                        updateValue(key, v)                       -- auto-save on change
                        task.spawn(function() pcall(c.Callback or function() end, v) end)
                    end,
                })
                -- Apply the restored state to the feature (AddToggle sets the visual
                -- but never fires the callback), so a saved-ON toggle re-enables.
                if type(c.Callback) == "function" then
                    task.spawn(function() pcall(c.Callback, default) end)
                end
                return tolerant({})
            end

            function secWrap:Slider(c)
                c = c or {}
                local v = c.Value or {}
                local round = 0
                local step = c.Step or v.Step
                if type(step) == "number" and step > 0 and step < 1 then round = 2 end
                local requested = v.Default or c.Default or (v.Min or c.Min or 0)
                local key = keyFor(c.Title or "Slider")
                local default = trackValue(key, requested)
                if type(default) ~= "number" then default = requested end
                sec:AddSlider({
                    Name = c.Title or "Slider",
                    Min = v.Min or c.Min or 0,
                    Max = v.Max or c.Max or 100,
                    Default = default,
                    Round = round,
                    Callback = function(val)
                        updateValue(key, val)                     -- auto-save on change
                        task.spawn(function() pcall(c.Callback or function() end, val) end)
                    end,
                })
                if type(c.Callback) == "function" then
                    task.spawn(function() pcall(c.Callback, default) end)
                end
                return tolerant({})
            end

            function secWrap:Button(c)
                c = c or {}
                sec:AddButton({ Name = c.Title or "Button", Callback = callback(c.Callback) })
                return tolerant({})
            end

            function secWrap:Paragraph(c)
                c = c or {}
                local title = tostring(c.Title or "")
                local function compose(desc)
                    desc = tostring(desc or "")
                    -- Title on its own line above the (often multi-line) body.
                    if title ~= "" and desc ~= "" then return title .. "\n" .. desc end
                    return title ~= "" and title or desc
                end
                local label = sec:AddLabel(compose(c.Desc or c.Content))
                return tolerant({
                    SetDesc = function(_, newdesc) pcall(function() label:SetValue(compose(newdesc)) end) end,
                    SetTitle = function(_, nt) title = tostring(nt) end,
                })
            end

            return secWrap
        end

        return tabWrap
    end

    return windowWrap
end

return WindUI
