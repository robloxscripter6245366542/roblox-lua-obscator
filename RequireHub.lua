--[[
    RequireHub — powered by WindUI
    Type a number, require(ID), or any full expression and run it
    e.g.  82872821
    e.g.  require(82872821).MorphMonster("Rapbatrat","locust")
--]]

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true
))()

local Window = WindUI:CreateWindow({
    Title = "RequireHub",
    Icon = "solar:folder-2-bold-duotone",
    Folder = "RequireHub",
    NewElements = true,
    HideSearchBar = true,

    OpenButton = {
        Title = "RequireHub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 0,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#6e3cff"),
            Color3.fromHex("#3c8fff")
        ),
    },

    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

local Tab = Window:Tab({
    Title = "Loader",
    Icon = "solar:folder-2-bold-duotone",
})

-- Input field
local currentExpr = ""

Tab:Input({
    Title = "Require Expression",
    Desc = 'Type a number, require(ID), or require(ID).Method("arg")',
    Placeholder = 'e.g.  82872821',
    Type = "Input",
    Callback = function(value)
        currentExpr = value
    end,
})

Tab:Space()

-- Run button
Tab:Button({
    Title = "Run",
    Color = Color3.fromHex("#6e3cff"),
    Justify = "Center",
    Icon = "",
    Callback = function()
        local code = currentExpr:match("^%s*(.-)%s*$")
        if code == "" then
            WindUI:Notify({
                Title = "RequireHub",
                Content = "Enter an expression first",
                Icon = "solar:info-square-bold",
                Duration = 2,
            })
            return
        end

        -- bare number → require(n)
        if code:match("^%d+$") then
            code = "require(" .. code .. ")"
        end

        local fn, ce = loadstring(code)
        if not fn then
            fn, ce = loadstring("return " .. code)
        end

        local ok, e
        if fn then
            ok, e = pcall(fn)
        else
            ok, e = false, ce
        end

        if ok then
            WindUI:Notify({
                Title = "Done",
                Content = code,
                Icon = "solar:check-square-bold",
                Duration = 3,
            })
        else
            local msg = tostring(e):gsub("^.*:%d+: ", "")
            WindUI:Notify({
                Title = "Error",
                Content = msg,
                Icon = "solar:info-square-bold",
                Duration = 5,
            })
            warn("[RequireHub] " .. tostring(e))
        end
    end,
})
