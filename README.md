# Astra UI Library

A modern, dark-themed UI library for Roblox executors. Built for real scripts — clean, fast, and fully compatible with PC and mobile executors.

## Features

- **Dark Minimal Design** — GothamSSm font, dark palette, sharp 5px corners, 1px borders
- **PC + Mobile** — Draggable window on desktop, dedicated toggle button on touch devices
- **Drag & Resize** — Fully draggable title bar with corner resize handle (clamped to min/max)
- **16 UI Elements** — Toggle, Slider, Button, Dropdown, Keybind, Checkbox, RadioGroup, ColorPicker, TextBox, Label, Paragraph, Separator, ProgressBar, Table, Section Headers, ConfigSection
- **Floating Action Buttons** — Draggable on-screen buttons for quick actions (ideal for mobile), with conditional visibility
- **Element Descriptions** — Optional subtitle text on Toggles and Buttons for extra context
- **Element Dependencies** — Toggle children: hide/show related elements based on a parent toggle state
- **Notification System** — Queued toasts with icons, auto-dismiss timers, and stacked layout
- **Config System** — Save, load, delete, and auto-save settings to JSON files via executor filesystem
- **Collapsible Sections** — Sidebar sections expand/collapse to organize tabs
- **Customizable** — Custom accent colors, light theme option, watermark text
- **RGB Borders** — Beautiful, animated, toggleable RGB glow around the main UI, minimize icon, and floating buttons
- **Protected Parenting** — Auto-parents to `gethui()`, `syn.protect_gui`, or `CoreGui` based on executor

## Installation

```lua
local Library = loadstring(game:HttpGet("https://github.com/liccodeveloper/AstraUiLibrary/raw/refs/heads/main/src.lua"))()
```

## Quick Start

```lua
local Library = loadstring(game:HttpGet("https://github.com/liccodeveloper/AstraUiLibrary/raw/refs/heads/main/src.lua"))()

local window = Library.new("MY SCRIPT", "MyScriptConfigs")
window:SetToggleKey(Enum.KeyCode.Delete)

window:Notify({
    Title       = "Welcome!",
    Description = "Script loaded",
    Duration    = 3,
    Icon        = "rbxassetid://10709775704",
})

-- Mobile size adjustment
if game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled then
    window.container.Size = UDim2.new(0, 500, 0, 300)
    window._originalHeight = 300
    window.container.Position = UDim2.new(0.5, -250, 0.5, -150)
end

-- Create sidebar sections
local CombatSection = window:CreateSection("Combat")
local PlayerSection = window:CreateSection("Player")

-- Create tabs inside sections
local CombatTab = CombatSection:CreateTab("Combat Config", "rbxassetid://102159218243131")
local PlayerTab = PlayerSection:CreateTab("Player Config", "rbxassetid://134573650903721")

-- Add elements
CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name     = "Enable Aimbot",
    Default  = false,
    Flag     = "AimbotEnabled",
    Callback = function(enabled)
        print("Aimbot:", enabled)
    end,
})

CombatTab:CreateSlider({
    Name     = "Aim Speed",
    Min      = 1,
    Max      = 100,
    Default  = 50,
    Flag     = "AimSpeed",
    Callback = function(value)
        print("Speed:", value)
    end,
})

PlayerTab:CreateSection("Movement")

PlayerTab:CreateSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 200,
    Default  = 16,
    Flag     = "WalkSpeed",
    Callback = function(value)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end,
})
```

---

## API Reference

### Library

#### `Library.new(title, configFolder, sizeConfig, options)`

Creates a new window.

```lua
-- Basic
local window = Library.new("My Script", "MyScriptConfigs")

-- With custom size constraints
local window = Library.new("My Script", "MyScriptConfigs", {
    Default = { Width = 690, Height = 446 },
    Min     = { Width = 500, Height = 300 },
    Max     = { Width = 1200, Height = 800 },
})

-- With options
local window = Library.new("My Script", "MyScriptConfigs", nil, {
    AccentColor  = Color3.fromRGB(0, 170, 255), -- custom accent
    Theme        = "light",                       -- "light" or nil for dark
    Watermark    = "v1.0.0",                      -- bottom-right watermark
    RGBEnabled   = true,                          -- animates a rainbow border
    RGBSpeed     = 60,                            -- rainbow gradient rotation speed
    RGBThickness = 2                              -- boundary thickness of the glow
})
```

