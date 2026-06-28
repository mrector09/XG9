-- SpecialOperationsService: SOF selection, eligibility, unit assignment.
-- SOF access CANNOT be purchased — it must be earned through gameplay.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)
local RankConfig  = require(script.Parent.Parent.Parent.shared.Config.RankConfig)

local SOFService = {}

local RankService -- injected
local XPService   -- injected

function SOFService.SetDependencies(rs, xs)
    RankService = rs
    XPService   = xs
end

-- SOF units and their unlock requirements
local SOF_UNITS = {
    Rangers = {
        displayName    = "75th Ranger Regiment",
        minRank        = 4,  -- Sergeant
        requiredBadges = { "AirborneWings" },
        requiredSchools = { "AirborneSchool", "RangerSchool" },
        selectionMission = "RangerSelection",
    },
    GreenBerets = {
        displayName    = "Special Forces (Green Berets)",
        minRank        = 4,
        requiredBadges = { "AirborneWings" },
        requiredSchools = { "AirborneSchool", "SFSelection" },
        selectionMission = "SFSelection",
    },
    SEAL = {
        displayName    = "Naval Special Warfare (SEALs)",
        minRank        = 4,
        requiredBadges = {},
        requiredSchools = { "DivingSchool", "AirborneSchool", "SOFSelection" },
        selectionMission = "SEALSelection",
    },
    Delta = {
        displayName    = "Delta-Style Unit",
        minRank        = 6,  -- Staff Sergeant
        requiredBadges = { "RangerTab", "AirborneWings" },
        requiredSchools = { "AirborneSchool", "RangerSchool", "SOFSelection" },
        selectionMission = "AdvancedSelection",
    },
    ForceRecon = {
        displayName    = "Force Reconnaissance",
        minRank        = 4,
        requiredBadges = { "AirborneWings" },
        requiredSchools = { "AirborneSchool", "DivingSchool", "SOFSelection" },
        selectionMission = "ForceReconSelection",
    },
    SOAR = {
        displayName    = "160th SOAR (Night Stalkers)",
        minRank        = 4,
        requiredBadges = { "PilotWings" },
        requiredSchools = { "FlightSchool", "AdvancedFlightSchool", "SOFSelection" },
        selectionMission = "SOARSelection",
    },
}

-- ─── Eligibility check ────────────────────────────────────────────────────────
function SOFService.CheckEligibility(player, unitId)
    local unit = SOF_UNITS[unitId]
    if not unit then return false, "Unknown SOF unit" end

    local data = DataService.GetData(player)
    if not data then return false, "Data not loaded" end

    -- Rank
    if (data.Rank or 1) < unit.minRank then
        local needed = RankConfig.Ranks[unit.minRank]
        return false, ("Requires rank: %s"):format(needed and needed.name or "?")
    end

    -- Badges
    for _, badgeId in ipairs(unit.requiredBadges) do
        if not (data.Badges and data.Badges[badgeId]) then
            return false, ("Missing badge: %s"):format(badgeId)
        end
    end

    -- Schools
    for _, schoolId in ipairs(unit.requiredSchools) do
        if not (data.SchoolsCompleted and data.SchoolsCompleted[schoolId]) then
            return false, ("Must complete school: %s"):format(schoolId)
        end
    end

    -- Not already in unit
    if data.SOFUnits and data.SOFUnits[unitId] then
        return false, "Already a member of this unit"
    end

    return true
end

-- ─── Selection ────────────────────────────────────────────────────────────────
function SOFService.StartSelection(player, unitId)
    local ok, reason = SOFService.CheckEligibility(player, unitId)
    if not ok then return false, reason end

    DataService.UpdateData(player, function(d)
        d.SOFSelectionActive = unitId
    end)

    Remotes.FireClient("SOFSelectionStarted", player, {
        unitId      = unitId,
        displayName = SOF_UNITS[unitId].displayName,
        mission     = SOF_UNITS[unitId].selectionMission,
    })

    return true
end

-- Called when the selection mission is completed on the deployment server
function SOFService.CompleteSelection(player, unitId, passed)
    local data = DataService.GetData(player)
    if not data or data.SOFSelectionActive ~= unitId then return false end

    DataService.UpdateData(player, function(d)
        d.SOFSelectionActive = false
    end)

    if not passed then
        Remotes.FireClient("SOFSelectionFailed", player, {
            reason = "Did not meet selection standards. Train and try again.",
        })
        return false
    end

    -- Grant unit membership
    DataService.UpdateData(player, function(d)
        d.SOFUnits        = d.SOFUnits or {}
        d.SOFUnits[unitId] = true
    end)

    -- Award SOF badge
    local badgeKey = unitId .. "_Member"
    DataService.UpdateData(player, function(d)
        d.Badges        = d.Badges or {}
        d.Badges[badgeKey] = true
    end)

    Remotes.FireClient("SOFSelectionPassed", player, {
        unitId      = unitId,
        displayName = SOF_UNITS[unitId].displayName,
    })

    if XPService then
        XPService.AwardXP(player, 1000, "SOFSelection")
    end

    Remotes.FireClient("NotificationSent", player, {
        title = "Welcome to " .. SOF_UNITS[unitId].displayName,
        body  = "You earned your place — no shortcuts.",
        icon  = "SOF",
    })

    return true
end

function SOFService.GetSOFUnits(player)
    local data = DataService.GetData(player)
    return data and data.SOFUnits or {}
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function SOFService.Init()
    print("[SOFService] Initialized.")
end

return SOFService
