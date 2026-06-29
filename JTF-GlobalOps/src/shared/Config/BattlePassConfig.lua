-- BattlePassConfig: seasonal battle pass tiers and rewards.
-- Season resets every 8 weeks. BPXPPerTier controls how much XP a tier needs.

local BattlePassConfig = {}

BattlePassConfig.SeasonName    = "Season 1 — Desert Storm"
BattlePassConfig.SeasonEnd     = "2026-09-01"  -- ISO date string for countdown display
BattlePassConfig.MaxTier       = 50
BattlePassConfig.BPXPPerTier   = 500           -- XP needed to advance one tier

-- Sources that grant Battle Pass XP
BattlePassConfig.BPXPSources = {
    MissionComplete = 100,
    DailyMission    = 50,
    WeeklyOp        = 300,
    Kill            = 5,
    Deployment      = 75,
    SchoolComplete  = 150,
    Login           = 25,
}

-- Rewards per tier. "type" can be:
-- "Cash", "Cosmetic", "WeaponSkin", "VehicleSkin", "Badge", "Emote", "Title", "XP"
BattlePassConfig.Tiers = {
    [1]  = { free = { type = "Cash",       amount = 200  },  premium = { type = "Cosmetic",   id = "DesertBeret"        } },
    [2]  = { free = { type = "XP",         amount = 100  },  premium = { type = "WeaponSkin",  id = "DesertSand_M4A1"   } },
    [3]  = { free = { type = "Cash",       amount = 200  },  premium = { type = "Emote",       id = "TacticalSalute"    } },
    [4]  = { free = { type = "XP",         amount = 150  },  premium = { type = "VehicleSkin", id = "DesertCamo_Humvee" } },
    [5]  = { free = { type = "Cash",       amount = 300  },  premium = { type = "Cosmetic",    id = "DesertGlasses"     } },
    [6]  = { free = { type = "XP",         amount = 200  },  premium = { type = "WeaponSkin",  id = "DesertSand_M17"   } },
    [7]  = { free = { type = "Cash",       amount = 300  },  premium = { type = "Title",       id = "DesertVeteran"     } },
    [8]  = { free = { type = "XP",         amount = 250  },  premium = { type = "Cosmetic",    id = "DesertKeffiyeh"    } },
    [9]  = { free = { type = "Cash",       amount = 400  },  premium = { type = "WeaponSkin",  id = "DesertSand_MK18"  } },
    [10] = { free = { type = "Badge",      id = "S1T10"  },  premium = { type = "Cosmetic",    id = "DesertPatchSet"    } },
    [11] = { free = { type = "Cash",       amount = 400  },  premium = { type = "VehicleSkin", id = "DesertCamo_JLTV"  } },
    [12] = { free = { type = "XP",         amount = 300  },  premium = { type = "Emote",       id = "HighFive"         } },
    [13] = { free = { type = "Cash",       amount = 500  },  premium = { type = "WeaponSkin",  id = "Brushstroke_M110" } },
    [14] = { free = { type = "XP",         amount = 350  },  premium = { type = "Cosmetic",    id = "PilotFlightSuit"  } },
    [15] = { free = { type = "Cash",       amount = 500  },  premium = { type = "VehicleSkin", id = "DesertCamo_Helo"  } },
    [16] = { free = { type = "XP",         amount = 400  },  premium = { type = "WeaponSkin",  id = "DesertSand_M249"  } },
    [17] = { free = { type = "Cash",       amount = 600  },  premium = { type = "Cosmetic",    id = "TacticalVest_V2"  } },
    [18] = { free = { type = "XP",         amount = 450  },  premium = { type = "Title",       id = "SandRunner"       } },
    [19] = { free = { type = "Cash",       amount = 600  },  premium = { type = "Emote",       id = "ReconCrouch"      } },
    [20] = { free = { type = "Badge",      id = "S1T20"  },  premium = { type = "Cosmetic",    id = "S1_ArmorSet"      } },
    [25] = { free = { type = "Cash",       amount = 800  },  premium = { type = "WeaponSkin",  id = "Gold_M4A1"        } },
    [30] = { free = { type = "Cash",       amount = 1000 },  premium = { type = "VehicleSkin", id = "Gold_Humvee"      } },
    [35] = { free = { type = "Cash",       amount = 1200 },  premium = { type = "Title",       id = "OperationVet"     } },
    [40] = { free = { type = "Badge",      id = "S1T40"  },  premium = { type = "Cosmetic",    id = "S1_EliteArmor"   } },
    [45] = { free = { type = "Cash",       amount = 1500 },  premium = { type = "WeaponSkin",  id = "Diamond_MK18"    } },
    [50] = { free = { type = "Badge",      id = "S1T50"  },  premium = { type = "Cosmetic",    id = "S1_MythicHelmet" } },
}

-- Price of the battle pass in Robux (display only — purchase handled via DevProduct)
BattlePassConfig.PriceRobux = 400

return BattlePassConfig
