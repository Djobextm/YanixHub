local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")

-- Настройки предсказания
local BasePrediction = 0.14 -- Оптимально для MM2
local Gravity = 196.2

-- Ожидание вкладки Main
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
_G.Config.PingComp = true

-- --- ФУНКЦИЯ РАСЧЕТА ТРАЕКТОРИИ (REMI LOGIC) ---
local function GetPrecisionTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Ищем Мардера (наличие ножа)
            local isMurderer = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if isMurderer then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Компенсация пинга
                local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                local timeScale = BasePrediction + ping
                
                -- Предсказание позиции
                local predictedPos = root.Position + (velocity * timeScale)
                
                -- Если цель прыгает, корректируем по Y
                if math.abs(velocity.Y) > 0.5 then
                    predictedPos = predictedPos + Vector3.new(0, (0.5 * Gravity * timeScale^2), 0)
                end
                
                -- Целимся точно в центр хитбокса
                return predictedPos + Vector3.new(0, 0.5, 0)
            end
        end
    end
    return nil
end

-- --- ФУНКЦИЯ КНОПКИ (ВЫСТРЕЛ БЕЗ ПОВОРОТА) ---
local function ShootMurderer()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- 1. Достаем пистолет если нужно
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3) -- Задержка для MM2
        end
        
        -- 2. ВИРТУАЛЬНЫЙ КЛИК
        -- Мы просто жмем на курок. Камера может смотреть куда угодно.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- СОЗДАНИЕ КНОПКИ (REMI SHOOT) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixShootUI"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Name = "RemiShoot"
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "REMI SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Draggable = true
AimBtn.Active = true
AimBtn.Visible = false

local UICorner = Instance.new("UICorner", AimBtn)
local UIStroke = Instance.new("UIStroke", AimBtn)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 2

AimBtn.MouseButton1Click:Connect(ShootMurderer)

-- --- ИНТЕРФЕЙС FLUENT ---

Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Raycast Hook)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

Tab:AddToggle("PingComp", {
    Title = "Ping Compensation", 
    Default = true
}):OnChanged(function(v) 
    _G.Config.PingComp = v 
end)

Tab:AddToggle("ShowBtn", {
    Title = "Show Remi Button", 
    Default = false
}):OnChanged(function(v) 
    AimBtn.Visible = v 
end)

-- --- ТОТ САМЫЙ ХУК (МАГИЧЕСКИЕ ПУЛИ) ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Когда скрипт или игрок стреляет (событие ShootGun)
    if _G.Config.SilentAim and tostring(self) == "ShootGun" and method == "FireServer" then
        local targetPos = GetPrecisionTarget()
        if targetPos then
            -- ПОДМЕНА: Неважно куда ты стрелял, сервер получит координаты Мардера
            args[1] = targetPos 
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)

return true
