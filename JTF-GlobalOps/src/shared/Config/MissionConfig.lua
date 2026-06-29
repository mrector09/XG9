-- MissionConfig: deployment maps, mission types, and daily/weekly templates.

local MissionConfig = {}

-- ─── Deployment Maps ─────────────────────────────────────────────────────────
MissionConfig.Maps = {
    Desert = {
        displayName  = "Operation Sand Viper",
        environment  = "Desert",
        thumbnail    = "rbxassetid://0",  -- replace with actual asset ID
        minRank      = 1,
        xpMultiplier = 1.0,
        availableModes = { "Patrol", "Convoy", "Raid", "HVTCapture" },
        ribbon       = "DesertCampaign",
        nightMode    = true,
        weather      = { "Clear", "Sandstorm", "HeatHaze" },
        enemyFaction = "Raider",
    },
    Jungle = {
        displayName  = "Operation Green Canopy",
        environment  = "Jungle",
        thumbnail    = "rbxassetid://0",
        minRank      = 2,
        xpMultiplier = 1.15,
        availableModes = { "Patrol", "HostageRescue", "Raid", "Ambush" },
        ribbon       = "JungleCampaign",
        nightMode    = true,
        weather      = { "Clear", "Rain", "HeavyRain", "Fog" },
        enemyFaction = "Cartel",
    },
    Arctic = {
        displayName  = "Operation Frozen Wolf",
        environment  = "Arctic",
        thumbnail    = "rbxassetid://0",
        minRank      = 3,
        xpMultiplier = 1.25,
        availableModes = { "Patrol", "BaseDefense", "HVTCapture", "MedEvac" },
        ribbon       = "ArcticCampaign",
        nightMode    = true,
        weather      = { "Clear", "Blizzard", "Fog" },
        enemyFaction = "Militia",
    },
    Mountain = {
        displayName  = "Operation Iron Peak",
        environment  = "Mountain",
        thumbnail    = "rbxassetid://0",
        minRank      = 3,
        xpMultiplier = 1.25,
        availableModes = { "Patrol", "Raid", "HostageRescue", "Convoy" },
        ribbon       = "MountainCampaign",
        nightMode    = true,
        weather      = { "Clear", "Snow", "Fog", "Wind" },
        enemyFaction = "Insurgent",
    },
    UrbanCity = {
        displayName  = "Operation Urban Storm",
        environment  = "Urban",
        thumbnail    = "rbxassetid://0",
        minRank      = 4,
        xpMultiplier = 1.35,
        availableModes = { "Raid", "HostageRescue", "HVTCapture", "Patrol", "GateGuard" },
        ribbon       = "UrbanCampaign",
        nightMode    = true,
        weather      = { "Clear", "Rain", "Fog" },
        enemyFaction = "PMC",
    },
    Island = {
        displayName  = "Operation Blue Tide",
        environment  = "Island",
        thumbnail    = "rbxassetid://0",
        minRank      = 4,
        xpMultiplier = 1.35,
        availableModes = { "Raid", "HostageRescue", "Convoy", "AirAssault" },
        ribbon       = "IslandCampaign",
        nightMode    = true,
        weather      = { "Clear", "Tropical Storm", "Rain" },
        enemyFaction = "Pirate",
    },
    EuropeanForest = {
        displayName  = "Operation Grey Forest",
        environment  = "Forest",
        thumbnail    = "rbxassetid://0",
        minRank      = 5,
        xpMultiplier = 1.45,
        availableModes = { "Patrol", "Ambush", "BaseDefense", "Convoy", "HVTCapture" },
        ribbon       = "EuropeanCampaign",
        nightMode    = true,
        weather      = { "Clear", "Rain", "Fog", "Snow" },
        enemyFaction = "PMC",
    },
    BorderRegion = {
        displayName  = "Operation Iron Border",
        environment  = "Border",
        thumbnail    = "rbxassetid://0",
        minRank      = 5,
        xpMultiplier = 1.5,
        availableModes = { "GateGuard", "Patrol", "Convoy", "Raid", "BaseDefense" },
        ribbon       = "BorderCampaign",
        nightMode    = true,
        weather      = { "Clear", "Rain", "Fog", "Wind" },
        enemyFaction = "Cartel",
    },
}

