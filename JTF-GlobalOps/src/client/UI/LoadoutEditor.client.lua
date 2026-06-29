-- LoadoutEditor.client.lua — weapon & equipment selection screen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local shared  = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme   = require(shared:WaitForChild("Theme"))
local Remotes = require(shared:WaitForChild("Remotes"))
local WepCfg  = require(shared:WaitForChild("Config"):WaitForChild("WeaponConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("LoadoutEditor", 8)
sg.Enabled = false
sg.Parent  = PlayerGui

local root = Theme.Frame(sg, "Root",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), Theme.Colors.BG)

-- Header
local header = Theme.Frame(root, "Header",
    UDim2.new(1, 0, 0, 52), nil, Theme.Colors.Surface)
Theme.Frame(header, "Gold", UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), Theme.Colors.Primary)
Theme.Label(header, "Title", "LOADOUT EDITOR",
    UDim2.new(1, -120, 1, 0), UDim2.new(0, 24, 0, 0),
    Theme.Colors.Primary, 16, Theme.Fonts.Bold)

local closeBtn = Theme.Button(header, "Close", "✕ Back",
    UDim2.new(0, 88, 0, 32),
    UDim2.new(1, -100, 0.5, -16), "ghost")
closeBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
    local mm = PlayerGui:FindFirstChild("MainMenu")
    if mm then mm.Enabled = true end
end)

-- Content
local content = Theme.Frame(root, "Content",
    UDim2.new(1, -48, 1, -88),
    UDim2.new(0, 24, 0, 60),
    Color3.new(0,0,0), 1)

-- ─── Left: slot tabs ──────────────────────────────────────────────────────────
local slotPanel = Theme.Frame(content, "SlotPanel",
    UDim2.new(0, 200, 1, 0), nil, Color3.new(0,0,0), 1)
