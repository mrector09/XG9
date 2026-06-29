-- GamepassService: checks gamepass ownership, grants perks, handles DevProduct purchases.

local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Remotes            = require(script.Parent.Parent.Parent.shared.Remotes)
local DataService        = require(script.Parent.DataService)
local GamepassConfig     = require(script.Parent.Parent.Parent.shared.Config.GamepassConfig)

local GamepassService = {}

local EconomyService -- injected
local XPService      -- injected

function GamepassService.SetDependencies(es, xs)
    EconomyService = es
    XPService      = xs
end

-- ─── Gamepass checks ──────────────────────────────────────────────────────────
function GamepassService.HasGamepass(player, passName)
    -- First check local cache (faster)
    local data = DataService.GetData(player)
    if data and data.OwnedGamepasses and data.OwnedGamepasses[passName] then
        return true
    end

    -- Check with Roblox (source of truth)
    local config = GamepassConfig.Gamepasses[passName]
    if not config then return false end

    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, config.id)
    end)

    if ok and owns then
        -- Cache it
        DataService.UpdateData(player, function(d)
            d.OwnedGamepasses = d.OwnedGamepasses or {}
            d.OwnedGamepasses[passName] = true
        end)
        return true
    end

    return false
end

function GamepassService.GetAllPerks(player)
    local perks = {}
    for passName, config in pairs(GamepassConfig.Gamepasses) do
        if GamepassService.HasGamepass(player, passName) then
            for key, val in pairs(config.perks) do
                -- Numeric perks accumulate
                if type(val) == "number" then
                    perks[key] = (perks[key] or 1) * val
                else
                    perks[key] = val
                end
            end
        end
    end
    return perks
end

-- Apply all gamepass effects to a freshly joined player
function GamepassService.ApplyEffects(player)
    local perks = GamepassService.GetAllPerks(player)

    -- XP multiplier temp store (picked up by XPService)
    if perks.xpMultiplier and perks.xpMultiplier > 1 then
        DataService.UpdateData(player, function(d)
            d.OwnedGamepasses = d.OwnedGamepasses or {}
            d.OwnedGamepasses["XPBoost"] = perks.xpMultiplier > 1
        end)
    end

    -- Daily bonus cash
    if perks.dailyBonusCash and EconomyService then
        EconomyService.AddCash(player, perks.dailyBonusCash, "VIPDailyBonus")
    end

    Remotes.FireClient("GamepassPerksApplied", player, { perks = perks })
end

-- ─── Developer Product purchase handler ───────────────────────────────────────
-- Register this as MarketplaceService.ProcessReceipt
local function processReceipt(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

    local productId = receiptInfo.ProductId

    for productName, config in pairs(GamepassConfig.DevProducts) do
        if config.id == productId then
            -- Handle product
            if config.cashAmount and EconomyService then
                EconomyService.AddCash(player, config.cashAmount, "Purchase_" .. productName)
            end

            if config.tierSkips then
                local BPService = require(script.Parent.BattlePassService)
                for _ = 1, config.tierSkips do
                    BPService.AdvanceTier(player)
                end
            end

            if config.xpMultiplier and XPService then
                XPService.ApplyTempBooster(player, config.xpMultiplier, config.durationMin or 60)
            end

            if config.crateType then
                -- TODO: implement crate opening logic
                Remotes.FireClient("NotificationSent", player, {
                    title = "Crate Opened",
                    body  = "Your " .. config.crateType .. " crate rewards are in your inventory.",
                    icon  = "Crate",
                })
            end

            Remotes.FireClient("PurchaseComplete", player, { productId = productId })
            return Enum.ProductPurchaseDecision.PurchaseGranted
        end
    end

    warn("[GamepassService] Unknown product ID:", productId)
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ─── Init ─────────────────────────────────────────────────────────────────────
function GamepassService.Init()
    MarketplaceService.ProcessReceipt = processReceipt

    -- Apply effects for every player that joins
    Players.PlayerAdded:Connect(function(player)
        task.delay(2, function()  -- wait for data to load
            GamepassService.ApplyEffects(player)
        end)
    end)

    print("[GamepassService] Initialized.")
end

return GamepassService
