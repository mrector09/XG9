-- VehicleService: spawning, fuel, turrets, permissions, despawn.

local Players       = game:GetService("Players")
local Remotes       = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService   = require(script.Parent.DataService)
local VehicleConfig = require(script.Parent.Parent.Parent.shared.Config.VehicleConfig)

local VehicleService = {}

local JobService  -- injected
local XPService   -- injected

function VehicleService.SetDependencies(js, xs)
    JobService = js
    XPService  = xs
end

-- Active vehicle instances: [vehicleModel] = { ownerId, vehicleId, fuel, health }
local ActiveVehicles = {}

-- Fuel tick interval (seconds)
local FUEL_TICK = 5

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getTemplate(vehicleId)
    local storage = game.ServerStorage:FindFirstChild("Vehicles")
    return storage and storage:FindFirstChild(vehicleId)
end

local function fuelLoop(model, config)
    task.spawn(function()
        while model and model.Parent do
            task.wait(FUEL_TICK)
            local state = ActiveVehicles[model]
            if not state then break end

            -- Only drain fuel if a player is driving (primary seat occupied)
            local seat = model:FindFirstChildWhichIsA("VehicleSeat")
            if seat and seat.Occupant then
                local drain = (config.fuelPerStud or 0.05) * (config.maxSpeed or 50) * FUEL_TICK * 0.1
                state.fuel  = math.max(0, state.fuel - drain)

                local driver = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
                if driver then
                    Remotes.FireClient("FuelUpdated", driver, {
                        vehicleId = state.vehicleId,
                        fuel      = state.fuel,
                        maxFuel   = config.fuelCapacity,
                    })
                end

                if state.fuel <= 0 then
                    -- Kill engine: zero max speed
                    seat.MaxSpeed = 0
                end
            end
        end
    end)
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function VehicleService.CanSpawnVehicle(player, vehicleId)
    local config = VehicleConfig.Vehicles[vehicleId]
    if not config then return false, "Unknown vehicle" end

    if JobService then
        local ok, reason = JobService.CanDriveVehicle(player, vehicleId)
        if not ok then return false, reason end
    end

    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    -- Spawn cost check
    local cost = config.spawnCost or 0
    if cost > 0 and (data.Cash or 0) < cost then
        return false, ("Requires %d cash to spawn"):format(cost)
    end

    return true
end

function VehicleService.SpawnVehicle(player, vehicleId, spawnPosition)
    local ok, reason = VehicleService.CanSpawnVehicle(player, vehicleId)
    if not ok then return nil, reason end

    local config   = VehicleConfig.Vehicles[vehicleId]
    local template = getTemplate(vehicleId)

    if not template then
        return nil, "Vehicle model not found in ServerStorage"
    end

    -- Deduct spawn cost
    if (config.spawnCost or 0) > 0 then
        local EconomyService = require(script.Parent.EconomyService)
        EconomyService.RemoveCash(player, config.spawnCost, "VehicleSpawn")
    end

    local model = template:Clone()
    model:SetPrimaryPartCFrame(CFrame.new(spawnPosition or Vector3.new(0, 5, 0)))
    model.Parent = workspace

    ActiveVehicles[model] = {
        ownerId   = player.UserId,
        vehicleId = vehicleId,
        fuel      = config.fuelCapacity,
        health    = config.health,
    }

    -- Tag owner
    local ownerTag = Instance.new("IntValue")
    ownerTag.Name  = "OwnerId"
    ownerTag.Value = player.UserId
    ownerTag.Parent = model

    fuelLoop(model, config)

    Remotes.FireClient("VehicleSpawned", player, {
        vehicleId = vehicleId,
        modelName = model.Name,
    })

    return model
end

function VehicleService.DespawnVehicle(model)
    if ActiveVehicles[model] then
        ActiveVehicles[model] = nil
    end
    if model and model.Parent then
        model:Destroy()
    end
end

function VehicleService.RefuelVehicle(model, amount)
    local state = ActiveVehicles[model]
    if not state then return end
    local config = VehicleConfig.Vehicles[state.vehicleId]
    state.fuel   = math.min(state.fuel + amount, config and config.fuelCapacity or 100)
end

function VehicleService.DamageVehicle(model, damage)
    local state = ActiveVehicles[model]
    if not state then return end
    state.health = math.max(0, state.health - damage)

    if state.health <= 0 then
        -- Destroy vehicle after short delay
        task.delay(1.5, function()
            VehicleService.DespawnVehicle(model)
        end)
    end
end

-- Track driving studs for daily missions
function VehicleService.TrackDriving(player, studs)
    local MissionService = require(script.Parent.MissionService)
    if MissionService then
        MissionService.TrackObjective(player, "DriveStuds", studs)
    end
    DataService.UpdateData(player, function(d)
        d.DrivingStuds = (d.DrivingStuds or 0) + studs
    end)
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function VehicleService.Init()
    Remotes.SetCallback("SpawnVehicle", function(player, vehicleId)
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local spawnPos = hrp and (hrp.Position + hrp.CFrame.LookVector * 15) or Vector3.new(0, 5, 0)
        return VehicleService.SpawnVehicle(player, vehicleId, spawnPos)
    end)

    print("[VehicleService] Initialized.")
end

return VehicleService
