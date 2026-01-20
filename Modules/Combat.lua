local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")

-- Конфиг
_G.Config = _G.Config or {}
_G.Config.SilentAim = false
_G.Config.PingComp = true

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

-- --- ФУНКЦИЯ ПОЛУЧЕНИЯ ТОЧКИ МАРДЕРА ---
local function GetMagicTarget()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            -- Проверка на Мардера
            if p.Character:FindFirstChild("Knife") or p.Backpack:FindFirstChild("Knife") then
                local root = p.Character.HumanoidRootPart
                local velocity = root.Velocity
                
                -- Динамическое упреждение (Пинг + База)
                local ping = _G.Config.PingComp and (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0
                local prediction = 0.145 + ping
                
                -- Итоговая позиция (в торс)
                return root.Position + (velocity * prediction) + Vector3.new(0, 0.5, 0)
            end
        end
    end
    return nil
end

-- --- КНОПКА ВЫСТРЕЛА ---
local function ExecuteShoot()
    local char = LP.Character
    if not char then return end
    
    local gun = char:FindFirstChild("Gun") or LP.Backpack:FindFirstChild("Gun")
    if gun then
        -- Экипировка
        if gun.Parent == LP.Backpack then
            char.Humanoid:EquipTool(gun)
            task.wait(0.3)
        end
        
        -- Вызываем выстрел. Даже если персонаж смотрит в пол, 
        -- хук ниже подменит направление в момент отправки на сервер.
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- --- КРИТИЧЕСКИЙ ХУК (ПОДМЕНА В ПАКЕТЕ) ---
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Если игра пытается отправить данные о выстреле
    if _G.Config.SilentAim and method == "FireServer" and tostring(self) == "ShootGun" then
        local targetPos = GetMagicTarget()
        if targetPos then
            -- ПРИНУДИТЕЛЬНАЯ ПОДМЕНА:
            -- args[1] - это позиция, куда летит пуля в скрипте MM2.
            args[1] = targetPos
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)

-- --- СОЗДАНИЕ GUI ---
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local AimBtn = Instance.new("TextButton", ScreenGui)
AimBtn.Size = UDim2.new(0, 150, 0, 50)
AimBtn.Position = UDim2.new(0.5, -75, 0.8, 0)
AimBtn.Text = "MAGIC SHOOT"
AimBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AimBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.Visible = false
AimBtn.Draggable = true
AimBtn.Active = true
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", AimBtn).Color = Color3.new(1, 0, 0)

AimBtn.MouseButton1Click:Connect(ExecuteShoot)

-- --- ИНТЕРФЕЙС FLUENT ---
Tab:AddToggle("SilentAim", {
    Title = "Silent Aim (Magic Fix)", 
    Description = "Пуля летит в Мардера при любом направлении выстрела",
    Default = false
}):OnChanged(function(v) _G.Config.SilentAim = v end)

Tab:AddToggle("PingComp", {Title = "Ping Compensation", Default = true}):OnChanged(function(v) _G.Config.PingComp = v end)
Tab:AddToggle("ShowBtn", {Title = "Show Remi Button", Default = false}):OnChanged(function(v) AimBtn.Visible = v end)

return true
