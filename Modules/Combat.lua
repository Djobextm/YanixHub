local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- --- КОНФИГУРАЦИЯ ---
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true
_G.Config.Prediction = 0.135 -- Базовое упреждение

-- Ожидание загрузки UI
local Tab = nil
for i = 1, 20 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end
if not Tab then return false end

-- --- СОЗДАНИЕ ВИЗУАЛЬНОЙ МЕТКИ (КРУЖОК) ---
local DotGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
DotGui.Name = "YanixVisuals"
DotGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Dot = Instance.new("Frame", DotGui)
Dot.Name = "PredictionDot"
Dot.AnchorPoint = Vector2.new(0.5, 0.5) -- Центрируем якорь
Dot.Size = UDim2.new(0, 12, 0, 12) -- Размер
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Красный цвет
Dot.Visible = false

local UICorner = Instance.new("UICorner", Dot)
UICorner.CornerRadius = UDim.new(1, 0) -- Делаем круглым
local UIStroke = Instance.new("UIStroke", Dot)
UIStroke.Color = Color3.new(1, 1, 1) -- Белая обводка
UIStroke.Thickness = 2

-- --- ФУНКЦИЯ ПОИСКА ЦЕЛИ И РАСЧЕТА ---
local function GetTargetPos()
    -- Используем pcall для защиты от ошибок доступа
    local success, result = pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                -- Проверка на Мардера
                if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                    local root = p.Character.HumanoidRootPart
                    local velocity = root.Velocity
                    
                    -- Расчет упреждения (Пинг + База)
                    local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                    local totalPredict = _G.Config.Prediction + ping
                    
                    -- Итоговая позиция: Текущая + (Скорость * Время) + Смещение в центр
                    local finalPos = root.Position + (velocity * totalPredict) + Vector3.new(0, 0.5, 0)
                    return finalPos
                end
            end
        end
        return nil
    end)
    if success then return result else return nil end
end

-- --- ОБНОВЛЕНИЕ ПОЗИЦИИ МЕТКИ ---
RunService.RenderStepped:Connect(function()
    if not _G.Config.SilentAim then
        Dot.Visible = false
        return
    end

    local targetPos = GetTargetPos()
    if targetPos then
        -- Переводим 3D координаты мира в 2D координаты экрана
        local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(targetPos)
        if onScreen then
            Dot.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
            Dot.Visible = true
        else
            Dot.Visible = false
        end
    else
        Dot.Visible = false
    end
end)

-- --- ЕДИНСТВЕННЫЙ БЕЗОПАСНЫЙ ХУК (MAGIC BULLET) ---
-- Этот метод работает на большинстве мобильных экзекуторов без крашей
local mt = getrawmetatable(game)
setreadonly(mt, false)
local old_nc = mt.__namecall

mt.__namecall = newcclosure(function(self, ...)
    local namecall_method = getnamecallmethod()
    local args = {...}

    -- Безопасная проверка условия
    local isShootEvent = (namecall_method == "FireServer" and self.Name == "ShootGun")

    if _G.Config.SilentAim and isShootEvent then
        local targetPos = GetTargetPos()
        if targetPos then
            -- ПОДМЕНА: Заменяем координаты клика на предсказанные координаты Мардера
            args[1] = targetPos
            return old_nc(self, unpack(args))
        end
    end

    return old_nc(self, ...)
end)
setreadonly(mt, true)

-- --- ФУНКЦИЯ КНОПКИ ВЫСТРЕЛА ---
local function ForceShoot()
    local char = LP.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3)
        end
        -- Виртуальный клик
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- СОЗДАНИЕ КНОПКИ ---
local AimBtn = Instance.new("TextButton", DotGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "MAGIC SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 16
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", AimBtn).Color = Color3.new(1, 0, 0)

AimBtn.MouseButton1Click:Connect(ForceShoot)

-- --- FLUENT ИНТЕРФЕЙС ---
Tab:AddToggle("SilentAim", {Title = "Silent Aim (Delta Fix)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("PingComp", {Title = "Ping Compensation", Default = true}):OnChanged(function(v) _G.Config.PingComp = v end)
Tab:AddSlider("Prediction", {Title = "Prediction Amount", Default = 0.135, Min = 0.1, Max = 0.2, Rounding = 3}):OnChanged(function(v) _G.Config.Prediction = v end)
Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) AimBtn.Visible = v end)

return true
