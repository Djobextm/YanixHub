local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("RunService")
local WS = workspace
local Stats = game:GetService("Stats")

-- --- Настройки ---
_G.Config = _G.Config or {}
_G.Config.SilentAim = true
_G.Config.ShowDot = true

-- Поиск вкладки для интеграции в твой UI
local Tab = nil
for i = 1, 15 do
    if _G.Tabs and _G.Tabs.Main then Tab = _G.Tabs.Main break end
    task.wait(0.5)
end

-- --- Визуал (Кружок на торсе) ---
if _G.TargetGui then _G.TargetGui:Destroy() end
local Gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
_G.TargetGui = Gui

local Dot = Instance.new("Frame", Gui)
Dot.Size = UDim2.new(0, 12, 0, 12)
Dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Dot.AnchorPoint = Vector2.new(0.5, 0.5)
Dot.Visible = false
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
local Stroke = Instance.new("UIStroke", Dot)
Stroke.Thickness = 2
Stroke.Color = Color3.new(1, 1, 1)

-- --- Функция поиска Мардера ---
local function GetMurderer()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на наличие ножа (как в твоем примере)
            if v.Character:FindFirstChild("Knife") or v.Backpack:FindFirstChild("Knife") then
                return v
            end
        end
    end
    return nil
end

-- --- Рендер кружка на торсе ---
RS.RenderStepped:Connect(function()
    if _G.Config.SilentAim and _G.Config.ShowDot then
        local Murderer = GetMurderer()
        if Murderer and Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") then
            local Root = Murderer.Character.HumanoidRootPart
            local Pos, OnScreen = WS.CurrentCamera:WorldToViewportPoint(Root.Position)
            
            if OnScreen then
                Dot.Position = UDim2.new(0, Pos.X, 0, Pos.Y)
                Dot.Visible = true
                return
            end
        end
    end
    Dot.Visible = false
end)

-- --- Metatable Silent Aim (На основе твоего примера) ---
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if _G.Config.SilentAim and not checkcaller() then
        -- Используем InvokeServer и ShootGun (как в твоем примере)
        if method == "InvokeServer" and tostring(self) == "ShootGun" then
            local Murderer = GetMurderer()
            if Murderer and Murderer.Character and Murderer.Character:FindFirstChild("HumanoidRootPart") then
                local Root = Murderer.Character.HumanoidRootPart
                
                -- Мы целимся именно в позицию Root (торс), где висит кружок
                -- В MM2 аргумент [2] в ShootGun отвечает за направление/позицию
                args[2] = Root.Position
                
                return oldNamecall(self, unpack(args))
            end
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

-- --- Кнопка выстрела ---
local ShootBtn = Instance.new("TextButton", Gui)
ShootBtn.Size = UDim2.new(0, 150, 0, 50)
ShootBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
ShootBtn.Text = "SILENT SHOOT"
ShootBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ShootBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ShootBtn.Font = Enum.Font.GothamBold
ShootBtn.Visible = false
Instance.new("UICorner", ShootBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ShootBtn).Color = Color3.new(1, 0, 0)

ShootBtn.MouseButton1Click:Connect(function()
    local char = LP.Character
    local gun = char and (char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun"))
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.2)
        end
        -- Нажимаем на экран через VirtualInputManager
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end)

-- --- UI Настройки ---
if Tab then
    Tab:AddToggle("SilentAim", {Title = "Silent Aim (Anchored)", Default = true}):OnChanged(function(v) _G.Config.SilentAim = v end)
    Tab:AddToggle("ShowDot", {Title = "Show Target Dot", Default = true}):OnChanged(function(v) _G.Config.ShowDot = v end)
    Tab:AddToggle("ShowBtn", {Title = "Show Shoot Button", Default = false}):OnChanged(function(v) ShootBtn.Visible = v end)
end

return true
