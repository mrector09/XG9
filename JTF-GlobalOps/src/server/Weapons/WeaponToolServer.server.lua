-- WeaponToolServer.server.lua
-- Place this Script inside EVERY weapon Tool in ServerStorage/Weapons/<WeaponId>/
-- It reads WeaponId from the Tool's Attribute and links into WeaponService.
-- The Tool must have a StringAttribute named "WeaponId" set to its config key (e.g. "M4A1").

local Players      = game:GetService("Players")

local tool         = script.Parent  -- the Tool instance
local weaponId     = tool:GetAttribute("WeaponId")

if not weaponId then
    warn("[WeaponToolServer] Tool is missing WeaponId attribute:", tool:GetFullName())
    return
end

local shared       = game.ReplicatedStorage:WaitForChild("JTF", 10)
local Remotes      = require(shared:WaitForChild("Remotes"))
local WeaponConfig = require(shared:WaitForChild("Config"):WaitForChild("WeaponConfig"))
local wConfig      = WeaponConfig.Weapons[weaponId]

if not wConfig then
    warn("[WeaponToolServer] Unknown weapon in config:", weaponId)
    return
end

-- Grab services (they're already running — just require the modules)
local services     = game.ServerScriptService:WaitForChild("JTF"):WaitForChild("Services")
local WeaponService = require(services:WaitForChild("WeaponService"))

local owner  = nil  -- Player who has this tool equipped
local equipped = false

-- ─── Equip / Unequip ─────────────────────────────────────────────────────────
tool.Equipped:Connect(function()
    equipped = true
    local char = tool.Parent
    if char then
        owner = Players:GetPlayerFromCharacter(char)
    end
end)

tool.Unequipped:Connect(function()
    equipped = false
    owner    = nil
end)

-- ─── Grenade / thrown weapon activation ──────────────────────────────────────
-- For firearms, firing is handled entirely by WeaponClient → WeaponFired remote.
-- For grenades, we handle the throw here server-side.
if wConfig.category == "Thrown" then
    tool.Activated:Connect(function()
        if not owner then return end

        local char = tool.Parent
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Validate throw cooldown (basic anti-spam)
        local now = tick()
        if (tool:GetAttribute("LastThrow") or 0) + 2 > now then return end
        tool:SetAttribute("LastThrow", now)

        -- Server-side grenade
        local fusePart = Instance.new("Part")
        fusePart.Size      = Vector3.new(0.3, 0.3, 0.3)
        fusePart.BrickColor = BrickColor.new("Bright green")
        fusePart.CanCollide = true
        fusePart.Parent    = workspace

        -- Throw direction: forward + slightly up
        local throwDir = (hrp.CFrame.LookVector + Vector3.new(0, 0.35, 0)).Unit
        local velocity = Instance.new("BodyVelocity")
        velocity.Velocity  = throwDir * 40
        velocity.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
        velocity.Parent    = fusePart
        fusePart.CFrame    = hrp.CFrame + hrp.CFrame.LookVector * 2 + Vector3.new(0, 1, 0)

        -- Destroy BodyVelocity after brief moment so gravity takes over
        task.delay(0.15, function()
            if velocity and velocity.Parent then
                velocity:Destroy()
            end
        end)

        -- Detonate after fuse
        task.delay(wConfig.fuseTime or 2.5, function()
            if not fusePart or not fusePart.Parent then return end

            local blastPos = fusePart.Position
            fusePart:Destroy()

            if wConfig.category == "Thrown" and wConfig.damage > 0 then
                -- Frag grenade: AOE damage
                local blastRadius = wConfig.blastRadius or 12
                for _, player in ipairs(Players:GetPlayers()) do
                    local c   = player.Character
                    local h   = c and c:FindFirstChild("HumanoidRootPart")
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    if h and hum and hum.Health > 0 then
                        local dist = (h.Position - blastPos).Magnitude
                        if dist <= blastRadius then
                            local dmg = wConfig.damage * (1 - dist / blastRadius)
                            hum:TakeDamage(math.floor(dmg))
                        end
                    end
                end
                -- Damage NPCs in blast
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj.Name == "HumanoidRootPart" then
                        local hum = obj.Parent:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local dist = (obj.Position - blastPos).Magnitude
                            if dist <= blastRadius then
                                hum:TakeDamage(wConfig.damage * (1 - dist / blastRadius))
                            end
                        end
                    end
                end

            elseif wConfig.stunDuration then
                -- Flashbang: stun players in range
                local stunRange = 20
                for _, player in ipairs(Players:GetPlayers()) do
                    local c  = player.Character
                    local h  = c and c:FindFirstChild("HumanoidRootPart")
                    if h and (h.Position - blastPos).Magnitude <= stunRange then
                        Remotes.FireClient("DamageTaken", player, {
                            amount = 0,
                            source = "Flashbang",
                            stun   = wConfig.stunDuration,
                        })
                    end
                end
            end
        end)

        -- Remove from inventory after throw
        task.delay(0.5, function()
            tool:Destroy()
        end)
    end)
end
