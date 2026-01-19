local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

-- Инициализация вкладок из глобальной таблицы
local Tab = _G.Tabs.Main

-- ==========================================
-- ФУНКЦИИ ПОИСКА ЦЕЛЕЙ
-- ==========================================

-- Поиск Мардера для Шерифа (Silent Aim)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                return p.Character.Head
            end
        end
    end
    return nil
end

-- Поиск жертв для Мардера (Kill Aura)
local function GetNearestVictim()
    local nearest, dist = nil, 20 -- Радиус ауры 20 стадов
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < dist then 
                nearest = p.Character.HumanoidRootPart
                dist = d 
            end
        end
    end
    return nearest
end

-- Поиск Шерифа/Героя для броска ножа (Throw Aim)
local function GetSheriff()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            if p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun") or 
               p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver") then
                return p.Character.Head
            end
        end
    end
    return nil
end

-- ==========================================
-- ИНТЕРФЕЙС
-- ==========================================

Tab:AddToggle("SAim", {Title = "Silent Aim (Gun)", Default = false}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

Tab:AddToggle("TAim", {Title = "Throw Aim (Knife)", Default = false}):OnChanged(function(v) 
    _G.Config.ThrowAim = v 
end)

Tab:AddToggle("KAura", {Title = "Kill Aura (Murderer)", Default = false}):OnChanged(function(v) 
    _G.Config.KillAura = v 
end)

-- ==========================================
-- ЛОГИКА (ХУКИ И ЦИКЛЫ)
-- ==========================================

-- Kill Aura: Работает через прикосновение рукоятки ножа к игроку
RunService.Stepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        local target = GetNearestVictim()
        if target then
            firetouchinterest(LP.Character.Knife.Handle, target, 0)
            firetouchinterest(LP.Character.Knife.Handle, target, 1)
        end
    end
end)

-- Silent Aim & Throw Aim: Перехват цели через __index
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if self == Mouse and (index == "Hit" or index == "Target") then
        -- Если мы Шериф и стреляем
        if _G.Config.SilentAim then
            local target = GetMurderer()
            if target then
                return (index == "Hit" and target.CFrame or target)
            end
        end
        
        -- Если мы Мардер и кидаем нож
        if _G.Config.ThrowAim then
            local target = GetSheriff()
            if target then
                return (index == "Hit" and target.CFrame or target)
            end
        end
    end
    return OldIndex(self, index)
end)

return true
