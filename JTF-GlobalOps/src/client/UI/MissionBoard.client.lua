-- MissionBoard.client.lua
-- Builds the Mission Board ScreenGui and populates it from the server.
-- Press M to open/close. Displays daily missions, weekly op, and deploy buttons.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer.PlayerGui

local shared    = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes   = require(shared:WaitForChild("Remotes"))
local MissionConfig = require(shared:WaitForChild("Config"):WaitForChild("MissionConfig"))

-- ─── Build ScreenGui ─────────────────────────────────────────────────────────
local Screen = Instance.new("ScreenGui")
Screen.Name           = "MissionBoard"
Screen.ResetOnSpawn   = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Enabled        = false
Screen.Parent         = PlayerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size                  = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3      = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel       = 0
overlay.Parent                = Screen

-- Main panel
local panel = Instance.new("Frame")
panel.Name                   = "Panel"
panel.Size                   = UDim2.new(0, 900, 0, 600)
panel.Position               = UDim2.new(0.5, -450, 0.5, -300)
panel.BackgroundColor3       = Color3.fromRGB(18, 22, 28)
panel.BorderSizePixel        = 0
panel.Parent                 = Screen

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(30, 38, 50)
header.BorderSizePixel  = 0
header.Parent           = panel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size                  = UDim2.new(0.6, 0, 1, 0)
title.Position              = UDim2.new(0, 16, 0, 0)
title.Text                  = "MISSION BOARD — JOINT TASK FORCE"
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 18
title.TextColor3            = Color3.fromRGB(255, 200, 0)
title.BackgroundTransparency = 1
title.TextXAlignment        = Enum.TextXAlignment.Left
title.Parent                = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size                  = UDim2.new(0, 36, 0, 36)
closeBtn.Position              = UDim2.new(1, -44, 0, 7)
closeBtn.Text                  = "✕"
closeBtn.Font                  = Enum.Font.GothamBold
closeBtn.TextSize              = 18
closeBtn.TextColor3            = Color3.fromRGB(200, 200, 200)
closeBtn.BackgroundColor3      = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel       = 0
closeBtn.Parent                = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- ─── Left column: Daily Missions ──────────────────────────────────────────────
local leftCol = Instance.new("Frame")
leftCol.Size             = UDim2.new(0, 270, 1, -60)
leftCol.Position         = UDim2.new(0, 10, 0, 56)
leftCol.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
leftCol.BorderSizePixel  = 0
leftCol.Parent           = panel

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = leftCol

local dailyTitle = Instance.new("TextLabel")
dailyTitle.Size                  = UDim2.new(1, -10, 0, 32)
dailyTitle.Position              = UDim2.new(0, 8, 0, 8)
dailyTitle.Text                  = "DAILY MISSIONS"
dailyTitle.Font                  = Enum.Font.GothamBold
dailyTitle.TextSize              = 14
dailyTitle.TextColor3            = Color3.fromRGB(255, 200, 0)
dailyTitle.BackgroundTransparency = 1
dailyTitle.TextXAlignment        = Enum.TextXAlignment.Left
dailyTitle.Parent                = leftCol

local dailyList = Instance.new("ScrollingFrame")
dailyList.Name                   = "DailyList"
dailyList.Size                   = UDim2.new(1, -10, 1, -50)
dailyList.Position               = UDim2.new(0, 5, 0, 46)
dailyList.BackgroundTransparency = 1
dailyList.ScrollBarThickness     = 4
dailyList.Parent                 = leftCol

local dailyLayout = Instance.new("UIListLayout")
dailyLayout.Padding   = UDim.new(0, 6)
dailyLayout.SortOrder = Enum.SortOrder.LayoutOrder
dailyLayout.Parent    = dailyList

-- ─── Centre column: Deployment Maps ──────────────────────────────────────────
local centreCol = Instance.new("Frame")
centreCol.Size             = UDim2.new(0, 340, 1, -60)
centreCol.Position         = UDim2.new(0, 290, 0, 56)
centreCol.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
centreCol.BorderSizePixel  = 0
centreCol.Parent           = panel

local centreCorner = Instance.new("UICorner")
centreCorner.CornerRadius = UDim.new(0, 8)
centreCorner.Parent = centreCol

local mapTitle = Instance.new("TextLabel")
mapTitle.Size                  = UDim2.new(1,-10, 0, 32)
mapTitle.Position              = UDim2.new(0, 8, 0, 8)
mapTitle.Text                  = "DEPLOYMENT MAPS"
mapTitle.Font                  = Enum.Font.GothamBold
mapTitle.TextSize              = 14
mapTitle.TextColor3            = Color3.fromRGB(255, 200, 0)
mapTitle.BackgroundTransparency = 1
mapTitle.TextXAlignment        = Enum.TextXAlignment.Left
mapTitle.Parent                = centreCol

