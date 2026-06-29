-- HelicopterClient.client.lua
-- Full helicopter flight controller using BodyVelocity + BodyGyro.
-- Attach this LocalScript to the helicopter model or place in StarterPlayerScripts.
-- The helicopter Model MUST have a VehicleSeat named "PilotSeat" and a
-- StringAttribute "VehicleId" = "Helicopter" (or TransportHelicopter, AttackHelicopter).

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local shared      = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes     = require(shared:WaitForChild("Remotes"))
local VehicleConfig = require(shared:WaitForChild("Config"):WaitForChild("VehicleConfig"))

-- ─── Constants ────────────────────────────────────────────────────────────────
local LIFT_FORCE       = 800      -- upward force (tune to heli mass)
local TILT_AMOUNT      = 25       -- max pitch/roll degrees
local YAW_SPEED        = 60       -- degrees/second for rotation
local FORWARD_SPEED    = 60       -- studs/second max horizontal speed
local HOVER_DAMPING    = 0.85     -- velocity damping when no input
local ALTITUDE_SPEED   = 30       -- studs/second vertical

-- ─── State ────────────────────────────────────────────────────────────────────
local IsFlying      = false
local HeliModel     = nil
local HeliRootPart  = nil
local BodyVelocity  = nil
local BodyGyro      = nil
local FlightStart   = 0
local FlightTimer   = 0

-- Input tracking
local Thrust    = 0   -- Q/E: up/down
local Pitch     = 0   -- W/S: forward/back
local Roll      = 0   -- A/D: left/right (strafe)
local Yaw       = 0   -- left/right rotation

-- Throttle (0–1, controlled by holding Q/E)
local Throttle  = 0

-- ─── Body force setup ────────────────────────────────────────────────────────
local function setupPhysics(rootPart)
    -- Remove any existing
    for _, c in ipairs(rootPart:GetChildren()) do
        if c:IsA("BodyVelocity") or c:IsA("BodyGyro") then c:Destroy() end
    end

    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity  = Vector3.zero
    BodyVelocity.Parent    = rootPart

    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.D         = 100
    BodyGyro.P         = 3000
    BodyGyro.CFrame    = rootPart.CFrame
    BodyGyro.Parent    = rootPart
end

local function cleanupPhysics(rootPart)
    if BodyVelocity and BodyVelocity.Parent then BodyVelocity:Destroy() end
    if BodyGyro     and BodyGyro.Parent     then BodyGyro:Destroy()     end
    BodyVelocity = nil
    BodyGyro     = nil
end

