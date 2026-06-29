-- AimAssist LocalScript
-- Place in: StarterPlayer > StarterPlayerScripts
-- Command Authority Military Role Play

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ─── Configuration ───────────────────────────────────────────────────────────
local Config = {
    -- Input
    HoldKey    = Enum.KeyCode.Q,   -- Hold to activate aim assist
    ToggleKey  = Enum.KeyCode.G,   -- Toggle aim assist on/off

    -- Targeting
    MaxDistance = 200,             -- Max stud range
    FOVDegrees  = 15,              -- Half-angle of FOV cone for candidate selection
    AimPart     = "Head",          -- "Head" or "HumanoidRootPart"

    -- Feel
    Smoothness  = 0.12,            -- Lerp factor per frame (lower = smoother/slower)

    -- Filters
    TeamCheck   = true,            -- Skip teammates
    WallCheck   = true,            -- Skip targets behind walls
}
-- ─────────────────────────────────────────────────────────────────────────────

local enabled  = true
local holding  = false

-- Returns true if player is on the same team as the local player
local function sameTeam(player)
    if not Config.TeamCheck then return false end
    return LocalPlayer.Team ~= nil and LocalPlayer.Team == player.Team
end

-- Returns true if there is a clear line of sight to targetPart
local function lineOfSight(targetPart)
    local origin    = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        targetPart.Parent,
    }

    return workspace:Raycast(origin, direction, params) == nil
end

-- Returns the screen-space distance from the viewport centre to worldPos
local function screenDistFromCentre(worldPos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen then return math.huge end
    local centre = Camera.ViewportSize / 2
    return (Vector2.new(screenPos.X, screenPos.Y) - centre).Magnitude
end

-- Returns the pixel radius of the FOV cone at the centre of the screen
local function fovRadius()
    return (Camera.ViewportSize.Y / 2) * math.tan(math.rad(Config.FOVDegrees))
end

-- Scans all players and returns the Part closest to the crosshair within FOV
local function findBestTarget()
    local bestPart     = nil
    local bestDistance = math.huge
    local radius       = fovRadius()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if sameTeam(player)      then continue end

        local char = player.Character
        if not char then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local part     = char:FindFirstChild(Config.AimPart)
        if not humanoid or humanoid.Health <= 0 or not part then continue end

        -- Range check
        if (part.Position - Camera.CFrame.Position).Magnitude > Config.MaxDistance then
            continue
        end

        -- FOV check
        local dist = screenDistFromCentre(part.Position)
        if dist > radius then continue end

        -- Wall check
        if Config.WallCheck and not lineOfSight(part) then continue end

        if dist < bestDistance then
            bestDistance = dist
            bestPart     = part
        end
    end

    return bestPart
end

-- Smoothly rotate the camera toward targetPart
local function aimAt(targetPart)
    local camPos   = Camera.CFrame.Position
    local goal     = CFrame.lookAt(camPos, targetPart.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(goal, Config.Smoothness)
end

-- ─── Input ───────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.ToggleKey then
        enabled = not enabled
        print(("[Aim Assist] %s"):format(enabled and "ON" or "OFF"))
    elseif input.KeyCode == Config.HoldKey then
        holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.HoldKey then
        holding = false
    end
end)

-- ─── Main Loop ───────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
    if not enabled or not holding then return end

    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local target = findBestTarget()
    if target and target.Parent then
        aimAt(target)
    end
end)

print("[Command Authority] Aim Assist ready | Hold " ..
    Config.HoldKey.Name .. " to aim | " .. Config.ToggleKey.Name .. " to toggle")
