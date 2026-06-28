-- BattlePassService: tier advancement, reward claiming, season tracking.

local Players         = game:GetService("Players")
local Remotes         = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService     = require(script.Parent.DataService)
local BattlePassConfig = require(script.Parent.Parent.Parent.shared.Config.BattlePassConfig)

local BattlePassService = {}

local EconomyService -- injected
local XPService      -- injected

function BattlePassService.SetDependencies(es, xs)
    EconomyService = es
    XPService      = xs
end

-- ─── BP XP ────────────────────────────────────────────────────────────────────
function BattlePassService.AddBPXP(player, amount, source)
    if amount <= 0 then return end

    local data = DataService.GetData(player)
    if not data then return end

    local xpPerTier = BattlePassConfig.BPXPPerTier
    local maxTier   = BattlePassConfig.MaxTier

    DataService.UpdateData(player, function(d)
        d.BattlePassXP = (d.BattlePassXP or 0) + amount
    end)

    -- Check tier advancement
    local newData = DataService.GetData(player)
    local newTier = math.min(
        math.floor((newData.BattlePassXP or 0) / xpPerTier),
        maxTier
    )

    if newTier > (newData.BattlePassTier or 0) then
        local oldTier = newData.BattlePassTier or 0
        DataService.UpdateData(player, function(d)
            d.BattlePassTier = newTier
        end)

        for tier = oldTier + 1, newTier do
            Remotes.FireClient("BPTierUnlocked", player, { tier = tier })
        end
    end

    Remotes.FireClient("BPXPAdded", player, {
        amount  = amount,
        source  = source,
        tier    = newData.BattlePassTier,
        totalXP = newData.BattlePassXP,
    })
end

-- Add BPXP from a known source key
function BattlePassService.AddBPXPFromSource(player, sourceKey)
    local amount = BattlePassConfig.BPXPSources[sourceKey]
    if amount then
        BattlePassService.AddBPXP(player, amount, sourceKey)
    end
end

-- Advance one tier (used by tier-skip developer product)
function BattlePassService.AdvanceTier(player)
    local data = DataService.GetData(player)
    if not data then return end

    local currentTier = data.BattlePassTier or 0
    if currentTier >= BattlePassConfig.MaxTier then return end

    DataService.UpdateData(player, function(d)
        d.BattlePassTier = currentTier + 1
        d.BattlePassXP   = (currentTier + 1) * BattlePassConfig.BPXPPerTier
    end)

    Remotes.FireClient("BPTierUnlocked", player, { tier = currentTier + 1 })
end

-- ─── Reward claiming ──────────────────────────────────────────────────────────
function BattlePassService.ClaimReward(player, tier, isPremium)
    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    if (data.BattlePassTier or 0) < tier then
        return false, "Tier not yet unlocked"
    end

    local claimKey = tostring(tier) .. (isPremium and "_p" or "_f")
    if data.BPClaimedTiers and data.BPClaimedTiers[claimKey] then
        return false, "Already claimed"
    end

    -- Check premium ownership
    if isPremium and not (data.BattlePassOwned) then
        return false, "Battle Pass not owned"
    end

    local tierData = BattlePassConfig.Tiers[tier]
    if not tierData then return false, "No rewards for this tier" end

    local reward = isPremium and tierData.premium or tierData.free
    if not reward then return false, "No reward" end

    -- Grant reward
    if reward.type == "Cash" and EconomyService then
        EconomyService.AddCash(player, reward.amount or 0, "BattlePass")
    elseif reward.type == "XP" and XPService then
        XPService.AwardXP(player, reward.amount or 0, "BattlePass")
    elseif reward.type == "Badge" then
        DataService.UpdateData(player, function(d)
            d.Badges        = d.Badges or {}
            d.Badges[reward.id] = true
        end)
    else
        -- Cosmetic, skin, emote, title — flagged in data for UI/appearance system
        DataService.UpdateData(player, function(d)
            d.UnlockedCosmetics = d.UnlockedCosmetics or {}
            d.UnlockedCosmetics[reward.id] = true
        end)
    end

    -- Mark claimed
    DataService.UpdateData(player, function(d)
        d.BPClaimedTiers        = d.BPClaimedTiers or {}
        d.BPClaimedTiers[claimKey] = true
    end)

    Remotes.FireClient("BPRewardClaimed", player, { tier = tier, reward = reward })
    return true, reward
end

-- ─── Remote callbacks ─────────────────────────────────────────────────────────
function BattlePassService.Init()
    Remotes.SetCallback("ClaimBPReward", function(player, tier, isPremium)
        return BattlePassService.ClaimReward(player, tier, isPremium)
    end)

    print("[BattlePassService] Initialized.")
end

return BattlePassService
