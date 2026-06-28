-- MissionService: manages active missions, objective tracking, daily/weekly generation.

local Players       = game:GetService("Players")
local Remotes       = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService   = require(script.Parent.DataService)
local MissionConfig = require(script.Parent.Parent.Parent.shared.Config.MissionConfig)

local MissionService = {}

local XPService      -- injected
local EconomyService -- injected

function MissionService.SetDependencies(xs, es)
    XPService      = xs
    EconomyService = es
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function todayUTC()
    return os.date("!%Y-%m-%d")
end

local function thisWeekUTC()
    local t = os.date("!*t")
    local dow = t.wday  -- 1=Sun … 7=Sat
    local daysToMonday = (dow == 1) and 6 or (dow - 2)
    local ts = os.time(t) - daysToMonday * 86400
    local monday = os.date("!%Y-%m-%d", ts)
    return monday
end

local function pickRandom(pool, count)
    local shuffled = {}
    for _, v in ipairs(pool) do table.insert(shuffled, v) end
    -- Fisher-Yates
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    local result = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(result, shuffled[i])
    end
    return result
end

-- ─── Daily mission generation ─────────────────────────────────────────────────
function MissionService.RefreshDailyMissions(player)
    local today = todayUTC()
    local data  = DataService.GetData(player)
    if not data then return end

    if data.DailyMissionsDate == today then
        return data.DailyMissions  -- already generated today
    end

    local count = MissionConfig.DailyCount
    -- VIP extra mission handled by GamepassService perks
    local picked = pickRandom(MissionConfig.DailyPool, count)

    local missions = {}
    for _, mission in ipairs(picked) do
        missions[mission.id] = { progress = 0, goal = mission.target, completed = false }
    end

    DataService.UpdateData(player, function(d)
        d.DailyMissions     = missions
        d.DailyMissionsDate = today
    end)

    Remotes.FireClient("DailyMissionsRefreshed", player, {
        missions = picked,
        date     = today,
    })

    return missions
end

-- ─── Objective tracking ───────────────────────────────────────────────────────
-- Called internally by other services (WeaponService, VehicleService, etc.)
function MissionService.TrackObjective(player, objectiveType, amount)
    local data = DataService.GetData(player)
    if not data then return end

    local today = todayUTC()
    if data.DailyMissionsDate ~= today then
        MissionService.RefreshDailyMissions(player)
        data = DataService.GetData(player)
    end

    local pool    = MissionConfig.DailyPool
    local updated = {}

    for _, mission in ipairs(pool) do
        local mData = data.DailyMissions and data.DailyMissions[mission.id]
        if mData and not mData.completed and mission.type == objectiveType then
            local newProgress = math.min(mData.progress + amount, mData.goal)
            DataService.UpdateData(player, function(d)
                d.DailyMissions[mission.id].progress = newProgress
            end)

            if newProgress >= mData.goal then
                MissionService.CompleteDailyMission(player, mission)
            else
                Remotes.FireClient("ObjectiveUpdated", player, {
                    missionId = mission.id,
                    progress  = newProgress,
                    goal      = mData.goal,
                })
            end

            table.insert(updated, mission.id)
        end
    end

    -- Track weekly deployment count
    if objectiveType == "DeployCount" then
        local weekTag = thisWeekUTC()
        DataService.UpdateData(player, function(d)
            if d.WeeklyResetDate ~= weekTag then
                d.WeeklyDeployCount = 0
                d.WeeklyOpClaimed   = false
                d.WeeklyResetDate   = weekTag
            end
            d.WeeklyDeployCount = (d.WeeklyDeployCount or 0) + amount
        end)
        MissionService.CheckWeeklyOp(player)
    end
end

function MissionService.CompleteDailyMission(player, mission)
    DataService.UpdateData(player, function(d)
        if d.DailyMissions[mission.id] then
            d.DailyMissions[mission.id].completed = true
        end
    end)

    if XPService then XPService.AwardXP(player, mission.xp, "DailyMission") end
    if EconomyService then EconomyService.AddCash(player, mission.cash, "DailyMission") end

    Remotes.FireClient("MissionCompleted", player, {
        missionId = mission.id,
        xp        = mission.xp,
        cash      = mission.cash,
    })

    Remotes.FireClient("NotificationSent", player, {
        title = "Daily Mission Complete!",
        body  = mission.label,
        icon  = "Mission",
    })
end

-- ─── Weekly operation check ───────────────────────────────────────────────────
function MissionService.CheckWeeklyOp(player)
    local data = DataService.GetData(player)
    if not data then return end
    if data.WeeklyOpClaimed then return end

    local weekly = MissionConfig.WeeklyOperation
    if (data.WeeklyDeployCount or 0) >= weekly.missions then
        MissionService.CompleteWeeklyOp(player)
    end
end

function MissionService.CompleteWeeklyOp(player)
    local weekly = MissionConfig.WeeklyOperation

    DataService.UpdateData(player, function(d)
        d.WeeklyOpClaimed = true
    end)

    if XPService then XPService.AwardXP(player, weekly.xpReward, "WeeklyOperation") end
    if EconomyService then EconomyService.AddCash(player, weekly.cashReward, "WeeklyOp") end

    Remotes.FireClient("NotificationSent", player, {
        title = "Weekly Operation Complete!",
        body  = weekly.displayName .. " — All objectives met.",
        icon  = "WeeklyOp",
    })
end

-- ─── Remote callbacks ─────────────────────────────────────────────────────────
function MissionService.Init()
    Remotes.SetCallback("GetMissions", function(player)
        local data = MissionService.RefreshDailyMissions(player)
        return {
            daily   = data,
            weekly  = {
                config  = MissionConfig.WeeklyOperation,
                progress = DataService.GetOrDefault(player, "WeeklyDeployCount") or 0,
                claimed  = DataService.GetOrDefault(player, "WeeklyOpClaimed") or false,
            },
        }
    end)

    Remotes.SetCallback("SubmitObjective", function(player, objectiveType, amount)
        MissionService.TrackObjective(player, objectiveType, amount or 1)
        local data = DataService.GetData(player)
        return data and data.DailyMissions or {}
    end)

    -- Refresh daily missions for each player on join
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function()
            MissionService.RefreshDailyMissions(player)
        end)
    end)

    print("[MissionService] Initialized.")
end

return MissionService
