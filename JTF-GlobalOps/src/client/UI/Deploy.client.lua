-- Deploy.client.lua — deployment map selection and quick-launch screen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local shared     = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme      = require(shared:WaitForChild("Theme"))
local Remotes    = require(shared:WaitForChild("Remotes"))
local MapCfg     = require(shared:WaitForChild("Config"):WaitForChild("MissionConfig"))
local RankCfg    = require(shared:WaitForChild("Config"):WaitForChild("RankConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("Deploy", 8)
sg.Enabled = false
sg.Parent  = PlayerGui

local root = Theme.Frame(sg, "Root",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Theme.Colors.BG)

-- Header
local header = Theme.Frame(root, "Header",
    UDim2.new(1,0,0,52), nil, Theme.Colors.Surface)
Theme.Frame(header, "Gold",
    UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), Theme.Colors.Primary)
Theme.Label(header, "Title", "DEPLOYMENT",
    UDim2.new(1,-120,1,0), UDim2.new(0,24,0,0),
    Theme.Colors.Primary, 16, Theme.Fonts.Bold)

local closeBtn = Theme.Button(header, "Close", "✕ Back",
    UDim2.new(0,88,0,32), UDim2.new(1,-100,0.5,-16), "ghost")
closeBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
    local mm = PlayerGui:FindFirstChild("MainMenu")
    if mm then mm.Enabled = true end
end)

-- Content area
local content = Theme.Frame(root, "Content",
    UDim2.new(1,-48,1,-88),
    UDim2.new(0,24,0,60),
    Color3.new(0,0,0), 1)

-- ─── Left: map list ───────────────────────────────────────────────────────────
local mapPanel = Theme.Frame(content, "MapPanel",
    UDim2.new(1,-300,1,0), nil, Color3.new(0,0,0), 1)
Theme.Label(mapPanel, "MapTitle", "SELECT OPERATION",
    UDim2.new(1,0,0,22), nil, Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local mapScroll = Theme.Scroll(mapPanel, "MapScroll",
    UDim2.new(1,0,1,-30), UDim2.new(0,0,0,28))
Theme.ListLayout(mapScroll, Enum.FillDirection.Vertical, 8)

-- ─── Right: mission details + deploy ─────────────────────────────────────────
local detailPanel = Theme.Frame(content, "DetailPanel",
    UDim2.new(0,284,1,0),
    UDim2.new(1,-284,0,0),
    Theme.Colors.Surface)
Theme.Corner(detailPanel, Theme.Radius.Md)
Theme.Stroke(detailPanel, Theme.Colors.Border)
Theme.Padding(detailPanel, 16)

-- Detail header
local detailNameLbl = Theme.Label(detailPanel, "OpName", "SELECT AN OPERATION",
    UDim2.new(1,0,0,28), nil,
    Theme.Colors.Text, 16, Theme.Fonts.Bold)

local detailEnvLbl = Theme.Label(detailPanel, "Env", "",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,30),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Regular)

-- XP multiplier
local xpMultFrame = Theme.Frame(detailPanel, "XPMultRow",
    UDim2.new(1,0,0,22), UDim2.new(0,0,0,56), Color3.new(0,0,0), 1)
Theme.Label(xpMultFrame, "L", "XP MULTIPLIER",
    UDim2.new(0.6,0,1,0), nil,
    Theme.Colors.TextMuted, 10, Theme.Fonts.Bold)
local xpMultVal = Theme.Label(xpMultFrame, "V", "—",
    UDim2.new(0.4,0,1,0), UDim2.new(0.6,0,0,0),
    Theme.Colors.Success, 10, Theme.Fonts.Bold,
    Enum.TextXAlignment.Right)

-- Rank requirement
local rankReqFrame = Theme.Frame(detailPanel, "RankRow",
    UDim2.new(1,0,0,22), UDim2.new(0,0,0,82), Color3.new(0,0,0), 1)
Theme.Label(rankReqFrame, "L", "MIN. RANK",
    UDim2.new(0.6,0,1,0), nil,
    Theme.Colors.TextMuted, 10, Theme.Fonts.Bold)
local rankReqVal = Theme.Label(rankReqFrame, "V", "—",
    UDim2.new(0.4,0,1,0), UDim2.new(0.6,0,0,0),
    Theme.Colors.Text, 10, Theme.Fonts.Bold,
    Enum.TextXAlignment.Right)

-- Divider
local div1 = Theme.Divider(detailPanel)
div1.Position = UDim2.new(0,-16,0,112)
div1.Size     = UDim2.new(1,32,0,1)

-- Mode selector
Theme.Label(detailPanel, "ModeTitle", "MISSION MODE",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,120),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local modeScroll = Theme.Scroll(detailPanel, "ModeScroll",
    UDim2.new(1,0,0,130), UDim2.new(0,0,0,142))
