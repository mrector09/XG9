-- TutorialService: scripted boot camp sequence for new recruits.
-- Covers the full 10-minute first-impression loop from the design spec.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.Parent.Services.DataService)

local TutorialService = {}

local XPService      -- injected
local RankService    -- injected
local WeaponService  -- injected
local NPCSpawner     -- injected (set after AI initializes)

function TutorialService.SetDependencies(xs, rs, ws, ns)
    XPService     = xs
    RankService   = rs
    WeaponService = ws
    NPCSpawner    = ns
end

-- ─── Step definitions ────────────────────────────────────────────────────────
-- Each step: { id, label, instruction, triggerType, triggerValue, autoAdvance }
-- triggerType: "reach" (proximity), "shoot" (fire weapon), "board" (sit in seat),
--              "kill" (kill NPC), "timed" (auto after N seconds), "server" (code calls AdvanceStep)
local STEPS = {
    [1] = {
        id          = "welcome",
        label       = "Report for Duty",
        instruction = "Welcome, Recruit. Move to the Armory marker to collect your M4A1.",
        triggerType = "reach",
        triggerTag  = "ArmoryMarker",
        radius      = 8,
    },
    [2] = {
        id          = "getWeapon",
        label       = "Collect Your Weapon",
        instruction = "Walk into the armory to receive your M4A1 rifle.",
        triggerType = "timed",
        triggerTime = 3,  -- auto-advance 3s after step starts (weapon is granted server-side)
    },
    [3] = {
        id          = "range",
        label       = "Head to the Range",
        instruction = "Move to the Firing Range and qualify with your M4A1. Hit 5 targets.",
        triggerType = "reach",
        triggerTag  = "RangeMarker",
        radius      = 12,
    },
    [4] = {
        id          = "qualify",
        label       = "Marksmanship Qualification",
        instruction = "Fire at the range targets. Hit 5 of them to qualify.",
        triggerType = "kill",
        killTarget  = "RangeTarget",
        killCount   = 5,
    },
    [5] = {
        id          = "humvee",
        label       = "Board the Humvee",
        instruction = "Head to the motor pool and board the Humvee for your convoy insertion.",
        triggerType = "board",
        vehicleTag  = "TutorialHumvee",
    },
    [6] = {
        id          = "convoy",
        label       = "Convoy to the AO",
        instruction = "Hold on — the convoy is moving to the desert AO. Stay mounted.",
        triggerType = "timed",
        triggerTime = 20,
    },
    [7] = {
        id          = "deploy",
        label       = "Clear the Objective",
        instruction = "Dismount and clear the enemy position. Eliminate all hostiles.",
        triggerType = "kill",
        killTarget  = "TutorialInsurgent",
        killCount   = 3,
    },
    [8] = {
        id          = "extract",
        label       = "Extract to LZ",
        instruction = "Objective secure. Move to the extraction point.",
        triggerType = "reach",
        triggerTag  = "ExtractMarker",
        radius      = 10,
    },
    [9] = {
        id          = "complete",
        label       = "Boot Camp Complete",
        instruction = "Outstanding, Recruit. You have been promoted to Private.",
        triggerType = "timed",
        triggerTime = 4,
    },
}

-- Per-player tutorial state
local PlayerState = {}  -- [userId] = { step, killCount, timer, connections }

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function getState(player)
    local id = player.UserId
    if not PlayerState[id] then
        PlayerState[id] = {
            step        = 0,
            killCount   = 0,
            timer       = 0,
            connections = {},
        }
    end
    return PlayerState[id]
end

local function sendStep(player, stepIndex)
    local step = STEPS[stepIndex]
    if not step then return end

    Remotes.FireClient("TutorialStepTriggered", player, {
        step        = stepIndex,
        id          = step.id,
        label       = step.label,
        instruction = step.instruction,
        total       = #STEPS,
    })
end

-- ─── Step advancement ─────────────────────────────────────────────────────────
function TutorialService.AdvanceStep(player)
    local state = getState(player)
    state.step      = state.step + 1
    state.killCount = 0
    state.timer     = 0

    -- Disconnect previous step connections
    for _, conn in ipairs(state.connections) do
        pcall(function() conn:Disconnect() end)
    end
    state.connections = {}

    local stepIndex = state.step
    local step      = STEPS[stepIndex]

    if not step then
        -- Tutorial complete
        TutorialService.Complete(player)
        return
    end

    sendStep(player, stepIndex)

    -- ── Step 2: grant weapon ──────────────────────────────────────────────────
    if step.id == "getWeapon" then
        if WeaponService then
            WeaponService.GiveWeapon(player, "M4A1")
            WeaponService.GiveWeapon(player, "M17")
        end
    end

    -- ── Step 4: spawn range targets ──────────────────────────────────────────
    if step.id == "qualify" then
        TutorialService.SpawnRangeTargets(player)
    end

    -- ── Step 7: spawn tutorial enemies ───────────────────────────────────────
    if step.id == "deploy" then
        TutorialService.SpawnTutorialEnemies(player)
    end

    -- ── Timed auto-advance ────────────────────────────────────────────────────
    if step.triggerType == "timed" then
        task.delay(step.triggerTime or 5, function()
            local s = getState(player)
            if s.step == stepIndex then
                TutorialService.AdvanceStep(player)
            end
        end)
    end

    -- ── Proximity trigger ─────────────────────────────────────────────────────
    if step.triggerType == "reach" and step.triggerTag then
        local marker = workspace:FindFirstChild(step.triggerTag, true)
        if marker then
            local conn = game:GetService("RunService").Heartbeat:Connect(function()
                local char = player.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local dist = (hrp.Position - marker.Position).Magnitude
                if dist <= (step.radius or 10) then
                    local s = getState(player)
                    if s.step == stepIndex then
                        TutorialService.AdvanceStep(player)
                    end
                end
            end)
            table.insert(state.connections, conn)
        end
    end

    -- ── Vehicle board trigger ─────────────────────────────────────────────────
    if step.triggerType == "board" and step.vehicleTag then
        local vehicle = workspace:FindFirstChild(step.vehicleTag, true)
        if vehicle then
            for _, seat in ipairs(vehicle:GetDescendants()) do
                if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
                    local conn = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                        if seat.Occupant then
                            local occ = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
                            if occ == player then
                                local s = getState(player)
                                if s.step == stepIndex then
                                    TutorialService.AdvanceStep(player)
                                end
                            end
                        end
                    end)
                    table.insert(state.connections, conn)
                end
            end
        end
    end