Theme.Label(slotPanel, "SlotTitle", "EQUIPMENT SLOTS",
    UDim2.new(1,0,0,22), nil, Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local slotScroll = Theme.Scroll(slotPanel, "SlotScroll",
    UDim2.new(1, 0, 1, -30), UDim2.new(0,0,0,28))
Theme.ListLayout(slotScroll, Enum.FillDirection.Vertical, 6)

-- ─── Center: weapon list ──────────────────────────────────────────────────────
local weaponPanel = Theme.Frame(content, "WeaponPanel",
    UDim2.new(1, -450, 1, 0),
    UDim2.new(0, 216, 0, 0),
    Color3.new(0,0,0), 1)
Theme.Label(weaponPanel, "WTitle", "WEAPONS",
    UDim2.new(1,0,0,22), nil, Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local weaponScroll = Theme.Scroll(weaponPanel, "WeaponScroll",
    UDim2.new(1, 0, 1, -30), UDim2.new(0,0,0,28))
Theme.ListLayout(weaponScroll, Enum.FillDirection.Vertical, 6)

-- ─── Right: stats + attachments ───────────────────────────────────────────────
local statsPanel = Theme.Frame(content, "StatsPanel",
    UDim2.new(0, 224, 1, 0),
    UDim2.new(1, -224, 0, 0),
    Theme.Colors.Surface)
Theme.Corner(statsPanel, Theme.Radius.Md)
Theme.Stroke(statsPanel, Theme.Colors.Border)
Theme.Padding(statsPanel, 14)

local statsNameLbl = Theme.Label(statsPanel, "WepName", "SELECT A WEAPON",
    UDim2.new(1,0,0,26), nil, Theme.Colors.Text, 16, Theme.Fonts.Bold)
local statsCatLbl  = Theme.Label(statsPanel, "WepCat", "",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,28),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Regular)

-- Stat bars
local statsBars = Theme.Frame(statsPanel, "StatBars",
    UDim2.new(1,0,0,136), UDim2.new(0,0,0,54),
    Color3.new(0,0,0), 1)
Theme.ListLayout(statsBars, Enum.FillDirection.Vertical, 6)

local STAT_DEFS = {
    { key = "damage",   label = "DAMAGE",    max = 140 },
    { key = "range",    label = "RANGE",     max = 1800 },
    { key = "fireRate", label = "FIRE RATE", max = 15 },
    { key = "magSize",  label = "MAG SIZE",  max = 200 },
}

local statBarRefs = {}
for _, s in ipairs(STAT_DEFS) do
    local row = Theme.Frame(statsBars, s.key .. "Row",
        UDim2.new(1,0,0,24), nil, Color3.new(0,0,0), 1)

    Theme.Label(row, "Lbl", s.label,
        UDim2.new(0,72,1,0), nil,
        Theme.Colors.TextMuted, 9, Theme.Fonts.Bold)

    local track = Theme.Frame(row, "Track",
        UDim2.new(1,-100,0,8),
        UDim2.new(0,80,0.5,-4),
        Theme.Colors.Surface3)
    Theme.Corner(track, Theme.Radius.Full)

    local fill = Theme.Frame(track, "Fill",
        UDim2.new(0,0,1,0), nil, Theme.Colors.Primary)
    Theme.Corner(fill, Theme.Radius.Full)

    local valLbl = Theme.Label(row, "Val", "--",
        UDim2.new(0,24,1,0), UDim2.new(1,-24,0,0),
        Theme.Colors.TextMuted, 9, Theme.Fonts.Regular,
        Enum.TextXAlignment.Right)

    statBarRefs[s.key] = { fill = fill, val = valLbl, max = s.max }
end

-- Divider + attachments
local divLine = Theme.Divider(statsPanel)
divLine.Position = UDim2.new(0,-14,0,198)
divLine.Size     = UDim2.new(1,28,0,1)

Theme.Label(statsPanel, "AttachTitle", "ATTACHMENT SLOTS",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,206),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local attachScroll = Theme.Scroll(statsPanel, "AttachScroll",
    UDim2.new(1,0,1,-270), UDim2.new(0,0,0,228))
Theme.ListLayout(attachScroll, Enum.FillDirection.Vertical, 4)

-- Equip button pinned at bottom
local saveBtn = Theme.Button(statsPanel, "Save", "✔ EQUIP & SAVE",
    UDim2.new(1,0,0,36), UDim2.new(0,0,1,-36), "primary")
saveBtn.TextSize = 13

-- Status bar
local statusBar = Theme.Frame(root, "Status",
    UDim2.new(1,0,0,36), UDim2.new(0,0,1,-36), Theme.Colors.Surface)
local statusLbl = Theme.Label(statusBar, "Msg", "",
    UDim2.new(1,-24,1,0), UDim2.new(0,16,0,0),
    Theme.Colors.TextMuted, 12, Theme.Fonts.Regular)

local function setStatus(msg, isOk)
    statusLbl.Text       = msg
    statusLbl.TextColor3 = isOk and Theme.Colors.Success or Theme.Colors.Danger
    task.delay(4, function() statusLbl.Text = "" end)
end

-- ─── Slot definitions ─────────────────────────────────────────────────────────
local SLOTS = {
    { id = "Primary",   label = "PRIMARY",   icon = "⚔",
      categories = { AssaultRifle = true, LMG = true, SniperRifle = true, Shotgun = true } },
    { id = "Secondary", label = "SECONDARY", icon = "🔫",
      categories = { Pistol = true } },
    { id = "Throwable", label = "THROWABLE", icon = "💣",
      categories = { Thrown = true } },
}

local CAT_COLOR = {
    AssaultRifle = Color3.fromRGB( 58, 130, 247),
    LMG          = Color3.fromRGB(200, 140,  40),
    SniperRifle  = Color3.fromRGB(218,  54,  51),
    Shotgun      = Color3.fromRGB(180, 100,  40),
    Pistol       = Color3.fromRGB( 46, 175,  80),
    Thrown       = Color3.fromRGB(160,  80, 160),
}

local selectedWeapons = { Primary = nil, Secondary = nil, Throwable = nil }
local currentSlot     = "Primary"
local slotBtnRefs     = {}

-- ─── Stats panel ─────────────────────────────────────────────────────────────

local currentSlotDef = nil

local function updateStats(weaponId)
    local cfg = WepCfg.Weapons[weaponId]
    if not cfg then return end

    statsNameLbl.Text = cfg.displayName or weaponId
    statsCatLbl.Text  = cfg.category or ""

    for _, s in ipairs(STAT_DEFS) do
        local ref = statBarRefs[s.key]
        local val = cfg[s.key] or 0
        local pct = math.clamp(val / ref.max, 0, 1)
        TweenService:Create(ref.fill,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad),
            { Size = UDim2.new(pct, 0, 1, 0) }
        ):Play()
        ref.val.Text = tostring(math.floor(val))
    end

    -- Rebuild attachment rows
    for _, c in ipairs(attachScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local slots = cfg.attachSlots
    if slots and #slots > 0 then
        for _, slotName in ipairs(slots) do
            local row = Theme.Frame(attachScroll, slotName .. "Row",
                UDim2.new(1,0,0,36), nil, Theme.Colors.Surface2)
            Theme.Corner(row, Theme.Radius.Sm)
            Theme.Padding(row, nil, 0, 10, 0, 10)

            Theme.Label(row, "SlotName", slotName,
                UDim2.new(0.5,0,1,0), nil,
                Theme.Colors.TextMuted, 11, Theme.Fonts.Bold)

            Theme.Label(row, "SlotVal", "Default",
                UDim2.new(0.5,0,1,0), UDim2.new(0.5,0,0,0),
                Theme.Colors.Text, 11, Theme.Fonts.Regular,
                Enum.TextXAlignment.Right)
        end
    else
        Theme.Label(attachScroll, "NoAttach", "No attachment slots",
            UDim2.new(1,0,0,30), nil,
            Theme.Colors.TextSubtle, 11, Theme.Fonts.Regular)
    end
end

local function clearStats()
    statsNameLbl.Text = "SELECT A WEAPON"
    statsCatLbl.Text  = ""
    for _, s in ipairs(STAT_DEFS) do
        local ref = statBarRefs[s.key]
        TweenService:Create(ref.fill,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad),
            { Size = UDim2.new(0, 0, 1, 0) }
        ):Play()
        ref.val.Text = "--"
    end
    for _, c in ipairs(attachScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

-- ─── Weapon list ──────────────────────────────────────────────────────────────

local function buildWeaponList(slotDef)
    for _, c in ipairs(weaponScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local order = 1
    for weaponId, cfg in pairs(WepCfg.Weapons) do
        if slotDef.categories[cfg.category] then
            local isEquipped = (selectedWeapons[slotDef.id] == weaponId)

            local card = Theme.Frame(weaponScroll, weaponId .. "Card",
                UDim2.new(1,-4,0,58), nil,
                isEquipped and Theme.Colors.Surface3 or Theme.Colors.Surface)
            card.LayoutOrder = order
            Theme.Corner(card, Theme.Radius.Md)
            Theme.Stroke(card, isEquipped and Theme.Colors.Primary or Theme.Colors.Border)

            local stripeColor = CAT_COLOR[cfg.category] or Theme.Colors.TextSubtle
            local stripe = Theme.Frame(card, "Stripe",
                UDim2.new(0,4,1,-12), UDim2.new(0,0,0,6), stripeColor)
            Theme.Corner(stripe, Theme.Radius.Full)

            Theme.Label(card, "Name", cfg.displayName or weaponId,
                UDim2.new(1,-56,0,22), UDim2.new(0,14,0,8),
                Theme.Colors.Text, 12, Theme.Fonts.Bold)

            Theme.Label(card, "Cat", cfg.category or "",
                UDim2.new(1,-56,0,16), UDim2.new(0,14,0,32),
                Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular)

            if isEquipped then
                Theme.Label(card, "Equipped", "EQUIPPED",
                    UDim2.new(0,58,0,18), UDim2.new(1,-62,0.5,-9),
                    Theme.Colors.Primary, 9, Theme.Fonts.Bold,
                    Enum.TextXAlignment.Center)
            end

            local hitbox = Instance.new("TextButton")
            hitbox.Size                  = UDim2.new(1,0,1,0)
            hitbox.BackgroundTransparency = 1
            hitbox.Text                  = ""
            hitbox.Parent                = card

            local capturedId  = weaponId
            local capturedSlot = slotDef
            hitbox.MouseButton1Click:Connect(function()
                selectedWeapons[currentSlot] = capturedId
                updateStats(capturedId)
                buildWeaponList(capturedSlot)
            end)

            order = order + 1
        end
    end

    if order == 1 then
        Theme.Label(weaponScroll, "None", "No weapons for this slot.",
            UDim2.new(1,0,0,30), nil, Theme.Colors.TextMuted, 12)
    end
end

-- ─── Slot tabs ────────────────────────────────────────────────────────────────

local function refreshEquippedLabels()
    for _, slotDef in ipairs(SLOTS) do
        local ref = slotBtnRefs[slotDef.id]
        if ref then
            local equipped = selectedWeapons[slotDef.id]
            if equipped then
                local cfg = WepCfg.Weapons[equipped]
                ref.equippedLbl.Text = cfg and (cfg.displayName or equipped) or "None"
            else
                ref.equippedLbl.Text = "None"
            end
        end
    end
end

local function selectSlot(slotDef)
    currentSlot    = slotDef.id
    currentSlotDef = slotDef

    for _, ref in pairs(slotBtnRefs) do
        ref.btn.BackgroundColor3 = Theme.Colors.Surface2
        ref.label.TextColor3     = Theme.Colors.TextMuted
        ref.stroke.Color         = Theme.Colors.Border
    end
    local ref = slotBtnRefs[slotDef.id]
    if ref then
        ref.btn.BackgroundColor3 = Theme.Colors.Surface3
        ref.label.TextColor3     = Theme.Colors.Primary
        ref.stroke.Color         = Theme.Colors.Primary
    end

    buildWeaponList(slotDef)

    local equipped = selectedWeapons[slotDef.id]
    if equipped then
        updateStats(equipped)
    else
        clearStats()
    end
end

for _, slotDef in ipairs(SLOTS) do
    local btn    = Theme.Frame(slotScroll, slotDef.id .. "SlotBtn",
        UDim2.new(1,-4,0,54), nil, Theme.Colors.Surface2)
    Theme.Corner(btn, Theme.Radius.Md)
    local stroke = Theme.Stroke(btn, Theme.Colors.Border)

    Theme.Label(btn, "Icon", slotDef.icon,
        UDim2.new(0,28,1,0), UDim2.new(0,10,0,0),
        Theme.Colors.TextMuted, 20, Theme.Fonts.Regular,
        Enum.TextXAlignment.Center)

    local lbl = Theme.Label(btn, "Lbl", slotDef.label,
        UDim2.new(1,-50,0,20), UDim2.new(0,44,0,8),
        Theme.Colors.TextMuted, 12, Theme.Fonts.Bold)

    local equippedLbl = Theme.Label(btn, "EquippedWep", "None",
        UDim2.new(1,-50,0,16), UDim2.new(0,44,0,28),
        Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular)

    local hitbox = Instance.new("TextButton")
    hitbox.Size                  = UDim2.new(1,0,1,0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                  = ""
    hitbox.Parent                = btn

    local captured = slotDef
    hitbox.MouseButton1Click:Connect(function()
        selectSlot(captured)
    end)

    slotBtnRefs[slotDef.id] = { btn = btn, label = lbl, stroke = stroke, equippedLbl = equippedLbl }
end

-- ─── Save ────────────────────────────────────────────────────────────────────

saveBtn.MouseButton1Click:Connect(function()
    if not selectedWeapons.Primary then
        setStatus("✗ Select a primary weapon first", false)
        return
    end
    saveBtn.Text = "Saving..."
    local ok = Remotes.InvokeServer("SaveLoadout", selectedWeapons)
    saveBtn.Text = "✔ EQUIP & SAVE"
    if ok then
        setStatus("✓ Loadout saved successfully!", true)
        refreshEquippedLabels()
    else
        setStatus("✗ Could not save loadout", false)
    end
end)

-- ─── Open hook ────────────────────────────────────────────────────────────────

local OpenLoadout = Instance.new("BindableFunction")
OpenLoadout.Name   = "Open_LoadoutEditor"
OpenLoadout.Parent = PlayerGui
OpenLoadout.OnInvoke = function()
    task.spawn(function()
        local saved = Remotes.InvokeServer("GetLoadout")
        if saved then
            selectedWeapons.Primary   = saved.Primary
            selectedWeapons.Secondary = saved.Secondary
            selectedWeapons.Throwable = saved.Throwable
        end
        refreshEquippedLabels()
        selectSlot(SLOTS[1])
    end)
    sg.Enabled = true
end

selectSlot(SLOTS[1])

print("[JTF] LoadoutEditor: ready")
