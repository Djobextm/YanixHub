local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Ждем вкладку 'Main' из твоего UI.lua
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then
    warn("YanixHub: Вкладка не найдена!")
    return false
end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.KillAura = false

-- Функция поиска Мардера (нацеливание на ТЕЛО)
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверяем наличие ножа
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                return p.Character.HumanoidRootPart -- Возвращаем туловище
            end
        end
    end
    return nil
end

-- Поиск цели для Kill Aura (дистанция 15)
local function GetClosestPlayer()
    local target, lastDist = nil, 15
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
Tab:AddToggle("SilentAim", {Title = "Silent Aim (Body Target)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("KillAura", {Title = "Kill Aura (Murderer)", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- --- ULTIMATE SILENT AIM ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Перехватываем событие ShootGun
    if _G.Config.SilentAim and tostring(self) == "ShootGun" and method == "FireServer" then
        local targetPart = GetMurderer()
        if targetPart then
            -- Направляем пулю строго в центр тела Мардера
            args[1] = targetPart.Position
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- --- KILL AURA ---
task.spawn(function()
    while task.wait(0.1) do
        if _G.Config.KillAura and LP.Character then
            local knife = LP.Character:FindFirstChild("Knife")
            if knife and knife:IsA("Tool") then
                local target = GetClosestPlayer()
                if target then
                    knife:Activate()
                    local slash = knife:FindFirstChild("Slash") or knife:FindFirstChild("Stab")
                    if slash then slash:FireServer(target.HumanoidRootPart.Position) end
                end
            end
        end
    end
end)

return true
