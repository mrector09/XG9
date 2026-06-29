-- GamepassConfig: all gamepasses and developer products.
-- Replace ID values with your actual Roblox asset IDs before publishing.

local GamepassConfig = {}

-- ─── Gamepasses ───────────────────────────────────────────────────────────────
-- Purchased once. Checked via MarketplaceService:UserOwnsGamePassAsync()
GamepassConfig.Gamepasses = {
    VIP = {
        id          = 000000001,  -- REPLACE with real ID
        displayName = "VIP",
        description = "Custom VIP nameplate, private quarters, and exclusive VIP lounge access.",
        perks = {
            vipNameplate    = true,
            privateQuarters = true,
            vipLounge       = true,
            dailyBonusCash  = 100,
        },
    },
    ExtraLoadout = {
        id          = 000000002,
        displayName = "Extra Loadout Slots",
        description = "Adds 3 additional saved loadout slots.",
        perks = {
            extraLoadoutSlots = 3,
        },
    },
    ExtraUniform = {
        id          = 000000003,
        displayName = "Extra Uniform Slots",
        description = "Adds 3 additional saved uniform slots.",
        perks = {
            extraUniformSlots = 3,
        },
    },
    PremiumCamo = {
        id          = 000000004,
        displayName = "Premium Camo Pack",
        description = "Unlocks 10 exclusive weapon and uniform camo patterns.",
        perks = {
            premiumCamos = true,
        },
    },
    CustomNameplate = {
        id          = 000000005,
        displayName = "Custom Nameplate",
        description = "Set a custom callsign displayed above your character.",
        perks = {
            customNameplate = true,
        },
    },
    PremiumRadioTag = {
        id          = 000000006,
        displayName = "Premium Radio Tag",
        description = "Unique radio callsign sound and visual effect.",
        perks = {
            premiumRadioTag = true,
        },
    },
    PrivateQuarters = {
        id          = 000000007,
        displayName = "Private Quarters",
        description = "Access to a private spawn room with personal locker.",
        perks = {
            privateQuarters = true,
        },
    },
    VehiclePaintPack = {
        id          = 000000008,
        displayName = "Vehicle Paint Pack",
        description = "Unlocks 8 unique paint schemes for all vehicles.",
        perks = {
            vehiclePaintPack = true,
        },
    },
    WeaponSkinPack = {
        id          = 000000009,
        displayName = "Weapon Skin Pack",
        description = "Unlocks 12 premium weapon skins.",
        perks = {
            weaponSkinPack = true,
        },
    },
    AdvancedEmotes = {
        id          = 000000010,
        displayName = "Advanced Emotes",
        description = "15 military-themed emotes and animations.",
        perks = {
            advancedEmotes = true,
        },
    },
    OfficerCosmetics = {
        id          = 000000011,
        displayName = "Officer Cosmetics",
        description = "Exclusive officer uniform pieces, medals, and decorations.",
        perks = {
            officerCosmetics = true,
        },
    },
    PilotCosmetics = {
        id          = 000000012,
        displayName = "Pilot Cosmetics",
        description = "Exclusive flight suits, helmets, and patches.",
        perks = {
            pilotCosmetics = true,
        },
    },
    SOFCosmetics = {
        id          = 000000013,
        displayName = "Special Operations Cosmetics",
        description = "Exclusive SOF gear — skins only, access still must be earned.",
        perks = {
            sofCosmetics = true,
        },
    },
    ExtraDailyRewards = {
        id          = 000000014,
        displayName = "Extra Daily Rewards",
        description = "Double the daily login reward and an extra daily mission slot.",
        perks = {
            doubleDailyReward  = true,
            extraDailyMission  = true,
        },
    },
    XPBoost = {
        id          = 000000015,
        displayName = "XP Boost (10%)",
        description = "Permanently earn 10% more XP from all sources. Not pay-to-win.",
        perks = {
            xpMultiplier = 1.10,
        },
    },
}

-- ─── Developer Products ───────────────────────────────────────────────────────
-- Purchased multiple times. Handled via ProcessReceipt callback.
GamepassConfig.DevProducts = {
    CashPack_Small = {
        id          = 100000001,  -- REPLACE with real ID
        displayName = "Cash Pack — Small",
        description = "Adds 1,000 in-game cash.",
        cashAmount  = 1000,
    },
    CashPack_Medium = {
        id          = 100000002,
        displayName = "Cash Pack — Medium",
        description = "Adds 5,000 in-game cash.",
        cashAmount  = 5000,
    },
    CashPack_Large = {
        id          = 100000003,
        displayName = "Cash Pack — Large",
        description = "Adds 15,000 in-game cash.",
        cashAmount  = 15000,
    },
    CosmeticCrate = {
        id          = 100000004,
        displayName = "Cosmetic Crate",
        description = "Opens one mystery cosmetic crate.",
        crateType   = "Cosmetic",
    },
    BattlePassTierSkip = {
        id          = 100000005,
        displayName = "Battle Pass Tier Skip",
        description = "Instantly advances one Battle Pass tier.",
        tierSkips   = 1,
    },
    TempXPBooster = {
        id          = 100000006,
        displayName = "XP Booster (1 hour)",
        description = "Doubles XP earned for 1 hour.",
        xpMultiplier = 2.0,
        durationMin = 60,
    },
    DeploymentSupplyCrate = {
        id          = 100000007,
        displayName = "Deployment Supply Crate",
        description = "Grants a supply crate with ammo, equipment, and a random skin.",
        crateType   = "Deployment",
    },
}

return GamepassConfig
