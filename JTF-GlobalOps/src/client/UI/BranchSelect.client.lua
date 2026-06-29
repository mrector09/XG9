-- BranchSelect.client.lua — branch and job selection screen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local shared   = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme    = require(shared:WaitForChild("Theme"))
local Remotes  = require(shared:WaitForChild("Remotes"))
local JobCfg   = require(shared:WaitForChild("Config"):WaitForChild("JobConfig"))
local RankCfg  = require(shared:WaitForChild("Config"):WaitForChild("RankConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("BranchSelect", 8)
sg.Enabled = false
sg.Parent  = PlayerGui

local root = Theme.Frame(sg, "Root",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), Theme.Colors.BG)

-- Header
local header = Theme.Frame(root, "Header",
    UDim2.new(1, 0, 0, 52), nil, Theme.Colors.Surface)
Theme.Frame(header, "Gold", UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), Theme.Colors.Primary)
Theme.Label(header, "Title", "SELECT YOUR BRANCH & JOB",
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
    UDim2.new(1, -48, 1, -68),
    UDim2.new(0, 24, 0, 60),
    Color3.new(0,0,0), 1)

-- Branch list (left)
local branchPanel = Theme.Frame(content, "BranchPanel",
    UDim2.new(0, 220, 1, 0), nil, Color3.new(0,0,0), 1)
Theme.Label(branchPanel, "BTitle", "BRANCHES",
    UDim2.new(1,0,0,22), nil, Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local branchScroll = Theme.Scroll(branchPanel, "Scroll",
    UDim2.new(1, 0, 1, -30), UDim2.new(0,0,0,28))
Theme.ListLayout(branchScroll, Enum.FillDirection.Vertical, 6)

-- Job list (right)
local jobPanel = Theme.Frame(content, "JobPanel",
    UDim2.new(1, -236, 1, 0),
    UDim2.new(0, 236, 0, 0),
    Color3.new(0,0,0), 1)

local jobTitleLbl = Theme.Label(jobPanel, "JTitle", "SELECT A BRANCH FIRST",
    UDim2.new(1,0,0,22), nil, Theme.Colors.TextSubtle, 11, Theme.Fonts.Bold)

local jobScroll = Theme.Scroll(jobPanel, "JobScroll",
    UDim2.new(1, 0, 1, -30), UDim2.new(0,0,0,28))

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0.5, -8, 0, 110)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder   = Enum.SortOrder.LayoutOrder
gridLayout.Parent      = jobScroll

-- Status bar
local statusBar = Theme.Frame(root, "Status",
    UDim2.new(1,0,0,36),
    UDim2.new(0,0,1,-36),
    Theme.Colors.Surface)
local statusLbl = Theme.Label(statusBar, "Msg", "",
    UDim2.new(1,-24,1,0), UDim2.new(0,16,0,0),
    Theme.Colors.TextMuted, 12, Theme.Fonts.Regular)

local function setStatus(msg, isOk)
    statusLbl.Text       = msg
    statusLbl.TextColor3 = isOk and Theme.Colors.Success or Theme.Colors.Danger
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local playerData = nil
local selectedBranch = nil

local function getPlayerRank()
    return (playerData and playerData.Rank) or 1
end

local function canApply(jobEntry)
    if not jobEntry.requirements then return true, "" end
    local req = jobEntry.requirements
    if req.rank and getPlayerRank() < req.rank then
        local rankName = (RankCfg.Ranks[req.rank] or {}).name or ("Rank " .. req.rank)
        return false, "Requires " .. rankName
    end
    return true, ""
end

-- ─── Job card builder ─────────────────────────────────────────────────────────

local function buildJobCard(branch, jobId, jobEntry)
    local ok, reason = canApply(jobEntry)

    local card = Theme.Frame(jobScroll, jobId .. "Card",
        UDim2.new(0,0,0,0), nil,
        ok and Theme.Colors.Surface or Theme.Colors.Surface2)
    card.LayoutOrder = jobEntry.order or 1
    Theme.Corner(card, Theme.Radius.Md)
    if not ok then
        Theme.Stroke(card, Theme.Colors.Border)
    else
        Theme.Stroke(card, Theme.Colors.BorderBright)
    end

    local nameLbl = Theme.Label(card, "Name",
        jobEntry.displayName or jobId,
        UDim2.new(1,-16,0,22), UDim2.new(0,10,0,8),
        ok and Theme.Colors.Text or Theme.Colors.TextMuted,
        12, Theme.Fonts.Bold)

    local payLbl = Theme.Label(card, "Pay",
        "Pay: $" .. math.floor((jobEntry.basePay or 100)),
        UDim2.new(1,-16,0,16), UDim2.new(0,10,0,34),
        Theme.Colors.Success, 10, Theme.Fonts.Regular)

    if not ok then
        Theme.Label(card, "Lock", "🔒 " .. reason,
            UDim2.new(1,-16,0,16), UDim2.new(0,10,0,54),
            Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular)
    else
        local selectBtn = Theme.Button(card, "Select", "SELECT",
            UDim2.new(1,-16,0,26), UDim2.new(0,8,1,-34), "primary")
        selectBtn.TextSize = 11
        selectBtn.MouseButton1Click:Connect(function()
            local res = Remotes.InvokeServer("SelectBranch", branch)
            task.wait(0.1)
            local res2 = Remotes.InvokeServer("ApplyForJob", branch, jobId)
            if res2 then
                setStatus("✓ Assigned to " .. (jobEntry.displayName or jobId), true)
            else
                setStatus("✗ Could not apply for this job", false)
            end
            task.delay(3, function() statusLbl.Text = "" end)
        end)
    end

    return card
