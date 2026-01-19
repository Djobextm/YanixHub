local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Tab = _G.Tabs.Visuals

-- Функция определения цвета роли MM2
local function GetRoleColor(player)
    if not player or not player.Character then return Color3.fromRGB(0, 255, 0) end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return Color3.fromRGB(255, 0, 0) -- Мардер
    elseif char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return Color3.fromRGB(0, 0, 255) -- Шериф
    elseif char:FindFirstChild("Revolver") or (backpack and backpack:FindFirstChild("Revolver")) then
        return Color3.fromRGB(255, 255, 0) -- Герой
    end
    return Color3.fromRGB(0, 255, 0) -- Невинный
end

-- Универсальная функция создания тега (Имена и Оружие)
local function CreateTag(parent, text, color)
    if parent:FindFirstChild("YnxTag") then parent.YnxTag:Destroy() end
    
    local bgu = Instance.new("BillboardGui")
    bgu.Name = "YnxTag"
    bgu.Adornee = parent
    bgu.Size = UDim2.new(0, 200, 0, 50)
    bgu.StudsOffset = Vector3.new(0, 2, 0)
    bgu.AlwaysOnTop = true
    bgu.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = color or Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0 -- Обводка для читаемости
    lbl.Parent = bgu
    return bgu
end

-- Логика Player ESP
local function SetupPlayerESP(player)
    if player == LP then return end
    local function apply()
        local char = player.Character or player.CharacterAdded:Wait()
        local head = char:WaitForChild("Head", 5)
        if not head then return end

        local highlight = char:FindFirstChild("YnxHighlight") or Instance.new("Highlight")
        highlight.Name = "YnxHighlight"
        highlight.Parent = char
        highlight.FillTransparency = 0.5
        
        local tag = CreateTag(head, player.Name, Color3.new(1,1,1))

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not highlight.Parent then
                conn:Disconnect()
                return
            end
            
            local active = _G.Config.ESP or false
            highlight.Enabled = active
            tag.Enabled = active
            
            if active then
                local color = GetRoleColor(player)
                highlight.FillColor = color
                highlight.OutlineColor = color
                tag.TextLabel.TextColor3 = color
            end
        end)
    end
    player.CharacterAdded:Connect(apply)
    if player.Character then apply() end
end

-- Gun ESP (Надпись ★ FALLING GUN ★)
local function SetupGunESP()
    RunService.RenderStepped:Connect(function()
        -- Поиск выпавшего пистолета в MM2
        local gun = workspace:FindFirstChild("GunDrop") or workspace:FindFirstChild("Gun")
        if gun and gun:IsA("BasePart") then
            -- Подсветка (Highlight)
            local gHighlight = gun:FindFirstChild("YnxGunHighlight") or Instance.new("Highlight")
            gHighlight.Name = "YnxGunHighlight"
            gHighlight.Parent = gun
            gHighlight.FillColor = Color3.fromRGB(255, 255, 255)
            gHighlight.Enabled = _G.Config.GunESP or false
            
            -- Надпись со звездами ★ FALLING GUN ★
            local gTag = gun:FindFirstChild("YnxTag") or CreateTag(gun, "★ FALLING GUN ★", Color3.fromRGB(255, 255, 255))
            gTag.Enabled = _G.Config.GunESP or false
        end
    end)
end

-- Инициализация модулей
for _, p in pairs(Players:GetPlayers()) do SetupPlayerESP(p) end
Players.PlayerAdded:Connect(SetupPlayerESP)
SetupGunESP()

-- Переключатели в меню
Tab:AddToggle("ESP", {Title = "Player ESP + Names", Default = false}):OnChanged(function(v) _G.Config.ESP = v end)
Tab:AddToggle("GunESP", {Title = "Dropped Gun ESP", Default = false}):OnChanged(function(v) _G.Config.GunESP = v end)

return true
