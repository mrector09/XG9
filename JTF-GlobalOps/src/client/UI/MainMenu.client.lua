-- MainMenu.client.lua — polished military main menu built entirely in code.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local shared    = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme     = require(shared:WaitForChild("Theme"))
local Remotes   = require(shared:WaitForChild("Remotes"))
local RankCfg   = require(shared:WaitForChild("Config"):WaitForChild("RankConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("MainMenu", 5)
sg.Enabled = true
sg.Parent  = PlayerGui

-- Full-screen dark background
local bg = Theme.Frame(sg, "BG",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Theme.Colors.BG)

-- Subtle scanline gradient overlay
local scanGrad = Instance.new("UIGradient")
scanGrad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10,13,20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
})
scanGrad.Rotation = 180
scanGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.7),
    NumberSequenceKeypoint.new(0.5, 0.85),
    NumberSequenceKeypoint.new(1,   0.7),
})
scanGrad.Parent = bg

-- ─── Header bar ───────────────────────────────────────────────────────────────
local header = Theme.Frame(bg, "Header",
    UDim2.new(1, 0, 0, 60),
    UDim2.new(0,0,0,0),
    Theme.Colors.Surface)

-- Gold accent line at bottom of header
local headerLine = Theme.Frame(header, "Line",
    UDim2.new(1, 0, 0, 2),
    UDim2.new(0, 0, 1, -2),
    Theme.Colors.Primary)

-- JTF logo text
local logoLabel = Theme.Label(header, "Logo",
    "JTF: GLOBAL OPERATIONS",
    UDim2.new(0, 400, 1, 0),
    UDim2.new(0, 24, 0, 0),
    Theme.Colors.Primary, 22, Theme.Fonts.Bold)

local subtitleLabel = Theme.Label(header, "Subtitle",
    "JOINT TASK FORCE SIMULATOR",
    UDim2.new(0, 400, 0, 18),
    UDim2.new(0, 26, 0, 34),
    Theme.Colors.TextMuted, 11, Theme.Fonts.Medium)

-- Clock (top right)
local clockLabel = Theme.Label(header, "Clock",
    "00:00:00",
    UDim2.new(0, 120, 1, 0),
    UDim2.new(1, -136, 0, 0),
    Theme.Colors.TextMuted, 13, Theme.Fonts.Mono,
    Enum.TextXAlignment.Right)

task.spawn(function()
    while sg.Parent do
        clockLabel.Text = os.date("%H:%M:%S")
        task.wait(1)
    end
end)

-- ─── Main content area ────────────────────────────────────────────────────────
local content = Theme.Frame(bg, "Content",
    UDim2.new(1, -48, 1, -84),
    UDim2.new(0, 24, 0, 72),
    Color3.new(0,0,0), 1)

-- Three-column layout
local LEFT_W   = 260
local RIGHT_W  = 220
local CENTER_W = 0  -- flex

