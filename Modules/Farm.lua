local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Инициализация вкладки
local Tab = _G.Tabs.Farm

-- ==========================================
-- НАСТРОЙКИ И ИНТЕРФЕЙС
-- ==========================================

Tab:AddToggle("AFarm", {Title = "Smooth Fly Farm (NoClip)", Default = false}):OnChanged(function(v) 
    _G.Config.AutoFarm = v 
end)

Tab:AddSlider("FWait", {
    Title = "Скорость полета (плавность)", 
    Default = 0.15, Min = 0.05, Max = 0.5, Rounding = 2,
    Callback = function(v) _G.Config.FarmWait = v end
})

-- ==========================================
-- ЛОГИКА ПОЛЕТА И NOCLIP
-- ==========================================

-- Постоянный NoClip во время фарма
RunService.Stepped:Connect(function()
    if _G.Config.AutoFarm and LP.Character then
        for _, part in pairs(LP.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Основной цикл фарма
task.spawn(function()
    while task.wait() do
        pcall(function()
            if _G.Config.AutoFarm and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local root = LP.Character.HumanoidRootPart
                
                -- Поиск контейнера с монетами в MM2
                local coinContainer = workspace:FindFirstChild("CoinContainer", true)
                if coinContainer then
                    local targetCoin = coinContainer:FindFirstChildWhichIsA("Part", true)
                    
                    if targetCoin then
                        -- Плавное перемещение (Lerp) сквозь стены
                        -- 0.15 - это скорость. Чем выше, тем быстрее летит.
                        local speed = _G.Config.FarmWait or 0.15
                        root.CFrame = root.CFrame:Lerp(targetCoin.CFrame, speed)
                        
                        -- Обнуляем гравитацию, чтобы не падать при полете
                        root.Velocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
    end
end)

return true
