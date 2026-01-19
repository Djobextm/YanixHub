local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

local originalTrans = {}

Tab:AddSlider("WS", {Title = "Speed", Default = 16, Min = 16, Max = 150, Callback = function(v) _G.Config.Speed = v end})
Tab:AddToggle("Fly", {Title = "Noclip Fly", Default = false}):OnChanged(function(v) _G.Config.Fly = v end)
Tab:AddToggle("XRay", {Title = "X-Ray", Default = false}):OnChanged(function(v)
    _G.Config.XRay = v
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character) then
            if v then
                if not originalTrans[obj] then originalTrans[obj] = obj.Transparency end
                obj.Transparency = 0.5
            else
                obj.Transparency = originalTrans[obj] or 0
            end
        end
    end
end)

Tab:AddToggle("FBright", {Title = "FullBright", Default = false}):OnChanged(function(v)
    if v then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    end
end)

-- НОВАЯ ФУНКЦИЯ: Anti-Fling
Tab:AddToggle("AFling", {Title = "Anti-Fling", Default = false}):OnChanged(function(v) 
    _G.Config.AntiFling = v 
end)

-- Основной цикл управления персонажем
RS.Stepped:Connect(function()
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local root = LP.Character.HumanoidRootPart
        local hum = LP.Character.Humanoid
        
        hum.WalkSpeed = _G.Config.Speed or 16
        
        -- Логика Anti-Fling
        if _G.Config.AntiFling then
            -- Сбрасываем опасную инерцию
            if root.Velocity.Magnitude > 75 or root.RotVelocity.Magnitude > 75 then
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
            
            -- Отключаем коллизии с частями других игроков
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LP and player.Character then
                    for _, part in pairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end

        -- Логика полета (Noclip)
        if _G.Config.Fly then
            for _, v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            root.Velocity = hum.MoveDirection * (_G.Config.Speed) + Vector3.new(0, 2, 0)
        end
    end
end)

return true
