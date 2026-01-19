local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

-- Инициализация вкладки
local Tab = _G.Tabs.Player

-- ==========================================
-- ИНТЕРФЕЙС
-- ==========================================

Tab:AddSlider("WSpeed", {
    Title = "Скорость бега",
    Default = 16, Min = 16, Max = 150, Rounding = 1,
    Callback = function(v) _G.Config.Speed = v end
})

Tab:AddSlider("JPow", {
    Title = "Сила прыжка",
    Default = 50, Min = 50, Max = 200, Rounding = 1,
    Callback = function(v) _G.Config.Jump = v end
})

Tab:AddToggle("InfJump", {Title = "Бесконечный прыжок", Default = false}):OnChanged(function(v) 
    _G.Config.InfJump = v 
end)

Tab:AddToggle("FlyMode", {Title = "Полёт через стены (Noclip Fly)", Default = false}):OnChanged(function(v) 
    _G.Config.Fly = v 
end)

-- ==========================================
-- ЛОГИКА
-- ==========================================

-- Обработка бесконечного прыжка
UIS.JumpRequest:Connect(function()
    if _G.Config.InfJump and LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
        LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Основной цикл обновления характеристик и Полета
RunService.Stepped:Connect(function()
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            local hum = LP.Character.Humanoid
            local root = LP.Character.HumanoidRootPart

            -- Применяем скорость и прыжок
            hum.WalkSpeed = _G.Config.Speed or 16
            hum.JumpPower = _G.Config.Jump or 50

            -- Логика Полета + NoClip
            if _G.Config.Fly then
                -- Отключаем столкновения со стенами
                for _, part in pairs(LP.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end

                -- Удержание в воздухе и перемещение
                local moveDir = hum.MoveDirection
                root.Velocity = moveDir * (_G.Config.Speed * 1.5) + Vector3.new(0, 2, 0)
                
                -- Поддержка высоты (чтобы не падать)
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    root.Velocity = root.Velocity + Vector3.new(0, 50, 0)
                elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    root.Velocity = root.Velocity + Vector3.new(0, -50, 0)
                end
            end
        end
    end)
end)

return true