local modeLayout = Instance.new("UIGridLayout")
modeLayout.CellSize    = UDim2.new(0.5,-4,0,34)
modeLayout.CellPadding = UDim2.new(0,8,0,6)
modeLayout.SortOrder   = Enum.SortOrder.LayoutOrder
modeLayout.Parent      = modeScroll

-- Enemies
local div2 = Theme.Divider(detailPanel)
div2.Position = UDim2.new(0,-16,0,278)
div2.Size     = UDim2.new(1,32,0,1)

Theme.Label(detailPanel, "EnemyTitle", "ENEMY FACTION",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,286),
    Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)
local enemyLbl = Theme.Label(detailPanel, "EnemyVal", "—",
    UDim2.new(1,0,0,18), UDim2.new(0,0,0,304),
    Theme.Colors.Danger, 12, Theme.Fonts.Bold)

-- Deploy button
local deployBtn = Theme.Button(detailPanel, "Deploy",
    "⬡ DEPLOY NOW",
    UDim2.new(1,0,0,44), UDim2.new(0,0,1,-44), "primary")
deployBtn.TextSize = 15
deployBtn.Visible  = false

-- Status bar
local statusBar = Theme.Frame(root, "Status",
    UDim2.new(1,0,0,36), UDim2.new(0,0,1,-36), Theme.Colors.Surface)
local statusLbl = Theme.Label(statusBar, "Msg", "",
    UDim2.new(1,-24,1,0), UDim2.new(0,16,0,0),
    Theme.Colors.TextMuted, 12, Theme.Fonts.Regular)

local function setStatus(msg, isOk)
    statusLbl.Text       = msg
    statusLbl.TextColor3 = isOk and Theme.Colors.Success or Theme.Colors.Danger
    task.delay(5, function() statusLbl.Text = "" end)
end

-- ─── State ────────────────────────────────────────────────────────────────────
local playerRank      = 1
local selectedMapId   = nil
local selectedMode    = nil
local selectedMapCard = nil
local modeBtnRefs     = {}

local ENV_COLOR = {
    Desert   = Color3.fromRGB(200, 150,  60),
    Jungle   = Color3.fromRGB( 60, 140,  60),
    Arctic   = Color3.fromRGB(160, 210, 240),
    Mountain = Color3.fromRGB(130, 100,  80),
    Urban    = Color3.fromRGB( 80, 100, 140),
    Island   = Color3.fromRGB( 40, 160, 200),
    Forest   = Color3.fromRGB( 50, 110,  60),
    Border   = Color3.fromRGB(140, 100,  60),
}

-- ─── Mode selection ───────────────────────────────────────────────────────────
local function selectMode(mode)
    selectedMode = mode
    for mId, ref in pairs(modeBtnRefs) do
        ref.BackgroundColor3 = mId == mode and Theme.Colors.Primary or Theme.Colors.Surface2
        ref.TextColor3       = mId == mode and Theme.Colors.PrimaryText or Theme.Colors.TextMuted
    end
end

