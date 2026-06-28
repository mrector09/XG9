-- TeamService: maps branches to Roblox Teams, handles friendly fire.

local Players  = game:GetService("Players")
local Teams    = game:GetService("Teams")
local Remotes  = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)

local TeamService = {}

-- Map branch name → Team instance (created on init)
local TeamMap = {}

-- Branches that are treated as hostile to all military branches
local HOSTILE_BRANCHES = { Hostile = true }

local BRANCH_COLORS = {
    Army       = BrickColor.new("Bright green"),
    Marines    = BrickColor.new("Forest green"),
    Navy       = BrickColor.new("Navy blue"),
    AirForce   = BrickColor.new("Medium blue"),
    SpaceForce = BrickColor.new("Dark blue"),
    Civilian   = BrickColor.new("Bright yellow"),
    Hostile    = BrickColor.new("Bright red"),
}

-- ─── Team creation ────────────────────────────────────────────────────────────
local function ensureTeam(name, color)
    local team = Teams:FindFirstChild(name)
    if not team then
        team = Instance.new("Team")
        team.Name          = name
        team.TeamColor     = color
        team.AutoAssignable = false
        team.Parent        = Teams
    end
    return team
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function TeamService.GetTeam(branch)
    return TeamMap[branch]
end

function TeamService.SetPlayerTeam(player, branch)
    local team = TeamMap[branch]
    if not team then
        warn("[TeamService] Unknown branch:", branch)
        return
    end
    player.Team = team
    Remotes.FireClient("TeamChanged", player, { teamName = branch })
end

function TeamService.GetPlayerBranch(player)
    local data = DataService.GetData(player)
    return data and data.Branch or "Army"
end

-- Returns true if a and b are on the same faction (friendly fire = false)
function TeamService.AreFriendly(playerA, playerB)
    local branchA = TeamService.GetPlayerBranch(playerA)
    local branchB = TeamService.GetPlayerBranch(playerB)

    -- Both hostile? They can hurt each other (PvP server rule — adjust as needed)
    if HOSTILE_BRANCHES[branchA] and HOSTILE_BRANCHES[branchB] then
        return false
    end

    -- One hostile, one military → enemies
    if HOSTILE_BRANCHES[branchA] ~= HOSTILE_BRANCHES[branchB] then
        return false
    end

    -- Both military → friendly
    return true
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function TeamService.Init()
    for branch, color in pairs(BRANCH_COLORS) do
        TeamMap[branch] = ensureTeam(branch, color)
    end

    Players.PlayerAdded:Connect(function(player)
        task.delay(1.5, function()  -- wait for data to load
            local branch = TeamService.GetPlayerBranch(player)
            TeamService.SetPlayerTeam(player, branch)
        end)
    end)

    print("[TeamService] Initialized.")
end

return TeamService
