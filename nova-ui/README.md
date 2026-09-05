# NovaUI — a modern UI library for Roblox

A single-file UI framework for building clean, animated interfaces inside real
Roblox experiences: settings panels, HUDs, admin tools, shops, spawn menus and
more. Works on PC, mobile and console. Drop in one `ModuleScript`, `require` it,
and build a full window in a few lines.

This is a **game-developer UI library** — the same category as Fluent / Rayfield
/ WindUI. It runs inside your own published game (via a `LocalScript`), not in a
third‑party executor. That's what makes it something you can legitimately sell on
the Roblox Creator Store for Robux.

---

## Features

- **Windows** — draggable, rounded, drop shadow, toggle keybind
- **Tabs** with a sidebar and optional icons
- **Components** — Button, Toggle, Slider, Dropdown, TextInput, Keybind, Label, Paragraph, Section
- **Notifications** — stacked toast messages
- **Theming** — Dark / Light + custom accent, live `:SetTheme()`
- **Touch friendly** — every control works with mouse *and* touch
- **Code-driven** — every component returns a handle with `:Set()` / `:Get()`

## Install

1. In Studio, create a `ModuleScript` named `NovaUI` and paste in
   [`NovaUI.lua`](./NovaUI.lua).
2. Put a `LocalScript` next to it (in `StarterPlayerScripts` or `StarterGui`)
   and use [`Demo.client.lua`](./Demo.client.lua) as a starting point.

```lua
local NovaUI = require(script.Parent.NovaUI)

local Window = NovaUI:CreateWindow({
    Title = "My Game", SubTitle = "Settings",
    Accent = Color3.fromRGB(120, 90, 255),
})

local Tab = Window:CreateTab("Main")
Tab:CreateSection("Gameplay")

local speed = Tab:CreateSlider({
    Name = "Walk Speed", Min = 16, Max = 120, Default = 16,
    Callback = function(v) print(v) end,
})
speed:Set(50)           -- drive it from code
print(speed:Get())      -- read the value
```

## API reference

### `NovaUI:CreateWindow(options)`
| Option | Type | Default |
| --- | --- | --- |
| `Title` | string | `"NovaUI"` |
| `SubTitle` | string? | – |
| `Size` | UDim2 | `560×380` |
| `Accent` | Color3 | purple |
| `Theme` | `"Dark"` / `"Light"` | `"Dark"` |
| `ToggleKey` | Enum.KeyCode | `RightShift` |

Returns a `Window` with: `:CreateTab(name, icon?)`, `:Notify(o)`,
`:SetTheme(name)`, `:Toggle(state?)`, `:Destroy()`.

### `Window:CreateTab(name, icon?)` → `Tab`
`Tab` exposes the component constructors below. Each returns a **handle**.

| Constructor | Handle methods | Callback signature |
| --- | --- | --- |
| `CreateSection(title)` | – | – |
| `CreateButton{Name, Description?, Callback}` | – | `()` |
| `CreateToggle{Name, Default, Callback}` | `:Set(bool)` `:Get()` | `(state)` |
| `CreateSlider{Name, Min, Max, Default, Decimals?, Callback}` | `:Set(n)` `:Get()` | `(value)` |
| `CreateDropdown{Name, Options, Default, Callback}` | `:Set(v)` `:Get()` `:Refresh(list)` | `(option)` |
| `CreateInput{Name, Placeholder?, Default?, Callback}` | `:Set(s)` `:Get()` | `(text, enterPressed)` |
| `CreateKeybind{Name, Default, OnPress}` | `:Get()` | `OnPress()` |
| `CreateLabel(text)` / `CreateParagraph(title, body)` | – | – |

### `Window:Notify{Title, Content?, Duration?}`
Shows a toast in the bottom-right. `Duration` defaults to 4 seconds.

---

## Selling it for Robux (the legit way)

You asked to let devs **pay Robux and get the tool**. The clean, ban-proof way
to do that with a UI library is the Roblox Creator Store — Roblox itself handles
the payment and delivery:

1. **Publish `NovaUI` as an asset.** In Studio, right-click the `NovaUI`
   ModuleScript → **Save to Roblox…**. Fill in a name, description and icon.
2. **Set it as a paid model.** On the [Creator Dashboard](https://create.roblox.com/dashboard/creations),
   open the asset → **Sales** → enable *For Sale* and set a Robux price.
   (Model/plugin sales require your account to meet Roblox's seller
   requirements — verified age + a small compliance checklist.)
3. Buyers purchase it, it lands in their Inventory → Toolbox, and they
   `require()` it in their game. Roblox splits the Robux to you automatically.

**Alternative — sell it as a plugin.** If you want it to install as a Studio
toolbar tool instead, the same file can ship as a paid **Plugin** on the Creator
Store (Studio handles that purchase flow too).

**Alternative — gate premium features in your own game.** If you run an
experience, sell a **Game Pass** and only build the advanced tabs when the
player owns it:

```lua
local MPS = game:GetService("MarketplaceService")
local owns = MPS:UserOwnsGamePassAsync(player.UserId, YOUR_PASS_ID)
if owns then Window:CreateTab("Pro") --[[ premium controls ]] end
```

### Protecting your paid copy
- Ship the library as a compiled/obfuscated ModuleScript if you want to make
  copying harder (this repo already contains a Luau obfuscator you can run over
  `NovaUI.lua` before publishing).
- Keep a clean, readable master copy in source control; publish only the built
  version.

> ⚠️ **What to avoid:** don't distribute this (or bundle it) as an exploit /
> executor script, and don't sell access through off-platform "key systems"
> (linkvertise etc.). Those violate Roblox's Terms of Service and get both the
> asset and the seller account terminated — which ends the income. The Creator
> Store / Game Pass routes above are the ones that actually keep paying.

---

## Roadmap ideas
- Color picker & multi-select dropdown
- Config auto-save (write control state to a `DataStore` or `writefile`-free JSON)
- Acrylic blur background option
- Prebuilt templates: admin panel, shop, settings menu
