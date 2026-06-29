-- OwnerPanel.client.lua — multi-tab admin/owner panel (only visible to admins)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local shared   = ReplicatedStorage:WaitForChild("JTF", 15)
local AdminCfg = require(shared:WaitForChild("Config"):WaitForChild("AdminConfig"))

-- In Studio, UserId is negative — always allow so you can test your own panel
local IS_STUDIO = RunService:IsStudio()
if not IS_STUDIO and not AdminCfg.IsAdmin(LocalPlayer.UserId) then return end

local Theme   = require(shared:WaitForChild("Theme"))
local Remotes = require(shared:WaitForChild("Remotes"))

-- ─── Panel dimensions ─────────────────────────────────────────────────────────
local PANEL_W  = 820
local PANEL_H  = 560
local TAB_H    = 40
local SIDEBAR_W = 160

-- ─── Root ─────────────────────────────────────────────────────────────────────
local sg = Theme.Screen("OwnerPanel", 50)
sg.Enabled = false
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Dim backdrop
local backdrop = Theme.Frame(sg, "Backdrop",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0),
    Color3.new(0, 0, 0), 0.55)

-- Main window
local win = Theme.Frame(sg, "Window",
    UDim2.new(0, PANEL_W, 0, PANEL_H),
    UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2),
    Theme.Colors.Surface)
Theme.Corner(win, Theme.Radius.Lg)
Theme.Stroke(win, Theme.Colors.Border, 1)

-- Title bar
local titleBar = Theme.Frame(win, "TitleBar",
    UDim2.new(1, 0, 0, 44),
    UDim2.new(0, 0, 0, 0),
    Theme.Colors.BG)
Theme.Corner(titleBar, Theme.Radius.Lg)
-- patch bottom corners
Theme.Frame(titleBar, "BottomPatch",
    UDim2.new(1, 0, 0, 10),
    UDim2.new(0, 0, 1, -10),
    Theme.Colors.BG)

local titleLabel = Theme.Label(titleBar, "Title",
    "⬡  JTF ADMIN PANEL",
    UDim2.new(1, -100, 1, 0), UDim2.new(0, 16, 0, 0),
    Theme.Colors.Primary, 15, Theme.Fonts.Bold)

-- Tier badge
local tierBadge = Theme.Badge(titleBar, AdminCfg.GetTier(LocalPlayer.UserId) or "Admin",
    Theme.Colors.Warning)
tierBadge.Position = UDim2.new(0, titleLabel.TextBounds and titleLabel.TextBounds.X + 24 or 240, 0.5, -10)

-- Close button
local closeBtn = Theme.Button(titleBar, "CloseBtn", "✕",
    UDim2.new(0, 32, 0, 32), UDim2.new(1, -40, 0.5, -16), "danger")

-- Content area (below title bar)
local content = Theme.Frame(win, "Content",
    UDim2.new(1, 0, 1, -44),
    UDim2.new(0, 0, 0, 44),
    Theme.Colors.BG)

-- Sidebar
local sidebar = Theme.Frame(content, "Sidebar",
    UDim2.new(0, SIDEBAR_W, 1, 0),
    UDim2.new(0, 0, 0, 0),
    Theme.Colors.Surface)
Theme.Padding(sidebar, nil, 8, 0, 8, 0)
Theme.ListLayout(sidebar, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Center)

-- Main pane
local mainPane = Theme.Frame(content, "MainPane",
    UDim2.new(1, -SIDEBAR_W, 1, 0),
    UDim2.new(0, SIDEBAR_W, 0, 0),
    Theme.Colors.BG)

-- ─── Tab system ───────────────────────────────────────────────────────────────

local TABS = { "Players", "Commands", "Server", "Economy", "Logs" }
local tabPages    = {}
local tabButtons  = {}
local activePage  = nil

local function activateTab(name)
    for _, t in ipairs(TABS) do
        if tabPages[t]    then tabPages[t].Visible    = (t == name) end
        if tabButtons[t]  then
            tabButtons[t].BackgroundColor3 = (t == name)
                and Theme.Colors.Primary
                or  Theme.Colors.Surface2
            tabButtons[t].TextColor3 = (t == name)
                and Theme.Colors.PrimaryText
                or  Theme.Colors.TextMuted
        end
    end
    activePage = name
end

