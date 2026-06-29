-- OverheadTag.client.lua — shows rank + name above every player's head.
-- Reads from player.leaderstats.Rank (StringValue set by RankService).

local Players = game:GetService("Players")

print("[JTF] OverheadTag client starting")

-- Rank abbreviations matched to RankConfig order
local RANK_ABBR = {
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

-- Color per tier group
local RANK_COLOR = {
    RCT = Color3.fromRGB(180, 190, 200),  -- enlisted: muted white
    PVT = Color3.fromRGB(180, 190, 200),
    SPC = Color3.fromRGB(180, 190, 200),
    SGT = Color3.fromRGB( 46, 175,  80),  -- NCO: green
    SSG = Color3.fromRGB( 46, 175,  80),
    SFC = Color3.fromRGB( 46, 175,  80),
    LT  = Color3.fromRGB(255, 184,   0),  -- officer: gold
    CPT = Color3.fromRGB(255, 184,   0),
    MAJ = Color3.fromRGB(255, 184,   0),
    COL = Color3.fromRGB(255, 210,  60),
    GEN = Color3.fromRGB(255, 230, 100),
}

local function getAbbr(rankName)
    return RANK_ABBR[rankName] or rankName:sub(1, 3):upper()
end

local function getColor(abbr)
    return RANK_COLOR[abbr] or Color3.fromRGB(200, 200, 200)
end

-- ─── Build the BillboardGui ────────────────────────────────────────────────────

local function makeTag(character, player)
    local head = character:WaitForChild("Head", 5)
    if not head then return end

    -- Remove any existing tag
    local existing = head:FindFirstChild("OverheadTag")
    if existing then existing:Destroy() end

    -- Read current rank from leaderstats
    local leaderstats = player:WaitForChild("leaderstats", 6)
    local rankValue   = leaderstats and leaderstats:FindFirstChild("Rank")
    local rankName    = (rankValue and rankValue.Value ~= "") and rankValue.Value or "Recruit"
    local abbr        = getAbbr(rankName)
    local rankColor   = getColor(abbr)

    -- BillboardGui
    local bill = Instance.new("BillboardGui")
    bill.Name             = "OverheadTag"
    bill.Size             = UDim2.new(0, 180, 0, 52)
    bill.StudsOffset      = Vector3.new(0, 2.8, 0)
    bill.AlwaysOnTop      = false
    bill.ResetOnSpawn     = false
    bill.LightInfluence   = 0
    bill.Parent           = head

    -- Outer frame (dark bg with slight transparency)
    local bg = Instance.new("Frame")
    bg.Name                   = "BG"
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3       = Color3.fromRGB(8, 10, 16)
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel        = 0
    bg.Parent                 = bill

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bg

    -- Accent left bar (rank color)
    local bar = Instance.new("Frame")
    bar.Name            = "Bar"
    bar.Size            = UDim2.new(0, 3, 1, -8)
    bar.Position        = UDim2.new(0, 5, 0, 4)
    bar.BackgroundColor3 = rankColor
    bar.BorderSizePixel  = 0
    bar.Parent           = bg
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    -- Rank abbreviation label
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name               = "RankLabel"
    rankLabel.Size               = UDim2.new(0, 42, 1, 0)
    rankLabel.Position           = UDim2.new(0, 13, 0, 0)
    rankLabel.Text               = abbr
    rankLabel.TextColor3         = rankColor
    rankLabel.Font               = Enum.Font.GothamBold
    rankLabel.TextSize           = 13
    rankLabel.BackgroundTransparency = 1
    rankLabel.TextXAlignment     = Enum.TextXAlignment.Left
    rankLabel.TextYAlignment     = Enum.TextYAlignment.Center
    rankLabel.Parent             = bg

    -- Separator
    local sep = Instance.new("Frame")
    sep.Size             = UDim2.new(0, 1, 0, 28)
    sep.Position         = UDim2.new(0, 54, 0.5, -14)
    sep.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
    sep.BorderSizePixel  = 0
    sep.Parent           = bg

    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name               = "NameLabel"
    nameLabel.Size               = UDim2.new(1, -65, 0.58, 0)
    nameLabel.Position           = UDim2.new(0, 60, 0, 4)
    nameLabel.Text               = player.DisplayName
    nameLabel.TextColor3         = Color3.fromRGB(230, 238, 248)
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextSize           = 13
    nameLabel.TextScaled         = false
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    nameLabel.Parent             = bg

    -- Username (smaller, muted) if display name differs
    local subLabel = Instance.new("TextLabel")
    subLabel.Name               = "SubLabel"
    subLabel.Size               = UDim2.new(1, -65, 0.4, 0)
    subLabel.Position           = UDim2.new(0, 60, 0.58, 0)
    subLabel.Text               = "@" .. player.Name
    subLabel.TextColor3         = Color3.fromRGB(100, 115, 135)
    subLabel.Font               = Enum.Font.Gotham
    subLabel.TextSize           = 10
    subLabel.TextScaled         = false
    subLabel.BackgroundTransparency = 1
    subLabel.TextXAlignment     = Enum.TextXAlignment.Left
    subLabel.TextTruncate       = Enum.TextTruncate.AtEnd
    subLabel.Parent             = bg

    -- Live-update when rank changes
    if rankValue then
        rankValue.Changed:Connect(function(newRankName)
            local newAbbr  = getAbbr(newRankName)
            local newColor = getColor(newAbbr)
            rankLabel.Text       = newAbbr
            rankLabel.TextColor3 = newColor
            bar.BackgroundColor3 = newColor
        end)
    end

    return bill
end

-- ─── Hook all players ─────────────────────────────────────────────────────────

local function onCharacterAdded(player, character)
    task.spawn(makeTag, character, player)
end

local function onPlayerAdded(player)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
end

-- Existing players (e.g. if script loads after PlayerAdded already fired)
for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

Players.PlayerAdded:Connect(onPlayerAdded)
