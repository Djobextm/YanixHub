local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Конфигурация
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.DynamicPrediction = 0.145
_G.Config.ShowDot = true
_G.Config.PingComp = true

-- Ожидание UI вкладки
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end
if not Tab then return false end

-- --- СОЗДАНИЕ ВИЗУАЛЬНОЙ МЕТКИ (DOT) ---
local DotGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
DotGui.Name = "RemiVisuals"

local Dot = Instance.new("Frame", DotGui)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.Visible = false
Dot.ZIndex = 10
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local DotStroke = Instance.new("UIStroke", Dot)
DotStroke.Color = Color3.new(1, 1, 1)
DotStroke.Thickness = 1.5

-- --- ФУНКЦИЯ ПОИСКА МАРДЕРА И УПРЕЖДЕНИЯ ---
local function GetTargetData()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на роль Мардера
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Динамический расчет упреждения
                local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                local dist = (root.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                local timeScale = _G.Config.DynamicPrediction + ping + (dist / 900)
                
                -- Точка выстрела (Торс + Упреждение)
                local predictPos = root.Position + (velocity * timeScale) + Vector3.new(0, 0.5, 0)
                return predictPos, p.Character
            end
        end
    end
    return nil
end

-- --- ОБНОВЛЕНИЕ МЕТКИ (RENDER STEPPED) ---
RunService.RenderStepped:Connect(function()
    if _G.Config.SilentAim and _G.Config.ShowDot then
        local targetPos = GetTargetData()
        if targetPos then
            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(targetPos)
            if onScreen then
                Dot.Position = UDim2.new(0, screenPos.X - 5, 0, screenPos.Y - 5)
                Dot.Visible = true
                return
            end
        end
    end
    Dot.Visible = false
end)

-- --- СУПЕР ХУК (MAGIC BULLET LOGIC) ---
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

-- Обман локального скрипта оружия (Mouse.Hit)
mt.__index = newcclosure(function(self, key)
    if _G.Config.SilentAim and not checkcaller() and self == Mouse and (key == "Hit" or key == "p") then
        local tPos = GetTargetData()
        if tPos then return CFrame.new(tPos) end
    end
    return oldIndex(self, key)
end)

-- Обман сервера (FireServer ShootGun)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if _G.Config.SilentAim and method == "FireServer" and tostring(self) == "ShootGun" then
        local tPos = GetTargetData()
        if tPos then
            args[1] = tPos -- Направляем пулю в предсказанную точку
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- --- ФУНКЦИЯ КНОПКИ (ВЫСТРЕЛА) ---
local function ExecuteShoot()
    local char = LP.Character
    local gun = char and (char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun"))
    
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3)
        end
        
        -- Просто кликаем. Хуки сами направят пулю в красную метку.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- UI КНОПКА (REMI SHOOT) ---
local AimBtn = Instance.new("TextButton", DotGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "DYNAMIC SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", AimBtn)
Stroke.Color, Stroke.Thickness = Color3.new(1, 0, 0), 2

AimBtn.MouseButton1Click:Connect(ExecuteShoot)

-- --- FLUENT ИНТЕРФЕЙС ---
Tab:AddToggle("SilentAim", {Title = "Dynamic Silent Aim", Default = false}):OnChanged(function(v) _G.Config.SilentAim = v end)
Tab:AddToggle("ShowDot", {Title = "Show Prediction Dot", Default = true}):OnChanged(function(v) _G.Config.ShowDot = v end)
Tab:AddSlider("PredictStr", {Title = "Prediction Strength", Default = 0.145, Min = 0.1, Max = 0.2, Rounding = 3}):OnChanged(function(v) _G.Config.DynamicPrediction = v end)
Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) AimBtn.Visible = v end)

return true
