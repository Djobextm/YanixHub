local Players = game:GetService("Playerslocal Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Функция определения цвета по роли (MM2)
local function GetRoleColor(player)
    if not player.Character then return Color3.fromRGB(0, 255, 0) end
    
    -- Мардер (Красный)
    if player.Character:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife") then
        return Color3.fromRGB(255, 0, 0)
    end
    
    -- Шериф (Синий)
    if player.Character:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun") then
        return Color3.fromRGB(0, 0, 255)
    end
    
    -- Герой (Желтый) — невинный с револьвером
    if player.Character:FindFirstChild("Revolver") or player.Backpack:FindFirstChild("Revolver") then
        return Color3.fromRGB(255, 255, 0)
    end
    
    -- Невинный (Зеленый)
    return Color3.fromRGB(0, 255, 0)
end

-- Функция управления ESP
local function CreateESP(player)
    if player == LP then return end
    
    local function apply()
        local char = player.Character or player.CharacterAdded:Wait()
        
        -- Удаляем старый эффект, если он остался
        local old = char:FindFirstChild("YnxESP")
        if old then old:Destroy() end
        
        -- Создаем Highlight (безопасный метод без белых блоков)
        local highlight = Instance.new("Highlight")
        highlight.Name = "YnxESP"
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = _G.Config.ESP or false
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            -- Проверка на существование объекта
            if not char or not char.Parent or not highlight.Parent then 
                conn:Disconnect() 
                return 
            end
            
            -- ПРЯМОЕ УПРАВЛЕНИЕ ВКЛЮЧЕНИЕМ/ВЫКЛЮЧЕНИЕМ
            if _G.Config.ESP then
                highlight.Enabled = true
                highlight.FillColor = GetRoleColor(player)
                highlight.OutlineColor = highlight.FillColor
            else
                highlight.Enabled = false
            end
        end)
    end
    
    player.CharacterAdded:Connect(apply)
    if player.Character then apply() end
end

-- Инициализация для всех игроков
for _, p in pairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(CreateESP)

-- Кнопка в меню
Tab:AddToggle("ESP", {Title = "Player ESP (Roles)", Default = false}):OnChanged(function(v)
    _G.Config.ESP = v
    
    -- Принудительное мгновенное обновление для всех при выключении
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("YnxESP") then
                p.Character.YnxESP.Enabled = false
            end
        end
    end
end)

return true
