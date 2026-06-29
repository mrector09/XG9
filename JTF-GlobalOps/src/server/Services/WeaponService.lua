-- WeaponService: server-side weapon management, damage validation, anti-exploit.

local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local Remotes       = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService   = require(script.Parent.DataService)
local WeaponConfig  = require(script.Parent.Parent.Parent.shared.Config.WeaponConfig)

local WeaponService = {}

local TeamService   -- injected
local XPService     -- injected
local EconomyService -- injected

function WeaponService.SetDependencies(ts, xs, es)
    TeamService    = ts
    XPService      = xs
    EconomyService = es
end

-- Track per-player server-side ammo and cooldowns
local PlayerWeaponState = {}  -- [userId] = { [weaponId] = { ammo, lastFire } }

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getState(player)
    local id = player.UserId
    if not PlayerWeaponState[id] then
        PlayerWeaponState[id] = {}
    end
    return PlayerWeaponState[id]
end

local function initWeaponState(player, weaponId)
    local state   = getState(player)
    local config  = WeaponConfig.Weapons[weaponId]
    if not config then return end
    if not state[weaponId] then
        state[weaponId] = {
            ammo     = config.magSize,
            reserve  = config.maxAmmo - config.magSize,
            lastFire = 0,
        }
    end
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function WeaponService.GiveWeapon(player, weaponId)
    local config = WeaponConfig.Weapons[weaponId]
    if not config then
        warn("[WeaponService] Unknown weapon:", weaponId)
        return
    end

    -- Find the weapon Tool in ServerStorage and clone into backpack
    local template = game.ServerStorage:FindFirstChild("Weapons")
        and game.ServerStorage.Weapons:FindFirstChild(weaponId)
    if not template then
        -- Weapon model not built yet — just track state for future use
        initWeaponState(player, weaponId)
        return
    end

    local tool = template:Clone()
    tool.Parent = player.Backpack
    initWeaponState(player, weaponId)
end

function WeaponService.ClearWeapons(player)
    -- Remove all tools from backpack and character
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then tool:Destroy() end
    end
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then tool:Destroy() end
        end
    end
    PlayerWeaponState[player.UserId] = {}
end

function WeaponService.GetAmmo(player, weaponId)
    local state = getState(player)
    return state[weaponId] and state[weaponId].ammo or 0
end

-- Called by client via RemoteEvent "WeaponFired"
-- Returns whether the shot was valid (for damage application)
function WeaponService.ValidateFire(player, weaponId, origin, direction)
    local config = WeaponConfig.Weapons[weaponId]
    if not config then return false, "Unknown weapon" end

    local state = getState(player)
    local ws    = state[weaponId]
    if not ws then return false, "Weapon not equipped" end

    -- Ammo check
    if ws.ammo <= 0 then return false, "No ammo" end

    -- Fire rate check
    local now      = tick()
    local minDelay = 1 / config.fireRate
    if (now - ws.lastFire) < (minDelay * 0.75) then  -- 25% leniency for latency
        return false, "Firing too fast"
    end

    -- Distance sanity: origin must be near the player's character
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - origin).Magnitude > 20 then
            return false, "Origin too far from character"
        end
    end

    -- All checks passed — deduct ammo and update timestamp
    ws.ammo     = ws.ammo - 1
    ws.lastFire = now

    return true
end

-- Server-side raycast and damage application
function WeaponService.ProcessShot(shooter, weaponId, origin, direction)
    local ok, reason = WeaponService.ValidateFire(shooter, weaponId, origin, direction)
    if not ok then return end

    local config = WeaponConfig.Weapons[weaponId]
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { shooter.Character }
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local unitDir = direction.Unit
    local result  = Workspace:Raycast(origin, unitDir * (config.range or 500), raycastParams)

    if not result then return end

    local hitInstance = result.Instance
    local character   = hitInstance:FindFirstAncestorOfClass("Model")
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local victim = Players:GetPlayerFromCharacter(character)

    -- Friendly fire check
    if victim and TeamService and TeamService.AreFriendly(shooter, victim) then
        return  -- no friendly fire
    end

    -- Calculate damage
    local damage = config.damage or 20
    local isHead = hitInstance.Name == "Head"
    if isHead then
        damage = damage * (config.headMulti or 1.5)
    end

    humanoid:TakeDamage(damage)

    -- Hit confirmation to shooter
    Remotes.FireClient("HitConfirmed", shooter, {
        targetId = victim and victim.UserId or 0,
        damage   = damage,
        isHead   = isHead,
    })

    -- Check kill
    if humanoid.Health <= 0 then
        WeaponService.HandleKill(shooter, victim, weaponId)
    end
end

function WeaponService.HandleKill(shooter, victim, weaponId)
    if XPService then
        XPService.AwardXPFromSource(shooter, "Kill")
    end

    -- Track weapon mastery
    DataService.UpdateData(shooter, function(d)
        d.TotalKills = (d.TotalKills or 0) + 1
        d.WeaponKills = d.WeaponKills or {}
        d.WeaponKills[weaponId] = (d.WeaponKills[weaponId] or 0) + 1
    end)

    if victim then
        DataService.UpdateData(victim, function(d)
            d.TotalDeaths = (d.TotalDeaths or 0) + 1
        end)
    end

    Remotes.FireClient("PlayerKilled", shooter, {
        victimId = victim and victim.UserId or 0,
        weaponId = weaponId,
    })
end

function WeaponService.HandleReload(player, weaponId)
    local config = WeaponConfig.Weapons[weaponId]
    if not config then return false end

    local state = getState(player)
    local ws    = state[weaponId]
    if not ws then return false end

    local needed  = config.magSize - ws.ammo
    local given   = math.min(needed, ws.reserve)
    ws.ammo       = ws.ammo + given
    ws.reserve    = ws.reserve - given

    return true
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function WeaponService.Init()
    Remotes.On("WeaponFired", function(player, weaponId, origin, direction)
        WeaponService.ProcessShot(player, weaponId, origin, direction)
    end)

    Remotes.On("WeaponReloaded", function(player, weaponId)
        WeaponService.HandleReload(player, weaponId)
    end)

    Players.PlayerRemoving:Connect(function(player)
        PlayerWeaponState[player.UserId] = nil
    end)

    print("[WeaponService] Initialized.")
end

return WeaponService
