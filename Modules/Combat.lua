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
    warn("YanixHub: Вкладка 'Main' не найдена! Проверь UI.lua")
    return false
end

-- Инициализация конфига
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.KillAura = false

-- Поиск Мардера для Silent Aim
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- Поиск ближайшего игрока для Kill Aura (дистанция 15 studs)
local function GetClosestPlayer()
    local target = nil
    local lastDist = 15
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
    Title = "Silent Aim (Target: Murderer)", 
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

-- 1. Silent Aim (Проброс выстрела в Мардера)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if tostring(self) == "ShootGun" and method == "FireServer" and _G.Config.SilentAim then
        local target = GetMurderer()
        if target then
            args[1] = target.Position
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

-- 2. Kill Aura (Авто-атака ножом)
task.spawn(function()
    while task.wait(0.1) do
        if _G.Config.KillAura and LP.Character then
            -- Ищем нож в руках
            local knife = LP.Character:FindFirstChild("Knife")
            if knife and knife:IsA("Tool") then
                local target = GetClosestPlayer()
                if target then
                    knife:Activate()
                    -- Удаленный вызов для регистрации урона
                    local slash = knife:FindFirstChild("Slash") or knife:FindFirstChild("Stab")
                    if slash then
                        slash:FireServer(target.HumanoidRootPart.Position)
                    end
                end
            end
        end
    end
end)

return true
