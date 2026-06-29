-- UIController.client.lua
-- Manages all game UI screens and connects them to server events.
-- Each Screen is a ScreenGui (create them in StarterGui; this script drives them).

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer.PlayerGui

local shared   = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes  = require(shared:WaitForChild("Remotes"))
local RankConfig = require(shared:WaitForChild("Config"):WaitForChild("RankConfig"))

-- ─── Screen registry ─────────────────────────────────────────────────────────
-- All ScreenGui names. Create them in StarterGui and this script will find them.
local Screens = {}
local ScreenNames = {
    "HUD", "MainMenu", "TeamSelect", "BranchSelect", "JobSelect",
    "MissionBoard", "DeploymentScreen", "DailyRewards", "BattlePass",
    "GamepassShop", "LoadoutEditor", "UniformEditor", "VehicleSpawn",
    "SquadMenu", "ProfileCard", "RankPopup", "Notification",
    "Tutorial", "LeaderboardScreen",
}

for _, name in ipairs(ScreenNames) do
    local gui = PlayerGui:WaitForChild(name, 5)
    Screens[name] = gui  -- may be nil if not yet built in Studio
end

local function getScreen(name)
    return Screens[name] or PlayerGui:FindFirstChild(name)
end

local function show(name)
    local s = getScreen(name)
    if s then s.Enabled = true end
end

local function hide(name)
    local s = getScreen(name)
    if s then s.Enabled = false end
end

local function hideAll()
    for _, name in ipairs(ScreenNames) do hide(name) end
end

-- ─── XP bar ──────────────────────────────────────────────────────────────────
local function updateXPBar(xp, rankIndex)
    local hud = getScreen("HUD")
    if not hud then return end

    local xpBar   = hud:FindFirstChild("XPBar", true)
    local xpLabel = hud:FindFirstChild("XPLabel", true)
    local rankLabel = hud:FindFirstChild("RankLabel", true)

    local current = RankConfig.Ranks[rankIndex]
    local next    = RankConfig.Ranks[rankIndex + 1]

    if rankLabel and current then
        rankLabel.Text = current.name
    end

    if next and xpBar and xpLabel then
        local progress = (xp - current.xp) / (next.xp - current.xp)
        xpBar:TweenSize(
            UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0),
            Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true
        )
        xpLabel.Text = xp .. " / " .. next.xp
    else
        -- Max rank
        if xpLabel then xpLabel.Text = "MAX RANK" end
        if xpBar   then xpBar.Size   = UDim2.new(1, 0, 1, 0) end
    end
end

-- ─── Notification toast ──────────────────────────────────────────────────────
local NotifQueue = {}
local IsShowingNotif = false

local function showNextNotif()
    if IsShowingNotif or #NotifQueue == 0 then return end
    IsShowingNotif = true

    local notif = table.remove(NotifQueue, 1)
    local gui   = getScreen("Notification")
    if not gui then
        IsShowingNotif = false
        return
    end

    local frame  = gui:FindFirstChild("NotifFrame", true)
    local title  = frame and frame:FindFirstChild("Title", true)
    local body   = frame and frame:FindFirstChild("Body", true)

    if title then title.Text = notif.title or "" end
    if body  then body.Text  = notif.body  or "" end

    gui.Enabled = true
    if frame then
        frame.Position = UDim2.new(1, 20, 0.8, 0)
        TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = UDim2.new(0.7, 0, 0.8, 0)
        }):Play()
    end

    task.delay(3.5, function()
        if frame then
            TweenService:Create(frame, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 20, 0.8, 0)
            }):Play()
        end
        task.delay(0.35, function()
            gui.Enabled    = false
            IsShowingNotif = false
            showNextNotif()
        end)
    end)
end

local function queueNotification(title, body, icon)
    table.insert(NotifQueue, { title = title, body = body, icon = icon })
    showNextNotif()
end

