local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local RS = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

-- --- ГЛОБАЛЬНЫЕ НАСТРОЙКИ ---
getgenv().Config = getgenv().Config or {
    SilentAim = false,
    ShowDot = true,
    Prediction = 0.138 -- Динамическое упреждение внутри хука
}

-- Очистка старых GUI
if getgenv().CombatVisuals then getgenv().CombatVisuals:Destroy() end

-- --- GUI КРУЖКА ---
local Visuals = Instance.new("ScreenGui", game:GetService("CoreGui"))
Visuals.Name = "CombatVisuals"
getgenv().CombatVisuals = Visuals

local Dot = Instance.new("Frame", Visuals)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.Visible = false
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", Dot)
Stroke.Color = Color3.new(1, 1, 1)
Stroke.Thickness = 1.5

-- --- ФУНКЦИЯ ПОИСКА МАРДЕРА ---
local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на нож (стандарт MM2)
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                if p.Character.Humanoid.Health > 0 then
                    return p.Character.HumanoidRootPart
                end
            end
        end
    end
    return nil
end

-- --- ОБНОВЛЕНИЕ КРУЖКА (ЖЕСТКАЯ ПРИВЯЗКА) ---
RS.RenderStepped:Connect(function()
    if getgenv().Config.SilentAim and getgenv().Config.ShowDot then
        local Root = GetMurderer()
        if Root then
            -- Проецируем 3D позицию торса на 2D экран
            local ScreenPos, OnScreen = workspace.CurrentCamera:WorldToViewportPoint(Root.Position)
            if OnScreen then
                Dot.Position = UDim2.new(0, ScreenPos.X, 0, ScreenPos.Y)
                Dot.Visible = true
                return
            end
        end
    end
    Dot.Visible = false
end)

-- --- АНАЛИЗ И ПРИМЕНЕНИЕ ХУКОВ ---
-- Используем метод подмены свойств мыши, так как Delta лучше всего работает с __index
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    -- Проверка: Обращается ли скрипт оружия к мышке?
    if getgenv().Config.SilentAim and not checkcaller() and self == Mouse then
        local Root = GetMurderer()
        if Root then
            -- Если оружие хочет знать, куда летит пуля (Hit)
            if key == "Hit" then
                -- Добавляем небольшое динамическое упреждение на основе скорости
                local Prediction = Root.Velocity * getgenv().Config.Prediction
                return CFrame.new(Root.Position + Prediction)
            -- Если оружие проверяет, на кого наведен прицел (Target)
            elseif key == "Target" then
                return Root
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- --- КНОПКА ВЫСТРЕЛА ---
local function ExecuteShoot()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.25)
        end
        -- Имитируем клик. Хук выше заставит игру думать, что клик был по кружку.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- UI ИНТЕГРАЦИЯ ---
local Tab = nil
for i = 1, 20 do
    if _G.Tabs and _G.Tabs.Main then Tab = _G.Tabs.Main break end
    task.wait(0.2)
end

if Tab then
    Tab:AddToggle("SilentAim", {Title = "Dynamic Silent Aim", Default = false}):OnChanged(function(v) getgenv().Config.SilentAim = v end)
    Tab:AddToggle("ShowDot", {Title = "Show Target Dot", Default = true}):OnChanged(function(v) getgenv().Config.ShowDot = v end)
    
    -- Кнопка выстрела (отдельная, если нужно)
    local ShootBtn = Instance.new("TextButton", Visuals)
    ShootBtn.Size = UDim2.new(0, 150, 0, 50)
    ShootBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
    ShootBtn.Text = "FORCE SHOOT"
    ShootBtn.Visible = false
    ShootBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ShootBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
    Instance.new("UICorner", ShootBtn)
    ShootBtn.MouseButton1Click:Connect(ExecuteShoot)

    Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) ShootBtn.Visible = v end)
end

return true
