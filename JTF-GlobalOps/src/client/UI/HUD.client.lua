-- HUD.client.lua
-- Builds the in-game HUD entirely in code — no Studio layout required.
-- Creates: XP bar, rank label, cash, ammo, health, crosshair, compass,
--          objective tracker, minimap frame, kill feed.

local Players     = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService  = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer.PlayerGui

-- ─── Build root ScreenGui ────────────────────────────────────────────────────
local HUD = Instance.new("ScreenGui")
HUD.Name            = "HUD"
HUD.ResetOnSpawn    = false
HUD.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
HUD.IgnoreGuiInset  = true
HUD.Parent          = PlayerGui

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function makeFrame(parent, name, size, pos, color, transparency)
    local f = Instance.new("Frame")
    f.Name                  = name
    f.Size                  = size
    f.Position              = pos
    f.BackgroundColor3      = color or Color3.new(0, 0, 0)
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel       = 0
    f.Parent                = parent
    return f
end

local function makeLabel(parent, name, text, size, pos, textColor, fontSize)
    local l = Instance.new("TextLabel")
    l.Name                  = name
    l.Size                  = size
    l.Position              = pos
    l.Text                  = text
    l.TextColor3            = textColor or Color3.new(1, 1, 1)
    l.TextSize              = fontSize or 14
    l.Font                  = Enum.Font.GothamBold
    l.BackgroundTransparency = 1
    l.TextStrokeTransparency = 0.6
    l.TextStrokeColor3      = Color3.new(0, 0, 0)
    l.Parent                = parent
    return l
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

-- ─── Health bar (bottom left) ────────────────────────────────────────────────
local healthBG = makeFrame(HUD, "HealthBG",
    UDim2.new(0, 220, 0, 18),
    UDim2.new(0, 20, 1, -80),
    Color3.fromRGB(20, 20, 20), 0.3)
corner(healthBG, 4)

local healthBar = makeFrame(healthBG, "HealthBar",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(60, 200, 60), 0)
corner(healthBar, 4)

makeLabel(healthBG, "HealthLabel", "100 HP",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(1, 1, 1), 12)

-- ─── Armor bar ───────────────────────────────────────────────────────────────
local armorBG = makeFrame(HUD, "ArmorBG",
    UDim2.new(0, 220, 0, 10),
    UDim2.new(0, 20, 1, -60),
    Color3.fromRGB(20, 20, 20), 0.3)
corner(armorBG, 3)

makeFrame(armorBG, "ArmorBar",
    UDim2.new(0.75, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(80, 140, 220), 0)

-- ─── Ammo counter (bottom right) ─────────────────────────────────────────────
local ammoBG = makeFrame(HUD, "AmmoBG",
    UDim2.new(0, 140, 0, 50),
    UDim2.new(1, -160, 1, -100),
    Color3.new(0,0,0), 0.5)
corner(ammoBG, 6)

makeLabel(ammoBG, "AmmoLabel", "30 / 120",
    UDim2.new(1, 0, 0.6, 0), UDim2.new(0, 0, 0, 4),
    Color3.new(1, 1, 1), 24)

makeLabel(ammoBG, "WeaponLabel", "M4A1",
    UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.6, 0),
    Color3.fromRGB(200, 200, 200), 13)

-- ─── XP bar (top) ────────────────────────────────────────────────────────────
local xpBG = makeFrame(HUD, "XPBarBG",
    UDim2.new(0.35, 0, 0, 14),
    UDim2.new(0.325, 0, 0, 4),
    Color3.fromRGB(20, 20, 20), 0.35)
corner(xpBG, 4)

