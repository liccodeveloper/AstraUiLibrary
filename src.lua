local ts = game:GetService("TweenService")
local ui = game:GetService("UserInputService")
local plr = game:GetService("Players")
local gs = game:GetService("GuiService")
local hs = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local rs = game:GetService("RunService")

local n = "Astra"

local c = {
    Background = Color3.fromRGB(12, 12, 12),
    Secondary = Color3.fromRGB(20, 20, 20),
    Border = Color3.fromRGB(39, 39, 39),
    Text = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(93, 93, 93),
    TextFade = Color3.fromRGB(9, 9, 9),
    Accent = Color3.fromRGB(255, 255, 255),
    Toggle = {
        Enabled = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(32, 32, 32),
        Circle = Color3.fromRGB(20, 20, 20)
    },
    Checkbox = {
        Enabled = Color3.fromRGB(255, 255, 255),
        Disabled = Color3.fromRGB(22, 22, 22),
        Border = Color3.fromRGB(60, 60, 60),
        Check = Color3.fromRGB(12, 12, 12)
    },
    Notification = {
        Background = Color3.fromRGB(11, 11, 11),
        Border = Color3.fromRGB(26, 26, 26),
        Timer = Color3.fromRGB(255, 255, 255)
    }
}

local s = {
    Astra    = {Width = 690, Height = 446},
    MinAstra = {Width = 500, Height = 300},
    MaxAstra = {Width = 1200, Height = 800},
    Toggle = {Width = 38, Height = 21, Circle = 13},
    Button = {Height = 39, HeightWithDesc = 55},
    Slider = {Height = 46},
    Dropdown = {Height = 39, OptionHeight = 30},
    Tab = {Width = 135, Height = 35},
    ColorPicker = {Width = 180, Height = 160},
    Notification = {Width = 220, Height = 70},
    TextBox = {Height = 39, InputWidth = 150}
}

local f = {
    Regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
    Bold    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
}

local textsize = {
    Title  = 14,
    Normal = 14,
    Small  = 13,
    Tiny   = 11
}

local animationspeed = {
    Fast     = 0.1,
    Normal   = 0.15,
    Slow     = 0.2,
    VerySlow = 0.3
}

local Library = {}
Library.__index = Library

local NotificationQueue = {}
local NotificationContainers = {}

Library._activeDragger = nil
ui.InputChanged:Connect(function(input)
    if Library._activeDragger and
       (input.UserInputType == Enum.UserInputType.MouseMovement or
        input.UserInputType == Enum.UserInputType.Touch) then
        Library._activeDragger(input)
    end
end)

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function CreateTween(instance, properties, duration, easingStyle, easingDirection)
    local tween = ts:Create(
        instance,
        TweenInfo.new(
            duration or animationspeed.Normal,
            easingStyle or Enum.EasingStyle.Quad,
            easingDirection or Enum.EasingDirection.Out
        ),
        properties
    )
    tween:Play()
    return tween
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function CreateCorner(parent, radius)
    return CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 5),
        Parent = parent
    })
end

local function CreateStroke(parent, color, transparency)
    return CreateInstance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or c.Border,
        Transparency = transparency or 0,
        Thickness = 1,
        Parent = parent
    })
end

local function CreatePadding(parent, top, bottom, left, right)
    return CreateInstance("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent = parent
    })
end

local function CreateListLayout(parent, padding, sortOrder, direction)
    return CreateInstance("UIListLayout", {
        Padding       = UDim.new(0, padding or 0),
        SortOrder     = sortOrder or Enum.SortOrder.LayoutOrder,
        FillDirection = direction or Enum.FillDirection.Vertical,
        Parent = parent
    })
end

local function IsMobileDevice()
    return ui.TouchEnabled and not ui.KeyboardEnabled
end

local function MakeDraggable(frame, handle)
    local dragging = false
    local dragStart, startPos
    handle = handle or frame

    local function OnInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position

            Library._activeDragger = function(inp)
                if dragging then
                    local delta = inp.Position - dragStart
                    frame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Library._activeDragger = nil
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end

    handle.InputBegan:Connect(OnInputBegan)
end

-- ── Config helpers ────────────────────────────────────────────────────────────

local function EnsureConfigFolder()
    if isfolder and not isfolder("AstraConfigs") then
        makefolder("AstraConfigs")
    end
end

local function GetAvailableConfigs()
    local configs = {}
    if isfolder and listfiles then
        EnsureConfigFolder()
        local files = listfiles("AstraConfigs")
        for _, file in ipairs(files) do
            local name = file:match("AstraConfigs/(.+)%.json$")
                      or file:match("AstraConfigs\\(.+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    return configs
end

local function CreateNotificationContainer(screenGui)
    local container = CreateInstance("Frame", {
        Name = "NotificationContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -240, 0, 20),
        Size = UDim2.new(0, 220, 1, -40),
        Parent = screenGui
    })
    CreateListLayout(container, 10, Enum.SortOrder.LayoutOrder, Enum.FillDirection.Vertical)
    return container
end

-- ── Parenting helper (Rayfield-style) ─────────────────────────────────────────

--- Parents a ScreenGui to the safest available container.
--- Priority: gethui() → syn.protect_gui+CoreGui → CoreGui.RobloxGui → CoreGui
--- This mirrors Rayfield's approach, keeping the UI alive across map changes
--- and rendering it above Roblox's native interface.
--- @param screenGui ScreenGui
local function ParentToProtectedGui(screenGui)
    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    elseif CoreGui:FindFirstChild("RobloxGui") then
        screenGui.Parent = CoreGui.RobloxGui
    else
        screenGui.Parent = CoreGui
    end
end

-- ── Library.new ───────────────────────────────────────────────────────────────

function Library.new(title, configFolder, sizeConfig, options)
    local self = setmetatable({}, Library)
    self.title        = title        or "Astra"
    self.configFolder = configFolder or title or "Astra"

    local sc  = sizeConfig or {}
    local def = sc.Default or {}
    local mn  = sc.Min     or {}
    local mx  = sc.Max     or {}

    self._defaultSize = Vector2.new(def.Width or s.Astra.Width,    def.Height or s.Astra.Height)
    self._minSize     = Vector2.new(mn.Width  or s.MinAstra.Width, mn.Height  or s.MinAstra.Height)
    self._maxSize     = Vector2.new(mx.Width  or s.MaxAstra.Width, mx.Height  or s.MaxAstra.Height)

    self.sections       = {}
    self.currentTab     = nil
    self.minimized      = false
    self._keybinds      = {}
    self._toggleKey     = Enum.KeyCode.RightControl
    self._visible       = true
    self._originalHeight = self._defaultSize.Y
    self._mobileToggle  = nil
    self._configElements = {}
    self._autoSave      = false
    self._currentConfig = "default"
    self._connections   = {}
    self._floatingButtons = {}

    local opts = options or {}
    self._rgbEnabled    = opts.RGBEnabled == true
    self._rgbSpeed      = opts.RGBSpeed or 60
    self._rgbThickness  = opts.RGBThickness or 2

    if opts.AccentColor then
        c.Accent           = opts.AccentColor
        c.Toggle.Enabled   = opts.AccentColor
        c.Checkbox.Enabled = opts.AccentColor
        c.Checkbox.Border  = opts.AccentColor
    end

    if opts.Theme == "light" then
        c.Background          = Color3.fromRGB(240, 240, 240)
        c.Secondary           = Color3.fromRGB(228, 228, 228)
        c.Border              = Color3.fromRGB(208, 208, 208)
        c.Text                = Color3.fromRGB(17, 17, 17)
        c.TextDark            = Color3.fromRGB(130, 130, 130)
        c.TextFade            = Color3.fromRGB(210, 210, 210)
        c.Toggle.Disabled     = Color3.fromRGB(200, 200, 200)
        c.Toggle.Circle       = Color3.fromRGB(240, 240, 240)
        c.Checkbox.Disabled   = Color3.fromRGB(210, 210, 210)
        c.Checkbox.Border     = opts.AccentColor or Color3.fromRGB(180, 180, 180)
        c.Notification.Background = Color3.fromRGB(230, 230, 230)
        c.Notification.Border     = Color3.fromRGB(200, 200, 200)
        c.Notification.Timer      = opts.AccentColor or Color3.fromRGB(80, 80, 80)
    end

    self._watermarkText = opts.Watermark or nil

    self:_CreateMainAstra()
    self:_SetupKeybindListener()
    self:_SetupMobileSupport()
    self._notifContainer = CreateNotificationContainer(self.screenGui)

    if self._watermarkText then
        self:_CreateWatermark(self._watermarkText)
    end

    return self
end

-- ── Public methods ────────────────────────────────────────────────────────────

function Library:SetAccentColor(color)
    c.Accent           = color
    c.Toggle.Enabled   = color
    c.Checkbox.Enabled = color
    c.Checkbox.Border  = color
end

function Library:SetWatermark(text)
    self._watermarkText = text
    if self._watermarkLabel then
        self._watermarkLabel.Text = text
    else
        self:_CreateWatermark(text)
    end
end

function Library:_CreateWatermark(text)
    local watermark = CreateInstance("TextLabel", {
        Name = "Watermark",
        FontFace = f.Regular,
        TextColor3 = Color3.fromRGB(40, 40, 40),
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        TextSize = 11,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -8, 1, -6),
        Size = UDim2.new(0, 300, 0, 16),
        ZIndex = 10,
        Parent = self.screenGui
    })
    self._watermarkLabel = watermark
    return watermark
end

