-- NPCSpawner: wave-based NPC spawning for missions.
-- Used by MissionService and BaseDefense events.

local NPCService = require(script.Parent.NPCService)

local NPCSpawner = {}

-- Active wave sessions: [sessionId] = { config, wavesRemaining, aliveCount, onComplete }
local Sessions = {}
local sessionCounter = 0

-- ─── Faction presets ─────────────────────────────────────────────────────────
local FACTION_PRESETS = {
    Raider   = { npcId = "Raider",    weapon = "M4A1",   health = 80  },
    Militia  = { npcId = "Militia",   weapon = "M16",    health = 90  },
    Insurgent = { npcId = "Insurgent", weapon = "M4A1",  health = 85  },
    Cartel   = { npcId = "Cartel",    weapon = "M4A1",   health = 95  },
    Pirate   = { npcId = "Pirate",    weapon = "Shotgun", health = 80  },
    PMC      = { npcId = "PMC",       weapon = "MK18",   health = 120, accurate = true },
}

--[[
    waveConfig = {
        sessionId    = string (auto-generated if nil),
        faction      = "Insurgent",
        spawnPoints  = { Vector3, ... },      -- spawn positions
        patrolArea   = { Vector3, ... },      -- patrol waypoints
        coverPoints  = { BasePart, ... },
        waves        = 3,
        npcsPerWave  = 5,
        waveCooldown = 10,                    -- seconds between waves
        onWaveClear  = function(waveNum) end, -- called when wave is cleared
        onAllClear   = function() end,         -- called when all waves done
    }
--]]
function NPCSpawner.StartWaves(waveConfig)
    sessionCounter = sessionCounter + 1
    local sessionId = waveConfig.sessionId or ("session_" .. sessionCounter)

    local preset  = FACTION_PRESETS[waveConfig.faction] or FACTION_PRESETS.Insurgent
    local session = {
        config         = waveConfig,
        preset         = preset,
        wavesRemaining = waveConfig.waves or 3,
        currentWave    = 0,
        aliveInWave    = 0,
        onWaveClear    = waveConfig.onWaveClear,
        onAllClear     = waveConfig.onAllClear,
        active         = true,
        spawnedBrains  = {},
    }

    Sessions[sessionId] = session
    NPCSpawner.SpawnNextWave(sessionId)

    return sessionId
end

function NPCSpawner.SpawnNextWave(sessionId)
    local session = Sessions[sessionId]
    if not session or not session.active then return end
    if session.wavesRemaining <= 0 then
        -- All waves complete
        Sessions[sessionId] = nil
        if session.onAllClear then
            session.onAllClear()
        end
        return
    end

    session.currentWave    = session.currentWave + 1
    session.wavesRemaining = session.wavesRemaining - 1

    local wc     = session.config
    local preset = session.preset
    local count  = wc.npcsPerWave or 5

    -- Scale difficulty with wave number
    local healthScale = 1 + (session.currentWave - 1) * 0.15
    local health      = math.floor((preset.health or 100) * healthScale)

    session.aliveInWave = count

    for i = 1, count do
        -- Pick a spawn point (cycle through them)
        local spawnPos = wc.spawnPoints and wc.spawnPoints[((i - 1) % #wc.spawnPoints) + 1]
            or Vector3.new(0, 5, 0)

        -- Offset slightly so NPCs don't stack
        spawnPos = spawnPos + Vector3.new(
            math.random(-4, 4), 0, math.random(-4, 4)
        )

        local brain = NPCService.SpawnNPC({
            npcId        = preset.npcId,
            faction      = wc.faction,
            weapon       = preset.weapon,
            health       = health,
            position     = spawnPos,
            patrolPoints = wc.patrolArea or {},
            coverPoints  = wc.coverPoints or {},
            onDeath      = function(b)
                NPCSpawner.OnNPCDeath(sessionId, b)
            end,
        })

        if brain then
            table.insert(session.spawnedBrains, brain)
        end
    end
end

function NPCSpawner.OnNPCDeath(sessionId, brain)
    local session = Sessions[sessionId]
    if not session then return end

    session.aliveInWave = math.max(0, session.aliveInWave - 1)

    if session.aliveInWave <= 0 then
        -- Wave cleared
        if session.onWaveClear then
            session.onWaveClear(session.currentWave)
        end

        if session.wavesRemaining > 0 then
            task.delay(session.config.waveCooldown or 10, function()
                NPCSpawner.SpawnNextWave(sessionId)
            end)
        else
            -- All waves done
            Sessions[sessionId] = nil
            if session.onAllClear then
                session.onAllClear()
            end
        end
    end
end

function NPCSpawner.StopSession(sessionId)
    local session = Sessions[sessionId]
    if session then
        session.active = false
        Sessions[sessionId] = nil
    end
end

-- Spawn a single NPC group (for patrols, gate guards, HVT escort etc.)
function NPCSpawner.SpawnGroup(faction, positions, patrolPoints, coverPoints, onDeath)
    local preset = FACTION_PRESETS[faction] or FACTION_PRESETS.Insurgent
    local brains = {}

    for _, pos in ipairs(positions) do
        local brain = NPCService.SpawnNPC({
            npcId        = preset.npcId,
            faction      = faction,
            weapon       = preset.weapon,
            health       = preset.health,
            position     = pos,
            patrolPoints = patrolPoints or {},
            coverPoints  = coverPoints  or {},
            onDeath      = onDeath,
        })
        if brain then
            table.insert(brains, brain)
        end
    end

    return brains
end

-- Spawn a named HVT (High Value Target) with boosted stats
function NPCSpawner.SpawnHVT(faction, position, patrolPoints, onCapture)
    local preset = FACTION_PRESETS[faction] or FACTION_PRESETS.PMC
    local brain  = NPCService.SpawnNPC({
        npcId        = preset.npcId .. "_HVT",  -- Studio model: e.g. PMC_HVT
        faction      = faction,
        weapon       = "MK18",
        health       = 300,
        position     = position,
        patrolPoints = patrolPoints or {},
        coverPoints  = {},
        onDeath      = onCapture,
    })

    -- Tag model as HVT
    if brain and brain.Model then
        local tag = Instance.new("BoolValue")
        tag.Name   = "IsHVT"
        tag.Value  = true
        tag.Parent = brain.Model
    end

    return brain
end

return NPCSpawner
