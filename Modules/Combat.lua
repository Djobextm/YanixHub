local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Tab = _G.Tabs.Combat

-- Переменные для работы функций
_G.Config.SilentAim = false
_G.Config.KillAura = false

-- Вспомогательная функция поиска Мардера (для Сайлент Аима)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка ножа в руках или рюкзаке
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- Вспомогательная функция поиска ближайшей цели (для Килл Ауры, если ты Мардер)
local function GetClosestPlayer(dist)
    local target = nil
    local lastDist = dist
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < lastDist then
                lastDist = d
                target = p.Character
            end
        end
    end
    return target
end

-- --- ИНТЕРФЕЙС ---

-- Silent Aim (Только на Мардера)
Tab:AddToggle("SilentAim", {Title = "Silent Aim (Target: Murderer)", Default = false}):OnChanged(function(v)
    _G.Config.SilentAim = v
end)

-- Kill Aura (Авто-удар ножом)
Tab:AddToggle("KillAura", {Title = "Kill Aura (If Murderer)", Default = false}):OnChanged(function(v)
    _G.Config.KillAura = v
end)

-- --- ЛОГИКА ---

-- 1. Перехват выстрела (Silent Aim)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Перехватываем событие стрельбы
    if tostring(self) == "ShootGun" and method == "FireServer" and _G.Config.SilentAim then
        local target = GetMurderer()
        if target then
            -- Меняем направление пули точно в HumanoidRootPart Мардера
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- 2. Цикл Kill Aura (срабатывает каждые 0.1 сек)
task.spawn(function()
    while task.wait(0.1) do
        if _G.Config.KillAura then
            -- Проверяем, есть ли у нас нож в руках
            local knife = LP.Character:FindFirstChild("Knife")
            if knife and knife:IsA("Tool") then
                local targetChar = GetClosestPlayer(15) -- Дистанция 15 studs
                if targetChar then
                    -- Активируем нож (удар)
                    knife:Activate()
                    -- Для некоторых версий MM2 требуется вызов Remote
                    local slash = knife:FindFirstChild("Slash") or knife:FindFirstChild("Stab")
                    if slash and slash:IsA("RemoteEvent") then
                        slash:FireServer(targetChar.HumanoidRootPart.Position)
                    end
                end
            end
        end
    end
end)

return true
