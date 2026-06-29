-- Theme: shared UI design system.
-- Require this in any UI script to get consistent colors, fonts, and builder helpers.

local Theme = {}

-- ─── Color palette ────────────────────────────────────────────────────────────
Theme.Colors = {
    -- Backgrounds
    BG          = Color3.fromRGB(10,  13,  20),   -- page background
    Surface     = Color3.fromRGB(16,  21,  32),   -- cards, panels
    Surface2    = Color3.fromRGB(22,  30,  44),   -- elevated surfaces
    Surface3    = Color3.fromRGB(30,  40,  58),   -- hover / selected

    -- Accents
    Primary     = Color3.fromRGB(255, 184,  0),   -- gold / amber (main CTA)
    PrimaryDark = Color3.fromRGB(200, 140,  0),
    PrimaryText = Color3.fromRGB(10,   10,  10),  -- text on primary buttons

    -- Status
    Success     = Color3.fromRGB( 46, 175,  80),
    Danger      = Color3.fromRGB(218,  54,  51),
    Warning     = Color3.fromRGB(210, 153,  34),
    Info        = Color3.fromRGB( 58, 130, 247),

    -- Text
    Text        = Color3.fromRGB(240, 246, 252),
    TextMuted   = Color3.fromRGB(139, 148, 158),
    TextSubtle  = Color3.fromRGB( 80,  90, 110),

    -- Borders
    Border      = Color3.fromRGB( 40,  52,  72),
    BorderBright = Color3.fromRGB(60,  80, 110),

    -- Specific
    XPBar       = Color3.fromRGB(255, 184,   0),
    HealthFull  = Color3.fromRGB( 46, 175,  80),
    HealthLow   = Color3.fromRGB(218,  54,  51),
    FuelFull    = Color3.fromRGB( 46, 175,  80),
    FuelLow     = Color3.fromRGB(218,  54,  51),
    AmmoText    = Color3.fromRGB(240, 246, 252),
    CompassText = Color3.fromRGB(180, 200, 220),
}

-- ─── Fonts ────────────────────────────────────────────────────────────────────
Theme.Fonts = {
    Bold    = Enum.Font.GothamBold,
    Medium  = Enum.Font.GothamMedium,
    Regular = Enum.Font.Gotham,
    Mono    = Enum.Font.RobotoMono,
}

-- ─── Sizing ───────────────────────────────────────────────────────────────────
Theme.Radius = {
    Sm  = UDim.new(0, 4),
    Md  = UDim.new(0, 8),
    Lg  = UDim.new(0, 12),
    Xl  = UDim.new(0, 16),
    Full = UDim.new(1, 0),
}

-- ─── Builder helpers ──────────────────────────────────────────────────────────

function Theme.Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Theme.Radius.Md
    c.Parent = parent
    return c
end

function Theme.Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or Theme.Colors.Border
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

function Theme.Gradient(parent, colorA, colorB, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(colorA or Theme.Colors.Surface2, colorB or Theme.Colors.Surface)
    g.Rotation = rotation or 90
    g.Parent   = parent
    return g
end

function Theme.Padding(parent, all, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    if all then
        p.PaddingTop    = UDim.new(0, all)
        p.PaddingRight  = UDim.new(0, all)
        p.PaddingBottom = UDim.new(0, all)
        p.PaddingLeft   = UDim.new(0, all)
    else
        p.PaddingTop    = UDim.new(0, top    or 0)
        p.PaddingRight  = UDim.new(0, right  or 0)
        p.PaddingBottom = UDim.new(0, bottom or 0)
        p.PaddingLeft   = UDim.new(0, left   or 0)
    end
    p.Parent = parent
    return p
end

function Theme.ListLayout(parent, dir, padding, align)
    local l = Instance.new("UIListLayout")
    l.FillDirection  = dir    or Enum.FillDirection.Vertical
    l.Padding        = UDim.new(0, padding or 6)
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    l.Parent         = parent
    return l
end

-- ─── Component builders ───────────────────────────────────────────────────────

-- Base Frame
function Theme.Frame(parent, name, size, pos, color, transparency)
    local f = Instance.new("Frame")
    f.Name                   = name or "Frame"
    f.Size                   = size or UDim2.new(1, 0, 1, 0)
    f.Position               = pos  or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3       = color or Theme.Colors.Surface
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel        = 0
    f.Parent                 = parent
    return f
end

-- Text label
function Theme.Label(parent, name, text, size, pos, color, fontSize, font, align)
    local l = Instance.new("TextLabel")
    l.Name                   = name or "Label"
    l.Size                   = size or UDim2.new(1, 0, 0, 20)
    l.Position               = pos  or UDim2.new(0, 0, 0, 0)
    l.Text                   = text or ""
    l.TextColor3             = color or Theme.Colors.Text
    l.TextSize               = fontSize or 14
    l.Font                   = font  or Theme.Fonts.Regular
    l.BackgroundTransparency = 1
    l.TextXAlignment         = align or Enum.TextXAlignment.Left
    l.TextWrapped            = true
    l.BorderSizePixel        = 0
    l.Parent                 = parent
    return l
end

-- Button
function Theme.Button(parent, name, text, size, pos, style)
    style = style or "primary"
    local colors = {
        primary  = { bg = Theme.Colors.Primary,  text = Theme.Colors.PrimaryText },
        danger   = { bg = Theme.Colors.Danger,   text = Theme.Colors.Text },
        ghost    = { bg = Theme.Colors.Surface3, text = Theme.Colors.Text },
        success  = { bg = Theme.Colors.Success,  text = Theme.Colors.Text },
        muted    = { bg = Theme.Colors.Surface2, text = Theme.Colors.TextMuted },
    }
    local c = colors[style] or colors.primary

    local btn = Instance.new("TextButton")
    btn.Name             = name or "Button"
    btn.Size             = size or UDim2.new(0, 100, 0, 32)
    btn.Position         = pos  or UDim2.new(0, 0, 0, 0)
    btn.Text             = text or "Button"
    btn.TextColor3       = c.text
    btn.BackgroundColor3 = c.bg
    btn.Font             = Theme.Fonts.Bold
    btn.TextSize         = 13
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Parent           = parent

    Theme.Corner(btn, Theme.Radius.Sm)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.12)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = c.bg
    end)

    return btn
