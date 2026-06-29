-- AdminService: validates and executes admin/owner commands.
-- All commands are permission-checked against AdminConfig before execution.

local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared       = ReplicatedStorage:WaitForChild("JTF", 15)
local AdminConfig  = require(shared:WaitForChild("Config"):WaitForChild("AdminConfig"))
local Remotes      = require(shared:WaitForChild("Remotes"))

local AdminService = {}

-- Injected dependencies
local _DataService, _XPService, _EconomyService, _RankService, _NPCService, _NPCSpawner

function AdminService.SetDependencies(DataService, XPService, EconomyService, RankService, NPCService, NPCSpawner)
    _DataService   = DataService
    _XPService     = XPService
    _EconomyService = EconomyService
    _RankService   = RankService
    _NPCService    = NPCService
    _NPCSpawner    = NPCSpawner
end

-- ─── Log ring buffer ──────────────────────────────────────────────────────────

local LOG_MAX = 200
local Logs = {}

local function log(actorId, actorName, action, detail)
    local entry = {
        time   = os.time(),
        actor  = actorName .. " (" .. actorId .. ")",
        action = action,
        detail = detail or "",
    }
    table.insert(Logs, 1, entry)
    if #Logs > LOG_MAX then table.remove(Logs) end
    return entry
end

-- ─── Helper: resolve player by name or UserId ─────────────────────────────────

local function resolvePlayer(nameOrId)
    local id = tonumber(nameOrId)
    for _, p in ipairs(Players:GetPlayers()) do
        if id then
            if p.UserId == id then return p end
        else
            if p.Name:lower() == tostring(nameOrId):lower() then return p end
        end
    end
    return nil
end

-- ─── Ban store (in-memory; swap for DataStore for persistence) ────────────────

local BannedIds = {}  -- [userId] = {reason, bannedBy, timestamp}

Players.PlayerAdded:Connect(function(player)
    if BannedIds[player.UserId] then
        player:Kick("You are banned: " .. (BannedIds[player.UserId].reason or "No reason given"))
    end
end)

-- ─── Command implementations ──────────────────────────────────────────────────

local Commands = {}

function Commands.kick(actor, targetName, reason)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found: " .. tostring(targetName) end
    if target.UserId == AdminConfig.OwnerId and actor.UserId ~= AdminConfig.OwnerId then
        return false, "Cannot kick the owner"
    end
    target:Kick(reason or "Kicked by " .. actor.Name)
    log(actor.UserId, actor.Name, "kick", target.Name .. " — " .. (reason or "no reason"))
    return true, "Kicked " .. target.Name
end

function Commands.ban(actor, targetName, reason)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found: " .. tostring(targetName) end
    if target.UserId == AdminConfig.OwnerId then return false, "Cannot ban the owner" end
    BannedIds[target.UserId] = { reason = reason, bannedBy = actor.Name, timestamp = os.time() }
    target:Kick("Banned: " .. (reason or "No reason given"))
    log(actor.UserId, actor.Name, "ban", target.Name .. " — " .. (reason or "no reason"))
    return true, "Banned " .. target.Name
end

function Commands.unban(actor, userId)
    local id = tonumber(userId)
    if not id then return false, "Provide a numeric UserId" end
    if not BannedIds[id] then return false, "UserId " .. id .. " is not banned" end
    BannedIds[id] = nil
    log(actor.UserId, actor.Name, "unban", tostring(id))
    return true, "Unbanned UserId " .. id
end

function Commands.promote(actor, targetName)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found: " .. tostring(targetName) end
    local ok, msg = _RankService.PromotePlayer(target)
    if ok then log(actor.UserId, actor.Name, "promote", target.Name) end
    return ok, msg or (ok and "Promoted " .. target.Name or "Promotion failed")
end

function Commands.demote(actor, targetName)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found: " .. tostring(targetName) end
    local ok, msg = _RankService.DemotePlayer(target)
    if ok then log(actor.UserId, actor.Name, "demote", target.Name) end
    return ok, msg or (ok and "Demoted " .. target.Name or "Demotion failed")
