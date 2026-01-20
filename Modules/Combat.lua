local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")

-- Конфигурация
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true
_G.Config.ShowBtn = false

-- Ожидание вкладки Main из UI
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

-- --- ФУНКЦИЯ РАСЧЕТА ЦЕЛИ (REMI PREDICTION) ---
local function GetRemiTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на Мардера (наличие ножа)
            local isMurderer = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            if isMurderer then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Динамический пинг
                local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                local predictTime = 0.145 + ping
                
                -- Точка попадания с упреждением
                local predictedPos = root.Position + (velocity * predictTime)
                
                -- Наводим чуть выше центра (в торс/голову)
                return predictedPos + Vector3.new(0, 0.8, 0)
            end
        end
    end
    return nil
end

-- --- ГАРАНТИРОВАННЫЙ ВЫСТРЕЛ (REMI SHOOT) ---
local function ExecuteShoot()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if gun then
        -- Авто-экипировка
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3) -- Задержка для регистрации в руках
        end
        
        -- Виртуальный клик (симуляция нажатия на экран/мышку)
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.03)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- ГЛАВНЫЙ ХУК: ПОДМЕНА МЫШКИ (__index) ---
-- Этот хук заставляет скрипт пистолета верить, что мышка на Мардере
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if _G.Config.SilentAim and not checkcaller() and self == Mouse then
        if key == "Hit" then
            local pos = GetRemiTarget()
            if pos then
                return CFrame.new(pos)
            end
        elseif key == "Target" then
            local pos = GetRemiTarget()
            if pos then
                -- Возвращаем любую часть Мардера
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character and p.Character:FindFirstChild("Knife") then
                        return p.Character.HumanoidRootPart
                    end
                end
            end
        end
    end
    return oldIndex(self, key)
end)

-- --- ВТОРОЙ ХУК: ПОДМЕНА СОБЫТИЯ (__namecall) ---
-- Перехват пакета ShootGun для полной уверенности
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if _G.Config.SilentAim and method == "FireServer" and tostring(self) == "ShootGun" then
        local pos = GetRemiTarget()
        if pos then
            args[1] = pos -- Заменяем координаты клика на координаты Мардера
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)

-- --- UI КНОПКА (REMI SHOOT) ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 160, 0, 55)
AimBtn.Position = UDim2.new(0.5, -80, 0.7, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "REMI SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 16
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true

local UICorner = Instance.new("UICorner", AimBtn)
UICorner.CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", AimBtn)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 2

AimBtn.MouseButton1Click:Connect(ExecuteShoot)

-- --- FLUENT SETTINGS ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Magic Bullet)", 
    Description = "Стреляет в Мардера, даже если ты смотришь в пол",
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

Tab:AddToggle("ShowRemiBtn", {
    Title = "Show Remi Shoot Button", 
    Default = false
}):OnChanged(function(v) 
    AimBtn.Visible = v 
end)

return true
