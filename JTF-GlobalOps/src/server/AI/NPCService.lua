-- NPCService: manages all NPC instances, the update loop, and XP rewards on kill.
-- Other services call NPCService.SpawnNPC / DespawnAll / GetAliveCount.

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local NPCBrain   = require(script.Parent.NPCBrain)

local NPCService = {}

local XPService      -- injected
local MissionService -- injected

function NPCService.SetDependencies(xs, ms)
    XPService      = xs
    MissionService = ms
end

-- Active brains keyed by model
local ActiveBrains = {}

-- Update tick rate (seconds between AI ticks — saves performance)
local TICK_RATE = 0.1
local lastTick  = 0

-- ─── NPC template loader ──────────────────────────────────────────────────────
local function getTemplate(npcId)
    local storage = game.ServerStorage:FindFirstChild("NPCs")
    return storage and storage:FindFirstChild(npcId)
end

-- ─── Public API ───────────────────────────────────────────────────────────────

--[[
    config = {
        npcId        = "Insurgent",      -- model name in ServerStorage/NPCs/
        faction      = "Hostile",
        weapon       = "M4A1",
        health       = 100,
        position     = Vector3,
        patrolPoints = { Vector3, ... },
        coverPoints  = { BasePart, ... },
        onAlert      = function(player) end,   -- optional callback
        onDeath      = function(brain) end,    -- optional callback
    }
--]]
function NPCService.SpawnNPC(config)
    local template = getTemplate(config.npcId or "Insurgent")
    if not template then
        warn("[NPCService] Template not found:", config.npcId)
        return nil
    end

    local model = template:Clone()
    model:SetPrimaryPartCFrame(CFrame.new(config.position or Vector3.new(0, 5, 0)))
    model.Parent = workspace

    local brain = NPCBrain.new(model, config)

    -- Register in global brain list for inter-NPC communication
    NPCBrain.AllBrains[model] = brain
    ActiveBrains[model]       = brain

    -- Alert callback
    if config.onAlert then
        table.insert(brain.AlertCallbacks, config.onAlert)
    end

    -- Death callback: XP reward + mission tracking
    local originalDeath = brain.OnDeath
    brain.OnDeath = function(b)
        originalDeath(b)  -- calls model cleanup etc.

        -- Award XP to whoever killed this NPC
        -- WeaponService.HandleKill already calls XPService for player kills
        -- For NPC kills via server-side damage we fire here too
        if config.onDeath then
            config.onDeath(brain)
        end

        NPCBrain.AllBrains[model] = nil
        ActiveBrains[model]       = nil
    end

    return brain
end

function NPCService.DespawnAll()
    for model, brain in pairs(ActiveBrains) do
        brain.Alive = false
        if model and model.Parent then
            model:Destroy()
        end
    end
    ActiveBrains       = {}
    NPCBrain.AllBrains = {}
end

function NPCService.GetAliveCount()
    local count = 0
    for _, brain in pairs(ActiveBrains) do
        if brain.Alive then count = count + 1 end
    end
    return count
end

function NPCService.GetAllBrains()
    return ActiveBrains
end

-- Alert all NPCs in range of a position (used when a gunshot fires)
function NPCService.AlertInRange(position, range, alertingPlayer)
    for _, brain in pairs(ActiveBrains) do
        if brain.Alive and brain.State == "Patrol" or brain.State == "Idle" then
            local dist = (brain:GetPosition() - position).Magnitude
            if dist <= range then
                brain.Target = alertingPlayer
                brain:SetState("Alerted")
            end
        end
    end
end

-- ─── Main update loop ─────────────────────────────────────────────────────────
function NPCService.Init()
    RunService.Heartbeat:Connect(function(dt)
        local now = tick()
        if now - lastTick < TICK_RATE then return end
        lastTick = now

        for model, brain in pairs(ActiveBrains) do
            if not model or not model.Parent then
                ActiveBrains[model]       = nil
                NPCBrain.AllBrains[model] = nil
            else
                local ok, err = pcall(brain.Update, brain, TICK_RATE)
                if not ok then
                    warn("[NPCService] Brain update error:", err)
                end
            end
        end
    end)

    print("[NPCService] Initialized.")
end

return NPCService
