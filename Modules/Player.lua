local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

-- 1. НАСТРОЙКИ СКОРОСТИ (Speed)
Tab:AddSlider("SpeedSlider", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(v) _G.Config.Speed = v end
})

-- 2. НАСТРОЙКИ ПРЫЖКА (Jump)
Tab:AddSlider("JumpSlider", {
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 250,
    Rounding = 1,
    Callback = function(v) _G.Config.Jump = v end
})

-- 3. NOCLIP (Проход сквозь стены)
Tab:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(v)
    _G.Config.Noclip = v
end)

-- 4. ANTI-FLING (Защита от толкания и раскрутки)
Tab:AddToggle("AntiFlingToggle", {Title = "Anti-Fling", Default = false}):OnChanged(function(v)
    _G.Config.AntiFling = v
end)

-- ГЛАВНЫЙ ЦИКЛ ОБРАБОТКИ (Без X-Ray)
RS.Stepped:Connect(function()
    pcall(function()
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            local root = LP.Character:FindFirstChild("HumanoidRootPart")

            if hum then
                -- Применение Speed и Jump
                hum.WalkSpeed = _G.Config.Speed or 16
                hum.JumpPower = _G.Config.Jump or 50
                hum.UseJumpPower = true
            end

            if root then
                -- Логика Noclip (Отключаем коллизию персонажа)
                if _G.Config.Noclip then
                    for _, part in pairs(LP.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end

                -- Логика Anti-Fling
                if _G.Config.AntiFling then
                    -- Обнуляем физические силы, которые могут заставить персонажа летать
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                    
                    -- Отключаем коллизию с другими игроками, чтобы они не могли вас толкнуть
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            for _, pPart in pairs(p.Character:GetChildren()) do
                                if pPart:IsA("BasePart") then
                                    pPart.CanCollide = false
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end)

return true