end

function Commands.setRank(actor, targetName, rankIndex)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found" end
    local idx = tonumber(rankIndex)
    if not idx then return false, "Provide a numeric rank index" end
    local ok, msg = _RankService.SetRank(target, idx)
    if ok then log(actor.UserId, actor.Name, "setRank", target.Name .. " → " .. idx) end
    return ok, msg or (ok and "Set rank" or "Failed")
end

function Commands.giveCash(actor, targetName, amount)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found" end
    local amt = tonumber(amount)
    if not amt or amt <= 0 then return false, "Provide a positive amount" end
    _EconomyService.AddCash(target, amt)
    log(actor.UserId, actor.Name, "giveCash", target.Name .. " +" .. amt)
    return true, "Gave $" .. amt .. " to " .. target.Name
end

function Commands.giveXP(actor, targetName, amount)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found" end
    local amt = tonumber(amount)
    if not amt or amt <= 0 then return false, "Provide a positive amount" end
    _XPService.AwardXP(target, amt, "Admin")
    log(actor.UserId, actor.Name, "giveXP", target.Name .. " +" .. amt)
    return true, "Gave " .. amt .. " XP to " .. target.Name
end

function Commands.spawnNPC(actor, faction, count)
    local n = math.min(tonumber(count) or 1, 20)
    local playerPos = actor.Character
        and actor.Character:FindFirstChild("HumanoidRootPart")
        and actor.Character.HumanoidRootPart.Position
        or Vector3.new(0, 5, 0)

    local positions = {}
    for i = 1, n do
        local angle = (i / n) * math.pi * 2
        positions[i] = playerPos + Vector3.new(math.cos(angle) * 8, 0, math.sin(angle) * 8)
    end
    _NPCSpawner.SpawnGroup(faction or "Militia", positions)
    log(actor.UserId, actor.Name, "spawnNPC", n .. "x " .. (faction or "Militia"))
    return true, "Spawned " .. n .. " " .. (faction or "Militia") .. " NPCs"
end

function Commands.clearNPCs(actor)
    _NPCService.DespawnAll()
    log(actor.UserId, actor.Name, "clearNPCs", "")
    return true, "All NPCs despawned"
end

function Commands.announce(actor, message)
    if not message or message == "" then return false, "Provide a message" end
    Remotes.FireAllClients("AdminAnnounce", {
        message = message,
        sender  = actor.Name,
        time    = os.time(),
    })
    log(actor.UserId, actor.Name, "announce", message)
    return true, "Announcement sent"
end

function Commands.setWeather(actor, weatherType)
    local presets = {
        clear   = { FogEnd = 100000, Brightness = 2,    Ambient = Color3.fromRGB(200,200,200) },
        fog     = { FogEnd = 300,    Brightness = 0.5,  Ambient = Color3.fromRGB(100,100,100) },
        rain    = { FogEnd = 1200,   Brightness = 0.8,  Ambient = Color3.fromRGB(120,130,140) },
        storm   = { FogEnd = 500,    Brightness = 0.4,  Ambient = Color3.fromRGB( 80, 80, 90) },
        night   = { FogEnd = 800,    Brightness = 0,    Ambient = Color3.fromRGB( 30, 40, 50) },
        sunrise = { FogEnd = 3000,   Brightness = 1.2,  Ambient = Color3.fromRGB(220,180,130) },
    }
    local p = presets[weatherType]
    if not p then return false, "Unknown weather: " .. tostring(weatherType) end
    for k, v in pairs(p) do Lighting[k] = v end
    log(actor.UserId, actor.Name, "setWeather", weatherType)
    return true, "Weather set to " .. weatherType
end

function Commands.setTime(actor, hour)
    local h = tonumber(hour)
    if not h then return false, "Provide a numeric hour (0-24)" end
    h = math.clamp(h, 0, 24)
    Lighting.TimeOfDay = string.format("%02d:00:00", math.floor(h))
    log(actor.UserId, actor.Name, "setTime", h .. ":00")
    return true, "Time set to " .. h .. ":00"
