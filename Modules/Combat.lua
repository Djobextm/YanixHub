local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Tab = (_G.Tabs and _G.Tabs.Combat) -- Исправление ошибки AddToggle

-- Проверка инициализации вкладки
if not Tab then
    warn("YanixHub: Вкладка Combat не найдена в _G.Tabs!")
    return false
end

-- Глобальные настройки (если еще не созданы)
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.KillAura = false

-- Функция поиска Мардера (строго по наличию ножа)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Мардер — это игрок с Knife в руках или рюкзаке
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- Функция поиска ближайшего игрока (для Kill Aura)
local function GetClosestPlayer(maxDist)
    local target = nil
    local lastDist = maxDist
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < lastDist then
                lastDist = dist
                target = p.Character
            end
        end
    end
    return target
end

-- --- ИНТЕРФЕЙС ---

Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Only Murderer)", 
    Default = false
}):OnChanged(function(v)
    _G.Config.SilentAim = v
end)

Tab:AddToggle("KillAura", {
    Title = "Kill Aura (Murderer Mode)", 
    Default = false
}):OnChanged(function(v)
    _G.Config.KillAura = v
end)

-- --- ЛОГИКА ---

-- 1. Silent Aim через перехват RemoteEvent
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- "ShootGun" — стандартное имя удаленного события стрельбы в MM2
    if tostring(self) == "ShootGun" and method == "FireServer" and _G.Config.SilentAim then
        local target = GetMurderer()
        if target then
            -- Подменяем координаты выстрела на позицию Мардера
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- 2. Цикл Kill Aura
task.spawn(function()
    while task.wait(0.2) do
        if _G.Config.KillAura and LP.Character then
            local knife = LP.Character:FindFirstChild("Knife")
            if knife and knife:IsA("Tool") then
                local targetChar = GetClosestPlayer(15) -- Радиус 15 студов
                if targetChar then
                    knife:Activate()
                    -- Попытка вызвать событие удара напрямую для надежности
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