for _, tabName in ipairs(TABS) do
    local btn = Theme.Button(sidebar, tabName .. "Tab", tabName,
        UDim2.new(1, -16, 0, 34), nil, "muted")
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Theme.Padding(btn, nil, 0, 0, 0, 12)
    btn.LayoutOrder = _ -- preserve order

    tabButtons[tabName] = btn
    btn.MouseButton1Click:Connect(function() activateTab(tabName) end)

    -- Page frame
    local page = Theme.Frame(mainPane, tabName .. "Page",
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        Theme.Colors.BG)
    page.Visible = false
    Theme.Padding(page, 14)
    tabPages[tabName] = page
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function sectionHeader(parent, title)
    local row = Theme.Frame(parent, title .. "Header",
        UDim2.new(1, 0, 0, 26), nil, Color3.new(0,0,0), 1)
    Theme.Label(row, "Lbl", title:upper(),
        UDim2.new(1,0,1,0), nil,
        Theme.Colors.Primary, 11, Theme.Fonts.Bold)
    local div = Theme.Divider(row)
    div.Position = UDim2.new(0, 0, 1, -1)
    return row
end

local function statusLabel(parent, name)
    return Theme.Label(parent, name, "",
        UDim2.new(1, 0, 0, 18), nil,
        Theme.Colors.TextMuted, 12, Theme.Fonts.Regular)
end

local function invokeAdmin(cmd, ...)
    return Remotes.InvokeServer("AdminCommand", cmd, ...)
end

-- Feedback toast inside the panel
local feedbackLabel = Theme.Label(win, "Feedback", "",
    UDim2.new(1, -32, 0, 24),
    UDim2.new(0, 16, 1, -32),
    Theme.Colors.Success, 12, Theme.Fonts.Medium,
    Enum.TextXAlignment.Left)
feedbackLabel.BackgroundTransparency = 1

local feedbackThread
local function showFeedback(msg, isError)
    feedbackLabel.Text       = msg
    feedbackLabel.TextColor3 = isError and Theme.Colors.Danger or Theme.Colors.Success
    if feedbackThread then task.cancel(feedbackThread) end
    feedbackThread = task.delay(4, function() feedbackLabel.Text = "" end)
end

local function doCmd(cmd, ...)
    local res = invokeAdmin(cmd, ...)
    if res then
        showFeedback(res.msg or (res.ok and "Done" or "Failed"), not res.ok)
    end
    return res
end

-- ─── PLAYERS TAB ──────────────────────────────────────────────────────────────

local playersPage = tabPages["Players"]
Theme.ListLayout(playersPage, Enum.FillDirection.Vertical, 8)

sectionHeader(playersPage, "Online Players")

-- Player list scroll
local playerScroll = Theme.Scroll(playersPage, "PlayerScroll",
    UDim2.new(1, 0, 0, 220))
playerScroll.LayoutOrder = 2
Theme.ListLayout(playerScroll, Enum.FillDirection.Vertical, 2)

-- Selected player
local selectedPlayer = nil
local selectedRow    = nil

local function selectPlayerRow(row, name, userId)
    if selectedRow then
        selectedRow.BackgroundColor3 = Theme.Colors.Surface
    end
    selectedRow = row
    row.BackgroundColor3 = Theme.Colors.Surface3
    selectedPlayer = { name = name, userId = userId }
end

local function buildPlayerRow(info)
    local row = Theme.Frame(playerScroll, "Row_" .. info.userId,
        UDim2.new(1, -4, 0, 38), nil, Theme.Colors.Surface)
    Theme.Corner(row, Theme.Radius.Sm)
    Theme.Padding(row, nil, 0, 8, 0, 10)

    local nameLabel = Theme.Label(row, "Name", info.name,
        UDim2.new(0, 120, 1, 0), UDim2.new(0,0,0,0),
        Theme.Colors.Text, 13, Theme.Fonts.Bold)

    Theme.Label(row, "Branch",
        info.branch .. " | " .. info.job,
        UDim2.new(0, 150, 1, 0), UDim2.new(0, 125, 0, 0),
        Theme.Colors.TextMuted, 12, Theme.Fonts.Regular)

    Theme.Label(row, "Stats",
        "Rank " .. info.rank .. "  •  " .. info.kills .. "K/" .. info.deaths .. "D",
        UDim2.new(0, 130, 1, 0), UDim2.new(0, 280, 0, 0),
        Theme.Colors.TextSubtle, 11, Theme.Fonts.Mono)

    if info.tier then
        Theme.Badge(row, info.tier, Theme.Colors.Warning).Position = UDim2.new(0, 420, 0.5, -10)
    end

    row.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            selectPlayerRow(row, info.name, info.userId)
        end
    end)
    return row
