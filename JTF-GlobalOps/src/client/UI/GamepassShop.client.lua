-- GamepassShop.client.lua — gamepass and dev product store.

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local shared  = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme   = require(shared:WaitForChild("Theme"))
local Remotes = require(shared:WaitForChild("Remotes"))
local GpCfg   = require(shared:WaitForChild("Config"):WaitForChild("GamepassConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Theme.Screen("GamepassShop", 8)
sg.Enabled = false
sg.Parent  = PlayerGui

local root = Theme.Frame(sg, "Root",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Theme.Colors.BG)

-- Header
local header = Theme.Frame(root, "Header",
    UDim2.new(1,0,0,52), nil, Theme.Colors.Surface)
Theme.Frame(header, "Gold",
    UDim2.new(1,0,0,2), UDim2.new(0,0,1,-2), Theme.Colors.Primary)
Theme.Label(header, "Title", "SHOP",
    UDim2.new(1,-120,1,0), UDim2.new(0,24,0,0),
    Theme.Colors.Primary, 16, Theme.Fonts.Bold)

local closeBtn = Theme.Button(header, "Close", "✕ Back",
    UDim2.new(0,88,0,32), UDim2.new(1,-100,0.5,-16), "ghost")
closeBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
    local mm = PlayerGui:FindFirstChild("MainMenu")
    if mm then mm.Enabled = true end
end)

-- ─── Tab bar ─────────────────────────────────────────────────────────────────
local tabBar = Theme.Frame(root, "TabBar",
    UDim2.new(1,0,0,42), UDim2.new(0,0,0,52), Theme.Colors.Surface2)
Theme.Padding(tabBar, nil, 6, 16, 6, 16)
Theme.ListLayout(tabBar, Enum.FillDirection.Horizontal, 8)

-- ─── Content ──────────────────────────────────────────────────────────────────
local content = Theme.Frame(root, "Content",
    UDim2.new(1,-48,1,-112), UDim2.new(0,24,0,102),
    Color3.new(0,0,0), 1)

local shopScroll = Theme.Scroll(content, "Scroll", UDim2.new(1,0,1,0), nil)

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize             = UDim2.new(0, 220, 0, 148)
gridLayout.CellPadding          = UDim2.new(0, 14, 0, 14)
gridLayout.SortOrder            = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Left
gridLayout.Parent               = shopScroll

-- ─── State ────────────────────────────────────────────────────────────────────
local activeTab   = "Gamepasses"
local tabBtnRefs  = {}
local ownedPasses = {}

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local CAT_ICON = {
    Gamepasses  = "⬡",
    CashPacks   = "💰",
    Consumables = "⚡",
}

local function clearGrid()
    for _, c in ipairs(shopScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function buildPassCard(passId, cfg, order)
    local isOwned = ownedPasses[passId]

    local card = Theme.Frame(shopScroll, passId .. "Card",
        UDim2.new(0,0,0,0), nil, Theme.Colors.Surface)
    card.LayoutOrder = order
    Theme.Corner(card, Theme.Radius.Md)
    Theme.Stroke(card, isOwned and Theme.Colors.Success or Theme.Colors.Border)
    Theme.Padding(card, 14)

    -- Icon circle
    local circle = Theme.Frame(card, "Icon",
        UDim2.new(0,38,0,38), UDim2.new(0,0,0,0),
        isOwned and Theme.Colors.Success or Theme.Colors.Primary)
    Theme.Corner(circle, Theme.Radius.Full)
    Theme.Label(circle, "I", isOwned and "✓" or "◆",
        UDim2.new(1,0,1,0), nil,
        Theme.Colors.PrimaryText, 18, Theme.Fonts.Bold,
        Enum.TextXAlignment.Center)

    Theme.Label(card, "Name", cfg.displayName,
        UDim2.new(1,-52,0,22), UDim2.new(0,48,0,0),
        Theme.Colors.Text, 13, Theme.Fonts.Bold)

    if isOwned then
        Theme.Label(card, "OwnedBadge", "OWNED",
            UDim2.new(0,52,0,16), UDim2.new(0,48,0,22),
            Theme.Colors.Success, 9, Theme.Fonts.Bold)
    end

    Theme.Label(card, "Desc", cfg.description,
        UDim2.new(1,0,0,40), UDim2.new(0,0,0,46),
        Theme.Colors.TextMuted, 9, Theme.Fonts.Regular)

    if isOwned then
        Theme.Label(card, "Footer", "Already purchased",
            UDim2.new(1,0,0,20), UDim2.new(0,0,1,-22),
            Theme.Colors.TextSubtle, 9, Theme.Fonts.Regular,
            Enum.TextXAlignment.Center)
    else
        local buyBtn = Theme.Button(card, "Buy", "BUY WITH ROBUX",
            UDim2.new(1,0,0,26), UDim2.new(0,0,1,-26), "primary")
        buyBtn.TextSize = 11
        local id = cfg.id
        buyBtn.MouseButton1Click:Connect(function()
            MarketplaceService:PromptGamePassPurchase(LocalPlayer, id)
        end)
    end
end

local function buildProductCard(productKey, cfg, order)
    local card = Theme.Frame(shopScroll, productKey .. "Card",
        UDim2.new(0,0,0,0), nil, Theme.Colors.Surface)
    card.LayoutOrder = order
    Theme.Corner(card, Theme.Radius.Md)
    Theme.Stroke(card, Theme.Colors.Border)
    Theme.Padding(card, 14)

    local accentColor = cfg.cashAmount and Theme.Colors.Success or Theme.Colors.Info
    local circle = Theme.Frame(card, "Icon",
        UDim2.new(0,38,0,38), UDim2.new(0,0,0,0), accentColor)
    Theme.Corner(circle, Theme.Radius.Full)
    Theme.Label(circle, "I", cfg.cashAmount and "💰" or "⚡",
        UDim2.new(1,0,1,0), nil,
        Color3.new(1,1,1), 18, Theme.Fonts.Regular,
        Enum.TextXAlignment.Center)

    Theme.Label(card, "Name", cfg.displayName,
        UDim2.new(1,-52,0,22), UDim2.new(0,48,0,0),
        Theme.Colors.Text, 13, Theme.Fonts.Bold)

    if cfg.cashAmount then
        Theme.Label(card, "Amount", "$" .. cfg.cashAmount .. " cash",
            UDim2.new(1,-52,0,16), UDim2.new(0,48,0,22),
            Theme.Colors.Success, 10, Theme.Fonts.Bold)
    end

    Theme.Label(card, "Desc", cfg.description,
        UDim2.new(1,0,0,36), UDim2.new(0,0,0,46),
        Theme.Colors.TextMuted, 9, Theme.Fonts.Regular)

    local buyBtn = Theme.Button(card, "Buy", "BUY WITH ROBUX",
        UDim2.new(1,0,0,26), UDim2.new(0,0,1,-26),
        cfg.cashAmount and "success" or "ghost")
    buyBtn.TextSize = 11
    local id = cfg.id
    buyBtn.MouseButton1Click:Connect(function()
        MarketplaceService:PromptProductPurchase(LocalPlayer, id)
    end)
end

-- ─── Tab rendering ────────────────────────────────────────────────────────────
local function showTab(tabId)
    activeTab = tabId

    for id, btn in pairs(tabBtnRefs) do
        btn.BackgroundColor3       = id == tabId and Theme.Colors.Surface3 or Color3.new(0,0,0)
        btn.BackgroundTransparency = id == tabId and 0 or 1
        btn.TextColor3             = id == tabId and Theme.Colors.Primary or Theme.Colors.TextMuted
    end

    clearGrid()
    local order = 1

    if tabId == "Gamepasses" then
        for passId, cfg in pairs(GpCfg.Gamepasses) do
            buildPassCard(passId, cfg, order)
            order = order + 1
        end

    elseif tabId == "CashPacks" then
        for key, cfg in pairs(GpCfg.DevProducts) do
            if cfg.cashAmount then
                buildProductCard(key, cfg, order)
                order = order + 1
            end
        end

    elseif tabId == "Consumables" then
        for key, cfg in pairs(GpCfg.DevProducts) do
            if not cfg.cashAmount then
                buildProductCard(key, cfg, order)
                order = order + 1
            end
        end
    end

    if order == 1 then
        Theme.Label(shopScroll, "Empty", "Nothing here yet.",
            UDim2.new(1,0,0,40), nil, Theme.Colors.TextMuted, 14)
    end
end

-- ─── Build tab buttons ────────────────────────────────────────────────────────
local TABS = {
    { id = "Gamepasses",  label = "GAMEPASSES",  order = 1 },
    { id = "CashPacks",   label = "CASH PACKS",  order = 2 },
    { id = "Consumables", label = "CONSUMABLES", order = 3 },
}

for _, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Name                  = tab.id
    btn.Size                  = UDim2.new(0, 140, 1, 0)
    btn.BackgroundColor3      = Color3.new(0,0,0)
    btn.BackgroundTransparency = 1
    btn.Text                  = tab.label
    btn.TextColor3            = Theme.Colors.TextMuted
    btn.Font                  = Theme.Fonts.Bold
    btn.TextSize              = 11
    btn.BorderSizePixel       = 0
    btn.LayoutOrder           = tab.order
    btn.Parent                = tabBar
    Theme.Corner(btn, Theme.Radius.Sm)

    local captured = tab.id
    btn.MouseButton1Click:Connect(function()
        showTab(captured)
    end)

    tabBtnRefs[tab.id] = btn
end

-- ─── Open hook ────────────────────────────────────────────────────────────────
local OpenShop = Instance.new("BindableFunction")
OpenShop.Name   = "Open_GamepassShop"
OpenShop.Parent = PlayerGui
OpenShop.OnInvoke = function()
    task.spawn(function()
        local data = Remotes.InvokeServer("GetPlayerData")
        ownedPasses = (data and data.OwnedGamepasses) or {}
        showTab(activeTab)
    end)
    sg.Enabled = true
end

print("[JTF] GamepassShop: ready")
