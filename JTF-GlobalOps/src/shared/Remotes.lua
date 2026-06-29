-- Remotes: creates or retrieves all RemoteEvents and RemoteFunctions.
-- Server: require this and call .Init() once.
-- Client: require this and read the returned tables directly.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

local Remotes = {}

-- ─── Folder ───────────────────────────────────────────────────────────────────
local function getOrCreate(parent, className, name)
    local obj = parent:FindFirstChild(name)
    if not obj then
        assert(IS_SERVER, ("Remote '%s' must be created on the server first"):format(name))
        obj = Instance.new(className)
        obj.Name = name
        obj.Parent = parent
    end
    return obj
end

local function folder(parent, name)
    local f = parent:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
    end
    return f
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function Remotes.Init()
    local root      = folder(ReplicatedStorage, "JTF")
    local evFolder  = folder(root, "RemoteEvents")
    local fnFolder  = folder(root, "RemoteFunctions")

    -- ── Events (server → client or client → server fire-and-forget) ──────────
    local eventNames = {
        -- XP / Rank
        "XPAwarded",           -- server → client: { amount, source, totalXP }
        "RankChanged",         -- server → client: { newRank, rankName }
        "BadgeEarned",         -- server → client: { badgeId, badgeName }

        -- Economy
        "CashUpdated",         -- server → client: { newBalance, delta }

        -- Jobs / Teams
        "JobChanged",          -- server → client: { branch, job }
        "TeamChanged",         -- server → client: { teamName }

        -- Missions
        "MissionStarted",      -- server → client: { missionId, objectives }
        "ObjectiveUpdated",    -- server → client: { objectiveIndex, progress, goal }
        "MissionCompleted",    -- server → client: { missionId, xp, cash, ribbon }
        "DailyMissionsRefreshed", -- server → client: { missions }

        -- Deployments
        "DeploymentStarted",   -- server → client: { mapName }
        "DeploymentEnded",     -- server → client: { results }
        "RibbonAwarded",       -- server → client: { ribbonId }

        -- Weapons (client → server)
        "WeaponFired",         -- client → server: { weaponId, origin, direction }
        "WeaponReloaded",      -- client → server: { weaponId }
        "GrenadeThrown",       -- client → server: { grenadeType, origin, velocity }

        -- Damage (server → client)
        "DamageTaken",         -- server → client: { amount, source }
        "HitConfirmed",        -- server → client: { targetId, damage }
        "PlayerKilled",        -- server → client: { victimId, weaponId }

        -- Vehicles
        "VehicleSpawned",      -- server → client: { vehicleId, model }
        "VehicleDespawned",    -- server → client: { vehicleId }
        "FuelUpdated",         -- server → client: { vehicleId, fuel }
        "VehicleDamaged",      -- server → client: { vehicleId, health }

        -- Flight / Airborne
        "ParachuteDeployed",   -- server → client / client → server
        "FastRopeStarted",     -- server → client: { ropeAnchor }
        "FlightHoursUpdated",  -- server → client: { hours }

        -- Medical
        "ReviveOffered",       -- server → client: { medicId }
        "PlayerRevived",       -- server → client
        "HealApplied",         -- server → client: { amount }

        -- Battle Pass
        "BPXPAdded",           -- server → client: { amount, tier, totalBPXP }
        "BPTierUnlocked",      -- server → client: { tier }
        "BPRewardClaimed",     -- server → client: { tier, reward }

        -- Daily Rewards
        "DailyRewardAvailable",  -- server → client
        "DailyRewardClaimed",    -- server → client: { reward, streak }

        -- Shop / Gamepass
        "GamepassPerksApplied",  -- server → client: { perks }
        "PurchaseComplete",      -- server → client: { productId }

        -- Special Ops
        "SOFSelectionStarted",   -- server → client
        "SOFSelectionPassed",    -- server → client: { unitId }
        "SOFSelectionFailed",    -- server → client: { reason }

        -- UI misc
        "NotificationSent",      -- server → client: { title, body, icon }
        "TutorialStepTriggered", -- server → client: { step }
        "ProfileCardUpdated",    -- server → client: { profileData }

        -- Admin
        "AdminAnnounce",         -- server → all clients: { message, sender, time }
    }

    for _, name in ipairs(eventNames) do
        getOrCreate(evFolder, "RemoteEvent", name)
    end

    -- ── Functions (client → server round trip) ────────────────────────────────
    local functionNames = {
        "GetPlayerData",        -- returns full save data for local player
        "GetJobInfo",           -- args: branch, job → returns JobConfig entry
        "ApplyForJob",          -- args: branch, job → returns ok, reason
        "RequestDeploy",        -- args: mapName → returns ok, reason
        "ClaimDailyReward",     -- returns reward table or nil if not available
        "ClaimBPReward",        -- args: tier → returns ok, reward
        "PurchaseShopItem",     -- args: productId → returns ok (dev product bridge)
        "GetMissions",          -- returns daily missions + weekly op for local player
        "SpawnVehicle",         -- args: vehicleId → returns ok, reason
        "RequestRevive",        -- returns ok
        "SubmitObjective",      -- args: objectiveType, amount → returns progress
        "GetLeaderboard",       -- args: category → returns top 25 entries
        "SetCallsign",          -- args: callsign → returns ok, reason
        "SelectBranch",         -- args: branch → returns ok
        "GetLoadout",           -- returns saved loadout table { Primary, Secondary, Throwable }
        "SaveLoadout",          -- args: loadoutTable → returns ok
        "AdminCommand",         -- args: cmd, ...args → returns { ok, msg/data }
        "AdminGetPlayers",      -- returns list of online players with data snapshots
    }

    for _, name in ipairs(functionNames) do
        getOrCreate(fnFolder, "RemoteFunction", name)
    end

    return Remotes
end

-- ─── Accessors ────────────────────────────────────────────────────────────────
local function waitForFolder()
    local root = ReplicatedStorage:WaitForChild("JTF", 10)
    assert(root, "JTF shared folder not found in ReplicatedStorage")
    return root
end

function Remotes.GetEvent(name)
    local root = waitForFolder()
    return root:WaitForChild("RemoteEvents"):WaitForChild(name, 10)
end

function Remotes.GetFunction(name)
    local root = waitForFolder()
    return root:WaitForChild("RemoteFunctions"):WaitForChild(name, 10)
end

-- Convenience: fire a named event to a specific player (server only)
function Remotes.FireClient(eventName, player, ...)
    Remotes.GetEvent(eventName):FireClient(player, ...)
end

-- Convenience: fire a named event to all players (server only)
function Remotes.FireAllClients(eventName, ...)
    Remotes.GetEvent(eventName):FireAllClients(...)
end

-- Convenience: fire event to server (client only)
function Remotes.FireServer(eventName, ...)
    Remotes.GetEvent(eventName):FireServer(...)
end

-- Convenience: invoke function (client only)
function Remotes.InvokeServer(fnName, ...)
    return Remotes.GetFunction(fnName):InvokeServer(...)
end

-- Convenience: set server callback (server only)
function Remotes.SetCallback(fnName, callback)
    Remotes.GetFunction(fnName).OnServerInvoke = callback
end

-- Convenience: connect to an event (works both sides)
function Remotes.On(eventName, callback)
    return Remotes.GetEvent(eventName).OnServerEvent:Connect(callback)
end

function Remotes.OnClient(eventName, callback)
    return Remotes.GetEvent(eventName).OnClientEvent:Connect(callback)
end

return Remotes