local mapList = Instance.new("ScrollingFrame")
mapList.Name                   = "MapList"
mapList.Size                   = UDim2.new(1, -10, 1, -50)
mapList.Position               = UDim2.new(0, 5, 0, 46)
mapList.BackgroundTransparency = 1
mapList.ScrollBarThickness     = 4
mapList.Parent                 = centreCol

local mapLayout = Instance.new("UIListLayout")
mapLayout.Padding   = UDim.new(0, 6)
mapLayout.SortOrder = Enum.SortOrder.LayoutOrder
mapLayout.Parent    = mapList

-- ─── Right column: Weekly Op ─────────────────────────────────────────────────
local rightCol = Instance.new("Frame")
rightCol.Size             = UDim2.new(0, 240, 1, -60)
rightCol.Position         = UDim2.new(0, 644, 0, 56)
rightCol.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
rightCol.BorderSizePixel  = 0
rightCol.Parent           = panel

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 8)
rightCorner.Parent = rightCol

local weeklyTitle = Instance.new("TextLabel")
weeklyTitle.Size                  = UDim2.new(1,-10, 0, 32)
weeklyTitle.Position              = UDim2.new(0, 8, 0, 8)
weeklyTitle.Text                  = "WEEKLY OPERATION"
weeklyTitle.Font                  = Enum.Font.GothamBold
weeklyTitle.TextSize              = 14
weeklyTitle.TextColor3            = Color3.fromRGB(255, 200, 0)
weeklyTitle.BackgroundTransparency = 1
weeklyTitle.TextXAlignment        = Enum.TextXAlignment.Left
weeklyTitle.Parent                = rightCol

local weeklyBody = Instance.new("Frame")
weeklyBody.Name             = "WeeklyBody"
weeklyBody.Size             = UDim2.new(1,-10, 1, -50)
weeklyBody.Position         = UDim2.new(0, 5, 0, 46)
weeklyBody.BackgroundTransparency = 1
weeklyBody.Parent           = rightCol

-- ─── Helper functions ─────────────────────────────────────────────────────────
local function makeCard(parent, title, description, buttonText, onPress, locked)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -8, 0, 80)
    card.BackgroundColor3 = locked
        and Color3.fromRGB(30, 30, 35)
        or  Color3.fromRGB(35, 45, 60)
    card.BorderSizePixel  = 0
    card.Parent           = parent

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent       = card

    local tl = Instance.new("TextLabel")
    tl.Size                  = UDim2.new(1, -10, 0, 22)
    tl.Position              = UDim2.new(0, 8, 0, 6)
    tl.Text                  = title
    tl.Font                  = Enum.Font.GothamBold
    tl.TextSize              = 13
    tl.TextColor3            = locked and Color3.fromRGB(120,120,120) or Color3.new(1,1,1)
    tl.BackgroundTransparency = 1
    tl.TextXAlignment        = Enum.TextXAlignment.Left
    tl.Parent                = card

    local desc = Instance.new("TextLabel")
    desc.Size                  = UDim2.new(1, -10, 0, 28)
    desc.Position              = UDim2.new(0, 8, 0, 26)
    desc.Text                  = description
    desc.Font                  = Enum.Font.Gotham
    desc.TextSize              = 11
    desc.TextColor3            = Color3.fromRGB(180,180,180)
    desc.BackgroundTransparency = 1
    desc.TextXAlignment        = Enum.TextXAlignment.Left
    desc.TextWrapped           = true
    desc.Parent                = card

    if not locked then
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(0, 90, 0, 22)
        btn.Position         = UDim2.new(1, -98, 1, -28)
        btn.Text             = buttonText or "DEPLOY"
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.TextColor3       = Color3.new(0, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
        btn.BorderSizePixel  = 0
        btn.Parent           = card

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 4)
        bc.Parent       = btn

        btn.MouseButton1Click:Connect(function()
            if onPress then onPress() end
        end)
    else
        local lockLabel = Instance.new("TextLabel")
        lockLabel.Size                  = UDim2.new(0, 80, 0, 22)
        lockLabel.Position              = UDim2.new(1, -88, 1, -28)
        lockLabel.Text                  = "🔒 LOCKED"
        lockLabel.Font                  = Enum.Font.GothamBold
        lockLabel.TextSize              = 11
        lockLabel.TextColor3            = Color3.fromRGB(150,100,100)
        lockLabel.BackgroundTransparency = 1
        lockLabel.Parent                = card
    end

    return card
end

