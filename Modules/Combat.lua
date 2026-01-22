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
for i = 1, 30 do -- Увеличил время ожидания
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end
if not Tab then return false end

-- --- СОЗДАНИЕ ВИЗУАЛЬНОЙ МЕТКИ (КРУЖОК) ---
if _G.DotGui then _G.DotGui:Destroy() end -- Удаляем старый, если есть
_G.DotGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
_G.DotGui.Name = "YanixVisuals_Fixed"
_G.DotGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Dot = Instance.new("Frame", _G.DotGui)
Dot.Name = "TargetDot"
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.Size = UDim2.new(0, 14, 0, 14) -- Чуть больше
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.Visible = false

local UICorner = Instance.new("UICorner", Dot)
UICorner.CornerRadius = UDim.new(1, 0)
local UIStroke = Instance.new("UIStroke", Dot)
UIStroke.Color = Color3.new(255, 255, 255)
UIStroke.Thickness = 2

-- --- ФУНКЦИЯ ПОИСКА МАРДЕРА ---
-- isForShooting = true (для выстрела, с упреждением)
-- isForShooting = false (для кружка, точно на торсе)
local function GetMurdererPos(isForShooting)
    local success, result = pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                -- Проверка на Мардера
                if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                    local root = p.Character.HumanoidRootPart
                    
                    if isForShooting then
                        -- РАСЧЕТ УПРЕЖДЕНИЯ ДЛЯ ВЫСТРЕЛА
                        local velocity = root.Velocity
                        local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                        local totalPredict = _G.Config.Prediction + ping
                        -- Целимся в верхнюю часть торса
                        return root.Position + (velocity * totalPredict) + Vector3.new(0, 1, 0)
                    else
                        -- ТОЧНАЯ ПОЗИЦИЯ ДЛЯ КРУЖКА
                        return root.Position
                    end
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

    -- Получаем позицию БЕЗ упреждения, чтобы кружок был на торсе
    local targetPos = GetMurdererPos(false)
    if targetPos then
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

-- --- ФУНКЦИЯ ВЫСТРЕЛА (DELTA-SAFE SILENT AIM) ---
local function ForceShoot()
    local char = LP.Character
    if not char or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- 1. Экипировка
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.2) -- Небольшая задержка
        end
        
        -- 2. Получаем позицию С УПРЕЖДЕНИЕМ
        local targetPos = GetMurdererPos(true)
        if targetPos then
            local cam = Workspace.CurrentCamera
            local oldCFrame = cam.CFrame -- Запоминаем куда смотрели
            
            -- 3. МГНОВЕННЫЙ ПОВОРОТ КАМЕРЫ НА ЦЕЛЬ
            cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
            
            -- 4. ВИРТУАЛЬНЫЙ КЛИК
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            RunService.RenderStepped:Wait() -- Ждем один кадр
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            
            -- 5. ВОЗВРАТ КАМЕРЫ (Очень быстро, незаметно для глаза)
            cam.CFrame = oldCFrame
        end
    end
end

-- --- СОЗДАНИЕ КНОПКИ ---
if _G.AimBtn then _G.AimBtn:Destroy() end
_G.AimBtn = Instance.new("TextButton", _G.DotGui)
_G.AimBtn.Size = UDim2.new(0, 160, 0, 55)
_G.AimBtn.Position = UDim2.new(0.5, -80, 0.7, 0)
_G.AimBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
_G.AimBtn.Text = "MAGIC SHOOT"
_G.AimBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
_G.AimBtn.Font = Enum.Font.GothamBlack
_G.AimBtn.TextSize = 18
_G.AimBtn.Visible = false
_G.AimBtn.Draggable = true
_G.AimBtn.Active = true
Instance.new("UICorner", _G.AimBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", _G.AimBtn).Color = Color3.new(1, 0, 0)
Instance.new("UIStroke", _G.AimBtn).Thickness = 2

_G.AimBtn.MouseButton1Click:Connect(ForceShoot)

-- --- FLUENT ИНТЕРФЕЙС ---
Tab:AddToggle("SilentAim", {Title = "Silent Aim (Delta Safe)", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddSlider("Prediction", {Title = "Prediction Amount", Default = 0.135, Min = 0.1, Max = 0.2, Rounding = 3}):OnChanged(function(v) _G.Config.Prediction = v end)
Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) _G.AimBtn.Visible = v end)

return true
