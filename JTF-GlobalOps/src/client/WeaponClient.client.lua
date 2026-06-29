-- WeaponClient.client.lua
-- Handles client-side weapon firing: raycast, recoil camera shake, ammo HUD.
-- The server validates every shot — this script only handles feel and visuals.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

local shared  = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes = require(shared:WaitForChild("Remotes"))
local WeaponConfig = require(shared:WaitForChild("Config"):WaitForChild("WeaponConfig"))

-- ─── State ────────────────────────────────────────────────────────────────────
local CurrentWeapon   = nil   -- weaponId string
local CurrentAmmo     = 0
local CurrentReserve  = 0
local IsFiring        = false
local IsReloading     = false
local LastFireTime    = 0

-- Recoil state
local RecoilOffset    = Vector2.new(0, 0)
local RecoilTarget    = Vector2.new(0, 0)

-- ─── HUD helpers ──────────────────────────────────────────────────────────────
local function updateAmmoHUD()
    local gui    = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    local ammoLabel = gui and gui:FindFirstChild("AmmoLabel", true)
    if ammoLabel then
        ammoLabel.Text = CurrentAmmo .. " / " .. CurrentReserve
    end
end

-- ─── Recoil ───────────────────────────────────────────────────────────────────
local function applyRecoil(config)
    local kickUp    = config.recoilKick   or 1
    local recovery  = config.recoilRecov  or 0.85

    -- Add kick
    RecoilTarget = RecoilTarget + Vector2.new(
        math.random(-100, 100) / 100 * kickUp * 0.3,
        kickUp
    )
end

RunService.RenderStepped:Connect(function(dt)
    -- Lerp recoil back to zero (recovery)
    local config = CurrentWeapon and WeaponConfig.Weapons[CurrentWeapon]
    local recov  = config and (config.recoilRecov or 0.85) or 0.85

    RecoilOffset = RecoilOffset:Lerp(RecoilTarget, 0.4)
    RecoilTarget = RecoilTarget * recov

    -- Apply to camera
    if RecoilOffset.Magnitude > 0.01 then
        Camera.CFrame = Camera.CFrame
            * CFrame.Angles(math.rad(RecoilOffset.Y * 0.1), math.rad(RecoilOffset.X * 0.05), 0)
    end
end)

-- ─── Raycast from camera ──────────────────────────────────────────────────────
local function getAimRay()
    local unitRay = Camera:ScreenPointToRay(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )
    return unitRay.Origin, unitRay.Direction
end

-- ─── Fire ─────────────────────────────────────────────────────────────────────
local function fireWeapon()
    if not CurrentWeapon then return end
    local config = WeaponConfig.Weapons[CurrentWeapon]
    if not config then return end

    if IsReloading then return end
    if CurrentAmmo <= 0 then
        -- Auto-reload when empty
        reloadWeapon()
        return
    end

    local now     = tick()
    local minGap  = 1 / (config.fireRate or 10)
    if now - LastFireTime < minGap then return end

    LastFireTime = now
    CurrentAmmo  = math.max(0, CurrentAmmo - 1)

    -- Client-side visual feedback (immediate)
    applyRecoil(config)
    updateAmmoHUD()

    -- Play muzzle flash / sound via Tool script (handled per-weapon model)
    -- Fire server to validate and process damage
    local origin, direction = getAimRay()
    Remotes.FireServer("WeaponFired", CurrentWeapon, origin, direction * (config.range or 500))
end

function reloadWeapon()
    if IsReloading or not CurrentWeapon then return end
    local config = WeaponConfig.Weapons[CurrentWeapon]
    if not config then return end
    if CurrentReserve <= 0 then return end
    if CurrentAmmo >= config.magSize then return end

    IsReloading = true

    -- Play reload animation (handled by Tool model)
    task.delay(config.reloadTime or 2.5, function()
        if not CurrentWeapon then IsReloading = false return end

        local needed = config.magSize - CurrentAmmo
        local given  = math.min(needed, CurrentReserve)
        CurrentAmmo    = CurrentAmmo + given
        CurrentReserve = CurrentReserve - given
        IsReloading    = false

        updateAmmoHUD()
        Remotes.FireServer("WeaponReloaded", CurrentWeapon)
    end)
end

-- ─── Tool equip detection ─────────────────────────────────────────────────────
local function onToolEquipped(tool)
    local weaponId = tool:GetAttribute("WeaponId")
    if not weaponId then return end

    local config = WeaponConfig.Weapons[weaponId]
    if not config then return end

    CurrentWeapon  = weaponId
    CurrentAmmo    = config.magSize
    CurrentReserve = config.maxAmmo - config.magSize
    IsReloading    = false

    updateAmmoHUD()
end

local function onToolUnequipped()
    CurrentWeapon = nil
    IsFiring      = false
end

-- Watch character for tool changes
local function watchCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Equipped:Connect(function() onToolEquipped(child) end)
            child.Unequipped:Connect(onToolUnequipped)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(watchCharacter)
if LocalPlayer.Character then watchCharacter(LocalPlayer.Character) end

-- ─── Input handling ───────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = true
        fireWeapon()  -- first shot immediately
    end

    if input.KeyCode == Enum.KeyCode.R then
        reloadWeapon()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsFiring = false
    end
end)

-- Auto-fire loop for automatic weapons
RunService.Heartbeat:Connect(function()
    if not IsFiring or not CurrentWeapon then return end
    local config = CurrentWeapon and WeaponConfig.Weapons[CurrentWeapon]
    if config and config.automatic then
        fireWeapon()
    end
end)

-- ─── Server hit feedback ──────────────────────────────────────────────────────
Remotes.OnClient("HitConfirmed", function(payload)
    -- Flash crosshair red / show hitmarker
    local gui = LocalPlayer.PlayerGui:FindFirstChild("HUD")
    if gui then
        local hitmarker = gui:FindFirstChild("Hitmarker", true)
        if hitmarker then
            hitmarker.Visible = true
            hitmarker.ImageColor3 = payload.isHead
                and Color3.fromRGB(255, 80, 80)
                or  Color3.fromRGB(255, 255, 255)
            task.delay(0.12, function()
                hitmarker.Visible = false
            end)
        end
    end
end)

print("[WeaponClient] Loaded.")
