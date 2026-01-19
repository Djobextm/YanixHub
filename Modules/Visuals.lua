local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Функция определения цвета роли (MM2)
local function GetRoleColor(player)
    if not player or not player.Character then return Color3.fromRGB(0, 255, 0) end
    
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    -- 1. Мардер (Красный)
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255, 0, 0)
    end
    
    -- 2. Шериф (Синий)
    if char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0, 0, 255)
    end
    
    -- 3. Герой (Желтый) - Невинный с револьвером
    if char:FindFirstChild("Revolver") or (backpack and backpack:FindFirstChild("Revolver")) then
        return Color3.fromRGB(255, 255, 0)
    end
    
    -- 4. Невинный (Зеленый)
    return Color3.fromRGB(0, 255, 0)
end

-- Основная функция ESP
local function CreateESP(player)
    if player == LP then return end
    
    local function setup()
        -- Ждем загрузки персонажа, чтобы избежать ошибок nil
        local char = player.Character or player.CharacterAdded:Wait()
        
        -- Очистка старых эффектов, чтобы не плодить белые блоки
        local old = char:FindFirstChild("YnxHighlight")
        if old then old:Destroy() end
        
        -- Создаем Highlight (не создает багов на карте)
        local highlight = Instance.new("Highlight")
        highlight.Name = "YnxHighlight"
        highlight.Parent = char
        highlight.Adornee = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            -- Проверка на валидность объектов перед обращением
            if not char or not char.Parent or not highlight.Parent then
                if connection then connection:Disconnect() end
                return
            end

            if _G.Config.ESP then
                highlight.Enabled = true
                highlight.FillColor = GetRoleColor(player)
                highlight.OutlineColor = highlight.FillColor
            else
                highlight.Enabled = false
            end
        end)
    end
    
    player.CharacterAdded:Connect(setup)
    if player.Character then setup() end
end

-- Инициализация ESP для всех игроков
for _, p in pairs(Players:GetPlayers()) do
    CreateESP(p)
end
Players.PlayerAdded:Connect(CreateESP)

-- Кнопка управления в меню
Tab:AddToggle("ESP", {Title = "Player ESP (Fix Roles)", Default = false}):OnChanged(function(v)
    _G.Config.ESP = v
    
    -- Мгновенное принудительное выключение всех эффектов
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                local h = p.Character:FindFirstChild("YnxHighlight")
                if h then h.Enabled = false end
            end
        end
    end
end)

return true
