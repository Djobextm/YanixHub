local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local WS = workspace
local Camera = WS.CurrentCamera
local VIM = game:GetService("VirtualInputManager")

-- --- CONFIG ---
getgenv().Config = getgenv().Config or {
    SilentAim = false,
    ShowDot = true
}

-- Очистка старых GUI
if getgenv().CombatVisuals then getgenv().CombatVisuals:Destroy() end

-- --- GUI (Кружок на торсе) ---
local Visuals = Instance.new("ScreenGui", game:GetService("CoreGui"))
Visuals.Name = "CombatVisuals"
getgenv().CombatVisuals = Visuals

local Dot = Instance.new("Frame", Visuals)
Dot.Size = UDim2.new(0, 10, 0, 10)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.Visible = false
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.ZIndex = 100 -- Поверх всего
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", Dot)
Stroke.Color = Color3.new(1, 1, 1)
Stroke.Thickness = 1.5

-- --- ФУНКЦИЯ ПОИСКА ТОРСА МАРДЕРА ---
local function GetMurdererTorso()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            -- Проверка роли (нож)
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                local char = p.Character
                if char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    -- Пытаемся найти торс (поддержка R15 и R6)
                    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                end
            end
        end
    end
    return nil
end

-- --- ЦИКЛ ПРИВЯЗКИ КРУЖКА (ЖЕСТКИЙ ANCHOR) ---
RS.RenderStepped:Connect(function()
    if getgenv().Config.SilentAim and getgenv().Config.ShowDot then
        local Torso = GetMurdererTorso()
        if Torso then
            -- Используем именно CFrame.Position торса для точности
            local WorldPos = Torso.Position
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(WorldPos)
            
            if OnScreen then
                -- Учитываем GUI Inset (чтобы не было смещения вниз)
                local FixedPos = game:GetService("GuiService"):GetGuiInset()
                Dot.Position = UDim2.new(0, ScreenPos.X, 0, ScreenPos.Y - FixedPos.Y)
                Dot.Visible = true
                return
            end
        end
    end
    Dot.Visible = false
end)

-- --- ЧИСТЫЙ SILENT AIM (OminousVibes Logic) ---
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
setreadonly(mt, false)

-- Подмена Mouse.Hit (Куда целится скрипт оружия)
mt.__index = newcclosure(function(self, key)
    if getgenv().Config.SilentAim and not checkcaller() and tostring(self) == "Mouse" then
        local Torso = GetMurdererTorso()
        if Torso then
            if key == "Hit" then
                return Torso.CFrame -- Возвращаем CFrame торса
            elseif key == "Target" then
                return Torso
            end
        end
    end
    return oldIndex(self, key)
end)

-- Подмена пакета выстрела (InvokeServer)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if getgenv().Config.SilentAim and not checkcaller() then
        if method == "InvokeServer" and tostring(self) == "ShootGun" then
            local Torso = GetMurdererTorso()
            if Torso then
                -- args[2] в MM2 — это Vector3 цели
                args[2] = Torso.Position
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- --- ФУНКЦИЯ ВЫСТРЕЛА ---
local function SilentShoot()
    local char = LP.Character
    local gun = char and (char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun"))
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.25)
        end
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- ИНТЕГРАЦИЯ В МЕНЮ ---
local Tab = nil
for i = 1, 20 do
    if _G.Tabs and _G.Tabs.Main then Tab = _G.Tabs.Main break end
    task.wait(0.2)
end

if Tab then
    Tab:AddToggle("SilentAim", {Title = "Silent Aim (Anchored)", Default = false}):OnChanged(function(v) getgenv().Config.SilentAim = v end)
    Tab:AddToggle("ShowDot", {Title = "Show Target Dot", Default = true}):OnChanged(function(v) getgenv().Config.ShowDot = v end)
    
    local ShootBtn = Instance.new("TextButton", Visuals)
    ShootBtn.Size = UDim2.new(0, 150, 0, 50)
    ShootBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
    ShootBtn.Text = "FORCE SHOOT"
    ShootBtn.Visible = false
    ShootBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ShootBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    Instance.new("UICorner", ShootBtn)
    ShootBtn.MouseButton1Click:Connect(SilentShoot)

    Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) ShootBtn.Visible = v end)
end

return true