-- ─── LEFT: Player card ───────────────────────────────────────────────────────
local leftPanel = Theme.Frame(content, "Left",
    UDim2.new(0, LEFT_W, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Color3.new(0,0,0), 1)
Theme.ListLayout(leftPanel, Enum.FillDirection.Vertical, 10)

-- Avatar frame placeholder
local avatarCard = Theme.Frame(leftPanel, "AvatarCard",
    UDim2.new(1, 0, 0, 130),
    nil, Theme.Colors.Surface)
avatarCard.LayoutOrder = 1
Theme.Corner(avatarCard, Theme.Radius.Lg)

-- Avatar circle
local avatarCircle = Theme.Frame(avatarCard, "Circle",
    UDim2.new(0, 72, 0, 72),
    UDim2.new(0, 16, 0.5, -36),
    Theme.Colors.Surface3)
Theme.Corner(avatarCircle, Theme.Radius.Full)
Theme.Stroke(avatarCircle, Theme.Colors.Primary, 2)

local avatarInitial = Theme.Label(avatarCircle, "Initial",
    string.upper(string.sub(LocalPlayer.Name, 1, 1)),
    UDim2.new(1, 0, 1, 0), nil,
    Theme.Colors.Primary, 28, Theme.Fonts.Bold,
    Enum.TextXAlignment.Center)

-- Player name + info
local playerNameLbl = Theme.Label(avatarCard, "PlayerName",
    LocalPlayer.DisplayName,
    UDim2.new(1, -106, 0, 22),
    UDim2.new(0, 100, 0, 24),
    Theme.Colors.Text, 15, Theme.Fonts.Bold)

local rankBadgeLbl = Theme.Label(avatarCard, "RankBadge",
    "RECRUIT",
    UDim2.new(1, -106, 0, 18),
    UDim2.new(0, 100, 0, 48),
    Theme.Colors.Primary, 11, Theme.Fonts.Bold)

local branchLbl = Theme.Label(avatarCard, "Branch",
    "Army • Infantry",
    UDim2.new(1, -106, 0, 18),
    UDim2.new(0, 100, 0, 68),
    Theme.Colors.TextMuted, 11, Theme.Fonts.Regular)

local cashLbl = Theme.Label(avatarCard, "Cash",
    "$500",
    UDim2.new(1, -106, 0, 18),
    UDim2.new(0, 100, 0, 90),
    Theme.Colors.Success, 12, Theme.Fonts.Bold)

-- XP progress section
local xpCard = Theme.Frame(leftPanel, "XPCard",
    UDim2.new(1, 0, 0, 62),
    nil, Theme.Colors.Surface)
xpCard.LayoutOrder = 2
Theme.Corner(xpCard, Theme.Radius.Md)
Theme.Padding(xpCard, 12)

local xpTopRow = Theme.Frame(xpCard, "XPTop",
    UDim2.new(1, 0, 0, 18), nil, Color3.new(0,0,0), 1)
Theme.Label(xpTopRow, "XPTitle", "EXPERIENCE",
    UDim2.new(0.5, 0, 1, 0), nil, Theme.Colors.TextSubtle, 10, Theme.Fonts.Bold)
local xpNumLbl = Theme.Label(xpTopRow, "XPNum", "0 XP",
    UDim2.new(0.5, 0, 1, 0), UDim2.new(0.5,0,0,0),
    Theme.Colors.TextMuted, 10, Theme.Fonts.Mono,
    Enum.TextXAlignment.Right)

-- XP bar track
local xpTrack = Theme.Frame(xpCard, "XPTrack",
    UDim2.new(1, 0, 0, 8),
    UDim2.new(0, 0, 0, 24),
    Theme.Colors.Surface3)
Theme.Corner(xpTrack, Theme.Radius.Full)

local xpFill = Theme.Frame(xpTrack, "XPFill",
    UDim2.new(0, 0, 1, 0), nil, Theme.Colors.Primary)
Theme.Corner(xpFill, Theme.Radius.Full)

local xpNextLbl = Theme.Label(xpCard, "XPNext", "Next: Private at 500 XP",
    UDim2.new(1, 0, 0, 14),
    UDim2.new(0, 0, 0, 38),
    Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular)

-- Stats card
local statsCard = Theme.Frame(leftPanel, "StatsCard",
    UDim2.new(1, 0, 0, 90),
    nil, Theme.Colors.Surface)
statsCard.LayoutOrder = 3
Theme.Corner(statsCard, Theme.Radius.Md)
Theme.Padding(statsCard, 12)
Theme.ListLayout(statsCard, Enum.FillDirection.Vertical, 5)

local function statRow(parent, label, valueKey)
    local row = Theme.Frame(parent, label .. "Row",
        UDim2.new(1, 0, 0, 16), nil, Color3.new(0,0,0), 1)
    row.LayoutOrder = #parent:GetChildren()
    Theme.Label(row, "Label", label,
        UDim2.new(0.6, 0, 1, 0), nil, Theme.Colors.TextMuted, 10, Theme.Fonts.Regular)
    local valLbl = Theme.Label(row, "Value", "—",
        UDim2.new(0.4, 0, 1, 0), UDim2.new(0.6,0,0,0),
        Theme.Colors.Text, 10, Theme.Fonts.Bold,
        Enum.TextXAlignment.Right)
    return valLbl
end

local killsVal   = statRow(statsCard, "Total Kills",   "TotalKills")
local deathsVal  = statRow(statsCard, "Total Deaths",  "TotalDeaths")
local deploysVal = statRow(statsCard, "Deployments",   "DeploymentsCompleted")
local revivesVal = statRow(statsCard, "Revives",       "TotalRevives")

-- ─── CENTER: Navigation ───────────────────────────────────────────────────────
local centerPanel = Theme.Frame(content, "Center",
    UDim2.new(1, -(LEFT_W + RIGHT_W + 32), 1, 0),
    UDim2.new(0, LEFT_W + 16, 0, 0),
    Color3.new(0,0,0), 1)

-- Section heading
Theme.Label(centerPanel, "NavTitle", "COMMAND CENTER",
    UDim2.new(1, 0, 0, 22),
    UDim2.new(0, 0, 0, 0),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

-- Button grid (2 wide)
local navGrid = Theme.Frame(centerPanel, "NavGrid",
    UDim2.new(1, 0, 1, -32),
    UDim2.new(0, 0, 0, 28),
    Color3.new(0,0,0), 1)

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize          = UDim2.new(0.5, -6, 0, 88)
gridLayout.CellPadding       = UDim2.new(0, 12, 0, 12)
gridLayout.SortOrder         = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.Parent            = navGrid

local NAV_ITEMS = {
    { icon = "⬡", label = "DEPLOY",        sub = "Enter the battlefield",   key = "Deploy",      style = "primary", order = 1 },
    { icon = "⊞",  label = "MISSION BOARD", sub = "Daily missions & ops",    key = "MissionBoard",style = "ghost",   order = 2 },
    { icon = "⊙",  label = "LOADOUT",       sub = "Weapons & equipment",     key = "LoadoutEditor", style = "ghost",   order = 3 },
    { icon = "☰",  label = "BRANCH & JOB",  sub = "Select your role",        key = "BranchSelect",style = "ghost",   order = 4 },
    { icon = "★",  label = "BATTLE PASS",   sub = "Season rewards",          key = "BattlePass",  style = "ghost",   order = 5 },
    { icon = "◎",  label = "SHOP",          sub = "Cosmetics & upgrades",    key = "GamepassShop",style = "ghost",   order = 6 },
}

-- BindableFunction so other scripts can open the menu
local OpenMenu = Instance.new("BindableFunction")
OpenMenu.Name   = "OpenMainMenu"
OpenMenu.Parent = PlayerGui

local function openScreen(name)
    sg.Enabled = false
    -- Fire event so UIController (or screen scripts) can react
    local bf = PlayerGui:FindFirstChild("Open_" .. name)
    if bf then bf:Invoke() end
    -- Fallback: find ScreenGui by name and enable it
    local screen = PlayerGui:FindFirstChild(name)
    if screen then screen.Enabled = true end
end

for _, item in ipairs(NAV_ITEMS) do
    local card = Theme.Frame(navGrid, item.key .. "Card",
        UDim2.new(0, 0, 0, 0), nil,
        item.style == "primary" and Theme.Colors.Primary or Theme.Colors.Surface)
    card.LayoutOrder = item.order
    Theme.Corner(card, Theme.Radius.Md)
    if item.style ~= "primary" then
        Theme.Stroke(card, Theme.Colors.Border)
    end

    -- Icon
    local iconLbl = Theme.Label(card, "Icon", item.icon,
        UDim2.new(0, 36, 0, 36),
        UDim2.new(0, 14, 0, 14),
        item.style == "primary" and Theme.Colors.PrimaryText or Theme.Colors.Primary,
        22, Theme.Fonts.Bold, Enum.TextXAlignment.Center)

    -- Label
    local titleLbl = Theme.Label(card, "Title", item.label,
        UDim2.new(1, -20, 0, 20),
        UDim2.new(0, 14, 0, 52),
        item.style == "primary" and Theme.Colors.PrimaryText or Theme.Colors.Text,
        13, Theme.Fonts.Bold)

    local subLbl = Theme.Label(card, "Sub", item.sub,
        UDim2.new(1, -20, 0, 16),
        UDim2.new(0, 14, 0, 68),
        item.style == "primary" and Color3.fromRGB(80, 60, 0) or Theme.Colors.TextSubtle,
        10, Theme.Fonts.Regular)

    -- Click hit area
    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1,0,1,0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.Parent = card

    local origColor = card.BackgroundColor3
    hitbox.MouseEnter:Connect(function()
        card.BackgroundColor3 = origColor:Lerp(Color3.new(1,1,1), 0.08)
    end)
    hitbox.MouseLeave:Connect(function()
        card.BackgroundColor3 = origColor
    end)
    hitbox.MouseButton1Click:Connect(function()
        openScreen(item.key)
    end)
end

-- ─── RIGHT: Server info ───────────────────────────────────────────────────────
local rightPanel = Theme.Frame(content, "Right",
    UDim2.new(0, RIGHT_W, 1, 0),
    UDim2.new(1, -RIGHT_W, 0, 0),
    Color3.new(0,0,0), 1)
Theme.ListLayout(rightPanel, Enum.FillDirection.Vertical, 10)

Theme.Label(rightPanel, "RightTitle", "SERVER STATUS",
    UDim2.new(1, 0, 0, 22), nil,
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold).LayoutOrder = 1

local serverCard = Theme.Frame(rightPanel, "ServerCard",
    UDim2.new(1, 0, 0, 100), nil, Theme.Colors.Surface)
serverCard.LayoutOrder = 2
Theme.Corner(serverCard, Theme.Radius.Md)
Theme.Padding(serverCard, 12)
Theme.ListLayout(serverCard, Enum.FillDirection.Vertical, 6)

local function serverStat(parent, label)
    local row = Theme.Frame(parent, label, UDim2.new(1,0,0,18), nil, Color3.new(0,0,0), 1)
    row.LayoutOrder = #parent:GetChildren()
    Theme.Label(row, "L", label, UDim2.new(0.65,0,1,0), nil, Theme.Colors.TextMuted, 10, Theme.Fonts.Regular)
    local v = Theme.Label(row, "V", "—", UDim2.new(0.35,0,1,0), UDim2.new(0.65,0,0,0),
        Theme.Colors.Text, 10, Theme.Fonts.Bold, Enum.TextXAlignment.Right)
    return v
end

local svPlayersVal = serverStat(serverCard, "Players Online")
local svNPCsVal    = serverStat(serverCard, "Active NPCs")
local svUptimeVal  = serverStat(serverCard, "Uptime")

-- Daily reward status
local dailyCard = Theme.Frame(rightPanel, "DailyCard",
    UDim2.new(1, 0, 0, 60), nil, Theme.Colors.Surface)
dailyCard.LayoutOrder = 3
Theme.Corner(dailyCard, Theme.Radius.Md)
Theme.Padding(dailyCard, 12)

Theme.Label(dailyCard, "DailyTitle", "DAILY REWARD",
    UDim2.new(1, 0, 0, 18), nil,
    Theme.Colors.TextSubtle, 10, Theme.Fonts.Bold)

local dailyBtn = Theme.Button(dailyCard, "DailyClaim", "Claim Reward",
    UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 1, -28), "success")
dailyBtn.MouseButton1Click:Connect(function()
    local res = Remotes.InvokeServer("ClaimDailyReward")
    if res then dailyBtn.Text = "Claimed!" dailyBtn.BackgroundColor3 = Theme.Colors.TextSubtle end
end)

-- ─── Populate from server data ────────────────────────────────────────────────

local function refreshData()
    local data = Remotes.InvokeServer("GetPlayerData")
    if not data then return end

    -- Rank
    local rankInfo = RankCfg.Ranks[data.Rank or 1] or RankCfg.Ranks[1]
    local nextInfo = RankCfg.Ranks[(data.Rank or 1) + 1]
    rankBadgeLbl.Text = string.upper(rankInfo.name)
    branchLbl.Text    = (data.Branch or "Army") .. " • " .. (data.Job or "Infantry")
    cashLbl.Text      = "$" .. tostring(data.Cash or 0)

    -- XP bar
    xpNumLbl.Text = tostring(data.XP or 0) .. " XP"
    if nextInfo then
        local pct = math.clamp((data.XP - rankInfo.xp) / (nextInfo.xp - rankInfo.xp), 0, 1)
        xpFill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
        xpNextLbl.Text = "Next: " .. nextInfo.name .. " at " .. nextInfo.xp .. " XP"
    else
        xpFill:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)
        xpNextLbl.Text = "Maximum rank achieved"
    end

    -- Stats
    killsVal.Text   = tostring(data.TotalKills or 0)
    deathsVal.Text  = tostring(data.TotalDeaths or 0)
    deploysVal.Text = tostring(data.DeploymentsCompleted or 0)
    revivesVal.Text = tostring(data.TotalRevives or 0)

    -- Server info
    svPlayersVal.Text = tostring(#game:GetService("Players"):GetPlayers())
end

-- ─── Show / hide ─────────────────────────────────────────────────────────────

Remotes.OnClient("RankChanged", function(payload)
    task.delay(0.5, refreshData)
end)

Remotes.OnClient("CashUpdated", function(payload)
    cashLbl.Text = "$" .. tostring(payload.newBalance or 0)
end)

-- Refresh when menu opens
OpenMenu.OnInvoke = function()
    sg.Enabled = true
    task.spawn(refreshData)
end

-- Initial data load
task.spawn(function()
    task.wait(3)
    refreshData()
end)

print("[JTF] MainMenu: ready")