end

-- ─── Kill tracking (called externally by WeaponService on any kill) ───────────
function TutorialService.OnPlayerKill(player, victimModel)
    local state = getState(player)
    local step  = STEPS[state.step]
    if not step or step.triggerType ~= "kill" then return end

    -- Check kill target tag
    if step.killTarget then
        if not victimModel:FindFirstChild(step.killTarget) then return end
    end

    state.killCount = state.killCount + 1

    local needed = step.killCount or 1
    Remotes.FireClient("TutorialStepTriggered", player, {
        step        = state.step,
        killProgress = state.killCount,
        killGoal    = needed,
        instruction = step.instruction,
    })

    if state.killCount >= needed then
        TutorialService.AdvanceStep(player)
    end
end

-- ─── Range targets ────────────────────────────────────────────────────────────
function TutorialService.SpawnRangeTargets(player)
    if not NPCSpawner then return end
    -- Spawn 5 stationary dummies at the range
    local rangeMarker = workspace:FindFirstChild("RangeMarker", true)
    if not rangeMarker then return end

    local origin = rangeMarker.Position
    for i = 1, 5 do
        local pos = origin + Vector3.new((i - 3) * 6, 0, 15)
        NPCSpawner.SpawnGroup("Insurgent", { pos }, {}, {}, function(brain)
            -- Tag so TutorialService.OnPlayerKill can identify these
            local tag = Instance.new("StringValue")
            tag.Name   = "RangeTarget"
            tag.Parent = brain.Model
            TutorialService.OnPlayerKill(player, brain.Model)
        end)
    end
end

-- ─── Tutorial enemies ─────────────────────────────────────────────────────────
function TutorialService.SpawnTutorialEnemies(player)
    if not NPCSpawner then return end
    local deployMarker = workspace:FindFirstChild("TutorialDeployMarker", true)
    if not deployMarker then return end

    local origin = deployMarker.Position
    local positions = {
        origin + Vector3.new(10, 0, 10),
        origin + Vector3.new(-8, 0, 15),
        origin + Vector3.new(5, 0, 20),
    }

    NPCSpawner.SpawnGroup("Insurgent", positions, {}, {}, function(brain)
        local tag = Instance.new("StringValue")
        tag.Name   = "TutorialInsurgent"
        tag.Parent = brain.Model
        TutorialService.OnPlayerKill(player, brain.Model)
    end)
end

-- ─── Completion ───────────────────────────────────────────────────────────────
function TutorialService.Complete(player)
    DataService.UpdateData(player, function(d)
        d.TutorialComplete = true
    end)

    -- Promote to Private (Rank 2)
    if RankService then
        RankService.SetRank(player, 2)
    end

    -- Award XP and badge
    if XPService then
        XPService.AwardXP(player, 500, "TutorialComplete")
    end

    DataService.UpdateData(player, function(d)
        d.Badges = d.Badges or {}
        d.Badges["BootCampGraduate"] = true
    end)

    Remotes.FireClient("BadgeEarned", player, {
        badgeId   = "BootCampGraduate",
        badgeName = "Boot Camp Graduate",
    })

    Remotes.FireClient("NotificationSent", player, {
        title = "Boot Camp Complete!",
        body  = "Promoted to Private. Report to the Mission Board.",
        icon  = "Rank",
    })

    -- Clean up state
    local state = getState(player)
    for _, conn in ipairs(state.connections) do
        pcall(function() conn:Disconnect() end)
    end
    PlayerState[player.UserId] = nil
end

-- ─── Init ────────────────────────────────────────────────────────────────────
function TutorialService.StartForPlayer(player)
    local data = DataService.GetData(player)
    if data and data.TutorialComplete then return end

    local state = getState(player)
    if state.step > 0 then return end  -- already started

    task.delay(2, function()
        TutorialService.AdvanceStep(player)
    end)
end

function TutorialService.Init()
    Players.PlayerAdded:Connect(function(player)
        task.delay(4, function()
            TutorialService.StartForPlayer(player)
        end)
    end)
    print("[TutorialService] Initialized.")
end

return TutorialService