end

-- ─── Branch card builder ──────────────────────────────────────────────────────

local BRANCH_COLORS = {
    Army       = Color3.fromRGB( 60, 100,  55),
    Marines    = Color3.fromRGB(140,  30,  30),
    Navy       = Color3.fromRGB( 30,  60, 140),
    AirForce   = Color3.fromRGB( 30, 100, 180),
    SpaceForce = Color3.fromRGB( 20,  20,  60),
    Civilian   = Color3.fromRGB( 80,  80,  80),
    Hostile    = Color3.fromRGB(120,  30,  20),
}

local BRANCH_ICON = {
    Army = "★", Marines = "⬡", Navy = "⚓", AirForce = "✈",
    SpaceForce = "◈", Civilian = "◉", Hostile = "☠",
}

local selectedCard = nil

local function showJobs(branchName)
    selectedBranch = branchName
    jobTitleLbl.Text = string.upper(branchName) .. " — SELECT JOB"

    -- Clear existing jobs
    for _, c in ipairs(jobScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local jobs = JobCfg.Jobs and JobCfg.Jobs[branchName]
    if not jobs then
        Theme.Label(jobScroll, "None", "No jobs configured for this branch.",
            UDim2.new(1,0,0,30), nil, Theme.Colors.TextMuted, 12)
        return
    end

    local order = 1
    for jobId, jobEntry in pairs(jobs) do
        buildJobCard(branchName, jobId, jobEntry, order)
        order += 1
    end
end

local function buildBranchCard(branchName)
    local color = BRANCH_COLORS[branchName] or Theme.Colors.Surface2
    local icon  = BRANCH_ICON[branchName]  or "◆"

    local card = Theme.Frame(branchScroll, branchName .. "Card",
        UDim2.new(1,-4,0,62), nil, Theme.Colors.Surface)
    Theme.Corner(card, Theme.Radius.Md)
    Theme.Stroke(card, Theme.Colors.Border)

    -- Color accent stripe
    local stripe = Theme.Frame(card, "Stripe",
        UDim2.new(0, 4, 1, -12), UDim2.new(0,0,0,6), color)
    Theme.Corner(stripe, Theme.Radius.Full)

    Theme.Label(card, "Icon", icon,
        UDim2.new(0, 30, 0, 30), UDim2.new(0, 12, 0.5, -15),
        Color3.new(1,1,1), 16, Theme.Fonts.Bold, Enum.TextXAlignment.Center)

    Theme.Label(card, "Name", branchName,
        UDim2.new(1, -56, 0, 24), UDim2.new(0, 48, 0, 10),
        Theme.Colors.Text, 13, Theme.Fonts.Bold)

    local hitbox = Instance.new("TextButton")
    hitbox.Size = UDim2.new(1,0,1,0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text = ""
    hitbox.Parent = card

    hitbox.MouseButton1Click:Connect(function()
        -- Highlight selected card
        if selectedCard then
            selectedCard.BackgroundColor3 = Theme.Colors.Surface
        end
        card.BackgroundColor3 = Theme.Colors.Surface3
        selectedCard = card
        showJobs(branchName)
    end)
end

-- Build all branch cards (excluding Hostile — players can't choose it)
local PLAYER_BRANCHES = {"Army","Marines","Navy","AirForce","SpaceForce","Civilian"}
for _, b in ipairs(PLAYER_BRANCHES) do
    buildBranchCard(b)
end

-- ─── Open hook ────────────────────────────────────────────────────────────────

local OpenBranchSelect = Instance.new("BindableFunction")
OpenBranchSelect.Name   = "Open_BranchSelect"
OpenBranchSelect.Parent = PlayerGui
OpenBranchSelect.OnInvoke = function()
    -- Refresh player data
    task.spawn(function()
        playerData = Remotes.InvokeServer("GetPlayerData")
    end)
    sg.Enabled = true
end

print("[JTF] BranchSelect: ready")
