-- NPCBrain: per-NPC state machine.
-- One NPCBrain instance is created per NPC model by NPCService.
-- States: Idle → Patrol → Alerted → Engaging → Searching → Dead

local PathfindingService = game:GetService("PathfindingService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")

local NPCBrain = {}
NPCBrain.__index = NPCBrain

-- ─── Tuning constants ─────────────────────────────────────────────────────────
local DETECTION_RANGE    = 80    -- studs before NPC can see player
local HEARING_RANGE      = 50    -- studs — alert without line of sight
local ENGAGE_RANGE       = 60    -- studs — NPC will shoot within this range
local LOSE_TARGET_TIME   = 8     -- seconds without LOS before switching to Search
local SEARCH_TIME        = 12    -- seconds spent searching before returning to Patrol
local FIRE_COOLDOWN      = 0.65  -- seconds between shots
local ACCURACY_SPREAD    = 3.0   -- degrees of random bullet spread (higher = worse)
local MAX_HEALTH         = 100
local PATROL_WAIT        = 3     -- seconds to wait at each patrol waypoint
local PATHFIND_TIMEOUT   = 5     -- seconds before re-computing path

-- ─── Constructor ──────────────────────────────────────────────────────────────
function NPCBrain.new(model, config)
    local self = setmetatable({}, NPCBrain)

    self.Model      = model
    self.Humanoid   = model:FindFirstChildOfClass("Humanoid")
    self.HRP        = model:FindFirstChild("HumanoidRootPart")
    self.Animator   = self.Humanoid and self.Humanoid:FindFirstChildOfClass("Animator")

    self.Config     = config or {}
    self.Faction    = config.faction or "Hostile"
    self.WeaponId   = config.weapon  or "M4A1"

    -- State machine
    self.State      = "Idle"
    self.Target     = nil         -- Player instance
    self.TargetLastSeen = 0       -- tick()
    self.SearchTimer    = 0
    self.FireTimer      = 0
    self.PatrolIndex    = 1
    self.PatrolPoints   = config.patrolPoints or {}
    self.PatrolWaitTimer = 0
    self.PathTimer      = 0
    self.CurrentPath    = nil
    self.WaypointIndex  = 1
    self.AlertCallbacks = {}      -- fired when NPC spots a player

    -- Cover points near spawn (set by NPCSpawner)
    self.CoverPoints = config.coverPoints or {}
    self.CurrentCover = nil

    self.Alive = true
    self.Health = config.health or MAX_HEALTH

    -- Set Humanoid health
    if self.Humanoid then
        self.Humanoid.MaxHealth = self.Health
        self.Humanoid.Health    = self.Health
    end

    -- Wire up death
    if self.Humanoid then
        self.Humanoid.Died:Connect(function()
            self:OnDeath()
        end)
    end

    return self
end

-- ─── Utilities ────────────────────────────────────────────────────────────────
function NPCBrain:GetPosition()
    return self.HRP and self.HRP.Position or Vector3.new(0, 0, 0)
end

function NPCBrain:LookAt(target)
    if not self.HRP then return end
    local dir = (target - self:GetPosition()) * Vector3.new(1, 0, 1)
    if dir.Magnitude < 0.1 then return end
    self.HRP.CFrame = CFrame.lookAt(self:GetPosition(), self:GetPosition() + dir)
end

function NPCBrain:HasLineOfSight(targetPos)
    local origin = self:GetPosition() + Vector3.new(0, 1.5, 0)
    local dir    = targetPos - origin

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { self.Model }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end

    -- If raycast hit a player character part, we have LOS
    local character = result.Instance:FindFirstAncestorOfClass("Model")
    local player    = character and Players:GetPlayerFromCharacter(character)
    return player ~= nil
end

function NPCBrain:FindClosestPlayer()
    local best     = nil
    local bestDist = DETECTION_RANGE

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local dist = (hrp.Position - self:GetPosition()).Magnitude
        if dist < bestDist then
            if self:HasLineOfSight(hrp.Position) then
                bestDist = dist
                best     = player
            end
        end
    end

    return best
end