-- ─── Rank popup ──────────────────────────────────────────────────────────────
local function showRankPopup(rankName)
    local gui   = getScreen("RankPopup")
    if not gui then return end

    local label = gui:FindFirstChild("RankName", true)
    if label then label.Text = "PROMOTED TO\n" .. rankName end

    gui.Enabled = true
    task.delay(4, function() gui.Enabled = false end)
end

-- ─── Tutorial step handler ────────────────────────────────────────────────────
local TUTORIAL_STEPS = {
    [1] = function()
        show("Tutorial")
        queueNotification("Welcome, Recruit!", "Complete boot camp to earn your first rank.", "Tutorial")
    end,
    [2] = function()
        queueNotification("Head to the Range", "Qualify with the M4A1 to advance.", "Weapon")
    end,
    [3] = function()
        queueNotification("Mount Up", "Board the Humvee for convoy insertion.", "Vehicle")
    end,
    [4] = function()
        queueNotification("First Deployment", "Desert AO is hot — move to the objective.", "Deploy")
    end,
    [5] = function()
        hide("Tutorial")
        queueNotification("Boot Camp Complete!", "Check the Mission Board for your next orders.", "Rank")
    end,
}

-- ─── Main menu flow ──────────────────────────────────────────────────────────
local function openBranchSelect()
    hideAll()
    show("BranchSelect")
end

local function openJobSelect(branch)
    hide("BranchSelect")
    show("JobSelect")
    -- Populate job list based on branch — wire to actual UI buttons in Studio
end

local function openMissionBoard()
    hideAll()
    show("MissionBoard")
    show("HUD")
    -- Fetch missions from server
    local missions = Remotes.InvokeServer("GetMissions")
    -- Populate board UI with missions table (wire in Studio)
    print("[UIController] Mission board refreshed:", missions)
end

local function openDeploymentScreen()
    hideAll()
    show("DeploymentScreen")
    show("HUD")
end

local function openShop()
    hideAll()
    show("GamepassShop")
end

local function openBattlePass()
    hideAll()
    show("BattlePass")
end

local function openDailyRewards()
    show("DailyRewards")
end

local function openLoadout()
    hide("MainMenu")
    show("LoadoutEditor")
end

local function openVehicleSpawn()
    hide("MainMenu")
    show("VehicleSpawn")
end

local function openProfile(targetUserId)
    show("ProfileCard")
    -- Fetch and display profile — connect to UI in Studio
end

-- ─── Remote event listeners ──────────────────────────────────────────────────
Remotes.OnClient("NotificationSent", function(payload)
    queueNotification(payload.title, payload.body, payload.icon)
end)

Remotes.OnClient("RankChanged", function(payload)
    showRankPopup(payload.rankName)
    updateXPBar(0, payload.rankIndex)
    queueNotification("Promoted!", "You are now " .. payload.rankName, "Rank")
end)

Remotes.OnClient("XPAwarded", function(payload)
    -- Update XP bar — we need rank index from local data
    -- Pull from server periodically or cache locally
    local data = Remotes.InvokeServer("GetPlayerData")
    if data then
        updateXPBar(data.XP, data.Rank)
    end
end)

Remotes.OnClient("CashUpdated", function(payload)
    local hud      = getScreen("HUD")
    local cashLabel = hud and hud:FindFirstChild("CashLabel", true)
    if cashLabel then
        cashLabel.Text = "$" .. tostring(payload.newBalance)
    end
end)

Remotes.OnClient("DailyRewardAvailable", function()
    openDailyRewards()
end)

Remotes.OnClient("DailyRewardClaimed", function(payload)
    queueNotification(
        "Daily Reward — Day " .. payload.reward.day,
        ("$%d Cash + %d XP"):format(payload.reward.cash, payload.reward.xp),
        "DailyReward"
    )
end)

Remotes.OnClient("MissionCompleted", function(payload)
    queueNotification(
        "Mission Complete!",
        ("+%d XP  +$%d"):format(payload.xp or 0, payload.cash or 0),
        "Mission"
    )
end)

