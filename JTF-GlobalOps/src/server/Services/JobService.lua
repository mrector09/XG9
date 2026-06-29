-- JobService: job assignment, eligibility checks, and equipment grants.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)
local JobConfig   = require(script.Parent.Parent.Parent.shared.Config.JobConfig)
local RankConfig  = require(script.Parent.Parent.Parent.shared.Config.RankConfig)

local JobService = {}

local RankService   -- injected
local WeaponService -- injected

function JobService.SetDependencies(rs, ws)
    RankService   = rs
    WeaponService = ws
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getJobEntry(branch, job)
    local branchTable = JobConfig.Jobs[branch]
    return branchTable and branchTable[job]
end

local function playerHasBadge(data, badgeId)
    return data.Badges[badgeId] == true
end

local function playerHasSchool(data, schoolId)
    return data.SchoolsCompleted[schoolId] == true
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function JobService.GetCurrentJob(player)
    local data = DataService.GetData(player)
    if not data then return nil, nil end
    return data.Branch, data.Job
end

function JobService.GetJobEntry(branch, job)
    return getJobEntry(branch, job)
end

function JobService.CanApplyForJob(player, branch, job)
    local data  = DataService.GetData(player)
    local entry = getJobEntry(branch, job)

    if not data  then return false, "Data not loaded" end
    if not entry then return false, "Unknown job" end

    local req = entry.requirements or {}

    -- Rank check
    if req.rank and (data.Rank or 1) < req.rank then
        local needed = RankConfig.Ranks[req.rank]
        return false, ("Requires rank: %s"):format(needed and needed.name or "?")
    end

    -- Badge check
    for _, badgeId in ipairs(req.badges or {}) do
        if not playerHasBadge(data, badgeId) then
            return false, ("Missing badge: %s"):format(badgeId)
        end
    end

    -- School check
    for _, schoolId in ipairs(req.schools or {}) do
        if not playerHasSchool(data, schoolId) then
            return false, ("Missing school: %s"):format(schoolId)
        end
    end

    -- SOF check
    if entry.sofUnit then
        local sofMinRank = RankConfig.SOFMinRank or 4
        if (data.Rank or 1) < sofMinRank then
            return false, "Special Operations requires minimum Sergeant rank"
        end
    end

    return true
end

function JobService.ApplyForJob(player, branch, job)
    local ok, reason = JobService.CanApplyForJob(player, branch, job)
    if not ok then return false, reason end

    DataService.UpdateData(player, function(d)
        d.Branch = branch
        d.Job    = job
    end)

    -- Clear old equipment and grant new kit
    if WeaponService then
        WeaponService.ClearWeapons(player)
        local entry = getJobEntry(branch, job)
        if entry and entry.equipment then
            for _, weaponId in ipairs(entry.equipment) do
                WeaponService.GiveWeapon(player, weaponId)
            end
        end
    end

    Remotes.FireClient("JobChanged", player, { branch = branch, job = job })

    Remotes.FireClient("NotificationSent", player, {
        title = "Job Assigned",
        body  = ("You are now %s / %s"):format(branch, job),
        icon  = "Job",
    })

    return true
end

function JobService.GetAvailableJobs(player)
    local available = {}
    for branch, jobs in pairs(JobConfig.Jobs) do
        available[branch] = {}
        for jobName, _ in pairs(jobs) do
            local ok, reason = JobService.CanApplyForJob(player, branch, jobName)
            available[branch][jobName] = { available = ok, reason = reason }
        end
    end
    return available
end

-- Check if player's current job allows them to drive a specific vehicle
function JobService.CanDriveVehicle(player, vehicleId)
    local VehicleConfig = require(script.Parent.Parent.Parent.shared.Config.VehicleConfig)
    local vConfig = VehicleConfig.Vehicles[vehicleId]
    if not vConfig then return false, "Unknown vehicle" end

    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    local reqJobs = vConfig.requireJob
    if not reqJobs or #reqJobs == 0 then return true end  -- no restriction

    local currentJobKey = data.Branch .. "." .. data.Job
    for _, allowedKey in ipairs(reqJobs) do
        if allowedKey == currentJobKey then return true end
    end

    return false, "Your current job does not allow driving this vehicle"
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function JobService.Init()
    -- Remote callback: client requests job info
    Remotes.SetCallback("GetJobInfo", function(player, branch, job)
        return getJobEntry(branch, job)
    end)

    Remotes.SetCallback("ApplyForJob", function(player, branch, job)
        return JobService.ApplyForJob(player, branch, job)
    end)

    Remotes.SetCallback("SelectBranch", function(player, branch)
        if not JobConfig.Jobs[branch] then
            return false, "Invalid branch"
        end
        -- Assign the first available job in the branch, or Infantry / Rifleman / Sailor
        local defaultJobs = { Army = "Infantry", Marines = "Rifleman", Navy = "Sailor",
                               AirForce = "SecurityForces", SpaceForce = "CyberOperator",
                               Civilian = "Contractor", Hostile = "Raider" }
        local defaultJob  = defaultJobs[branch] or next(JobConfig.Jobs[branch])
        return JobService.ApplyForJob(player, branch, defaultJob)
    end)

    print("[JobService] Initialized.")
end

return JobService
