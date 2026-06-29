-- WeaponToolClient.client.lua
-- Place this LocalScript inside EVERY weapon Tool in ServerStorage/Weapons/<WeaponId>/
-- Handles: animations, muzzle flash, sounds, crosshair, ADS camera zoom.
-- Relies on WeaponClient.client.lua for actual firing logic.

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local tool     = script.Parent
local weaponId = tool:GetAttribute("WeaponId")
if not weaponId then return end

local shared       = game.ReplicatedStorage:WaitForChild("JTF", 10)
local WeaponConfig = require(shared:WaitForChild("Config"):WaitForChild("WeaponConfig"))
local wConfig      = WeaponConfig.Weapons[weaponId]
if not wConfig then return end

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")
local Animator    = Humanoid:WaitForChild("Animator")

-- ─── Animations ──────────────────────────────────────────────────────────────
-- Load animations from the Tool — create Animation objects named:
-- "Equip", "Fire", "Reload", "ADS_In", "ADS_Out", "Idle"
-- Set their AnimationId attribute (rbxassetid://...) in Studio.
local Animations = {}
local function loadAnim(name, defaultId)
    local animObj = tool:FindFirstChild(name)
    if not animObj then
        animObj = Instance.new("Animation")
        animObj.Name = name
        animObj.AnimationId = "rbxassetid://" .. (defaultId or "0")
        animObj.Parent = tool
    end
    local track = Animator:LoadAnimation(animObj)
    Animations[name] = track
    return track
end

-- These animation IDs are placeholders — replace with real IDs in Studio
loadAnim("Equip",   "0")
loadAnim("Fire",    "0")
loadAnim("Reload",  "0")
loadAnim("Idle",    "0")
loadAnim("ADS_In",  "0")
loadAnim("ADS_Out", "0")

-- ─── Sound setup ─────────────────────────────────────────────────────────────
local function getOrCreateSound(name, defaultId)
    local snd = tool:FindFirstChild(name)
    if not snd then
        snd = Instance.new("Sound")
        snd.Name     = name
        snd.SoundId  = "rbxassetid://" .. (defaultId or "0")
        snd.Parent   = tool
    end
    return snd
end

-- Replace SoundId values with real Roblox audio asset IDs
local SoundFire   = getOrCreateSound("Fire",   "0")
local SoundReload = getOrCreateSound("Reload", "0")
local SoundEmpty  = getOrCreateSound("Empty",  "0")
local SoundEquip  = getOrCreateSound("Equip",  "0")

-- ─── Muzzle flash ─────────────────────────────────────────────────────────────
local MuzzleAttachment = tool:FindFirstChild("MuzzleAttachment", true)
local MuzzleFlash      = MuzzleAttachment and MuzzleAttachment:FindFirstChildOfClass("ParticleEmitter")

local function doMuzzleFlash()
    if MuzzleFlash then
        MuzzleFlash:Emit(3)
    end
end

-- ─── ADS (aim down sights) ────────────────────────────────────────────────────
local DEFAULT_FOV = 70
local ADS_FOV     = DEFAULT_FOV / (wConfig.attachSlots and 1 or 1)  -- adjust per optic later
local IsADS       = false
local ADSTween    = nil

local function setADS(state)
    if state == IsADS then return end
    IsADS = state

    if ADSTween then ADSTween:Cancel() end

    local targetFOV = state and ADS_FOV or DEFAULT_FOV
    ADSTween = TweenService:Create(
        Camera,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { FieldOfView = targetFOV }
    )
    ADSTween:Play()

    if state then
        if Animations.ADS_In then Animations.ADS_In:Play() end
    else
        if Animations.ADS_Out then Animations.ADS_Out:Play() end
    end
end

-- ─── Crosshair spread ────────────────────────────────────────────────────────
local Spread   = 0
local MAX_SPREAD = 20
local SPREAD_PER_SHOT = wConfig.recoilKick or 1.5
local SPREAD_RECOVERY = 8  -- units/second

RunService.RenderStepped:Connect(function(dt)
    -- Recover crosshair spread
    Spread = math.max(0, Spread - SPREAD_RECOVERY * dt)

    local gui      = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local crosshair = gui and gui:FindFirstChild("Crosshair", true)
    if crosshair then
        -- Move the 4 lines outward by Spread pixels
        local size = 10 + Spread
        for _, line in ipairs(crosshair:GetChildren()) do
            if line:IsA("Frame") then
                -- Lines are named Top, Bottom, Left, Right
                if line.Name == "Top"    then line.Position = UDim2.new(0.5, -1, 0.5, -size) end
                if line.Name == "Bottom" then line.Position = UDim2.new(0.5, -1, 0.5,  size) end
                if line.Name == "Left"   then line.Position = UDim2.new(0.5, -size, 0.5, -1) end
                if line.Name == "Right"  then line.Position = UDim2.new(0.5, size, 0.5, -1)  end
            end
        end
    end
end)

-- ─── Fire visual ──────────────────────────────────────────────────────────────
local function onFire()
    -- Play fire animation (don't restart if still playing)
    if Animations.Fire and not Animations.Fire.IsPlaying then
        Animations.Fire:Play()
    end
    SoundFire:Play()
    doMuzzleFlash()
    Spread = math.min(MAX_SPREAD, Spread + SPREAD_PER_SHOT)
end

local function onReload()
    if Animations.Reload then
        Animations.Reload:Play()
    end
    SoundReload:Play()
end

-- WeaponClient fires this signal when it processes a shot
-- We use a BindableEvent in the tool for cross-script communication
local FireSignal   = tool:FindFirstChild("FireSignal")
local ReloadSignal = tool:FindFirstChild("ReloadSignal")

if not FireSignal then
    FireSignal      = Instance.new("BindableEvent")
    FireSignal.Name = "FireSignal"
    FireSignal.Parent = tool
end
if not ReloadSignal then
    ReloadSignal      = Instance.new("BindableEvent")
    ReloadSignal.Name = "ReloadSignal"
    ReloadSignal.Parent = tool
end

FireSignal.Event:Connect(onFire)
ReloadSignal.Event:Connect(onReload)

-- ─── Input ────────────────────────────────────────────────────────────────────
local equipped = false

tool.Equipped:Connect(function()
    equipped = true
    SoundEquip:Play()
    if Animations.Equip then Animations.Equip:Play() end
    if Animations.Idle  then Animations.Idle:Play()  end
    Camera.FieldOfView = DEFAULT_FOV
end)

tool.Unequipped:Connect(function()
    equipped = false
    setADS(false)
    Camera.FieldOfView = DEFAULT_FOV
    for _, track in pairs(Animations) do
        track:Stop()
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not equipped then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        setADS(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        setADS(false)
    end
end)
