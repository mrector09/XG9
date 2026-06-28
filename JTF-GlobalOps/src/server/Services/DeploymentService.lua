-- DeploymentService: manages deployments, ribbons, XP/cash on completion, teleporting.

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Remotes         = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService     = require(script.Parent.DataService)
local MissionConfig   = require(script.Parent.Parent.Parent.shared.Config.MissionConfig)

local DeploymentService = {}

local XPService       -- injected
local EconomyService  -- injected
local MissionService  -- injected
local RankService     -- injected

function DeploymentService.SetDependencies(xs, es, ms, rs)
    XPService      = xs
    EconomyService = es
    MissionService = ms
    RankService    = rs
end

-- Map name → Place ID for TeleportService (fill in real place IDs)
local MAP_PLACE_IDS = {
    Desert         = 0000000001,
    Jungle         = 0000000002,
    Arctic         = 0000000003,
    Mountain       = 0000000004,
    UrbanCity      = 0000000005,
    Island         = 0000000006,
    EuropeanForest = 0000000007,
    BorderRegion   = 0000000008,
}

-- Active deployment sessions: [userId] = { mapName, startTime, missionType }
local ActiveDeployments = {}

-- ─── Eligibility ──────────────────────────────────────────────────────────────
function DeploymentService.CanDeploy(player, mapName)
    local mapConfig = MissionConfig.Maps[mapName]
    if not mapConfig then return false, "Unknown map" end

    local data = DataService.GetData(player)
    if not data then return false, "Data not ready" end

    if (data.Rank or 1) < (mapConfig.minRank or 1) then
        return false, ("Requires minimum rank %d"):format(mapConfig.minRank)
    end

    return true
end

-- ─── Deployment start ─────────────────────────────────────────────────────────
function DeploymentService.Deploy(player, mapName, missionType)
    local ok, reason = DeploymentService.CanDeploy(player, mapName)
    if not ok then return false, reason end

    local mapConfig = MissionConfig.Maps[mapName]
    ActiveDeployments[player.UserId] = {
        mapName     = mapName,
        missionType = missionType or "Patrol",
        startTime   = os.time(),
        xpMult      = mapConfig.xpMultiplier or 1.0,
    }

    Remotes.FireClient("DeploymentStarted", player, { mapName = mapName, missionType = missionType })

    -- Teleport to the deployment place
    local placeId = MAP_PLACE_IDS[mapName]
    if placeId and placeId ~= 0 then
        local success = pcall(function()
            TeleportService:TeleportAsync(placeId, { player })
        end)
        if not success then
            warn("[DeploymentService] Teleport failed for", player.Name, "to", mapName)
        end
    else
        -- Single-place game: fire a local deployment event instead
        Remotes.FireClient("NotificationSent", player, {
            title = "Deploying to " .. mapName,
            body  = "Loading mission area...",
            icon  = "Deploy",
        })
    end

    return true
end

-- ─── Deployment end ───────────────────────────────────────────────────────────
-- results = { kills, assists, revives, objectivesComplete, survivalTime }
function DeploymentService.CompleteDeployment(player, results)
    local session = ActiveDeployments[player.UserId]
    if not session then return end

    ActiveDeployments[player.UserId] = nil

    local mapConfig    = MissionConfig.Maps[session.mapName]
    local missionConfig = MissionConfig.Types[session.missionType]
    if not missionConfig then return end

    local baseXP   = missionConfig.baseXP or 200
    local baseCash = missionConfig.baseCash or 150
    local xpMult   = session.xpMult or 1.0

    local totalXP   = math.floor(baseXP * xpMult)
    local totalCash = math.floor(baseCash * (RankService and RankService.GetPayMultiplier(player) or 1))

    -- Bonus for objectives
    local objBonus = (results and results.objectivesComplete or 0) * 50
    totalXP   = totalXP + objBonus
    totalCash = totalCash + math.floor(objBonus * 0.5)

    -- Award XP and cash
    if XPService      then XPService.AwardXP(player, totalXP, "DeploymentEnd") end
    if EconomyService then EconomyService.AddCash(player, totalCash, "Deployment") end

    -- Track deployment count
    DataService.UpdateData(player, function(d)
        d.DeploymentsCompleted = (d.DeploymentsCompleted or 0) + 1
    end)

    -- Award deployment ribbon
    if mapConfig and mapConfig.ribbon then
        DeploymentService.AwardRibbon(player, mapConfig.ribbon)
    end

    -- Notify MissionService
    if MissionService then
        MissionService.TrackObjective(player, "DeployCount", 1)
    end

    Remotes.FireClient("DeploymentEnded", player, {
        mapName  = session.mapName,
        xp       = totalXP,
        cash     = totalCash,
        results  = results,
    })
end

-- ─── Ribbons ──────────────────────────────────────────────────────────────────
function DeploymentService.AwardRibbon(player, ribbonId)
    local data = DataService.GetData(player)
    if not data then return end
    if data.DeploymentRibbons[ribbonId] then return end  -- already have it

    DataService.UpdateData(player, function(d)
        d.DeploymentRibbons[ribbonId] = true
    end)

    Remotes.FireClient("RibbonAwarded", player, { ribbonId = ribbonId })
    Remotes.FireClient("NotificationSent", player, {
        title = "Ribbon Awarded",
        body  = ribbonId .. " ribbon earned!",
        icon  = "Ribbon",
    })
end

-- ─── Remote callbacks ─────────────────────────────────────────────────────────
function DeploymentService.Init()
    Remotes.SetCallback("RequestDeploy", function(player, mapName, missionType)
        return DeploymentService.Deploy(player, mapName, missionType)
    end)

    -- Client fires this when a deployment mission concludes on the server map
    Remotes.On("MissionCompleted", function(player, payload)
        DeploymentService.CompleteDeployment(player, payload)
    end)

    print("[DeploymentService] Initialized.")
end

return DeploymentService