function Library:Notify(config)
    local title       = config.Title       or "Notification"
    local description = config.Description or ""
    local duration    = config.Duration    or 3
    local icon        = config.Icon        or "rbxassetid://10709775704"

    local notification = CreateInstance("Frame", {
        Name = "Notification",
        BackgroundColor3 = c.Notification.Background,
        Position = UDim2.new(1, 20, 0, 0),
        Size = UDim2.new(1, 0, 0, s.Notification.Height),
        ClipsDescendants = true,
        Parent = self._notifContainer
    })
    CreateCorner(notification, 4)
    CreateInstance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = c.Notification.Border,
        Thickness = 1.5,
        Parent = notification
    })

    CreateInstance("TextLabel", {
        Name = "Title",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 16),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -60, 0, 19),
        Parent = notification
    })

    CreateInstance("TextLabel", {
        Name = "Description",
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = description,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 38),
        TextSize = textsize.Normal,
        Size = UDim2.new(1, -60, 0, 19),
        Parent = notification
    })

    local iconImage = CreateInstance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = icon,
        Position = UDim2.new(1, -33, 0, 23),
        Size = UDim2.new(0, 19, 0, 19),
        Parent = notification
    })
    CreateInstance("UIAspectRatioConstraint", { Parent = iconImage })

    local timerBar = CreateInstance("Frame", {
        Name = "Timer",
        BackgroundColor3 = c.Notification.Timer,
        Position = UDim2.new(0, 0, 1, -3),
        Size = UDim2.new(1, 0, 0, 3),
        Parent = notification
    })
    CreateCorner(timerBar, 100)

    CreateTween(notification, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    CreateTween(timerBar, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        CreateTween(notification, {Position = UDim2.new(1, 20, 0, 0)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        notification:Destroy()
    end)

    return notification
end

function Library:_SetupKeybindListener()
    self._connections["keybind_listener"] = ui.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == self._toggleKey then
            self:Toggle()
        end
        for _, keybindData in pairs(self._keybinds) do
            local key = keybindData.key
            if typeof(key) == "EnumItem" then
                if key.EnumType == Enum.UserInputType then
                    if input.UserInputType == key then
                        keybindData.callback()
                    end
                else
                    if input.KeyCode == key then
                        keybindData.callback()
                    end
                end
            end
        end
    end)
end

function Library:Toggle()
    self._visible = not self._visible
    self.container.Visible = self._visible
    if self._minimizeIcon then
        if not self._visible and not self._iconPlaced then
            self._minimizeIcon.Position = UDim2.new(
                0, self.container.AbsolutePosition.X + 50,
                0, self.container.AbsolutePosition.Y + 50
            )
            self._iconPlaced = true
        end
        self._minimizeIcon.Visible = not self._visible
    end
    if self._mobileToggle then
        self._mobileToggle.Visible = false
    end
end

function Library:SetToggleKey(keyCode)
    self._toggleKey = keyCode
end

function Library:_SetupMobileSupport()
    local mobileButton = CreateInstance("ImageButton", {
        Name = "MobileToggle",
        Image = "rbxassetid://112235310154264",
        ImageColor3 = c.Text,
        BackgroundColor3 = c.Background,
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 15, 0.5, -25),
        Size = UDim2.new(0, 50, 0, 50),
        AnchorPoint = Vector2.new(0, 0.5),
        Visible = false,
        ZIndex = 999,
        Parent = self.screenGui
    })
    CreateCorner(mobileButton, 25)
    CreateStroke(mobileButton)

    local dragging = false
    local dragStart, startPos

    mobileButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = mobileButton.Position
            Library._activeDragger = function(inp)
                if dragging then
                    local delta = inp.Position - dragStart
                    mobileButton.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end
    end)

    mobileButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                local delta = input.Position - dragStart
                if delta.Magnitude < 10 then
                    self:Toggle()
                end
            end
            dragging = false
            Library._activeDragger = nil
        end
    end)

    self._mobileToggle = mobileButton
    if IsMobileDevice() then
        mobileButton.Visible = not self._visible
    end
end

function Library:_CreateRGBGlow(targetFrame, cornerRadius, isIcon)
    if not self._rgbEnabled then return nil, nil end
    local glow = CreateInstance("Frame", {
        Name = targetFrame.Name .. "RGBGlow",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 0,
        Visible = targetFrame.Visible,
        Parent = self.screenGui
    })
    CreateCorner(glow, cornerRadius)
    local grad = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Rotation = 0,
        Parent = glow
    })
    local function sync()
        if isIcon then
            glow.Position = targetFrame.Position
            glow.AnchorPoint = targetFrame.AnchorPoint
        else
            glow.Position = UDim2.new(
                targetFrame.Position.X.Scale, targetFrame.Position.X.Offset - self._rgbThickness,
                targetFrame.Position.Y.Scale, targetFrame.Position.Y.Offset - self._rgbThickness
            )
        end
        glow.Size = UDim2.new(
            targetFrame.Size.X.Scale, targetFrame.Size.X.Offset + (self._rgbThickness * 2),
            targetFrame.Size.Y.Scale, targetFrame.Size.Y.Offset + (self._rgbThickness * 2)
        )
        glow.Visible = targetFrame.Visible
    end
    self._connections["sync_glow_" .. targetFrame.Name .. "_pos"] = targetFrame:GetPropertyChangedSignal("Position"):Connect(sync)
    self._connections["sync_glow_" .. targetFrame.Name .. "_size"] = targetFrame:GetPropertyChangedSignal("Size"):Connect(sync)
    self._connections["sync_glow_" .. targetFrame.Name .. "_vis"] = targetFrame:GetPropertyChangedSignal("Visible"):Connect(sync)
    sync()
    return glow, grad
end

function Library:_CreateMainAstra()
    self.screenGui = CreateInstance("ScreenGui", {
        Name = n,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        DisplayOrder = 100
    })

    ParentToProtectedGui(self.screenGui)

    self.container = CreateInstance("Frame", {
        Name = "Container",
        BackgroundColor3 = c.Background,
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -self._defaultSize.X / 2, 0.5, -self._defaultSize.Y / 2),
        BorderSizePixel = 0,
        Size = UDim2.new(0, self._defaultSize.X, 0, self._defaultSize.Y),
        ClipsDescendants = false,
        Parent = self.screenGui
    })
    CreateCorner(self.container, 12)
    if not self._rgbEnabled then
        CreateStroke(self.container)
    end

    self.topBar = CreateInstance("Frame", {
        Name = "TopBar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 45),
        Parent = self.container
    })

    self.titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        FontFace = f.Regular,
        TextColor3 = c.Text,
        Text = self.title,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = textsize.Title,
        Size = UDim2.new(0, 150, 0, 25),
        Parent = self.topBar
    })

    self:_CreateAstraControls()

    CreateInstance("Frame", {
        Name = "Header",
        BackgroundColor3 = c.Border,
        Position = UDim2.new(0, 0, 0, 45),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.container
    })

    self:_CreateContentArea()
    self.container.ZIndex = 1
    self._rgbGlow, self._rgbGradient = self:_CreateRGBGlow(self.container, 12, false)

    self:_CreateMinimizeIcon()
    MakeDraggable(self.container, self.topBar)

    if self._rgbEnabled then
        self._connections["rgb_render"] = rs.RenderStepped:Connect(function(dt)
            if self._rgbGradient then
                self._rgbGradient.Rotation = (self._rgbGradient.Rotation + self._rgbSpeed * dt) % 360
            end
            if self._iconRgbGradient then
                self._iconRgbGradient.Rotation = (self._iconRgbGradient.Rotation + self._rgbSpeed * dt) % 360
            end
            for _, fab in ipairs(self._floatingButtons) do
                if fab.gradient then
                    fab.gradient.Rotation = (fab.gradient.Rotation + self._rgbSpeed * dt) % 360
                end
            end
        end)
    end
end

function Library:_CreateMinimizeIcon()
    local iconSize = 50

    self._minimizeIcon = CreateInstance("Frame", {
        Name = "MinimizeIcon",
        BackgroundColor3 = c.Background,
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, iconSize, 0, iconSize),
        Visible = false,
        ZIndex = 1,
        Parent = self.screenGui
    })
    CreateCorner(self._minimizeIcon, 10)
    if not self._rgbEnabled then
        CreateInstance("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Parent = self._minimizeIcon
        })
    else
        self._iconRgbGlow, self._iconRgbGradient = self:_CreateRGBGlow(self._minimizeIcon, 10, true)
    end

    self._minimizeIconImage = CreateInstance("ImageLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Image = "",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.6, 0, 0.6, 0),
        Parent = self._minimizeIcon
    })
    CreateInstance("UIAspectRatioConstraint", { Parent = self._minimizeIconImage })

    local dragging = false
    local dragStart, startPos

    self._minimizeIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = self._minimizeIcon.Position
            Library._activeDragger = function(inp)
                if dragging then
                    local delta = inp.Position - dragStart
                    self._minimizeIcon.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging then
                        local delta = input.Position - dragStart
                        if delta.Magnitude < 10 then
                            self:_ToggleMinimize()
                        end
                    end
                    dragging = false
                    Library._activeDragger = nil
                end
            end)
        end
    end)
end

function Library:SetMinimizeIcon(imageId)
    if self._minimizeIconImage then
        self._minimizeIconImage.Image = imageId
    end
end

