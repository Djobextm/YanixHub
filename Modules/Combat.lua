local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

-- --- CONFIG ---
getgenv().Config = getgenv().Config or {}
getgenv().Config.SilentAim = false
getgenv().Config.ShowDot = true

-- Очистка старых элементов
if getgenv().Visuals then getgenv().Visuals:Destroy() end

-- --- GUI (Кружок на торсе) ---
local Visuals = Instance.new("ScreenGui", game:GetService("CoreGui"))
Visuals.Name = "RemiAnchoredVisuals"
getgenv().Visuals = Visuals

local Dot = Instance.new("Frame", Visuals)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.Visible = false
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.ZIndex = 10
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", Dot)
Stroke.Color = Color3.new(1, 1, 1)
Stroke.Thickness = 1.5

-- --- ФУНКЦИЯ ПОИСКА МАРДЕРА ---
local function GetMurdererRoot()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                if p.Character.Humanoid.Health > 0 then
                    return p.Character.HumanoidRootPart
                end
            end
        end
    end
    return nil
end

-- --- ЦИКЛ ОБНОВЛЕНИЯ МЕТКИ ---
RS.RenderStepped:Connect(function()
    if not getgenv().Config.SilentAim or not getgenv().Config.ShowDot then
        Dot.Visible = false
        return
    end

    local Root = GetMurdererRoot()
    if Root then
        local ScreenPos, OnScreen = Workspace.CurrentCamera:WorldToViewportPoint(Root.Position)
        if OnScreen then
            Dot.Visible = true
            Dot.Position = UDim2.new(0, ScreenPos.X, 0, ScreenPos.Y)
        else
            Dot.Visible = false
        end
    else
        Dot.Visible = false
    end
end)

-- --- ГЛАВНЫЙ ФИКС: ПЕРЕХВАТ МЫШИ (RAYCAST) ---
-- Это заставляет пулю лететь в кружок, а не туда, куда ты нажал
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    -- Если игра запрашивает "Куда нажала мышка?" (Hit) или "На кого наведена?" (Target)
    if getgenv().Config.SilentAim and not checkcaller() and tostring(self) == "Mouse" then
        local Root = GetMurdererRoot()
        if Root then
            if key == "Hit" then
                -- Возвращаем координаты кружка (торса) вместо места нажатия
                return CFrame.new(Root.Position)
            elseif key == "Target" then
                -- Возвращаем сам торс мардера
                return Root
            end
        end
    end
    return oldIndex(self, key)
end)

setreadonly(mt, true)

-- --- ФУНКЦИЯ ВЫСТРЕЛА ---
local function SilentShoot()
    local Char = LP.Character
    if not Char then return end
    
    local Gun = Char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if Gun then
        if Gun.Parent == LP.Backpack then
            Char.Humanoid:EquipTool(Gun)
            task.wait(0.25)
        end
        
        -- Нажимаем кнопку. Благодаря хуку выше, игра "подумает", 
        -- что ты кликнул точно по кружку (торсу).
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- UI КНОПКА ---
local ShootBtn = Instance.new("TextButton", Visuals)
ShootBtn.Size = UDim2.new(0, 150, 0, 50)
ShootBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
ShootBtn.Text = "DYNAMIC SHOOT"
ShootBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ShootBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
ShootBtn.Font = Enum.Font.GothamBold
ShootBtn.Visible = false
Instance.new("UICorner", ShootBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", ShootBtn).Color = Color3.new(1, 0, 0)
ShootBtn.MouseButton1Click:Connect(SilentShoot)

-- --- ИНТЕГРАЦИЯ С ТВОИМ МЕНЮ ---
local Tab = nil
for i = 1, 20 do
    if _G.Tabs and _G.Tabs.Main then Tab = _G.Tabs.Main break end
    task.wait(0.2)
end

if Tab then
    Tab:AddToggle("SilentAim", {Title = "Dynamic Silent Aim", Default = false}):OnChanged(function(v) getgenv().Config.SilentAim = v end)
    Tab:AddToggle("ShowDot", {Title = "Show Target Dot", Default = true}):OnChanged(function(v) getgenv().Config.ShowDot = v end)
    Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) ShootBtn.Visible = v end)
end

return true
