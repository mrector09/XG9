-- QuickGive.client.lua — owner-only floating panel for giving items to self.
-- Toggle: Insert key (or Ctrl+G). Only visible to the owner / in Studio.

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local shared     = ReplicatedStorage:WaitForChild("JTF", 15)
local Theme      = require(shared:WaitForChild("Theme"))
local Remotes    = require(shared:WaitForChild("Remotes"))
local AdminCfg   = require(shared:WaitForChild("Config"):WaitForChild("AdminConfig"))
local RankCfg    = require(shared:WaitForChild("Config"):WaitForChild("RankConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local IS_STUDIO   = RunService:IsStudio()

-- Owner / studio gate
if not IS_STUDIO and not AdminCfg.IsAdmin(LocalPlayer.UserId) then return end

-- ─── Screen ───────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "QuickGive"
sg.ResetOnSpawn   = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.DisplayOrder   = 20  -- above everything
sg.Enabled        = false
sg.Parent         = PlayerGui

-- ─── Panel (floating, right side) ────────────────────────────────────────────
local PANEL_W = 320
local PANEL_H = 560

local panel = Theme.Frame(sg, "Panel",
    UDim2.new(0, PANEL_W, 0, PANEL_H),
    UDim2.new(1, -(PANEL_W + 16), 0.5, -(PANEL_H / 2)),
    Theme.Colors.Surface)
Theme.Corner(panel, Theme.Radius.Lg)
Theme.Stroke(panel, Theme.Colors.Primary, 2)

-- Shadow (cosmetic)
local shadow = Theme.Frame(sg, "Shadow",
    UDim2.new(0, PANEL_W + 20, 0, PANEL_H + 20),
    UDim2.new(1, -(PANEL_W + 26), 0.5, -(PANEL_H / 2) - 10),
    Color3.new(0,0,0))
shadow.BackgroundTransparency = 0.6
Theme.Corner(shadow, Theme.Radius.Xl)
shadow.ZIndex = panel.ZIndex - 1

-- Panel header
local pHeader = Theme.Frame(panel, "Header",
    UDim2.new(1,0,0,44), nil, Theme.Colors.Surface2)
Theme.Corner(pHeader, Theme.Radius.Lg)
-- Cover bottom corners of header
Theme.Frame(pHeader, "CornerFix", UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), Theme.Colors.Surface2)

Theme.Label(pHeader, "Title", "⚙ QUICK GIVE",
    UDim2.new(1,-60,1,0), UDim2.new(0,14,0,0),
    Theme.Colors.Primary, 13, Theme.Fonts.Bold)

local closePanelBtn = Theme.Button(pHeader, "X", "✕",
    UDim2.new(0,28,0,28), UDim2.new(1,-36,0.5,-14), "ghost")
closePanelBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
end)

local targetLbl = Theme.Label(pHeader, "Target",
    "Target: " .. LocalPlayer.Name,
    UDim2.new(1,-60,0,14), UDim2.new(0,14,1,-16),
    Theme.Colors.TextSubtle, 9, Theme.Fonts.Mono)

-- Scrollable content
local scroll = Theme.Scroll(panel, "Scroll",
    UDim2.new(1,-8,1,-52), UDim2.new(0,4,0,48))
Theme.ListLayout(scroll, Enum.FillDirection.Vertical, 10)
Theme.Padding(scroll, 10)

-- Status label (inline at bottom of scroll area)
local statusLbl = Theme.Label(scroll, "Status", "",
    UDim2.new(1,0,0,18), nil,
    Theme.Colors.Success, 10, Theme.Fonts.Regular)
statusLbl.LayoutOrder = 99

local function setStatus(msg, isOk)
    statusLbl.Text       = msg
    statusLbl.TextColor3 = isOk and Theme.Colors.Success or Theme.Colors.Danger
    task.delay(4, function() statusLbl.Text = "" end)
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function invoke(cmd, ...)
    local res = Remotes.InvokeServer("AdminCommand", cmd, ...)
    return res and res.ok, res and (res.msg or "")
end

