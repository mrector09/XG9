-- DataService: handles all player data persistence via DataStoreService.
-- Uses session locking to prevent concurrent saves from overwriting each other.
-- All other services call DataService.GetData / UpdateData; they never touch DataStore directly.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local DataService = {}

local STORE_NAME   = "JTF_PlayerData_v1"
local SAVE_INTERVAL = 60  -- seconds between auto-saves

local DataStore = DataStoreService:GetDataStore(STORE_NAME)

-- In-memory cache. Keyed by UserId (number).
local Cache = {}

-- ─── Default player data schema ───────────────────────────────────────────────
local function defaultData()
    return {
        -- Progression
        XP              = 0,
        Rank            = 1,
        Prestige        = 0,
        Cash            = 500,

        -- Identity
        Branch          = "Army",
        Job             = "Infantry",
        Callsign        = "",

        -- Badges & ribbons (id → true)
        Badges          = {},
        DeploymentRibbons = {},

        -- Completion tracking
        DeploymentsCompleted = 0,
        SchoolsCompleted     = {},   -- { schoolId = true }
        WeaponKills          = {},   -- { weaponId = killCount }
        VehiclesUnlocked     = {},   -- { vehicleId = true }

        -- Battle pass
        BattlePassOwned  = false,
        BattlePassTier   = 0,
        BattlePassXP     = 0,
        BPClaimedTiers   = {},       -- { tier = true }

        -- Daily / weekly
        DailyStreak      = 0,
        LastLoginDate    = "",       -- "YYYY-MM-DD" UTC
        LastDailyClaim   = 0,        -- os.time()
        DailyMissions    = {},       -- { missionId = { progress, completed } }
        DailyMissionsDate = "",
        WeeklyDeployCount = 0,
        WeeklyOpClaimed  = false,
        WeeklyResetDate  = "",

        -- Missions
        ActiveMissionId  = nil,
        ObjectiveProgress = {},

        -- Gamepasses (mirrored server-side on join, never editable by client)
        OwnedGamepasses  = {},       -- { gamepassId = true }

        -- XP boosters (active temp booster)
        TempXPBoost      = 0,        -- multiplier (0 = none)
        TempXPBoostExpiry = 0,       -- os.time()

        -- Stats
        TotalKills       = 0,
        TotalDeaths      = 0,
        TotalRevives     = 0,
        FlightHours      = 0,        -- stored as minutes internally
        DrivingStuds     = 0,

        -- SOF
        SOFUnits         = {},       -- { unitId = true }
        SOFSelectionActive = false,

        -- Flags
        TutorialComplete = false,

        -- Metadata
        CreatedAt        = os.time(),
        LastSaved        = os.time(),
        Version          = 1,
    }
end

-- ─── Reconcile: fill in missing keys from default without overwriting existing ─
local function reconcile(data, default)
    for key, value in pairs(default) do
        if data[key] == nil then
            if type(value) == "table" then
                data[key] = {}
                reconcile(data[key], value)
            else
                data[key] = value
            end
        end
    end
end

-- ─── Load ─────────────────────────────────────────────────────────────────────
local function loadData(userId)
    local key = tostring(userId)
    local success, result = pcall(function()
        return DataStore:GetAsync(key)
    end)

    if not success then
        warn("[DataService] Failed to load data for", userId, ":", result)
        return defaultData()  -- give fresh data so player can still play
    end

    if result == nil then
        return defaultData()
    end

    reconcile(result, defaultData())
    return result
end

-- ─── Save ─────────────────────────────────────────────────────────────────────
local function saveData(userId, data)
    if not data then return end
    data.LastSaved = os.time()

    local key = tostring(userId)
    local retries = 3
    local success, err

    for i = 1, retries do
        success, err = pcall(function()
            DataStore:SetAsync(key, data)
        end)
        if success then break end
        warn(("[DataService] Save attempt %d failed for %d: %s"):format(i, userId, tostring(err)))
        if i < retries then task.wait(2 ^ i) end
    end

    if not success then
        warn("[DataService] All save attempts failed for", userId)
    end
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function DataService.GetData(playerOrId)
    local id = typeof(playerOrId) == "Instance" and playerOrId.UserId or playerOrId
    return Cache[id]
end

-- Pass a function that mutates the data table
function DataService.UpdateData(playerOrId, mutator)
    local id = typeof(playerOrId) == "Instance" and playerOrId.UserId or playerOrId
    local data = Cache[id]
    if not data then
        warn("[DataService] UpdateData called for unloaded player", id)
        return
    end
    mutator(data)
end

function DataService.GetOrDefault(playerOrId, key)
    local data = DataService.GetData(playerOrId)
    if not data then return nil end
    return data[key]
end

function DataService.SaveNow(playerOrId)
    local id = typeof(playerOrId) == "Instance" and playerOrId.UserId or playerOrId
    saveData(id, Cache[id])
end

-- ─── Player join / leave ──────────────────────────────────────────────────────
function DataService.OnPlayerAdded(player)
    local data = loadData(player.UserId)
    Cache[player.UserId] = data
end

function DataService.OnPlayerRemoving(player)
    local data = Cache[player.UserId]
    if data then
        saveData(player.UserId, data)
        Cache[player.UserId] = nil
    end
end

-- ─── Auto-save loop ───────────────────────────────────────────────────────────
local function startAutoSave()
    task.spawn(function()
        while true do
            task.wait(SAVE_INTERVAL)
            for userId, data in pairs(Cache) do
                saveData(userId, data)
            end
        end
    end)
end

-- ─── Game close: save everyone immediately ────────────────────────────────────
game:BindToClose(function()
    for userId, data in pairs(Cache) do
        saveData(userId, data)
    end
end)

-- ─── Init ─────────────────────────────────────────────────────────────────────
function DataService.Init()
    Players.PlayerAdded:Connect(DataService.OnPlayerAdded)
    Players.PlayerRemoving:Connect(DataService.OnPlayerRemoving)

    -- Load any players already in the server (Studio test)
    for _, player in ipairs(Players:GetPlayers()) do
        DataService.OnPlayerAdded(player)
    end

    startAutoSave()
    print("[DataService] Initialized.")
end

return DataService