function Library:CreateFloatingButton(config)
    local text     = config.Text     or "Button"
    local callback = config.Callback or function() end
    local width    = config.Width    or 100
    local height   = config.Height   or 42
    local order    = #self._floatingButtons

    local btnFrame = CreateInstance("Frame", {
        Name = "FloatingBtn_" .. text,
        BackgroundColor3 = c.Background,
        BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -15, 0, 120 + (order * (height + 12))),
        Size = UDim2.new(0, width, 0, height),
        Visible = false,
        ZIndex = 998,
        Parent = self.screenGui
    })
    CreateCorner(btnFrame, 10)
    if not self._rgbEnabled then
        CreateInstance("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 2,
            Parent = btnFrame
        })
    end

    CreateInstance("TextLabel", {
        Name = "Label",
        FontFace = f.Bold,
        TextColor3 = c.Text,
        Text = text,
        BackgroundTransparency = 1,
        TextSize = textsize.Normal,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 999,
        Parent = btnFrame
    })

    local dragging = false
    local dragStart, startPos

    btnFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = btnFrame.Position
            Library._activeDragger = function(inp)
                if dragging then
                    local delta = inp.Position - dragStart
                    btnFrame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragging then
                        local delta = input.Position - dragStart
                        if delta.Magnitude < 10 then
                            callback()
                        end
                    end
                    dragging = false
                    Library._activeDragger = nil
                end
            end)
        end
    end)

    local fabGlow, fabGrad
    if self._rgbEnabled then
        fabGlow, fabGrad = self:_CreateRGBGlow(btnFrame, 10, true)
    end

    local fabData = {frame = btnFrame, glow = fabGlow, gradient = fabGrad}
    table.insert(self._floatingButtons, fabData)

    return {
        SetVisible = function(_, visible)
            btnFrame.Visible = visible
            if fabGlow then fabGlow.Visible = visible end
        end,
        SetText    = function(_, t) btnFrame:FindFirstChild("Label").Text = t end,
        GetFrame   = function() return btnFrame end,
        _frame     = btnFrame,
    }
end

function Library:SetFloatingButtonsVisible(visible)
    for _, fab in ipairs(self._floatingButtons) do
        fab.frame.Visible = visible
        if fab.glow then fab.glow.Visible = visible end
    end
end

function Library:_CreateAstraControls()
    local minimizeBtn = CreateInstance("ImageLabel", {
        Name = "Minimize",
        ImageColor3 = c.TextDark,
        Image = "rbxassetid://82603981310445",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -35, 0, 15),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = self.topBar
    })

    local minimizeClickArea = CreateInstance("TextButton", {
        Name = "TextButton",
        Text = "",
        Rotation = 0.01,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 21, 0, 15),
        Parent = minimizeBtn
    })

    minimizeClickArea.MouseButton1Click:Connect(function()
        self:_ToggleMinimize()
    end)

    minimizeBtn.MouseEnter:Connect(function() minimizeBtn.ImageColor3 = c.Text     end)
    minimizeBtn.MouseLeave:Connect(function() minimizeBtn.ImageColor3 = c.TextDark end)

    local closeBtn = CreateInstance("ImageButton", {
        Name = "Close",
        ImageColor3 = c.TextDark,
        Image = "rbxassetid://119943770201674",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = self.topBar
    })

    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)
    closeBtn.MouseEnter:Connect(function() closeBtn.ImageColor3 = Color3.fromRGB(255, 100, 100) end)
    closeBtn.MouseLeave:Connect(function() closeBtn.ImageColor3 = c.TextDark end)

    local resizeBtn = CreateInstance("ImageButton", {
        Name = "Resize",
        ImageColor3 = Color3.fromRGB(110, 110, 110),
        Image = "rbxassetid://120997033468887",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.new(0, 62, 0, 60),
        BorderSizePixel = 0,
        Parent = self.container
    })

    self.resizeBtn = resizeBtn
    self:_SetupSmartResize(resizeBtn)
end

function Library:_CreateContentArea()
    self.mainContent = CreateInstance("Frame", {
        Name = "MainContent",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 46),
        Size = UDim2.new(1, 0, 1, -46),
        ClipsDescendants = true,
        Parent = self.container
    })

    self.sectionsContainer = CreateInstance("ScrollingFrame", {
        Name = "SectionsContainer",
        ScrollBarThickness = 0,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 165, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.mainContent
    })
    CreateListLayout(self.sectionsContainer, 0, Enum.SortOrder.LayoutOrder)
    CreatePadding(self.sectionsContainer, 5, 5, 5, 5)

    CreateInstance("Frame", {
        Name = "Separator",
        BackgroundColor3 = c.Border,
        Position = UDim2.new(0, 165, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0),
        Parent = self.mainContent
    })

    self.contentContainer = CreateInstance("ScrollingFrame", {
        Name = "ContentContainer",
        ScrollBarThickness = 0,
        ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 166, 0, 0),
        Size = UDim2.new(1, -166, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.mainContent
    })
    CreateListLayout(self.contentContainer, 8, Enum.SortOrder.LayoutOrder)
    CreatePadding(self.contentContainer, 10, 10, 15, 15)
end

function Library:_SetupSmartResize(handle)
    local resizing = false
    local resizeStart, startSize

    handle.MouseEnter:Connect(function()
        handle.ImageColor3 = c.Text
    end)
    handle.MouseLeave:Connect(function()
        if not resizing then
            handle.ImageColor3 = Color3.fromRGB(110, 110, 110)
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            resizing    = true
            resizeStart = input.Position
            startSize   = self.container.AbsoluteSize
            self._originalHeight = startSize.Y

            Library._activeDragger = function(inp)
                if resizing then
                    local delta     = inp.Position - resizeStart
                    local newWidth  = math.clamp(startSize.X + delta.X, self._minSize.X, self._maxSize.X)
                    local newHeight = math.clamp(startSize.Y + delta.Y, self._minSize.Y, self._maxSize.Y)
                    self.container.Size = UDim2.new(0, newWidth, 0, newHeight)
                    self._originalHeight = newHeight
                end
            end

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    Library._activeDragger = nil
                    handle.ImageColor3 = Color3.fromRGB(110, 110, 110)
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)
end

function Library:_ToggleMinimize()
    self.minimized = not self.minimized
    if self.minimized then
        self._visible = false
        if self._minimizeIcon and not self._iconPlaced then
            self._minimizeIcon.Position = UDim2.new(
                0, self.container.AbsolutePosition.X + 50,
                0, self.container.AbsolutePosition.Y + 50
            )
            self._iconPlaced = true
        end
        self.container.Visible = false
        if self._minimizeIcon then self._minimizeIcon.Visible = true end
    else
        self._visible = true
        self.container.Visible = true
        if self._minimizeIcon then self._minimizeIcon.Visible = false end
    end
end

function Library:Destroy()
    if self._autoSave then
        self:SaveConfig(self._currentConfig)
    end
    for _, conn in pairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    if self.screenGui then
        self.screenGui:Destroy()
    end
end

-- ── Config ────────────────────────────────────────────────────────────────────

function Library:_RegisterConfigElement(id, elementType, getValue, setValue)
    self._configElements[id] = {
        type     = elementType,
        getValue = getValue,
        setValue = setValue
    }
end

function Library:SaveConfig(configName)
    if not writefile then
        self:Notify({ Title = "Error", Description = "Config system not supported", Duration = 3 })
        return false
    end
    EnsureConfigFolder()
    local configData = {}
    for id, element in pairs(self._configElements) do
        local value = element.getValue()
        if typeof(value) == "Color3" then
            value = {R = value.R, G = value.G, B = value.B, _type = "Color3"}
        elseif typeof(value) == "EnumItem" then
            value = {_type = "EnumItem", _enum = tostring(value.EnumType), _value = value.Name}
        end
        configData[id] = value
    end
    local success = pcall(function()
        writefile("AstraConfigs/" .. configName .. ".json", hs:JSONEncode(configData))
    end)
    if success then
        self._currentConfig = configName
        self:Notify({ Title = "Config Saved", Description = "Saved as: " .. configName, Duration = 2, Icon = "rbxassetid://10723356507" })
        return true
    else
        self:Notify({ Title = "Error", Description = "Failed to save config", Duration = 3 })
        return false
    end
end

function Library:LoadConfig(configName)
    if not readfile or not isfile then
        self:Notify({ Title = "Error", Description = "Config system not supported", Duration = 3 })
        return false
    end
    local path = "AstraConfigs/" .. configName .. ".json"
    if not isfile(path) then
        self:Notify({ Title = "Error", Description = "Config not found: " .. configName, Duration = 3 })
        return false
    end
    local success, data = pcall(function() return hs:JSONDecode(readfile(path)) end)
    if not success or not data then
        self:Notify({ Title = "Error", Description = "Failed to load config", Duration = 3 })
        return false
    end
    for id, value in pairs(data) do
        if self._configElements[id] then
            if type(value) == "table" and value._type == "Color3" then
                value = Color3.new(value.R, value.G, value.B)
            elseif type(value) == "table" and value._type == "EnumItem" then
                value = Enum[value._enum][value._value]
            end
            pcall(function() self._configElements[id].setValue(value) end)
        end
    end
    self._currentConfig = configName
    self:Notify({ Title = "Config Loaded", Description = "Loaded: " .. configName, Duration = 2, Icon = "rbxassetid://10723356507" })
    return true
end

function Library:DeleteConfig(configName)
    if not delfile or not isfile then return false end
    local path = "AstraConfigs/" .. configName .. ".json"
    if isfile(path) then
        delfile(path)
        self:Notify({ Title = "Config Deleted", Description = "Deleted: " .. configName, Duration = 2 })
        return true
    end
    return false
