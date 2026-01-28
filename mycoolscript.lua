local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Network = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"))
local Replication = require(ReplicatedStorage:WaitForChild("Game"):WaitForChild("Replication"))

local EWGG = "Lightning Event"
local POSITION = Vector3.new(1228, 5380, -13109)
local BPOSITION = Vector3.new(-435, 15385, 110)
local HOLOGRAPHIC_POS = Vector3.new(1343, 5342, -13003)
local CHOSEN = (math.random() < 0.5) and POSITION or BPOSITION
local LABEL = (CHOSEN == BPOSITION) and "group b" or "group a"
local HATCH_COOLDOWN = 0.1
local WEBHOOK_URL = "hhttps://discord.com/api/webhooks/1465873288931573985/7saUqEutsrIYFzZJ0higowWCMa7VxrwH-QtBmjmYIxXleXgYKrVyIx61yp5H0-66K56U"

local DEEEEBUG = false
local CONSOLE = false
local uhoH = false

math.randomseed(os.time())

do
    if CONSOLE == true then
        local StarterGui = game:GetService("StarterGui")
        local open = false
        open = not open
        pcall(function()
            StarterGui:SetCore("DevConsoleVisible", open)
        end)
    end
end


local function enable_error_hook(overlay)
    local StarterGui = game:GetService("StarterGui")
    local ScriptContext = game:GetService("ScriptContext")
    ScriptContext.Error:Connect(function()
        if uhoH then
            return
        end
        uhoH = true
        if overlay and overlay.bg then
            overlay.bg.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
            overlay.bg.BackgroundTransparency = 0.3
        end
        pcall(function()
            StarterGui:SetCore("DevConsoleVisible", true)
        end)
    end)
end

local function get_hatch_amount(data)
    local activeBoosts = (type(data) == "table" and type(data.ActiveBoosts) == "table") and data.ActiveBoosts or {}
    if activeBoosts["Octo Incubator"] or activeBoosts.OctoHatch then
        return 8
    end
    local gamepasses = (type(data) == "table" and type(data.Gamepasses) == "table") and data.Gamepasses or {}
    if gamepasses.x8Egg == true then
        return 8
    end
    return 3
end

local function get_eggs_count(data)
    local stats = data and data.Statistics
    local eggs = tonumber(stats and stats.Eggs) or 0
    local lp = Players.LocalPlayer
    local ls = lp and lp:FindFirstChild("leaderstats")
    local lsEggs = ls and ls:FindFirstChild("Eggs")
    if lsEggs and lsEggs.Value ~= nil then
        eggs = tonumber(lsEggs.Value) or eggs
    end
    return eggs
end

local function build_overlay()
    local lp = Players.LocalPlayer
    if not lp then return nil end
    local gui = lp:WaitForChild("PlayerGui"):FindFirstChild("StandaloneOverlay")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
    gui.Name = "StandaloneOverlay"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999999
    gui.Parent = lp:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.Parent = gui


    local hpmLabel = Instance.new("TextLabel")
    hpmLabel.BackgroundTransparency = 1
    hpmLabel.Size = UDim2.new(0, 900, 0, 60)
    hpmLabel.Position = UDim2.new(0.5, -450, 0.5, -70)
    hpmLabel.Font = Enum.Font.GothamBlack
    hpmLabel.TextSize = 36
    hpmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpmLabel.Text = "HPM: -- | --"
    hpmLabel.Parent = bg

    local statsLabel = Instance.new("TextLabel")
    statsLabel.BackgroundTransparency = 1
    statsLabel.Size = UDim2.new(0, 900, 0, 60)
    statsLabel.Position = UDim2.new(0.5, -450, 0.5, -10)
    statsLabel.Font = Enum.Font.GothamBlack
    statsLabel.TextSize = 34
    statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statsLabel.Text = "htch amt: -- | --"
    statsLabel.Parent = bg

    local groupLabel = Instance.new("TextLabel")
    groupLabel.BackgroundTransparency = 1
    groupLabel.Size = UDim2.new(0, 900, 0, 50)
    groupLabel.Position = UDim2.new(0.5, -450, 0.5, 55)
    groupLabel.Font = Enum.Font.GothamBlack
    groupLabel.TextSize = 30
    groupLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    groupLabel.Text = tostring(LABEL)
    groupLabel.Parent = bg

    return { gui = gui, bg = bg, hpm = hpmLabel, stats = statsLabel, group = groupLabel }
end

