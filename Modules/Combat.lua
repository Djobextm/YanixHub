local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Main

-- Функция поиска цели (Туловище + Бесконечный радиус)
local function GetTarget()
    local target = nil
    local shortestDist = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            -- Безопасная проверка наличия HumanoidRootPart
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            
            if root and hum and hum.Health > 0 then
                -- Проверка, является ли игрок Мардером (наличие ножа)
                local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                
                if isMur then
                    local dist = (LP.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = root -- Целимся в туловище
                    end
                end
            end
        end
    end
    return target
end

Tab:AddToggle("SAim", {Title = "Silent Aim (Body + Dist)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("KAura", {Title = "Kill Aura", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- РЕАЛИЗАЦИЯ: Подмена Mouse.Hit (Пример 1)
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and self == Mouse and (index == "Hit" or index == "Target") then
        if _G.Config.SilentAim then
            local t = GetTarget()
            if t then
                -- Возвращаем позицию цели напрямую, обходя проверку дистанции сервера
                return (index == "Hit" and t.CFrame or t)
            end
        end
    end
    return OldIndex(self, index)
end)

-- Kill Aura (Через Touched - Пример 3)
RunService.Stepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        local knife = LP.Character.Knife:FindFirstChild("Handle")
        if knife then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    if (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude < 16 then
                        firetouchinterest(p.Character.HumanoidRootPart, knife, 0)
                        firetouchinterest(p.Character.HumanoidRootPart, knife, 1)
                    end
                end
            end
        end
    end
end)

return true