end

function Library:GetConfigs()
    return GetAvailableConfigs()
end

function Library:SetAutoSave(enabled)
    self._autoSave = enabled
    if enabled then
        task.spawn(function()
            while self._autoSave and self.screenGui and self.screenGui.Parent do
                task.wait(30)
                if self._autoSave then self:SaveConfig(self._currentConfig) end
            end
        end)
    end
end

-- ── Sections & Tabs ───────────────────────────────────────────────────────────

function Library:CreateSection(name)
    local section = {
        name = name, tabs = {}, expanded = true, _library = self
    }

    local sectionFrame = CreateInstance("Frame", {
        Name = "Section_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = self.sectionsContainer
    })
    CreateListLayout(sectionFrame, 2, Enum.SortOrder.LayoutOrder)

    local headerContainer = CreateInstance("Frame", {
        Name = "HeaderContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 25),
        LayoutOrder = 0,
        Parent = sectionFrame
    })

    CreateInstance("TextButton", {
        Name = "Header",
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = "",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = headerContainer
    })

    CreateInstance("TextLabel", {
        Name = "Label",
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 0),
        TextSize = textsize.Small,
        Size = UDim2.new(1, -25, 1, 0),
        Parent = headerContainer
    })

    local arrow = CreateInstance("ImageButton", {
        Name = "Arrow",
        Image = "rbxassetid://105558791071013",
        ImageColor3 = c.TextDark,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0.5, -7),
        Size = UDim2.new(0, 15, 0, 15),
        Rotation = 0,
        Parent = headerContainer
    })

    local tabsContainer = CreateInstance("Frame", {
        Name = "TabsContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Parent = sectionFrame
    })
    CreateListLayout(tabsContainer, 2, Enum.SortOrder.LayoutOrder)
    CreatePadding(tabsContainer, 0, 0, 15, 0)

    local headerBtn = headerContainer:FindFirstChild("Header")

    local function ToggleSection()
        section.expanded = not section.expanded
        arrow.Rotation = section.expanded and 0 or 180
        tabsContainer.Visible = section.expanded
    end

    headerBtn.MouseButton1Click:Connect(ToggleSection)
    arrow.MouseButton1Click:Connect(ToggleSection)

    section.frame         = sectionFrame
    section.tabsContainer = tabsContainer
    table.insert(self.sections, section)

    local sectionMethods = setmetatable({}, {__index = section})
    function sectionMethods:CreateTab(tabName, icon)
        return Library._CreateTab(self, tabName, icon)
    end

    return sectionMethods
end

function Library._CreateTab(section, name, icon)
    local tab = { name = name, elements = {} }

    local tabBtn = CreateInstance("Frame", {
        Name = name,
        BackgroundColor3 = c.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(0, s.Tab.Width, 0, s.Tab.Height),
        Parent = section.tabsContainer
    })
    CreateCorner(tabBtn, 5)
    local tabStroke = CreateStroke(tabBtn, c.Border, 1)

    local iconLabel = CreateInstance("ImageLabel", {
        Name = "Icon",
        BackgroundTransparency = 1,
        Image = icon or "rbxassetid://112235310154264",
        ImageColor3 = c.TextDark,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.new(0, 15, 0, 15),
        Parent = tabBtn
    })

    local tabText = CreateInstance("TextLabel", {
        Name = "TabText",
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 33, 0, 0),
        Size = UDim2.new(1, -42, 1, 0),
        TextSize = textsize.Small,
        Parent = tabBtn
    })
    CreateInstance("UIPadding", { PaddingRight = UDim.new(0, 9), Parent = tabText })

    local textGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    c.TextDark),
            ColorSequenceKeypoint.new(0.65, c.TextDark),
            ColorSequenceKeypoint.new(1,    c.TextFade)
        }),
        Parent = tabText
    })

    local clickBtn = CreateInstance("TextButton", {
        Name = "ClickButton",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = tabBtn
    })

    tab.content = CreateInstance("Frame", {
        Name = name .. "_Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = section._library.contentContainer
    })
    CreateListLayout(tab.content, 8, Enum.SortOrder.LayoutOrder)

    clickBtn.MouseButton1Click:Connect(function()
        Library._SelectTab(section._library, tab, tabBtn, tabStroke, iconLabel, tabText, textGradient)
    end)
    clickBtn.MouseEnter:Connect(function()
        if section._library.currentTab ~= tab then tabBtn.BackgroundTransparency = 0.7 end
    end)
    clickBtn.MouseLeave:Connect(function()
        if section._library.currentTab ~= tab then tabBtn.BackgroundTransparency = 1 end
    end)

    tab.button       = tabBtn
    tab.stroke       = tabStroke
    tab.icon         = iconLabel
    tab.textLabel    = tabText
    tab.textGradient = textGradient
    tab._library     = section._library

    table.insert(section.tabs, tab)

    if not section._library.currentTab then
        Library._SelectTab(section._library, tab, tabBtn, tabStroke, iconLabel, tabText, textGradient)
    end

    local tabMethods = setmetatable({}, {__index = tab})

    function tabMethods:CreateSection(sectionName)      return Library._CreateContentSection(self, sectionName) end
    function tabMethods:CreateLabel(config)             return Library._CreateLabel(self, config)               end
    function tabMethods:CreateSeparator(config)         return Library._CreateSeparator(self, config)           end
    function tabMethods:CreateParagraph(config)         return Library._CreateParagraph(self, config)           end
    function tabMethods:CreateSlider(config)            return Library._CreateSlider(self, config)              end
    function tabMethods:CreateButton(config)            return Library._CreateButton(self, config)              end
    function tabMethods:CreateToggle(config)            return Library._CreateToggle(self, config)              end
    function tabMethods:CreateCheckbox(config)          return Library._CreateCheckbox(self, config)            end
    function tabMethods:CreateRadioGroup(config)        return Library._CreateRadioGroup(self, config)          end
    function tabMethods:CreateDropdown(config)          return Library._CreateDropdown(self, config)            end
    function tabMethods:CreateKeybind(config)           return Library._CreateKeybind(self, config, section._library) end
    function tabMethods:CreateColorPicker(config)       return Library._CreateColorPicker(self, config)         end
    function tabMethods:CreateTextBox(config)           return Library._CreateTextBox(self, config)             end
    function tabMethods:CreateConfigSection()           return Library._CreateConfigSection(self)               end
    function tabMethods:CreateProgressBar(config)       return Library._CreateProgressBar(self, config)         end
    function tabMethods:CreateTable(config)             return Library._CreateTable(self, config)               end

    return tabMethods
end

function Library._SelectTab(lib, tab, btn, stroke, icon, textLabel, textGradient)
    if lib.currentTab then
        lib.currentTab.content.Visible         = false
        lib.currentTab.button.BackgroundTransparency = 1
        lib.currentTab.icon.ImageColor3        = c.TextDark
        lib.currentTab.stroke.Transparency     = 1
        if lib.currentTab.textGradient then
            lib.currentTab.textGradient.Enabled = true
        end
    end
    lib.currentTab          = tab
    tab.content.Visible     = true
    btn.BackgroundTransparency = 1
    icon.ImageColor3        = c.Text
    stroke.Transparency     = 1
    if textGradient then textGradient.Enabled = false end
    textLabel.TextColor3    = c.Text
end

-- ── Elements (inalterados, apenas recopiados) ─────────────────────────────────

function Library._CreateContentSection(tab, name)
    return CreateInstance("TextLabel", {
        Name = "Section_" .. name,
        FontFace = f.Regular,
        TextColor3 = c.TextDark,
        Text = name,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        TextSize = 15,
        Size = UDim2.new(1, 0, 0, 25),
        Parent = tab.content
    })
end

function Library._CreateLabel(tab, config)
    local text      = config.Text      or "Label"
    local textColor = config.TextColor or c.TextDark
    local textSize  = config.TextSize  or textsize.Normal

    local label = CreateInstance("TextLabel", {
        Name = "Label_" .. text,
        FontFace = f.Regular,
        TextColor3 = textColor,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BackgroundTransparency = 1,
        TextSize = textSize,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = tab.content
    })
    return {
        SetText  = function(_, t) label.Text = t end,
        SetColor = function(_, c) label.TextColor3 = c end,
        GetText  = function() return label.Text end,
        _frame   = label
    }
end

function Library._CreateSeparator(tab, config)
    local text = config and config.Text or nil
    local container = CreateInstance("Frame", {
        Name = "Separator",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, text and 20 or 10),
        Parent = tab.content
    })
    if text and text ~= "" then
        local leftLine = CreateInstance("Frame", { BackgroundColor3 = c.Border, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 1), Parent = container })
        local label    = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.TextDark, Text = text, BackgroundTransparency = 1, TextSize = textsize.Tiny, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = container })
        local rightLine = CreateInstance("Frame", { BackgroundColor3 = c.Border, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 1), Parent = container })
        task.defer(function()
            local lw = math.floor((container.AbsoluteSize.X - label.AbsoluteSize.X - 12) / 2)
            if lw > 0 then
                leftLine.Size  = UDim2.new(0, lw, 0, 1)
                rightLine.Size = UDim2.new(0, lw, 0, 1)
            end
        end)
    else
        CreateInstance("Frame", { BackgroundColor3 = c.Border, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Parent = container })
    end
    return container
end