local xpFill = makeFrame(xpBG, "XPBar",
    UDim2.new(0, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(255, 180, 0), 0)
corner(xpFill, 4)

makeLabel(xpBG, "XPLabel", "0 / 500 XP",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(1, 1, 1), 10)

-- ─── Rank + cash panel (top left) ────────────────────────────────────────────
local infoPanelBG = makeFrame(HUD, "InfoPanel",
    UDim2.new(0, 190, 0, 50),
    UDim2.new(0, 10, 0, 22),
    Color3.new(0, 0, 0), 0.5)
corner(infoPanelBG, 6)

makeLabel(infoPanelBG, "RankLabel", "Recruit",
    UDim2.new(1, -10, 0.5, 0), UDim2.new(0, 8, 0, 2),
    Color3.fromRGB(255, 200, 0), 15)

makeLabel(infoPanelBG, "CashLabel", "$500",
    UDim2.new(1, -10, 0.5, 0), UDim2.new(0, 8, 0.5, 0),
    Color3.fromRGB(120, 220, 120), 13)

-- ─── Crosshair (centre) ──────────────────────────────────────────────────────
local crosshairFrame = makeFrame(HUD, "Crosshair",
    UDim2.new(0, 0, 0, 0),
    UDim2.new(0.5, 0, 0.5, 0),
    Color3.new(0,0,0), 1)

local function makeLine(name, sizeX, sizeY, posX, posY)
    local line = makeFrame(crosshairFrame, name,
        UDim2.new(0, sizeX, 0, sizeY),
        UDim2.new(0.5, posX, 0.5, posY),
        Color3.new(1, 1, 1), 0)
    line.ZIndex = 10
    return line
end

makeLine("Top",    2, 12,  -1, -22)
makeLine("Bottom", 2, 12,  -1,  10)
makeLine("Left",  12,  2, -22,  -1)
makeLine("Right", 12,  2,  10,  -1)

-- Centre dot
local dot = makeFrame(crosshairFrame, "Dot",
    UDim2.new(0, 4, 0, 4), UDim2.new(0.5, -2, 0.5, -2),
    Color3.new(1,1,1), 0)
dot.ZIndex = 10

-- Hit marker (hidden by default)
local hitmarker = makeFrame(HUD, "Hitmarker",
    UDim2.new(0, 20, 0, 20), UDim2.new(0.5, -10, 0.5, -10),
    Color3.new(1,1,1), 0)
hitmarker.Visible = false
do
    local img = Instance.new("ImageLabel")
    img.Size  = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.Image = "rbxassetid://0"  -- replace with hitmarker image
    img.Parent = hitmarker
end

-- ─── Objective tracker (right side) ──────────────────────────────────────────
local objPanel = makeFrame(HUD, "ObjectivePanel",
    UDim2.new(0, 240, 0, 140),
    UDim2.new(1, -255, 0, 60),
    Color3.new(0,0,0), 0.45)
corner(objPanel, 6)

makeLabel(objPanel, "ObjTitle", "OBJECTIVES",
    UDim2.new(1, -10, 0, 20), UDim2.new(0, 8, 0, 4),
    Color3.fromRGB(255, 200, 0), 12)

local objList = Instance.new("ScrollingFrame")
objList.Name                  = "ObjList"
objList.Size                  = UDim2.new(1, -10, 1, -30)
objList.Position              = UDim2.new(0, 5, 0, 28)
objList.BackgroundTransparency = 1
objList.ScrollBarThickness    = 0
objList.Parent                = objPanel

local objLayout = Instance.new("UIListLayout")
objLayout.Padding   = UDim.new(0, 4)
objLayout.SortOrder = Enum.SortOrder.LayoutOrder
objLayout.Parent    = objList

-- ─── Kill feed (top right) ───────────────────────────────────────────────────
local killFeedFrame = makeFrame(HUD, "KillFeed",
    UDim2.new(0, 220, 0, 160),
    UDim2.new(1, -230, 0, 60),
    Color3.new(0,0,0), 1)

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
killFeedLayout.Padding           = UDim.new(0, 2)
killFeedLayout.SortOrder         = Enum.SortOrder.LayoutOrder
killFeedLayout.Parent            = killFeedFrame

-- ─── Minimap frame placeholder ───────────────────────────────────────────────
local minimapBG = makeFrame(HUD, "MinimapBG",
    UDim2.new(0, 140, 0, 140),
    UDim2.new(0, 10, 1, -160),
    Color3.fromRGB(15, 30, 15), 0.25)
corner(minimapBG, 70)  -- circular

makeLabel(minimapBG, "MinimapLabel", "MAP",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(80,80,80), 11)

-- ─── Compass (top centre) ────────────────────────────────────────────────────
local compassBG = makeFrame(HUD, "CompassBG",
    UDim2.new(0, 300, 0, 24),
    UDim2.new(0.5, -150, 0, 22),
    Color3.new(0,0,0), 0.5)
corner(compassBG, 4)

local compassLabel = makeLabel(compassBG, "CompassLabel", "N  NE  E  SE  S  SW  W  NW",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(220, 220, 220), 11)

-- Update compass each frame
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local _, yaw, _ = hrp.CFrame:ToEulerAnglesYXZ()
    local deg = math.deg(yaw) % 360
    local dirs = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
    local idx  = math.floor((deg + 22.5) / 45) % 8 + 1
    compassLabel.Text = ("%.0f°  %s"):format(deg, dirs[idx])
end)