local function buildModes(modes)
    for _, c in ipairs(modeScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    modeBtnRefs = {}

    for i, mode in ipairs(modes) do
        local btn = Instance.new("TextButton")
        btn.Name             = mode
        btn.Size             = UDim2.new(0,0,0,0)
        btn.BackgroundColor3 = Theme.Colors.Surface2
        btn.TextColor3       = Theme.Colors.TextMuted
        btn.Font             = Theme.Fonts.Bold
        btn.TextSize         = 10
        btn.Text             = mode
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = i
        btn.Parent           = modeScroll
        Theme.Corner(btn, Theme.Radius.Sm)

        local captured = mode
        btn.MouseButton1Click:Connect(function()
            selectMode(captured)
        end)

        modeBtnRefs[mode] = btn
    end

    -- Default: first mode
    if #modes > 0 then
        selectMode(modes[1])
    end
end

-- ─── Map selection ────────────────────────────────────────────────────────────
local function showMapDetails(mapId, mapData)
    selectedMapId = mapId

    local isLocked = playerRank < (mapData.minRank or 1)
    local rankInfo = RankCfg.Ranks[mapData.minRank or 1] or {}

    detailNameLbl.Text = mapData.displayName or mapId
    detailEnvLbl.Text  = mapData.environment or ""

    local envColor = ENV_COLOR[mapData.environment] or Theme.Colors.TextMuted
    detailEnvLbl.TextColor3 = envColor

    xpMultVal.Text = "×" .. tostring(mapData.xpMultiplier or 1.0)
    rankReqVal.Text = rankInfo.name or ("Rank " .. (mapData.minRank or 1))
    rankReqVal.TextColor3 = isLocked and Theme.Colors.Danger or Theme.Colors.Success

    enemyLbl.Text = mapData.enemyFaction or "Unknown"

    buildModes(mapData.availableModes or { "Patrol" })

    deployBtn.Visible = true
    deployBtn.Text    = isLocked
        and "🔒 Requires " .. (rankInfo.name or "higher rank")
        or  "⬡ DEPLOY NOW"
    deployBtn.BackgroundColor3 = isLocked
        and Theme.Colors.TextSubtle
        or  Theme.Colors.Primary
end

local function buildMapCards()
    for _, c in ipairs(mapScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local order = 1
    for mapId, mapData in pairs(MapCfg.Maps) do
        local isLocked = playerRank < (mapData.minRank or 1)
        local envColor = ENV_COLOR[mapData.environment] or Theme.Colors.TextSubtle

        local card = Theme.Frame(mapScroll, mapId .. "Card",
            UDim2.new(1,-4,0,72), nil,
            isLocked and Theme.Colors.Surface or Theme.Colors.Surface)
        card.LayoutOrder = mapData.minRank or order
        Theme.Corner(card, Theme.Radius.Md)
        Theme.Stroke(card, isLocked and Theme.Colors.Border or Theme.Colors.BorderBright)

        -- Environment color stripe
        local stripe = Theme.Frame(card, "Stripe",
            UDim2.new(0,4,1,-12), UDim2.new(0,0,0,6),
            isLocked and Theme.Colors.TextSubtle or envColor)
        Theme.Corner(stripe, Theme.Radius.Full)

        Theme.Label(card, "Name", mapData.displayName or mapId,
            UDim2.new(1,-56,0,22), UDim2.new(0,14,0,8),
            isLocked and Theme.Colors.TextMuted or Theme.Colors.Text,
            12, Theme.Fonts.Bold)

        Theme.Label(card, "Env",
            (mapData.environment or "") .. "  ×" .. tostring(mapData.xpMultiplier or 1.0) .. " XP",
            UDim2.new(1,-56,0,16), UDim2.new(0,14,0,32),
            Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular)

        if isLocked then
            local rankInfo = RankCfg.Ranks[mapData.minRank or 1] or {}
            Theme.Label(card, "Lock", "🔒 " .. (rankInfo.name or "Locked"),
                UDim2.new(0,90,0,18), UDim2.new(1,-94,0.5,-9),
                Theme.Colors.Danger, 9, Theme.Fonts.Bold,
                Enum.TextXAlignment.Right)
        else
            Theme.Label(card, "ModesLbl",
                table.concat(mapData.availableModes or {}, " · "),
                UDim2.new(1,-56,0,16), UDim2.new(0,14,0,50),
                Theme.Colors.TextSubtle, 8, Theme.Fonts.Regular)
        end

        local hitbox = Instance.new("TextButton")
        hitbox.Size                  = UDim2.new(1,0,1,0)
        hitbox.BackgroundTransparency = 1
        hitbox.Text                  = ""
        hitbox.Parent                = card

        local capturedId   = mapId
        local capturedData = mapData
        hitbox.MouseButton1Click:Connect(function()
            if selectedMapCard then
                selectedMapCard.BackgroundColor3 = Theme.Colors.Surface
            end
            card.BackgroundColor3 = Theme.Colors.Surface3
            selectedMapCard = card
            showMapDetails(capturedId, capturedData)
        end)

        order = order + 1
    end
end

-- ─── Deploy button ────────────────────────────────────────────────────────────
deployBtn.MouseButton1Click:Connect(function()
    if not selectedMapId then
        setStatus("Select an operation first", false)
        return
    end
    local mapData = MapCfg.Maps[selectedMapId]
    if mapData and playerRank < (mapData.minRank or 1) then
        local rankInfo = RankCfg.Ranks[mapData.minRank or 1] or {}
        setStatus("✗ Requires rank: " .. (rankInfo.name or "higher rank"), false)
        return
    end

    deployBtn.Text = "Deploying..."
    local ok, reason = Remotes.InvokeServer("RequestDeploy", selectedMapId, selectedMode or "Patrol")
    deployBtn.Text = "⬡ DEPLOY NOW"

    if ok then
        setStatus("✓ Deployed to " .. (MapCfg.Maps[selectedMapId] and MapCfg.Maps[selectedMapId].displayName or selectedMapId), true)
        sg.Enabled = false
    else
        setStatus("✗ " .. tostring(reason or "Could not deploy"), false)
    end
end)

-- ─── Open hook ────────────────────────────────────────────────────────────────
local OpenDeploy = Instance.new("BindableFunction")
OpenDeploy.Name   = "Open_Deploy"
OpenDeploy.Parent = PlayerGui
OpenDeploy.OnInvoke = function()
    task.spawn(function()
        local data = Remotes.InvokeServer("GetPlayerData")
        playerRank = (data and data.Rank) or 1
        buildMapCards()
    end)
    sg.Enabled = true
end

print("[JTF] Deploy: ready")
