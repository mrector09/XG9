-- BattlePass.client.lua — season battle pass progress and reward claiming.

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local shared  = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme   = require(shared:WaitForChild("Theme"))
local Remotes = require(shared:WaitForChild("Remotes"))
local BPCfg   = require(shared:WaitForChild("Config"):WaitForChild("BattlePassConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Replace with the actual Roblox Gamepass ID for the premium battle pass.
local BP_GAMEPASS_ID = 000000099

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("BattlePass", 8)
sg.Enabled = false
sg.Parent  = PlayerGui

local root = Theme.Frame(sg, "Root",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Theme.Colors.BG)

-- Header
local header = Theme.Frame(root, "Header",
    UDim2.new(1,0,0,52), nil, Theme.Colors.Surface)
Theme.Frame(header, "Gold",
    UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), Theme.Colors.Primary)
Theme.Label(header, "Title",
    "BATTLE PASS — " .. BPCfg.SeasonName,
    UDim2.new(1,-120,1,0), UDim2.new(0,24,0,0),
    Theme.Colors.Primary, 16, Theme.Fonts.Bold)

local closeBtn = Theme.Button(header, "Close", "✕ Back",
    UDim2.new(0,88,0,32), UDim2.new(1,-100,0.5,-16), "ghost")
closeBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
    local mm = PlayerGui:FindFirstChild("MainMenu")
    if mm then mm.Enabled = true end
end)

-- ─── Progress strip ───────────────────────────────────────────────────────────
local progressStrip = Theme.Frame(root, "Progress",
    UDim2.new(1,0,0,72), UDim2.new(0,0,0,52), Theme.Colors.Surface2)
Theme.Padding(progressStrip, nil, 0, 24, 0, 24)

local tierLbl = Theme.Label(progressStrip, "TierLbl", "TIER 0",
    UDim2.new(0,80,0,28), UDim2.new(0,0,0,8),
    Theme.Colors.Primary, 24, Theme.Fonts.Bold)

Theme.Label(progressStrip, "SeasonEnd",
    "Season ends " .. BPCfg.SeasonEnd,
    UDim2.new(0,200,0,16), UDim2.new(0,88,0,14),
    Theme.Colors.TextSubtle, 10, Theme.Fonts.Regular)

-- XP bar
local xpBarTrack = Theme.Frame(progressStrip, "XPTrack",
    UDim2.new(1,-360,0,10), UDim2.new(0,88,0,44),
    Theme.Colors.Surface3)
Theme.Corner(xpBarTrack, Theme.Radius.Full)
local xpBarFill = Theme.Frame(xpBarTrack, "Fill",
    UDim2.new(0,0,1,0), nil, Theme.Colors.Primary)
Theme.Corner(xpBarFill, Theme.Radius.Full)

local xpLbl = Theme.Label(progressStrip, "XPLbl", "0 / 500 BP XP",
    UDim2.new(0,160,0,16), UDim2.new(1,-264,0,44),
    Theme.Colors.TextMuted, 10, Theme.Fonts.Mono,
    Enum.TextXAlignment.Right)

-- Premium purchase button
local purchaseBtn = Theme.Button(progressStrip, "Purchase",
    "⭐ GET PREMIUM — " .. BPCfg.PriceRobux .. " R$",
    UDim2.new(0,200,0,36), UDim2.new(1,-216,0.5,-18), "primary")
purchaseBtn.MouseButton1Click:Connect(function()
    MarketplaceService:PromptGamePassPurchase(LocalPlayer, BP_GAMEPASS_ID)
end)

-- ─── Tier track ───────────────────────────────────────────────────────────────
local trackBg = Theme.Frame(root, "TrackBG",
    UDim2.new(1,-48,0,190), UDim2.new(0,24,0,132),
    Theme.Colors.Surface)
Theme.Corner(trackBg, Theme.Radius.Md)
Theme.Stroke(trackBg, Theme.Colors.Border)