-- ─── Populate from server data ────────────────────────────────────────────────
local function populateBoard(data)
    -- Clear lists
    for _, c in ipairs(dailyList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    for _, c in ipairs(mapList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end

    -- Daily missions
    local daily = data and data.daily or {}
    local pool  = MissionConfig.DailyPool
    for _, mission in ipairs(pool) do
        local mData = daily[mission.id]
        if mData then
            local prog = mData.progress or 0
            local goal = mData.goal or mission.target
            local done = mData.completed
            makeCard(
                dailyList,
                mission.label,
                (done and "✓ COMPLETE" or ("%d / %d"):format(prog, goal))
                    .. "  +" .. mission.xp .. " XP",
                done and "DONE" or "TRACK",
                nil,
                done
            )
        end
    end

    -- Deployment maps
    local playerData = Remotes.InvokeServer("GetPlayerData")
    local playerRank = playerData and playerData.Rank or 1

    for mapId, mapCfg in pairs(MissionConfig.Maps) do
        local locked = playerRank < (mapCfg.minRank or 1)
        makeCard(
            mapList,
            mapCfg.displayName,
            mapCfg.environment .. " · " .. table.concat(mapCfg.availableModes, ", "),
            "DEPLOY",
            function()
                Screen.Enabled = false
                Remotes.InvokeServer("RequestDeploy", mapId, "Patrol")
            end,
            locked
        )
    end

    -- Weekly op
    for _, c in ipairs(weeklyBody:GetChildren()) do c:Destroy() end
    local weekly  = data and data.weekly
    local wConfig = MissionConfig.WeeklyOperation
    local progress = weekly and weekly.progress or 0
    local claimed  = weekly and weekly.claimed or false

    local wDesc = Instance.new("TextLabel")
    wDesc.Size                  = UDim2.new(1,-10, 0, 80)
    wDesc.Position              = UDim2.new(0, 6, 0, 0)
    wDesc.Text                  = wConfig.displayName .. "\n\n" .. wConfig.description
    wDesc.Font                  = Enum.Font.Gotham
    wDesc.TextSize              = 12
    wDesc.TextColor3            = Color3.fromRGB(200,200,200)
    wDesc.BackgroundTransparency = 1
    wDesc.TextXAlignment        = Enum.TextXAlignment.Left
    wDesc.TextWrapped           = true
    wDesc.Parent                = weeklyBody

    local wProgLabel = Instance.new("TextLabel")
    wProgLabel.Size                  = UDim2.new(1,-10, 0, 22)
    wProgLabel.Position              = UDim2.new(0, 6, 0, 86)
    wProgLabel.Text                  = ("Deployments: %d / %d"):format(progress, wConfig.missions)
    wProgLabel.Font                  = Enum.Font.GothamBold
    wProgLabel.TextSize              = 13
    wProgLabel.TextColor3            = Color3.fromRGB(255,200,0)
    wProgLabel.BackgroundTransparency = 1
    wProgLabel.TextXAlignment        = Enum.TextXAlignment.Left
    wProgLabel.Parent                = weeklyBody

    local wRewards = Instance.new("TextLabel")
    wRewards.Size                  = UDim2.new(1,-10, 0, 40)
    wRewards.Position              = UDim2.new(0, 6, 0, 112)
    wRewards.Text                  = ("Reward: +%d XP  +$%d"):format(wConfig.xpReward, wConfig.cashReward)
    wRewards.Font                  = Enum.Font.Gotham
    wRewards.TextSize              = 12
    wRewards.TextColor3            = Color3.fromRGB(120, 220, 120)
    wRewards.BackgroundTransparency = 1
    wRewards.TextXAlignment        = Enum.TextXAlignment.Left
    wRewards.Parent                = weeklyBody

    if claimed then
        local claimedLabel = Instance.new("TextLabel")
        claimedLabel.Size                  = UDim2.new(1,-10, 0, 24)
        claimedLabel.Position              = UDim2.new(0, 6, 0, 158)
        claimedLabel.Text                  = "✓ CLAIMED THIS WEEK"
        claimedLabel.Font                  = Enum.Font.GothamBold
        claimedLabel.TextSize              = 13
        claimedLabel.TextColor3            = Color3.fromRGB(60, 220, 60)
        claimedLabel.BackgroundTransparency = 1
        claimedLabel.Parent                = weeklyBody
    end
end

-- ─── Open / close ─────────────────────────────────────────────────────────────
local function open()
    Screen.Enabled = true
    local data = Remotes.InvokeServer("GetMissions")
    populateBoard(data)
end

local function close()
    Screen.Enabled = false
end

closeBtn.MouseButton1Click:Connect(close)

-- UIController calls open via the M key — but we also expose it via BindableFunction
local openFn = Instance.new("BindableFunction")
openFn.Name   = "OpenMissionBoard"
openFn.Parent = PlayerGui
openFn.OnInvoke = open

-- Refresh on daily refresh event
Remotes.OnClient("DailyMissionsRefreshed", function()
    if Screen.Enabled then
        local data = Remotes.InvokeServer("GetMissions")
        populateBoard(data)
    end
end)

print("[MissionBoard] Built.")
