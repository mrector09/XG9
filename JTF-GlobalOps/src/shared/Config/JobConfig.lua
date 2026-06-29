-- JobConfig: all playable jobs organized by branch.
-- requirements.rank = minimum rank index (from RankConfig)
-- requirements.badges = badges that must be earned first
-- requirements.schools = school IDs that must be complete

local JobConfig = {}

JobConfig.Branches = {
    "Army", "Marines", "Navy", "AirForce", "SpaceForce", "Civilian", "Hostile"
}

JobConfig.Jobs = {
    -- ─── ARMY ────────────────────────────────────────────────────────────────
    Army = {
        Infantry = {
            displayName = "Infantry",
            description = "Ground combat soldier, backbone of all operations.",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 100,
            equipment = { "M4A1", "M17", "FragGrenade", "SmokePrimary" },
            vehicleAccess = { "Humvee", "LMTV" },
        },
        Medic = {
            displayName = "Combat Medic",
            requirements = { rank = 2, badges = {}, schools = { "MedicalBasic" } },
            basePay = 130,
            equipment = { "M4A1", "M17", "MedKit", "TourniquetKit" },
            vehicleAccess = { "Ambulance", "Humvee" },
        },
        Engineer = {
            displayName = "Combat Engineer",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 120,
            equipment = { "M4A1", "M17", "RepairKit", "C4", "WireKit" },
            vehicleAccess = { "Humvee", "LMTV", "FuelTruck" },
        },
        ArmorCrew = {
            displayName = "Armor Crew",
            requirements = { rank = 3, badges = {}, schools = { "DrivingSchool" } },
            basePay = 140,
            equipment = { "M17", "M4A1" },
            vehicleAccess = { "Tank", "Stryker", "Humvee" },
        },
        MilitaryPolice = {
            displayName = "Military Police",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 125,
            equipment = { "M17", "M4A1", "Handcuffs", "Baton" },
            vehicleAccess = { "PoliceVehicle", "Humvee" },
        },
        DrillSergeant = {
            displayName = "Drill Sergeant",
            requirements = { rank = 6, badges = { "ExpertMarksman" }, schools = {} },
            basePay = 175,
            equipment = { "M4A1", "M17" },
            vehicleAccess = { "Humvee" },
        },
        Ranger = {
            displayName = "Ranger",
            requirements = { rank = 4, badges = { "RangerTab" }, schools = { "AirborneSchool", "RangerSchool" } },
            basePay = 200,
            equipment = { "M4A1", "MK18", "M17", "FragGrenade", "SmokePrimary", "Flashbang" },
            vehicleAccess = { "Humvee", "JLTV", "MRAP" },
            sofUnit = true,
        },
        GreenBeret = {
            displayName = "Green Beret",
            requirements = { rank = 4, badges = { "SpecialForcesTab" }, schools = { "AirborneSchool", "SFSelection" } },
            basePay = 250,
            equipment = { "MK18", "M4A1", "M17", "FragGrenade", "SmokePrimary", "Flashbang" },
            vehicleAccess = { "Humvee", "JLTV", "MRAP", "RHIB" },
            sofUnit = true,
        },
    },

    -- ─── MARINES ─────────────────────────────────────────────────────────────
    Marines = {
        Rifleman = {
            displayName = "Marine Rifleman",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 105,
            equipment = { "M16", "M17", "FragGrenade" },
            vehicleAccess = { "Humvee", "LMTV" },
        },
        Recon = {
            displayName = "Recon Marine",
            requirements = { rank = 3, badges = {}, schools = { "DivingSchool" } },
            basePay = 160,
            equipment = { "M4A1", "M110", "M17" },
            vehicleAccess = { "RHIB", "Humvee" },
        },
        ForceRecon = {
            displayName = "Force Recon",
            requirements = { rank = 4, badges = { "AirborneWings" }, schools = { "AirborneSchool", "SOFSelection" } },
            basePay = 240,
            equipment = { "MK18", "M110", "M17", "Flashbang", "SmokePrimary" },
            vehicleAccess = { "RHIB", "Humvee", "JLTV" },
            sofUnit = true,
        },
        MachineGunner = {
            displayName = "Machine Gunner",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 135,
            equipment = { "M249", "M17" },
            vehicleAccess = { "Humvee", "LMTV" },
        },
    },

    -- ─── NAVY ────────────────────────────────────────────────────────────────
    Navy = {
        Sailor = {
            displayName = "Sailor",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 100,
            equipment = { "M17" },
            vehicleAccess = { "Boat", "RHIB" },
        },
        SEAL = {
            displayName = "Navy SEAL",
            requirements = { rank = 4, badges = { "SEALTrident" }, schools = { "DivingSchool", "AirborneSchool", "SOFSelection" } },
            basePay = 260,
            equipment = { "MK18", "M110", "M17", "FragGrenade", "Flashbang", "SmokePrimary" },
            vehicleAccess = { "RHIB", "Boat", "Humvee", "JLTV" },
            sofUnit = true,
        },
        BoatCrew = {
            displayName = "Boat Crew",
            requirements = { rank = 2, badges = {}, schools = { "BoatSchool" } },
            basePay = 120,
            equipment = { "M4A1", "M17" },
            vehicleAccess = { "Boat", "RHIB" },
        },
        Corpsman = {
            displayName = "Navy Corpsman",
            requirements = { rank = 2, badges = {}, schools = { "MedicalBasic" } },
            basePay = 130,
            equipment = { "M4A1", "M17", "MedKit", "TourniquetKit" },
            vehicleAccess = { "Boat", "Humvee", "Ambulance" },
        },
    },

    -- ─── AIR FORCE ───────────────────────────────────────────────────────────
    AirForce = {
        Pilot = {
            displayName = "Pilot",
            requirements = { rank = 3, badges = { "PilotWings" }, schools = { "FlightSchool" } },
            basePay = 220,
            equipment = { "M17" },
            vehicleAccess = { "Helicopter", "TransportHelicopter", "AttackHelicopter", "FighterJet", "CargoPlane" },
        },
        Pararescue = {
            displayName = "Pararescue (PJ)",
            requirements = { rank = 4, badges = { "AirborneWings", "CombatMedic" }, schools = { "AirborneSchool", "MedicalBasic", "SOFSelection" } },
            basePay = 245,
            equipment = { "MK18", "M17", "MedKit" },
            vehicleAccess = { "Helicopter", "TransportHelicopter" },
            sofUnit = true,
        },
        SecurityForces = {
            displayName = "Security Forces",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 110,
            equipment = { "M4A1", "M17" },
            vehicleAccess = { "PoliceVehicle", "Humvee" },
        },
        DronePilot = {
            displayName = "Drone Pilot",
            requirements = { rank = 2, badges = {}, schools = { "FlightSchool" } },
            basePay = 150,
            equipment = { "M17", "DroneController" },
            vehicleAccess = { "Drone" },
        },
        Loadmaster = {
            displayName = "Loadmaster",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 130,
            equipment = { "M17" },
            vehicleAccess = { "CargoPlane", "TransportHelicopter" },
        },
    },

    -- ─── SPACE FORCE ─────────────────────────────────────────────────────────
    SpaceForce = {
        CyberOperator = {
            displayName = "Cyber Operator",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 160,
            equipment = { "M17", "Laptop" },
            vehicleAccess = {},
        },
        SatelliteOperator = {
            displayName = "Satellite Operator",
            requirements = { rank = 2, badges = {}, schools = {} },
            basePay = 155,
            equipment = { "M17" },
            vehicleAccess = {},
        },
        ElectronicWarfare = {
            displayName = "Electronic Warfare",
            requirements = { rank = 3, badges = {}, schools = {} },
            basePay = 170,
            equipment = { "M17", "EWKit" },
            vehicleAccess = { "JLTV" },
        },
        MissileWarning = {
            displayName = "Missile Warning",
            requirements = { rank = 3, badges = {}, schools = {} },
            basePay = 165,
            equipment = { "M17" },
            vehicleAccess = {},
        },
    },

    -- ─── CIVILIAN ────────────────────────────────────────────────────────────
    Civilian = {
        Mechanic = {
            displayName = "Mechanic",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 90,
            equipment = { "RepairKit", "WrenchTool" },
            vehicleAccess = { "Humvee", "LMTV", "FuelTruck" },
        },
        Doctor = {
            displayName = "Doctor",
            requirements = { rank = 1, badges = {}, schools = { "MedicalBasic" } },
            basePay = 120,
            equipment = { "MedKit", "Defibrillator" },
            vehicleAccess = { "Ambulance" },
        },
        Contractor = {
            displayName = "Contractor",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 110,
            equipment = { "M4A1", "M17" },
            vehicleAccess = { "Humvee", "LMTV" },
        },
        Reporter = {
            displayName = "Reporter",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 80,
            equipment = { "Camera" },
            vehicleAccess = { "Humvee" },
        },
        Firefighter = {
            displayName = "Firefighter",
            requirements = { rank = 1, badges = {}, schools = {} },
            basePay = 95,
            equipment = { "FireHose", "ExtinguisherKit" },
            vehicleAccess = { "FireTruck" },
        },
    },

    -- ─── HOSTILE ─────────────────────────────────────────────────────────────
    Hostile = {
        Raider     = { displayName = "Raider",     requirements = { rank = 1 }, basePay = 80,  equipment = { "M4A1", "FragGrenade" }, vehicleAccess = {} },
        Militia    = { displayName = "Militia",     requirements = { rank = 1 }, basePay = 75,  equipment = { "M16", "FragGrenade" },  vehicleAccess = { "Humvee" } },
        Insurgent  = { displayName = "Insurgent",   requirements = { rank = 1 }, basePay = 80,  equipment = { "M4A1", "Shotgun" },     vehicleAccess = {} },
        Cartel     = { displayName = "Cartel",      requirements = { rank = 2 }, basePay = 100, equipment = { "M4A1", "Shotgun", "M17" }, vehicleAccess = { "Humvee" } },
        Pirate     = { displayName = "Pirate",      requirements = { rank = 1 }, basePay = 85,  equipment = { "M4A1", "M17" },         vehicleAccess = { "Boat", "RHIB" } },
        PMC        = { displayName = "PMC Operator", requirements = { rank = 3 }, basePay = 150, equipment = { "MK18", "M17", "Flashbang", "SmokePrimary" }, vehicleAccess = { "Humvee", "JLTV" } },
    },
}

return JobConfig
