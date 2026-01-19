local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Функция определения цвета (4 роли: Мардер, Шериф, Герой, Невинный)
local function GetRoleColor(player)
    if not player or not player.Character then return Color3.fromRGB(0, 255, 0) end
    
    local char = player.Character
    local backpack = player.Backpack
    
    -- Мардер (Красный)
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255, 0, 0)
    end
    
    -- Шериф (Синий)
    if char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0, 0, 255)
    end
    
    -- Герой (Желтый)
    if char:FindFirstChild("Revolver") or (backpack and backpack:FindFirstChild("Revolver")) then
        return Color3.fromRGB(255, 255, 0)
    end
    
    -- Невинный (Зеленый)
    return Color3.fromRGB(0, 255, 0)
end

-- Функция управления ESP
local function ApplyESP(player)
    if player == LP then return end
    
    local function setup()
        local char = player.Character or player.CharacterAdded:Wait()
        -- Удаляем старые Highlight, чтобы не было наслоений
        for _, old in pairs(char:GetChildren()) do
            if old.Name == "YnxHighlight" then old:Destroy() end
        end

        local highlight = Instance.new("Highlight")
        highlight.Name = "YnxHighlight"
        highlight.Parent = char
        highlight.Adornee = char
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not highlight.Parent then
                connection:Disconnect()
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

-- Инициализация
for _, p in pairs(Players:GetPlayers()) do ApplyESP(p) end
Players.PlayerAdded:Connect(ApplyESP)

Tab:AddToggle("ESP", {Title = "Player ESP (Fix Roles)", Default = false}):OnChanged(function(v)
    _G.Config.ESP = v
    -- Мгновенное скрытие при выключении
    if not v then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("YnxHighlight") then
                p.Character.YnxHighlight.Enabled = false
            end
        end
    end
end)

return true