| Parameter | Type | Description |
|---|---|---|
| `title` | string | Window title displayed in the title bar |
| `configFolder` | string? | Folder name for config files (defaults to title) |
| `sizeConfig` | table? | `{ Default, Min, Max }` with `{ Width, Height }` each |
| `options` | table? | `{ AccentColor, Theme, Watermark, RGBEnabled, RGBSpeed, RGBThickness }` |

---

### Window Methods

| Method | Description |
|---|---|
| `window:SetToggleKey(KeyCode)` | Key to show/hide the window |
| `window:Toggle()` | Manually toggle visibility |
| `window:Notify({ Title, Description, Duration, Icon })` | Show a notification toast |
| `window:CreateSection(name)` | Create a sidebar section (returns Section) |
| `window:SetAccentColor(Color3)` | Change the accent color at runtime |
| `window:SetWatermark(text)` | Set or update the watermark text |
| `window:CreateFloatingButton(config)` | Create a floating action button (see FAB section) |
| `window:SetFloatingButtonsVisible(bool)` | Show/hide all floating buttons (respects conditions) |
| `window:RefreshFloatingButtons()` | Re-evaluate all FAB conditions and update visibility |
| `window:Destroy()` | Clean up the entire UI and all connections |

#### Config Methods

| Method | Description |
|---|---|
| `window:SaveConfig(name)` | Save all flagged element values to `AstraConfigs/{name}.json` |
| `window:LoadConfig(name)` | Load and apply a saved config |
| `window:DeleteConfig(name)` | Delete a config file |
| `window:GetConfigs()` | Returns `table` of available config names |
| `window:SetAutoSave(enabled)` | Toggle auto-save (saves every 30 seconds) |

---

### Section

Created via `window:CreateSection(name)`. Sections are collapsible groups in the sidebar.

#### `section:CreateTab(name, icon)`

```lua
local tab = section:CreateTab("Combat Config", "rbxassetid://102159218243131")
```

| Parameter | Type | Description |
|---|---|---|
| `name` | string | Tab label in the sidebar |
| `icon` | string? | `rbxassetid://` image ID for the tab icon |

---

### Tab Elements

All elements are created via `Tab:Create___({...})`. Most accept a `Flag` parameter for the config system.

---

#### Toggle

```lua
-- Basic toggle
local toggle = tab:CreateToggle({
    Name     = "Enable Feature",
    Default  = false,
    Flag     = "FeatureEnabled",
    Callback = function(enabled) end,
})

-- Toggle with description (optional subtitle below the name)
local toggle = tab:CreateToggle({
    Name        = "Kill Aura",
    Description = "Attacks nearby players automatically",
    Default     = false,
    Callback    = function(enabled) end,
})
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `Name` | string | yes | Toggle label |
| `Description` | string | no | Subtitle text displayed below the name (auto-expands height) |
| `Default` | boolean | no | Initial state (default: `false`) |
| `Flag` | string | no | Unique ID for config save/load |
| `Callback` | function | no | Called with `(enabled)` on toggle |

| Method | Return |
|---|---|
| `toggle:SetValue(bool)` | — |
| `toggle:GetValue()` | `boolean` |
| `toggle:SetChildren(table)` | — |

---

#### Slider

```lua
local slider = tab:CreateSlider({
    Name     = "Speed",
    Min      = 0,
    Max      = 100,
    Default  = 50,
    Flag     = "SpeedValue",
    Callback = function(value) end,
})
```

| Method | Return |
|---|---|
| `slider:SetValue(number)` | — |
| `slider:GetValue()` | `number` |

---

#### Button

```lua
-- Basic button
tab:CreateButton({
    Name     = "Execute",
    Callback = function() end,
})

-- Button with description (optional subtitle)
tab:CreateButton({
    Name        = "Teleport to Gun",
    Description = "Teleports you to the nearest gun on the map",
    Callback    = function() end,
})
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `Name` | string | yes | Button label |
| `Description` | string | no | Subtitle text displayed below the name (auto-expands height) |
| `Callback` | function | no | Called on click |

| Method | Description |
|---|---|
| `button:SetText(string)` | Change button label |

---

#### Dropdown

```lua
local dropdown = tab:CreateDropdown({
    Name        = "Select",
    Options     = {"Option A", "Option B", "Option C"},
    Default     = "Option A",
    MultiSelect = false,
    Flag        = "SelectedOption",
    Callback    = function(selected) end,
})
```

