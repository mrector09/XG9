-- Main.server.lua — boots all JTF services in dependency order.
-- Place this Script directly inside ServerScriptService/JTF (alongside the Services folder).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")

-- Shared modules live here after Rojo sync
local shared = ReplicatedStorage:WaitForChild("JTF", 15)
assert(shared, "ReplicatedStorage.JTF not found — check Rojo sync")

-- Service folder
local servicesFolder = script.Parent:WaitForChild("Services", 10)
assert(servicesFolder, "Services folder not found")

local function Service(name)
    return require(servicesFolder:WaitForChild(name, 10))
end

-- ─── 1. Remotes: must come first — all other services use it ──────────────────
local Remotes = require(shared:WaitForChild("Remotes"))
Remotes.Init()

-- ─── 2. Data: must come second — all services read/write player data ──────────
local DataService = Service("DataService")
DataService.Init()

-- ─── 3. Core progression ──────────────────────────────────────────────────────
local RankService    = Service("RankService")
local XPService      = Service("XPService")
local EconomyService = Service("EconomyService")

RankService.Init()
XPService.Init()
XPService.SetRankService(RankService)     -- wire circular dep
EconomyService.Init()

-- ─── 4. Teams and jobs ────────────────────────────────────────────────────────
local TeamService = Service("TeamService")
local WeaponService = Service("WeaponService")
local JobService  = Service("JobService")

TeamService.Init()
WeaponService.SetDependencies(TeamService, XPService, EconomyService)
WeaponService.Init()
JobService.SetDependencies(RankService, WeaponService)
JobService.Init()

-- ─── 5. Gameplay systems ──────────────────────────────────────────────────────
local MissionService    = Service("MissionService")
local DeploymentService = Service("DeploymentService")
local VehicleService    = Service("VehicleService")
local MedicalService    = Service("MedicalService")
local FlightService     = Service("FlightService")

MissionService.SetDependencies(XPService, EconomyService)
MissionService.Init()

DeploymentService.SetDependencies(XPService, EconomyService, MissionService, RankService)
DeploymentService.Init()

VehicleService.SetDependencies(JobService, XPService)
VehicleService.Init()

MedicalService.SetDependencies(XPService, MissionService)
MedicalService.Init()

FlightService.SetDependencies(XPService, MissionService)
FlightService.Init()

-- ─── 6. Meta / monetization systems ──────────────────────────────────────────
local GamepassService     = Service("GamepassService")
local BattlePassService   = Service("BattlePassService")
local DailyRewardService  = Service("DailyRewardService")
local SOFService          = Service("SpecialOperationsService")

GamepassService.SetDependencies(EconomyService, XPService)
GamepassService.Init()

BattlePassService.SetDependencies(EconomyService, XPService)
BattlePassService.Init()

DailyRewardService.SetDependencies(EconomyService, XPService, BattlePassService)
DailyRewardService.Init()

SOFService.SetDependencies(RankService, XPService)
SOFService.Init()

-- ─── 7. Player data remote callback ──────────────────────────────────────────
Remotes.SetCallback("GetPlayerData", function(player)
    return DataService.GetData(player)
end)

-- ─── 8. Leaderboard remote ────────────────────────────────────────────────────
local Players = game:GetService("Players")

Remotes.SetCallback("GetLeaderboard", function(player, category)
    -- Simple in-memory leaderboard from current players
    -- For persistent leaderboards use OrderedDataStore
    local results = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local data = DataService.GetData(p)
        if data then
            local value = 0
            if category == "XP"           then value = data.XP or 0
            elseif category == "Kills"    then value = data.TotalKills or 0
            elseif category == "Deploys"  then value = data.DeploymentsCompleted or 0
            end
            table.insert(results, { name = p.Name, value = value, userId = p.UserId })
        end
    end
    table.sort(results, function(a, b) return a.value > b.value end)
    return results
end)

-- ─── 9. Tutorial trigger ─────────────────────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
    task.delay(4, function()  -- after all services are ready
        local data = DataService.GetData(player)
        if data and not data.TutorialComplete then
            Remotes.FireClient("TutorialStepTriggered", player, { step = 1 })
        end
    end)
end)

print("[JTF] All services initialized. Server ready.")