end

function Commands.teleport(actor, targetName, destinationName)
    local target = resolvePlayer(targetName)
    if not target then return false, "Player not found: " .. tostring(targetName) end

    local destPos
    if destinationName then
        local dest = resolvePlayer(destinationName)
        if dest and dest.Character and dest.Character:FindFirstChild("HumanoidRootPart") then
            destPos = dest.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
        end
    end
    if not destPos then
        destPos = actor.Character and actor.Character:FindFirstChild("HumanoidRootPart")
            and actor.Character.HumanoidRootPart.Position + Vector3.new(3, 5, 0)
    end
    if not destPos then return false, "Could not determine destination" end

    local hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, target.Name .. " has no character loaded" end
    hrp.CFrame = CFrame.new(destPos)
    log(actor.UserId, actor.Name, "teleport", target.Name)
    return true, "Teleported " .. target.Name
end

function Commands.viewLogs(actor, count)
    local n = math.min(tonumber(count) or 30, LOG_MAX)
    local slice = {}
    for i = 1, math.min(n, #Logs) do slice[i] = Logs[i] end
    return true, slice
end

function Commands.serverStats(actor)
    local stats = {
        playerCount  = #Players:GetPlayers(),
        maxPlayers   = Players.MaxPlayers,
        npcCount     = _NPCService and _NPCService.GetAliveCount() or 0,
        serverTime   = os.time(),
        uptimeApprox = math.floor(workspace.DistributedGameTime),
    }
    return true, stats
end

-- ─── Remote dispatch ──────────────────────────────────────────────────────────

local COMMAND_PERM = {
    kick        = "kick",
    ban         = "ban",
    unban       = "unban",
    promote     = "promote",
    demote      = "demote",
    setRank     = "setRank",
    giveCash    = "giveCash",
    giveXP      = "giveXP",
    spawnNPC    = "spawnNPC",
    clearNPCs   = "spawnNPC",
    announce    = "announce",
    setWeather  = "setWeather",
    setTime     = "setTime",
    teleport    = "teleport",
    viewLogs    = "viewLogs",
    serverStats = "serverStats",
}

function AdminService.Init()
    Remotes.SetCallback("AdminCommand", function(player, commandName, ...)
        if not AdminConfig.IsAdmin(player.UserId) then
            return { ok = false, msg = "Access denied" }
        end
        local perm = COMMAND_PERM[commandName]
        if not perm then
            return { ok = false, msg = "Unknown command" }
        end
        if not AdminConfig.HasPermission(player.UserId, perm) then
            return { ok = false, msg = "Permission denied: " .. perm }
        end
        local fn = Commands[commandName]
        if not fn then
            return { ok = false, msg = "Not implemented" }
        end
        local ok, a, b = pcall(fn, player, ...)
        if not ok then
            warn("[AdminService]", commandName, a)
            return { ok = false, msg = "Server error" }
        end
        -- a = first return (bool success), b = second return (string msg or table data)
        if type(b) == "table" then
            return { ok = a, data = b }
        end
        return { ok = a, msg = tostring(b or "") }
    end)

    -- Owner-only: get full player list with data snapshots
    Remotes.SetCallback("AdminGetPlayers", function(player)
        if not AdminConfig.IsAdmin(player.UserId) then return {} end
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local data = _DataService and _DataService.GetData(p) or {}
            table.insert(list, {
                name     = p.Name,
                userId   = p.UserId,
                tier     = AdminConfig.GetTier(p.UserId),
                rank     = data.Rank or 1,
                xp       = data.XP   or 0,
                cash     = data.Cash  or 0,
                branch   = data.Branch or "None",
                job      = data.Job    or "None",
                kills    = data.TotalKills  or 0,
                deaths   = data.TotalDeaths or 0,
            })
        end
        return list
    end)

    print("[AdminService] Initialized")
end

return AdminService