local function section(label)
    local s = Theme.Frame(scroll, label .. "Section",
        UDim2.new(1,0,0,18), nil, Color3.new(0,0,0), 1)
    s.LayoutOrder = #scroll:GetChildren()
    Theme.Label(s, "L", label,
        UDim2.new(1,0,1,0), nil,
        Theme.Colors.TextSubtle, 10, Theme.Fonts.Bold)
    local div = Theme.Divider(s)
    div.Position = UDim2.new(0,0,1,-1)
    return s
end

local function row(parent, label, widget)
    local r = Theme.Frame(parent, label .. "Row",
        UDim2.new(1,0,0,34), nil, Color3.new(0,0,0), 1)
    r.LayoutOrder = parent and #parent:GetChildren() or 0
    Theme.Label(r, "L", label,
        UDim2.new(0.38,0,1,0), nil,
        Theme.Colors.TextMuted, 10, Theme.Fonts.Regular)
    widget.Size     = UDim2.new(0.6,0,0,26)
    widget.Position = UDim2.new(0.4,0,0.5,-13)
    widget.Parent   = r
    return r
end

local function makeInput(placeholder)
    local box = Instance.new("TextBox")
    box.PlaceholderText      = placeholder
    box.Text                 = ""
    box.TextColor3           = Theme.Colors.Text
    box.PlaceholderColor3    = Theme.Colors.TextSubtle
    box.BackgroundColor3     = Theme.Colors.Surface3
    box.Font                 = Theme.Fonts.Regular
    box.TextSize             = 12
    box.ClearTextOnFocus     = false
    box.BorderSizePixel      = 0
    box.TextXAlignment       = Enum.TextXAlignment.Center
    Theme.Corner(box, Theme.Radius.Sm)
    Theme.Stroke(box, Theme.Colors.Border)
    return box
end

local function makeBtn(label, style)
    local b = Theme.Button(nil, "Btn", label, UDim2.new(1,0,0,28), nil, style or "ghost")
    b.TextSize = 11
    return b
end

-- ─── QUICK ACTIONS ────────────────────────────────────────────────────────────
local s1 = section("QUICK ACTIONS")
s1.LayoutOrder = 1

local quickRow1 = Theme.Frame(scroll, "QuickRow1",
    UDim2.new(1,0,0,30), nil, Color3.new(0,0,0), 1)
quickRow1.LayoutOrder = 2
Theme.ListLayout(quickRow1, Enum.FillDirection.Horizontal, 6)

local QUICK_ACTIONS = {
    { label = "+1K Cash",   cmd = "giveCash", args = {LocalPlayer.Name, "1000"} },
    { label = "+500 XP",    cmd = "giveXP",   args = {LocalPlayer.Name, "500"} },
    { label = "+Rank",      cmd = "promote",  args = {LocalPlayer.Name} },
}
for _, qa in ipairs(QUICK_ACTIONS) do
    local btn = makeBtn(qa.label, "muted")
    btn.Size        = UDim2.new(0, 86, 1, 0)
    btn.LayoutOrder = #quickRow1:GetChildren()
    btn.Parent      = quickRow1
    local captured  = qa
    btn.MouseButton1Click:Connect(function()
        local ok, msg = invoke(captured.cmd, table.unpack(captured.args))
        setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
    end)
end

-- MAX ALL button (prominent)
local maxBtn = makeBtn("⭐ MAX EVERYTHING", "primary")
maxBtn.Size        = UDim2.new(1,0,0,34)
maxBtn.LayoutOrder = 3
maxBtn.TextSize    = 12
maxBtn.Parent      = scroll
maxBtn.MouseButton1Click:Connect(function()
    maxBtn.Text = "Working..."
    local ok, msg = invoke("giveMax", LocalPlayer.Name)
    maxBtn.Text = "⭐ MAX EVERYTHING"
    setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
end)

-- ─── CASH ────────────────────────────────────────────────────────────────────
local s2 = section("CASH")
s2.LayoutOrder = 4

local cashInput = makeInput("Amount (e.g. 5000)")
local cashRow   = row(scroll, "Amount", cashInput)
cashRow.LayoutOrder = 5

