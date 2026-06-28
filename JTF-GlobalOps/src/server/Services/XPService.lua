-- XPService: awards XP, applies multipliers, syncs leaderstat, triggers rank checks.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)
local RankConfig  = require(script.Parent.Parent.Parent.shared.Config.RankConfig)

local XPService = {}

-- Deferred circular reference — set by Main after RankService is ready
local RankService

function XPService.SetRankService(rs)
    RankService = rs
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getXPMultiplier(data)
    local base = 1.0

    -- Prestige bonus
    if data.Prestige and data.Prestige > 0 then
        base = base * (RankConfig.PrestigeMultiplier ^ data.Prestige)
    end

    -- Gamepass XP boost
    for _, gp in pairs(data.OwnedGamepasses or {}) do
        if gp == true then
            -- XPBoost gamepass is checked specifically
        end
    end
    if data.OwnedGamepasses and data.OwnedGamepasses["XPBoost"] then
        base = base * 1.10
    end

    -- Temp XP booster
    if data.TempXPBoost and data.TempXPBoost > 0 then
        if os.time() < (data.TempXPBoostExpiry or 0) then
            base = base * data.TempXPBoost
        else
            -- Expired — clear it
            data.TempXPBoost = 0
            data.TempXPBoostExpiry = 0
        end
    end

    return base
end

-- ─── Award XP ─────────────────────────────────────────────────────────────────
-- source: key from RankConfig.XPSources or a custom string (for display only)
function XPService.AwardXP(player, amount, source)
    if amount <= 0 then return end

    local data = DataService.GetData(player)
    if not data then return end

    local multiplier = getXPMultiplier(data)
    local final      = math.floor(amount * multiplier)

    DataService.UpdateData(player, function(d)
        d.XP = d.XP + final
    end)

    -- Sync leaderstat
    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("XP") then
        ls.XP.Value = data.XP
    end

    Remotes.FireClient("XPAwarded", player, {
        amount  = final,
        source  = source or "Unknown",
        totalXP = data.XP,
    })

    -- Check whether XP warrants a rank promotion
    if RankService then
        RankService.CheckPromotion(player)
    end
end

function XPService.AwardXPFromSource(player, sourceKey)
    local base = RankConfig.XPSources[sourceKey]
    if not base then
        warn("[XPService] Unknown XP source:", sourceKey)
        return
    end
    XPService.AwardXP(player, base, sourceKey)
end

function XPService.GetXP(player)
    local data = DataService.GetData(player)
    return data and data.XP or 0
end

-- Apply a temporary XP booster
function XPService.ApplyTempBooster(player, multiplier, durationMinutes)
    DataService.UpdateData(player, function(d)
        d.TempXPBoost       = multiplier
        d.TempXPBoostExpiry = os.time() + durationMinutes * 60
    end)
end

-- Prestige: requires max rank, resets XP to 0 and increments Prestige
function XPService.Prestige(player)
    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    if data.Rank < #require(script.Parent.Parent.Parent.shared.Config.RankConfig).Ranks then
        return false, "Must be max rank to prestige"
    end

    DataService.UpdateData(player, function(d)
        d.XP       = 0
        d.Rank     = 1
        d.Prestige = (d.Prestige or 0) + 1
    end)

    Remotes.FireClient("NotificationSent", player, {
        title = "Prestige " .. data.Prestige,
        body  = "You have prestiged! XP multiplier increased.",
        icon  = "Prestige",
    })

    return true
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function XPService.Init()
    print("[XPService] Initialized.")
end

return XPService
