-- CharacterController.client.lua
-- Sprint, crouch, prone, parachute, fast-rope, night vision.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera

local shared   = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes  = require(shared:WaitForChild("Remotes"))

-- ─── Config ───────────────────────────────────────────────────────────────────
local WALK_SPEED    = 16
local SPRINT_SPEED  = 28
local CROUCH_SPEED  = 8
local PRONE_SPEED   = 4

local CROUCH_HEIGHT = 1.0   -- HipHeight while crouching
local PRONE_HEIGHT  = 0.1   -- HipHeight while prone
local NORMAL_HEIGHT = 1.35  -- Default HipHeight

-- ─── State ────────────────────────────────────────────────────────────────────
local IsSprinting  = false
local IsCrouching  = false
local IsProne      = false
local IsParachuting = false
local NightVision  = false

-- Night vision overlay (simple ColorCorrectionEffect)
local NVColorCorrection
do
    local lighting = game:GetService("Lighting")
    NVColorCorrection = Instance.new("ColorCorrectionEffect")
    NVColorCorrection.TintColor = Color3.fromRGB(80, 255, 80)
    NVColorCorrection.Brightness = 0.3
    NVColorCorrection.Saturation = -0.8
    NVColorCorrection.Enabled    = false
    NVColorCorrection.Parent     = lighting
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function setStance(speed, hipHeight)
    local hum = getHumanoid()
    if not hum then return end
    hum.WalkSpeed = speed
    hum.HipHeight = hipHeight
end

-- ─── Stance toggles ───────────────────────────────────────────────────────────
local function startSprint()
    if IsCrouching or IsProne then return end
    IsSprinting = true
    setStance(SPRINT_SPEED, NORMAL_HEIGHT)
end

local function stopSprint()
    IsSprinting = false
    if IsCrouching then
        setStance(CROUCH_SPEED, CROUCH_HEIGHT)
    elseif IsProne then
        setStance(PRONE_SPEED, PRONE_HEIGHT)
    else
        setStance(WALK_SPEED, NORMAL_HEIGHT)
    end
end

local function toggleCrouch()
    if IsProne then return end
    IsCrouching = not IsCrouching
    IsSprinting = false
    if IsCrouching then
        setStance(CROUCH_SPEED, CROUCH_HEIGHT)
    else
        setStance(WALK_SPEED, NORMAL_HEIGHT)
    end
end

local function toggleProne()
    IsProne     = not IsProne
    IsCrouching = false
    IsSprinting = false
    if IsProne then
        setStance(PRONE_SPEED, PRONE_HEIGHT)
    else
        setStance(WALK_SPEED, NORMAL_HEIGHT)
    end
end

-- ─── Night vision ─────────────────────────────────────────────────────────────
local function toggleNightVision()
    NightVision              = not NightVision
    NVColorCorrection.Enabled = NightVision
    game:GetService("Lighting").Brightness = NightVision and 0 or 2
end

-- ─── Parachute ────────────────────────────────────────────────────────────────
local function deployParachute()
    if IsParachuting then return end
    IsParachuting = true
    Remotes.FireServer("ParachuteDeployed")
end

Remotes.OnClient("ParachuteDeployed", function(userId)
    -- Animate chute for all players
    if userId == LocalPlayer.UserId then
        IsParachuting = true
        -- Character attachment for canopy visual handled by workspace model
    end
end)

-- ─── Input map ────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    local k = input.KeyCode

    if k == Enum.KeyCode.LeftShift then startSprint() end
    if k == Enum.KeyCode.C          then toggleCrouch() end
    if k == Enum.KeyCode.Z          then toggleProne() end
    if k == Enum.KeyCode.N          then toggleNightVision() end
    if k == Enum.KeyCode.X          then deployParachute() end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then stopSprint() end
end)

-- ─── Reset on respawn ─────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function()
    IsSprinting   = false
    IsCrouching   = false
    IsProne       = false
    IsParachuting = false
    NVColorCorrection.Enabled = false
    NightVision = false
end)

print("[CharacterController] Loaded. C=crouch Z=prone N=NV X=chute Shift=sprint")