local tierScroll = Instance.new("ScrollingFrame")
tierScroll.Name                   = "TierScroll"
tierScroll.Size                   = UDim2.new(1,-16,1,-16)
tierScroll.Position               = UDim2.new(0,8,0,8)
tierScroll.BackgroundTransparency = 1
tierScroll.BorderSizePixel        = 0
tierScroll.ScrollBarThickness     = 4
tierScroll.ScrollBarImageColor3   = Theme.Colors.Border
tierScroll.ScrollingDirection     = Enum.ScrollingDirection.X
tierScroll.CanvasSize             = UDim2.new(0,0,0,0)
tierScroll.AutomaticCanvasSize    = Enum.AutomaticSize.X
tierScroll.Parent                 = trackBg

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection  = Enum.FillDirection.Horizontal
listLayout.Padding        = UDim2.new(0, 6)
listLayout.SortOrder      = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Parent             = tierScroll

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

-- ─── Reward label helper ──────────────────────────────────────────────────────
local REWARD_ICON = {
    Cash        = "💰",  XP          = "⭐",  Badge      = "🏅",
    Cosmetic    = "👕",  WeaponSkin  = "🔫",  VehicleSkin = "🚗",
    Emote       = "💃",  Title       = "📛",
}

local function rewardText(reward)
    if not reward then return "—" end
    local icon = REWARD_ICON[reward.type] or "◆"
    if reward.type == "Cash" then return icon .. " $" .. (reward.amount or "?") end
    if reward.type == "XP"   then return icon .. " +" .. (reward.amount or "?") end
    return icon .. " " .. (reward.id or reward.type)
end

-- ─── Tier card builder ────────────────────────────────────────────────────────
local MILESTONE = { [10]=true,[20]=true,[25]=true,[30]=true,[40]=true,[50]=true }

local tierCardRefs = {}

local function buildTierCards(playerTier, ownsBP, claimedTiers)
    for _, c in ipairs(tierScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    tierCardRefs = {}

    for tier = 1, BPCfg.MaxTier do
        local isReached   = tier <= playerTier
        local isMilestone = MILESTONE[tier]
        local tierData    = BPCfg.Tiers[tier] or {}
        local freeClaimed = claimedTiers and claimedTiers["free_"  .. tier]
        local premClaimed = claimedTiers and claimedTiers["prem_"  .. tier]

        local cardW = isMilestone and 118 or 90

        local card = Theme.Frame(tierScroll, "Tier" .. tier,
            UDim2.new(0, cardW, 1, -14),
            UDim2.new(0, 0, 0, 7),
            isReached and Theme.Colors.Surface2 or Theme.Colors.Surface)
        card.LayoutOrder = tier
        Theme.Corner(card, Theme.Radius.Md)
        Theme.Stroke(card,
            isMilestone and Theme.Colors.Primary or
            (isReached   and Theme.Colors.BorderBright or Theme.Colors.Border))

        -- Tier number
        Theme.Label(card, "TierNum", tostring(tier),
            UDim2.new(1,0,0,22), UDim2.new(0,0,0,4),
            isMilestone and Theme.Colors.Primary or
            (isReached   and Theme.Colors.Text or Theme.Colors.TextSubtle),
            isMilestone and 16 or 12, Theme.Fonts.Bold,
            Enum.TextXAlignment.Center)

        -- Divider under tier number
        local div = Theme.Divider(card)
        div.Position = UDim2.new(0,6,0,28)
        div.Size     = UDim2.new(1,-12,0,1)

        -- Free reward row
        local freeRow = Theme.Frame(card, "FreeRow",
            UDim2.new(1,0,0,38), UDim2.new(0,0,0,32),
            Color3.new(0,0,0), 1)
        Theme.Label(freeRow, "Tag", "FREE",
            UDim2.new(1,0,0,12), nil,
            Theme.Colors.TextSubtle, 7, Theme.Fonts.Bold,
            Enum.TextXAlignment.Center)
        Theme.Label(freeRow, "Reward",
            rewardText(tierData.free),
            UDim2.new(1,-4,0,14), UDim2.new(0,2,0,14),
            (freeClaimed and Theme.Colors.TextSubtle) or
            (isReached   and Theme.Colors.Text       or Theme.Colors.TextMuted),
            7, Theme.Fonts.Regular, Enum.TextXAlignment.Center)

        if isReached and tierData.free and not freeClaimed then
            local claimBtn = Theme.Button(card, "ClaimFree", "CLAIM",
                UDim2.new(1,-8,0,18), UDim2.new(0,4,0,50), "success")
            claimBtn.TextSize = 8
            local t = tier
            claimBtn.MouseButton1Click:Connect(function()
                local ok = Remotes.InvokeServer("ClaimBPReward", t)
                if ok then
                    setStatus("✓ Tier " .. t .. " reward claimed!", true)
                    claimBtn.Text = "✓"
                    claimBtn.BackgroundColor3 = Theme.Colors.TextSubtle
                else
                    setStatus("✗ Could not claim this reward", false)
                end
            end)
        end

        -- Premium reward row
        local premY = isReached and 74 or 72
        local premRow = Theme.Frame(card, "PremRow",
            UDim2.new(1,0,0,40), UDim2.new(0,0,0,premY),
            ownsBP and Theme.Colors.Surface3 or Color3.new(0,0,0),
            ownsBP and 0 or 1)
        if ownsBP then Theme.Corner(premRow, Theme.Radius.Sm) end

        Theme.Label(premRow, "Tag", "PREMIUM",
            UDim2.new(1,0,0,12), nil,
            ownsBP and Theme.Colors.Primary or Theme.Colors.TextSubtle,
            7, Theme.Fonts.Bold, Enum.TextXAlignment.Center)
        Theme.Label(premRow, "Reward",
            ownsBP and rewardText(tierData.premium) or "🔒",
            UDim2.new(1,-4,0,14), UDim2.new(0,2,0,14),
            (premClaimed and Theme.Colors.TextSubtle) or
            (ownsBP      and Theme.Colors.Text        or Theme.Colors.TextSubtle),
            7, Theme.Fonts.Regular, Enum.TextXAlignment.Center)

        if ownsBP and isReached and tierData.premium and not premClaimed then
            local claimBtn = Theme.Button(card, "ClaimPrem", "CLAIM",
                UDim2.new(1,-8,0,18), UDim2.new(0,4,0,premY + 22), "primary")
            claimBtn.TextSize = 8
            local t = tier
            claimBtn.MouseButton1Click:Connect(function()
                local ok = Remotes.InvokeServer("ClaimBPReward", t, true)
                if ok then
                    setStatus("✓ Premium tier " .. t .. " reward claimed!", true)
                    claimBtn.Text = "✓"
                    claimBtn.BackgroundColor3 = Theme.Colors.TextSubtle
                else
                    setStatus("✗ Could not claim this reward", false)
                end
            end)
        end

        tierCardRefs[tier] = card
    end
end

-- ─── Scroll to current tier ───────────────────────────────────────────────────
local function scrollToTier(tier)
    local card = tierCardRefs[tier]
    if not card then return end
    task.wait(0.12)
    local absX  = card.AbsolutePosition.X - tierScroll.AbsolutePosition.X
    local canvas = tierScroll.CanvasPosition
    TweenService:Create(tierScroll,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad),
        { CanvasPosition = Vector2.new(math.max(0, canvas.X + absX - 40), 0) }
    ):Play()