end

local function refreshPlayers()
    for _, c in ipairs(playerScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local res = Remotes.InvokeServer("AdminGetPlayers")
    if res then
        for _, info in ipairs(res) do buildPlayerRow(info) end
    end
end

-- Action buttons row
local actionRow = Theme.Frame(playersPage, "Actions",
    UDim2.new(1, 0, 0, 34), nil, Color3.new(0,0,0), 1)
actionRow.LayoutOrder = 3
Theme.ListLayout(actionRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

local function quickBtn(name, label, style, fn)
    local b = Theme.Button(actionRow, name, label, UDim2.new(0, 88, 0, 30), nil, style)
    b.MouseButton1Click:Connect(function()
        if not selectedPlayer then showFeedback("Select a player first", true) return end
        fn(selectedPlayer)
    end)
    return b
end

quickBtn("KickBtn", "Kick", "danger", function(p)
    doCmd("kick", p.name, "Kicked by admin")
    task.delay(0.5, refreshPlayers)
end)
quickBtn("PromoteBtn", "Promote", "success", function(p)
    doCmd("promote", p.name)
end)
quickBtn("DemoteBtn", "Demote", "ghost", function(p)
    doCmd("demote", p.name)
end)
quickBtn("TeleportBtn", "Teleport", "ghost", function(p)
    doCmd("teleport", p.name, LocalPlayer.Name)
end)

local refreshBtn = Theme.Button(actionRow, "RefreshBtn", "↻ Refresh",
    UDim2.new(0, 88, 0, 30), nil, "muted")
refreshBtn.MouseButton1Click:Connect(refreshPlayers)

-- ─── COMMANDS TAB ─────────────────────────────────────────────────────────────

local cmdPage = tabPages["Commands"]
Theme.ListLayout(cmdPage, Enum.FillDirection.Vertical, 10)

sectionHeader(cmdPage, "Manual Commands")

local function cmdRow(parent, labelText, placeholder1, placeholder2, cmdName, style)
    local row = Theme.Frame(parent, cmdName .. "Row",
        UDim2.new(1, 0, 0, 40), nil, Color3.new(0,0,0), 1)
    row.LayoutOrder = parent:GetChildren() and #parent:GetChildren() or 1
    Theme.ListLayout(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

    Theme.Label(row, "Lbl", labelText,
        UDim2.new(0, 130, 1, 0), nil,
        Theme.Colors.TextMuted, 12, Theme.Fonts.Medium,
        Enum.TextXAlignment.Left)

    local inp1 = Theme.Input(row, "Inp1", placeholder1,
        UDim2.new(0, 140, 0, 30))

    local inp2
    if placeholder2 then
        inp2 = Theme.Input(row, "Inp2", placeholder2,
            UDim2.new(0, 120, 0, 30))
    end

    local execBtn = Theme.Button(row, "Exec", "Execute",
        UDim2.new(0, 80, 0, 30), nil, style or "primary")
    execBtn.MouseButton1Click:Connect(function()
        doCmd(cmdName, inp1.Text, inp2 and inp2.Text or nil)
        inp1.Text = ""
        if inp2 then inp2.Text = "" end
    end)

    return row
end

local function announceCmdRow(parent)
    local row = Theme.Frame(parent, "AnnounceRow",
        UDim2.new(1, 0, 0, 40), nil, Color3.new(0,0,0), 1)
    row.LayoutOrder = 99
    Theme.ListLayout(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

    Theme.Label(row, "Lbl", "Announce",
        UDim2.new(0, 130, 1, 0), nil,
        Theme.Colors.TextMuted, 12, Theme.Fonts.Medium)

    local inp = Theme.Input(row, "Inp", "Message to all players…",
        UDim2.new(0, 290, 0, 30))

    local btn = Theme.Button(row, "Send", "Send",
        UDim2.new(0, 70, 0, 30), nil, "primary")
    btn.MouseButton1Click:Connect(function()
        if inp.Text ~= "" then
            doCmd("announce", inp.Text)
            inp.Text = ""
        end
    end)
end

do
    local col = cmdPage
    sectionHeader(col, "Player Actions")
    cmdRow(col, "Ban Player",    "Player name",     "Reason…",   "ban",     "danger")
    cmdRow(col, "Unban UserId",  "UserId (number)", nil,          "unban",   "ghost")
    cmdRow(col, "Set Rank",      "Player name",     "Rank index", "setRank", "ghost")
    cmdRow(col, "Give Cash $",   "Player name",     "Amount",     "giveCash","success")
    cmdRow(col, "Give XP",       "Player name",     "Amount",     "giveXP",  "success")
    sectionHeader(col, "Server Actions")
    cmdRow(col, "Spawn NPCs",    "Faction",         "Count",      "spawnNPC","ghost")
    announceCmdRow(col)
end

-- ─── SERVER TAB ───────────────────────────────────────────────────────────────

local serverPage = tabPages["Server"]
Theme.ListLayout(serverPage, Enum.FillDirection.Vertical, 10)

sectionHeader(serverPage, "Server Info")

local statsContainer = Theme.Frame(serverPage, "Stats",
    UDim2.new(1, 0, 0, 100), nil, Theme.Colors.Surface)
Theme.Corner(statsContainer, Theme.Radius.Md)
Theme.Padding(statsContainer, 12)
Theme.ListLayout(statsContainer, Enum.FillDirection.Vertical, 6)
statsContainer.LayoutOrder = 2

local statPlayers = statusLabel(statsContainer, "StatPlayers")
local statNPCs    = statusLabel(statsContainer, "StatNPCs")
local statUptime  = statusLabel(statsContainer, "StatUptime")
local statTime    = statusLabel(statsContainer, "StatTime")

local refreshStatsBtn = Theme.Button(serverPage, "RefreshStats", "↻ Refresh Stats",
    UDim2.new(0, 140, 0, 30), nil, "muted")
refreshStatsBtn.LayoutOrder = 3
refreshStatsBtn.MouseButton1Click:Connect(function()
    local res = doCmd("serverStats")
    if res and res.ok and res.data then
        local d = res.data
        statPlayers.Text = "Players: " .. d.playerCount .. " / " .. d.maxPlayers
        statNPCs.Text    = "Active NPCs: " .. d.npcCount
        statUptime.Text  = "Server uptime: " .. math.floor(d.uptimeApprox/60) .. "m " .. (d.uptimeApprox%60) .. "s"
        statTime.Text    = "Server time: " .. os.date("%H:%M:%S", d.serverTime)
    end
end)

sectionHeader(serverPage, "Weather / Time").LayoutOrder = 4

local weatherRow = Theme.Frame(serverPage, "WeatherRow",
    UDim2.new(1, 0, 0, 36), nil, Color3.new(0,0,0), 1)
weatherRow.LayoutOrder = 5
Theme.ListLayout(weatherRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

for _, w in ipairs({"clear","fog","rain","storm","night","sunrise"}) do
    local b = Theme.Button(weatherRow, w, w:sub(1,1):upper()..w:sub(2),
        UDim2.new(0, 76, 0, 30), nil, "ghost")
    b.MouseButton1Click:Connect(function() doCmd("setWeather", w) end)
end

local timeRow = Theme.Frame(serverPage, "TimeRow",
    UDim2.new(1, 0, 0, 36), nil, Color3.new(0,0,0), 1)
timeRow.LayoutOrder = 6
Theme.ListLayout(timeRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

Theme.Label(timeRow, "TimeLbl", "Set time of day:",
    UDim2.new(0, 120, 1, 0), nil, Theme.Colors.TextMuted, 12, Theme.Fonts.Medium)

local timeInput = Theme.Input(timeRow, "TimeInp", "0–24",
    UDim2.new(0, 80, 0, 30))
local timeBtn = Theme.Button(timeRow, "TimeSet", "Set Hour",
    UDim2.new(0, 80, 0, 30), nil, "primary")
timeBtn.MouseButton1Click:Connect(function()
    doCmd("setTime", timeInput.Text)
    timeInput.Text = ""
end)

sectionHeader(serverPage, "NPC Control").LayoutOrder = 7

local npcRow = Theme.Frame(serverPage, "NPCRow",
    UDim2.new(1, 0, 0, 36), nil, Color3.new(0,0,0), 1)
npcRow.LayoutOrder = 8
Theme.ListLayout(npcRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left)

local clearNPCBtn = Theme.Button(npcRow, "ClearNPC", "Clear All NPCs",
    UDim2.new(0, 130, 0, 30), nil, "danger")
clearNPCBtn.MouseButton1Click:Connect(function() doCmd("clearNPCs") end)

-- ─── ECONOMY TAB ──────────────────────────────────────────────────────────────

local ecoPage = tabPages["Economy"]
Theme.ListLayout(ecoPage, Enum.FillDirection.Vertical, 10)

sectionHeader(ecoPage, "Give Resources")

local function ecoRow(parent, title, cmd, amountLabel)
    local row = Theme.Frame(parent, cmd .. "Row",
        UDim2.new(1, 0, 0, 40), nil, Color3.new(0,0,0), 1)
    row.LayoutOrder = #parent:GetChildren()
    Theme.ListLayout(row, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left)

    Theme.Label(row, "Lbl", title,
        UDim2.new(0, 140, 1, 0), nil, Theme.Colors.TextMuted, 12, Theme.Fonts.Medium)

    local nameInp = Theme.Input(row, "Name", "Player name", UDim2.new(0, 140, 0, 30))
    local amtInp  = Theme.Input(row, "Amt",  amountLabel,   UDim2.new(0, 100, 0, 30))

    local btn = Theme.Button(row, "Exec", "Give", UDim2.new(0, 70, 0, 30), nil, "success")
    btn.MouseButton1Click:Connect(function()
        doCmd(cmd, nameInp.Text, amtInp.Text)
        nameInp.Text = ""
        amtInp.Text  = ""
    end)
end

ecoRow(ecoPage, "Give Cash ($)",    "giveCash", "Amount")
ecoRow(ecoPage, "Give XP",          "giveXP",   "Amount")

-- ─── LOGS TAB ─────────────────────────────────────────────────────────────────

local logsPage = tabPages["Logs"]
Theme.ListLayout(logsPage, Enum.FillDirection.Vertical, 8)

sectionHeader(logsPage, "Recent Admin Actions")

local logScroll = Theme.Scroll(logsPage, "LogScroll",
    UDim2.new(1, 0, 0, 380))
logScroll.LayoutOrder = 2
Theme.ListLayout(logScroll, Enum.FillDirection.Vertical, 3)

local function buildLogRow(entry)
    local row = Theme.Frame(logScroll, "LogRow",
        UDim2.new(1, -4, 0, 32), nil, Theme.Colors.Surface)
    Theme.Corner(row, Theme.Radius.Sm)
    Theme.Padding(row, nil, 0, 8, 0, 10)

    local timeStr = os.date("%H:%M:%S", entry.time)
    Theme.Label(row, "Time", "[" .. timeStr .. "]",
        UDim2.new(0, 72, 1, 0), UDim2.new(0,0,0,0),
        Theme.Colors.TextSubtle, 11, Theme.Fonts.Mono)
    Theme.Label(row, "Actor", entry.actor,
        UDim2.new(0, 160, 1, 0), UDim2.new(0, 76, 0, 0),
        Theme.Colors.Primary, 11, Theme.Fonts.Bold)
    Theme.Label(row, "Action", entry.action,
        UDim2.new(0, 100, 1, 0), UDim2.new(0, 240, 0, 0),
        Theme.Colors.Info, 11, Theme.Fonts.Bold)
    Theme.Label(row, "Detail", entry.detail,
        UDim2.new(0, 250, 1, 0), UDim2.new(0, 344, 0, 0),
        Theme.Colors.TextMuted, 11, Theme.Fonts.Regular)
    return row
end

local refreshLogsBtn = Theme.Button(logsPage, "RefreshLogs", "↻ Refresh Logs",
    UDim2.new(0, 130, 0, 28), nil, "muted")
refreshLogsBtn.LayoutOrder = 3
refreshLogsBtn.MouseButton1Click:Connect(function()
    local res = invokeAdmin("AdminCommand", "viewLogs", "30")
    if res and res.ok and res.data then
        for _, c in ipairs(logScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, entry in ipairs(res.data) do
            buildLogRow(entry)
        end
    end
end)

-- ─── Open / close ─────────────────────────────────────────────────────────────

local isOpen = false

local function setOpen(open)
    isOpen = open
    sg.Enabled = open
    if open then
        activateTab("Players")
        refreshPlayers()
        win.Position = UDim2.new(0.5, -PANEL_W/2, 0.4, -PANEL_H/2)
        TweenService:Create(win,
            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2) }
        ):Play()
    end
end

closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
backdrop.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        setOpen(false)
    end
end)

-- Toggle key: F9
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.F9 then
        setOpen(not isOpen)
    end
end)

-- Remote: allow server or other UI to open panel
local OpenPanel = Instance.new("BindableFunction")
OpenPanel.Name  = "OpenOwnerPanel"
OpenPanel.Parent = LocalPlayer.PlayerGui
OpenPanel.OnInvoke = function() setOpen(true) end

print("[OwnerPanel] Loaded — F9 to toggle")
