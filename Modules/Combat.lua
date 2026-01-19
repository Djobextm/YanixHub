local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")

-- Настройки Prediction (Предсказание движения)
local PredictionAmount = 0.165 

-- Ожидание вкладки 'Main' из твоего UI.lua
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then
    warn("YanixHub: Вкладка 'Main' (Combat) не найдена!")
    return false
end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false

-- Функция поиска Мардера и расчета точки (Тело + Prediction)
local function GetPredictTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка: является ли игрок Мардером (нож в руках или рюкзаке)
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                local root = p.Character.HumanoidRootPart
                -- Рассчитываем позицию с учетом скорости игрока
                return root.Position + (root.Velocity * PredictionAmount)
            end
        end
    end
    return nil
end

-- Функция для мгновенного выстрела
local function ShootMurderer()
    local gun = LP.Character:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if gun then
        -- Авто-экипировка пистолета
        if gun.Parent == LP.Backpack then
            LP.Character.Humanoid:EquipTool(gun)
        end
        
        local hitPos = GetPredictTarget()
        if hitPos then
            local shootEvent = gun:FindFirstChild("ShootGun")
            if shootEvent and shootEvent:IsA("RemoteEvent") then
                shootEvent:FireServer(hitPos)
            end
        end
    end
end

-- --- СОЗДАНИЕ ЭКРАННОЙ КНОПКИ (Draggable) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixAimGui"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Name = "AimButton"
AimBtn.Size = UDim2.new(0, 130, 0, 45)
AimBtn.Position = UDim2.new(0.5, -65, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "SHOOT MURDERER"
AimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimBtn.Font = Enum.Font.SourceSansBold
AimBtn.TextSize = 14
AimBtn.Draggable = true -- Позволяет перемещать кнопку пальцем/мышкой
AimBtn.Active = true
AimBtn.Visible = false -- Скрыта по умолчанию

-- Визуал кнопки
local UICorner = Instance.new("UICorner", AimBtn)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", AimBtn)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 2

AimBtn.MouseButton1Click:Connect(ShootMurderer)

-- --- ИНТЕРФЕЙС В МЕНЮ ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim + Screen Button", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
    AimBtn.Visible = v -- Кнопка на экране появляется только при включении
end)

-- --- ЛОГИКА SILENT AIM (Через клики по экрану) ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Перехват стандартного события выстрела MM2
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