-- ─── Vehicle HUD (hidden by default) ─────────────────────────────────────────
local vehicleHUD = Instance.new("ScreenGui")
vehicleHUD.Name          = "VehicleHUD"
vehicleHUD.ResetOnSpawn  = false
vehicleHUD.Enabled       = false
vehicleHUD.Parent        = PlayerGui

local vNameLabel = makeLabel(vehicleHUD, "VehicleName", "HUMVEE",
    UDim2.new(0, 200, 0, 24), UDim2.new(0.5, -100, 1, -130),
    Color3.fromRGB(255, 200, 0), 16)

local speedBG = makeFrame(vehicleHUD, "SpeedBG",
    UDim2.new(0, 180, 0, 40), UDim2.new(0.5, -90, 1, -100),
    Color3.new(0,0,0), 0.5)
corner(speedBG, 6)

makeLabel(speedBG, "SpeedLabel", "0 km/h",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.new(1,1,1), 20)

local fuelBG = makeFrame(vehicleHUD, "FuelBG",
    UDim2.new(0, 180, 0, 12), UDim2.new(0.5, -90, 1, -55),
    Color3.fromRGB(30,30,30), 0.4)
corner(fuelBG, 4)

local fuelBar = makeFrame(fuelBG, "FuelBar",
    UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0),
    Color3.fromRGB(60, 180, 60), 0)
corner(fuelBar, 4)

makeLabel(fuelBG, "FuelLabel", "100%",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    Color3.new(1,1,1), 10)

local vHealthBG = makeFrame(vehicleHUD, "VehicleHealthBG",
    UDim2.new(0, 180, 0, 10), UDim2.new(0.5, -90, 1, -70),
    Color3.fromRGB(30,30,30), 0.4)
corner(vHealthBG, 4)

makeFrame(vHealthBG, "VehicleHealthBar",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    Color3.fromRGB(60, 200, 60), 0)

makeLabel(vehicleHUD, "FuelWarning", "NO FUEL",
    UDim2.new(0, 150, 0, 30), UDim2.new(0.5, -75, 0.5, -15),
    Color3.fromRGB(255, 60, 60), 20).Visible = false

-- Altitude label for helicopters
makeLabel(vehicleHUD, "AltitudeLabel", "0 m AGL",
    UDim2.new(0, 160, 0, 22), UDim2.new(0.5, -80, 1, -130),
    Color3.fromRGB(120, 200, 255), 13).Visible = false

local throttleBG = makeFrame(vehicleHUD, "ThrottleBG",
    UDim2.new(0, 12, 0, 100), UDim2.new(1, -40, 0.5, -50),
    Color3.fromRGB(20,20,20), 0.4)
corner(throttleBG, 4)

