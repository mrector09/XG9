-- VehicleController.client.lua
-- Drives the in-seat HUD (speedometer, fuel gauge, damage indicator)
-- and tracks driving stats for daily missions.
-- Place in StarterPlayerScripts — runs globally, not per-vehicle.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local shared      = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes     = require(shared:WaitForChild("Remotes"))
local VehicleConfig = require(shared:WaitForChild("Config"):WaitForChild("VehicleConfig"))

-- ─── State ────────────────────────────────────────────────────────────────────
local CurrentSeat    = nil
local CurrentVehicle = nil
local CurrentVehicleId = nil
local LastPosition   = nil
local StudsTraveled  = 0
local StudsReportTimer = 0
local STUDS_REPORT_INTERVAL = 50  -- report every 50 studs driven

-- ─── HUD helpers ──────────────────────────────────────────────────────────────
local function getVehicleHUD()
    return LocalPlayer.PlayerGui:FindFirstChild("VehicleHUD")
end

local function showVehicleHUD(vehicleId)
    local hud = getVehicleHUD()
    if hud then hud.Enabled = true end
    local config = VehicleConfig.Vehicles[vehicleId]
    -- Set vehicle name label
    if hud then
        local nameLabel = hud:FindFirstChild("VehicleName", true)
        if nameLabel and config then
            nameLabel.Text = config.displayName or vehicleId
        end
    end
end

local function hideVehicleHUD()
    local hud = getVehicleHUD()
    if hud then hud.Enabled = false end
end

local function updateSpeedometer(speed)
    local hud = getVehicleHUD()
    if not hud then return end
    local label = hud:FindFirstChild("SpeedLabel", true)
    if label then
        label.Text = math.floor(math.abs(speed)) .. " km/h"
    end
    local bar = hud:FindFirstChild("SpeedBar", true)
    local config = CurrentVehicleId and VehicleConfig.Vehicles[CurrentVehicleId]
    if bar and config then
        bar.Size = UDim2.new(math.clamp(math.abs(speed) / (config.maxSpeed or 80), 0, 1), 0, 1, 0)
    end
end

local function updateFuelGauge(fuel, maxFuel)
    local hud = getVehicleHUD()
    if not hud then return end
    local bar   = hud:FindFirstChild("FuelBar", true)
    local label = hud:FindFirstChild("FuelLabel", true)
    local pct   = maxFuel > 0 and (fuel / maxFuel) or 0
    if bar then
        bar.Size = UDim2.new(pct, 0, 1, 0)
        bar.BackgroundColor3 = pct < 0.2
            and Color3.fromRGB(220, 50, 50)
            or  Color3.fromRGB(60, 180, 60)
    end
    if label then
        label.Text = math.floor(pct * 100) .. "%"
    end
end

local function updateHealthBar(health, maxHealth)
    local hud = getVehicleHUD()
    if not hud then return end
    local bar = hud:FindFirstChild("VehicleHealthBar", true)
    if bar then
        local pct = maxHealth > 0 and (health / maxHealth) or 0
        bar.Size  = UDim2.new(pct, 0, 1, 0)
        bar.BackgroundColor3 = pct < 0.3
            and Color3.fromRGB(220, 50, 50)
            or  Color3.fromRGB(60, 180, 60)
    end
end

-- ─── Seat detection ───────────────────────────────────────────────────────────
local function onSeatOccupied(seat, vehicle, vehicleId)
    CurrentSeat      = seat
    CurrentVehicle   = vehicle
    CurrentVehicleId = vehicleId
    LastPosition     = vehicle.PrimaryPart and vehicle.PrimaryPart.Position
    StudsTraveled    = 0

    showVehicleHUD(vehicleId)

    local config = VehicleConfig.Vehicles[vehicleId]
    if config then
        updateFuelGauge(config.fuelCapacity, config.fuelCapacity)
        updateHealthBar(config.health, config.health)
    end
end

local function onSeatVacated()
    -- Report final stud count
    if StudsTraveled > 0 then
        Remotes.FireServer("WeaponFired")  -- placeholder — use a dedicated remote
        Remotes.InvokeServer("SubmitObjective", "DriveStuds", math.floor(StudsTraveled))
    end

    CurrentSeat      = nil
    CurrentVehicle   = nil
    CurrentVehicleId = nil
    LastPosition     = nil
    StudsTraveled    = 0
    hideVehicleHUD()
end

-- Watch character for VehicleSeat occupation
local function watchCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")

    humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local seat = humanoid.SeatPart
        if seat then
            local vehicle   = seat:FindFirstAncestorOfClass("Model")
            local vehicleId = vehicle and vehicle:GetAttribute("VehicleId")
            if vehicleId then
                onSeatOccupied(seat, vehicle, vehicleId)
            end
        else
            if CurrentSeat then
                onSeatVacated()
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(watchCharacter)
if LocalPlayer.Character then watchCharacter(LocalPlayer.Character) end

-- ─── Main update loop ─────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    if not CurrentVehicle or not CurrentVehicle.PrimaryPart then return end

    local primary = CurrentVehicle.PrimaryPart
    local vel     = primary.AssemblyLinearVelocity
    local speed   = vel.Magnitude * 3.6  -- studs/s → km/h (approx)

    updateSpeedometer(speed)

    -- Track studs for daily mission
    if LastPosition then
        local dist  = (primary.Position - LastPosition).Magnitude
        StudsTraveled   = StudsTraveled + dist
        StudsReportTimer = StudsReportTimer + dist

        if StudsReportTimer >= STUDS_REPORT_INTERVAL then
            StudsReportTimer = 0
            Remotes.InvokeServer("SubmitObjective", "DriveStuds", math.floor(STUDS_REPORT_INTERVAL))
        end
    end
    LastPosition = primary.Position
end)

-- ─── Server-pushed fuel/damage updates ───────────────────────────────────────
Remotes.OnClient("FuelUpdated", function(payload)
    if payload.vehicleId == CurrentVehicleId then
        updateFuelGauge(payload.fuel, payload.maxFuel or 100)
        if payload.fuel <= 0 then
            Remotes.FireClient and nil  -- suppress unused warning
            -- Show "OUT OF FUEL" warning
            local hud = getVehicleHUD()
            local warn_label = hud and hud:FindFirstChild("FuelWarning", true)
            if warn_label then warn_label.Visible = true end
        end
    end
end)

Remotes.OnClient("VehicleDamaged", function(payload)
    if payload.vehicleId == CurrentVehicleId then
        local config = VehicleConfig.Vehicles[CurrentVehicleId]
        updateHealthBar(payload.health, config and config.health or 1000)
    end
end)

-- ─── Turret control (keyboard fallback for non-VehicleSeat turrets) ──────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not CurrentSeat then return end
    if input.KeyCode == Enum.KeyCode.F then
        -- Eject from vehicle
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
    end
end)

print("[VehicleController] Loaded. F = eject vehicle.")
