local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Имитация клика
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Параметры точности (Remi Logic)
local BasePrediction = 0.125
local Gravity = 196.2

-- Поиск вкладки Main из твоего UI
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

-- Инициализация конфига
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true
_G.Config.ShowBtn = false

-- --- ФУНКЦИЯ РАСЧЕТА ЦЕЛИ (ULTRA PRECISION REMI) ---
local function GetPrecisionTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка: является ли игрок Мардером
            local isMurderer = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if isMurderer then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Динамический пинг компенсатор
                local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                local timeScale = BasePrediction + ping
                
                -- Основное предсказание (Позиция + Скорость * Время)
                local predictedPos = root.Position + (velocity * timeScale)
                
                -- Коррекция прыжка (параболическая траектория)
                if math.abs(velocity.Y) > 0.5 then
                    predictedPos = predictedPos + Vector3.new(0, (0.5 * Gravity * timeScale^2), 0)
                end
                
                -- Возвращаем точку в центр торса (чуть ниже головы)
                return predictedPos + Vector3.new(0, 0.8, 0)
            end
        end
    end
    return nil
end

-- --- ГАРАНТИРОВАННЫЙ ВЫСТРЕЛ (FIXED BUTTON LOGIC) ---
local function ShootMurderer()
    local char = LP.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- 1. Экипировка пистолета
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3) -- Пауза, чтобы сервер MM2 разрешил выстрел
        end
        
        local targetPos = GetPrecisionTarget()
        if targetPos then
            -- 2. ВИРТУАЛЬНЫЙ КЛИК (Имитируем нажатие на центр экрана)
            -- Это заставляет локальный скрипт пистолета сработать штатно
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            
            -- 3. ПРЯМОЙ ВЫЗОВ (На случай, если клик не прошел фильтр)
            local event = gun:FindFirstChild("ShootGun")
            if event then
                event:FireServer(targetPos)
            end
        end
    end
end

-- --- ЭКРАННАЯ КНОПКА (REMI BUTTON) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixCombatUI"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.75, 0)
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
    Title = "Ultra Silent Aim (Remi)", 
    Default = false
}):OnChanged(function(v) 
    _G.Config.SilentAim = v 
end)

Tab:AddToggle("PingComp", {
    Title = "Ping Compensation", 
    Description = "Авто-подстройка под лаги",
    Default = true
}):OnChanged(function(v) 
    _G.Config.PingComp = v 
end)

Tab:AddToggle("ShowBtn", {
    Title = "Remi Shoot Button", 
    Default = false
}):OnChanged(function(v) 
    AimBtn.Visible = v 
end)

-- --- ХУК SILENT AIM (ПЕРЕХВАТ ВЫСТРЕЛА) ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Перехватываем выстрел, вызванный кликом или вручную
    if _G.Config.SilentAim and tostring(self) == "ShootGun" and method == "FireServer" then
        local pos = GetPrecisionTarget()
        if pos then
            args[1] = pos -- Подменяем координаты на предсказанные Remi
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)

return true
