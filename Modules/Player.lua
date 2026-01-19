local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- Ждем загрузку вкладок из _G.Tabs (Fluent)
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and (_G.Tabs.Player or _G.Tabs.Main) then
        Tab = _G.Tabs.Player or _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

-- Конфиг
_G.Config = _G.Config or {}
_G.Config.WalkSpeed = 16
_G.Config.JumpPower = 50
_G.Config.AntiFling = false

-- --- ФУНКЦИИ ---

local function ApplyAntiFling()
    if not _G.Config.AntiFling or not LP.Character then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            for _, myPart in pairs(LP.Character:GetChildren()) do
                if myPart:IsA("BasePart") then
                    for _, otherPart in pairs(player.Character:GetChildren()) do
                        if otherPart:IsA("BasePart") then
                            local constraint = Instance.new("NoCollisionConstraint")
                            constraint.Part0 = myPart
                            constraint.Part1 = otherPart
                            constraint.Parent = myPart
                            game:GetService("Debris"):AddItem(constraint, 0.05)
                        end
                    end
                end
            end
        end
    end
end

-- --- ИНТЕРФЕЙС (Fluent Syntax) ---

local SpeedInput = Tab:AddInput("SpeedInput", {
    Title = "Скорость бега",
    Default = "16",
    Placeholder = "Введите число...",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        _G.Config.WalkSpeed = tonumber(Value) or 16
    end
})

Tab:AddParagraph({
    Title = "💡 Рекомендация по скорости",
    Content = "Стандарт: 16\nБезопасно: 20-25\nСвыше 30: Возможны вылеты (кики) в MM2."
})

local JumpInput = Tab:AddInput("JumpInput", {
    Title = "Сила прыжка",
    Default = "50",
    Placeholder = "Введите число...",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        _G.Config.JumpPower = tonumber(Value) or 50
    end
})

Tab:AddParagraph({
    Title = "💡 Рекомендация по прыжкам",
    Content = "Стандарт: 50\nОптимально: 60-65."
})

-- Разделитель для красоты в Fluent
Tab:AddParagraph({Title = "--- Защита ---", Content = ""})

local AntiFlingToggle = Tab:AddToggle("AntiFlingToggle", {
    Title = "Anti-Fling (No-Collision)", 
    Default = false 
})

AntiFlingToggle:OnChanged(function()
    _G.Config.AntiFling = AntiFlingToggle.Value
end)

Tab:AddParagraph({
    Title = "🛡️ Описание Anti-Fling",
    Content = "Убирает коллизию с другими игроками. Вас нельзя будет столкнуть с места или убить флингом."
})

-- Дополнительная кнопка для заполнения места (чтобы скролл работал)
Tab:AddButton({
    Title = "Reset Character",
    Description = "Мгновенная смерть",
    Callback = function()
        if LP.Character then LP.Character:BreakJoints() end
    end
})

-- --- ЛОГИКА ---

RunService.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        hum.WalkSpeed = _G.Config.WalkSpeed
        hum.JumpPower = _G.Config.JumpPower
        hum.UseJumpPower = true
        
        if _G.Config.AntiFling then
            ApplyAntiFling()
            local root = LP.Character:FindFirstChild("HumanoidRootPart")
            if root then
                -- Обнуляем физическое вращение от ударов других игроков
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)

return true