local cashBtn = makeBtn("Give Cash", "success")
cashBtn.Size        = UDim2.new(1,0,0,28)
cashBtn.LayoutOrder = 6
cashBtn.Parent      = scroll
cashBtn.MouseButton1Click:Connect(function()
    local amt = tonumber(cashInput.Text)
    if not amt or amt <= 0 then setStatus("✗ Enter a valid amount", false) return end
    local ok, msg = invoke("giveCash", LocalPlayer.Name, tostring(math.floor(amt)))
    setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
    if ok then cashInput.Text = "" end
end)

-- ─── XP ──────────────────────────────────────────────────────────────────────
local s3 = section("EXPERIENCE")
s3.LayoutOrder = 7

local xpInput = makeInput("Amount (e.g. 1000)")
local xpRow   = row(scroll, "Amount", xpInput)
xpRow.LayoutOrder = 8

local xpBtn = makeBtn("Give XP", "success")
xpBtn.Size        = UDim2.new(1,0,0,28)
xpBtn.LayoutOrder = 9
xpBtn.Parent      = scroll
xpBtn.MouseButton1Click:Connect(function()
    local amt = tonumber(xpInput.Text)
    if not amt or amt <= 0 then setStatus("✗ Enter a valid amount", false) return end
    local ok, msg = invoke("giveXP", LocalPlayer.Name, tostring(math.floor(amt)))
    setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
    if ok then xpInput.Text = "" end
end)

-- ─── RANK ────────────────────────────────────────────────────────────────────
local s4 = section("RANK")
s4.LayoutOrder = 10

local rankGrid = Theme.Frame(scroll, "RankGrid",
    UDim2.new(1,0,0,100), nil, Color3.new(0,0,0), 1)
rankGrid.LayoutOrder = 11
local rgLayout = Instance.new("UIGridLayout")
rgLayout.CellSize    = UDim2.new(0.5,-4,0,26)
rgLayout.CellPadding = UDim2.new(0,8,0,4)
rgLayout.SortOrder   = Enum.SortOrder.LayoutOrder
rgLayout.Parent      = rankGrid

for idx, rankInfo in pairs(RankCfg.Ranks) do
    local rb = makeBtn(rankInfo.name, "muted")
    rb.LayoutOrder = idx
    rb.TextSize    = 9
    rb.Parent      = rankGrid
    local capturedIdx = idx
    rb.MouseButton1Click:Connect(function()
        local ok, msg = invoke("setRank", LocalPlayer.Name, tostring(capturedIdx))
        setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
    end)
end

-- ─── BATTLE PASS ─────────────────────────────────────────────────────────────
local s5 = section("BATTLE PASS")
s5.LayoutOrder = 12

local bpBtn = makeBtn("⭐ Max Battle Pass (Tier 50)", "primary")
bpBtn.Size        = UDim2.new(1,0,0,28)
bpBtn.LayoutOrder = 13
bpBtn.Parent      = scroll
bpBtn.MouseButton1Click:Connect(function()
    local ok, msg = invoke("maxBP", LocalPlayer.Name)
    setStatus(ok and "✓ " .. msg or "✗ " .. msg, ok)
end)

-- ─── Toggle keybind ───────────────────────────────────────────────────────────

local isOpen = false
local function setOpen(open)
    isOpen = open
    if open then
        -- Animate slide in from right
        panel.Position = UDim2.new(1, 16, 0.5, -(PANEL_H / 2))
        sg.Enabled = true
        TweenService:Create(panel,
            TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(1, -(PANEL_W + 16), 0.5, -(PANEL_H / 2)) }
        ):Play()
    else
        local tw = TweenService:Create(panel,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(1, 16, 0.5, -(PANEL_H / 2)) })
        tw:Play()
        tw.Completed:Connect(function()
            sg.Enabled = false
        end)
    end
end

UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    local isInsert  = inp.KeyCode == Enum.KeyCode.Insert
    local isCtrlG   = inp.KeyCode == Enum.KeyCode.G
        and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    if isInsert or isCtrlG then
        setOpen(not isOpen)
    end
end)

closePanelBtn.MouseButton1Click:Connect(function()
    setOpen(false)
end)

print("[JTF] QuickGive: ready (Insert or Ctrl+G to toggle)")
