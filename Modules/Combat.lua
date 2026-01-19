local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Main

-- Поиск цели (Пример 2: Передача объекта цели)
local function GetTarget(role)
    local target = nil
    local shortestDist = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root and p.Character:FindFirstChildOfClass("Humanoid") and p.Character.Humanoid.Health > 0 then
                local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun")
                
                if (role == "Murderer" and isMur) or (role == "Sheriff" and isShr) then
                    local dist = (LP.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = root
                    end
                end
            end
        end
    end
    return target
end

Tab:AddToggle("SAim", {Title = "Silent Aim (Mouse.Hit)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("KAura", {Title = "Kill Aura (Touched)", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- РЕАЛИЗАЦИЯ ПРИМЕРА 1 (Server-trusted Mouse.Hit)
-- Исправляет ошибку GunClient Line 64/69
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and (index == "Hit" or index == "Target") and self == Mouse then
        if _G.Config.SilentAim then
            local t = GetTarget("Murderer")
            if t then 
                -- Сервер верит этим данным без проверки line-of-sight
                return (index == "Hit" and t.CFrame or t) 
            end
        end
    end
    return OldIndex(self, index)
end)

-- РЕАЛИЗАЦИЯ ПРИМЕРА 3 (firetouchinterest = 100% Kill Aura)
RunService.Stepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude < 16 then
                    firetouchinterest(p.Character.HumanoidRootPart, LP.Character.Knife.Handle, 0)
                    firetouchinterest(p.Character.HumanoidRootPart, LP.Character.Knife.Handle, 1)
                end
            end
        end
    end
end)

return true
