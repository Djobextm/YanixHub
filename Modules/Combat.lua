local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Main

-- ==========================================
-- УМНЫЙ ПОИСК ЦЕЛИ (97% + ТОЧНОСТЬ)
-- ==========================================

local function GetBestTarget(role)
    local target = nil
    local nearestDist = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            -- Проверка на то, жив ли игрок
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                
                local isMur = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
                local isShr = p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Gun") or 
                               p.Character:FindFirstChild("Revolver") or p.Backpack:FindFirstChild("Revolver")

                if (role == "Murderer" and isMur) or (role == "Sheriff" and isShr) then
                    local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDist then
                        target = p.Character.Head
                        nearestDist = dist
                    end
                end
            end
        end
    end
    return target
end

-- ==========================================
-- ИНТЕРФЕЙС
-- ==========================================

Tab:AddToggle("SAim", {Title = "Silent Aim (Bullet Redirect)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("TAim", {Title = "Throw Aim (Ultra Knife)", Default = false}):OnChanged(function(v) _G.Config.ThrowAim = v end)
Tab:AddToggle("KAura", {Title = "Kill Aura (Murderer)", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- ==========================================
-- ГЛАВНЫЙ МЕХАНИЗМ (HOOKS)
-- ==========================================

-- 1. Перехват выстрела (ShootGun Remote)
-- Это исправляет проблему "стрельбы в стену"
local OldNamecall
OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and _G.Config.SilentAim and method == "FireServer" then
        if self.Name == "ShootGun" or self.Name == "Shoot" then
            local target = GetBestTarget("Murderer")
            if target then
                -- Подменяем координаты клика на координаты головы мардера
                args[1] = target.Position
                return OldNamecall(self, unpack(args))
            end
        end
    end
    return OldNamecall(self, ...)
end)

-- 2. Перехват Мышки (Для Броска ножа и визуальных лучей)
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() then
        if _G.Config.SilentAim and self == Mouse and (index == "Hit" or index == "Target") then
            local t = GetBestTarget("Murderer")
            if t then return (index == "Hit" and t.CFrame or t) end
        elseif _G.Config.ThrowAim and self == Mouse and (index == "Hit" or index == "Target") then
            local t = GetBestTarget("Sheriff")
            if t then return (index == "Hit" and t.CFrame or t) end
        end
    end
    return OldIndex(self, index)
end)

-- 3. Kill Aura (Touch Interest)
RunService.Stepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < 18 then
                    firetouchinterest(LP.Character.Knife.Handle, p.Character.HumanoidRootPart, 0)
                    firetouchinterest(LP.Character.Knife.Handle, p.Character.HumanoidRootPart, 1)
                end
            end
        end
    end
end)

return true
