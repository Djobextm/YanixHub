local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Настройки Remi Prediction
local PredictionAmount = 0.165 
local RemiEnabled = true -- По умолчанию включен режим Remi в логике

-- Ожидание вкладки 'Main' из UI.lua
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.SilentAimButton = false

-- Функция расчета точки (Remi Prediction Logic)
local function GetRemiTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на Мардера
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Логика Remi: игнорирование мелких колебаний и расчет по вектору движения
                if velocity.Magnitude < 1 then
                    return root.Position
                end
                
                return root.Position + (velocity * PredictionAmount)
            end
        end
    end
    return nil
end

-- ИСПРАВЛЕННАЯ ФУНКЦИЯ АВТО-ВЫСТРЕЛА
local function ShootMurderer()
    local gun = LP.Character:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- 1. Достаем пистолет, если он в рюкзаке
        if gun.Parent == LP.Backpack then
            LP.Character.Humanoid:EquipTool(gun)
            task.wait(0.2) -- Увеличенная задержка для регистрации экипировки сервером
        end
        
        local hitPos = GetRemiTarget()
        if hitPos then
            -- 2. ГАРАНТИРОВАННЫЙ ВЫСТРЕЛ
            -- Имитируем активацию (нажатие)
            gun:Activate()
            
            -- Находим удаленное событие выстрела
            local shootEvent = gun:FindFirstChild("ShootGun")
            if shootEvent and shootEvent:IsA("RemoteEvent") then
                -- Отправляем сигнал выстрела в предсказанную точку
                shootEvent:FireServer(hitPos)
                
                -- Дополнительный вызов для некоторых версий MM2 (Remi Bypass)
                local remote = ReplicatedStorage:FindFirstChild("ShootGun", true)
                if remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(hitPos)
                end
            end
        end
    end
end

-- --- ЭКРАННАЯ КНОПКА (Draggable) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixRemiGui"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Name = "AimButton"
AimBtn.Size = UDim2.new(0, 140, 0, 45)
AimBtn.Position = UDim2.new(0.5, -70, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
AimBtn.Text = "REMI SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
AimBtn.Font = Enum.Font.GothamBold
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

Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Remi Prediction)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

Tab:AddToggle("SilentAimBtnToggle", {
    Title = "Remi Shoot Button (Screen)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAimButton = v
    AimBtn.Visible = v
end)

-- --- ЛОГИКА ПАССИВНОГО SILENT AIM (NAME_CALL) ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if _G.Config.SilentAim and tostring(self) == "ShootGun" and method == "FireServer" then
        local hitPos = GetRemiTarget()
        if hitPos then
            args[1] = hitPos
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

return true
