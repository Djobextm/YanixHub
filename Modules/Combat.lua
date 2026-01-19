local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Настройки Remi Prediction
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

if not Tab then return false end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.SilentAimButton = false

-- --- ФУНКЦИЯ ПОИСКА ЦЕЛИ (REMI LOGIC) ---
local function GetRemiTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на Мардера (тело)
            local hasKnife = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if hasKnife then
                local root = p.Character.HumanoidRootPart
                -- Если Мардер стоит — стреляем точно в него, если бежит — на опережение
                if root.Velocity.Magnitude < 1 then
                    return root.Position
                end
                return root.Position + (root.Velocity * PredictionAmount)
            end
        end
    end
    return nil
end

-- --- ГАРАНТИРОВАННЫЙ ВЫСТРЕЛ (REMI SHOOT) ---
local function ShootMurderer()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- 1. Достаем пистолет
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.2) -- Задержка для регистрации экипировки
        end
        
        local hitPos = GetRemiTarget()
        if hitPos then
            -- 2. ВИРТУАЛЬНАЯ АКТИВАЦИЯ (Имитация клика по экрану)
            gun:Activate()
            
            -- 3. Прямой вызов события выстрела
            local shootEvent = gun:FindFirstChild("ShootGun")
            if shootEvent and shootEvent:IsA("RemoteEvent") then
                shootEvent:FireServer(hitPos)
            end
            
            -- Дополнительный Bypass для MM2
            local mainRemote = ReplicatedStorage:FindFirstChild("ShootGun", true)
            if mainRemote and mainRemote:IsA("RemoteEvent") then
                mainRemote:FireServer(hitPos)
            end
        end
    end
end

-- --- ЭКРАННАЯ КНОПКА (REMI BUTTON) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixRemiShootGui"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Name = "RemiShootButton"
AimBtn.Size = UDim2.new(0, 140, 0, 45)
AimBtn.Position = UDim2.new(0.5, -70, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "REMI SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
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

-- --- ИНТЕРФЕЙС FLUENT ---

Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Remi Prediction)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

Tab:AddToggle("RemiBtn", {
    Title = "Show Remi Shoot Button", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAimButton = v
    AimBtn.Visible = v
end)

-- --- ЛОГИКА ПАССИВНОГО SILENT AIM (Namecall) ---
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
