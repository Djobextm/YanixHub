local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Main

-- ==========================================
-- УМНЫЙ ПОИСК ЦЕЛИ (Input Validation)
-- ==========================================
local function GetTarget(role)
    local target = nil
    local shortestDistance = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- Проверка ролей
                local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun") or 
                               p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")

                if (role == "Murderer" and isMur) or (role == "Sheriff" and isShr) then
                    local distance = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        target = p.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return target
end

-- Элементы интерфейса
Tab:AddToggle("SAim", {Title = "Silent Aim (Input Trust)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("TAim", {Title = "Throw Aim (Safe)", Default = false}):OnChanged(function(v) _G.Config.ThrowAim = v end)
Tab:AddToggle("KAura", {Title = "Kill Aura (Legit)", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- ==========================================
-- SERVER-TRUSTED INPUT MANIPULATION (HOOK)
-- ==========================================
-- Этот метод исправляет ошибку "Unable to cast CoordinateFrame to bool" на строке 69
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and (index == "Hit" or index == "Target") and self == Mouse then
        if _G.Config.SilentAim then
            local murderer = GetTarget("Murderer")
            if murderer then
                -- Подменяем "Hit" (куда смотрит пуля) на CFrame цели
                return (index == "Hit" and murderer.CFrame or murderer)
            end
        end
        
        if _G.Config.ThrowAim then
            local sheriff = GetTarget("Sheriff")
            if sheriff then
                return (index == "Hit" and sheriff.CFrame or sheriff)
            end
        end
    end
    return OldIndex(self, index)
end)

-- ==========================================
-- KILL AURA (OPTIMIZED)
-- ==========================================
RunService.Stepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        local knife = LP.Character.Knife
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                -- Проверка дистанции для стабильного срабатывания
                if (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude < 16 then
                    firetouchinterest(p.Character.HumanoidRootPart, knife.Handle, 0)
                    firetouchinterest(p.Character.HumanoidRootPart, knife.Handle, 1)
                end
            end
        end
    end
end)

return true
