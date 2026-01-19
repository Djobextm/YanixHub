local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- Настройки Prediction
local PredictionAmount = 0.165 

-- Ожидание вкладки 'Main' из UI.lua
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then
    warn("YanixHub: Вкладка 'Main' не найдена!")
    return false
end

-- Инициализация конфига
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.SilentAimButton = false

-- Функция расчета точки (Тело + Prediction)
local function GetPredictTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                local root = p.Character.HumanoidRootPart
                return root.Position + (root.Velocity * PredictionAmount)
            end
        end
    end
    return nil
end

-- Функция для выстрела (используется кнопкой)
local function ShootMurderer()
    local gun = LP.Character:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if gun then
        if gun.Parent == LP.Backpack then
            LP.Character.Humanoid:EquipTool(gun)
        end
        local hitPos = GetPredictTarget()
        if hitPos then
            local shootEvent = gun:FindFirstChild("ShootGun")
            if shootEvent then shootEvent:FireServer(hitPos) end
        end
    end
end

-- --- СОЗДАНИЕ ЭКРАННОЙ КНОПКИ ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixAimButtonGui"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Name = "AimButton"
AimBtn.Size = UDim2.new(0, 130, 0, 45)
AimBtn.Position = UDim2.new(0.5, -65, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "SHOOT MURDERER"
AimBtn.TextColor3 = Color3.new(1, 1, 1)
AimBtn.Font = Enum.Font.SourceSansBold
AimBtn.TextSize = 14
AimBtn.Draggable = true
AimBtn.Active = true
AimBtn.Visible = false 

local UICorner = Instance.new("UICorner", AimBtn)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", AimBtn)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 2

AimBtn.MouseButton1Click:Connect(ShootMurderer)

-- --- ИНТЕРФЕЙС В МЕНЮ ---

-- 1. Пассивный Silent Aim (для обычных выстрелов)
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Passive)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

-- 2. Отдельная функция для экранной кнопки
Tab:AddToggle("SilentAimBtnToggle", {
    Title = "Silent Aim Button (Screen)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAimButton = v
    AimBtn.Visible = v -- Кнопка зависит только от этого тумблера
end)

-- --- ЛОГИКА ---

-- Логика пассивного Silent Aim (только если включен SilentAim)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if _G.Config.SilentAim and tostring(self) == "ShootGun" and method == "FireServer" then
        local hitPos = GetPredictTarget()
        if hitPos then
            args[1] = hitPos
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

return true