-- ─── Flight loop ─────────────────────────────────────────────────────────────
local function startFlight(model)
    HeliModel    = model
    HeliRootPart = model.PrimaryPart
    if not HeliRootPart then return end

    setupPhysics(HeliRootPart)
    IsFlying   = true
    FlightStart = tick()
    FlightTimer = 0

    RunService:BindToRenderStep("HeliFlight", Enum.RenderPriority.Camera.Value, function(dt)
        if not IsFlying or not HeliRootPart or not HeliRootPart.Parent then
            RunService:UnbindFromRenderStep("HeliFlight")
            return
        end

        FlightTimer = FlightTimer + dt

        -- ── Read input ────────────────────────────────────────────────────────
        local up      = UserInputService:IsKeyDown(Enum.KeyCode.Q) and 1 or 0
        local down    = UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0
        local fwd     = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        local back    = UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0
        local left    = UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0
        local right   = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local yawLeft = UserInputService:IsKeyDown(Enum.KeyCode.Left)  and 1 or 0
        local yawRight= UserInputService:IsKeyDown(Enum.KeyCode.Right) and 1 or 0

        -- Throttle changes (collective)
        Throttle = math.clamp(Throttle + (up - down) * dt * 1.5, 0, 1)

        -- Hover at 50% throttle sustains altitude
        local liftVelocity = (Throttle - 0.5) * ALTITUDE_SPEED * 2

        -- Horizontal input
        local cf         = HeliRootPart.CFrame
        local forwardVec = cf.LookVector * Vector3.new(1, 0, 1)
        local rightVec   = cf.RightVector * Vector3.new(1, 0, 1)

        local hInput = (forwardVec * (fwd - back) + rightVec * (right - left))
        if hInput.Magnitude > 0 then
            hInput = hInput.Unit
        end

        -- Desired velocity
        local desiredVelocity = hInput * FORWARD_SPEED + Vector3.new(0, liftVelocity, 0)

        -- Apply damping when no horizontal input
        local currentVel = HeliRootPart.AssemblyLinearVelocity
        if hInput.Magnitude < 0.1 then
            desiredVelocity = Vector3.new(
                currentVel.X * HOVER_DAMPING,
                desiredVelocity.Y,
                currentVel.Z * HOVER_DAMPING
            )
        end

        if BodyVelocity then
            BodyVelocity.Velocity = desiredVelocity
        end

        -- ── Yaw rotation ──────────────────────────────────────────────────────
        local yawDelta = (yawRight - yawLeft) * YAW_SPEED * dt
        local targetCF = cf * CFrame.Angles(0, math.rad(-yawDelta), 0)

        -- ── Bank and pitch tilt ────────────────────────────────────────────────
        local pitchAngle = math.rad(-TILT_AMOUNT * (fwd - back))
        local rollAngle  = math.rad( TILT_AMOUNT * (right - left))

        -- Extract yaw only from current CFrame, apply tilt on top
        local _, yawAngle, _ = targetCF:ToEulerAnglesYXZ()
        local desiredGyro = CFrame.fromEulerAnglesYXZ(pitchAngle, yawAngle, rollAngle)

        if BodyGyro then
            BodyGyro.CFrame = desiredGyro
        end

        -- ── Log flight time (every 60s) ────────────────────────────────────────
        if FlightTimer >= 60 then
            FlightTimer = 0
            Remotes.InvokeServer("SubmitObjective", "FlyStuds", 600)
            Remotes.FireServer("WeaponFired")  -- dummy call; real flight logging is server-side
        end
    end)
end

local function stopFlight()
    IsFlying = false
    RunService:UnbindFromRenderStep("HeliFlight")
    if HeliRootPart then
        cleanupPhysics(HeliRootPart)
    end

    -- Log total flight time
    local minutes = math.floor((tick() - FlightStart) / 60)
    if minutes > 0 then
        -- Server logs flight time via FlightService
        print(("[HeliClient] Flight ended — %d minutes"):format(minutes))
    end

    HeliModel    = nil
    HeliRootPart = nil
    Throttle     = 0
end

-- ─── Seat detection ───────────────────────────────────────────────────────────
local function watchCharacter(char)
    local humanoid = char:WaitForChild("Humanoid")

    humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
        local seat = humanoid.SeatPart
        if seat and seat.Name == "PilotSeat" then
            local vehicle   = seat:FindFirstAncestorOfClass("Model")
            local vehicleId = vehicle and vehicle:GetAttribute("VehicleId")
            local vConfig   = vehicleId and VehicleConfig.Vehicles[vehicleId]
            if vConfig and vConfig.category == "RotaryWing" then
                startFlight(vehicle)
            end
        else
            if IsFlying then
                stopFlight()
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(watchCharacter)
if LocalPlayer.Character then watchCharacter(LocalPlayer.Character) end

-- ─── Helicopter HUD ──────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not IsFlying or not HeliRootPart then return end

    local hud       = LocalPlayer.PlayerGui:FindFirstChild("VehicleHUD")
    local altLabel  = hud and hud:FindFirstChild("AltitudeLabel", true)
    local throttleBar = hud and hud:FindFirstChild("ThrottleBar", true)

    -- Altitude
    if altLabel then
        local rayResult = workspace:Raycast(
            HeliRootPart.Position,
            Vector3.new(0, -500, 0),
            RaycastParams.new()
        )
        local alt = rayResult and math.floor(rayResult.Distance) or 0
        altLabel.Text = alt .. " m AGL"
    end

    -- Throttle
    if throttleBar then
        throttleBar.Size = UDim2.new(Throttle, 0, 1, 0)
    end
end)

print("[HelicopterClient] Loaded. Q/E=collective W/S=pitch A/D=roll Arrows=yaw")
