-- OverheadTag.server.lua
-- Server creates BillboardGuis so every client sees every player's tag.
-- Runs independently — no service dependencies needed.

local Players = game:GetService("Players")

print("[JTF] OverheadTag server: starting")

-- ─── Rank display data ────────────────────────────────────────────────────────

local ABBR = {
    ["Recruit"]              = "RCT",
    ["Private"]              = "PVT",
    ["Specialist"]           = "SPC",
    ["Sergeant"]             = "SGT",
    ["Staff Sergeant"]       = "SSG",
    ["Sergeant First Class"] = "SFC",
    ["Lieutenant"]           = "LT",
    ["Captain"]              = "CPT",
    ["Major"]                = "MAJ",
    ["Colonel"]              = "COL",
    ["General"]              = "GEN",
}

local TIER_COLOR = {
    RCT = Color3.fromRGB(170, 182, 196),
    PVT = Color3.fromRGB(170, 182, 196),
    SPC = Color3.fromRGB(170, 182, 196),
    SGT = Color3.fromRGB( 46, 175,  80),
    SSG = Color3.fromRGB( 46, 175,  80),
    SFC = Color3.fromRGB( 46, 175,  80),
    LT  = Color3.fromRGB(255, 184,   0),
    CPT = Color3.fromRGB(255, 184,   0),
    MAJ = Color3.fromRGB(255, 184,   0),
    COL = Color3.fromRGB(255, 210,  60),
    GEN = Color3.fromRGB(255, 230, 100),
}

local function getAbbr(rankName)
    return ABBR[rankName] or string.upper(string.sub(tostring(rankName or ""), 1, 3))
end

local function getColor(abbr)
    return TIER_COLOR[abbr] or Color3.fromRGB(170, 182, 196)
end

-- ─── Tag builder ─────────────────────────────────────────────────────────────

local function buildTag(head, player, rankName)
    local abbr  = getAbbr(rankName)
    local color = getColor(abbr)

    local bill = Instance.new("BillboardGui")
    bill.Name         = "OverheadTag"
    bill.Size         = UDim2.new(0, 210, 0, 58)
    bill.StudsOffset  = Vector3.new(0, 3.4, 0)
    bill.AlwaysOnTop  = false
    bill.MaxDistance  = 80
    bill.ResetOnSpawn = false
    bill.Parent       = head

    -- Dark panel background
    local bg = Instance.new("Frame")
    bg.Name                   = "BG"
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3       = Color3.fromRGB(7, 9, 14)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel        = 0
    bg.Parent                 = bill
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = bg

    -- Thin left accent bar (rank color)
    local bar = Instance.new("Frame")
    bar.Name             = "Bar"
    bar.Size             = UDim2.new(0, 3, 0, 36)
    bar.Position         = UDim2.new(0, 6, 0.5, -18)
    bar.BackgroundColor3 = color
    bar.BorderSizePixel  = 0
    bar.Parent           = bg
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bar

    -- Rank abbreviation
    local rankLbl = Instance.new("TextLabel")
    rankLbl.Name                 = "RankAbbr"
    rankLbl.Size                 = UDim2.new(0, 42, 1, 0)
    rankLbl.Position             = UDim2.new(0, 14, 0, 0)
    rankLbl.Text                 = abbr
    rankLbl.TextColor3           = color
    rankLbl.Font                 = Enum.Font.GothamBold
    rankLbl.TextSize             = 14
    rankLbl.BackgroundTransparency = 1
    rankLbl.TextXAlignment       = Enum.TextXAlignment.Left
    rankLbl.TextYAlignment       = Enum.TextYAlignment.Center
    rankLbl.Parent               = bg

    -- Vertical divider
    local div = Instance.new("Frame")
    div.Size             = UDim2.new(0, 1, 0, 32)
    div.Position         = UDim2.new(0, 58, 0.5, -16)
    div.BackgroundColor3 = Color3.fromRGB(40, 55, 75)
    div.BorderSizePixel  = 0
    div.Parent           = bg

    -- Display name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name                 = "PlayerName"
    nameLbl.Size                 = UDim2.new(1, -70, 0.55, 0)
    nameLbl.Position             = UDim2.new(0, 64, 0, 5)
    nameLbl.Text                 = player.DisplayName
    nameLbl.TextColor3           = Color3.fromRGB(232, 240, 252)
    nameLbl.Font                 = Enum.Font.GothamBold
    nameLbl.TextSize             = 13
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
    nameLbl.TextTruncate         = Enum.TextTruncate.AtEnd
    nameLbl.Parent               = bg

    -- @username subtitle
    local subLbl = Instance.new("TextLabel")
    subLbl.Name                 = "SubLabel"
    subLbl.Size                 = UDim2.new(1, -70, 0.42, 0)
    subLbl.Position             = UDim2.new(0, 64, 0.56, 0)
    subLbl.Text                 = "@" .. player.Name
    subLbl.TextColor3           = Color3.fromRGB(75, 90, 110)
    subLbl.Font                 = Enum.Font.Gotham
    subLbl.TextSize             = 10
    subLbl.BackgroundTransparency = 1
    subLbl.TextXAlignment       = Enum.TextXAlignment.Left
    subLbl.TextTruncate         = Enum.TextTruncate.AtEnd
    subLbl.Parent               = bg

    return bill
end

local function updateTagRank(head, rankName)
    local tag = head:FindFirstChild("OverheadTag")
    if not tag then return end
    local bg = tag:FindFirstChild("BG")
    if not bg then return end
    local abbr  = getAbbr(rankName)
    local color = getColor(abbr)
    local rl = bg:FindFirstChild("RankAbbr")
    local bar = bg:FindFirstChild("Bar")
    if rl  then rl.Text = abbr; rl.TextColor3 = color end
    if bar then bar.BackgroundColor3 = color end
end

-- ─── Per-player setup ────────────────────────────────────────────────────────

local function setupCharacter(player, character)
    local head = character:WaitForChild("Head", 10)
    if not head then
        warn("[OverheadTag] Head not found for", player.Name)
        return
    end

    -- Build tag immediately with default rank so it shows right away
    buildTag(head, player, "Recruit")
    print("[OverheadTag] Tag created for", player.Name)

    -- Update with real rank once leaderstats exist
    task.spawn(function()
        local ls = player:WaitForChild("leaderstats", 10)
        if not ls then
            warn("[OverheadTag] leaderstats missing for", player.Name)
            return
        end
        local rankVal = ls:WaitForChild("Rank", 6)
        if not rankVal then return end

        -- Apply current rank
        updateTagRank(head, rankVal.Value)

        -- Live-update on promotion
        rankVal.Changed:Connect(function(newRank)
            updateTagRank(head, newRank)
        end)
    end)
end

local function setupPlayer(player)
    player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
    -- Studio: character may already exist when this script runs
    if player.Character then
        task.spawn(setupCharacter, player, player.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end

Players.PlayerAdded:Connect(setupPlayer)

print("[JTF] OverheadTag server: ready")
