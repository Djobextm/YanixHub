local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local Tab = _G.Tabs.Player

local storage = {}

-- Фикс слайдера
Tab:AddSlider("WS", {Title = "Speed", Default = 16, Min = 16, Max = 150, Rounding = 1, Callback = function(v) _G.Config.Speed = v end})

-- Безопасный X-Ray (Больше никаких белых объектов на карте)
Tab:AddToggle("XRay", {Title = "Safe X-Ray", Default = false}):OnChanged(function(v)
    _G.Config.XRay = v
    for _, obj in pairs(workspace:GetDescendants()) do
        -- Игнорируем MeshPart, Union и части персонажей
        if obj:IsA("Part") and not obj:IsDescendantOf(LP.Character) then
            if v then
                if not storage[obj] then storage[obj] = obj.Transparency end
                obj.Transparency = 0.6
            else
                obj.Transparency = storage[obj] or 0
            end
        end
    end
end)

RS.Stepped:Connect(function()
    pcall(function()
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = _G.Config.Speed or 16
        end
    end)
end)

return true
