local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

-- Хранилище для восстановления прозрачности
local transparencyCache = {}

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

-- 3. X-RAY (Просвечивание стен без багов моделей)
Tab:AddToggle("XRayToggle", {Title = "X-Ray", Default = false}):OnChanged(function(v)
    _G.Config.XRay = v
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Обрабатываем только обычные детали (Part), чтобы не было белых кубов на месте мешей
        if obj:IsA("Part") and not obj:IsDescendantOf(LP.Character) then
            if v then
                if not transparencyCache[obj] then transparencyCache[obj] = obj.Transparency end
                obj.Transparency = 0.5
            else
                obj.Transparency = transparencyCache[obj] or 0
            end
        end
    end
end)

-- 4. NOCLIP (Проход сквозь стены)
Tab:AddToggle("NoclipToggle", {Title = "Noclip", Default = false}):OnChanged(function(v)
    _G.Config.Noclip = v
end)

-- 5. ANTI-FLING (Защита от толкания и раскрутки)
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
                -- Применение Speed и Jump
                hum.WalkSpeed = _G.Config.Speed or 16
                hum.JumpPower = _G.Config.Jump or 50
                hum.UseJumpPower = true
            end

            if root then
                -- Логика Noclip
                if _G.Config.Noclip then
                    for _, part in pairs(LP.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end

                -- Логика Anti-Fling
                if _G.Config.AntiFling then
                    root.Velocity = Vector3.new(0, 0, 0)
                    root.RotVelocity = Vector3.new(0, 0, 0)
                    -- Отключаем коллизию с другими игроками для предотвращения флинга
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
