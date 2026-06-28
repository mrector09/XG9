-- FlightService: pilot licenses, flight hours, parachutes, airborne operations.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)

local FlightService = {}

local XPService  -- injected
local MissionService -- injected

function FlightService.SetDependencies(xs, ms)
    XPService      = xs
    MissionService = ms
end

-- License IDs and requirements
local LICENSES = {
    RotaryWingLicense  = { school = "FlightSchool",        displayName = "Rotary Wing License" },
    FixedWingLicense   = { school = "AdvancedFlightSchool", displayName = "Fixed Wing License"  },
    AttackPilotLicense = { school = "AttackFlightSchool",   displayName = "Attack Pilot License"},
    DroneLicense       = { school = "FlightSchool",         displayName = "Drone Operator License" },
}

-- Active parachutes: [player] = { deployTime, landedCallback }
local ActiveParachutes = {}

-- ─── Public API ───────────────────────────────────────────────────────────────
function FlightService.HasLicense(player, licenseId)
    local data = DataService.GetData(player)
    if not data then return false end
    return data.SchoolsCompleted and data.SchoolsCompleted[LICENSES[licenseId] and LICENSES[licenseId].school] == true
end

function FlightService.GrantLicense(player, licenseId)
    local license = LICENSES[licenseId]
    if not license then return false, "Unknown license" end

    DataService.UpdateData(player, function(d)
        d.SchoolsCompleted = d.SchoolsCompleted or {}
        d.SchoolsCompleted[license.school] = true
    end)

    Remotes.FireClient("NotificationSent", player, {
        title = "License Earned",
        body  = license.displayName .. " — you are now certified.",
        icon  = "Pilot",
    })

    return true
end

-- Log flight time in minutes
function FlightService.LogFlightTime(player, minutes)
    if minutes <= 0 then return end

    DataService.UpdateData(player, function(d)
        d.FlightHours = (d.FlightHours or 0) + minutes
    end)

    local data = DataService.GetData(player)
    Remotes.FireClient("FlightHoursUpdated", player, {
        hours = (data.FlightHours or 0) / 60,
    })

    if MissionService then
        MissionService.TrackObjective(player, "FlyStuds", math.floor(minutes * 10))
    end

    if XPService then
        local xp = math.floor(minutes * 5)
        XPService.AwardXP(player, xp, "FlightTime")
    end
end

function FlightService.GetFlightHours(player)
    local data = DataService.GetData(player)
    return data and ((data.FlightHours or 0) / 60) or 0
end

-- ─── Parachute system ─────────────────────────────────────────────────────────
function FlightService.DeployParachute(player)
    if ActiveParachutes[player] then return false, "Parachute already deployed" end

    local char = player.Character
    if not char then return false, "No character" end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No HumanoidRootPart" end

    -- Verify player is airborne (above ground)
    local rayResult = workspace:Raycast(
        hrp.Position,
        Vector3.new(0, -500, 0),
        RaycastParams.new()
    )
    local groundDist = rayResult and rayResult.Distance or 500
    if groundDist < 10 then
        return false, "Too close to the ground"
    end

    ActiveParachutes[player] = { deployTime = tick() }

    -- Fire to all clients near player so they see the parachute animation
    Remotes.FireAllClients("ParachuteDeployed", player.UserId)

    -- Reduce fall velocity via BodyVelocity on server
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce  = Vector3.new(0, math.huge, 0)
    bv.Velocity  = Vector3.new(0, -8, 0)  -- slow descent
    bv.Parent    = hrp

    -- Clean up when player lands (humanoid state)
    local connection
    connection = char:FindFirstChildOfClass("Humanoid").StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed then
            bv:Destroy()
            ActiveParachutes[player] = nil
            connection:Disconnect()
        end
    end)

    return true
end

-- Called by client to request HALO / static line jump
function FlightService.InitiateAirborneJump(player, jumpType)
    local validTypes = { StaticLine = true, HALO = true, HAHO = true }
    if not validTypes[jumpType] then return false, "Invalid jump type" end

    -- Check airborne badge requirement for HALO/HAHO
    local data = DataService.GetData(player)
    if jumpType ~= "StaticLine" then
        if not (data and data.Badges and data.Badges["AirborneWings"]) then
            return false, "Requires Airborne Wings badge"
        end
    end

    -- Teleport character to jump altitude above current position
    local char = player.Character
    if char and char.PrimaryPart then
        local pos = char.PrimaryPart.Position
        local altitudeBoost = jumpType == "HALO" and 400 or (jumpType == "HAHO" and 300 or 100)
        char:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(0, altitudeBoost, 0)))
    end

    return true
end

-- Fast rope: lower player from helicopter
function FlightService.StartFastRope(player, ropeAnchorCFrame)
    Remotes.FireClient("FastRopeStarted", player, {
        anchorPosition = ropeAnchorCFrame.Position,
    })
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function FlightService.Init()
    Remotes.On("ParachuteDeployed", function(player)
        FlightService.DeployParachute(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        ActiveParachutes[player] = nil
    end)

    print("[FlightService] Initialized.")
end

return FlightService
