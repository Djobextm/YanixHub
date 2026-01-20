local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local VIM = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

-- Конфигурация
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true

-- Поиск вкладки Main
local Tab = nil
for i = 1, 20 do
    if _G.Tabs and _G.Tabs.Main then
        Tab = _G.Tabs.Main
        break
    end
    task.wait(0.5)
end

if not Tab then return false end

-- --- ФУНКЦИЯ ПОИСКА МАРДЕРА ---
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Ищем нож у игрока
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- --- РАСЧЕТ УПРЕЖДЕНИЯ (PREDICTION) ---
local function GetMagicPos(target)
    local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
    local prediction = 0.142 + ping
    
    return target.Position + (target.Velocity * prediction) + Vector3.new(0, 0.6, 0)
end

-- --- МАГИЧЕСКИЙ ХУК (САМАЯ СТАБИЛЬНАЯ ЧАСТЬ) ---
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    -- Проверяем, что запрос идет к мышке и включен Silent Aim
    if _G.Config.SilentAim and self == Mouse and not checkcaller() then
        if key == "Hit" then
            local target = GetMurderer()
            if target then
                return CFrame.new(GetMagicPos(target)) -- Подменяем позицию клика
            end
        elseif key == "Target" then
            local target = GetMurderer()
            if target then
                return target -- Подменяем объект под мышкой
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- --- ФУНКЦИЯ ВЫСТРЕЛА ---
local function MagicShoot()
    local char = LP.Character
    local gun = char and (char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun"))
    
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3)
        end
        
        -- Просто кликаем. Хук выше сам направит пулю.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- СОЗДАНИЕ КНОПКИ ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
AimBtn.Text = "MAGIC SHOOT"
AimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", AimBtn)
Stroke.Color, Stroke.Thickness = Color3.new(1, 0, 0), 2

AimBtn.MouseButton1Click:Connect(MagicShoot)

-- --- ИНТЕРФЕЙС FLUENT ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Magic)", 
    Description = "Подменяет направление выстрела на Мардера",
    Default = false
}):OnChanged(function(v) _G.Config.SilentAim = v end)

Tab:AddToggle("PingComp", {Title = "Ping Compensation", Default = true}):OnChanged(function(v) _G.Config.PingComp = v end)
Tab:AddToggle("ShowBtn", {Title = "Show Remi Button", Default = false}):OnChanged(function(v) AimBtn.Visible = v end)

return true
