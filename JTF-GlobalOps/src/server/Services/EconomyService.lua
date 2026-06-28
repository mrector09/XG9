-- EconomyService: manages in-game cash (earn, spend, balance queries).
-- All cash mutations go through here so we have a single audit point.

local Players     = game:GetService("Players")
local Remotes     = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

local MAX_BALANCE = 10_000_000  -- sanity cap

local function syncLeaderstat(player, newBalance)
    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Cash") then
        ls.Cash.Value = newBalance
    end
    Remotes.FireClient("CashUpdated", player, {
        newBalance = newBalance,
        delta      = 0,  -- caller will fill this if needed
    })
end

-- ─── Public API ───────────────────────────────────────────────────────────────
function EconomyService.GetBalance(player)
    local data = DataService.GetData(player)
    return data and data.Cash or 0
end

function EconomyService.AddCash(player, amount, reason)
    if amount <= 0 then return end
    local data = DataService.GetData(player)
    if not data then return end

    DataService.UpdateData(player, function(d)
        d.Cash = math.min(d.Cash + amount, MAX_BALANCE)
    end)

    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Cash") then
        ls.Cash.Value = data.Cash
    end

    Remotes.FireClient("CashUpdated", player, {
        newBalance = data.Cash,
        delta      = amount,
        reason     = reason or "Reward",
    })
end

-- Returns true if successful, false + reason if insufficient funds
function EconomyService.RemoveCash(player, amount, reason)
    if amount <= 0 then return true end
    local data = DataService.GetData(player)
    if not data then return false, "No data" end

    if data.Cash < amount then
        return false, ("Insufficient funds (have %d, need %d)"):format(data.Cash, amount)
    end

    DataService.UpdateData(player, function(d)
        d.Cash = d.Cash - amount
    end)

    local ls = player:FindFirstChild("leaderstats")
    if ls and ls:FindFirstChild("Cash") then
        ls.Cash.Value = data.Cash
    end

    Remotes.FireClient("CashUpdated", player, {
        newBalance = data.Cash,
        delta      = -amount,
        reason     = reason or "Purchase",
    })

    return true
end

function EconomyService.SetCash(player, amount)
    local clamped = math.clamp(amount, 0, MAX_BALANCE)
    DataService.UpdateData(player, function(d)
        d.Cash = clamped
    end)
    local data = DataService.GetData(player)
    syncLeaderstat(player, data and data.Cash or 0)
end

-- Award deployment pay based on job pay rate * rank multiplier
function EconomyService.AwardDeploymentPay(player, basePay, rankMultiplier)
    local total = math.floor(basePay * (rankMultiplier or 1))
    EconomyService.AddCash(player, total, "DeploymentPay")
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function EconomyService.Init()
    print("[EconomyService] Initialized.")
end

return EconomyService
