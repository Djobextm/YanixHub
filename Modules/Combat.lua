local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local WS = workspace
local Camera = WS.CurrentCamera
local VIM = game:GetService("VirtualInputManager")
local Mouse = LP:GetMouse()

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
Dot.ZIndex = 100
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", Dot)
Stroke.Color = Color3.new(1, 1, 1)
Stroke.Thickness = 1.5

-- --- ФУНКЦИЯ ПОИСКА ТОРСА МАРДЕРА ---
local function GetMurdererTorso()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                local char = p.Character
                if char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    -- Центр хитбокса
                    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
                end
            end
        end
    end
    return nil
end

-- --- ЦИКЛ КРУЖКА ---
RS.RenderStepped:Connect(function()
    if getgenv().Config.SilentAim and getgenv().Config.ShowDot then
        local Torso = GetMurdererTorso()
        if Torso then
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Torso.Position)
            if OnScreen then
                local FixedPos = game:GetService("GuiService"):GetGuiInset()
                Dot.Position = UDim2.new(0, ScreenPos.X, 0, ScreenPos.Y - FixedPos.Y)
                Dot.Visible = true
                return
            end
        end
    end
    Dot.Visible = false
end)

-- --- ULTIMATE SILENT AIM (OminousVibes Long Range Fix) ---
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if getgenv().Config.SilentAim and not checkcaller() and self == Mouse then
        local Torso = GetMurdererTorso()
        if Torso then
            if key == "Hit" then
                -- Возвращаем CFrame торса для ЛЮБОЙ дистанции
                return Torso.CFrame
            elseif key == "Target" then
                return Torso
            end
        end
    end
    return oldIndex(self, key)
end)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if getgenv().Config.SilentAim and not checkcaller() then
        -- MM2 ShootGun Remote
        if method == "InvokeServer" and tostring(self) == "ShootGun" then
            local Torso = GetMurdererTorso()
            if Torso then
                -- ПРЯМАЯ ПОДМЕНА: аргумент [2] это точка приземления пули.
                -- Мы ставим её ровно в торс Мардера.
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
            task.wait(0.3) -- Чуть больше задержка для надежности Delta
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
    Tab:AddToggle("SilentAim", {Title = "Silent Aim (Global Range)", Default = false}):OnChanged(function(v) getgenv().Config.SilentAim = v end)
    Tab:AddToggle("ShowDot", {Title = "Show Target Dot", Default = true}):OnChanged(function(v) getgenv().Config.ShowDot = v end)
    
    local ShootBtn = Instance.new("TextButton", Visuals)
    ShootBtn.Size = UDim2.new(0, 160, 0, 50)
    ShootBtn.Position = UDim2.new(0.5, -80, 0.75, 0)
    ShootBtn.Text = "SHOOT MURDERER"
    ShootBtn.Visible = false
    ShootBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ShootBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
    ShootBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", ShootBtn)
    ShootBtn.MouseButton1Click:Connect(SilentShoot)

    Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) ShootBtn.Visible = v end)
end

return true
