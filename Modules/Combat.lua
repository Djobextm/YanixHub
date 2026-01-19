local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")

local Tab = _G.Tabs.Main

-- Функция поиска цели (SnapSanix Style)
local function GetTarget(Role)
    local Target = nil
    local Distance = math.huge
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local IsMur = v.Character:FindFirstChild("Knife") or v.Backpack:FindFirstChild("Knife")
                local IsShr = v.Character:FindFirstChild("Gun") or v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Revolver") or v.Backpack:FindFirstChild("Revolver")
                
                local Match = false
                if Role == "Murderer" and IsMur then Match = true end
                if Role == "Sheriff" and IsShr then Match = true end
                
                if Match then
                    local Mag = (LP.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if Mag < Distance then
                        Distance = Mag
                        Target = v.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return Target
end

Tab:AddToggle("SAim", {Title = "Silent Aim (Safe Redirect)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("TAim", {Title = "Throw Aim (Ultra Knife)", Default = false}):OnChanged(function(v) _G.Config.ThrowAim = v end)
Tab:AddToggle("KAura", {Title = "Kill Aura (Legit)", Default = false}):OnChanged(function(v) _G.Config.KillAura = v end)

-- Перехват наведения без ошибок в консоли
local OldIndex
OldIndex = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and (index == "Hit" or index == "Target") and self == Mouse then
        if _G.Config.SilentAim then
            local T = GetTarget("Murderer")
            if T then return (index == "Hit" and T.CFrame or T) end
        end
        if _G.Config.ThrowAim then
            local T = GetTarget("Sheriff")
            if T then return (index == "Hit" and T.CFrame or T) end
        end
    end
    return OldIndex(self, index)
end)

-- Оптимизированная Аура
RunService.RenderStepped:Connect(function()
    if _G.Config.KillAura and LP.Character and LP.Character:FindFirstChild("Knife") then
        local Knife = LP.Character.Knife
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                if (LP.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude < 16 then
                    firetouchinterest(v.Character.HumanoidRootPart, Knife.Handle, 0)
                    firetouchinterest(v.Character.HumanoidRootPart, Knife.Handle, 1)
                end
            end
        end
    end
end)

return true