| Method | Description |
|---|---|
| `dropdown:SetValue(value)` | Set selection (string or table if multi) |
| `dropdown:GetValue()` | Get current selection |
| `dropdown:Refresh(newOptions)` | Replace the options list |

---

#### Keybind

```lua
local keybind = tab:CreateKeybind({
    Name     = "Fly Toggle",
    Default  = Enum.KeyCode.F,
    Toggle   = someToggle,    -- optional: auto-toggle linked element
    Flag     = "FlyKey",
    Callback = function() end,
})
```

| Method | Return |
|---|---|
| `keybind:SetKey(KeyCode)` | — |
| `keybind:GetKey()` | `EnumItem` |

---

#### Checkbox

```lua
local checkbox = tab:CreateCheckbox({
    Name     = "Show Distance",
    Default  = false,
    Flag     = "ShowDist",
    Callback = function(checked) end,
})
```

| Method | Return |
|---|---|
| `checkbox:SetValue(bool)` | — |
| `checkbox:GetValue()` | `boolean` |

---

#### RadioGroup

```lua
local radio = tab:CreateRadioGroup({
    Name     = "Mode",
    Options  = {"Fast", "Stealth", "Balanced"},
    Default  = "Fast",
    Flag     = "Mode",
    Callback = function(selected) end,
})
```

| Method | Return |
|---|---|
| `radio:SetValue(string)` | — |
| `radio:GetValue()` | `string` |

---

#### ColorPicker

```lua
local picker = tab:CreateColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(255, 0, 0),
    Flag     = "ESPColor",
    Callback = function(color) end,
})
```

| Method | Return |
|---|---|
| `picker:SetColor(Color3)` | — |
| `picker:GetColor()` | `Color3` |

---

#### TextBox

```lua
local textbox = tab:CreateTextBox({
    Name         = "Target",
    Default      = "",
    Placeholder  = "Enter name...",
    ClearOnFocus = false,
    NumbersOnly  = false,
    Flag         = "TargetName",
    Callback     = function(text, enterPressed) end,
})
```

| Method | Description |
|---|---|
| `textbox:SetText(string)` | Set value |
| `textbox:GetText()` | Get current text |
| `textbox:SetPlaceholder(string)` | Update placeholder |
| `textbox:Focus()` | Focus the input |

---

#### Paragraph

```lua
local para = tab:CreateParagraph({
    Title   = "About",
    Content = "Created by Licco Developer.",
})
```

| Method | Description |
|---|---|
| `para:SetTitle(string)` | Update title |
| `para:SetContent(string)` | Update content |

---

#### ProgressBar

```lua
local bar = tab:CreateProgressBar({
    Name    = "Loading",
    Default = 0,
})
```

| Method | Return |
|---|---|
| `bar:SetValue(0-100)` | — |
| `bar:GetValue()` | `number` |

---

#### Table

```lua
tab:CreateTable({
    Name    = "Keybinds",
    Headers = {"Action", "Key"},
    Rows    = {
        {"Shoot", "Q"},
        {"Throw", "R"},
    },
})
```

---

#### Label

```lua
tab:CreateLabel({
    Text      = "Status: Active",
    TextColor = Color3.new(0, 1, 0),
    TextSize  = 14,
})
```

---

#### Section Header

```lua
tab:CreateSection("Movement Settings")
```

Adds a visual text divider inside the tab content.

---

#### Separator

```lua
tab:CreateSeparator()
```

Adds a thin horizontal line.

---

#### Config Section

```lua
tab:CreateConfigSection()
```

Adds a complete config management UI with:
- Config name input
- Config selector dropdown
- Save / Load / Delete / Refresh buttons
- Auto-save toggle

---

## Element Dependencies (SetChildren)

Toggles can control the visibility of other elements. When the parent toggle is **OFF**, its children are **hidden**. When **ON**, they appear.

This is useful for grouping advanced options under a master toggle (e.g., ESP settings that only matter when ESP is enabled).

### Usage

```lua
-- 1. Create the parent toggle
local espToggle = tab:CreateToggle({
    Name        = "ESP Players",
    Description = "See players through walls",
    Default     = false,
    Callback    = function(enabled) end,
})

-- 2. Create child elements normally
local espRange = tab:CreateSlider({
    Name = "ESP Range", Min = 50, Max = 1500, Default = 500,
    Callback = function(v) end,
})

local espColor = tab:CreateColorPicker({
    Name = "ESP Color", Default = Color3.fromRGB(0, 255, 0),
    Callback = function(c) end,
})

-- 3. Link children to the parent
espToggle:SetChildren({ espRange, espColor })
-- espRange and espColor will be HIDDEN until espToggle is turned ON
```

