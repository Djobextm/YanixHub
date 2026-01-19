local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- Ждем загрузку вкладок
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and (_G.Tabs.Player or _G.Tabs.Main) then
        Tab = _G.Tabs.Player or _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

_G.Config = _G.Config or {}
_G.Config.WalkSpeed = 16
_G.Config.JumpPower = 50
_G.Config.AntiFling = false

-- --- ФУНКЦИИ ---

-- Функция отключения коллизии с другими игроками
local function UpdateAntiFling()
    if not _G.Config.AntiFling then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            for _, part in pairs(LP.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    for _, otherPart in pairs(player.Character:GetChildren()) do
                        if otherPart:IsA("BasePart") then
                            -- Создаем временный запрет на столкновение
                            local constraint = Instance.new("NoCollisionConstraint")
                            constraint.Part0 = part
                            constraint.Part1 = otherPart
                            constraint.Parent = part
                            game:GetService("Debris"):AddItem(constraint, 0.1)
                        end
                    end
                end
            end
        end
    end
end

-- --- ИНТЕРФЕЙС ---

Tab:AddSection("Характеристики")

Tab:AddInput("SpeedInput", {
    Title = "Скорость бега",
    Default = "16",
    Numeric = true,
    Finished = true,
    Callback = function(v) _G.Config.WalkSpeed = tonumber(v) or 16 end
})

Tab:AddParagraph({Title = "💡 Инфо", Content = "Безопасно: 16-25. Выше 30 — риск кика."})

Tab:AddSection("Защита")

-- Кнопка Anti-Fling
Tab:AddToggle("AntiFlingToggle", {
    Title = "Anti-Fling (No Collision)",
    Default = false
}):OnChanged(function(v)
    _G.Config.AntiFling = v
    if not v then
        -- Если выключили, можно сделать ресет или просто подождать
        print("Anti-Fling выключен")
    end
end)

Tab:AddParagraph({Title = "🛡️ Как это работает", Content = "Убирает коллизию с другими игроками. Они не смогут тебя толкнуть или зафлингать."})

-- --- ЦИКЛЫ ---

-- Основной цикл для скорости и анти-флинга
RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        -- Поддержка скорости
        LP.Character.Humanoid.WalkSpeed = _G.Config.WalkSpeed
        LP.Character.Humanoid.JumpPower = _G.Config.JumpPower
        LP.Character.Humanoid.UseJumpPower = true
        
        -- Работа Anti-Fling
        if _G.Config.AntiFling then
            UpdateAntiFling()
            -- Дополнительная защита: обнуление угловой скорости (Velocity)
            if LP.Character:FindFirstChild("HumanoidRootPart") then
                LP.Character.HumanoidRootPart.CanCollide = true -- Твой пол остается твердым
                -- Отключаем физическое воздействие от других
                for _, v in pairs(LP.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Velocity = Vector3.new(0, v.Velocity.Y, 0)
                        v.RotVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
    end
end)

return true
