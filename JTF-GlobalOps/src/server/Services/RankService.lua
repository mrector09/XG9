-- RankService: manages rank promotion, demotion, and rank-based permission checks.

local Players   = game:GetService("Players")
local Remotes   = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)
local RankConfig  = require(script.Parent.Parent.Parent.shared.Config.RankConfig)

local RankService = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getRankIndex(data)
    return data.Rank or 1
end

local function notifyRankChange(player, newIndex)
    local rankData = RankConfig.Ranks[newIndex]
    if not rankData then return end

    -- Update Roblox leaderboard display
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local rankStat = leaderstats:FindFirstChild("Rank")
        if rankStat then rankStat.Value = rankData.name end
    end

    Remotes.FireClient("RankChanged", player, {
        rankIndex = newIndex,
        rankName  = rankData.name,
    })

    Remotes.FireClient("NotificationSent", player, {
        title = "Promoted!",
        body  = "You are now " .. rankData.name,
        icon  = "Rank",
    })
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function RankService.GetRankIndex(player)
    local data = DataService.GetData(player)
    return data and getRankIndex(data) or 1
end

function RankService.GetRankName(player)
    local idx = RankService.GetRankIndex(player)
    return RankConfig.Ranks[idx] and RankConfig.Ranks[idx].name or "Unknown"
end

function RankService.GetRankData(rankIndex)
    return RankConfig.Ranks[rankIndex]
end

-- Check whether XP warrants an automatic promotion
function RankService.CheckPromotion(player)
    local data = DataService.GetData(player)
    if not data then return end

    local maxRank = #RankConfig.Ranks
    local current = getRankIndex(data)
    if current >= maxRank then return end

    local nextRank = RankConfig.Ranks[current + 1]
    if nextRank and data.XP >= nextRank.xp then
        RankService.PromotePlayer(player, "XP threshold reached")
    end
end

function RankService.PromotePlayer(player, reason)
    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    local maxRank = #RankConfig.Ranks
    local current = getRankIndex(data)

    if current >= maxRank then
        return false, "Already at maximum rank"
    end

    DataService.UpdateData(player, function(d)
        d.Rank = current + 1
    end)

    notifyRankChange(player, current + 1)

    print(("[RankService] %s promoted to %s (%s)"):format(
        player.Name,
        RankConfig.Ranks[current + 1].name,
        reason or "manual"
    ))

    -- Chain: check if they can be promoted again immediately
    RankService.CheckPromotion(player)

    return true
end

function RankService.DemotePlayer(player, reason)
    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    local current = getRankIndex(data)
    if current <= 1 then
        return false, "Already at minimum rank"
    end

    DataService.UpdateData(player, function(d)
        d.Rank = current - 1
    end)

    notifyRankChange(player, current - 1)

    print(("[RankService] %s demoted to %s (%s)"):format(
        player.Name,
        RankConfig.Ranks[current - 1].name,
        reason or "manual"
    ))

    return true
end

function RankService.SetRank(player, rankIndex)
    local data = DataService.GetData(player)
    if not data then return false end
    local clamped = math.clamp(rankIndex, 1, #RankConfig.Ranks)
    DataService.UpdateData(player, function(d)
        d.Rank = clamped
    end)
    notifyRankChange(player, clamped)
    return true
end

function RankService.HasPermission(player, perm)
    local idx      = RankService.GetRankIndex(player)
    local rankData = RankConfig.Ranks[idx]
    return rankData and rankData[perm] == true
end

function RankService.MeetsMinRank(player, minIndex)
    return RankService.GetRankIndex(player) >= minIndex
end

function RankService.GetPayMultiplier(player)
    local idx = RankService.GetRankIndex(player)
    return RankConfig.Ranks[idx] and RankConfig.Ranks[idx].pay or 1.0
end

-- ─── Leaderstat setup ─────────────────────────────────────────────────────────
local function setupLeaderstats(player)
    local ls = Instance.new("Folder")
    ls.Name  = "leaderstats"
    ls.Parent = player

    local rank = Instance.new("StringValue")
    rank.Name  = "Rank"
    rank.Value = "Recruit"
    rank.Parent = ls

    local xp = Instance.new("IntValue")
    xp.Name  = "XP"
    xp.Value = 0
    xp.Parent = ls

    local cash = Instance.new("IntValue")
    cash.Name  = "Cash"
    cash.Value = 0
    cash.Parent = ls
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function RankService.Init()
    Players.PlayerAdded:Connect(function(player)
        setupLeaderstats(player)
        -- Sync leaderstat to saved rank once data loads (brief wait)
        task.delay(1, function()
            local data = DataService.GetData(player)
            if not data then return end
            local ls = player:FindFirstChild("leaderstats")
            if ls then
                local rankEntry = RankConfig.Ranks[data.Rank]
                if rankEntry then
                    ls.Rank.Value = rankEntry.name
                end
                ls.XP.Value   = data.XP
                ls.Cash.Value = data.Cash
            end
        end)
    end)
    print("[RankService] Initialized.")
end

return RankService