### Rules

- `SetChildren` can be called on **any toggle**
- Children start **hidden** if the toggle's default is `false`
- Children appear/disappear **instantly** when the toggle changes
- Any element type can be a child (Slider, Checkbox, Button, Dropdown, etc.)
- You can call `SetChildren` at any time to update the list

---

## Config System

The config system saves and loads all element values that have a `Flag` set.

### How It Works

1. Add `Flag = "UniqueID"` to any element you want to persist
2. Call `window:SaveConfig("ProfileName")` to save
3. Call `window:LoadConfig("ProfileName")` to restore

Config files are stored as JSON in the `AstraConfigs/` folder.

### Supported Types

The config system automatically handles serialization for:
- `boolean`, `number`, `string` — stored as-is
- `Color3` — serialized as `{R, G, B, _type = "Color3"}`
- `EnumItem` (KeyCode) — serialized as `{_type = "EnumItem", _enum, _value}`
- `table` (multi-select) — stored as array

### Executor Requirements

Your executor must support these filesystem functions:
- `writefile`, `readfile`, `isfile`
- `makefolder`, `isfolder`, `listfiles`
- `delfile`

Most modern executors (Synapse, Fluxus, KRNL, Wave, Delta, Script-Ware, etc.) support these.

---

## Themes

### Dark (Default)

```
Background:  rgb(12, 12, 12)
Secondary:   rgb(20, 20, 20)
Border:      rgb(39, 39, 39)
Text:        rgb(255, 255, 255)
TextDark:    rgb(93, 93, 93)
Accent:      rgb(255, 255, 255)
```

### Light

Activated via `options.Theme = "light"` in `Library.new()`.

### Custom Accent

```lua
local window = Library.new("Script", nil, nil, {
    AccentColor = Color3.fromRGB(0, 170, 255)
})

-- Or at runtime:
window:SetAccentColor(Color3.fromRGB(255, 85, 0))
```

---

## Mobile Support

Mobile is detected automatically (`TouchEnabled and not KeyboardEnabled`). When active:
- A floating toggle button appears in the bottom-left corner
- The button is draggable and persists across tab switches
- Tap the button to show/hide the window

For best results, adjust window size on mobile:

```lua
if game:GetService("UserInputService").TouchEnabled
    and not game:GetService("UserInputService").KeyboardEnabled then
    window.container.Size = UDim2.new(0, 500, 0, 300)
    window._originalHeight = 300
    window.container.Position = UDim2.new(0.5, -250, 0.5, -150)
end
```

---

## User Profile Widget

The library includes an optional User Profile widget that docks at the bottom of the sidebar. It displays the user's avatar, name, and a customizable subtitle, alongside an interactive icon button.

### Setting Up the Profile

You can initialize or update the profile widget using `window:SetProfile(config)`.

```lua
window:SetProfile({
    Visible = true,
    SubText = "Astra Premium User", -- Standard subtitle
    Icon = "rbxassetid://73132811772878", -- Discord icon
    IconCallback = function()
        -- Example: Copy a Discord link to clipboard
        pcall(function() setclipboard("https://discord.gg/YOUR_INVITE") end)
        window:Notify({
            Title = "Link Copied!",
            Description = "Discord invite copied to clipboard.",
            Duration = 3,
            Icon = "rbxassetid://73132811772878"
        })
    end
})
```

### Dynamic Key Expiration Display

You can dynamically retrieve the key expiration date if your loader backend injects a global variable (e.g., `getgenv().AstraKeyExpiry`).

```lua
local userSubText = "Astra Premium User"
if getgenv().AstraKeyExpiry then
    local expiryData = tostring(getgenv().AstraKeyExpiry)
    if string.upper(expiryData) == "LIFETIME" then
        userSubText = "Lifetime"
    else
        userSubText = "Expires in " .. expiryData
    end
end

window:SetProfile({
    Visible = true,
    SubText = userSubText,
    Icon = "rbxassetid://73132811772878",
    IconCallback = function()
        -- Custom action here
    end
})
```

---

## Floating Action Buttons (FABs)

Floating Action Buttons are draggable, on-screen buttons designed for **mobile compatibility**. They provide quick access to actions without needing to open the main UI. Each button can have a **Condition** function that controls whether it should appear based on your script's state.

