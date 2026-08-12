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

    -- Alternate sections between the two Leviathan columns for a balanced layout.
    local sectionCount = 0

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
        local tab = win:AddTab({ Name = t.Title or "Tab", Icon = t.Icon })
        local tabWrap = tolerant({})

        function tabWrap:Section(s)
            s = s or {}
            sectionCount += 1
            local pos = (sectionCount % 2 == 1) and "left" or "right"
            local sec = tab:AddSection({ Name = s.Title or "Section", Position = pos })
            local secWrap = tolerant({})

            function secWrap:Toggle(c)
                c = c or {}
                sec:AddToggle({
                    Name = c.Title or "Toggle",
                    Default = c.Value ~= nil and c.Value or (c.Default or false),
                    Callback = callback(c.Callback),
                })
                return tolerant({})
            end

            function secWrap:Slider(c)
                c = c or {}
                local v = c.Value or {}
                local round = 0
                local step = c.Step or v.Step
                if type(step) == "number" and step > 0 and step < 1 then round = 2 end
                sec:AddSlider({
                    Name = c.Title or "Slider",
                    Min = v.Min or c.Min or 0,
                    Max = v.Max or c.Max or 100,
                    Default = v.Default or c.Default or (v.Min or c.Min or 0),
                    Round = round,
                    Callback = callback(c.Callback),
                })
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
                    if title ~= "" and desc ~= "" then return title .. "  —  " .. desc end
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
