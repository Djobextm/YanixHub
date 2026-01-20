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
    task.wait(0.5)
end
if not Tab then return false end

_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true

-- --- ФУНКЦИЯ ПОИСКА ЦЕЛИ ---
local function GetTarget()
    local mousePos = LP:GetMouse().Hit.p
    local closest = nil
    local minDist = 999999
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка: Ищем именно МАРДЕРА
            local isMurderer = p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife")
            
            if isMurderer then
                -- Дополнительная проверка на дистанцию, чтобы не сбоило
                local dist = (p.Character.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                return p.Character.HumanoidRootPart
            end
        end
    end
    return nil
end

-- --- ГЛАВНЫЙ ХУК: RAYCAST (ВИЗУАЛЬНЫЙ + ЛОГИЧЕСКИЙ) ---
-- Это заставляет саму игру рассчитывать полет пули в сторону врага
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if _G.Config.SilentAim and method == "Raycast" and tostring(self) == "Workspace" then
        local origin = args[1]
        local direction = args[2]
        
        -- Проверяем, что Raycast идет от нашего персонажа (от пистолета/головы)
        if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local myPos = LP.Character.HumanoidRootPart.Position
            if (origin - myPos).Magnitude < 15 then -- Если луч исходит от нас
                
                local targetPart = GetTarget()
                if targetPart then
                    -- РАСЧЕТ УПРЕЖДЕНИЯ
                    local vel = targetPart.Velocity
                    local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                    local prediction = 0.135 + ping
                    
                    local predictedPos = targetPart.Position + (vel * prediction) + Vector3.new(0, 0.5, 0)
                    
                    -- ПОДМЕНА НАПРАВЛЕНИЯ
                    -- Мы меняем Direction луча так, чтобы он летел точно в цель
                    local newDirection = (predictedPos - origin).Unit * 1000
                    args[2] = newDirection
                    
                    return oldNamecall(self, unpack(args))
                end
            end
        end
    end

    -- Дополнительный хук для FireServer (на всякий случай)
    if _G.Config.SilentAim and method == "FireServer" and tostring(self) == "ShootGun" then
        local targetPart = GetTarget()
        if targetPart then
             -- Пинг и упреждение
            local vel = targetPart.Velocity
            local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
            local predictedPos = targetPart.Position + (vel * (0.135 + ping)) + Vector3.new(0, 0.5, 0)
            
            args[1] = predictedPos
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- --- ФУНКЦИЯ ВЫСТРЕЛА (КНОПКА) ---
local function ForceShoot()
    local char = LP.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    
    if gun then
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.25)
        end
        -- Виртуальный клик. Благодаря хуку Raycast выше, 
        -- пуля полетит в Мардера, даже если камера смотрит в пол.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- UI КНОПКА ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "YanixMagicBullet"

local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.7, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.Text = "MAGIC SHOOT"
AimBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true

local UICorner = Instance.new("UICorner", AimBtn)
UICorner.CornerRadius = UDim.new(0, 10)
local UIStroke = Instance.new("UIStroke", AimBtn)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 2

AimBtn.MouseButton1Click:Connect(ForceShoot)

-- --- FLUENT UI ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Magic Bullet)", 
    Description = "Пули визуально и физически летят в цель",
    Default = false
}):OnChanged(function(v) _G.Config.SilentAim = v end)

Tab:AddToggle("PingComp", { Title = "Ping Compensation", Default = true }):OnChanged(function(v) _G.Config.PingComp = v end)

Tab:AddToggle("ShowBtn", { Title = "Show Magic Button", Default = false }):OnChanged(function(v) AimBtn.Visible = v end)

return true