function Library._CreateParagraph(tab, config)
    local title   = config.Title   or "Paragraph"
    local content = config.Content or "Description text here."
    local frame = CreateInstance("Frame", { Name = "Paragraph", BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame); CreatePadding(frame, 10, 10, 10, 10)
    local titleLabel   = CreateInstance("TextLabel", { Name = "Title",   FontFace = f.Regular, TextColor3 = c.Text,     Text = title,   TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, TextSize = textsize.Normal, Size = UDim2.new(1, 0, 0, 20), Parent = frame })
    local contentLabel = CreateInstance("TextLabel", { Name = "Content", FontFace = f.Regular, TextColor3 = c.TextDark, Text = content, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1, TextSize = textsize.Small, Position = UDim2.new(0, 0, 0, 22), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = frame })
    return {
        SetTitle   = function(_, t) titleLabel.Text   = t end,
        SetContent = function(_, t) contentLabel.Text = t end
    }
end

function Library._CreateSlider(tab, config)
    local name     = config.Name     or "Slider"
    local min      = config.Min      or 0
    local max      = config.Max      or 100
    local default  = config.Default  or 50
    local step     = config.Step     or 1
    local suffix   = config.Suffix   or ""
    local callback = config.Callback or function() end
    local flag     = config.Flag

    local decimals = 0
    if step < 1 then
        local dot = tostring(step):find("%.")
        if dot then decimals = #tostring(step) - dot end
    end

    local function Round(value)
        if step <= 0 then return value end
        local snapped = math.floor((value - min) / step + 0.5) * step + min
        snapped = math.clamp(snapped, min, max)
        if decimals > 0 then
            local mult = 10 ^ decimals
            return math.floor(snapped * mult + 0.5) / mult
        end
        return math.floor(snapped + 0.5)
    end

    local currentValue = Round(default)

    local function FormatValue(v)
        if decimals > 0 then return string.format("%." .. decimals .. "f", v) .. suffix end
        return tostring(math.floor(v)) .. suffix
    end

    local frame = CreateInstance("Frame", { Name = "Slider_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Slider.Height), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    CreateInstance("TextLabel", { Name = "Name",  FontFace = f.Regular, TextColor3 = c.Text, Text = name,                  TextXAlignment = Enum.TextXAlignment.Left,  BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5),   TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })
    local valueLabel = CreateInstance("TextLabel", { Name = "Value", FontFace = f.Regular, TextColor3 = c.Text, Text = FormatValue(currentValue), TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Position = UDim2.new(1, -70, 0, 5), TextSize = textsize.Normal, Size = UDim2.new(0, 60, 0, 20),  Parent = frame })

    local sliderBg = CreateInstance("Frame", { Name = "SliderBackground", BackgroundColor3 = Color3.fromRGB(11, 11, 11), Position = UDim2.new(0, 10, 0, 29), BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 7), Parent = frame })
    CreateCorner(sliderBg, 100)

    local sliderFill = CreateInstance("Frame", { Name = "SliderFill", BackgroundColor3 = c.Accent, BorderSizePixel = 0, Size = UDim2.new((currentValue - min) / math.max(max - min, 0.001), 0, 1, 0), Parent = sliderBg })
    CreateCorner(sliderFill, 100)

    local function UpdateSlider(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        currentValue = Round(min + (max - min) * relativeX)
        sliderFill.Size = UDim2.new((currentValue - min) / math.max(max - min, 0.001), 0, 1, 0)
        valueLabel.Text = FormatValue(currentValue)
        callback(currentValue)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UpdateSlider(input)
            Library._activeDragger = UpdateSlider
        end
    end)
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Library._activeDragger = nil
        end
    end)

    local methods = {
        SetValue = function(_, value)
            currentValue = Round(math.clamp(value, min, max))
            sliderFill.Size = UDim2.new((currentValue - min) / math.max(max - min, 0.001), 0, 1, 0)
            valueLabel.Text = FormatValue(currentValue)
            callback(currentValue)
        end,
        GetValue = function() return currentValue end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Slider", function() return currentValue end, function(v) methods:SetValue(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateButton(tab, config)
    local name     = config.Name     or "Button"
    local callback = config.Callback or function() end
    local desc     = config.Description

    local frameHeight = desc and s.Button.HeightWithDesc or s.Button.Height
    local frame = CreateInstance("Frame", { Name = "Button_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, frameHeight), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    local nameYOffset = desc and -16 or -10
    local nameLabel = CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, nameYOffset), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })
    
    if desc then
        CreateInstance("TextLabel", { Name = "Description", FontFace = f.Regular, TextColor3 = c.TextDark, Text = desc, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 2), TextSize = textsize.Tiny, Size = UDim2.new(1, -50, 0, 16), Parent = frame })
    end

    local icon = CreateInstance("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = "rbxassetid://10734898355", ImageColor3 = c.Text, Position = UDim2.new(1, -30, 0.5, -10), Size = UDim2.new(0, 20, 0, 20), Parent = frame })
    CreateInstance("UIAspectRatioConstraint", { Parent = icon })

    local button = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })
    button.MouseButton1Click:Connect(function()
        frame.BackgroundTransparency = 0.2
        task.wait(0.1)
        frame.BackgroundTransparency = 0.4
        callback()
    end)

    local methods = { SetText = function(_, t) nameLabel.Text = t end }
    methods._frame = frame
    return methods
end

function Library._CreateToggle(tab, config)
    local name     = config.Name     or "Toggle"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local desc     = config.Description
    local enabled  = default

    local frameHeight = desc and s.Button.HeightWithDesc or s.Button.Height
    local frame = CreateInstance("Frame", { Name = "Toggle_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, frameHeight), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    local nameYOffset = desc and -16 or -10
    CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, nameYOffset), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })

    if desc then
        CreateInstance("TextLabel", { Name = "Description", FontFace = f.Regular, TextColor3 = c.TextDark, Text = desc, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, 2), TextSize = textsize.Tiny, Size = UDim2.new(1, -70, 0, 16), Parent = frame })
    end

    local switchBg = CreateInstance("Frame", { Name = "SwitchBackground", BackgroundColor3 = enabled and c.Toggle.Enabled or c.Toggle.Disabled, Position = UDim2.new(1, -48, 0.5, -10), BorderSizePixel = 0, Size = UDim2.new(0, s.Toggle.Width, 0, s.Toggle.Height), Parent = frame })
    CreateCorner(switchBg, 100)

    local switchCircle = CreateInstance("Frame", { Name = "Circle", BackgroundColor3 = c.Toggle.Circle, AnchorPoint = Vector2.new(0, 0.5), Position = enabled and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, s.Toggle.Circle, 0, s.Toggle.Circle), Parent = switchBg })
    CreateCorner(switchCircle, 100)

    CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = switchCircle })

    local button = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })

    local methods = {}
    methods._children = {}
    methods._frame = frame

    function methods:_UpdateChildren()
        for _, child in ipairs(self._children) do
            if child._frame then
                child._frame.Visible = enabled
            end
        end
    end

    local function UpdateToggle()
        switchBg.BackgroundColor3 = enabled and c.Toggle.Enabled or c.Toggle.Disabled
        switchCircle.Position     = enabled and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        if methods._children and #methods._children > 0 then
            methods:_UpdateChildren()
        end
    end

    button.MouseButton1Click:Connect(function()
        enabled = not enabled
        UpdateToggle()
        callback(enabled)
    end)

    function methods:SetValue(value) enabled = value; UpdateToggle(); callback(enabled) end
    function methods:GetValue() return enabled end
    function methods:SetChildren(children)
        self._children = children
        self:_UpdateChildren()
    end

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Toggle", function() return enabled end, function(v) methods:SetValue(v) end)
    end

    return methods
end