-- ─── Pathfinding movement ─────────────────────────────────────────────────────
function NPCBrain:MoveTo(destination)
    if not self.Humanoid or not self.HRP then return end

    local now = tick()
    if now - self.PathTimer < PATHFIND_TIMEOUT and self.CurrentPath then
        return  -- still following existing path
    end

    self.PathTimer = now

    local path = PathfindingService:CreatePath({
        AgentRadius   = 2,
        AgentHeight   = 5,
        AgentCanJump  = true,
        AgentJumpHeight = 7,
        AgentMaxSlope = 45,
    })

    local ok, err = pcall(function()
        path:ComputeAsync(self:GetPosition(), destination)
    end)

    if not ok or path.Status ~= Enum.PathStatus.Success then
        -- Fallback: walk straight toward destination
        self.Humanoid:MoveTo(destination)
        return
    end

    self.CurrentPath   = path
    self.WaypointIndex = 2

    local waypoints = path:GetWaypoints()

    local function followNext()
        if not self.Alive then return end
        if self.WaypointIndex > #waypoints then
            self.CurrentPath = nil
            return
        end

        local wp = waypoints[self.WaypointIndex]
        if wp.Action == Enum.PathWaypointAction.Jump then
            self.Humanoid.Jump = true
        end

        self.Humanoid:MoveTo(wp.Position)
        self.WaypointIndex = self.WaypointIndex + 1

        -- Advance when reached
        local moveConn
        moveConn = self.Humanoid.MoveToFinished:Connect(function(reached)
            moveConn:Disconnect()
            if self.Alive then
                followNext()
            end
        end)
    end

    followNext()
end

-- ─── Shooting ─────────────────────────────────────────────────────────────────
function NPCBrain:ShootAt(targetChar)
    local now = tick()
    if now - self.FireTimer < FIRE_COOLDOWN then return end
    self.FireTimer = now

    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local origin = self:GetPosition() + Vector3.new(0, 1.5, 0)
    local dir    = (hrp.Position + Vector3.new(0, 1, 0) - origin).Unit

    -- Apply accuracy spread
    local spread = math.rad(ACCURACY_SPREAD)
    dir = CFrame.Angles(
        math.random() * spread - spread / 2,
        math.random() * spread - spread / 2,
        0
    ) * dir

    -- Raycast for hit
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = { self.Model }
    params.FilterType = Enum.RaycastFilterType.Exclude

    local WeaponConfig = require(script.Parent.Parent.Parent.shared.Config.WeaponConfig)
    local wConfig = WeaponConfig.Weapons[self.WeaponId]
    local range   = wConfig and wConfig.range or 300

    local result = workspace:Raycast(origin, dir * range, params)
    if not result then return end

    local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
    if not hitChar then return end

    local hum = hitChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Only damage players (not own faction)
    local victim = Players:GetPlayerFromCharacter(hitChar)
    if not victim then return end

    local damage   = wConfig and wConfig.damage or 20
    local isHead   = result.Instance.Name == "Head"
    if isHead then damage = damage * (wConfig and wConfig.headMulti or 1.5) end

    hum:TakeDamage(damage)
end

-- ─── Cover system ─────────────────────────────────────────────────────────────
function NPCBrain:SeekCover(fromPosition)
    if #self.CoverPoints == 0 then return nil end

    local best     = nil
    local bestScore = -math.huge

    for _, coverPart in ipairs(self.CoverPoints) do
        if not coverPart or not coverPart.Parent then continue end
        local pos  = coverPart.Position
        local dist = (pos - self:GetPosition()).Magnitude
        -- Score: close to NPC, far from threat
        local threatDist = (pos - fromPosition).Magnitude
        local score = threatDist - dist * 0.5
        if score > bestScore then
            bestScore = score
            best      = coverPart
        end
    end

    if best then
        self.CurrentCover = best
        self:MoveTo(best.Position)
    end

    return best
end

-- ─── State handlers ───────────────────────────────────────────────────────────
function NPCBrain:StateIdle(dt)
    -- Look around slowly, transition to Patrol if waypoints exist
    if #self.PatrolPoints > 0 then
        self:SetState("Patrol")
    end

    local target = self:FindClosestPlayer()
    if target then self:OnSpotPlayer(target) end
end