### Creating FABs

```lua
-- Basic floating button
local fab = window:CreateFloatingButton({
    Text     = "SHOOT",
    Callback = function()
        -- action to execute when tapped
        shootTarget()
    end,
})

-- FAB with conditional visibility
local fabShoot = window:CreateFloatingButton({
    Text      = "SHOOT",
    Callback  = function() shootTarget() end,
    Condition = function() return Settings.Aimbot.Enabled end,
})

-- Custom size
local fabWide = window:CreateFloatingButton({
    Text     = "GRAB GUN",
    Width    = 130,
    Height   = 42,
    Callback = function() grabGun() end,
})
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `Text` | string | no | Button label (default: `"Button"`) |
| `Callback` | function | no | Called when the button is tapped/clicked |
| `Condition` | function | no | Returns `boolean` — button only shows when this returns `true` |
| `Width` | number | no | Button width in pixels (default: `100`) |
| `Height` | number | no | Button height in pixels (default: `42`) |

| Method | Description |
|---|---|
| `fab:SetVisible(bool)` | Manually show/hide this specific button |
| `fab:SetText(string)` | Change the button label |
| `fab:GetFrame()` | Returns the underlying Frame instance |

### Controlling Visibility

FABs are **hidden by default**. Use `SetFloatingButtonsVisible` to show/hide all of them at once — typically via a Toggle in your UI:

```lua
tab:CreateToggle({
    Name        = "Mobile Compatibility",
    Description = "Shows floating action buttons on screen",
    Default     = false,
    Callback    = function(enabled)
        window:SetFloatingButtonsVisible(enabled)
    end,
})
```

### Conditional Visibility

When a FAB has a `Condition` function, it will only appear if **both**:
1. `SetFloatingButtonsVisible(true)` was called (Mobile Compatibility is ON)
2. The `Condition()` function returns `true`

This lets you link FABs to toggles — the button only appears when its feature is active:

```lua
-- Create the aimbot toggle
local aimbotToggle = tab:CreateToggle({
    Name     = "Aimbot",
    Default  = false,
    Callback = function(enabled)
        Settings.Aimbot.Enabled = enabled
        window:RefreshFloatingButtons()  -- re-evaluate all FAB conditions
    end,
})

-- Create a FAB that only shows when aimbot is ON
window:CreateFloatingButton({
    Text      = "SHOOT",
    Callback  = function() shoot() end,
    Condition = function() return Settings.Aimbot.Enabled end,
})
```

| Scenario | Mobile Toggle | Aimbot Toggle | SHOOT Button |
|---|---|---|---|
| Both off | OFF | OFF | ❌ Hidden |
| Only mobile | ON | OFF | ❌ Hidden |
| Only aimbot | OFF | ON | ❌ Hidden |
| Both on | ON | ON | ✅ Visible |

### FAB Behavior

- **Draggable** — Each button can be dragged freely on mobile (touch) and PC (mouse)
- **Tap to Execute** — Small drags (< 10px) count as taps and trigger the Callback
- **RGB Glow** — If `RGBEnabled = true`, FABs get animated RGB borders just like the main UI
- **Auto-stacking** — Multiple FABs stack vertically from the top-right corner of the screen
- **Independent position** — Each FAB remembers its dragged position independently

---

## GUI Protection

The library automatically parents itself to the safest container available:

| Priority | Method | Executor |
|---|---|---|
| 1 | `gethui()` | Most modern executors |
| 2 | `syn.protect_gui()` + CoreGui | Synapse |
| 3 | `CoreGui.RobloxGui` | Fallback |
| 4 | `CoreGui` | Last resort |

---

## Animation Speeds

| Constant | Duration |
|---|---|
| Fast | 0.1s |
| Normal | 0.15s |
| Slow | 0.2s |
| VerySlow | 0.3s |

All animations use `Quad` easing with `Out` direction by default.

---

## Common Icons

| Icon | Asset ID |
|---|---|
| Checkmark | `rbxassetid://10709775704` |
| Warning | `rbxassetid://10747384394` |
| Target | `rbxassetid://10723407389` |
| Gear | `rbxassetid://10734898355` |
| Save | `rbxassetid://10723356507` |
| Text | `rbxassetid://93828793199781` |
| Menu | `rbxassetid://112235310154264` |

---

## License

MIT — Free to use and modify.

## Credits

Created by **Licco Developer**.
