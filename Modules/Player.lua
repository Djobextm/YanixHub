local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Lighting = game:GetService("Lighting")
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

local originalTrans = {}

-- ФИКС: Добавлен Rounding = 1 для корректной работы слайдера
Tab:AddSlider("WS", {
    Title = "Speed", 
    Default = 16, 
    Min = 16, 
    Max = 150, 
    Rounding = 1, 
    Callback = function(v) _G.Config.Speed = v end
})

Tab:AddToggle("Fly", {Title = "Noclip Fly", Default = false}):OnChanged(function(v) _G.Config.Fly = v end)
Tab:AddToggle("AFling", {Title = "Anti-Fling", Default = false}):OnChanged(function(v) _G.Config.AntiFling = v end)
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

-- Безопасный цикл управления персонажем (Фикс "attempt to index nil")
RS.Stepped:Connect(function()
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local root = LP.Character.HumanoidRootPart
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            
            if hum then hum.WalkSpeed = _G.Config.Speed or 16 end
            
            -- Логика Anti-Fling
            if _G.Config.AntiFling then
                root.RotVelocity = Vector3.new(0,0,0) -- Сброс вращения
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        for _, part in pairs(p.Character:GetChildren()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end
            end

            -- Логика Fly / Noclip
            if _G.Config.Fly then
                for _, v in pairs(LP.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
                root.Velocity = hum.MoveDirection * (_G.Config.Speed or 16) + Vector3.new(0, 2, 0)
            end
        end
    end)
end)

return true