function NPCBrain:StatePatrol(dt)
    local target = self:FindClosestPlayer()
    if target then self:OnSpotPlayer(target) return end

    if #self.PatrolPoints == 0 then self:SetState("Idle") return end

    -- Wait at waypoint
    self.PatrolWaitTimer = (self.PatrolWaitTimer or 0) - dt
    if self.PatrolWaitTimer > 0 then return end

    local wp = self.PatrolPoints[self.PatrolIndex]
    if not wp then return end

    local dist = (wp - self:GetPosition()).Magnitude
    if dist < 4 then
        -- Reached waypoint — wait then advance
        self.PatrolWaitTimer = PATROL_WAIT
        self.PatrolIndex = (self.PatrolIndex % #self.PatrolPoints) + 1
    else
        self:MoveTo(wp)
    end
end

function NPCBrain:StateAlerted(dt)
    -- Brief alert pause before engaging
    task.delay(1.2, function()
        if self.Alive and self.State == "Alerted" then
            self:SetState("Engaging")
        end
    end)

    -- Alert nearby NPCs
    for _, brain in pairs(NPCBrain.AllBrains or {}) do
        if brain ~= self and brain.Alive and brain.State == "Patrol" then
            local dist = (brain:GetPosition() - self:GetPosition()).Magnitude
            if dist < HEARING_RANGE * 2 then
                brain.Target = self.Target
                brain:SetState("Alerted")
            end
        end
    end
end

function NPCBrain:StateEngaging(dt)
    if not self.Target or not self.Target.Character then
        self:SetState("Searching")
        return
    end

    local targetChar = self.Target.Character
    local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then self:SetState("Searching") return end

    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then
        self.Target = nil
        self:SetState("Patrol")
        return
    end

    local dist    = (targetHRP.Position - self:GetPosition()).Magnitude
    local hasLOS  = self:HasLineOfSight(targetHRP.Position)

    if hasLOS then
        self.TargetLastSeen = tick()
    end

    -- Lost sight for too long
    if tick() - self.TargetLastSeen > LOSE_TARGET_TIME then
        self:SetState("Searching")
        return
    end

    self:LookAt(targetHRP.Position)

    if hasLOS and dist <= ENGAGE_RANGE then
        -- Stand and fight if close, seek cover if taking fire
        self:ShootAt(targetChar)
    elseif dist > ENGAGE_RANGE then
        -- Close distance
        self:MoveTo(targetHRP.Position)
    else
        -- No LOS — move to last known position
        self:MoveTo(targetHRP.Position)
    end
end

function NPCBrain:StateSearching(dt)
    self.SearchTimer = (self.SearchTimer or SEARCH_TIME) - dt

    -- Walk to last known target area (stored in HRP when we lost LOS)
    if self.LastKnownTargetPos then
        local dist = (self.LastKnownTargetPos - self:GetPosition()).Magnitude
        if dist > 5 then
            self:MoveTo(self.LastKnownTargetPos)
        end
    end

    -- Check if player reappears
    local target = self:FindClosestPlayer()
    if target then self:OnSpotPlayer(target) return end

    if self.SearchTimer <= 0 then
        self.SearchTimer         = SEARCH_TIME
        self.LastKnownTargetPos  = nil
        self:SetState("Patrol")
    end
end

-- ─── State machine core ───────────────────────────────────────────────────────
function NPCBrain:SetState(newState)
    self.State        = newState
    self.CurrentPath  = nil  -- reset path on state change
    self.PathTimer    = 0

    -- Per-state setup
    if newState == "Searching" then
        self.SearchTimer = SEARCH_TIME
        if self.Target and self.Target.Character then
            local hrp = self.Target.Character:FindFirstChild("HumanoidRootPart")
            self.LastKnownTargetPos = hrp and hrp.Position
        end
    end
end

function NPCBrain:OnSpotPlayer(player)
    self.Target         = player
    self.TargetLastSeen = tick()
    if self.State ~= "Engaging" then
        self:SetState("Alerted")
    end

    -- Fire alert callbacks (used by NPCService to notify MissionService)
    for _, cb in ipairs(self.AlertCallbacks) do
        pcall(cb, player)
    end
end

function NPCBrain:OnDeath()
    self.Alive = false
    self:SetState("Dead")

    -- Drop weapon prop (optional — place a Tool on the ground)
    -- Reward XP to killer is handled by WeaponService.HandleKill

    -- Clean up body after delay
    task.delay(12, function()
        if self.Model and self.Model.Parent then
            self.Model:Destroy()
        end
    end)

    -- Notify NPCService
    if NPCBrain.OnDeathCallback then
        NPCBrain.OnDeathCallback(self)
    end
end

-- ─── Main update ──────────────────────────────────────────────────────────────
function NPCBrain:Update(dt)
    if not self.Alive then return end
    if not self.Humanoid or self.Humanoid.Health <= 0 then return end

    if     self.State == "Idle"      then self:StateIdle(dt)
    elseif self.State == "Patrol"    then self:StatePatrol(dt)
    elseif self.State == "Alerted"   then self:StateAlerted(dt)
    elseif self.State == "Engaging"  then self:StateEngaging(dt)
    elseif self.State == "Searching" then self:StateSearching(dt)
    end
end

-- Global registry for inter-NPC communication
NPCBrain.AllBrains = {}

return NPCBrain
