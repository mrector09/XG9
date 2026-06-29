-- AdminConfig: define owner and admin user IDs.
-- Get your UserId from: roblox.com/users/profile (the number in the URL)

local AdminConfig = {}

-- Game owner — has access to everything in the owner panel
AdminConfig.OwnerId = 23284440

-- Admin tier list: "Owner" > "HeadAdmin" > "Admin" > "Moderator"
AdminConfig.Admins = {
    -- [UserId] = "tier"
    -- [123456789] = "HeadAdmin",
    -- [987654321] = "Moderator",
}

-- Permissions per tier
AdminConfig.Permissions = {
    Owner = {
        kick = true, ban = true, unban = true,
        promote = true, demote = true, setRank = true,
        giveCash = true, giveXP = true,
        spawnNPC = true, triggerEvent = true,
        announce = true, setWeather = true, setTime = true,
        teleport = true, viewLogs = true, serverStats = true,
    },
    HeadAdmin = {
        kick = true, ban = true, unban = true,
        promote = true, demote = true, setRank = false,
        giveCash = true, giveXP = true,
        spawnNPC = true, triggerEvent = true,
        announce = true, setWeather = true, setTime = true,
        teleport = true, viewLogs = true, serverStats = true,
    },
    Admin = {
        kick = true, ban = false, unban = false,
        promote = true, demote = false, setRank = false,
        giveCash = false, giveXP = true,
        spawnNPC = false, triggerEvent = false,
        announce = true, setWeather = false, setTime = false,
        teleport = true, viewLogs = false, serverStats = true,
    },
    Moderator = {
        kick = true, ban = false, unban = false,
        promote = false, demote = false, setRank = false,
        giveCash = false, giveXP = false,
        spawnNPC = false, triggerEvent = false,
        announce = false, setWeather = false, setTime = false,
        teleport = false, viewLogs = false, serverStats = true,
    },
}

function AdminConfig.GetTier(userId)
    if userId == AdminConfig.OwnerId then return "Owner" end
    return AdminConfig.Admins[userId]
end

function AdminConfig.HasPermission(userId, perm)
    local tier = AdminConfig.GetTier(userId)
    if not tier then return false end
    local perms = AdminConfig.Permissions[tier]
    return perms and perms[perm] == true
end

function AdminConfig.IsAdmin(userId)
    return AdminConfig.GetTier(userId) ~= nil
end

return AdminConfig
