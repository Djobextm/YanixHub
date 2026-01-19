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

-- --- СОЗДАНИЕ ТАЙМЕРА (GUI) ---
local TimerGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
TimerGui.Name = "YanixTimerGui"

local TimerLabel = Instance.new("TextLabel", TimerGui)
TimerLabel.Name = "RoundTimer"
TimerLabel.Size = UDim2.new(0, 160, 0, 35)
TimerLabel.Position = UDim2.new(0.5, -80, 0, 15) -- Сверху по центру
TimerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TimerLabel.BackgroundTransparency = 0.3
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = 16
TimerLabel.Visible = false

local UICorner = Instance.new("UICorner", TimerLabel)
UICorner.CornerRadius = UDim.new(0, 10)

local UIStroke = Instance.new("UIStroke", TimerLabel)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- --- ЛОГИКА ОБНОВЛЕНИЯ ТАЙМЕРА ---
RunService.RenderStepped:Connect(function()
    if _G.Config.ShowRoundTimer then
        -- MM2 хранит время в StringValue внутри ReplicatedStorage
        local timerObj = ReplicatedStorage:FindFirstChild("Timer", true)
        if timerObj and timerObj:IsA("StringValue") then
            local timeText = timerObj.Value
            if timeText ~= "" then
                TimerLabel.Text = "⏱️ Time: " .. timeText
                TimerLabel.Visible = true
            else
                TimerLabel.Text = "Waiting for Round..."
                TimerLabel.Visible = true
            end
        else
            TimerLabel.Visible = false
        end
    else
        TimerLabel.Visible = false
    end
end)

-- --- ИНТЕРФЕЙС (Fluent) ---
Tab:AddToggle("RoundTimerToggle", {
    Title = "Show Round Timer",
    Description = "Отображает время раунда вверху экрана",
    Default = false
}):OnChanged(function(v)
    _G.Config.ShowRoundTimer = v
end)

-- Дополнительная полезная функция для Misc (например, FullBright)
Tab:AddButton({
    Title = "FullBright",
    Description = "Убирает тени и делает всё ярким",
    Callback = function()
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
        game:GetService("Lighting").GlobalShadows = false
    end
})

return true