function Library._CreateCheckbox(tab, config)
    local name     = config.Name     or "Checkbox"
    local default  = config.Default  or false
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local enabled  = default

    local frame = CreateInstance("Frame", { Name = "Checkbox_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Button.Height), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })

    local checkBg = CreateInstance("Frame", { Name = "CheckBackground", BackgroundColor3 = enabled and c.Checkbox.Enabled or c.Checkbox.Disabled, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 18, 0, 18), Parent = frame })
    CreateCorner(checkBg, 4)
    local checkStroke = CreateInstance("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = enabled and c.Checkbox.Enabled or c.Checkbox.Border, Thickness = 1.5, Parent = checkBg })

    local button = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = frame })

    local function UpdateCheckbox()
        checkBg.BackgroundColor3 = enabled and c.Checkbox.Enabled or c.Checkbox.Disabled
        checkStroke.Color        = enabled and c.Checkbox.Enabled or c.Checkbox.Border
    end

    button.MouseButton1Click:Connect(function() enabled = not enabled; UpdateCheckbox(); callback(enabled) end)
    button.MouseEnter:Connect(function() if not enabled then checkStroke.Color = Color3.fromRGB(90, 90, 90) end end)
    button.MouseLeave:Connect(function() if not enabled then checkStroke.Color = c.Checkbox.Border end end)

    local methods = {
        SetValue = function(_, value) enabled = value; UpdateCheckbox(); callback(enabled) end,
        GetValue = function() return enabled end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "Checkbox", function() return enabled end, function(v) methods:SetValue(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateRadioGroup(tab, config)
    local name     = config.Name     or "Radio Group"
    local options  = config.Options  or {"Option 1", "Option 2"}
    local default  = config.Default  or options[1]
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local selected = default

    local frame = CreateInstance("Frame", { Name = "RadioGroup_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)
    CreatePadding(frame, 8, 8, 10, 10); CreateListLayout(frame, 5, Enum.SortOrder.LayoutOrder)

    CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, LayoutOrder = 0, TextSize = textsize.Normal, Size = UDim2.new(1, 0, 0, 20), Parent = frame })

    local optionFrames = {}

    local function UpdateRadio()
        for _, data in pairs(optionFrames) do
            local isSelected = data.value == selected
            data.outerRing.BackgroundColor3 = isSelected and c.Accent or c.Secondary
            data.stroke.Color               = isSelected and c.Accent or c.Border
            data.innerDot.Visible           = isSelected
            data.label.TextColor3           = isSelected and c.Text or c.TextDark
        end
    end

    for i, option in ipairs(options) do
        local row = CreateInstance("Frame", { Name = "Option_" .. option, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, Parent = frame })
        local outerRing = CreateInstance("Frame", { BackgroundColor3 = option == selected and c.Accent or c.Secondary, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 16, 0, 16), Parent = row })
        CreateCorner(outerRing, 100)
        local ringStroke = CreateInstance("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = option == selected and c.Accent or c.Border, Thickness = 1.5, Parent = outerRing })
        local innerDot = CreateInstance("Frame", { BackgroundColor3 = c.Background, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 6, 0, 6), Visible = option == selected, Parent = outerRing })
        CreateCorner(innerDot, 100)
        local optLabel = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = option == selected and c.Text or c.TextDark, Text = option, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 26, 0, 0), TextSize = textsize.Small, Size = UDim2.new(1, -26, 1, 0), Parent = row })
        local clickBtn = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = row })
        optionFrames[option] = { value = option, outerRing = outerRing, stroke = ringStroke, innerDot = innerDot, label = optLabel }
        clickBtn.MouseButton1Click:Connect(function() selected = option; UpdateRadio(); callback(selected) end)
        clickBtn.MouseEnter:Connect(function() if selected ~= option then optLabel.TextColor3 = c.Text end end)
        clickBtn.MouseLeave:Connect(function() if selected ~= option then optLabel.TextColor3 = c.TextDark end end)
    end

    local methods = {
        SetValue = function(_, value) selected = value; UpdateRadio(); callback(selected) end,
        GetValue = function() return selected end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "RadioGroup", function() return selected end, function(v) methods:SetValue(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateDropdown(tab, config)
    local name        = config.Name        or "Dropdown"
    local options     = config.Options     or {"Option 1", "Option 2"}
    local default     = config.Default     or options[1]
    local multiSelect = config.MultiSelect or false
    local callback    = config.Callback    or function() end
    local flag        = config.Flag
    local lib         = tab._library
    local expanded    = false
    local selected    = multiSelect and (type(default) == "table" and default or {}) or default

    local frame = CreateInstance("Frame", { Name = "Dropdown_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Dropdown.Height), ClipsDescendants = false, ZIndex = 1, Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 10), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), ZIndex = 1, Parent = frame })

    local selectedDisplay = CreateInstance("Frame", { BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.04, Position = UDim2.new(1, -145, 0, 6), BorderSizePixel = 0, Size = UDim2.new(0, 135, 0, 26), ZIndex = 2, Parent = frame })
    CreateCorner(selectedDisplay, 5); CreateStroke(selectedDisplay)

    local selectedLabel = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = multiSelect and (#selected > 0 and table.concat(selected, ", ") or "None") or tostring(selected), TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, TextSize = textsize.Small, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = selectedDisplay })
    local arrow = CreateInstance("ImageLabel", { Image = "rbxassetid://105558791071013", ImageColor3 = c.TextDark, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0.5, -5), Size = UDim2.new(0, 10, 0, 10), Rotation = 0, ZIndex = 2, Parent = selectedDisplay })

    local searchEnabled    = config.SearchBox ~= false and #options > 5
    local searchHeight     = searchEnabled and 32 or 0
    local maxVisibleOptions = 5
    local totalOptionsHeight = math.min(#options * s.Dropdown.OptionHeight, maxVisibleOptions * s.Dropdown.OptionHeight) + searchHeight

    local optionsContainer = CreateInstance("Frame", { BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.04, Position = UDim2.new(1, -145, 0, 38), BorderSizePixel = 0, Size = UDim2.new(0, 135, 0, totalOptionsHeight), Visible = false, ZIndex = 100, ClipsDescendants = true, Parent = frame })
    CreateCorner(optionsContainer, 5); CreateStroke(optionsContainer)

    local searchBox = nil
    if searchEnabled then
        local searchBg = CreateInstance("Frame", { BackgroundColor3 = c.Background, BackgroundTransparency = 0.3, Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 0, 20), BorderSizePixel = 0, ZIndex = 101, Parent = optionsContainer })
        CreateCorner(searchBg, 4)
        searchBox = CreateInstance("TextBox", { FontFace = f.Regular, TextColor3 = c.Text, PlaceholderText = "Search...", PlaceholderColor3 = c.TextDark, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextSize = textsize.Small, BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 6, 0, 0), ClearTextOnFocus = false, ZIndex = 102, Parent = searchBg })
    end

    local optionsScroll = CreateInstance("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, searchHeight), Size = UDim2.new(1, 0, 1, -searchHeight), CanvasSize = UDim2.new(0, 0, 0, #options * s.Dropdown.OptionHeight), ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60), ZIndex = 100, Parent = optionsContainer })
    CreateListLayout(optionsScroll, 0, Enum.SortOrder.LayoutOrder)

    local function UpdateSelectedText()
        selectedLabel.Text = multiSelect and (#selected > 0 and table.concat(selected, ", ") or "None") or tostring(selected)
    end

    local function CreateOptionButton(option)
        local optionBtn = CreateInstance("TextButton", { Name = option, FontFace = f.Regular, TextColor3 = c.Text, Text = option, BackgroundColor3 = Color3.fromRGB(30, 30, 30), BackgroundTransparency = 1, BorderSizePixel = 0, TextSize = textsize.Small, Size = UDim2.new(1, 0, 0, s.Dropdown.OptionHeight), ZIndex = 100, Parent = optionsScroll })
        optionBtn.MouseEnter:Connect(function() optionBtn.BackgroundTransparency = 0.5 end)
        optionBtn.MouseLeave:Connect(function() optionBtn.BackgroundTransparency = 1 end)
        optionBtn.MouseButton1Click:Connect(function()
            if multiSelect then
                local idx = table.find(selected, option)
                if idx then table.remove(selected, idx) else table.insert(selected, option) end
                UpdateSelectedText(); callback(selected)
            else
                selected = option; UpdateSelectedText(); callback(selected)
                expanded = false; optionsContainer.Visible = false; arrow.Rotation = 0; frame.ZIndex = 1
            end
        end)
        return optionBtn
    end

    for _, option in ipairs(options) do CreateOptionButton(option) end

    if searchBox then
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            local visible = 0
            for _, child in ipairs(optionsScroll:GetChildren()) do
                if child:IsA("TextButton") then
                    child.Visible = query == "" or child.Name:lower():find(query, 1, true) ~= nil
                    if child.Visible then visible = visible + 1 end
                end
            end
            optionsScroll.CanvasSize = UDim2.new(0, 0, 0, visible * s.Dropdown.OptionHeight)
            optionsContainer.Size = UDim2.new(0, 135, 0, math.min(visible * s.Dropdown.OptionHeight, maxVisibleOptions * s.Dropdown.OptionHeight) + searchHeight)
        end)
    end

    local toggleBtn = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = selectedDisplay })

    local function CloseDropdown()
        expanded = false; optionsContainer.Visible = false; arrow.Rotation = 0; frame.ZIndex = 1
        if searchBox then searchBox.Text = "" end
        if Library._activeDropdown == CloseDropdown then Library._activeDropdown = nil end
    end

    toggleBtn.MouseButton1Click:Connect(function()
        if expanded then CloseDropdown()
        else
            if Library._activeDropdown then Library._activeDropdown() end
            expanded = true; optionsContainer.Visible = true; arrow.Rotation = 180; frame.ZIndex = 10
            Library._activeDropdown = CloseDropdown
        end
    end)

    lib._connections["dropdown_outside_" .. tostring(frame)] = ui.InputBegan:Connect(function(input)
        if not expanded then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mPos = input.Position
        local fPos, fSize = optionsContainer.AbsolutePosition, optionsContainer.AbsoluteSize
        local hPos, hSize = frame.AbsolutePosition, frame.AbsoluteSize
        if not (mPos.X >= hPos.X and mPos.X <= hPos.X + hSize.X and mPos.Y >= hPos.Y and mPos.Y <= hPos.Y + hSize.Y)
        and not (mPos.X >= fPos.X and mPos.X <= fPos.X + fSize.X and mPos.Y >= fPos.Y and mPos.Y <= fPos.Y + fSize.Y) then
            CloseDropdown()
        end
    end)

    local methods = {
        SetValue = function(_, value)
            selected = multiSelect and (type(value) == "table" and value or {value}) or value
            UpdateSelectedText(); callback(selected)
        end,
        GetValue = function() return selected end,
        Refresh = function(_, newOptions)
            options = newOptions
            for _, child in ipairs(optionsScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            for _, option in ipairs(options) do CreateOptionButton(option) end
            optionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * s.Dropdown.OptionHeight)
            optionsContainer.Size = UDim2.new(0, 135, 0, math.min(#options * s.Dropdown.OptionHeight, maxVisibleOptions * s.Dropdown.OptionHeight))
        end
    }

    if flag and lib then
        lib:_RegisterConfigElement(flag, "Dropdown", function() return selected end, function(v) methods:SetValue(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateKeybind(tab, config, lib)
    local name         = config.Name         or "Keybind"
    local default      = config.Default      or Enum.KeyCode.F
    local callback     = config.Callback     or function() end
    local linkedToggle = config.Toggle
    local flag         = config.Flag
    local currentKey   = default
    local listening    = false

    local function FireAction()
        if linkedToggle then linkedToggle:SetValue(not linkedToggle:GetValue()) end
        callback(currentKey)
    end

    local frame = CreateInstance("Frame", { Name = "Keybind_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Button.Height), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    local nameLabel = CreateInstance("TextLabel", { Name = "Name", FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })

    local statusDot = nil
    if linkedToggle then
        statusDot = CreateInstance("Frame", { BackgroundColor3 = linkedToggle:GetValue() and c.Accent or c.TextDark, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0, 6, 0, 6), BorderSizePixel = 0, Parent = frame })
        CreateCorner(statusDot, 100)
        nameLabel.Position = UDim2.new(0, 22, 0.5, -10)
        local orig = linkedToggle.SetValue
        linkedToggle.SetValue = function(self, value) orig(self, value); if statusDot then statusDot.BackgroundColor3 = value and c.Accent or c.TextDark end end
    end

    local keybindBox = CreateInstance("Frame", { BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.04, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, 30, 0, 26), Parent = frame })
    CreateCorner(keybindBox, 5); CreateStroke(keybindBox)

    local keyLabel = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = currentKey.Name, BackgroundTransparency = 1, TextSize = textsize.Normal, Size = UDim2.new(1, 0, 1, 0), Parent = keybindBox })
    local button   = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = keybindBox })

    local keybindId = name .. "_" .. tostring(tick())
    lib._keybinds[keybindId] = { key = currentKey, callback = FireAction }

    local shortNames = {
        MouseButton1 = "M1", MouseButton2 = "M2",
        RightControl = "RCtrl", LeftControl = "LCtrl",
        RightShift = "RShift", LeftShift = "LShift",
        RightAlt = "RAlt", LeftAlt = "LAlt",
    }

    local function UpdateKeyDisplay()
        if listening then
            keyLabel.Text = "..."
            keybindBox.Size = UDim2.new(0, 43, 0, 26)
        else
            local keyName = currentKey.Name
            local displayName = shortNames[keyName] or keyName
            keybindBox.Size = UDim2.new(0, math.max(#displayName * 9 + 10, 24), 0, 26)
            keyLabel.Text = displayName
        end
    end

    button.MouseButton1Click:Connect(function()
        listening = true
        UpdateKeyDisplay()
        task.wait(0.2)
    end)

    local inputConnection = ui.InputBegan:Connect(function(input, gameProcessed)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local ignore = { [Enum.KeyCode.LeftShift]=true, [Enum.KeyCode.RightShift]=true, [Enum.KeyCode.LeftControl]=true, [Enum.KeyCode.RightControl]=true, [Enum.KeyCode.LeftAlt]=true, [Enum.KeyCode.RightAlt]=true, [Enum.KeyCode.LeftMeta]=true, [Enum.KeyCode.RightMeta]=true }
                if not ignore[input.KeyCode] then
                    currentKey = input.KeyCode; listening = false
                    lib._keybinds[keybindId].key = currentKey; UpdateKeyDisplay()
                end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2 then
                currentKey = input.UserInputType; listening = false
                lib._keybinds[keybindId].key = currentKey; UpdateKeyDisplay()
            end
            return
        end
        if gameProcessed then return end
    end)

    lib._connections["keybind_" .. keybindId] = inputConnection
    UpdateKeyDisplay()

    local methods = {
        SetKey = function(_, keyCode) currentKey = keyCode; lib._keybinds[keybindId].key = currentKey; UpdateKeyDisplay() end,
        GetKey = function() return currentKey end
    }

    if flag and lib then
        lib:_RegisterConfigElement(flag, "Keybind", function() return currentKey end, function(v) methods:SetKey(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateColorPicker(tab, config)
    local name     = config.Name     or "Color Picker"
    local default  = config.Default  or Color3.fromRGB(255, 255, 255)
    local callback = config.Callback or function() end
    local flag     = config.Flag
    local currentColor = default
    local hue, sat, val = currentColor:ToHSV()
    local expanded = false

    local frame = CreateInstance("Frame", { Name = "ColorPicker_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Button.Height), Parent = tab.content })
    CreateCorner(frame, 6); CreateStroke(frame)

    CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), TextSize = textsize.Normal, Size = UDim2.new(1, -50, 1, 0), Parent = frame })

    local colorPreview = CreateInstance("Frame", { BackgroundColor3 = currentColor, Position = UDim2.new(1, -45, 0.5, -8), Size = UDim2.new(0, 35, 0, 16), ZIndex = 2, Parent = frame })
    CreateCorner(colorPreview, 4); CreateStroke(colorPreview)

    local previewBtn = CreateInstance("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 3, Parent = colorPreview })

    local pickerContainer = CreateInstance("Frame", { BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0, Size = UDim2.new(0, 160, 0, 115), Visible = false, ZIndex = 3000, Parent = tab.content:FindFirstAncestorOfClass("ScreenGui") or tab.content })
    CreateCorner(pickerContainer, 6)
    CreateInstance("UIStroke", { Color = Color3.fromRGB(40, 40, 40), Thickness = 1, Parent = pickerContainer })

    local svPicker = CreateInstance("Frame", { BackgroundColor3 = Color3.fromHSV(hue, 1, 1), Position = UDim2.new(0, 8, 0, 8), Size = UDim2.new(1, -16, 0, 85), ZIndex = 3001, Parent = pickerContainer })
    CreateCorner(svPicker, 4)

    local whiteLayer = CreateInstance("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), ZIndex = 3002, Parent = svPicker })
    CreateCorner(whiteLayer, 4)
    CreateInstance("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1)), Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Parent = whiteLayer })

    local blackLayer = CreateInstance("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), ZIndex = 3003, Parent = svPicker })
    CreateCorner(blackLayer, 4)
    CreateInstance("UIGradient", { Color = ColorSequence.new(Color3.new(0,0,0)), Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}), Parent = blackLayer })

    local svCursor = CreateInstance("Frame", { BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(sat,0,1-val,0), Size = UDim2.new(0,10,0,10), ZIndex = 3005, Parent = svPicker })
    CreateInstance("UIStroke", { Thickness = 1.5, Color = Color3.new(1,1,1), Parent = svCursor }); CreateCorner(svCursor, 100)

    local hueSlider = CreateInstance("Frame", { Position = UDim2.new(0,8,0,98), Size = UDim2.new(1,-16,0,8), ZIndex = 3001, Parent = pickerContainer })
    CreateCorner(hueSlider, 100)
    CreateInstance("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)), ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167,1,1)), ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333,1,1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)), ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667,1,1)), ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833,1,1)), ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)) }), Parent = hueSlider })

    local hueCursor = CreateInstance("Frame", { BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(hue,0,0.5,0), Size = UDim2.new(0,10,0,10), ZIndex = 3005, Parent = hueSlider })
    CreateCorner(hueCursor, 100)
    CreateInstance("UIStroke", { Thickness = 1, Color = Color3.fromRGB(20,20,20), Parent = hueCursor })

    local function UpdateColor()
        currentColor = Color3.fromHSV(hue, sat, val)
        colorPreview.BackgroundColor3 = currentColor
        svPicker.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
        hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)
        callback(currentColor)
    end

    local svDragging, hueDragging = false, false
    local function ProcessInput(input)
        if not pickerContainer.Visible then return end
        if svDragging then
            sat = math.clamp((input.Position.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1)
            val = 1 - math.clamp((input.Position.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1)
            UpdateColor()
        elseif hueDragging then
            hue = math.clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
            UpdateColor()
        end
    end

    svPicker.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = true; ProcessInput(input); Library._activeDragger = ProcessInput end end)
    hueSlider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then hueDragging = true; ProcessInput(input); Library._activeDragger = ProcessInput end end)
    ui.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then svDragging = false; hueDragging = false; Library._activeDragger = nil end end)

    local function ClosePicker()
        pickerContainer.Visible = false; expanded = false
        if Library.ActivePicker == ClosePicker then Library.ActivePicker = nil end
    end

    previewBtn.MouseButton1Click:Connect(function()
        if expanded then ClosePicker()
        else
            if Library.ActivePicker then Library.ActivePicker() end
            Library.ActivePicker = ClosePicker
            local btnPos = colorPreview.AbsolutePosition
            local viewport = workspace.CurrentCamera.ViewportSize
            local tx = math.max(0, btnPos.X - 170)
            local ty = math.min(btnPos.Y, viewport.Y - 125)
            pickerContainer.Position = UDim2.new(0, tx, 0, ty)
            pickerContainer.Visible = true; expanded = true
        end
    end)

    local methods = {
        SetColor = function(_, color) currentColor = color; hue, sat, val = color:ToHSV(); UpdateColor() end,
        GetColor = function() return currentColor end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "ColorPicker", function() return currentColor end, function(v) methods:SetColor(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateTextBox(tab, config)
    local name        = config.Name        or "TextBox"
    local default     = config.Default     or ""
    local placeholder = config.Placeholder or "Enter text..."
    local callback    = config.Callback    or function() end
    local clearOnFocus = config.ClearOnFocus or false
    local numbersOnly  = config.NumbersOnly  or false
    local flag         = config.Flag
    local currentText  = default

    local frame = CreateInstance("Frame", { Name = "TextBox_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.TextBox.Height), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0.5, -10), TextSize = textsize.Normal, Size = UDim2.new(0, 150, 0, 20), Parent = frame })

    local icon = CreateInstance("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://93828793199781", ImageColor3 = c.TextDark, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -165, 0.5, 0), Size = UDim2.new(0, 18, 0, 18), Parent = frame })

    local textBoxContainer = CreateInstance("Frame", { BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.04, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), BorderSizePixel = 0, Size = UDim2.new(0, s.TextBox.InputWidth, 0, 26), Parent = frame })
    CreateCorner(textBoxContainer, 5)
    local textBoxStroke = CreateStroke(textBoxContainer)

    local textBox = CreateInstance("TextBox", { FontFace = f.Regular, TextColor3 = c.Text, PlaceholderText = placeholder, PlaceholderColor3 = c.TextDark, Text = currentText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, TextSize = textsize.Small, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), ClearTextOnFocus = clearOnFocus, Parent = textBoxContainer })

    textBox.Focused:Connect(function() textBoxContainer.BackgroundTransparency = 0; textBoxStroke.Color = c.Accent; icon.ImageColor3 = c.Text end)
    textBox.FocusLost:Connect(function(enterPressed)
        textBoxContainer.BackgroundTransparency = 0.04; textBoxStroke.Color = c.Border; icon.ImageColor3 = c.TextDark
        if numbersOnly then
            local numValue = tonumber(textBox.Text)
            textBox.Text = numValue and tostring(numValue) or currentText
            currentText = textBox.Text
        else
            currentText = textBox.Text
        end
        callback(currentText, enterPressed)
    end)

    if numbersOnly then
        textBox:GetPropertyChangedSignal("Text"):Connect(function()
            local filtered = textBox.Text:gsub("[^%d%.%-]", "")
            if textBox.Text ~= filtered then textBox.Text = filtered end
        end)
    end

    local methods = {
        SetText       = function(_, t) currentText = tostring(t); textBox.Text = currentText end,
        GetText       = function() return currentText end,
        SetPlaceholder = function(_, p) textBox.PlaceholderText = p end,
        Focus         = function() textBox:CaptureFocus() end
    }

    if flag and tab._library then
        tab._library:_RegisterConfigElement(flag, "TextBox", function() return currentText end, function(v) methods:SetText(v) end)
    end

    methods._frame = frame
    return methods
end

function Library._CreateProgressBar(tab, config)
    local name    = config.Name    or "Progress"
    local min     = config.Min     or 0
    local max     = config.Max     or 100
    local default = config.Default or 0
    local suffix  = config.Suffix  or ""
    local current = math.clamp(default, min, max)

    local frame = CreateInstance("Frame", { Name = "ProgressBar_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, s.Slider.Height), Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), TextSize = textsize.Normal, Size = UDim2.new(0, 200, 0, 20), Parent = frame })
    local valueLabel = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.TextDark, Text = tostring(current) .. suffix, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 5), TextSize = textsize.Normal, Size = UDim2.new(0, 50, 0, 20), Parent = frame })

    local trackBg = CreateInstance("Frame", { BackgroundColor3 = Color3.fromRGB(11, 11, 11), Position = UDim2.new(0, 10, 0, 29), BorderSizePixel = 0, Size = UDim2.new(1, -20, 0, 7), Parent = frame })
    CreateCorner(trackBg, 100)

    local fill = CreateInstance("Frame", { BackgroundColor3 = c.Accent, BorderSizePixel = 0, Size = UDim2.new((max - min) > 0 and (current - min) / (max - min) or 0, 0, 1, 0), Parent = trackBg })
    CreateCorner(fill, 100)

    local function Refresh(value)
        current = math.clamp(value, min, max)
        fill.Size = UDim2.new((max - min) > 0 and (current - min) / (max - min) or 0, 0, 1, 0)
        valueLabel.Text = tostring(current) .. suffix
    end

    return {
        SetValue = function(_, v) Refresh(v) end,
        GetValue = function() return current end,
        SetMax   = function(_, v) max = v; Refresh(current) end,
        SetMin   = function(_, v) min = v; Refresh(current) end,
        _frame   = frame
    }
end

function Library._CreateTable(tab, config)
    local name       = config.Name       or "Table"
    local columns    = config.Columns    or {"Name", "Value"}
    local rowHeight  = config.RowHeight  or 28
    local maxVisible = config.MaxVisible or 6
    local data       = {}
    local colCount   = #columns

    local frame = CreateInstance("Frame", { Name = "Table_" .. name, BackgroundColor3 = c.Secondary, BackgroundTransparency = 0.4, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true, Parent = tab.content })
    CreateCorner(frame, 5); CreateStroke(frame)

    local titleLabel = CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = name, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 6), TextSize = textsize.Normal, Size = UDim2.new(1, -20, 0, 20), Parent = frame })

    local headerRow = CreateInstance("Frame", { BackgroundColor3 = c.Background, BackgroundTransparency = 0.2, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 0, 26), Parent = frame })
    for i, col in ipairs(columns) do
        local xPos = (i - 1) / colCount
        CreateInstance("TextLabel", { FontFace = f.Bold, TextColor3 = c.TextDark, Text = col, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.new(xPos, i == 1 and 10 or 4, 0, 0), Size = UDim2.new(1 / colCount, i == 1 and -10 or -4, 1, 0), TextSize = textsize.Small, Parent = headerRow })
    end

    CreateInstance("Frame", { BackgroundColor3 = c.Border, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 56), Size = UDim2.new(1, 0, 0, 1), Parent = frame })

    local bodyScroll = CreateInstance("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 57), Size = UDim2.new(1, 0, 0, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = frame })
    CreateListLayout(bodyScroll, 0, Enum.SortOrder.LayoutOrder)

    local rowFrames = {}

    local function RefreshHeight()
        local h = math.min(#data, maxVisible) * rowHeight
        bodyScroll.Size = UDim2.new(1, 0, 0, h)
        bodyScroll.CanvasSize = UDim2.new(0, 0, 0, #data * rowHeight)
        frame.Size = UDim2.new(1, 0, 0, 57 + h + (h > 0 and 6 or 0))
    end

    local function MakeRowFrame(idx, rowData)
        local isEven = idx % 2 == 0
        local rowFrame = CreateInstance("Frame", { Name = "Row_" .. idx, BackgroundColor3 = isEven and c.Background or c.Secondary, BackgroundTransparency = isEven and 0.5 or 0.8, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, rowHeight), LayoutOrder = idx, Parent = bodyScroll })
        for i = 1, colCount do
            CreateInstance("TextLabel", { FontFace = f.Regular, TextColor3 = c.Text, Text = tostring(rowData[i] or ""), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1, Position = UDim2.new((i-1)/colCount, i==1 and 10 or 4, 0, 0), Size = UDim2.new(1/colCount, i==1 and -10 or -4, 1, 0), TextSize = textsize.Small, Parent = rowFrame })
        end
        return rowFrame
    end

    local function RenderRows()
        for _, r in ipairs(rowFrames) do if r and r.Parent then r:Destroy() end end
        rowFrames = {}
        for idx, rowData in ipairs(data) do table.insert(rowFrames, MakeRowFrame(idx, rowData)) end
        RefreshHeight()
    end

    RefreshHeight()

    return {
        AddRow    = function(_, rowData) table.insert(data, rowData); table.insert(rowFrames, MakeRowFrame(#data, rowData)); RefreshHeight() end,
        RemoveRow = function(_, index) if index >= 1 and index <= #data then table.remove(data, index); RenderRows() end end,
        ClearRows = function(_) data = {}; RenderRows() end,
        SetData   = function(_, newData) data = newData; RenderRows() end,
        GetData   = function() return data end,
        SetTitle  = function(_, text) titleLabel.Text = text end
    }
end

function Library._CreateConfigSection(tab)
    local lib = tab._library
    Library._CreateContentSection(tab, "Configuration")

    local configNameBox = Library._CreateTextBox(tab, {
        Name = "Config Name", Default = "default", Placeholder = "Enter config name...",
        Callback = function(text) lib._currentConfig = text end
    })

    local configDropdown
    configDropdown = Library._CreateDropdown(tab, {
        Name = "Select Config", Options = lib:GetConfigs(), Default = "default",
        Callback = function(selected) configNameBox:SetText(selected); lib._currentConfig = selected end
    })

    Library._CreateButton(tab, { Name = "Save Config",    Callback = function() local n = configNameBox:GetText(); if n ~= "" then lib:SaveConfig(n); configDropdown:Refresh(lib:GetConfigs()) end end })
    Library._CreateButton(tab, { Name = "Load Config",    Callback = function() local n = configNameBox:GetText(); if n ~= "" then lib:LoadConfig(n) end end })
    Library._CreateButton(tab, { Name = "Delete Config",  Callback = function() local n = configNameBox:GetText(); if n ~= "" then lib:DeleteConfig(n); configDropdown:Refresh(lib:GetConfigs()) end end })
    Library._CreateButton(tab, { Name = "Refresh Configs", Callback = function() configDropdown:Refresh(lib:GetConfigs()); lib:Notify({ Title = "Configs Refreshed", Description = "Config list updated", Duration = 2, Icon = "rbxassetid://10723356507" }) end })
    Library._CreateToggle(tab, { Name = "Auto Save", Default = false, Callback = function(enabled) lib:SetAutoSave(enabled) end })

    return { RefreshConfigs = function() configDropdown:Refresh(lib:GetConfigs()) end }
end

return Library