local function sendWebhook(text)
    if type(WEBHOOK_URL) ~= "string" or WEBHOOK_URL == "" then
        return
    end
    local payload = {
        username = "thething",
        content = text,
    }
    local body = HttpService:JSONEncode(payload)
    local req = (syn and syn.request)
        or (http_request)
        or (request)
        or (http and http.request)
    if req then
        pcall(function()
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
        return
    end
    pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, body)
    end)
end

while not Replication.Loaded do
    task.wait(0.2)
end

local overlay = build_overlay()
enable_error_hook(overlay)
local lastHpmValue = nil
local samples = {}
local function updateHpm(eggs)
    local now = os.clock()
    samples[#samples + 1] = { t = now, v = eggs }
    local cutoff = now - 60
    while #samples > 0 and samples[1].t < cutoff do
        table.remove(samples, 1)
    end
    if #samples < 2 then
        return nil
    end
    local oldest = samples[1]
    local dt = now - oldest.t
    if dt <= 0 then
        return nil
    end
    return (eggs - oldest.v) / (dt / 60)
end

local function teleport_world(target)
    pcall(function()
        Network:InvokeServer("TeleportWorld", target)
    end)
end

local didWorldSwitch = false
local function wereinworld2yesS()
    if didWorldSwitch then
        return true
    end
    teleport_world("Space")
    for _ = 1, 20 do
        task.wait(0.5)
        local data = Replication and Replication.Data
        local world = tostring((data and (data.World or data.WorldName)) or "")
        if world == "2" or world == "Space" then
            didWorldSwitch = true
            return true
        end
    end
    return false
end

task.spawn(function()
    while true do
        task.wait(HATCH_COOLDOWN)
        if DEEEEBUG == true then
            print("it happened")
        end
        local lp = Players.LocalPlayer
        local ch = lp and lp.Character
        local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
        if root then
            if LABEL == "group a" then
                if wereinworld2yesS() then
                    root.CFrame = CFrame.new(HOLOGRAPHIC_POS)
                end
            else
                root.CFrame = CFrame.new(CHOSEN)
            end
        end
        pcall(function()
            local data = Replication and Replication.Data
            local amount = get_hatch_amount(data)
            if not amount or amount < 1 then amount = 1 end
            local ok, res = pcall(function()
                return Network:InvokeServer("OpenEgg", EWGG, amount, {})
            end)
            if (not ok) then
                local ok2, res2 = pcall(function()
                    return Network:InvokeServer("OpenEgg", EWGG, 1, {})
                end)
                if DEEEEBUG == true then
                    warn(string.format("fallback 1x ok=%s res=%s", tostring(ok2), tostring(res2)))
                end
            end
            if DEEEEBUG == true then
                warn(string.format("egg=%s amount=%s ok=%s res=%s", tostring(EWGG), tostring(amount), tostring(ok), tostring(res)))
            end
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.25)
        local data = Replication and Replication.Data
        local eggs = get_eggs_count(data)
        local hpm = updateHpm(eggs)
        if overlay then
            local data = Replication and Replication.Data
            local amount = get_hatch_amount(data)
            local zone = tostring((data and data.Zone) or "--")
            local world = tostring((data and (data.World or data.WorldName)) or "--")
            overlay.stats.Text = string.format("htch amt: %sx | %s", tostring(amount), zone)
            if hpm then
                local hpmInt = math.floor(hpm + 0.5)
                lastHpmValue = hpmInt
                overlay.hpm.Text = string.format("HPM: %d | %s", hpmInt, world)
            else
                lastHpmValue = nil
                overlay.hpm.Text = string.format("HPM: -- | %s", world)
            end
            if overlay.group then
                overlay.group.Text = tostring(LABEL)
            end
        end
    end
end)

task.spawn(function()
    do
        local data = Replication and Replication.Data
        local eggs = get_eggs_count(data)
        local lp = Players.LocalPlayer
        local uname = lp and lp.Name or "unknown"
        local hpmText = lastHpmValue and tostring(lastHpmValue) or "--"
        local msg = string.format("%s | HPM: %s | tptal: %s", uname, hpmText, tostring(eggs))
        sendWebhook(msg)
    end
    while true do
        task.wait(300)
        local delay = math.random(1, 30)
        task.wait(delay)
        local data = Replication and Replication.Data
        local eggs = get_eggs_count(data)
        local lp = Players.LocalPlayer
        local uname = lp and lp.Name or "unknown"
        local hpmText = lastHpmValue and tostring(lastHpmValue) or "--"
        local msg = string.format("%s | HPM: %s | total: %s", uname, hpmText, tostring(eggs))
        sendWebhook(msg)
    end
end)