Remotes.OnClient("RibbonAwarded", function(payload)
    queueNotification("Ribbon Earned", payload.ribbonId, "Ribbon")
end)

Remotes.OnClient("BadgeEarned", function(payload)
    queueNotification("Badge Earned!", payload.badgeName or payload.badgeId, "Badge")
end)

Remotes.OnClient("BPTierUnlocked", function(payload)
    queueNotification(
        "Battle Pass — Tier " .. payload.tier,
        "Claim your rewards in the Battle Pass menu.",
        "BattlePass"
    )
end)

Remotes.OnClient("SOFSelectionPassed", function(payload)
    queueNotification(
        "Welcome to SOF",
        payload.displayName .. " — you earned it.",
        "SOF"
    )
end)

Remotes.OnClient("TutorialStepTriggered", function(payload)
    local step = payload.step
    if TUTORIAL_STEPS[step] then
        TUTORIAL_STEPS[step]()
    end
end)

Remotes.OnClient("DeploymentStarted", function(payload)
    queueNotification("Deploying", "Heading to " .. payload.mapName, "Deploy")
end)

Remotes.OnClient("DeploymentEnded", function(payload)
    queueNotification(
        "Deployment Complete",
        ("+%d XP  +$%d"):format(payload.xp or 0, payload.cash or 0),
        "Deploy"
    )
end)

Remotes.OnClient("AdminAnnounce", function(payload)
    -- Show a prominent full-width announcement banner
    local sg = Instance.new("ScreenGui")
    sg.Name = "AdminAnnounce_" .. os.clock()
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 100
    sg.Parent = LocalPlayer.PlayerGui

    local banner = Instance.new("Frame")
    banner.Name = "Banner"
    banner.Size = UDim2.new(1, 0, 0, 56)
    banner.Position = UDim2.new(0, 0, 0, -60)
    banner.BackgroundColor3 = Color3.fromRGB(10, 13, 20)
    banner.BorderSizePixel = 0
    banner.Parent = sg

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.new(1, 0, 0, 3)
    stripe.Position = UDim2.new(0, 0, 1, -3)
    stripe.BackgroundColor3 = Color3.fromRGB(255, 184, 0)
    stripe.BorderSizePixel = 0
    stripe.Parent = banner

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.Text = "📢  " .. (payload.sender or "Admin") .. ": " .. (payload.message or "")
    lbl.TextColor3 = Color3.fromRGB(240, 246, 252)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = banner

    TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0, 0, 0, 0) }):Play()

    task.delay(6, function()
        TweenService:Create(banner, TweenInfo.new(0.3),
            { Position = UDim2.new(0, 0, 0, -60) }):Play()
        task.delay(0.35, function() sg:Destroy() end)
    end)
end)

-- ─── Key bindings ─────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.M         then openMissionBoard() end
    if k == Enum.KeyCode.B         then openBattlePass() end
    if k == Enum.KeyCode.I         then openLoadout() end
    if k == Enum.KeyCode.V         then openVehicleSpawn() end
    if k == Enum.KeyCode.Escape    then
        local main = getScreen("MainMenu")
        if main then
            local visible = main.Enabled
            hideAll()
            show("HUD")
            if not visible then show("MainMenu") end
        end
    end
end)

-- ─── Initial load ─────────────────────────────────────────────────────────────
-- Fetch player data and populate HUD on first load
task.spawn(function()
    task.wait(2)
    local data = Remotes.InvokeServer("GetPlayerData")
    if data then
        updateXPBar(data.XP or 0, data.Rank or 1)

        local hud      = getScreen("HUD")
        local cashLabel = hud and hud:FindFirstChild("CashLabel", true)
        if cashLabel then cashLabel.Text = "$" .. tostring(data.Cash or 0) end
    end
    show("HUD")
end)

print("[UIController] Loaded. M=MissionBoard B=BattlePass I=Loadout V=Vehicles Esc=Menu")
