-- DailyRewardService: daily login streaks and reward progression.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)

local DailyRewardService = {}

local EconomyService     -- injected
local XPService          -- injected
local BattlePassService  -- injected

function DailyRewardService.SetDependencies(es, xs, bps)
    EconomyService    = es
    XPService         = xs
    BattlePassService = bps
end

-- Reward ladder (loops after day 7)
local DAILY_REWARDS = {
    [1] = { cash = 200,  xp = 50,   bonus = nil },
    [2] = { cash = 300,  xp = 75,   bonus = nil },
    [3] = { cash = 400,  xp = 100,  bonus = "SmallCrate" },
    [4] = { cash = 500,  xp = 125,  bonus = nil },
    [5] = { cash = 600,  xp = 150,  bonus = nil },
    [6] = { cash = 750,  xp = 200,  bonus = "SmallCrate" },
    [7] = { cash = 1000, xp = 300,  bonus = "LargeCrate" },
}

local function todayUTC()
    return os.date("!%Y-%m-%d")
end

-- ─── Streak management ────────────────────────────────────────────────────────
local function checkAndUpdateStreak(data)
    local today     = todayUTC()
    local lastLogin = data.LastLoginDate or ""

    if lastLogin == today then
        -- Already logged in today
        return data.DailyStreak or 1, false
    end

    -- Compute yesterday
    local ts        = os.time()
    local yesterday = os.date("!%Y-%m-%d", ts - 86400)

    local newStreak
    if lastLogin == yesterday then
        -- Consecutive day — increment streak
        newStreak = (data.DailyStreak or 0) + 1
    else
        -- Streak broken or first login
        newStreak = 1
    end

    data.DailyStreak    = newStreak
    data.LastLoginDate  = today

    return newStreak, true  -- true = reward available
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function DailyRewardService.GetRewardForDay(streakDay)
    local index = ((streakDay - 1) % 7) + 1
    return DAILY_REWARDS[index]
end

function DailyRewardService.IsRewardAvailable(player)
    local data = DataService.GetData(player)
    if not data then return false end
    return data.LastLoginDate ~= todayUTC()
end

function DailyRewardService.ClaimDailyReward(player)
    local data = DataService.GetData(player)
    if not data then return nil, "Data not ready" end

    local streak, isNew = checkAndUpdateStreak(data)

    -- Save the streak update immediately
    DataService.UpdateData(player, function(d)
        d.DailyStreak   = streak
        d.LastLoginDate = todayUTC()
        d.LastDailyClaim = os.time()
    end)

    if not isNew then
        return nil, "Already claimed today"
    end

    local reward = DailyRewardService.GetRewardForDay(streak)
    local multiplier = 1

    -- VIP gamepass doubles reward
    local GamepassService = require(script.Parent.GamepassService)
    if GamepassService and GamepassService.HasGamepass(player, "ExtraDailyRewards") then
        multiplier = 2
    end

    local finalCash = reward.cash * multiplier
    local finalXP   = reward.xp  * multiplier

    if EconomyService then EconomyService.AddCash(player, finalCash, "DailyReward") end
    if XPService      then XPService.AwardXP(player, finalXP, "DailyLogin") end
    if BattlePassService then BattlePassService.AddBPXPFromSource(player, "Login") end

    -- Bonus item (crate unlock flag)
    if reward.bonus then
        DataService.UpdateData(player, function(d)
            d.PendingCrates = d.PendingCrates or {}
            table.insert(d.PendingCrates, reward.bonus)
        end)
    end

    Remotes.FireClient("DailyRewardClaimed", player, {
        reward = {
            cash    = finalCash,
            xp      = finalXP,
            bonus   = reward.bonus,
            streak  = streak,
            day     = ((streak - 1) % 7) + 1,
        },
        streak = streak,
    })

    return reward, nil
end

-- ─── Auto-notify on join ──────────────────────────────────────────────────────
function DailyRewardService.Init()
    Remotes.SetCallback("ClaimDailyReward", function(player)
        return DailyRewardService.ClaimDailyReward(player)
    end)

    Players.PlayerAdded:Connect(function(player)
        task.delay(3, function()
            if DailyRewardService.IsRewardAvailable(player) then
                Remotes.FireClient("DailyRewardAvailable", player)
            end
        end)
    end)

    print("[DailyRewardService] Initialized.")
end

return DailyRewardService