-- ─── Mission Types ────────────────────────────────────────────────────────────
MissionConfig.Types = {
    Patrol = {
        displayName  = "Patrol",
        description  = "Patrol the AO and eliminate all contacts.",
        objectives   = {
            { type = "Patrol", waypoints = 4, label = "Patrol 4 checkpoints" },
            { type = "KillEnemies", count = 5, label = "Eliminate 5 hostiles" },
        },
        baseXP       = 150,
        baseCash     = 120,
        durationMin  = 8,
    },
    Convoy = {
        displayName  = "Convoy Escort",
        description  = "Escort the supply convoy safely to the destination.",
        objectives   = {
            { type = "EscortVehicle", vehicleId = "ConvoyTruck", label = "Keep convoy alive" },
            { type = "ReachDestination", label = "Convoy reaches base" },
        },
        baseXP       = 200,
        baseCash     = 160,
        durationMin  = 12,
    },
    Raid = {
        displayName  = "Compound Raid",
        description  = "Assault and clear the enemy compound.",
        objectives   = {
            { type = "ReachPosition", label = "Enter compound" },
            { type = "ClearArea", enemyCount = 10, label = "Clear all hostiles" },
            { type = "SecureIntel", label = "Retrieve intel package" },
        },
        baseXP       = 300,
        baseCash     = 250,
        durationMin  = 15,
    },
    HostageRescue = {
        displayName  = "Hostage Rescue",
        description  = "Locate and extract the hostage without casualties.",
        objectives   = {
            { type = "FindHostage", label = "Locate the hostage" },
            { type = "EliminateGuards", count = 6, label = "Eliminate all guards" },
            { type = "ExtractHostage", label = "Extract to LZ" },
        },
        baseXP       = 350,
        baseCash     = 300,
        durationMin  = 20,
    },
    HVTCapture = {
        displayName  = "HVT Capture",
        description  = "Capture or neutralize the high value target.",
        objectives   = {
            { type = "SurveyArea", label = "Surveil target location" },
            { type = "CaptureOrKillHVT", label = "Capture or neutralize HVT" },
            { type = "Extract", label = "Extract to LZ" },
        },
        baseXP       = 400,
        baseCash     = 350,
        durationMin  = 20,
    },
    MedEvac = {
        displayName  = "Medical Evacuation",
        description  = "Extract wounded personnel under fire.",
        objectives   = {
            { type = "ReachCasualtyZone", label = "Reach casualty location" },
            { type = "TreatCasualties", count = 3, label = "Treat 3 casualties" },
            { type = "EvacToBase", label = "Evacuate to base" },
        },
        baseXP       = 250,
        baseCash     = 200,
        durationMin  = 15,
        requireJob   = { "Army.Medic", "Navy.Corpsman", "AirForce.Pararescue", "Civilian.Doctor" },
    },
    GateGuard = {
        displayName  = "Gate Guard",
        description  = "Secure the base entry point.",
        objectives   = {
            { type = "GuardPost", durationSec = 600, label = "Hold post for 10 minutes" },
            { type = "RejectUnauthorized", label = "Deny unauthorized access" },
        },
        baseXP       = 100,
        baseCash     = 80,
        durationMin  = 10,
    },
    BaseDefense = {
        displayName  = "Base Defense",
        description  = "Defend the FOB from enemy assault waves.",
        objectives   = {
            { type = "SurviveWaves", waves = 5, label = "Survive 5 waves" },
            { type = "ProtectObjective", label = "Keep HQ standing" },
        },
        baseXP       = 350,
        baseCash     = 300,
        durationMin  = 20,
    },
    AirAssault = {
        displayName  = "Air Assault",
        description  = "Helicopter insertion onto a hot LZ.",
        objectives   = {
            { type = "InsertViaHelo", label = "Air insert onto LZ" },
            { type = "SecureLZ", label = "Secure the landing zone" },
            { type = "ClearObjective", label = "Clear the objective" },
        },
        baseXP       = 280,
        baseCash     = 240,
        durationMin  = 18,
        requireJob   = { "AirForce.Pilot" },
    },
    Ambush = {
        displayName  = "Ambush",
        description  = "Set up an ambush on enemy patrol routes.",
        objectives   = {
            { type = "SetupAmbushSite", label = "Establish ambush position" },
            { type = "DestroyPatrol", count = 2, label = "Destroy 2 enemy patrols" },
        },
        baseXP       = 220,
        baseCash     = 180,
        durationMin  = 14,
    },
}

-- ─── Daily Mission Pool ───────────────────────────────────────────────────────
MissionConfig.DailyPool = {
    { id = "DM_KILLS_25",   type = "KillCount",    target = 25,  label = "Eliminate 25 enemies",      xp = 200, cash = 150 },
    { id = "DM_ASSIST_10",  type = "AssistCount",  target = 10,  label = "10 teammate assists",        xp = 150, cash = 100 },
    { id = "DM_HEAL_5",     type = "HealCount",    target = 5,   label = "Revive 5 teammates",         xp = 175, cash = 125 },
    { id = "DM_DEPLOY_2",   type = "DeployCount",  target = 2,   label = "Complete 2 deployments",     xp = 300, cash = 250 },
    { id = "DM_DRIVE_1000", type = "DriveStuds",   target = 1000, label = "Drive 1000 studs",          xp = 125, cash = 100 },
    { id = "DM_FLY_500",    type = "FlyStuds",     target = 500, label = "Fly 500 studs",              xp = 175, cash = 125 },
    { id = "DM_PATROL_3",   type = "PatrolCount",  target = 3,   label = "Complete 3 patrol missions", xp = 225, cash = 175 },
    { id = "DM_SCHOOL",     type = "SchoolVisit",  target = 1,   label = "Attend a training course",   xp = 100, cash = 75  },
}

-- Three daily missions are drawn randomly at midnight UTC
MissionConfig.DailyCount = 3

-- ─── Weekly Operation ─────────────────────────────────────────────────────────
MissionConfig.WeeklyOperation = {
    displayName  = "Weekly Campaign",
    description  = "This week's joint campaign operation.",
    missions     = 5,  -- must complete 5 deployments of any type
    xpReward     = 2000,
    cashReward   = 1500,
    badgeReward  = "WeeklyOpsRibbon",
}

return MissionConfig
