local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

-- 1. СКОРОСТЬ (WalkSpeed)
Tab:AddSlider("SpeedSlider", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(v) _G.Config.Speed = v end
})

-- 2. ПРЫЖОК (JumpPower)
Tab:AddSlider("JumpSlider", {
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 250,
    Rounding = 1,
    Callback = function(v) _G.Config.Jump = v end
})

-- 3. СКВОЗЬ СТЕНЫ (Noclip)
Tab:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(v)
    _G.Config.Noclip = v
end)

-- 4. АНТИ-ТОЛКАНИЕ (Anti-Fling)
Tab:AddToggle("AntiFlingToggle", {Title = "Anti-Fling", Default = false}):OnChanged(function(v)
    _G.Config.AntiFling = v
end)

-- ГЛАВНЫЙ ЦИКЛ ОБРАБОТКИ
RS.Stepped:Connect(function()
    pcall(function()
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            local root = LP.Character:FindFirstChild("HumanoidRootPart")

            if hum then
                -- Применяем настройки скорости и прыжка
                hum.WalkSpeed = _G.Config.Speed or 16
                hum.JumpPower = _G.Config.Jump or 50
                hum.UseJumpPower = true -- Обязательно для MM2
            end

            if root then
                -- NOCLIP: Отключаем коллизию только у твоего персонажа
                -- Это НЕ создает белых блоков на карте, так как не трогает workspace
                if _G.Config.Noclip then
                    for _, part in pairs(LP.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end

                -- ANTI-FLING: Защита от раскрутки
                if _G.Config.AntiFling then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end)
end)

return true
