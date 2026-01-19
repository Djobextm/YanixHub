local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ожидание вкладки 'Misc' из твоего UI.lua
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Misc then
        Tab = _G.Tabs.Misc
        break
    end
    task.wait(0.5)
end

if not Tab then
    warn("YanixHub: Вкладка 'Misc' не найдена!")
    return false
end

_G.Config = _G.Config or {}
_G.Config.ShowRoundTimer = false

-- --- СОЗДАНИЕ GUI ТАЙМЕРА (CoreGui) ---
-- Удаляем старый, если остался от прошлых запусков
if game:GetService("CoreGui"):FindFirstChild("YanixTimerSystem") then
    game:GetService("CoreGui").YanixTimerSystem:Destroy()
end

local TimerGui = Instance.new("ScreenGui")
TimerGui.Name = "YanixTimerSystem"
TimerGui.Parent = game:GetService("CoreGui")
TimerGui.DisplayOrder = 999
TimerGui.ResetOnSpawn = false

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Parent = TimerGui
TimerLabel.Size = UDim2.new(0, 160, 0, 35)
TimerLabel.Position = UDim2.new(0.5, -80, 0, 45) -- По центру сверху
TimerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TimerLabel.BackgroundTransparency = 0.2
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = 16
TimerLabel.Text = "⏱️ Loading..."
TimerLabel.Visible = false

local UICorner = Instance.new("UICorner", TimerLabel)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", TimerLabel)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5

-- --- ЛОГИКА ПОИСКА ТАЙМЕРА MM2 ---
local function UpdateTimer()
    if not _G.Config.ShowRoundTimer then 
        TimerLabel.Visible = false
        return 
    end

    -- Поиск объекта таймера. В MM2 это обычно StringValue с именем 'Timer'
    local timerObj = ReplicatedStorage:FindFirstChild("Timer", true)
    
    if timerObj then
        local value = ""
        if timerObj:IsA("StringValue") then
            value = timerObj.Value
        elseif timerObj:IsA("TextLabel") then
            value = timerObj.Text
        end

        if value ~= "" then
            TimerLabel.Text = "⏱️ " .. value
            TimerLabel.Visible = true
        else
            TimerLabel.Text = "⏱️ Waiting..."
            TimerLabel.Visible = true
        end
    else
        -- Если объект еще не создан сервером
        TimerLabel.Text = "⏱️ Intermission"
        TimerLabel.Visible = true
    end
end

-- Обновление каждую секунду (для экономии ресурсов)
task.spawn(function()
    while true do
        UpdateTimer()
        task.wait(0.5)
    end
end)

-- --- ИНТЕРФЕЙС FLUENT ---

Tab:AddParagraph({
    Title = "Полезные функции",
    Content = "Различные настройки игрового процесса"
})

local TimerToggle = Tab:AddToggle("RoundTimerToggle", {
    Title = "Show Round Timer",
    Description = "Показывает время раунда вверху экрана",
    Default = false
})

TimerToggle:OnChanged(function()
    _G.Config.ShowRoundTimer = TimerToggle.Value
    TimerLabel.Visible = TimerToggle.Value
end)

Tab:AddSection("Окружение")

Tab:AddButton({
    Title = "FullBright",
    Description = "Максимальная яркость (убирает темноту)",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") then
                v.Enabled = false
            end
        end
    end
})

Tab:AddButton({
    Title = "Anti-Lag",
    Description = "Убирает визуальные эффекты для повышения FPS",
    Callback = function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                v.Enabled = false
            end
        end
    end
})

return true
