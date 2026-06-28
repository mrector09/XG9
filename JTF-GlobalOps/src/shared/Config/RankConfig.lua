-- RankConfig: defines every rank, XP thresholds, pay multipliers, and permissions.
-- Index 1 = lowest rank. Add to the end to extend.

local RankConfig = {}

RankConfig.Ranks = {
    -- { name, xpRequired, payMultiplier, canLeadSquad, canTeachCourse, canAccessSOF }
    [1]  = { name = "Recruit",            xp = 0,       pay = 1.0,  lead = false, teach = false, sof = false },
    [2]  = { name = "Private",            xp = 500,     pay = 1.1,  lead = false, teach = false, sof = false },
    [3]  = { name = "Specialist",         xp = 1500,    pay = 1.2,  lead = false, teach = false, sof = false },
    [4]  = { name = "Sergeant",           xp = 3500,    pay = 1.4,  lead = true,  teach = false, sof = true  },
    [5]  = { name = "Staff Sergeant",     xp = 7000,    pay = 1.6,  lead = true,  teach = false, sof = true  },
    [6]  = { name = "Sergeant First Class", xp = 13000, pay = 1.8,  lead = true,  teach = true,  sof = true  },
    [7]  = { name = "Lieutenant",         xp = 22000,   pay = 2.0,  lead = true,  teach = true,  sof = true  },
    [8]  = { name = "Captain",            xp = 35000,   pay = 2.3,  lead = true,  teach = true,  sof = true  },
    [9]  = { name = "Major",              xp = 55000,   pay = 2.7,  lead = true,  teach = true,  sof = true  },
    [10] = { name = "Colonel",            xp = 85000,   pay = 3.2,  lead = true,  teach = true,  sof = true  },
    [11] = { name = "General",            xp = 130000,  pay = 4.0,  lead = true,  teach = true,  sof = true  },
}

-- Special Operations minimum rank index required
RankConfig.SOFMinRank = 4  -- Sergeant

-- Prestige resets XP to 0, multiplies all future XP gains
RankConfig.PrestigeMultiplier = 1.15

-- XP sources and their base awards
RankConfig.XPSources = {
    Kill            = 25,
    Assist          = 10,
    Objective       = 100,
    MissionComplete = 250,
    DeploymentEnd   = 150,
    BadgeEarned     = 200,
    SchoolComplete  = 300,
    DailyMission    = 75,
    WeeklyOperation = 500,
    DailyLogin      = 50,
    PatrolTick      = 5,
    ReviveTeammate  = 30,
    VehicleKill     = 40,
}

return RankConfig
