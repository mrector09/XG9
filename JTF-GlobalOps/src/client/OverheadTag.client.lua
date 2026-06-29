-- OverheadTag.client.lua — rank tag above every player's head.
-- No module dependencies; reads leaderstats.Rank once available.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("[JTF] OverheadTag: script started")

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
    RCT = Color3.fromRGB(180, 190, 200),
    PVT = Color3.fromRGB(180, 190, 200),
    SPC = Color3.fromRGB(180, 190, 200),
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
    return ABBR[rankName] or string.upper(string.sub(rankName or "RCT", 1, 3))
end

local function getColor(abbr)
    return TIER_COLOR[abbr] or Color3.fromRGB(200, 200, 200)
end

local function buildTag(player, character)
    print("[JTF] OverheadTag: building tag for", player.Name)

    local head = character:WaitForChild("Head", 10)
    if not head then
        warn("[JTF] OverheadTag: no Head found for", player.Name)
        return
    end

    -- Remove stale tag
    local old = head:FindFirstChild("OverheadTag")
    if old then old:Destroy() end

    -- ── BillboardGui ──────────────────────────────────────────────────────────
    local bill = Instance.new("BillboardGui")
    bill.Name         = "OverheadTag"
    bill.Size         = UDim2.new(0, 200, 0, 56)
    bill.StudsOffset  = Vector3.new(0, 3.2, 0)
    bill.AlwaysOnTop  = false
    bill.ResetOnSpawn = false
    bill.MaxDistance  = 80
    bill.Parent       = head

    -- Dark background
    local bg = Instance.new("Frame")
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3       = Color3.fromRGB(8, 10, 16)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel        = 0
    bg.Parent                 = bill
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 6)
    bgCorner.Parent = bg

    -- Rank abbreviation (left, colored by tier)
    local rankLbl = Instance.new("TextLabel")
    rankLbl.Name                 = "RankAbbr"
    rankLbl.Size                 = UDim2.new(0, 46, 1, 0)
    rankLbl.Position             = UDim2.new(0, 8, 0, 0)
    rankLbl.Text                 = "RCT"
    rankLbl.TextColor3           = Color3.fromRGB(180, 190, 200)
    rankLbl.Font                 = Enum.Font.GothamBold
    rankLbl.TextSize             = 14
    rankLbl.BackgroundTransparency = 1
    rankLbl.TextXAlignment       = Enum.TextXAlignment.Left
    rankLbl.TextYAlignment       = Enum.TextYAlignment.Center
    rankLbl.Parent               = bg

    -- Divider
    local div = Instance.new("Frame")
    div.Size             = UDim2.new(0, 1, 0, 30)
    div.Position         = UDim2.new(0, 56, 0.5, -15)
    div.BackgroundColor3 = Color3.fromRGB(50, 65, 85)
    div.BorderSizePixel  = 0
    div.Parent           = bg

    -- Player display name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name                 = "PlayerName"
    nameLbl.Size                 = UDim2.new(1, -66, 0.55, 0)
    nameLbl.Position             = UDim2.new(0, 62, 0, 4)
    nameLbl.Text                 = player.DisplayName
    nameLbl.TextColor3           = Color3.fromRGB(230, 238, 250)
    nameLbl.Font                 = Enum.Font.GothamBold
    nameLbl.TextSize             = 13
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
    nameLbl.TextTruncate         = Enum.TextTruncate.AtEnd
    nameLbl.Parent               = bg

    -- @username subtitle
    local subLbl = Instance.new("TextLabel")
    subLbl.Name                 = "UserName"
    subLbl.Size                 = UDim2.new(1, -66, 0.42, 0)
    subLbl.Position             = UDim2.new(0, 62, 0.55, 0)
    subLbl.Text                 = "@" .. player.Name
    subLbl.TextColor3           = Color3.fromRGB(90, 105, 125)
    subLbl.Font                 = Enum.Font.Gotham
    subLbl.TextSize             = 10
    subLbl.BackgroundTransparency = 1
    subLbl.TextXAlignment       = Enum.TextXAlignment.Left
    subLbl.TextTruncate         = Enum.TextTruncate.AtEnd
    subLbl.Parent               = bg

    -- ── Read leaderstats (may arrive after character) ─────────────────────────
    local function applyRank(rankName)
        local abbr  = getAbbr(rankName)
        local color = getColor(abbr)
        rankLbl.Text       = abbr
        rankLbl.TextColor3 = color
    end

    -- Try to find leaderstats immediately; if not ready, wait in background
    task.spawn(function()
        local ls = player:WaitForChild("leaderstats", 10)
        if not ls then
            warn("[JTF] OverheadTag: leaderstats not found for", player.Name, "— server may not have started")
            return
        end
        local rankVal = ls:WaitForChild("Rank", 5)
        if rankVal then
            applyRank(rankVal.Value)
            rankVal.Changed:Connect(applyRank)
        end
    end)

    print("[JTF] OverheadTag: tag built for", player.Name)
end

-- ── Hook players ──────────────────────────────────────────────────────────────

local function onPlayer(player)
    -- Already spawned
    if player.Character then
        task.spawn(buildTag, player, player.Character)
    end
    -- Future spawns
    player.CharacterAdded:Connect(function(char)
        task.spawn(buildTag, player, char)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    onPlayer(p)
end

Players.PlayerAdded:Connect(onPlayer)

print("[JTF] OverheadTag: ready, watching", #Players:GetPlayers(), "player(s)")
