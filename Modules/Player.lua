local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

local originalTrans = {}

-- Фикс: Обязательный параметр Rounding для слайдера
Tab:AddSlider("WS", {
    Title = "Speed", 
    Default = 16, 
    Min = 16, 
    Max = 150, 
    Rounding = 1, 
    Callback = function(v) _G.Config.Speed = v end
})

Tab:AddToggle("Fly", {Title = "Noclip Fly", Default = false}):OnChanged(function(v) _G.Config.Fly = v end)

-- Безопасный X-Ray (не создает фантомные блоки)
Tab:AddToggle("XRay", {Title = "X-Ray (Safe)", Default = false}):OnChanged(function(v)
    _G.Config.XRay = v
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Не трогаем HumanoidRootPart и меши, чтобы не появлялись белые коробки
        if obj:IsA("BasePart") and not obj:IsDescendantOf(LP.Character) then
            if obj.Name ~= "HumanoidRootPart" and not obj:IsA("MeshPart") then
                if v then
                    if not originalTrans[obj] then originalTrans[obj] = obj.Transparency end
                    obj.Transparency = 0.5
                else
                    obj.Transparency = originalTrans[obj] or 0
                end
            end
        end
    end
end)

-- Цикл обновлений с защитой от ошибок nil
RS.Stepped:Connect(function()
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = _G.Config.Speed or 16
                
                if _G.Config.Fly then
                    LP.Character.HumanoidRootPart.Velocity = hum.MoveDirection * (_G.Config.Speed or 16) + Vector3.new(0, 2, 0)
                    for _, part in pairs(LP.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end
    end)
end)

return true
