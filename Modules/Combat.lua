local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Ждем, пока основная таблица вкладок будет готова, чтобы не было ошибки nil
local Tab = nil
for i = 1, 10 do
    if _G.Tabs and _G.Tabs.Combat then
        Tab = _G.Tabs.Combat
        break
    end
    task.wait(0.5)
end

if not Tab then
    warn("YanixHub: Ошибка! Вкладка Combat не найдена в _G.Tabs. Проверь главный скрипт.")
    return false
end

-- Инициализация конфига
_G.Config = _G.Config or {}
_G.Config.SilentAim = false

-- Функция поиска Мардера (только игроки с ножом)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверяем нож в руках или в рюкзаке
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- Создание кнопки (AddToggle теперь не будет nil)
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Target: Murderer)", 
    Default = false
}):OnChanged(function(v)
    _G.Config.SilentAim = v
end)

-- Безопасный Silent Aim через hookmetamethod
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- "ShootGun" — событие выстрела в MM2
    if tostring(self) == "ShootGun" and method == "FireServer" and _G.Config.SilentAim then
        local target = GetMurderer()
        if target then
            -- Подменяем координаты цели на позицию Мардера
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

return true
