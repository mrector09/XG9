-- MedicalService: healing, revival, downed state, medevac.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)

local MedicalService = {}

local XPService      -- injected
local MissionService -- injected

function MedicalService.SetDependencies(xs, ms)
    XPService      = xs
    MissionService = ms
end

-- Downed players: [userId] = { bleedOutTimer, connection }
local DownedPlayers = {}

local BLEED_OUT_TIME = 30  -- seconds before death when downed

local MEDIC_JOBS = {
    ["Army.Medic"]          = true,
    ["Navy.Corpsman"]       = true,
    ["AirForce.Pararescue"] = true,
    ["Civilian.Doctor"]     = true,
}

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function isMedic(player)
    local data = DataService.GetData(player)
    if not data then return false end
    local key = data.Branch .. "." .. data.Job
    return MEDIC_JOBS[key] == true
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function MedicalService.HealPlayer(player, amount, healer)
    local char = player.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)

    Remotes.FireClient("HealApplied", player, { amount = amount })

    -- Award XP to healer
    if healer and XPService then
        XPService.AwardXP(healer, 15, "Heal")
    end

    return true
end

-- Put a player into a downed state instead of dying (if medic nearby)
function MedicalService.DownPlayer(player)
    if DownedPlayers[player.UserId] then return end

    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Keep health at 1 to prevent normal death
    humanoid.Health = 1

    -- Disable movement
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    DownedPlayers[player.UserId] = true

    Remotes.FireClient("NotificationSent", player, {
        title = "You are Down!",
        body  = "Wait for a medic, or you will bleed out.",
        icon  = "Medical",
    })

    -- Broadcast to nearby medics
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and isMedic(other) then
                local otherChar = other.Character
                local otherHRP  = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
                if otherHRP and (otherHRP.Position - hrp.Position).Magnitude < 100 then
                    Remotes.FireClient("ReviveOffered", other, { medicId = player.UserId })
                end
            end
        end
    end

    -- Start bleed-out timer
    task.delay(BLEED_OUT_TIME, function()
        if DownedPlayers[player.UserId] then
            MedicalService.KillDowned(player)
        end
    end)
end

function MedicalService.RevivePlayer(player, medic)
    if not DownedPlayers[player.UserId] then
        return false, "Player is not downed"
    end

    local char = player.Character
    if not char then return false, "No character" end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    humanoid.Health    = humanoid.MaxHealth * 0.4  -- revive at 40% health
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50

    DownedPlayers[player.UserId] = nil

    Remotes.FireClient("PlayerRevived", player)

    -- XP to medic
    if medic and XPService then
        XPService.AwardXPFromSource(medic, "ReviveTeammate")
    end

    -- Track revives for daily mission
    if medic and MissionService then
        MissionService.TrackObjective(medic, "HealCount", 1)
    end

    DataService.UpdateData(medic or player, function(d)
        if medic then
            d.TotalRevives = (d.TotalRevives or 0) + 1
        end
    end)

    return true
end

function MedicalService.KillDowned(player)
    DownedPlayers[player.UserId] = nil
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:TakeDamage(humanoid.MaxHealth)
    end
end

-- ─── Remote callbacks ─────────────────────────────────────────────────────────
function MedicalService.Init()
    Remotes.SetCallback("RequestRevive", function(medic, targetId)
        local target = Players:GetPlayerByUserId(targetId)
        if not target then return false, "Player not found" end
        if not isMedic(medic) then return false, "You are not a medic" end
        return MedicalService.RevivePlayer(target, medic)
    end)

    Players.PlayerRemoving:Connect(function(player)
        DownedPlayers[player.UserId] = nil
    end)

    print("[MedicalService] Initialized.")
end

return MedicalService