end

-- ─── Data refresh ─────────────────────────────────────────────────────────────
local function refresh()
    local data = Remotes.InvokeServer("GetPlayerData")
    if not data then return end

    local tier    = data.BattlePassTier   or 0
    local bpXP    = data.BattlePassXP     or 0
    local ownsBP  = data.BattlePassOwned  or false
    local claimed = data.BPClaimedTiers   or {}

    tierLbl.Text          = "TIER " .. tier
    purchaseBtn.Visible   = not ownsBP

    local xpInTier = bpXP % BPCfg.BPXPPerTier
    local pct      = xpInTier / BPCfg.BPXPPerTier
    TweenService:Create(xpBarFill,
        TweenInfo.new(0.4, Enum.EasingStyle.Quad),
        { Size = UDim2.new(pct, 0, 1, 0) }
    ):Play()
    xpLbl.Text = xpInTier .. " / " .. BPCfg.BPXPPerTier .. " BP XP"

    buildTierCards(tier, ownsBP, claimed)
    scrollToTier(math.max(1, tier))
end

-- ─── Open hook ────────────────────────────────────────────────────────────────
local OpenBP = Instance.new("BindableFunction")
OpenBP.Name   = "Open_BattlePass"
OpenBP.Parent = PlayerGui
OpenBP.OnInvoke = function()
    sg.Enabled = true
    task.spawn(refresh)
end

Remotes.OnClient("BPTierUnlocked", function(payload)
    if sg.Enabled then
        tierLbl.Text = "TIER " .. (payload.tier or "?")
    end
end)

print("[JTF] BattlePass: ready")