makeFrame(throttleBG, "ThrottleBar",
    UDim2.new(1,0,0,0), UDim2.new(0,0,1,-0),
    Color3.fromRGB(100, 200, 255), 0)

-- ─── Objective tracker public functions ──────────────────────────────────────
local function clearObjectives()
    for _, child in ipairs(objList:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

local function addObjective(text, complete)
    local row = makeFrame(objList, "Obj",
        UDim2.new(1, -4, 0, 18), UDim2.new(0,0,0,0),
        Color3.new(0,0,0), 1)
    local icon = makeLabel(row, "Icon", complete and "✓" or "○",
        UDim2.new(0, 16, 1, 0), UDim2.new(0, 2, 0, 0),
        complete and Color3.fromRGB(60,220,60) or Color3.fromRGB(255,200,0), 13)
    makeLabel(row, "Text", text,
        UDim2.new(1, -20, 1, 0), UDim2.new(0, 20, 0, 0),
        Color3.fromRGB(220,220,220), 12)
end

-- Kill feed entry
local function addKillFeedEntry(killerName, victimName, weaponId)
    local entry = makeLabel(killFeedFrame, "KillEntry",
        ("[%s] → [%s] %s"):format(killerName, victimName, weaponId or ""),
        UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(240, 240, 240), 11)
    entry.TextXAlignment = Enum.TextXAlignment.Right
    task.delay(5, function()
        TweenService:Create(entry, TweenInfo.new(0.5), {
            TextTransparency = 1
        }):Play()
        task.delay(0.6, function() entry:Destroy() end)
    end)

    -- Keep feed to 6 entries
    local entries = killFeedFrame:GetChildren()
    if #entries > 7 then
        for _, e in ipairs(entries) do
            if e:IsA("TextLabel") then e:Destroy() break end
        end
    end
end

-- ─── Connect to remotes ──────────────────────────────────────────────────────
local shared   = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes  = require(shared:WaitForChild("Remotes"))

Remotes.OnClient("PlayerKilled", function(payload)
    local killer = LocalPlayer.Name
    local victim = Players:GetPlayerByUserId(payload.victimId)
    addKillFeedEntry(killer, victim and victim.Name or "Enemy", payload.weaponId)
end)

Remotes.OnClient("MissionStarted", function(payload)
    clearObjectives()
    if payload.objectives then
        for _, obj in ipairs(payload.objectives) do
            addObjective(obj.label, false)
        end
    end
end)

Remotes.OnClient("ObjectiveUpdated", function(payload)
    -- Update objective row progress text
    local rows = objList:GetChildren()
    local idx  = payload.objectiveIndex
    if idx and rows[idx] then
        local textLabel = rows[idx]:FindFirstChild("Text")
        if textLabel and payload.progress and payload.goal then
            local base = textLabel.Text:match("^(.-)%s*%(%d") or textLabel.Text
            textLabel.Text = base .. (" (%d/%d)"):format(payload.progress, payload.goal)
        end
    end
end)

Remotes.OnClient("MissionCompleted", function()
    clearObjectives()
    addObjective("Mission Complete!", true)
    task.delay(5, clearObjectives)
end)

-- Health sync
local function updateHealthDisplay()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local pct = hum.Health / hum.MaxHealth
    healthBar.Size = UDim2.new(pct, 0, 1, 0)
    healthBar.BackgroundColor3 = pct < 0.3
        and Color3.fromRGB(220, 50, 50)
        or (pct < 0.6 and Color3.fromRGB(220, 180, 30) or Color3.fromRGB(60, 200, 60))

    local lbl = healthBG:FindFirstChild("HealthLabel")
    if lbl then lbl.Text = math.floor(hum.Health) .. " HP" end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("Health"):Connect(updateHealthDisplay)
    updateHealthDisplay()
end)
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:GetPropertyChangedSignal("Health"):Connect(updateHealthDisplay) end
end

print("[HUD] Built and running.")