end

-- Divider line
function Theme.Divider(parent, vertical)
    local d = Instance.new("Frame")
    d.Name                   = "Divider"
    d.BackgroundColor3       = Theme.Colors.Border
    d.BorderSizePixel        = 0
    d.Size                   = vertical
        and UDim2.new(0, 1, 1, 0)
        or  UDim2.new(1, 0, 0, 1)
    d.Parent                 = parent
    return d
end

-- Badge/tag
function Theme.Badge(parent, text, color)
    local bg = Theme.Frame(parent, "Badge",
        UDim2.new(0, 0, 0, 20), nil,
        color or Theme.Colors.Primary, 0)
    bg.AutomaticSize = Enum.AutomaticSize.X
    Theme.Corner(bg, Theme.Radius.Sm)
    Theme.Padding(bg, nil, 0, 8, 0, 8)

    Theme.Label(bg, "BadgeText", text,
        UDim2.new(1, 0, 1, 0), nil,
        Theme.Colors.PrimaryText, 11, Theme.Fonts.Bold,
        Enum.TextXAlignment.Center)

    return bg
end

-- Screen root
function Theme.Screen(name, displayOrder)
    local sg = Instance.new("ScreenGui")
    sg.Name             = name
    sg.ResetOnSpawn     = false
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset   = true
    sg.DisplayOrder     = displayOrder or 10
    sg.Enabled          = false
    return sg
end

-- ScrollFrame with no ugly bar
function Theme.Scroll(parent, name, size, pos)
    local sf = Instance.new("ScrollingFrame")
    sf.Name                   = name or "Scroll"
    sf.Size                   = size or UDim2.new(1, 0, 1, 0)
    sf.Position               = pos  or UDim2.new(0, 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel        = 0
    sf.ScrollBarThickness     = 4
    sf.ScrollBarImageColor3   = Theme.Colors.Border
    sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    sf.Parent                 = parent
    return sf
end

-- Input box
function Theme.Input(parent, name, placeholder, size, pos)
    local box = Instance.new("TextBox")
    box.Name                   = name or "Input"
    box.Size                   = size or UDim2.new(1, 0, 0, 34)
    box.Position               = pos  or UDim2.new(0, 0, 0, 0)
    box.PlaceholderText        = placeholder or ""
    box.Text                   = ""
    box.TextColor3             = Theme.Colors.Text
    box.PlaceholderColor3      = Theme.Colors.TextSubtle
    box.BackgroundColor3       = Theme.Colors.Surface3
    box.Font                   = Theme.Fonts.Regular
    box.TextSize               = 14
    box.ClearTextOnFocus       = false
    box.BorderSizePixel        = 0
    box.TextXAlignment         = Enum.TextXAlignment.Left
    box.Parent                 = parent

    Theme.Corner(box, Theme.Radius.Sm)
    Theme.Stroke(box, Theme.Colors.Border)
    Theme.Padding(box, nil, 0, 10, 0, 10)

    return box
end

return Theme
