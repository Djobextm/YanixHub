local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local VIM = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

-- Ожидание вкладки Main
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Проверка на загрузку
if not game:IsLoaded() then game.Loaded:Wait() end

-- Ожидание вкладки Main
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then 
    warn("Combat: Tab not found")
    return false 
end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true
_G.Config.ShowBtn = false

-- --- ФУНКЦИЯ ПОИСКА ЦЕЛИ (БЕЗОПАСНАЯ) ---
local function GetMurdererTarget()
    -- Используем pcall чтобы избежать ошибок если игрок вышел
    local success, result = pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                -- Ищем нож
                if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                    return p.Character.HumanoidRootPart
                end
            end
        end
        return nil
    end)
    
    if success then return result else return nil end
end

-- --- РАСЧЕТ УПРЕЖДЕНИЯ (PREDICTION) ---
local function GetPredictedPos(targetPart)
    if not targetPart then return nil end
    
    local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
    local prediction = 0.14 + ping
    local velocity = targetPart.Velocity
    
    -- Простая физика: Позиция + (Скорость * Время)
    return targetPart.Position + (velocity * prediction) + Vector3.new(0, 0.5, 0)
end

-- --- ХУК МЫШКИ (ГЛАВНАЯ МАГИЯ) ---
-- Это заставляет пулю лететь визуально в цель
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    -- Если скрипт пытается узнать позицию мыши (Hit) или цель (Target)
    if _G.Config.SilentAim and not checkcaller() and tostring(self) == "Mouse" then
        if key == "Hit" then
            local target = GetMurdererTarget()
            if target then
                local predPos = GetPredictedPos(target)
                return CFrame.new(predPos) -- Говорим игре, что мышка там
            end
        elseif key == "Target" then
            local target = GetMurdererTarget()
            if target then
                return target -- Говорим игре, что под курсором Мардер
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- --- ФУНКЦИЯ ВЫСТРЕЛА ---
local function Shoot()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.25)
        end
        
        -- Просто кликаем. Благодаря хуку выше, игра "думает", что мы кликаем по Мардеру
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- КНОПКА ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixStableUI"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.7, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
AimBtn.Text = "MAGIC SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", AimBtn).Color = Color3.fromRGB(255, 0, 0)

AimBtn.MouseButton1Click:Connect(Shoot)

-- --- FLUENT UI ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Mouse Hook)", 
    Description = "Стабильная версия Magic Bullet",
    Default = false
}):OnChanged(function(v) _G.Config.SilentAim = v end)

Tab:AddToggle("PingComp", { Title = "Ping Compensation", Default = true }):OnChanged(function(v) _G.Config.PingComp = v end)

Tab:AddToggle("ShowBtn", { Title = "Show Magic Button", Default = false }):OnChanged(function(v) AimBtn.Visible = v end)

return true
